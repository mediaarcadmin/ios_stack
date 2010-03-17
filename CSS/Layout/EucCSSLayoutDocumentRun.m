//
//  EucCSSLayoutDocumentRun.m
//  LibCSSTest
//
//  Created by James Montgomerie on 12/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayouter_Package.h"
#import "EucCSSLayoutDocumentRun.h"
#import "EucCSSLayoutDocumentRun_Package.h"
#import "EucCSSLayoutPositionedRun.h"
#import "EucCSSLayoutLine.h"
#import "EucCSSIntermediateDocument.h"
#import "EucCSSIntermediateDocument_Package.h"
#import "EucCSSIntermediateDocumentConcreteNode.h"
#import "EucCSSIntermediateDocumentGeneratedTextNode.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "THStringRenderer.h"
#import "THLog.h"
#import "th_just_with_floats.h"

#import <libcss/libcss.h>

static id sSingleSpaceMarker;
static id sOpenNodeMarker;
static id sCloseNodeMarker;
static id sHardBreakMarker;

typedef struct EucCSSLayoutDocumentRunBreakInfo {
    EucCSSLayoutDocumentRunPoint point;
    BOOL isComponent;
} EucCSSLayoutDocumentRunBreakInfo;

@interface EucCSSLayoutDocumentRun ()
- (void)_populateComponentInfo:(EucCSSLayoutDocumentRunComponentInfo *)info 
                       forNode:(EucCSSIntermediateDocumentNode *)subnode;
- (void)_addComponent:(id)component isWord:(BOOL)isWord info:(EucCSSLayoutDocumentRunComponentInfo *)size;
- (void)_accumulateTextNode:(EucCSSIntermediateDocumentNode *)subnode;
- (void)_accumulateImageNode:(EucCSSIntermediateDocumentNode *)subnode;
- (CGFloat)_textIndentInWidth:(CGFloat)width;
@end 

@implementation EucCSSLayoutDocumentRun

@synthesize components = _components;
@synthesize componentInfos = _componentInfos;
@synthesize componentsCount = _componentsCount;
@synthesize wordToComponent = _wordToComponent;

+ (void)initialize
{
    sSingleSpaceMarker = (id)kCFNull;
    sOpenNodeMarker = [[NSObject alloc] init];
    sCloseNodeMarker = [[NSObject alloc] init];
    sHardBreakMarker = [[NSObject alloc] init];
}

+ (id)singleSpaceMarker
{
    return sSingleSpaceMarker;
}

+ (id)openNodeMarker
{
    return sOpenNodeMarker;
}

+ (id)closeNodeMarker
{
    return sCloseNodeMarker;
}

+ (id)hardBreakMarker
{
    return sHardBreakMarker;
}

@synthesize id = _id;
@synthesize nextNodeUnderLimitNode = _nextNodeUnderLimitNode;
@synthesize nextNodeInDocument = _nextNodeInDocument;

