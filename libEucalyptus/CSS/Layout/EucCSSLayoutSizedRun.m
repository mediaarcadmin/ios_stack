//
//  EucCSSLayoutSizedRun.m
//  libEucalyptus
//
//  Created by James Montgomerie on 21/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSInternal.h"
#import "EucCSSLayouter.h"
#import "EucCSSLayoutSizedRun.h"
#import "EucCSSLayoutRun.h"
#import "EucCSSLayoutRun_Package.h"

#import "EucCSSLayoutPositionedContainer.h"
#import "EucCSSLayoutPositionedRun.h"
#import "EucCSSLayoutPositionedLine.h"
#import "EucCSSLayoutPositionedBlock.h"

#import "EucCSSIntermediateDocument.h"
#import "EucCSSIntermediateDocumentNode.h"

#import "THStringRenderer.h"
#import "THPair.h"
#import "THCache.h"
#import "THLog.h"
#import "th_just_with_floats.h"

#import <objc/runtime.h>

#import <libcss/libcss.h>

typedef struct EucCSSLayoutSizedRunBreakInfo {
    EucCSSLayoutRunPoint point;
    BOOL consumesComponent;
} EucCSSLayoutSizedRunBreakInfo;

@implementation EucCSSLayoutSizedRun

@synthesize run = _run;

#define SIZED_RUN_CACHE_CAPACITY 12
static NSString * const EucCSSSizedRunPerScaleFactorCacheCacheKey = @"EucCSSSizedRunPerScaleFactorCacheCacheKey";

