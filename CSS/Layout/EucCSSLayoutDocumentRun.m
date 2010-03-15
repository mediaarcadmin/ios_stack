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
- (void)_addComponent:(id)component isWord:(BOOL)isWord info:(EucCSSLayoutDocumentRunComponentInfo *)size;
- (void)_accumulateTextNode:(EucCSSIntermediateDocumentNode *)subnode;
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
        
        while (!reachedLimit && 
               inlineNode && 
               (inlineNode.isTextNode || (inlineNodeStyle &&
                                          //css_computed_float(inlineNodeStyle) == CSS_FLOAT_NONE &&
                                          (css_computed_display(inlineNodeStyle, false) & CSS_DISPLAY_BLOCK) != CSS_DISPLAY_BLOCK))) {
            if(inlineNode.isTextNode) {
                [self _accumulateTextNode:inlineNode];
            } else {
                // Open this node.
                EucCSSLayoutDocumentRunComponentInfo info = { 0, 0, 0, 0, 0, inlineNode };
                [self _addComponent:[EucCSSLayoutDocumentRun openNodeMarker] isWord:NO info:&info];
                if(inlineNode.childrenCount == 0) {
                    [self _addComponent:[EucCSSLayoutDocumentRun closeNodeMarker] isWord:NO info:&info];
                }
            }
            
            EucCSSIntermediateDocumentNode *nextNode = [inlineNode nextDisplayableUnder:inlineNode.parent];
            if(!nextNode) {
                // Close this node.
                if(!inlineNode.isTextNode && inlineNode.childrenCount > 0) {
                    // If the node /doesn't/ have children, it's already closed,
                    // above.
                    EucCSSLayoutDocumentRunComponentInfo info = { 0, 0, 0, 0, 0, inlineNode };
                    [self _addComponent:[EucCSSLayoutDocumentRun closeNodeMarker] isWord:NO info:&info];
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
    CGFloat lineSpacing = [stringRenderer lineSpacingForPointSize:fontPixelSize];
    CGFloat ascender = [stringRenderer ascenderForPointSize:fontPixelSize];
    CGFloat descender = [stringRenderer descenderForPointSize:fontPixelSize];
    EucCSSLayoutDocumentRunComponentInfo spaceInfo = { [stringRenderer widthOfString:@" " pointSize:fontPixelSize],
                                                        lineSpacing,
                                                        ascender,
                                                        descender,
                                                        fontPixelSize,
                                                        subnode };
    
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
                                EucCSSLayoutDocumentRunComponentInfo info = { [stringRenderer widthOfString:(NSString *)string pointSize:fontPixelSize],
                                    lineSpacing,
                                    ascender,
                                    descender,
                                    fontPixelSize,
                                    subnode };
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
                        EucCSSLayoutDocumentRunComponentInfo hardBreakInfo = { 0,
                           lineSpacing,
                           ascender,
                           descender,
                           fontPixelSize,
                           subnode };
                        [self _addComponent:[EucCSSLayoutDocumentRun hardBreakMarker] isWord:NO info:&hardBreakInfo];
                        _alreadyInsertedNewline = YES;
                    }
                    break;
                default:
                    if(_previousInlineCharacterWasSpace) {
                        if(!_alreadyInsertedNewline) {
                            [self _addComponent:[EucCSSLayoutDocumentRun singleSpaceMarker] isWord:NO info:&spaceInfo];
                        } else {
                            _alreadyInsertedNewline = NO;
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
                EucCSSLayoutDocumentRunComponentInfo info = { [stringRenderer widthOfString:(NSString *)string pointSize:fontPixelSize],
                                                               lineSpacing,
                                                               ascender,
                                                               descender,
                                                               fontPixelSize,
                                                               subnode };
                [self _addComponent:(id)string isWord:YES info:&info];
                CFRelease(string);
            }
        } /*else {
            if(wordStart == characters && sawNewline) {
                // Don't do anything - we collapse the spaces around the newline, 
                // then remove the newline, leaving an empty run.
                // See http://www.w3.org/TR/2009/CR-CSS2-20090908/visuren.html
                // Section 9.2.2.1:
                // "White space content that would subsequently be collapsed 
                // away according to the 'white-space' property does not 
                // generate any anonymous inline boxes."
            } else {
                if(!_alreadyInsertedNewline) {
                    [self _addComponent:[EucCSSLayoutDocumentRun singleSpaceMarker] isWord:NO info:&spaceInfo];
                } else {
                    _alreadyInsertedNewline = NO;
                }
            }
        }*/
        
        if(charactersToFree) {
            free(charactersToFree);
        }
    }
}

- (THBreak *)potentialBreaks
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
    return _potentialBreaks;
}

- (int)potentialBreaksCount
{
    if(_potentialBreaksCount == 0) {
        [self potentialBreaks];
    }
    return _potentialBreaksCount;
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
    if(_wordsCount == 0) {
        return nil;
    }    
    
    EucCSSLayoutPositionedRun *ret = [[EucCSSLayoutPositionedRun alloc] initWithDocumentRun:self];
    
    [self potentialBreaks];
    
    size_t startBreakOffset = 0;
    for(;;) {
        EucCSSLayoutDocumentRunPoint point = _potentialBreakInfos[startBreakOffset].point;
        if(point.word < wordOffset || point.element < elementOffset) {
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