- (id)initWithNode:(EucCSSIntermediateDocumentNode *)inlineNode 
    underLimitNode:(EucCSSIntermediateDocumentNode *)underNode
             forId:(uint32_t)id
       scaleFactor:(CGFloat)scaleFactor
{
    if((self = [super init])) {
        _id = id;
        
        _scaleFactor = scaleFactor;
        
        _startNode = [inlineNode retain];
        css_computed_style *inlineNodeStyle = inlineNode.computedStyle;
        
        // _wordToComponent is 1-indexed for words - word '0' is the start of 
        // this run - so set that up now.
        _wordToComponentCapacity = 128;
        _wordToComponent = malloc(_wordToComponentCapacity * sizeof(uint32_t));
        _wordToComponent[0] = 0;         
        
        BOOL reachedLimit = NO;
        
        EucCSSLayoutDocumentRunComponentInfo currentComponentInfo = {0};
        
        while (!reachedLimit && 
               inlineNode && 
               (inlineNode.isTextNode || (inlineNodeStyle &&
                                          //css_computed_float(inlineNodeStyle) == CSS_FLOAT_NONE &&
                                          (css_computed_display(inlineNodeStyle, false) & CSS_DISPLAY_BLOCK) != CSS_DISPLAY_BLOCK))) {
            if(inlineNode.isTextNode) {
                [self _accumulateTextNode:inlineNode];
            } else if(inlineNode.isImageNode) {
                [self _accumulateImageNode:inlineNode];
            } else {
                // Open this node.
                [self _populateComponentInfo:&currentComponentInfo forNode:inlineNode];
                [self _addComponent:[EucCSSLayoutDocumentRun openNodeMarker] isWord:NO info:&currentComponentInfo];
                if(inlineNode.childrenCount == 0) {
                    [self _addComponent:[EucCSSLayoutDocumentRun closeNodeMarker] isWord:NO info:&currentComponentInfo];
                }
            }
            
            EucCSSIntermediateDocumentNode *nextNode = [inlineNode nextDisplayableUnder:inlineNode.parent];
            if(!nextNode) {
                // Close this node.
                if(!inlineNode.isTextNode && inlineNode.childrenCount > 0) {
                    // If the node /doesn't/ have children, it's already closed,
                    // above.
                    [self _addComponent:[EucCSSLayoutDocumentRun closeNodeMarker] isWord:NO info:&currentComponentInfo];
                    [self _populateComponentInfo:&currentComponentInfo forNode:inlineNode.parent];
                }
                nextNode = [inlineNode nextDisplayableUnder:underNode];
            }
            if(nextNode) {
                inlineNode = nextNode;
                inlineNodeStyle = inlineNode.computedStyle;
            } else {
                inlineNode = inlineNode.nextDisplayable;
                reachedLimit = YES;
            }
        }    
        
        if(!reachedLimit) {
            _nextNodeUnderLimitNode = [inlineNode retain];
        } 
        _nextNodeInDocument = [inlineNode retain];
    }
    return self;
}

- (void)dealloc
{
    for(int i = 0; i < _componentsCount; ++i) {
        [_components[i] release];
    }
    free(_components);
    free(_componentInfos);
    free(_wordToComponent);
    
    free(_potentialBreaks);
    free(_potentialBreakInfos);

    [_startNode release];
    [_nextNodeUnderLimitNode release];
    [_nextNodeInDocument release];

    [_sizeDependentComponentIndexes release];
    
    [super dealloc];
}

- (CGFloat)_textIndentInWidth:(CGFloat)width;
{
    CGFloat ret = 0.0f;
    
    css_computed_style *style = _startNode.blockLevelNode.computedStyle;
    if(style) {
        css_fixed length = 0;
        css_unit unit = 0;
        css_computed_text_indent(style, &length, &unit);
        ret = EucCSSLibCSSSizeToPixels(style, length, unit, width, _scaleFactor);
    }
    return ret;
}

- (uint8_t)_textAlign;
{
    uint8_t ret = CSS_TEXT_ALIGN_DEFAULT;
    
    css_computed_style *style = _startNode.blockLevelNode.computedStyle;
    if(style) {
        ret = css_computed_text_align(style);
    }
    return ret;
}

- (void)_addComponent:(id)component isWord:(BOOL)isWord info:(EucCSSLayoutDocumentRunComponentInfo *)info
{

    if(isWord) {
        ++_wordsCount;
        if(_wordToComponentCapacity == _wordsCount) {
            _wordToComponentCapacity += 128;
            _wordToComponent = realloc(_wordToComponent, _wordToComponentCapacity * sizeof(uint32_t));
        }
        _wordToComponent[_wordsCount] = _componentsCount;
        _currentWordElementCount = 0;
    }
    
    if(_componentsCapacity == _componentsCount) {
        _componentsCapacity += 128;
        _components = realloc(_components, _componentsCapacity * sizeof(id));
        _componentInfos = realloc(_componentInfos, _componentsCapacity * sizeof(EucCSSLayoutDocumentRunComponentInfo));
    }
    
    info->point.word = _wordsCount;
    info->point.element = _currentWordElementCount;
    
    _components[_componentsCount] = [component retain];
    _componentInfos[_componentsCount] = *info;
    
    
    ++_componentsCount;
    ++_currentWordElementCount;
}

