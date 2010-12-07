//
//  EucCSSLayoutDocumentRun.m
//  LibCSSTest
//
//  Created by James Montgomerie on 12/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

#import "EucCSSInternal.h"
#import "EucCSSLayouter.h"
#import "EucCSSLayoutDocumentRun.h"
#import "EucCSSLayoutDocumentRun_Package.h"
#import "EucCSSLayoutPositionedRun.h"
#import "EucCSSLayoutPositionedLine.h"
#import "EucCSSLayoutPositionedBlock.h"
#import "EucCSSIntermediateDocument.h"
#import "EucCSSIntermediateDocument_Package.h"
#import "EucCSSIntermediateDocumentConcreteNode.h"
#import "EucCSSIntermediateDocumentGeneratedTextNode.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "EucCSSDocumentTreeNode.h"
#import "THStringRenderer.h"
#import "THNSStringSmartQuotes.h"
#import "THPair.h"
#import "THLog.h"
#import "th_just_with_floats.h"

#import "EucSharedHyphenator.h"

#import <libcss/libcss.h>
#import <pthread.h>
#import <objc/runtime.h>

typedef struct EucCSSLayoutDocumentRunBreakInfo {
    EucCSSLayoutDocumentRunPoint point;
    BOOL consumesComponent;
} EucCSSLayoutDocumentRunBreakInfo;

@interface EucCSSLayoutDocumentRun ()
- (void)_addComponent:(EucCSSLayoutDocumentRunComponentInfo *)info;
- (void)_accumulateTextNode:(EucCSSIntermediateDocumentNode *)subnode;
- (void)_accumulateImageNode:(EucCSSIntermediateDocumentNode *)subnode;
- (void)_accumulateFloatNode:(EucCSSIntermediateDocumentNode *)subnode;
- (CGFloat)_textIndentInWidth:(CGFloat)width;
@end 

@implementation EucCSSLayoutDocumentRun

@synthesize componentInfos = _componentInfos;
@synthesize componentsCount = _componentsCount;
@synthesize wordToComponent = _wordToComponent;

@synthesize startNode = _startNode;
@synthesize underNode = _underNode;
@synthesize id = _id;
@synthesize nextNodeUnderLimitNode = _nextNodeUnderLimitNode;
@synthesize nextNodeInDocument = _nextNodeInDocument;
@synthesize scaleFactor = _scaleFactor;

#define RUN_CACHE_CAPACITY 48
static NSString * const EucCSSDocumentRunCacheKey = @"EucCSSDocumentRunCacheKey";

