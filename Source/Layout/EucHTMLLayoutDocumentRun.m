//
//  EucHTMLLayoutDocumentRun.m
//  LibCSSTest
//
//  Created by James Montgomerie on 12/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucHTMLLayoutDocumentRun.h"
#import "EucHTMLLayoutPositionedRun.h"
#import "EucHTMLLayoutLine.h"
#import "EucHTMLDocument.h"
#import "EucHTMLDocumentConcreteNode.h"
#import "EucHTMLDocumentGeneratedTextNode.h"
#import "EucHTMLDocumentNode.h"
#import "THStringRenderer.h"
#import "thjust.h"

#import <libcss/libcss.h>

static id sSingleSpaceMarker;
static id sOpenNodeMarker;
static id sCloseNodeMarker;
static id sHardBreakMarker;

@interface EucHTMLLayoutDocumentRun ()
- (void)_addComponent:(id)component isWord:(BOOL)isWord info:(EucHTMLLayoutDocumentRunComponentInfo *)size;
- (void)_accumulateTextNode:(EucHTMLDocumentNode *)subnode;
- (CGFloat)_textIndentInWidth:(CGFloat)width;
@end 

@implementation EucHTMLLayoutDocumentRun

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

@synthesize components = _components;
@synthesize componentInfos = _componentInfos;