- (CGSize)_computedSizeForImage:(UIImage *)image
                 specifiedWidth:(CGFloat)specifiedWidth
                specifiedHeight:(CGFloat)specifiedHeight
                       maxWidth:(CGFloat)maxWidth
                       minWidth:(CGFloat)minWidth
                      maxHeight:(CGFloat)maxHeight
                      minHeight:(CGFloat)minHeight
{
    CGSize imageSize = image.size;

    // Sanitise the input.
    if(minHeight > maxHeight) {
        maxHeight = minHeight;
    }
    if(minWidth > maxWidth) {
        maxWidth = minWidth;
    }
    
    // Work out the size.
    CGSize computedSize;
    if(specifiedWidth != CGFLOAT_MAX && 
       specifiedHeight != CGFLOAT_MAX) {
        computedSize.width = specifiedWidth;
        computedSize.height = specifiedHeight;
    } else if(specifiedWidth == CGFLOAT_MAX && specifiedHeight != CGFLOAT_MAX) {
        computedSize.height = specifiedHeight;
        computedSize.width = specifiedHeight * (imageSize.width / imageSize.height);
    } else if(specifiedWidth != CGFLOAT_MAX && specifiedHeight == CGFLOAT_MAX){
        computedSize.width = specifiedWidth;
        computedSize.height = specifiedWidth * (imageSize.height / imageSize.width);
    } else {
        computedSize = imageSize;
    }
           
    computedSize.width = roundf(computedSize.width);
    computedSize.height = roundf(computedSize.height);
    
    // Re-run to work out conflicts.
    if(computedSize.width > maxWidth) {
        return [self _computedSizeForImage:image
                            specifiedWidth:maxWidth
                           specifiedHeight:specifiedHeight 
                                  maxWidth:maxWidth
                                  minWidth:minWidth 
                                 maxHeight:maxHeight
                                 minHeight:minHeight];
    }
    
    if(computedSize.width < minWidth) {
        return [self _computedSizeForImage:image
                            specifiedWidth:minWidth
                           specifiedHeight:specifiedHeight 
                                  maxWidth:maxWidth
                                  minWidth:minWidth 
                                 maxHeight:maxHeight
                                 minHeight:minHeight];
    }
    
    if(computedSize.height > maxHeight) {
        return [self _computedSizeForImage:image
                            specifiedWidth:specifiedHeight
                           specifiedHeight:maxHeight 
                                  maxWidth:maxWidth
                                  minWidth:minWidth 
                                 maxHeight:maxHeight
                                 minHeight:minHeight];
    }
    
    if(computedSize.height < minHeight) {
        return [self _computedSizeForImage:image
                            specifiedWidth:specifiedHeight
                           specifiedHeight:minHeight 
                                  maxWidth:maxWidth
                                  minWidth:minWidth 
                                 maxHeight:maxHeight
                                 minHeight:minHeight];
    }
    
    return computedSize;
}

- (void)_accumulateImageNode:(EucCSSIntermediateDocumentNode *)subnode
{
    NSData *imageData = [subnode.document.dataSource dataForURL:[subnode imageSrc]];

    if(imageData) {
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        
        if(image) {
            EucCSSLayoutDocumentRunComponentInfo info = { 0 };
            info.documentNode = subnode;
            
            [self _addComponent:image isWord:NO info:&info];
            
            if(!_sizeDependentComponentIndexes) {
                _sizeDependentComponentIndexes = [[NSMutableArray alloc] init];
            }
            [_sizeDependentComponentIndexes addObject:[NSNumber numberWithInteger:_componentsCount - 1]];
            
            _previousInlineCharacterWasSpace = NO;
            
            [image release];
        }
    }
}