+ (id)documentRunWithNode:(EucCSSIntermediateDocumentNode *)inlineNode 
           underLimitNode:(EucCSSIntermediateDocumentNode *)underNode
                    forId:(uint32_t)id
              scaleFactor:(CGFloat)scaleFactor
{
    EucCSSLayoutDocumentRun *ret = nil;
    
    EucCSSIntermediateDocument *document = inlineNode.document;
    @synchronized(document) {
        NSMutableArray *cachedRuns = objc_getAssociatedObject(document, EucCSSDocumentRunCacheKey);
        if(!cachedRuns) {
            cachedRuns = [[NSMutableArray alloc] initWithCapacity:RUN_CACHE_CAPACITY];
            objc_setAssociatedObject(document, EucCSSDocumentRunCacheKey, cachedRuns, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [cachedRuns release];
        }
        for(EucCSSLayoutDocumentRun *cachedRun in [cachedRuns reverseObjectEnumerator]) {
            if(cachedRun->_scaleFactor == scaleFactor &&
               cachedRun->_id == id &&
               cachedRun->_startNode.key == inlineNode.key &&
               cachedRun->_underNode.key == underNode.key) {
                ret = cachedRun;
                break;
            }
        }
        if(ret) {
            [ret retain];
            [cachedRuns removeObject:ret];
            // We'll add it again at the end to keep the last-used
            // eviction working.
        }
        if(!ret) {
            ret = [[[self class] alloc] initWithNode:inlineNode
                                      underLimitNode:underNode 
                                               forId:id 
                                         scaleFactor:scaleFactor];
        }
        if(cachedRuns.count == RUN_CACHE_CAPACITY) {
            [cachedRuns removeObjectAtIndex:0];
        }
        [cachedRuns addObject:ret];
        [ret release];
    }
    return ret;
}
        
- (id)initWithNode:(EucCSSIntermediateDocumentNode *)inlineNode 
    underLimitNode:(EucCSSIntermediateDocumentNode *)underNode
             forId:(uint32_t)id
       scaleFactor:(CGFloat)scaleFactor
{
    if((self = [super init])) {        
        _sharedHyphenator = [[EucSharedHyphenator sharedHyphenator] retain];

        _id = id;
        
        _scaleFactor = scaleFactor;
        
        
        _startNode = [inlineNode retain];
        _underNode = [underNode retain];
        
        // Retain this, because we're retaining nodes, but nodes don't retain
        // their documents.
        // No need to do this - noone should be using the run after the 
        // document's gone.
        //_document = [_startNode.document retain];        
        _document = _startNode.document;        
        
        css_computed_style *inlineNodeStyle = inlineNode.computedStyle;
                
        // _wordToComponent is 1-indexed for words - word '0' is the start of 
        // this run - so set that up now.
        _wordToComponentCapacity = 128;
        _wordToComponent = (uint32_t *)malloc(_wordToComponentCapacity * sizeof(uint32_t));
        _wordToComponent[0] = 0;         
        
        BOOL reachedLimit = NO;
        
        EucCSSLayoutDocumentRunComponentInfo currentComponentInfo = { EucCSSLayoutDocumentRunComponentKindNone };
        
        BOOL wasFloat = NO;
        while(YES) {
            EucCSSIntermediateDocumentNode *nextNode = nil;
            
            if(inlineNode.isTextNode) {
                [self _accumulateTextNode:inlineNode];
                nextNode = [inlineNode nextDisplayableUnder:underNode];
            } else if(inlineNode.isImageNode) {
                [self _accumulateImageNode:inlineNode];
                nextNode = [inlineNode nextDisplayableUnder:underNode];
            } else if(inlineNodeStyle) {
                if(css_computed_float(inlineNodeStyle) != CSS_FLOAT_NONE) {
                    [self _accumulateFloatNode:inlineNode];
                    nextNode = [inlineNode.parent displayableNodeAfter:inlineNode under:underNode];
                    wasFloat = YES;
                } else if(css_computed_display(inlineNodeStyle, false) != CSS_DISPLAY_BLOCK) {
                    // Open this node.
                    currentComponentInfo.kind = EucCSSLayoutDocumentRunComponentKindOpenNode;
                    currentComponentInfo.documentNode = inlineNode;
                    [self _addComponent:&currentComponentInfo];
                    nextNode = [inlineNode nextDisplayableUnder:underNode];
                } else {
                    break;
                }
            } else {
                break;   
            }
            
            if(nextNode) {
                EucCSSIntermediateDocumentNode *nextNodeParent = nextNode.parent;
                while(inlineNode != nextNodeParent && 
                      inlineNode != underNode) {
                    if(!inlineNode.isTextNode && 
                       !inlineNode.isImageNode &&
                       (!inlineNodeStyle || css_computed_float(inlineNodeStyle) == CSS_FLOAT_NONE)) {
                        // If the node /doesn't/ have children, it's already closed,
                        // above.
                        if(currentComponentInfo.documentNode != inlineNode) {
                            // We can close nodes that we didn't start if we're in
                            // an inline node with block nodes within it, so we
                            // need to populate this if we didn't above (usually,
                            // it's populated on node open).
                            currentComponentInfo.documentNode = inlineNode;
                        }
                        currentComponentInfo.kind = EucCSSLayoutDocumentRunComponentKindCloseNode;
                        [self _addComponent:&currentComponentInfo];
                    }                    
                    inlineNode = inlineNode.parent;
                    inlineNodeStyle = inlineNode.computedStyle;
                }

                inlineNode = nextNode;
                inlineNodeStyle = inlineNode.computedStyle;
            } else {
                if(wasFloat) {
                    inlineNode = [inlineNode.parent displayableNodeAfter:inlineNode under:nil];
                } else {
                    inlineNode = [inlineNode nextDisplayable];
                }
                reachedLimit = YES;
                break;
            }
            if(wasFloat) {
                wasFloat = NO;
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
    for(uint32_t i = 0; i < _componentsCount; ++i) {
        [_componentInfos[i].documentNode release];

        EucCSSLayoutDocumentRunComponentKind kind = _componentInfos[i].kind;
        if(kind == EucCSSLayoutDocumentRunComponentKindWord) {
            [_componentInfos[i].contents.string release];
        } else if (kind == EucCSSLayoutDocumentRunComponentKindImage) { 
            CFRelease(_componentInfos[i].contents.imageInfo.image);
        } else if(kind == EucCSSLayoutDocumentRunComponentKindHyphenationRule) {
            [_componentInfos[i].contents.hyphenationInfo.beforeHyphen release];
            [_componentInfos[i].contents.hyphenationInfo.afterHyphen release];
        }
    }
    free(_componentInfos);
    free(_wordToComponent);
    
    free(_potentialBreaks);
    free(_potentialBreakInfos);

    [_startNode release];
    [_underNode release];
    [_nextNodeUnderLimitNode release];
    [_nextNodeInDocument release];

    [_sizeDependentComponentIndexes release];
    [_floatComponentIndexes release];
    
    // See comments in init.
    //[_document release];
    
    [_sharedHyphenator release];
    
    [super dealloc];
}

- (CGFloat)_textIndentInWidth:(CGFloat)width;
{
    CGFloat ret = 0.0f;
    
    css_computed_style *style = _startNode.blockLevelNode.computedStyle;
    if(style) {
        css_fixed length = 0;
        css_unit unit = (css_unit)0;
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

- (void)_addComponent:(EucCSSLayoutDocumentRunComponentInfo *)info
{
    if(info->kind == EucCSSLayoutDocumentRunComponentKindWord) {
        ++_wordsCount;
        if(_wordToComponentCapacity == _wordsCount) {
            _wordToComponentCapacity += 128;
            _wordToComponent = (uint32_t *)realloc(_wordToComponent, _wordToComponentCapacity * sizeof(uint32_t));
        }
        _wordToComponent[_wordsCount] = _componentsCount;
        _currentWordElementCount = 0;
        
        [info->contents.string retain];
    } else if(info->kind == EucCSSLayoutDocumentRunComponentKindImage) {
        CFRetain(info->contents.imageInfo.image);
    } else if(info->kind == EucCSSLayoutDocumentRunComponentKindHyphenationRule) {
        [info->contents.hyphenationInfo.beforeHyphen retain];
        [info->contents.hyphenationInfo.afterHyphen retain];
    }
    
    if(_componentsCapacity == _componentsCount) {
        _componentsCapacity += 128;
        _componentInfos = (EucCSSLayoutDocumentRunComponentInfo *)realloc(_componentInfos, _componentsCapacity * sizeof(EucCSSLayoutDocumentRunComponentInfo));
    }
    
    info->point.word = _wordsCount;
    info->point.element = _currentWordElementCount;
    
    [info->documentNode retain];
    
    _componentInfos[_componentsCount] = *info;
    
    ++_componentsCount;
    ++_currentWordElementCount;
}

- (CGSize)_computedSizeForImage:(CGImageRef)image
                 specifiedWidth:(CGFloat)specifiedWidth
                specifiedHeight:(CGFloat)specifiedHeight
                       maxWidth:(CGFloat)maxWidth
                       minWidth:(CGFloat)minWidth
                      maxHeight:(CGFloat)maxHeight
                      minHeight:(CGFloat)minHeight
{
    CGSize imageSize = { CGImageGetWidth(image), CGImageGetHeight(image) };

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
        computedSize.width *= _scaleFactor;
        computedSize.height *= _scaleFactor;
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
    NSData *imageData = [subnode.document.dataSource dataForURL:[subnode imageSource]];

    if(imageData) {
        CGImageRef image = NULL;
#if TARGET_OS_IPHONE
        image = [UIImage imageWithData:imageData].CGImage;
        if(image) {
            CFRetain(image);
        }
#else
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
        if(imageSource) {
            image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
            CFRelease(imageSource);
        }
#endif
        if(image) {
            EucCSSLayoutDocumentRunComponentInfo info = { 0 };
            info.documentNode = subnode;
            info.kind = EucCSSLayoutDocumentRunComponentKindImage;
            info.contents.imageInfo.image = image;
            [self _addComponent:&info];
            
            if(!_sizeDependentComponentIndexes) {
                _sizeDependentComponentIndexes = [[NSMutableArray alloc] init];
            }
            [_sizeDependentComponentIndexes addObject:[NSNumber numberWithInteger:_componentsCount - 1]];
            
            _previousInlineCharacterWasSpace = NO;
            //_seenNonSpace = YES;
            
            CFRelease(image);
        }
    }
}

- (void)_recalculateSizeDependentComponentSizesForFrame:(CGRect)frame
{
    for(NSNumber *indexNumber in _sizeDependentComponentIndexes) {
        size_t offset = [indexNumber integerValue];
        
        CGImageRef image = _componentInfos[offset].contents.imageInfo.image;
        EucCSSIntermediateDocumentNode *subnode = _componentInfos[offset].documentNode;
        
        CGFloat specifiedWidth = CGFLOAT_MAX;
        CGFloat specifiedHeight = CGFLOAT_MAX;
        
        CGFloat maxWidth = CGFLOAT_MAX;
        CGFloat maxHeight = CGFLOAT_MAX;
        
        CGFloat minWidth = 1;
        CGFloat minHeight = 1;
        
        css_fixed length = 0;
        css_unit unit = (css_unit)0;
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
                if(unit == CSS_UNIT_PCT && frame.size.height == CGFLOAT_MAX) {
                    // Assume no intrinsic height;
                } else {
                    specifiedHeight = EucCSSLibCSSSizeToPixels(nodeStyle, length, unit, frame.size.height, _scaleFactor);
                }
            } 
        
            uint8_t maxHeightKind = css_computed_max_height(nodeStyle, &length, &unit);
            if (maxHeightKind == CSS_MAX_HEIGHT_SET) {
                if(unit == CSS_UNIT_PCT && frame.size.height == CGFLOAT_MAX) {
                    // Assume no max height;
                } else {
                    maxHeight = EucCSSLibCSSSizeToPixels(nodeStyle, length, unit, frame.size.height, _scaleFactor);
                }
            } 
        }
        /*
        if(specifiedWidth == CGFLOAT_MAX) {
            [subnode 
        }
        */
        
        if(maxWidth == CGFLOAT_MAX) {
            maxWidth = frame.size.width;
        }
        
        CGSize calculatedSize = [self _computedSizeForImage:image
                                             specifiedWidth:specifiedWidth
                                            specifiedHeight:specifiedHeight
                                                   maxWidth:maxWidth
                                                   minWidth:minWidth
                                                  maxHeight:maxHeight
                                                  minHeight:minHeight];
        
        _componentInfos[offset].width = calculatedSize.width;
        _componentInfos[offset].contents.imageInfo.scaledSize = CGSizeMake(calculatedSize.width, calculatedSize.height);
        
        if(css_computed_line_height(nodeStyle, &length, &unit) != CSS_LINE_HEIGHT_NORMAL) {
            _componentInfos[offset].contents.imageInfo.scaledLineHeight = EucCSSLibCSSSizeToPixels(nodeStyle, length, unit, calculatedSize.height, _scaleFactor);
        } else {
            _componentInfos[offset].contents.imageInfo.scaledLineHeight = calculatedSize.height;
        }  
    }
}

- (void)_accumulateTextNode:(EucCSSIntermediateDocumentNode *)subnode 
{
    css_computed_style *subnodeStyle;
    subnodeStyle = [subnode.parent computedStyle];
    
    enum css_white_space_e whiteSpaceModel = (enum css_white_space_e)css_computed_white_space(subnodeStyle);
    
    THStringRenderer *stringRenderer = subnode.stringRenderer;
    
    css_fixed length = 0;
    css_unit unit = (css_unit)0;
    css_computed_font_size(subnodeStyle, &length, &unit);
    
    // The font size percentages should already be fully resolved.
    CGFloat fontPixelSize = EucCSSLibCSSSizeToPixels(subnodeStyle, length, unit, 0, _scaleFactor);             

    EucCSSLayoutDocumentRunComponentInfo spaceInfo = { 0 };
    spaceInfo.kind = EucCSSLayoutDocumentRunComponentKindSpace;
    spaceInfo.documentNode = subnode;
    spaceInfo.width = [stringRenderer widthOfString:@" " pointSize:fontPixelSize];
    
    uint8_t textAlign = [self _textAlign];
    
    // CSS3 may have a way of specifying this.
    BOOL shouldHyphenate =  (textAlign == CSS_TEXT_ALIGN_LEFT || textAlign == CSS_TEXT_ALIGN_JUSTIFY) && 
                            !(whiteSpaceModel == CSS_WHITE_SPACE_PRE_LINE ||
                              whiteSpaceModel == CSS_WHITE_SPACE_PRE ||
                              whiteSpaceModel == CSS_WHITE_SPACE_PRE_WRAP);
    
    NSArray *preprocessedWords = subnode.preprocessedWords;
    if(preprocessedWords) {
        if(preprocessedWords.count) {
            for(NSString *word in preprocessedWords) {
                if(_previousInlineCharacterWasSpace && _seenNonSpace && !_alreadyInsertedSpace) {
                    [self _addComponent:&spaceInfo];                                    
                }
                
                word = [word stringWithSmartQuotes];
                
                EucCSSLayoutDocumentRunComponentInfo info = spaceInfo;
                info.kind = EucCSSLayoutDocumentRunComponentKindWord;
                info.contents.string = word;
                info.width = [stringRenderer widthOfString:word pointSize:fontPixelSize];
                [self _addComponent:&info];
                
                if(shouldHyphenate && word.length > 4) {
                    NSArray *hyphenations = [_sharedHyphenator hyphenationsForWord:word];
                    
                    EucCSSLayoutDocumentRunComponentInfo hyphenInfo = info;
                    hyphenInfo.kind = EucCSSLayoutDocumentRunComponentKindHyphenationRule;
                    
                    for(THPair *hyphenatedPair in hyphenations) {
                        NSString *beforeBreak = hyphenatedPair.first;
                        hyphenInfo.contents.hyphenationInfo.beforeHyphen = beforeBreak;
                        hyphenInfo.contents.hyphenationInfo.widthBeforeHyphen = [stringRenderer widthOfString:beforeBreak pointSize:fontPixelSize];
                        
                        NSString *afterBreak = hyphenatedPair.second;
                        hyphenInfo.contents.hyphenationInfo.afterHyphen = afterBreak;
                        hyphenInfo.contents.hyphenationInfo.widthAfterHyphen = [stringRenderer widthOfString:afterBreak pointSize:fontPixelSize];
                        
                        [self _addComponent:&hyphenInfo];
                    }
                }
                
                if(!_seenNonSpace) {
                    _seenNonSpace = YES;
                }
                if(_alreadyInsertedSpace) {
                    _alreadyInsertedSpace = NO;
                }
                if(!_previousInlineCharacterWasSpace) {
                    _previousInlineCharacterWasSpace = YES;
                }
            }            
        }
    } else {
        CFStringRef text = (CFStringRef)subnode.text;
        CFIndex textLength = CFStringGetLength(text);
        if(textLength) {
            UniChar *charactersToFree = NULL;
            const UniChar *characters = CFStringGetCharactersPtr(text);
            if(characters == NULL) {
                // CFStringGetCharactersPtr may return NULL at any time.
                charactersToFree = (UniChar *)malloc(sizeof(UniChar) * textLength);
                CFStringGetCharacters(text,
                                      CFRangeMake(0, textLength),
                                      charactersToFree);
                characters = charactersToFree;
            }
            
            const UniChar *cursor = characters;
            const UniChar *end = characters + textLength;
            
            const UniChar *wordStart = cursor;
            
            BOOL wordNeedsSmartQuotes = NO;
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
                    case 0x00A0: // Non-breaking Space
                        if(!_previousInlineCharacterWasSpace) {
                            if(wordStart != cursor) {
                                CFIndex wordLength = cursor - wordStart;
                                CFStringRef string = CFStringCreateWithCharacters(kCFAllocatorDefault,
                                                                                  wordStart, 
                                                                                  wordLength);
                                if(string) {
                                    if(wordNeedsSmartQuotes) {
                                        NSString *smartQuoted = [(NSString *)string stringWithSmartQuotesWithPreviousCharacter:_characterBeforeWord];
                                        CFRelease(string);
                                        string = (CFStringRef)[smartQuoted retain];
                                        wordNeedsSmartQuotes = NO;
                                    }
                                    EucCSSLayoutDocumentRunComponentInfo info = spaceInfo;
                                    info.kind = EucCSSLayoutDocumentRunComponentKindWord;
                                    info.contents.string = (NSString *)string;
                                    info.width = [stringRenderer widthOfString:(NSString *)string pointSize:fontPixelSize];
                                    [self _addComponent:&info];
                                    
                                    if(shouldHyphenate && wordLength > 4) {
                                        NSArray *hyphenations = [_sharedHyphenator hyphenationsForWord:(NSString *)string];
                                        
                                        EucCSSLayoutDocumentRunComponentInfo hyphenInfo = info;
                                        hyphenInfo.kind = EucCSSLayoutDocumentRunComponentKindHyphenationRule;
                                        
                                        for(THPair *hyphenatedPair in hyphenations) {
                                            NSString *beforeBreak = hyphenatedPair.first;
                                            hyphenInfo.contents.hyphenationInfo.beforeHyphen = beforeBreak;
                                            hyphenInfo.contents.hyphenationInfo.widthBeforeHyphen = [stringRenderer widthOfString:beforeBreak pointSize:fontPixelSize];
                                            
                                            NSString *afterBreak = hyphenatedPair.second;
                                            hyphenInfo.contents.hyphenationInfo.afterHyphen = afterBreak;
                                            hyphenInfo.contents.hyphenationInfo.widthAfterHyphen = [stringRenderer widthOfString:afterBreak pointSize:fontPixelSize];
                                            
                                            [self _addComponent:&hyphenInfo];
                                        }
                                    }
                                    CFRelease(string);
                                }
                            }
                            if(ch == 0x00A0) {
                                EucCSSLayoutDocumentRunComponentInfo info = spaceInfo;
                                info.kind = EucCSSLayoutDocumentRunComponentKindNonbreakingSpace;
                                [self _addComponent:&info];
                                wordStart = cursor + 1;
                            } else {
                                _previousInlineCharacterWasSpace = YES;
                            }
                            _characterBeforeWord = ' ';
                        }
                        if(whiteSpaceModel == CSS_WHITE_SPACE_PRE ||
                           whiteSpaceModel == CSS_WHITE_SPACE_PRE_WRAP ||
                           whiteSpaceModel == CSS_WHITE_SPACE_PRE_LINE) {
                            switch(ch) {
                                case 0x000A:
                                {
                                    EucCSSLayoutDocumentRunComponentInfo info = spaceInfo;
                                    info.kind = EucCSSLayoutDocumentRunComponentKindHardBreak;
                                    info.width = 0;
                                    [self _addComponent:&info];
                                    _alreadyInsertedSpace = YES;
                                    break;  
                                }
                                case 0x0009:
                                case 0x0020:
                                {
                                    if(whiteSpaceModel == CSS_WHITE_SPACE_PRE ||
                                       whiteSpaceModel == CSS_WHITE_SPACE_PRE_WRAP) {
                                        [self _addComponent:&spaceInfo];
                                        _alreadyInsertedSpace = YES;
                                    }
                                    break;
                                }
                            }
                        }
                        break;
                        
                    case '\'':
                    case '"':
                        wordNeedsSmartQuotes = YES;
                        // Fall through.
                    default:
                        if(_previousInlineCharacterWasSpace) {
                            if(!_alreadyInsertedSpace) {
                                [self _addComponent:&spaceInfo];
                            } else {
                                _alreadyInsertedSpace = NO;
                            }
                            wordStart = cursor;
                            _previousInlineCharacterWasSpace = NO;
                            if(!_seenNonSpace) {
                                _seenNonSpace = YES;
                            }
                        }
                }
                ++cursor;
            }
            if(!_previousInlineCharacterWasSpace) {
                CFStringRef string = CFStringCreateWithCharacters(kCFAllocatorDefault,
                                                                  wordStart, 
                                                                  cursor - wordStart);
                if(string) {
                    if(wordNeedsSmartQuotes) {
                        NSString *smartQuoted = [(NSString *)string stringWithSmartQuotesWithPreviousCharacter:_characterBeforeWord];
                        CFRelease(string);
                        string = (CFStringRef)[smartQuoted retain];
                        wordNeedsSmartQuotes = NO;
                    }                    
                    EucCSSLayoutDocumentRunComponentInfo info = spaceInfo;
                    info.kind = EucCSSLayoutDocumentRunComponentKindWord;
                    info.contents.string = (NSString *)string;
                    info.width = [stringRenderer widthOfString:(NSString *)string pointSize:fontPixelSize];
                    [self _addComponent:&info];
                    CFRelease(string);
                }
            } 
            if(_previousInlineCharacterWasSpace) {
                if(!_alreadyInsertedSpace && _seenNonSpace) {
                    // Check _seenNonSpace because we're not supposed to add spaces at the /start/ of lines.
                    [self _addComponent:&spaceInfo];
                    _alreadyInsertedSpace = YES;
                }
            }
            
            _characterBeforeWord = *(cursor - 1);
            
            if(charactersToFree) {
                free(charactersToFree);
            }
        }
    }
}

- (void)_accumulateFloatNode:(EucCSSIntermediateDocumentNode *)subnode
{
    EucCSSLayoutDocumentRunComponentInfo info = { 0 };
    info.documentNode = subnode;
    info.kind = EucCSSLayoutDocumentRunComponentKindFloat;
    [self _addComponent:&info];    
    
    if(!_floatComponentIndexes) {
        _floatComponentIndexes = [[NSMutableArray alloc] init];
    }
    [_floatComponentIndexes addObject:[NSNumber numberWithInteger:_componentsCount - 1]];    
}

- (void)_ensurePotentialBreaksCalculated
{
    if(!_potentialBreaks) {
        int breaksCapacity = _componentsCount + 1;
        THBreak *breaks = (THBreak *)malloc(breaksCapacity * sizeof(THBreak));
        EucCSSLayoutDocumentRunBreakInfo *breakInfos = (EucCSSLayoutDocumentRunBreakInfo *)malloc(breaksCapacity * sizeof(EucCSSLayoutDocumentRunBreakInfo));
        int breaksCount = 0;
        
        EucCSSIntermediateDocumentNode *currentInlineNodeWithStyle = _startNode;
        if(currentInlineNodeWithStyle.isTextNode) {
            currentInlineNodeWithStyle = currentInlineNodeWithStyle.parent;
        }
        
        enum css_white_space_e whiteSpaceModel = (enum css_white_space_e)css_computed_white_space(currentInlineNodeWithStyle.computedStyle);
        
        CGFloat lineSoFarWidth = 0.0f;
        CGFloat lastWordWidth = 0.0f;
        for(NSUInteger i = 0; i < _componentsCount; ++i) {
            EucCSSLayoutDocumentRunComponentInfo componentInfo = _componentInfos[i];
            switch(componentInfo.kind) {
                case EucCSSLayoutDocumentRunComponentKindSpace:
                case EucCSSLayoutDocumentRunComponentKindNonbreakingSpace:
                    {
                        if(whiteSpaceModel != CSS_WHITE_SPACE_PRE && 
                           whiteSpaceModel != CSS_WHITE_SPACE_NOWRAP) {
                            breaks[breaksCount].x0 = lineSoFarWidth;
                            lineSoFarWidth += _componentInfos[i].width;
                            breaks[breaksCount].x1 = lineSoFarWidth;
                            breaks[breaksCount].penalty = componentInfo.kind == EucCSSLayoutDocumentRunComponentKindNonbreakingSpace ? 1024 : 0;
                            breaks[breaksCount].flags = TH_JUST_WITH_FLOATS_FLAG_ISSPACE;
                            breakInfos[breaksCount].point = _componentInfos[i].point;
                            breakInfos[breaksCount].consumesComponent = YES;
                            ++breaksCount;
                        }
                    }
                    break;
                case EucCSSLayoutDocumentRunComponentKindHardBreak:
                    {
                        breaks[breaksCount].x0 = lineSoFarWidth;
                        lineSoFarWidth += _componentInfos[i].width;
                        breaks[breaksCount].x1 = lineSoFarWidth;
                        breaks[breaksCount].penalty = 0;
                        breaks[breaksCount].flags = TH_JUST_WITH_FLOATS_FLAG_ISHARDBREAK;
                        breakInfos[breaksCount].point = _componentInfos[i].point;
                        breakInfos[breaksCount].consumesComponent = YES;
                        ++breaksCount;                                        
                    }
                    break;
                case EucCSSLayoutDocumentRunComponentKindOpenNode:
                    {
                        currentInlineNodeWithStyle = _componentInfos[i].documentNode;
                        whiteSpaceModel = (enum css_white_space_e)css_computed_white_space(currentInlineNodeWithStyle.computedStyle);
                    }
                    break;
                case EucCSSLayoutDocumentRunComponentKindCloseNode:
                    {
                        NSParameterAssert(_componentInfos[i].documentNode == currentInlineNodeWithStyle);
                        currentInlineNodeWithStyle = currentInlineNodeWithStyle.parent;
                        whiteSpaceModel = (enum css_white_space_e)css_computed_white_space(currentInlineNodeWithStyle.computedStyle);
                    }
                    break;
                case EucCSSLayoutDocumentRunComponentKindWord:
                    {
                        lastWordWidth = _componentInfos[i].width;
                        lineSoFarWidth += lastWordWidth;
                    }
                    break;
                case EucCSSLayoutDocumentRunComponentKindHyphenationRule:
                    {
                        breaks[breaksCount].x0 = lineSoFarWidth + _componentInfos[i].contents.hyphenationInfo.widthBeforeHyphen - lastWordWidth;
                        breaks[breaksCount].x1 = lineSoFarWidth - _componentInfos[i].contents.hyphenationInfo.widthAfterHyphen;
                        breaks[breaksCount].penalty = 0;
                        breaks[breaksCount].flags = TH_JUST_WITH_FLOATS_FLAG_ISHYPHEN;
                        breakInfos[breaksCount].point = _componentInfos[i].point;
                        breakInfos[breaksCount].consumesComponent = NO;
                        ++breaksCount;                                                                
                    }
                    break;
                default:
                    lineSoFarWidth += _componentInfos[i].width;
            }
            
            if(breaksCount >= breaksCapacity) {
                breaksCapacity += _componentsCount;
                breaks = (THBreak *)realloc(breaks, breaksCapacity * sizeof(THBreak));
                breakInfos = (EucCSSLayoutDocumentRunBreakInfo *)realloc(breakInfos, breaksCapacity * sizeof(EucCSSLayoutDocumentRunBreakInfo));
            }                                            
        }
        breaks[breaksCount].x0 = lineSoFarWidth;
        breaks[breaksCount].x1 = lineSoFarWidth;
        breaks[breaksCount].penalty = 0;
        breaks[breaksCount].flags = TH_JUST_WITH_FLOATS_FLAG_ISHARDBREAK;
        breakInfos[breaksCount].point.word = _wordsCount + 1;
        breakInfos[breaksCount].point.element = 0;
        breakInfos[breaksCount].consumesComponent = NO;
        ++breaksCount;
        
        _potentialBreaks = breaks;
        _potentialBreaksCount = breaksCount;
        _potentialBreakInfos = breakInfos;
    }
}

- (uint32_t)pointToComponentOffset:(EucCSSLayoutDocumentRunPoint)point
{
    if(point.word > _wordsCount) {
        // This is an 'off the end' marker (i.e. an endpoint to line that
        // is 'after' the last word).
        return _componentsCount;
    } else {
        return _wordToComponent[point.word] + point.element;
    }
}

- (EucCSSLayoutPositionedRun *)positionRunForFrame:(CGRect)frame
                                       inContainer:(EucCSSLayoutPositionedBlock *)container
                              startingAtWordOffset:(uint32_t)wordOffset 
                                     elementOffset:(uint32_t)elementOffset
                            usingLayouterForFloats:(EucCSSLayouter *)layouter
{    
    if(_componentsCount == 0) {
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
        
    CGFloat textIndent;
    if(elementOffset == 0 && wordOffset == 0) {
        textIndent = [self _textIndentInWidth:frame.size.width];
    } else {
        textIndent = 0.0f;
    }
    
    NSMutableArray *lines = [[NSMutableArray alloc] init];
    CGPoint lineOrigin = CGPointZero;
    CGFloat lastLineMaxY = 0;
    
    BOOL firstTryAtLine = YES;
    CGFloat thisLineWidth = frame.size.width;
    
    uint8_t textAlign = [self _textAlign];
    
    NSUInteger floatComponentIndexesOffset = NSUIntegerMax;
    NSUInteger nextFloatComponentOffset = NSUIntegerMax;
    if(_floatComponentIndexes) {
        floatComponentIndexesOffset = 0;
        nextFloatComponentOffset = [[_floatComponentIndexes objectAtIndex:floatComponentIndexesOffset] integerValue];
    } 
       
    BOOL widthChanged;
    do {
        widthChanged = NO;
        
        NSUInteger startBreakOffset = 0;
        for(;;) {
            EucCSSLayoutDocumentRunPoint point = _potentialBreakInfos[startBreakOffset].point;
            if(startBreakOffset < _potentialBreaksCount && 
               (point.word < wordOffset || (point.word == wordOffset && point.element < elementOffset))) {
                ++startBreakOffset;
            } else {
                break;
            }
        }        
        if(startBreakOffset >= _potentialBreaksCount) {
            return nil;
        }
        int maxBreaksCount = _potentialBreaksCount - startBreakOffset;
        
        // Work out an offset to compensate the pre-calculated 
        // line lengths in the breaks array.
        CGFloat indentationOffset;
        uint32_t lineStartComponent;
        if(startBreakOffset) {
            indentationOffset = -_potentialBreaks[startBreakOffset].x1;
            
            EucCSSLayoutDocumentRunPoint point = { wordOffset, elementOffset };
            lineStartComponent = [self pointToComponentOffset:point];
            uint32_t firstBreakComponent = [self pointToComponentOffset:_potentialBreakInfos[startBreakOffset].point];
            for(uint32_t i = lineStartComponent; i < firstBreakComponent; ++i) {
                indentationOffset += _componentInfos[i].width;
            }
        } else {
            lineStartComponent = 0;
            indentationOffset = textIndent;
        }
        
        int *usedBreakIndexes = (int *)malloc(maxBreaksCount * sizeof(int));
        int usedBreakCount = th_just_with_floats(_potentialBreaks + startBreakOffset, maxBreaksCount, indentationOffset, thisLineWidth, 0, usedBreakIndexes);
        
        EucCSSLayoutDocumentRunBreakInfo lastLineBreakInfo = { _componentInfos[lineStartComponent].point, NO };
        
        for(int i = 0; i < usedBreakCount && !widthChanged; ++i) {
            EucCSSLayoutDocumentRunBreakInfo thisLineBreakInfo = _potentialBreakInfos[usedBreakIndexes[i] + startBreakOffset];
            EucCSSLayoutPositionedLine *newLine = [[EucCSSLayoutPositionedLine alloc] init];
            newLine.parent = ret;
            
            EucCSSLayoutDocumentRunPoint lineStartPoint;
            EucCSSLayoutDocumentRunPoint lineEndPoint;
            
            if(lastLineBreakInfo.consumesComponent) {
                EucCSSLayoutDocumentRunPoint point = lastLineBreakInfo.point;
                uint32_t componentOffset = [self pointToComponentOffset:point];
                ++componentOffset;
                if(componentOffset >= _componentsCount) {
                    // This is off the end of the components array.
                    // This must be an empty line at the end of a run.
                    // We remove this - the only way it can happen is if the last
                    // line ends in a newline (e.g. <br>), and we're about to add
                    // an implicit newline at the end of the block anyway.
                    [newLine release];        
                    break;
                } else {
                    lineStartPoint = _componentInfos[componentOffset].point;
                }
            } else {
                lineStartPoint = lastLineBreakInfo.point;
            }
            lineEndPoint = thisLineBreakInfo.point;
            
            newLine.startPoint = lineStartPoint;
            newLine.endPoint = lineEndPoint;
            
            if(nextFloatComponentOffset != NSUIntegerMax && 
               nextFloatComponentOffset >= [self pointToComponentOffset:lineStartPoint] &&
               nextFloatComponentOffset < [self pointToComponentOffset:lineEndPoint]) {
                // A float is on this line.  Place the float.
        
                BOOL completed = NO;
                EucCSSLayoutPoint returnedPoint = { 0 };

                EucCSSIntermediateDocumentNode *floatNode = _componentInfos[nextFloatComponentOffset].documentNode;
                
                EucCSSLayoutPoint floatPoint = { floatNode.key, 0, 0 };
                CGRect floatPotentialFrame = CGRectMake(0, 0, frame.size.width, CGFLOAT_MAX);
                EucCSSLayoutPositionedBlock *floatBlock = [layouter _layoutFromPoint:floatPoint
                                                                             inFrame:floatPotentialFrame
                                                                  returningNextPoint:&returnedPoint
                                                                  returningCompleted:&completed 
                                                                    lastBlockNodeKey:floatPoint.nodeKey
                                                               constructingAncestors:NO];
                
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
                if(floatComponentIndexesOffset >= _floatComponentIndexes.count) {
                    nextFloatComponentOffset = NSUIntegerMax;
                } else {
                    nextFloatComponentOffset = [[_floatComponentIndexes objectAtIndex:floatComponentIndexesOffset] integerValue];
                }
            }
        
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
            
            newLine.frame = CGRectMake(lineOrigin.x, lineOrigin.y, 0, 0);
            [newLine sizeToFitInWidth:thisLineWidth];
            
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
                lastLineMaxY = lineOrigin.y + newLine.frame.size.height;
                [lines addObject:newLine];
                
                lineOrigin.y = lastLineMaxY;
                lastLineBreakInfo = thisLineBreakInfo;
                if(!firstTryAtLine) {
                    firstTryAtLine = YES;
                }
            } 
            [newLine release];        
        }
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

- (NSArray *)words
{
    NSUInteger wordsCount = _wordsCount;
    NSMutableArray *words = [NSMutableArray arrayWithCapacity:wordsCount];
    
    for(NSUInteger i = 0; i < wordsCount; ++i) {
        [words addObject:_componentInfos[_wordToComponent[i + 1]].contents.string];
    }
    
    return words;
}

- (NSArray *)attributeValuesForWordsForAttributeName:(NSString *)attributeName
{
    NSUInteger wordsCount = _wordsCount;
    NSMutableArray *attributeValues = [NSMutableArray arrayWithCapacity:wordsCount];
    
    EucCSSIntermediateDocumentNode *lastDocumentNode = nil;
    NSString *lastAttribute = nil;
    for(NSUInteger i = 0; i < wordsCount; ++i) {
        NSString *attribute = lastAttribute;
        EucCSSIntermediateDocumentNode *documentNode = _componentInfos[_wordToComponent[i + 1]].documentNode;
        if(documentNode != lastDocumentNode) {
            BOOL found = NO;
            EucCSSIntermediateDocumentNode *containingNode = documentNode;
            do {
                EucCSSIntermediateDocumentNode *containingNode = documentNode.parent;
                if([containingNode respondsToSelector:@selector(documentTreeNode)]) {
                    NSString *newAttribute =  [(id <EucCSSDocumentTreeNode>)[containingNode performSelector:@selector(documentTreeNode)] attributeWithName:attributeName];
                    if(newAttribute) {
                        if(![newAttribute isEqualToString:attribute]) {
                            lastAttribute = newAttribute;
                            attribute = newAttribute;
                        }
                        found = YES;
                    }
                }
            } while(containingNode && !found);
        
            lastDocumentNode = documentNode;
        }
        [attributeValues addObject:attribute ?: @""];
    }
    
    return attributeValues;    
}

@end


