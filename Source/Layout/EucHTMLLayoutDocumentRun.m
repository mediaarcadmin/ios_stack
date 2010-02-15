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
#import "EucHTMLDocumentNode.h"
#import "THStringRenderer.h"
#import "thjust.h"

static id sSingleSpaceMarker;
static id sOpenNodeMarker;
static id sCloseNodeMarker;

@interface EucHTMLLayoutDocumentRun ()
- (void)_addComponent:(id)component isWord:(BOOL)isWord info:(EucHTMLLayoutDocumentRunComponentInfo *)size;
- (void)_accumulateTextNode:(EucHTMLDocumentNode *)subnode;
@end 

@implementation EucHTMLLayoutDocumentRun

+ (void)initialize
{
    sSingleSpaceMarker = (id)kCFNull;
    sOpenNodeMarker = [[NSObject alloc] init];
    sCloseNodeMarker = [[NSObject alloc] init];
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
                if(!inlineNode.children) {
                    [self _addComponent:[EucHTMLLayoutDocumentRun closeNodeMarker] isWord:NO info:&info];
                }
            }
            
            EucHTMLDocumentNode *nextNode = [inlineNode nextUnder:inlineNode.parent];
            if(!nextNode) {
                // Close this node.
                if(!inlineNode.isTextNode && inlineNode.children) {
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
                inlineNode = [inlineNode nextUnder:[[inlineNode document] body]];
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
    
    THStringRenderer *stringRenderer = subnode.stringRenderer;
    
    css_fixed length;
    css_unit unit;
    css_computed_font_size(subnodeStyle, &length, &unit);
    CGFloat fontPixelSize = libcss_size_to_pixels(subnodeStyle, length, unit);            
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
                case 0x000D: // CR
                case 0x000A: // LF
                    if(!sawNewline) {
                        sawNewline = YES;
                    }
                    // No break = fall through.
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
                    break;
                default:
                    if(_previousInlineCharacterWasSpace) {
                        [self _addComponent:[EucHTMLLayoutDocumentRun singleSpaceMarker] isWord:NO info:&spaceInfo];
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
        } else {
            if(wordStart == characters && sawNewline) {
                // Don't do anything - we collapse the spaces around the newline, 
                // then remove the newline, leaving an empty run.
                // See http://www.w3.org/TR/2009/CR-CSS2-20090908/visuren.html
                // Section 9.2.2.1:
                // "White space content that would subsequently be collapsed 
                // away according to the 'white-space' property does not 
                // generate any anonymous inline boxes."
            } else {
                [self _addComponent:[EucHTMLLayoutDocumentRun singleSpaceMarker] isWord:NO info:&spaceInfo];
            }
        }
        
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
        CGFloat lineSoFarWidth = 0;
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
    
    int maxBreaksCount = _potentialBreaksCount - startBreakOffset;
    int *usedBreakIndexes = (int *)malloc(maxBreaksCount * sizeof(int));
    int usedBreakCount = th_just(_potentialBreaks + startBreakOffset, maxBreaksCount, frame.size.width, 0, usedBreakIndexes);

    CGPoint lineOrigin = frame.origin;
    CGRect positionedRunFrame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, 0);
    
    
    NSLog(@"lines:");
    CGFloat lastLineStart = 0;
    for(int i = 0; i < usedBreakCount; ++i) {
        THBreak *thisBreak = _potentialBreaks + (usedBreakIndexes[i] + startBreakOffset);
        printf("line: %fpx\n", thisBreak->x0 - lastLineStart);
        lastLineStart = thisBreak->x1;
    }
     
    
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
        [newLine sizeToFitInWidth:frame.size.width];
        
        CGFloat newHeight = positionedRunFrame.size.height + newLine.size.height;
        if(newHeight <= frame.size.height) {
            positionedRunFrame.size.height = newHeight;
            [lines addObject:newLine];
        }
        
        lineOrigin.y += newLine.size.height;
        lineStartComponentOffset = thisComponentOffset + 1; // +1 to skip the space.

        [newLine release];
        
        /*CGFloat calculatedWidth = 0;
        for(int j = 0; j < newLine.componentCount; ++j) {
            calculatedWidth += newLine.componentInfos[j].width;
        }
       // NSLog(@"Calculated: %p: %s", newLine, [NSStringFromRect(NSRectFromCGRect(newLine.frame)) UTF8String]);
        printf("lin2: %fpx\n", calculatedWidth);
         */
    }
    
    EucHTMLLayoutPositionedRun *ret = nil;
    if(lines.count) {
        ret = [[EucHTMLLayoutPositionedRun alloc] initWithDocumentRun:self 
                                                                lines:lines
                                                                frame:positionedRunFrame];
    }
    free(usedBreakIndexes);
    
    return [ret autorelease];
}

@end