- (void)_recalculateSizeDependentComponentSizesForFrame:(CGRect)frame
{
    for(NSNumber *indexNumber in _sizeDependentComponentIndexes) {
        size_t offset = [indexNumber integerValue];
        
        UIImage *image = _components[offset];
        EucCSSIntermediateDocumentNode *subnode = _componentInfos[offset].documentNode;
        
        CGFloat specifiedWidth = CGFLOAT_MAX;
        CGFloat specifiedHeight = CGFLOAT_MAX;
        
        CGFloat maxWidth = CGFLOAT_MAX;
        CGFloat maxHeight = CGFLOAT_MAX;
        
        CGFloat minWidth = 1;
        CGFloat minHeight = 1;
        
        css_fixed length = 0;
        css_unit unit = 0;
        css_computed_style *nodeStyle = subnode.computedStyle;
        if(nodeStyle) {
            uint8_t widthKind = css_computed_width(nodeStyle, &length, &unit);
            if(widthKind == CSS_WIDTH_SET) {
                specifiedWidth = EucCSSLibCSSSizeToPixels(nodeStyle, length, unit, frame.size.width, _scaleFactor);
            }
            
            uint8_t maxWidthKind = css_computed_max_width(nodeStyle, &length, &unit);
            if (maxWidthKind == CSS_MAX_WIDTH_SET) {
                maxWidth = EucCSSLibCSSSizeToPixels(nodeStyle, length, unit, frame.size.width, _scaleFactor);
            } 
            
            uint8_t heightKind = css_computed_height(nodeStyle, &length, &unit);
            if (heightKind == CSS_HEIGHT_SET) {
                if(unit == CSS_UNIT_PCT) {
                    // Assume no intrinsic height;
                } else {
                    specifiedHeight = EucCSSLibCSSSizeToPixels(nodeStyle, length, unit, 0, _scaleFactor);
                }
            } 
        
            uint8_t maxHeightKind = css_computed_max_height(nodeStyle, &length, &unit);
            if (maxHeightKind == CSS_MAX_HEIGHT_SET) {
                if(unit == CSS_UNIT_PCT) {
                    // Assume no max height;
                } else {
                    maxHeight = EucCSSLibCSSSizeToPixels(nodeStyle, length, unit, 0, _scaleFactor);
                }
            } 
        }
        
        CGSize calculatedSize = [self _computedSizeForImage:image
                                             specifiedWidth:specifiedWidth
                                            specifiedHeight:specifiedHeight
                                                   maxWidth:maxWidth
                                                   minWidth:minWidth
                                                  maxHeight:maxHeight
                                                  minHeight:minHeight];
        
        _componentInfos[offset].width = calculatedSize.width;
        _componentInfos[offset].ascender = calculatedSize.height;
        _componentInfos[offset].pointSize = calculatedSize.height;
        
        if(css_computed_line_height(nodeStyle, &length, &unit) != CSS_LINE_HEIGHT_NORMAL) {
            _componentInfos[offset].lineHeight = EucCSSLibCSSSizeToPixels(nodeStyle, length, unit, calculatedSize.height, _scaleFactor);
        } else {
            _componentInfos[offset].lineHeight = calculatedSize.height;
        }            
    }
}

- (void)_populateComponentInfo:(EucCSSLayoutDocumentRunComponentInfo *)info 
                       forNode:(EucCSSIntermediateDocumentNode *)subnode 
{
    css_computed_style *subnodeStyle = subnode.computedStyle;
    if(!subnodeStyle) {
        subnodeStyle = [subnode.parent computedStyle];
    }
    THStringRenderer *stringRenderer = subnode.stringRenderer;

    css_fixed length = 0;
    css_unit unit = 0;
    css_computed_font_size(subnodeStyle, &length, &unit);
    CGFloat fontPixelSize = EucCSSLibCSSSizeToPixels(subnodeStyle, length, unit, 0, _scaleFactor);    
    
    info->pointSize = fontPixelSize;
    info->ascender = [stringRenderer ascenderForPointSize:fontPixelSize];

    if(css_computed_line_height(subnodeStyle, &length, &unit) != CSS_LINE_HEIGHT_NORMAL) {
        info->lineHeight = EucCSSLibCSSSizeToPixels(subnodeStyle, length, unit, fontPixelSize, _scaleFactor);
    } else {
        info->lineHeight = [stringRenderer lineSpacingForPointSize:fontPixelSize];
    }
    info->width = 0;
    info->documentNode = subnode;
}