+ (id)sizedRunWithRun:(EucCSSLayoutRun *)run
          scaleFactor:(CGFloat)scaleFactor
{
    EucCSSLayoutSizedRun *ret = nil;
    
    EucCSSIntermediateDocument *document = run.document;
    @synchronized(document) {
        THIntegerToObjectCache *perScaleFactorCacheCache = objc_getAssociatedObject(document, EucCSSSizedRunPerScaleFactorCacheCacheKey);
        if(!perScaleFactorCacheCache) {
            perScaleFactorCacheCache = [[THIntegerToObjectCache alloc] init];
            perScaleFactorCacheCache.conserveItemsInUse = NO;
            objc_setAssociatedObject(document, EucCSSSizedRunPerScaleFactorCacheCacheKey, perScaleFactorCacheCache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [perScaleFactorCacheCache release];
        }
        uint32_t intKey = *((uint32_t *)(&scaleFactor));
        THCache *sizedRunsCache = [perScaleFactorCacheCache objectForKey:intKey];
        if(!sizedRunsCache) {
            sizedRunsCache = [[THCache alloc] init];
            sizedRunsCache.generationLifetime = SIZED_RUN_CACHE_CAPACITY;
            sizedRunsCache.conserveItemsInUse = NO;
            [perScaleFactorCacheCache cacheObject:sizedRunsCache forKey:intKey];
            [sizedRunsCache release];
        }
        ret = [sizedRunsCache objectForKey:run];
        if(!ret) {
            ret = [[[self class] alloc] initWithRun:run
                                        scaleFactor:scaleFactor];
            [sizedRunsCache cacheObject:ret forKey:run];
            [ret autorelease];
        } 
    }
    return ret;
}

- (id)initWithRun:(EucCSSLayoutRun *)run
      scaleFactor:(CGFloat)scaleFactor
{
    if((self = [super initWithScaleFactor:scaleFactor])) {
        _run = [run retain];
    }
    return self;
}

- (void)dealloc
{
    [_run release];
    
    free(_potentialBreaks);
    free(_potentialBreakInfos);
    free(_componentWidthInfos);
    
    [super dealloc];
}

- (void)_processComponentsForWidths
{
    NSUInteger componentsCount = _run.componentsCount;
    if(componentsCount) {
        EucCSSLayoutRunComponentInfo *componentInfos = _run.componentInfos;
        EucCSSLayoutSizedRunWidthInfo *componentWidthInfos = malloc(sizeof(EucCSSLayoutSizedRunWidthInfo) * _run.componentsCount);
        
        EucCSSLayoutRunComponentInfo *currentComponentInfo = componentInfos;
        EucCSSLayoutSizedRunWidthInfo *currentWidthInfo = componentWidthInfos;
        
        EucCSSLayoutRunComponentInfo *afterEndComponentInfo = componentInfos + componentsCount;
        
        EucCSSIntermediateDocumentNode *currentNode = currentComponentInfo->documentNode.parent;
        
        CGFloat scaleFactor = self.scaleFactor;
        
        for(; currentComponentInfo < afterEndComponentInfo; ++currentComponentInfo, ++currentWidthInfo) {
            switch(currentComponentInfo->kind) {
                case EucCSSLayoutRunComponentKindSpace:
                case EucCSSLayoutRunComponentKindNonbreakingSpace:
                    currentWidthInfo->width = [currentNode.stringRenderer widthOfString:@" "
                                                                              pointSize:[currentNode textPointSizeWithScaleFactor:scaleFactor]];
                    break;
                case EucCSSLayoutRunComponentKindWord:
                    currentWidthInfo->width = [currentNode.stringRenderer widthOfString:currentComponentInfo->contents.stringInfo.string
                                                                              pointSize:[currentNode textPointSizeWithScaleFactor:scaleFactor]];
                    break;
                case EucCSSLayoutRunComponentKindHyphenationRule:
                    currentWidthInfo->hyphenWidths.widthBeforeHyphen = [currentNode.stringRenderer widthOfString:currentComponentInfo->contents.hyphenationInfo.beforeHyphen
                                                                                                       pointSize:[currentNode textPointSizeWithScaleFactor:scaleFactor]];
                    currentWidthInfo->hyphenWidths.widthAfterHyphen = [currentNode.stringRenderer widthOfString:currentComponentInfo->contents.hyphenationInfo.afterHyphen
                                                                                                       pointSize:[currentNode textPointSizeWithScaleFactor:scaleFactor]];
                    break;
                /*case EucCSSLayoutRunComponentKindImage:
                    // Will be processed as size-dependent
                    break;*/
                case EucCSSLayoutRunComponentKindOpenNode:
                    currentNode = currentComponentInfo->documentNode;
                    currentWidthInfo->width = 0;
                    break;
                case EucCSSLayoutRunComponentKindCloseNode:
                    currentNode = currentComponentInfo->documentNode.parent;
                    currentWidthInfo->width = 0;
                    break;
                default:
                    currentWidthInfo->width = 0;
            }
        }
        
        _componentWidthInfos = componentWidthInfos;
    }
}

- (CGSize)_computedSizeForImage:(CGImageRef)image
                 specifiedWidth:(CGFloat)specifiedWidth
                specifiedHeight:(CGFloat)specifiedHeight
                       maxWidth:(CGFloat)maxWidth
                       minWidth:(CGFloat)minWidth
                      maxHeight:(CGFloat)maxHeight
                      minHeight:(CGFloat)minHeight
{
    // Sanitise the input.
    if(minHeight > maxHeight) {
        maxHeight = minHeight;
    }
    if(minWidth > maxWidth) {
        maxWidth = minWidth;
    }
    
    if(specifiedWidth == CGFLOAT_MAX && specifiedHeight == CGFLOAT_MAX) {
        CGFloat scaleFactor = self.scaleFactor;
        specifiedWidth = CGImageGetWidth(image) * scaleFactor;
        specifiedHeight = CGImageGetHeight(image) * scaleFactor;
    } else if(specifiedWidth == CGFLOAT_MAX) {
        specifiedWidth = (CGFloat)CGImageGetWidth(image) / (CGFloat)CGImageGetHeight(image) * specifiedHeight;
    } else if(specifiedHeight == CGFLOAT_MAX) {
        specifiedHeight = (CGFloat)CGImageGetHeight(image) / (CGFloat)CGImageGetWidth(image) * specifiedWidth;
    }
    
    // Work out the size.
    // From http://www.w3.org/TR/CSS2/visudet.html#min-max-widths
    CGFloat W = specifiedWidth;
    CGFloat H = specifiedHeight;
    
    BOOL done = NO;
    while(!done) {
        CGFloat w = W, h = H;
    
             if(w > maxWidth)                         { W = maxWidth,                       H = MAX(maxWidth * h/w, minHeight); }
        else if(w < minWidth)                         { W = minWidth,                       H = MIN(minWidth * h/w, maxHeight); }
        else if(h > maxHeight)                        { W = MAX(maxHeight * w/h, minWidth), H = maxHeight;                      }
        else if(h < minHeight)	                      { W = MIN(minHeight * w/h, maxWidth), H = minHeight;                      }
        else if((w > maxWidth) && (h > maxHeight)) {
                 if(maxWidth/w <= maxHeight/h)        { W = maxWidth,                       H = MAX(minHeight, maxWidth * h/w); }
            else if(maxWidth/w > maxHeight/h)         { W = MAX(minWidth, maxHeight * w/h), H = maxHeight;                      }
        }
        else if((w < minWidth) && (h < minHeight)) {
                 if(minWidth/w <= minHeight/h)        { W = MIN(maxWidth, minHeight * w/h), H = minHeight;                      }
            else if(minWidth/w > minHeight/h)         { W = minWidth,                       H = MIN(maxHeight, minWidth * h/w); }
        }
        else if((w < minWidth) && (h > maxHeight))    { W = minWidth,                       H = maxHeight;                      }
        else if((w > maxWidth) && (h < minHeight))    { W = maxWidth,                       H = minHeight;                      }
        else                                          { done = YES; }
    }
    
 
    return CGSizeMake(roundf(W), roundf(H));
}

- (void)_processSizeDependentComponentsAtIndexes:(NSArray *)sizeDependentComponentIndexes forFrame:(CGRect)frame
{
    EucCSSLayoutRunComponentInfo *componentInfos = _run.componentInfos;
    EucCSSLayoutSizedRunWidthInfo *componentWidthInfos = _componentWidthInfos;

    for(NSNumber *indexNumber in sizeDependentComponentIndexes) {
        NSUInteger index = [indexNumber unsignedIntegerValue];
        
        EucCSSIntermediateDocumentNode *subnode = componentInfos[index].documentNode;
        CGImageRef image = [subnode.document  imageForURL:componentInfos[index].contents.imageInfo.imageURL];
        
        CGFloat specifiedWidth = CGFLOAT_MAX;
        CGFloat specifiedHeight = CGFLOAT_MAX;
        
        CGFloat maxWidth = CGFLOAT_MAX;
        CGFloat maxHeight = CGFLOAT_MAX;
        
        CGFloat minWidth = 1;
        CGFloat minHeight = 1;
        
        CGFloat scaleFactor = self.scaleFactor;
        
        css_fixed length = 0;
        css_unit unit = (css_unit)0;
        css_computed_style *nodeStyle = subnode.computedStyle;
        if(nodeStyle) {
            uint8_t widthKind = css_computed_width(nodeStyle, &length, &unit);
            if(widthKind == CSS_WIDTH_SET) {
                specifiedWidth = EucCSSLibCSSSizeToPixels(nodeStyle, length, unit, frame.size.width, scaleFactor);
            }
            
            uint8_t maxWidthKind = css_computed_max_width(nodeStyle, &length, &unit);
            if (maxWidthKind == CSS_MAX_WIDTH_SET) {
                maxWidth = EucCSSLibCSSSizeToPixels(nodeStyle, length, unit, frame.size.width, scaleFactor);
            } 
            
            uint8_t heightKind = css_computed_height(nodeStyle, &length, &unit);
            if (heightKind == CSS_HEIGHT_SET) {
                if(unit == CSS_UNIT_PCT && frame.size.height == CGFLOAT_MAX) {
                    // Assume no intrinsic height;
                } else {
                    specifiedHeight = EucCSSLibCSSSizeToPixels(nodeStyle, length, unit, frame.size.height, scaleFactor);
                }
            } 
            
            uint8_t maxHeightKind = css_computed_max_height(nodeStyle, &length, &unit);
            if (maxHeightKind == CSS_MAX_HEIGHT_SET) {
                if(unit == CSS_UNIT_PCT && frame.size.height == CGFLOAT_MAX) {
                    // Assume no max height;
                } else {
                    maxHeight = EucCSSLibCSSSizeToPixels(nodeStyle, length, unit, frame.size.height, scaleFactor);
                }
            } 
        }
        
        maxWidth = MIN(maxWidth, frame.size.width);
        maxHeight= MIN(maxHeight, frame.size.height);
        
        CGSize calculatedSize = [self _computedSizeForImage:image
                                             specifiedWidth:specifiedWidth
                                            specifiedHeight:specifiedHeight
                                                   maxWidth:maxWidth
                                                   minWidth:minWidth
                                                  maxHeight:maxHeight
                                                  minHeight:minHeight];
        
        componentWidthInfos[index].size = CGSizeMake(calculatedSize.width, calculatedSize.height);
        
        /*if(css_computed_line_height(nodeStyle, &length, &unit) != CSS_LINE_HEIGHT_NORMAL) {
            componentInfos[index].contents.imageInfo.scaledLineHeight = EucCSSLibCSSSizeToPixels(nodeStyle, length, unit, calculatedSize.height, scaleFactor);
        } else {
            componentInfos[index].contents.imageInfo.scaledLineHeight = calculatedSize.height;
        }*/ 
    }
    
    _lastSizeDependentComponentCalculationFrame = frame;
}

- (EucCSSLayoutSizedRunWidthInfo *)componentWidthInfosForFrame:(CGRect)frame
{
    if(!_componentWidthInfos) {
        [self _processComponentsForWidths];
    } else if(THWillLog()) {
        if(_run.sizeDependentComponentIndexes && !CGRectEqualToRect(frame, _lastSizeDependentComponentCalculationFrame)) {
            THLog(@"Sized run resizing - was %@, now %@", 
                  NSStringFromCGRect(_lastSizeDependentComponentCalculationFrame), 
                  NSStringFromCGRect(frame));
        }
    }

    NSArray *sizeDependentComponentIndexes = _run.sizeDependentComponentIndexes;
    if(sizeDependentComponentIndexes && !CGRectEqualToRect(frame, _lastSizeDependentComponentCalculationFrame)) {
        [self _processSizeDependentComponentsAtIndexes:sizeDependentComponentIndexes forFrame:frame];
        if(_potentialBreaks) {
            free(_potentialBreaks);
            _potentialBreaks = NULL;
            free(_potentialBreakInfos);
            _potentialBreakInfos = NULL;
        }
    }
    return _componentWidthInfos;
}

- (THBreak *)_potentialBreaksForFrame:(CGRect)frame
{
    EucCSSLayoutSizedRunWidthInfo *componentWidthInfos = [self componentWidthInfosForFrame:frame];
    if(componentWidthInfos && !_potentialBreaks) {
        NSUInteger componentsCount = _run.componentsCount;
        EucCSSLayoutRunComponentInfo *componentInfos = _run.componentInfos;

        int breaksCapacity = componentsCount + 1;
        THBreak *breaks = (THBreak *)malloc(breaksCapacity * sizeof(THBreak));
        EucCSSLayoutSizedRunBreakInfo *breakInfos = (EucCSSLayoutSizedRunBreakInfo *)malloc(breaksCapacity * sizeof(EucCSSLayoutSizedRunBreakInfo));
        int breaksCount = 0;
        
        EucCSSIntermediateDocumentNode *currentInlineNodeWithStyle = _run.startNode;
        if(currentInlineNodeWithStyle.isTextNode) {
            currentInlineNodeWithStyle = currentInlineNodeWithStyle.parent;
        }
        
        enum css_white_space_e whiteSpaceModel = (enum css_white_space_e)css_computed_white_space(currentInlineNodeWithStyle.computedStyle);
        
        CGFloat lineSoFarWidth = 0.0f;
        CGFloat lastWordWidth = 0.0f;
        for(NSUInteger i = 0; i < componentsCount; ++i) {
            EucCSSLayoutRunComponentInfo componentInfo = componentInfos[i];
            switch(componentInfo.kind) {
                case EucCSSLayoutRunComponentKindSpace:
                case EucCSSLayoutRunComponentKindNonbreakingSpace:
                {
                    if(whiteSpaceModel != CSS_WHITE_SPACE_PRE && 
                       whiteSpaceModel != CSS_WHITE_SPACE_NOWRAP) {
                        breaks[breaksCount].x0 = lineSoFarWidth;
                        lineSoFarWidth += componentWidthInfos[i].width;
                        breaks[breaksCount].x1 = lineSoFarWidth;
                        breaks[breaksCount].penalty = componentInfo.kind == EucCSSLayoutRunComponentKindNonbreakingSpace ? 1024 : 0;
                        breaks[breaksCount].flags = TH_JUST_WITH_FLOATS_FLAG_ISSPACE;
                        breakInfos[breaksCount].point = componentInfos[i].point;
                        breakInfos[breaksCount].consumesComponent = YES;
                        ++breaksCount;
                    }
                }
                    break;
                case EucCSSLayoutRunComponentKindHardBreak:
                {
                    breaks[breaksCount].x0 = lineSoFarWidth;
                    lineSoFarWidth += componentWidthInfos[i].width;
                    breaks[breaksCount].x1 = lineSoFarWidth;
                    breaks[breaksCount].penalty = 0;
                    breaks[breaksCount].flags = TH_JUST_WITH_FLOATS_FLAG_ISHARDBREAK;
                    breakInfos[breaksCount].point = componentInfos[i].point;
                    breakInfos[breaksCount].consumesComponent = YES;
                    ++breaksCount;                                        
                }
                    break;
                case EucCSSLayoutRunComponentKindOpenNode:
                {
                    currentInlineNodeWithStyle = componentInfos[i].documentNode;
                    whiteSpaceModel = (enum css_white_space_e)css_computed_white_space(currentInlineNodeWithStyle.computedStyle);
                }
                    break;
                case EucCSSLayoutRunComponentKindCloseNode:
                {
                    NSParameterAssert(componentInfos[i].documentNode == currentInlineNodeWithStyle);
                    currentInlineNodeWithStyle = currentInlineNodeWithStyle.parent;
                    whiteSpaceModel = (enum css_white_space_e)css_computed_white_space(currentInlineNodeWithStyle.computedStyle);
                }
                    break;
                case EucCSSLayoutRunComponentKindWord:
                {
                    lastWordWidth = componentWidthInfos[i].width;
                    lineSoFarWidth += lastWordWidth;
                }
                    break;
                case EucCSSLayoutRunComponentKindHyphenationRule:
                {
                    breaks[breaksCount].x0 = lineSoFarWidth + componentWidthInfos[i].hyphenWidths.widthBeforeHyphen - lastWordWidth;
                    breaks[breaksCount].x1 = lineSoFarWidth - componentWidthInfos[i].hyphenWidths.widthAfterHyphen;
                    breaks[breaksCount].penalty = 0;
                    breaks[breaksCount].flags = TH_JUST_WITH_FLOATS_FLAG_ISHYPHEN;
                    breakInfos[breaksCount].point = componentInfos[i].point;
                    breakInfos[breaksCount].consumesComponent = NO;
                    ++breaksCount;                                                                
                }
                    break;
                default:
                    lineSoFarWidth += componentWidthInfos[i].width;
            }
            
            if(breaksCount >= breaksCapacity) {
                breaksCapacity += componentsCount;
                breaks = (THBreak *)realloc(breaks, breaksCapacity * sizeof(THBreak));
                breakInfos = (EucCSSLayoutSizedRunBreakInfo *)realloc(breakInfos, breaksCapacity * sizeof(EucCSSLayoutSizedRunBreakInfo));
            }                                            
        }
        breaks[breaksCount].x0 = lineSoFarWidth;
        breaks[breaksCount].x1 = lineSoFarWidth;
        breaks[breaksCount].penalty = 0;
        if(_run.textAlign == CSS_TEXT_ALIGN_CENTER) {
            // With a non-hard break at the end, the justifier will distribute
            // the words evenly across all lines, giving a more pleasing
            // centered block.
            breaks[breaksCount].flags = 0;
        } else {
            breaks[breaksCount].flags = TH_JUST_WITH_FLOATS_FLAG_ISHARDBREAK;
        }
        breakInfos[breaksCount].point.word = _run.wordsCount + 1;
        breakInfos[breaksCount].point.element = 0;
        breakInfos[breaksCount].consumesComponent = NO;
        ++breaksCount;
        
        _potentialBreaks = breaks;
        _potentialBreaksCount = breaksCount;
        _potentialBreakInfos = breakInfos;
    }
    return _potentialBreaks;
}

- (EucCSSLayoutPositionedRun *)positionRunForFrame:(CGRect)frame
                                       inContainer:(EucCSSLayoutPositionedContainer *)container
                              startingAtWordOffset:(uint32_t)wordOffset 
                                     elementOffset:(uint32_t)elementOffset
                            usingLayouterForFloats:(EucCSSLayouter *)layouter
{
    NSUInteger componentsCount = _run.componentsCount;    
    if(componentsCount == 0) {
        return nil;
    }    
        
    EucCSSLayoutPositionedRun *ret = [[EucCSSLayoutPositionedRun alloc] initWithSizedRun:self];
    
    EucCSSLayoutRunComponentInfo *componentInfos = _run.componentInfos;
    THBreak *potentialBreaks = [self _potentialBreaksForFrame:frame];
    
    CGFloat textIndent;
    if(elementOffset == 0 && wordOffset == 0) {
        textIndent = [_run textIndentInWidth:frame.size.width initWithScaleFactor:self.scaleFactor];
    } else {
        textIndent = 0.0f;
    }
    
    NSMutableArray *lines = [[NSMutableArray alloc] init];
    CGPoint lineOrigin = CGPointZero;
    CGFloat lastLineMaxY = 0;
    
    BOOL firstTryAtLine = YES;
    CGFloat thisLineWidth = frame.size.width;
    
    uint8_t textAlign = [_run textAlign];
    
    NSArray *floatComponentIndexes = _run.floatComponentIndexes;
    NSUInteger floatComponentIndexesOffset = NSUIntegerMax;
    NSUInteger nextFloatComponentOffset = NSUIntegerMax;
    if(floatComponentIndexes) {
        floatComponentIndexesOffset = 0;
        nextFloatComponentOffset = [[floatComponentIndexes objectAtIndex:floatComponentIndexesOffset] integerValue];
    } 
    
    BOOL widthChanged;
    do {
        widthChanged = NO;
        
        NSUInteger startBreakOffset = 0;
        for(;;) {
            EucCSSLayoutRunPoint point = _potentialBreakInfos[startBreakOffset].point;
            if(startBreakOffset < _potentialBreaksCount && 
               (point.word < wordOffset || (point.word == wordOffset && point.element < elementOffset))) {
                ++startBreakOffset;
            } else {
                break;
            }
        }        
        if(startBreakOffset >= _potentialBreaksCount) {
            break;
        }
        int maxBreaksCount = _potentialBreaksCount - startBreakOffset;
        
        // Work out an offset to compensate the pre-calculated 
        // line lengths in the breaks array.
        CGFloat alreadyUsedComponentWidth;
        uint32_t lineStartComponent;
        if(startBreakOffset) {
            alreadyUsedComponentWidth = potentialBreaks[startBreakOffset - 1].x1;
            
            EucCSSLayoutRunPoint point = { wordOffset, elementOffset };
            lineStartComponent = [_run pointToComponentOffset:point];
        } else {
            alreadyUsedComponentWidth = 0;
            lineStartComponent = 0;
        }
        
        int *usedBreakIndexes = (int *)malloc(maxBreaksCount * sizeof(int));
        int usedBreakCount = th_just_with_floats(potentialBreaks + startBreakOffset, maxBreaksCount, textIndent - alreadyUsedComponentWidth, thisLineWidth, 0, usedBreakIndexes);
        
        EucCSSLayoutSizedRunBreakInfo lastLineBreakInfo = { componentInfos[lineStartComponent].point, NO };
        
        int lastBreakIndex = INT_MAX;
        for(int i = 0; i < usedBreakCount && !widthChanged; ++i) {
            int thisBreakIndex = usedBreakIndexes[i] + startBreakOffset;
            EucCSSLayoutSizedRunBreakInfo thisLineBreakInfo = _potentialBreakInfos[thisBreakIndex];
            EucCSSLayoutPositionedLine *newLine = [[EucCSSLayoutPositionedLine alloc] init];
            newLine.parent = ret;
            
            EucCSSLayoutRunPoint lineStartPoint;
            EucCSSLayoutRunPoint lineEndPoint;
            
            if(lastLineBreakInfo.consumesComponent) {
                EucCSSLayoutRunPoint point = lastLineBreakInfo.point;
                uint32_t componentOffset = [_run pointToComponentOffset:point];
                ++componentOffset;
                if(componentOffset >= componentsCount) {
                    // This is off the end of the components array.
                    // This must be an empty line at the end of a run.
                    // We remove this - the only way it can happen is if the last
                    // line ends in a newline (e.g. <br>), and we're about to add
                    // an implicit newline at the end of the block anyway.
                    [newLine release];        
                    break;
                } else {
                    lineStartPoint = componentInfos[componentOffset].point;
                }
            } else {
                lineStartPoint = lastLineBreakInfo.point;
            }
            lineEndPoint = thisLineBreakInfo.point;
            
            newLine.startPoint = lineStartPoint;
            newLine.endPoint = lineEndPoint;
            
            CGFloat lineComponentWidth;
            lineComponentWidth = potentialBreaks[thisBreakIndex].x0;
            if(lastBreakIndex == INT_MAX) {
                lineComponentWidth -= alreadyUsedComponentWidth;
            } else {
                lineComponentWidth -= potentialBreaks[lastBreakIndex].x1;
            }
            newLine.componentWidth = lineComponentWidth;
            
            newLine.frame = CGRectMake(lineOrigin.x, lineOrigin.y, 0, 0);
            
            [newLine sizeToFitInWidth:thisLineWidth parentFrame:frame];            
            
            if(nextFloatComponentOffset != NSUIntegerMax && 
               nextFloatComponentOffset >= [_run pointToComponentOffset:lineStartPoint] &&
               nextFloatComponentOffset < [_run pointToComponentOffset:lineEndPoint]) {
                // A float is on this line.  Place the float.
                
                BOOL completed = NO;
                EucCSSLayoutPoint returnedPoint = { 0 };
                
                EucCSSIntermediateDocumentNode *floatNode = componentInfos[nextFloatComponentOffset].documentNode;
                
                EucCSSLayoutPoint floatPoint = { floatNode.key, 0, 0 };
                CGRect floatPotentialFrame = CGRectMake(0, 0, frame.size.width, CGFLOAT_MAX);
                EucCSSLayoutPositionedBlock *floatBlock = [layouter _layoutFromPoint:floatPoint
                                                                             inFrame:floatPotentialFrame
                                                                  returningNextPoint:&returnedPoint
                                                                  returningCompleted:&completed 
                                                                    lastBlockNodeKey:floatPoint.nodeKey
                                                               stopBeforeNodeWithKey:0
                                                               constructingAncestors:NO
                                                                         scaleFactor:_scaleFactor];
                
                [floatBlock shrinkToFit];       
                
                [container addFloatChild:floatBlock 
                              atContentY:lineOrigin.y
                                  onLeft:css_computed_float(floatNode.computedStyle) == CSS_FLOAT_LEFT];
                
                if(THWillLog()) {
                    // Sanity check - was this consumed properly?
                    NSParameterAssert(completed == YES);
                    EucCSSIntermediateDocumentNode *afterFloat = [floatNode.parent displayableNodeAfter:floatNode
                                                                                                  under:nil];
                    NSParameterAssert(returnedPoint.nodeKey == afterFloat.key);
                }    
                
                // This float is consumed!
                ++floatComponentIndexesOffset;
                if(floatComponentIndexesOffset >= floatComponentIndexes.count) {
                    nextFloatComponentOffset = NSUIntegerMax;
                } else {
                    nextFloatComponentOffset = [[floatComponentIndexes objectAtIndex:floatComponentIndexesOffset] integerValue];
                }
            }
            
            if(textIndent) {
                newLine.indent = textIndent;
                textIndent = 0.0f;
            }
            if(textAlign == CSS_TEXT_ALIGN_JUSTIFY &&
               (potentialBreaks[thisBreakIndex].flags & TH_JUST_WITH_FLOATS_FLAG_ISHARDBREAK) == TH_JUST_WITH_FLOATS_FLAG_ISHARDBREAK) {
                newLine.align = CSS_TEXT_ALIGN_DEFAULT;
            } else {
                newLine.align = textAlign;
            }
            
            
            // Calculate available width for line of this height.
            
            CGFloat availableWidth;
            THPair *floats = [container floatsOverlappingYPoint:lineOrigin.y + frame.origin.y 
                                                         height:newLine.frame.size.height];
            if(floats) {
                CGFloat leftX = 0;
                CGFloat rightX = frame.size.width;
                for(EucCSSLayoutPositionedContainer *thisFloat in floats.first) {
                    CGRect floatFrame = [thisFloat frameInRelationTo:container];;
                    CGFloat floatMaxX = CGRectGetMaxX(floatFrame);
                    if(floatMaxX > leftX) {
                        leftX = floatMaxX;
                    }
                }
                for(EucCSSLayoutPositionedContainer *thisFloat in floats.second) {
                    CGRect floatFrame = [thisFloat frameInRelationTo:container];
                    CGFloat floatMinX = CGRectGetMinX(floatFrame);
                    if(floatMinX < rightX) {
                        rightX = floatMinX;
                    }
                }
                availableWidth = rightX - leftX;
                
                CGRect newlineFrame = newLine.frame;
                newlineFrame.origin.x = leftX;
                newLine.frame = newlineFrame;
            } else {
                availableWidth = frame.size.width;
            }
            
            // Is the available width != the used width?
            if(availableWidth != thisLineWidth) {                 
                THLogVerbose(@"Recalculating for float");
                if(firstTryAtLine) {
                    // We'll loop and try this line again with the real available width.
                    thisLineWidth = availableWidth;
                    firstTryAtLine = NO;
                } else {
                    // We can't fit this line in the width.
                    // We'll loop and try this line again after the first float
                    // ends.
                    CGFloat nextY = CGFLOAT_MAX;
                    
                    for(EucCSSLayoutPositionedContainer *thisFloat in floats.first) {
                        CGRect floatFrame = thisFloat.frame;
                        CGFloat floatMaxY = CGRectGetMaxY([thisFloat frameInRelationTo:container]);
                        floatMaxY -= floatFrame.origin.y;
                        if(floatMaxY < nextY) {
                            nextY = floatMaxY;
                        }
                    }
                    for(EucCSSLayoutPositionedContainer *thisFloat in floats.second) {
                        CGRect floatFrame = thisFloat.frame;
                        CGFloat floatMaxY = CGRectGetMaxY([thisFloat frameInRelationTo:container]);
                        floatMaxY -= floatFrame.origin.y;
                        if(floatMaxY < nextY) {
                            nextY = floatMaxY;
                        }
                    }
                    lineOrigin.y = nextY;
                    firstTryAtLine = YES;
                }
                
                wordOffset = newLine.startPoint.word;
                elementOffset = newLine.startPoint.element;
                
                widthChanged = YES;
            } else {
                if(newLine.componentWidth != 0) {
                    lastLineMaxY = lineOrigin.y + newLine.frame.size.height;
                    [lines addObject:newLine];
                    
                    lineOrigin.y = lastLineMaxY;
                }
                lastLineBreakInfo = thisLineBreakInfo;
                lastBreakIndex = thisBreakIndex;
                if(!firstTryAtLine) {
                    firstTryAtLine = YES;
                }
            } 
            [newLine release];        
        }
        
        free(usedBreakIndexes);
    } while(widthChanged);
    
    if(lines.count) {
        ret.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, lastLineMaxY);
        ret.children = lines;
    } else {
        [ret release];
        ret = nil;
    }
    
    [lines release];
    
    if(ret) {
        [container addChild:ret];
    }
    
    return [ret autorelease];
}

