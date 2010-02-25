//
//  EucHTMLLayouter.h
//  LibCSSTest
//
//  Created by James Montgomerie on 13/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import "EucHTMLLayouter.h"

#import "EucHTMLDocument.h"
#import "EucHTMLDocumentNode.h"
#import "EucHTMLDocumentConcreteNode.h"

#import "EucHTMLLayoutPositionedBlock.h"
#import "EucHTMLLayoutPositionedRun.h"
#import "EucHTMLLayoutDocumentRun.h"
#import "EucHTMLLayoutLine.h"

#import "THStringRenderer.h"
#import "thjust.h"

@implementation EucHTMLLayouter

@synthesize document = _document;

/*
Return words, 
Line start x positions and widths,
Line end word and hyphenation points, 
Block contents x/y position.
Block completion status.
*/

- (EucHTMLLayoutPositionedBlock *)_constructBlockAndAncestorsForNode:(EucHTMLDocumentNode *)node
                                                  returningInnermost:(EucHTMLLayoutPositionedBlock **)innermost
                                                             inFrame:(CGRect)frame
                                              afterInternalPageBreak:(BOOL)afterInternalPageBreak
{
    EucHTMLLayoutPositionedBlock *newContainer = [[[EucHTMLLayoutPositionedBlock alloc] initWithDocumentNode:node] autorelease];
    newContainer.documentNode = node;
    [newContainer positionInFrame:frame afterInternalPageBreak:afterInternalPageBreak];
    
    EucHTMLLayoutPositionedBlock *outermost = nil;
    if(![node.document nodeIsBody:node]) {
        EucHTMLLayoutPositionedBlock *parentContainer = nil;
        outermost = [self _constructBlockAndAncestorsForNode:node.parent
                                          returningInnermost:&parentContainer
                                                     inFrame:newContainer.contentRect
                                      afterInternalPageBreak:YES];
        [parentContainer addSubEntity:newContainer];
    } else {
        outermost = newContainer;
    }
    
    *innermost = newContainer;
    return outermost;
}
                                                        
