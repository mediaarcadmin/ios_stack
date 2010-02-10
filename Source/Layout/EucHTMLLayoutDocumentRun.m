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
- (void)_accumulateInlineNode:(EucHTMLDocumentNode *)subnode;
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
        _componentOffsetToWordOffset[_componentsCount] = _wordsCount;
        _wordOffsetToComponentOffset[_wordsCount] = _componentsCount;
        ++_wordsCount;
    }
    
    ++_componentsCount;
}

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
                                          (css_computed_display(inlineNodeStyle, false) & CSS_DISPLAY_INLINE) == CSS_DISPLAY_INLINE))) {
            if(inlineNode.isTextNode) {
                [self _accumulateInlineNode:inlineNode];
            } else {
                // Open this node.
                [self _addComponent:[EucHTMLLayoutDocumentRun openNodeMarker] isWord:NO info:NULL];
                [self _addComponent:inlineNode isWord:NO info:NULL];
                if(!inlineNode.children) {
                    [self _addComponent:[EucHTMLLayoutDocumentRun closeNodeMarker] isWord:NO info:NULL];
                    [self _addComponent:inlineNode isWord:NO info:NULL];
                }
            }
            
            EucHTMLDocumentNode *nextNode = [inlineNode nextUnder:inlineNode.parent];
            if(!nextNode) {
                // Close this node.
                if(!inlineNode.isTextNode && inlineNode.children) {
                    // If the node /doesn't/ have children, it's already closed,
                    // above.
                    [self _addComponent:[EucHTMLLayoutDocumentRun closeNodeMarker] isWord:NO info:NULL];
                    [self _addComponent:inlineNode isWord:NO info:NULL];
                }
                nextNode = [inlineNode nextUnder:underNode];
            }
            if(nextNode) {
                inlineNode = nextNode;
                inlineNodeStyle = inlineNode.computedStyle;
            } else {
                inlineNode = [inlineNode next];
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

- (void)_accumulateInlineNode:(EucHTMLDocumentNode *)subnode 
{
    css_computed_style *subnodeStyle;
    subnodeStyle = [subnode.parent computedStyle];
    
    THStringRenderer *stringRenderer = subnode.stringRenderer;
    
    css_fixed length;
    css_unit unit;
    css_computed_font_size(subnodeStyle, &length, &unit);
    CGFloat fontPixelSize = libcss_size_to_pixels(length, unit);            
    CGFloat lineSpacing = [stringRenderer lineSpacingForPointSize:fontPixelSize];
    CGFloat ascender = [stringRenderer ascenderForPointSize:fontPixelSize];
    CGFloat descender = [stringRenderer descenderForPointSize:fontPixelSize];
    EucHTMLLayoutDocumentRunComponentInfo spaceInfo = { [stringRenderer widthOfString:@" " pointSize:fontPixelSize],
                                                        lineSpacing,
                                                        ascender,
                                                        descender };
    
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
        
        while(cursor < end) {
            UniChar ch = *cursor;
            if(ch == 0x0009 || // tab
               ch == 0x000D || // CR
               ch == 0x000A || // LF
               ch == 0x0020    // Space
               ) {
                if(!_previousInlineCharacterWasSpace) {
                    if(wordStart != cursor) {
                        CFStringRef string = CFStringCreateWithCharacters(kCFAllocatorDefault,
                                                                          wordStart, 
                                                                          cursor - wordStart);
                        if(string) {
                            EucHTMLLayoutDocumentRunComponentInfo info = { [stringRenderer widthOfString:(NSString *)string pointSize:fontPixelSize],
                                                                            lineSpacing,
                                                                            ascender,
                                                                            descender };
                            [self _addComponent:(id)string isWord:YES info:&info];
                        }
                    }
                    [self _addComponent:[EucHTMLLayoutDocumentRun singleSpaceMarker] isWord:NO info:&spaceInfo];
                }
                _previousInlineCharacterWasSpace = YES;
            } else {
                if(_previousInlineCharacterWasSpace) {
                    wordStart = cursor;
                }
                _previousInlineCharacterWasSpace = NO;
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
                                                               descender };
                [self _addComponent:(id)string isWord:YES info:&info];
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
        int lineSoFarWidth = 0;
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
            } else if(component == sOpenNodeMarker) {
                currentInlineNodeWithStyle = _components[++i];
                // Take account of margins etc.
            } else if(component == sCloseNodeMarker) {
                ++i; // Skip the closed node reference.
                currentInlineNodeWithStyle = currentInlineNodeWithStyle.parent;
                // Take account of margins etc.
            } else {            
                lineSoFarWidth += _componentInfos[i].width;
            }
            if(breaksCount >= breaksCapacity) {
                breaksCapacity += _componentsCount;
                breaks = realloc(breaks, breaksCapacity * sizeof(THBreak));
                breakToComponentOffset = realloc(breakToComponentOffset, breaksCapacity * sizeof(int));
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
    [self potentialBreaks];
    
    size_t startComponentOffset = _wordOffsetToComponentOffset[wordOffset];
    size_t startBreakOffset = 0;
    while(_potentialBreakToComponentOffset[startBreakOffset] < startComponentOffset) {
        ++startBreakOffset;
    }
    
    int maxBreaksCount = _potentialBreaksCount - startBreakOffset;
    int *usedBreakIndexes = (int *)malloc(maxBreaksCount * sizeof(int));
    int usedBreakCount = th_just(_potentialBreaks + startBreakOffset, maxBreaksCount, floorf(frame.size.width), 0, usedBreakIndexes);

    CGPoint lineOrigin = frame.origin;
    CGRect positionedRunFrame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, 0);
    
    NSMutableArray *lines = [NSMutableArray arrayWithCapacity:usedBreakCount];
    int previousComponentOffset = startComponentOffset;
    for(int i = 0; i < usedBreakCount; ++i) {
        int thisComponentOffset = usedBreakIndexes[i] + startBreakOffset;
        EucHTMLLayoutLine *newLine = [[EucHTMLLayoutLine alloc] init];
        newLine.documentRun = self;
        newLine.startComponentOffset = _potentialBreakToComponentOffset[previousComponentOffset];
        newLine.startHyphenOffset = 0;
        newLine.endComponentOffset = _potentialBreakToComponentOffset[thisComponentOffset];
        newLine.endHyphenOffset = 0;
        newLine.origin = lineOrigin;
        [newLine sizeToFitInWidth:frame.size.width];
        
        CGFloat newHeight = positionedRunFrame.size.height + newLine.size.height;
        if(newHeight <= frame.size.height) {
            positionedRunFrame.size.height = newHeight;
            [lines addObject:newLine];
        }
        [newLine release];
        
        previousComponentOffset = thisComponentOffset;
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