- (void)_accumulateTextNode:(EucCSSIntermediateDocumentNode *)subnode 
{
    css_computed_style *subnodeStyle;
    subnodeStyle = [subnode.parent computedStyle];
    
    enum css_white_space_e whiteSpaceModel = css_computed_white_space(subnodeStyle);
    
    THStringRenderer *stringRenderer = subnode.stringRenderer;
    
    css_fixed length = 0;
    css_unit unit = 0;
    css_computed_font_size(subnodeStyle, &length, &unit);
    
    // The font size percentages should already be fully resolved.
    CGFloat fontPixelSize = EucCSSLibCSSSizeToPixels(subnodeStyle, length, unit, 0, _scaleFactor);             

    EucCSSLayoutDocumentRunComponentInfo spaceInfo = { 0 };
    [self _populateComponentInfo:&spaceInfo forNode:subnode];
    spaceInfo.width = [stringRenderer widthOfString:@" " pointSize:fontPixelSize];
    
    
    CFStringRef text = (CFStringRef)subnode.text;
    CFIndex textLength = CFStringGetLength(text);
    
    if(textLength) {
        UniChar *charactersToFree = NULL;
        const UniChar *characters = CFStringGetCharactersPtr(text);
        if(characters == NULL) {
            // CFStringGetCharactersPtr may return NULL at any time.
            charactersToFree = malloc(sizeof(UniChar) * textLength);
            CFStringGetCharacters(text,
                                  CFRangeMake(0, textLength),
                                  charactersToFree);
            characters = charactersToFree;
        }
        
        const UniChar *cursor = characters;
        const UniChar *end = characters + textLength;
        
        const UniChar *wordStart = cursor;
        
        BOOL sawNewline = NO;
        while(cursor < end) {
            UniChar ch = *cursor;
            switch(ch) {
                case 0x000A: // LF
                case 0x000D: // CR
                    if(!sawNewline) {
                        sawNewline = YES;
                    }
                    // No break - fall through.
                case 0x0009: // tab
                case 0x0020: // Space
                    if(!_previousInlineCharacterWasSpace) {
                        if(wordStart != cursor) {
                            CFStringRef string = CFStringCreateWithCharacters(kCFAllocatorDefault,
                                                                              wordStart, 
                                                                              cursor - wordStart);
                            if(string) {
                                EucCSSLayoutDocumentRunComponentInfo info = spaceInfo;
                                info.width = [stringRenderer widthOfString:(NSString *)string pointSize:fontPixelSize];
                                [self _addComponent:(id)string isWord:YES info:&info];
                                CFRelease(string);
                            }
                        }
                        _previousInlineCharacterWasSpace = YES;
                    }
                    if(ch == 0x000A && 
                       (whiteSpaceModel == CSS_WHITE_SPACE_PRE_LINE ||
                        whiteSpaceModel == CSS_WHITE_SPACE_PRE ||
                        whiteSpaceModel == CSS_WHITE_SPACE_PRE_WRAP)) {
                           EucCSSLayoutDocumentRunComponentInfo info = spaceInfo;
                           info.width = 0;
                           [self _addComponent:[EucCSSLayoutDocumentRun hardBreakMarker] isWord:NO info:&info];
                           _alreadyInsertedSpace = YES;
                    }
                    break;
                default:
                    if(_previousInlineCharacterWasSpace) {
                        if(!_alreadyInsertedSpace) {
                            [self _addComponent:[EucCSSLayoutDocumentRun singleSpaceMarker] isWord:NO info:&spaceInfo];
                        } else {
                            _alreadyInsertedSpace = NO;
                        }
                        wordStart = cursor;
                        _previousInlineCharacterWasSpace = NO;
                    }
            }
            ++cursor;
        }
        if(!_previousInlineCharacterWasSpace) {
            CFStringRef string = CFStringCreateWithCharacters(kCFAllocatorDefault,
                                                              wordStart, 
                                                              cursor - wordStart);
            if(string) {
                EucCSSLayoutDocumentRunComponentInfo info = spaceInfo;
                info.width = [stringRenderer widthOfString:(NSString *)string pointSize:fontPixelSize];
                [self _addComponent:(id)string isWord:YES info:&info];
                CFRelease(string);
            }
        } 
        if(_previousInlineCharacterWasSpace) {
            if(!_alreadyInsertedSpace) {
                [self _addComponent:[EucCSSLayoutDocumentRun singleSpaceMarker] isWord:NO info:&spaceInfo];
                _alreadyInsertedSpace = YES;
            }
        }
        
        if(charactersToFree) {
            free(charactersToFree);
        }
    }
}

