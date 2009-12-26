//
//  EucHTMLDocumentRenderer.m
//  LibCSSTest
//
//  Created by James Montgomerie on 13/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import "EucHTMLDocumentRenderer.h"
#import "EucHTMLDocumentNode.h"

typedef struct Breakpoint {
    uint32_t word;
    uint32_t hyphenationPoint;
} Breakpoint;

typedef struct EucPoint {
    uint32_t x;
    uint32_t y;
} EucPoint;

typedef struct EucSize {
    uint32_t width;
    uint32_t height;
} EucSize;

@interface EucHTMLDocumentRendererLaidOutNode : NSObject {
@public
    uint32_t blockNodeKey;
    
    EucPoint contentPosition;
    EucSize contentSize;
    
    NSString **words;
    void *hyphenationPoints;
    uint32_t *wordNodeKeys;
    uint32_t wordCount;
    
    Breakpoint *lineBreaks;
    EucPoint *linePositions;
    uint32_t lineCount;
} 

@end

@implementation EucHTMLDocumentRendererLaidOutNode

- (void)dealloc
{
    for(uint32_t i = 0; ++i; i < wordCount) {
        CFRelease((CFStringRef)words[i]);
    }
    free(words);
    free(hyphenationPoints);
    free(wordNodeKeys);
    
    free(lineBreaks);
    free(linePositions);
    
    [super dealloc];
}

@end


@implementation EucHTMLDocumentRenderer

/*
Return words, 
Line start x positions and widths,
Line end word and hyphenation points, 
Block contents x/y position.
Block completion status.
*/

- (EucHTMLDocumentNode *)layoutNode:(EucHTMLDocumentNode *)node 
                                atX:(uint32_t)atX
                                atY:(uint32_t)atY
                    maxContentWidth:(uint32_t)maxWidth 
                   maxContentHeight:(uint32_t)maxHeight
                       laidOutNodes:(NSMutableArray *)laidOutNodes
                      laidOutFloats:(NSMutableArray *)laidOutFloats
{
//    Keep track of: 
//        Fully laid out child nodes.
    NSMutableArray *laidOutChildren = [[NSMutableArray alloc] init];
//        X/Y of start of current block content
//        Current margin border and padding.    
//        Stack of left floats with end y position and width.
//        Stack of right floats with end y position and width.
//        "Current" line and line's max height so far.
//        Node/Word/Break position of start of lines in current block.

    
    EucHTMLDocumentRendererLaidOutNode *thisLaidOutNode = [[EucHTMLDocumentRendererLaidOutNode alloc] init];
    thisLaidOutNode->contentPosition.x = atX;
    thisLaidOutNode->contentPosition.y = atY;
        
//    While we have subnodes
    EucHTMLDocumentNode *previousSubnode = node;
    EucHTMLDocumentNode *subnode = [node nextUnder:node];
    while(subnode != nil) {         
        css_computed_style *subnodeStyle = [subnode computedStyle];
// 
        BOOL isInline = (css_computed_display(subnodeStyle, false) & CSS_DISPLAY_INLINE) == CSS_DISPLAY_INLINE;
        
//        If subnode is block
//            Add previous block to laid out children list.
//            Start new line (take into account "clear").
//            Performing margin collapsing.
//            If content of block is over the end of the page
//                Return.
//
//        If subnode is float
        if(css_computed_float(subnodeStyle) != CSS_FLOAT_NONE) {
//            Recurse to lay out float in available width.
//            -- No need to worry about block vs. inline - that's 
//            -- taken care of already.
//            If resulting float is smaller than available width
//                Place resulting float on current line.
//            Else
//                If float fits in empty line width
//                    Place resulting float on next line.
//                else
//                    Place float below any current floats.
//            If float doesn't fit on page vertically
//                If it's not on the first line.
//                    Record node to start of the current line in laid out list.
//                    Record laid out children in laid out list.
//                    Return.
//            Record float in laid out floats list.
//            Update float stack.
            previousSubnode = subnode;
            subnode = [subnode nextUnder:node];
//        Else If subnode is inline
        } else if(isInline) {
//            While subnodes are inline and not float
            while(subnode && (subnodeStyle = [subnode computedStyle]) &&
                  css_computed_float(subnodeStyle) == CSS_FLOAT_NONE &&
                  (css_computed_display(subnodeStyle, false) & CSS_DISPLAY_INLINE) == CSS_DISPLAY_INLINE) {
//                Create array of "lineElements" - words, spaces, node start/end markers (used to know about margins, fonts etc).
//                Combine contents, performing whitespace processing.
//                Parallel array maps to hyphenation points.
                if([subnode hasText]) {
                    
                }
                previousSubnode = subnode;
                subnode = [subnode nextUnder:node];
            }
//            Create horizontally-sized valid-break structure.
//                Remember to take into account indentation and any contents
//                already on the line.
//            Justify resulting paragraph.
//            Store word + hyphenation point -> line end map.
//                Work out line heights.
//            If floats end before page ends resulting lines overlap float end positions
//                Pop and reflow from start of line after overlap stops.
//            If resulting lines overflow the bottom of the page
//                If (overflow count < allowed widows count) 
//                    If (non-overflowed count - (allowed widows count - overflow count)) > orphans count
//                        Record node position.
//                        Return start of line at (non-overflowed count - (allowed widows count - overflow count))
//                    Else
//                        Remove any content from this block that's on this page.
//                        Return start of block.
//                Record node to overflow position in laid out list.
//                Record laid out children in laid out list.
//                Return.
//            If all lines fit
//                Check bottom padding of element.
//                If bottom padding < remaining height
//                    If (lines in block - min widows height) > min. orphans count.
//                        Record node to (lines in block - min widows height) in laid out list.
//                        Record laid out children in laid out list.
//                        Return.
//                    Else
//                        Record laid out children in laid out list.
//                        Return.
            previousSubnode = subnode;
            subnode = [subnode nextUnder:node];
//        Else if subnode is block
        } else if(!isInline) {
//            Recurse with block in available width.
//            If block not fully laid out
//                Record node position to end of current line in laid out list.
//                Record laid out children in laid out list.
//                Record partially laid out child.
//                Return.
            previousSubnode = subnode;
            subnode = [subnode nextUnder:node];
        } else {
            [NSException raise:NSInternalInconsistencyException format:@"Unexpected display type for node %ld", (long)subnode.key];
            previousSubnode = subnode;
            subnode = [subnode nextUnder:node];
        }
    }
        
    [laidOutChildren addObject:thisLaidOutNode];
    
    return previousSubnode;
}


@end
