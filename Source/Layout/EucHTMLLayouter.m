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

#import <parserutils/utils/stack.h>

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


- (BOOL)_trimBlockToFrame:(CGRect)frame returningNextPoint:(EucHTMLLayoutPoint *)returningNextPoint
{
    
}
 

- (EucHTMLLayoutPositionedBlock *)layoutFromPoint:(EucHTMLLayoutPoint)point
                                          inFrame:(CGRect)frame
                               returningNextPoint:(EucHTMLLayoutPoint *)returningNextPoint
                               returningCompleted:(BOOL *)returningCompleted
{
    EucHTMLLayoutPositionedBlock *positionedRoot = nil;      
    
    /*
     
        In the normal flow, page breaks can occur at the following places:
    
             1) In the vertical margin between block boxes. When an unforced 
                page break occurs here, the used values of the relevant 
                'margin-top' and 'margin-bottom' properties are set to '0'.
                When a forced page break occurs here, the used value of the
                relevant 'margin-bottom' property is set to '0'; the relevant
                'margin-top' used value may either be set to '0' or retained.
             2) Between line boxes inside a block box.
             3) Between the content edge of a block box and the outer edges of
                its child content (margin edges of block-level children or line
                box edges for inline-level children) if there is a (non-zero)
                gap between them.

          Note: It is expected that CSS3 will specify that the relevant 
                'margin-top' applies (i.e., is not set to '0') after a forced 
                page break.


        These breaks are subject to the following rules:
        
        Rule A: Breaking at (1) is allowed only if the 'page-break-after' and
                'page-break-before' properties of all the elements generating
                boxes that meet at this margin allow it, which is when at least
                one of them has the value 'always', 'left', or 'right', or when
                all of them are 'auto'.
        Rule B: However, if all of them are 'auto' and a common ancestor of all
                the elements has a 'page-break-inside' value of 'avoid', then
                breaking here is not allowed.
        Rule C: Breaking at (2) is allowed only if the number of line boxes
                between the break and the start of the enclosing block box is
                the value of 'orphans' or more, and the number of line boxes
                between the break and the end of the box is the value of
                'widows' or more.
        Rule D: In addition, breaking at (2) or (3) is allowed only if the
                'page-break-inside' property of the element and all its
                ancestors is 'auto'.


        Reformulating:
    
        Always: Between the content edge of a block box and the outer edges of
                its child content (margin edges of block-level children or line
                box edges for inline-level children) if there is a (non-zero)
                gap between them, only if the 'page-break-inside' property of
                the element and all its ancestors is 'auto'.
     
        Rule A: In the vertical margin between block boxes, only when at least
                one of them have 'page-break-after' and 'page-break-before' 
                properties of the value 'always', 'left', or 'right', or when
                all of them are 'auto' /unless/ all of them are 'auto', and 
                a common ancestor has a 'page-break-inside' value of 'avoid'.
     
        Rule B: [ Not in effect initially ].
                In the vertical margin between block boxes, only when at all the
                'page-break-after' and 'page-break-before' are 'auto', and 
                a common ancestor has a 'page-break-inside' value of 'avoid'.
     
        Rule C: Between line boxes inside a block box, if the number of line
                boxes between the break and the start of the enclosing block 
                box is the value of 'orphans' or more, and the number of line
                boxes between the break and the end of the box is the value of
                'widows' or more, only if the 'page-break-inside' property of
                the element and all its ancestors is 'auto'.
        
        Rule D: [ Not in effect initially ].
                Between the content edge of a block box and the outer edges of
                its child content (margin edges of block-level children or line
                box edges for inline-level children) if there is a (non-zero)
                gap between them, only if the 'page-break-inside' property of
                the element and all its ancestors is NOT 'auto'.
                Between line boxes inside a block box, if the number of line
                boxes between the break and the start of the enclosing block 
                box is the value of 'orphans' or more, and the number of line
                boxes between the break and the end of the box is the value of
                'widows' or more, only if the 'page-break-inside' property of
                the element and all its ancestors is NOT 'auto'.
     
    */                
    
    parserutils_stack *aBreakpoints, *bBreakpoints, *cBreakpoints, *dBreakpoints;
    parserutils_stack_create(sizeof(EucHTMLLayoutPoint), 64, EucRealloc, NULL, &aBreakpoints);
    parserutils_stack_create(sizeof(EucHTMLLayoutPoint), 64, EucRealloc, NULL, &bBreakpoints);
    parserutils_stack_create(sizeof(EucHTMLLayoutPoint), 64, EucRealloc, NULL, &cBreakpoints);
    parserutils_stack_create(sizeof(EucHTMLLayoutPoint), 64, EucRealloc, NULL, &dBreakpoints);
    
    uint32_t nodeKey = point.nodeKey;
    uint32_t wordOffset = point.word;
    uint32_t elementOffset = point.element;
    
    EucHTMLDocument *document = self.document;
    EucHTMLDocumentNode* currentDocumentNode = [document nodeForKey:nodeKey];
    
    if(currentDocumentNode) {
        css_computed_style *currentNodeStyle = currentDocumentNode.computedStyle;

        EucHTMLLayoutPositionedBlock *currentPositionedBlock = nil;
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
        
        BOOL reachedBottomOfFrame = NO;
        EucHTMLLayoutPoint nextPointAfterBottomOfFrame;
        
        CGFloat nextY = frame.origin.y;
        uint32_t nextRunNodeKey = ((EucHTMLDocumentConcreteNode *)currentDocumentNode).key;
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
                                                                                                 forId:nextRunNodeKey];
                
                // Position it.
                BOOL positionedRunIsComplete;
                EucHTMLLayoutPositionedRun *positionedRun = [documentRun positionedRunForFrame:potentialFrame
                                                                                    wordOffset:wordOffset
                                                                                 elementOffset:elementOffset
                                                                            returningCompleted:&positionedRunIsComplete];
                if(positionedRun) {
                    [currentPositionedBlock addSubEntity:positionedRun];
                }
                if(!positionedRunIsComplete) {
                    reachedBottomOfFrame = YES;
                    nextPointAfterBottomOfFrame.nodeKey = nextRunNodeKey;
                    if(positionedRun) {
                        EucHTMLLayoutLine *lastLine = positionedRun.lines.lastObject;
                        EucHTMLLayoutDocumentRunPoint lastLineEndPoint = lastLine.endPoint;
                        
                        nextPointAfterBottomOfFrame.word = lastLineEndPoint.word;
                        nextPointAfterBottomOfFrame.element = lastLineEndPoint.element;
                    } else {
                        nextPointAfterBottomOfFrame.word = wordOffset;
                        nextPointAfterBottomOfFrame.element = elementOffset;
                    }
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
                    nextRunNodeKey = ((EucHTMLDocumentConcreteNode *)currentDocumentNode).key;
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
                nextRunNodeKey = ((EucHTMLDocumentConcreteNode *)currentDocumentNode).key;  
                
                currentDocumentNode = currentDocumentNode.next;
            }
        } while(!reachedBottomOfFrame && currentDocumentNode);
        
        while(currentPositionedBlock) {
            [currentPositionedBlock closeBottomFromYPoint:nextY atInternalPageBreak:reachedBottomOfFrame];
            nextY = NSMaxY(currentPositionedBlock.frame);
            currentPositionedBlock = currentPositionedBlock.parent;
            CGRect potentialFrame = currentPositionedBlock.frame;
            if(potentialFrame.size.height != CGFLOAT_MAX) {
                potentialFrame.size.height = CGRectGetMaxY(potentialFrame) - nextY;
            }
            potentialFrame.origin.y = nextY;
        }
        
        [positionedRoot closeBottomFromYPoint:nextY atInternalPageBreak:NO];

        if(returningCompleted) {
            *returningCompleted = !reachedBottomOfFrame;
        }
        if(!reachedBottomOfFrame && returningNextPoint) {
            *returningNextPoint = nextPointAfterBottomOfFrame;
        }
    }
    
    parserutils_stack_destroy(aBreakpoints);
    parserutils_stack_destroy(bBreakpoints);
    parserutils_stack_destroy(cBreakpoints);
    parserutils_stack_destroy(dBreakpoints);
    
    return positionedRoot;
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