- (void)_ensurePotentialBreaksCalculated
{
    if(!_potentialBreaks) {
        int breaksCapacity = _componentsCount;
        THBreak *breaks = malloc(breaksCapacity * sizeof(THBreak));
        EucCSSLayoutDocumentRunBreakInfo *breakInfos = malloc(breaksCapacity * sizeof(EucCSSLayoutDocumentRunBreakInfo));
        int breaksCount = 0;
        
        EucCSSIntermediateDocumentNode *currentInlineNodeWithStyle = _startNode;
        if(currentInlineNodeWithStyle.isTextNode) {
            currentInlineNodeWithStyle = currentInlineNodeWithStyle.parent;
        }
        
        CGFloat lineSoFarWidth = 0.0f;
        for(NSUInteger i = 0; i < _componentsCount; ++i) {
            id component = _components[i];
            if(component == sSingleSpaceMarker) {
                breaks[breaksCount].x0 = lineSoFarWidth;
                lineSoFarWidth += _componentInfos[i].width;
                breaks[breaksCount].x1 = lineSoFarWidth;
                breaks[breaksCount].penalty = 0;
                breaks[breaksCount].flags = TH_JUST_WITH_FLOATS_FLAG_ISSPACE;
                breakInfos[breaksCount].point = _componentInfos[i].point;
                breakInfos[breaksCount].isComponent = YES;
                ++breaksCount;
            } else if(component == sOpenNodeMarker) {
                currentInlineNodeWithStyle = _componentInfos[i].documentNode;
                // Take account of margins etc.
            } else if(component == sCloseNodeMarker) {
                NSParameterAssert(_componentInfos[i].documentNode == currentInlineNodeWithStyle);
                currentInlineNodeWithStyle = currentInlineNodeWithStyle.parent;
                // Take account of margins etc.
            } else if(component == sHardBreakMarker) {
                breaks[breaksCount].x0 = lineSoFarWidth;
                lineSoFarWidth += _componentInfos[i].width;
                breaks[breaksCount].x1 = lineSoFarWidth;
                breaks[breaksCount].penalty = 0;
                breaks[breaksCount].flags = TH_JUST_WITH_FLOATS_FLAG_ISHARDBREAK;
                breakInfos[breaksCount].point = _componentInfos[i].point;
                breakInfos[breaksCount].isComponent = YES;
                ++breaksCount;                
            } else {            
                lineSoFarWidth += _componentInfos[i].width;
            }
            
            if(breaksCount >= breaksCapacity) {
                breaksCapacity += _componentsCount;
                breaks = realloc(breaks, breaksCapacity * sizeof(THBreak));
                breakInfos = realloc(breakInfos, breaksCapacity * sizeof(EucCSSLayoutDocumentRunBreakInfo));
            }                                            
        }
        breaks[breaksCount].x0 = lineSoFarWidth;
        breaks[breaksCount].x1 = lineSoFarWidth;
        breaks[breaksCount].penalty = 0;
        breaks[breaksCount].flags = TH_JUST_WITH_FLOATS_FLAG_ISHARDBREAK;
        breakInfos[breaksCount].point.word = _wordsCount + 1;
        breakInfos[breaksCount].point.element = 0;
        breakInfos[breaksCount].isComponent = NO;
        ++breaksCount;
        
        _potentialBreaks = breaks;
        _potentialBreaksCount = breaksCount;
        _potentialBreakInfos = breakInfos;
    }
}

- (uint32_t)_pointToComponentOffset:(EucCSSLayoutDocumentRunPoint)point
{
    if(point.word > _wordsCount) {
        // This is an 'off the end' marker (i.e. an endpoint to line that
        // is 'after' the last word).
        return _componentsCount;
    } else {
        return _wordToComponent[point.word] + point.element;
    }
}