- (EucHTMLLayoutPositionedBlock *)layoutFromNodeWithId:(uint32_t)nodeId
                                            wordOffset:(uint32_t)wordOffset
                                         elementOffset:(uint32_t)elementOffset
                                               inFrame:(CGRect)frame
{
    EucHTMLDocument *document = self.document;
    EucHTMLDocumentNode* currentDocumentNode = [document nodeForKey:nodeId];
    
    if(currentDocumentNode) {
        css_computed_style *currentNodeStyle = currentDocumentNode.computedStyle;

        EucHTMLLayoutPositionedBlock *currentPositionedBlock = nil;
        EucHTMLLayoutPositionedBlock *positionedRoot = nil;      
        if(!currentNodeStyle || (css_computed_display(currentNodeStyle, false) & CSS_DISPLAY_BLOCK) != CSS_DISPLAY_BLOCK) {
            currentDocumentNode = currentDocumentNode.blockLevelParent;
            positionedRoot = [self _constructBlockAndAncestorsForNode:currentDocumentNode.parent
                                                   returningInnermost:&currentPositionedBlock
                                                              inFrame:frame
                                               afterInternalPageBreak:YES];               
        } else {
            positionedRoot = [self _constructBlockAndAncestorsForNode:currentDocumentNode
                                                   returningInnermost:&currentPositionedBlock
                                                              inFrame:frame
                                               afterInternalPageBreak:NO];
        }
        currentDocumentNode = currentDocumentNode.next;
        
        CGFloat nextY = frame.origin.y;
        uint32_t nextRunId = ((EucHTMLDocumentConcreteNode *)currentDocumentNode).key;
        do {            
            CGRect potentialFrame = currentPositionedBlock.contentRect;
            if(potentialFrame.size.height != CGFLOAT_MAX) {
                potentialFrame.size.height = CGRectGetMaxY(potentialFrame) - nextY;
            }
            potentialFrame.origin.y = nextY;
            
            css_computed_style *currentNodeStyle = currentDocumentNode.computedStyle;
            if(!currentNodeStyle || (css_computed_display(currentNodeStyle, false) & CSS_DISPLAY_BLOCK) != CSS_DISPLAY_BLOCK) {
                // This is an inline element - start a run.
                
                EucHTMLDocumentNode *underNode = currentDocumentNode.parent;
                
                // Get the next run.
                EucHTMLLayoutDocumentRun *documentRun = [[EucHTMLLayoutDocumentRun alloc] initWithNode:currentDocumentNode
                                                                                        underLimitNode:underNode
                                                                                                 forId:nextRunId];
                
                // Position it.
                BOOL positionedRunIsComplete;
                EucHTMLLayoutPositionedRun *positionedRun = [documentRun positionedRunForFrame:potentialFrame
                                                                                    wordOffset:wordOffset
                                                                                 elementOffset:elementOffset
                                                                            returningCompleted:&positionedRunIsComplete];
                if(positionedRun) {
                    [currentPositionedBlock addSubEntity:positionedRun];
                }
                             
                if(elementOffset) {
                    elementOffset = 0;
                }
                if(wordOffset) {
                    wordOffset = 0;
                }
                
                nextY = CGRectGetMaxY(positionedRun.frame);
                
                EucHTMLDocumentNode *runsNextNode = documentRun.nextNodeUnderLimitNode;
                if(runsNextNode) {
                    // Non-first run in a block has the ID of its first element.
                    currentDocumentNode = runsNextNode;
                    nextRunId = ((EucHTMLDocumentConcreteNode *)currentDocumentNode).key;
                } else {
                    currentDocumentNode = documentRun.nextNodeInDocument;
                }
                [documentRun release];
            } else {
                // This is a block-level element.

                // Find the block's parent, closing open nodes until we reach it.
                EucHTMLDocumentNode *currentDocumentNodeBlockLevelParent = currentDocumentNode.blockLevelParent;
                while(currentPositionedBlock.documentNode != currentDocumentNodeBlockLevelParent) {
                    [currentPositionedBlock closeBottomFromYPoint:nextY atInternalPageBreak:NO];
                    nextY = NSMaxY(currentPositionedBlock.frame);
                    currentPositionedBlock = currentPositionedBlock.parent;
                }
                CGRect potentialFrame = currentPositionedBlock.contentRect;
                if(potentialFrame.size.height != CGFLOAT_MAX) {
                    potentialFrame.size.height = CGRectGetMaxY(potentialFrame) - nextY;
                }
                potentialFrame.origin.y = nextY;
                
                EucHTMLLayoutPositionedBlock *newBlock = [[EucHTMLLayoutPositionedBlock alloc] initWithDocumentNode:currentDocumentNode];
                [newBlock positionInFrame:potentialFrame
                            afterInternalPageBreak:NO];
                [currentPositionedBlock addSubEntity:newBlock];                    
                
                currentPositionedBlock = [newBlock autorelease];

                nextY = newBlock.contentRect.origin.y;
                
                // First run in a block has the ID of the block it's in.
                nextRunId = ((EucHTMLDocumentConcreteNode *)currentDocumentNode).key;  
                
                currentDocumentNode = currentDocumentNode.next;
            }
        } while(currentDocumentNode);
        
        while(currentPositionedBlock) {
            [currentPositionedBlock closeBottomFromYPoint:nextY atInternalPageBreak:NO];
            nextY = NSMaxY(currentPositionedBlock.frame);
            currentPositionedBlock = currentPositionedBlock.parent;
            CGRect potentialFrame = currentPositionedBlock.frame;
            if(potentialFrame.size.height != CGFLOAT_MAX) {
                potentialFrame.size.height = CGRectGetMaxY(potentialFrame) - nextY;
            }
            potentialFrame.origin.y = nextY;
        }
        
        [positionedRoot closeBottomFromYPoint:nextY atInternalPageBreak:NO];

        return positionedRoot;
    } else {
        return nil;
    }
}
    
/*
    NSMutableArray *laidOutChildren = [[NSMutableArray alloc] init];
        
    CGFloat currentY;
    
    EucHTMLBaseNode *previousSubnode = node;
    EucHTMLBaseNode *subnode = [node nextUnder:node];
    while(subnode != nil) {         
        css_computed_style *subnodeStyle;
        BOOL isInline;
        if([subnode isTextNode]) {
            subnodeStyle = nil;
            isInline = YES;
        } else {
            subnodeStyle = [subnode computedStyle];
            isInline = (css_computed_display(subnodeStyle, false) & CSS_DISPLAY_INLINE) == CSS_DISPLAY_INLINE;
        }
// 
        
//        If subnode is block
//            Add previous block to laid out children list.
//            Start new line (take into account "clear").
//            Performing margin collapsing.
//            If content of block is over the end of the page
//                Return.
//
//        If subnode is float
        if(subnodeStyle && css_computed_float(subnodeStyle) != CSS_FLOAT_NONE) {
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
            uint32_t runId;
            if(subnode == [subnode.parent.children objectAtIndex:0]) {
                runId = subnode.parent.key;
            } else {
                runId = subnode.key;
            }
            EucHTMLLayoutDocumentRun *run = [[EucHTMLLayoutDocumentRun alloc] initWithNode:subnode
                                                                                 underNode:node
                                                                                     forId:runId];
            EucHTMLLayoutPositionedRun *positionedRun = [run positionedRunForBounds:
            
            previousSubnode = inlineNode;
            subnode = [inlineNode nextUnder:node];
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
 
}*/


@end