- (CGFloat)minWidth
{
    THBreak *potentialBreaks = [self _potentialBreaksForFrame:CGRectMake(0, 0, 0, CGFLOAT_MAX)];
    
    CGFloat minWidth = 0;
    int potentialBreaksCount = _potentialBreaksCount;

    CGFloat lastX1 = 0;
    for(int i = 0; i < potentialBreaksCount; ++i) {
        CGFloat thisWidth = potentialBreaks[i].x0 - lastX1;
        if(thisWidth > minWidth) {
            minWidth = thisWidth;
        }
        lastX1 = potentialBreaks[i].x1;
    }
    
    return minWidth;
}

- (CGFloat)maxWidth
{
    THBreak *potentialBreaks = [self _potentialBreaksForFrame:CGRectMake(0, 0, CGFLOAT_MAX, CGFLOAT_MAX)];
    
    CGFloat maxWidth = 0;
    int potentialBreaksCount = _potentialBreaksCount;

    CGFloat lastX1 = 0;
    for(int i = 0; i < potentialBreaksCount; ++i) {
        if((potentialBreaks[i].flags & TH_JUST_WITH_FLOATS_FLAG_ISHARDBREAK) == TH_JUST_WITH_FLOATS_FLAG_ISHARDBREAK) {
            CGFloat thisWidth = potentialBreaks[i].x0 - lastX1;
            if(thisWidth > maxWidth) {
                maxWidth = thisWidth;
            }
            lastX1 = potentialBreaks[i].x1;
        }
    }
    
    return maxWidth;
}

@end