- (id)initWithNode:(EucHTMLDocumentNode *)inlineNode 
    underLimitNode:(EucHTMLDocumentNode *)underNode
             forId:(uint32_t)id
{
    if(self = [super init]) {
        _id = id;
        
        _startNode = [inlineNode retain];
        css_computed_style *inlineNodeStyle = inlineNode.computedStyle;
        
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
                EucHTMLLayoutDocumentRunComponentInfo info = { 0, 0, 0, 0, 0, inlineNode };
                [self _addComponent:[EucHTMLLayoutDocumentRun openNodeMarker] isWord:NO info:&info];
                if(inlineNode.childrenCount > 0) {
                    [self _addComponent:[EucHTMLLayoutDocumentRun closeNodeMarker] isWord:NO info:&info];
                }
            }
            
            EucHTMLDocumentNode *nextNode = [inlineNode nextUnder:inlineNode.parent];
            if(!nextNode) {
                // Close this node.
                if(!inlineNode.isTextNode && inlineNode.childrenCount > 0) {
                    // If the node /doesn't/ have children, it's already closed,
                    // above.
                    EucHTMLLayoutDocumentRunComponentInfo info = { 0, 0, 0, 0, 0, inlineNode };
                    [self _addComponent:[EucHTMLLayoutDocumentRun closeNodeMarker] isWord:NO info:&info];
                }
                nextNode = [inlineNode nextUnder:underNode];
            }
            if(nextNode) {
                inlineNode = nextNode;
                inlineNodeStyle = inlineNode.computedStyle;
            } else {
                inlineNode = [inlineNode nextUnder:[inlineNode.document body]];
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
    free(_componentOffsetToWordOffset);
    free(_wordOffsetToComponentOffset);
    
    free(_potentialBreaks);
    free(_potentialBreakToComponentOffset);

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
        css_fixed length;
        css_unit unit;
        css_computed_text_indent(style, &length, &unit);
        ret = EucHTMLLibCSSSizeToPixels(style, length, unit, width);
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


- (void)_addComponent:(id)component isWord:(BOOL)isWord info:(EucHTMLLayoutDocumentRunComponentInfo *)info
{
    if(_componentsCount == _componentsCapacity) {
        _componentsCapacity += 256;
        _components = realloc(_components, _componentsCapacity * sizeof(id));
        _componentInfos = realloc(_componentInfos, _componentsCapacity * sizeof(EucHTMLLayoutDocumentRunComponentInfo));
        _componentOffsetToWordOffset = realloc(_componentOffsetToWordOffset, _componentsCapacity * sizeof(size_t));
        _wordOffsetToComponentOffset = realloc(_wordOffsetToComponentOffset, _componentsCapacity * sizeof(size_t));
    }
    
    _components[_componentsCount] = [component retain];
    if(info) {
        _componentInfos[_componentsCount] = *info;
    }
    if(isWord) {
        _wordOffsetToComponentOffset[_wordsCount] = _startOfLastNonSpaceRun;
        ++_wordsCount;
    } else if(component == sSingleSpaceMarker) {
        _startOfLastNonSpaceRun = _componentsCount;
    }
    
    ++_componentsCount;
}

- (void)_accumulateTextNode:(EucHTMLDocumentNode *)subnode 
{
    css_computed_style *subnodeStyle;
    subnodeStyle = [subnode.parent computedStyle];
    
    enum css_white_space_e whiteSpaceModel = css_computed_white_space(subnodeStyle);
    
    THStringRenderer *stringRenderer = subnode.stringRenderer;
    
    css_fixed length;
    css_unit unit;
    css_computed_font_size(subnodeStyle, &length, &unit);
    
    // The font size percentages should already be fully resolved.
    CGFloat fontPixelSize = EucHTMLLibCSSSizeToPixels(subnodeStyle, length, unit, 0);             
    CGFloat lineSpacing = [stringRenderer lineSpacingForPointSize:fontPixelSize];
    CGFloat ascender = [stringRenderer ascenderForPointSize:fontPixelSize];
    CGFloat descender = [stringRenderer descenderForPointSize:fontPixelSize];
    EucHTMLLayoutDocumentRunComponentInfo spaceInfo = { [stringRenderer widthOfString:@" " pointSize:fontPixelSize],
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
                                EucHTMLLayoutDocumentRunComponentInfo info = { [stringRenderer widthOfString:(NSString *)string pointSize:fontPixelSize],
                                    lineSpacing,
                                    ascender,
                                    descender,
                                    fontPixelSize,
                                    subnode };
                                [self _addComponent:(id)string isWord:YES info:&info];
                            }
                        }
                        _previousInlineCharacterWasSpace = YES;
                    }
                    if(ch == 0x000A && 
                       (whiteSpaceModel == CSS_WHITE_SPACE_PRE_LINE ||
                        whiteSpaceModel == CSS_WHITE_SPACE_PRE ||
                        whiteSpaceModel == CSS_WHITE_SPACE_PRE_WRAP)) {
                        EucHTMLLayoutDocumentRunComponentInfo hardBreakInfo = { 0,
                           lineSpacing,
                           ascender,
                           descender,
                           fontPixelSize,
                           subnode };
                        [self _addComponent:[EucHTMLLayoutDocumentRun hardBreakMarker] isWord:NO info:&hardBreakInfo];
                        _alreadyInsertedNewline = YES;
                    }
                    break;
                default:
                    if(_previousInlineCharacterWasSpace) {
                        if(!_alreadyInsertedNewline) {
                            [self _addComponent:[EucHTMLLayoutDocumentRun singleSpaceMarker] isWord:NO info:&spaceInfo];
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
                EucHTMLLayoutDocumentRunComponentInfo info = { [stringRenderer widthOfString:(NSString *)string pointSize:fontPixelSize],
                                                               lineSpacing,
                                                               ascender,
                                                               descender,
                                                               fontPixelSize,
                                                               subnode };
                [self _addComponent:(id)string isWord:YES info:&info];
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
                    [self _addComponent:[EucHTMLLayoutDocumentRun singleSpaceMarker] isWord:NO info:&spaceInfo];
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
        int *breakToComponentOffset = malloc(breaksCapacity * sizeof(int));
        int breaksCount = 0;
        
        EucHTMLDocumentNode *currentInlineNodeWithStyle = _startNode;
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
                breaks[breaksCount].flags = TH_JUST_FLAG_ISSPACE;
                breakToComponentOffset[breaksCount] = i;
                ++breaksCount;
                
                if(breaksCount >= breaksCapacity) {
                    breaksCapacity += _componentsCount;
                    breaks = realloc(breaks, breaksCapacity * sizeof(THBreak));
                    breakToComponentOffset = realloc(breakToComponentOffset, breaksCapacity * sizeof(int));
                }                
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
                breaks[breaksCount].flags = TH_JUST_FLAG_ISHARDBREAK;
                breakToComponentOffset[breaksCount] = i;
                ++breaksCount;
                
                if(breaksCount >= breaksCapacity) {
                    breaksCapacity += _componentsCount;
                    breaks = realloc(breaks, breaksCapacity * sizeof(THBreak));
                    breakToComponentOffset = realloc(breakToComponentOffset, breaksCapacity * sizeof(int));
                }                                
            } else {            
                lineSoFarWidth += _componentInfos[i].width;
            }
        }
        breaks[breaksCount].x0 = lineSoFarWidth;
        breaks[breaksCount].x1 = lineSoFarWidth;
        breaks[breaksCount].penalty = 0;
        breaks[breaksCount].flags = TH_JUST_FLAG_ISHARDBREAK;
        breakToComponentOffset[breaksCount] = _componentsCount;
        ++breaksCount;
        
        _potentialBreaks = breaks;
        _potentialBreaksCount = breaksCount;
        _potentialBreakToComponentOffset = breakToComponentOffset;
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


- (EucHTMLLayoutPositionedRun *)positionedRunForFrame:(CGRect)frame
                                           wordOffset:(uint32_t)wordOffset 
                                         hyphenOffset:(uint32_t)hyphenOffset
                                   returningCompleted:(BOOL *)returningCompleted
{
    if(_wordsCount == 0) {
        return nil;
    }    
    
    [self potentialBreaks];
    
    size_t startComponentOffset = _wordOffsetToComponentOffset[wordOffset];
    size_t startBreakOffset = 0;
    while(_potentialBreakToComponentOffset[startBreakOffset] < startComponentOffset) {
        ++startBreakOffset;
    }
    
    CGFloat textIndent;
    if(hyphenOffset == 0 && wordOffset == 0) {
        textIndent = [self _textIndentInWidth:frame.size.width];
    } else {
        textIndent = 0.0f;
    }
    
    int maxBreaksCount = _potentialBreaksCount - startBreakOffset;
    int *usedBreakIndexes = (int *)malloc(maxBreaksCount * sizeof(int));
    CGFloat indentationOffset = 0;
    if(startBreakOffset) {
        indentationOffset = -_potentialBreaks[startBreakOffset].x1;
    }
    indentationOffset += textIndent;
    int usedBreakCount = th_just(_potentialBreaks + startBreakOffset, maxBreaksCount, textIndent, frame.size.width, 0, usedBreakIndexes);

    CGPoint lineOrigin = frame.origin;

    uint8_t textAlign = [self _textAlign];
    
    
    BOOL completed = YES;

    CGFloat maxY = CGRectGetMaxY(frame);
    CGFloat lastLineMaxY = maxY;
    
    NSMutableArray *lines = [NSMutableArray arrayWithCapacity:usedBreakCount];
    int lineStartComponentOffset = startComponentOffset;
    
    for(int i = 0; i < usedBreakCount; ++i) {
        int thisComponentOffset = _potentialBreakToComponentOffset[usedBreakIndexes[i] + startBreakOffset];
        EucHTMLLayoutLine *newLine = [[EucHTMLLayoutLine alloc] init];
        newLine.documentRun = self;
        newLine.startComponentOffset = lineStartComponentOffset;
        newLine.startHyphenOffset = 0;
        newLine.endComponentOffset = thisComponentOffset;
        newLine.endHyphenOffset = 0;
        
        newLine.origin = lineOrigin;
        
        if(textIndent) {
            newLine.indent = textIndent;
            textIndent = 0.0f;
        }
        if(textAlign == CSS_TEXT_ALIGN_JUSTIFY &&
           (_potentialBreaks[usedBreakIndexes[i] + startBreakOffset].flags & TH_JUST_FLAG_ISHARDBREAK) == TH_JUST_FLAG_ISHARDBREAK) {
            newLine.align = CSS_TEXT_ALIGN_DEFAULT;
        } else {
            newLine.align = textAlign;
        }
        [newLine sizeToFitInWidth:frame.size.width];

        CGFloat newLineMaxY = lineOrigin.y + newLine.size.height;
        if(newLineMaxY > maxY) {
            completed = NO;
            [newLine release];        
            break;
        } else  {
            lastLineMaxY = newLineMaxY;
            [lines addObject:newLine];
            [newLine release];        
        }
        
        lineOrigin.y = lastLineMaxY;
        lineStartComponentOffset = thisComponentOffset + 1; // +1 to skip the space.
    }
    
    EucHTMLLayoutPositionedRun *ret = nil;
    if(lines.count) {
        CGRect positionedRunFrame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, lastLineMaxY - frame.origin.y);
        ret = [[EucHTMLLayoutPositionedRun alloc] initWithDocumentRun:self 
                                                                lines:lines
                                                                frame:positionedRunFrame];
    }
    free(usedBreakIndexes);
    
    if(returningCompleted) {
        *returningCompleted = completed;
    }
    
    return [ret autorelease];
}

@end