- (EucCSSLayoutPositionedRun *)positionedRunForFrame:(CGRect)frame
                                          wordOffset:(uint32_t)wordOffset 
                                       elementOffset:(uint32_t)elementOffset
{
    if(_componentsCount == 1 && _components[0] == sSingleSpaceMarker) {
        return nil;
    }    
    
    EucCSSLayoutPositionedRun *ret = [[EucCSSLayoutPositionedRun alloc] initWithDocumentRun:self];
    
    if(_sizeDependentComponentIndexes) {
        free(_potentialBreaks);
        _potentialBreaks = NULL;
        free(_potentialBreakInfos);
        _potentialBreakInfos = NULL;
        [self _recalculateSizeDependentComponentSizesForFrame:frame];
    }
    [self _ensurePotentialBreaksCalculated];
    
    size_t startBreakOffset = 0;
    for(;;) {
        EucCSSLayoutDocumentRunPoint point = _potentialBreakInfos[startBreakOffset].point;
        if(point.word < wordOffset || (point.word == wordOffset && point.element < elementOffset)) {
            ++startBreakOffset;
        } else {
            break;
        }
    }
    
    CGFloat textIndent;
    if(elementOffset == 0 && wordOffset == 0) {
        textIndent = [self _textIndentInWidth:frame.size.width];
    } else {
        textIndent = 0.0f;
    }
    
    CGFloat indentationOffset;
    uint32_t lineStartComponent;
    if(startBreakOffset) {
        indentationOffset = -_potentialBreaks[startBreakOffset].x1;
        
        EucCSSLayoutDocumentRunPoint point = { wordOffset, elementOffset };
        lineStartComponent = [self _pointToComponentOffset:point];
        uint32_t firstBreakComponent = [self _pointToComponentOffset:_potentialBreakInfos[startBreakOffset].point];
        for(uint32_t i = lineStartComponent; i < firstBreakComponent; ++i) {
            indentationOffset += _componentInfos[i].width;
        }
    } else {
        lineStartComponent = 0;
        indentationOffset = textIndent;
    }
    
    int maxBreaksCount = _potentialBreaksCount - startBreakOffset;
    int *usedBreakIndexes = (int *)malloc(maxBreaksCount * sizeof(int));
    int usedBreakCount = th_just_with_floats(_potentialBreaks + startBreakOffset, maxBreaksCount, indentationOffset, frame.size.width, 0, usedBreakIndexes);

    CGPoint lineOrigin = frame.origin;

    uint8_t textAlign = [self _textAlign];
    
    CGFloat lastLineMaxY = frame.origin.y;
    
    NSMutableArray *lines = [NSMutableArray arrayWithCapacity:usedBreakCount];
    EucCSSLayoutDocumentRunBreakInfo lastLineBreakInfo = { _componentInfos[lineStartComponent].point, NO };
    for(int i = 0; i < usedBreakCount; ++i) {
        EucCSSLayoutDocumentRunBreakInfo thisLineBreakInfo = _potentialBreakInfos[usedBreakIndexes[i] + startBreakOffset];
        EucCSSLayoutLine *newLine = [[EucCSSLayoutLine alloc] init];
        newLine.containingRun = ret;
        if(lastLineBreakInfo.isComponent) {
            EucCSSLayoutDocumentRunPoint point = lastLineBreakInfo.point;
            uint32_t componentOffset = [self _pointToComponentOffset:point];
            ++componentOffset;
            if(componentOffset >= _componentsCount) {
                // This is off the end of the components array.
                // This must be an empty line at the end of a run.
                // We remove this - the only way it can happen is if the last
                // line ends in a newline (e.g. <br>), and we're about to add
                // an implicit newline at tee end of the block anyway.
                [newLine release];        
                break;
            } else {
                newLine.startPoint = _componentInfos[componentOffset].point;
            }
        } else {
            newLine.startPoint = lastLineBreakInfo.point;
        }
        newLine.endPoint = thisLineBreakInfo.point;

        newLine.origin = lineOrigin;
        
        if(textIndent) {
            newLine.indent = textIndent;
            textIndent = 0.0f;
        }
        if(textAlign == CSS_TEXT_ALIGN_JUSTIFY &&
           (_potentialBreaks[usedBreakIndexes[i] + startBreakOffset].flags & TH_JUST_WITH_FLOATS_FLAG_ISHARDBREAK) == TH_JUST_WITH_FLOATS_FLAG_ISHARDBREAK) {
            newLine.align = CSS_TEXT_ALIGN_DEFAULT;
        } else {
            newLine.align = textAlign;
        }
        [newLine sizeToFitInWidth:frame.size.width];

        CGFloat newLineMaxY = lineOrigin.y + newLine.size.height;
        lastLineMaxY = newLineMaxY;
        [lines addObject:newLine];
        [newLine release];        
    
        lineOrigin.y = lastLineMaxY;
        lastLineBreakInfo = thisLineBreakInfo;
    }
    
    if(lines.count) {
        ret.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, lastLineMaxY - frame.origin.y);
        ret.lines = lines;
    } else {
        [ret release];
        ret = nil;
    }
    free(usedBreakIndexes);
        
    return [ret autorelease];
}

- (EucCSSLayoutDocumentRunPoint)pointForNode:(EucCSSIntermediateDocumentNode *)node
{
    for(size_t i = 0; i < _componentsCount; ++i) {
        if(_componentInfos[i].documentNode == node) {
            return _componentInfos[i].point;
        }
    }
    EucCSSLayoutDocumentRunPoint ret = {0};
    return ret;
}

@end


