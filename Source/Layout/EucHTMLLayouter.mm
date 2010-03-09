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
#import "THLog.h"
#import "thjust.h"

#import <vector>
#import <utility>
using namespace std;

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
    EucHTMLLayoutPositionedBlock *newContainer;
    EucHTMLLayoutPositionedBlock *outermost;
    
    EucHTMLDocumentNode *blockLevelParent = node.blockLevelParent;
    if(blockLevelParent) {
        EucHTMLLayoutPositionedBlock *parentContainer = nil;
        outermost = [self _constructBlockAndAncestorsForNode:blockLevelParent
                                          returningInnermost:&parentContainer
                                                     inFrame:frame
                                      afterInternalPageBreak:YES];
        
        newContainer = [[[EucHTMLLayoutPositionedBlock alloc] initWithDocumentNode:node] autorelease];
        newContainer.documentNode = node;
        [newContainer positionInFrame:parentContainer.contentRect afterInternalPageBreak:afterInternalPageBreak];
        
        [parentContainer addSubEntity:newContainer];
    } else {
        newContainer = [[[EucHTMLLayoutPositionedBlock alloc] initWithDocumentNode:node] autorelease];
        newContainer.documentNode = node;
        [newContainer positionInFrame:frame afterInternalPageBreak:afterInternalPageBreak];
        
        outermost = newContainer;
    }
    
    *innermost = newContainer;
    return outermost;
}


-   (BOOL)_trimBlockToFrame:(CGRect)frame 
         returningNextPoint:(EucHTMLLayoutPoint *)returningNextPoint
                 pageBreaks:(vector< pair< EucHTMLLayoutPoint, id> > *)pageBreaks
pageBreaksDisallowedByRuleA:(vector<EucHTMLLayoutPoint> *)pageBreaksDisallowedByRuleA
pageBreaksDisallowedByRuleB:(vector<EucHTMLLayoutPoint> *)pageBreaksDisallowedByRuleB
pageBreaksDisallowedByRuleC:(vector<EucHTMLLayoutPoint> *)pageBreaksDisallowedByRuleC
pageBreaksDisallowedByRuleD:(vector<EucHTMLLayoutPoint> *)pageBreaksDisallowedByRuleD
{
    vector< pair< EucHTMLLayoutPoint, id> >::reverse_iterator pageBreakIt = pageBreaks->rbegin();
    vector< pair< EucHTMLLayoutPoint, id> >::reverse_iterator pageBreakItEnd = pageBreaks->rend();

    CGFloat maxY = CGRectGetMaxY(frame);

    id element;
    CGRect elementFrame;

    if(THWillLogVerbose()) {
        NSLog(@"All Breaks:");
        while(pageBreakIt != pageBreakItEnd) {
            EucHTMLLayoutPoint point = pageBreakIt->first;
            element = pageBreakIt->second;
            elementFrame = [element frame];        
            
            THLogVerbose(@"[%ld, %ld, %ld], %@, %@", point.nodeKey, point.word, point.element, NSStringFromRect(elementFrame),NSStringFromClass([element class]));
            
            ++pageBreakIt;
        } 
        
        pageBreakIt = pageBreaks->rbegin();
    }
    
    THLogVerbose(@"Choosing:");
    while(pageBreakIt != pageBreakItEnd) {
        element = pageBreakIt->second;
        elementFrame = [element frame];        
        
        if(THWillLogVerbose()) {
            EucHTMLLayoutPoint point = pageBreakIt->first;
            THLogVerbose(@"[%ld, %ld, %ld], %f, %@, %@", point.nodeKey, point.word, point.element, NSStringFromRect(elementFrame), NSStringFromClass([element class]));
        }
        if(elementFrame.origin.y <= maxY) {
            // The origin of the element after the break matches is the 
            // break's y position.  This break is the 'first' one on the page
            // (counting backwards through the possible breaks) so we should 
            // break at it, removing this element and all the ones after it.
            break;
        }
        ++pageBreakIt;
    } 
    
    if(pageBreakIt != pageBreakItEnd) {
        EucHTMLLayoutPoint point = pageBreakIt->first;
        id element = pageBreakIt->second;
        
        EucHTMLLayoutPositionedBlock *block;
        
        BOOL flattenBottomMargin = NO;
        if([element isKindOfClass:[EucHTMLLayoutLine class]]) {
            EucHTMLLayoutLine *line = (EucHTMLLayoutLine *)element;
            EucHTMLLayoutPositionedRun *run = line.containingRun;
            
            block = run.containingBlock;

            // Remove all the lines from this one on from this run.
            NSArray *lines = run.lines;
            NSUInteger lineIndex = [lines indexOfObject:line];
            NSArray *newLines = [lines subarrayWithRange:NSMakeRange(0, lineIndex)];
            run.lines = newLines;
            
            CGRect runFrame = run.frame;
            runFrame.size.height = CGRectGetMaxY([newLines.lastObject frame]) - runFrame.origin.y;
            run.frame = runFrame;
            
            // Remove all the runs after this one from the block.
            NSArray *subEntities = block.subEntities;
            NSUInteger runIndex = [subEntities indexOfObject:run];
            if(runIndex < subEntities.count) {
                block.subEntities = [subEntities subarrayWithRange:NSMakeRange(0, runIndex + 1)];
            }
        } else {
            // Remove all the blocks from this one on from its parent.
            block = (EucHTMLLayoutPositionedBlock *)element;

            EucHTMLLayoutPositionedBlock *blockParent = block.parent;
            NSArray *blockParentChildren = blockParent.subEntities;
            NSUInteger blockIndex = [blockParentChildren indexOfObject:block];
            blockParent.subEntities = [blockParentChildren subarrayWithRange:NSMakeRange(0, blockIndex)];
                        
            block = blockParent;
        }
        
        // Resize and close the 'last' block (the parent of the element we just
        // removed).
        CGFloat pageBottom = CGRectGetMaxY(frame);

        [block closeBottomFromYPoint:pageBottom atInternalPageBreak:flattenBottomMargin];
        EucHTMLLayoutPositionedBlock *blockParent = block.parent;
        
        // Remove all the blocks after this one, and re-close all the parents
        // on the way up, stretching them down to the bottom of the page.
        while(blockParent) {
            NSArray *blockParentChildren = blockParent.subEntities;
            NSUInteger blockIndex = [blockParentChildren indexOfObject:block];
            if(blockIndex < blockParentChildren.count) {
                blockParent.subEntities = [blockParentChildren subarrayWithRange:NSMakeRange(0, blockIndex + 1)];
            }
            [blockParent closeBottomFromYPoint:pageBottom atInternalPageBreak:YES];
            
            block = blockParent;
            blockParent = block.parent;
        }
        
        *returningNextPoint = point;
        return YES;
    }
    return NO;
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

        If the above does not provide enough break points to keep content from
        overflowing the page boxes, then rules A, B and D are dropped in order
        to find additional breakpoints.
     
        If that still does not lead to sufficient break points, rule C is
        dropped as well, to find still more break points.
          
    */                

    vector< pair< EucHTMLLayoutPoint, id> > pageBreaks;
    vector< EucHTMLLayoutPoint > pageBreaksDisallowedByRuleA;
    vector< EucHTMLLayoutPoint > pageBreaksDisallowedByRuleB;
    vector< EucHTMLLayoutPoint > pageBreaksDisallowedByRuleC;
    vector< EucHTMLLayoutPoint > pageBreaksDisallowedByRuleD;

    uint32_t nodeKey = point.nodeKey;
    uint32_t wordOffset = point.word;
    uint32_t elementOffset = point.element;
    
    EucHTMLDocument *document = self.document;
    EucHTMLDocumentNode* currentDocumentNode;
    if(!point.nodeKey) {
        currentDocumentNode = document.rootNode;
    } else {
        currentDocumentNode = [document nodeForKey:nodeKey];
    }
                                                
    if(currentDocumentNode) {
        css_computed_style *currentNodeStyle = currentDocumentNode.computedStyle;

        CGRect bottomlessFrame = CGRectMake(frame.origin.x, frame.origin.x, frame.size.width, CGFLOAT_MAX);
        EucHTMLLayoutPositionedBlock *currentPositionedBlock = nil;
        if(!currentNodeStyle || (css_computed_display(currentNodeStyle, false) & CSS_DISPLAY_BLOCK) != CSS_DISPLAY_BLOCK) {
            positionedRoot = [self _constructBlockAndAncestorsForNode:currentDocumentNode.blockLevelParent
                                                   returningInnermost:&currentPositionedBlock
                                                              inFrame:bottomlessFrame
                                               afterInternalPageBreak:YES];               
        } else {
            positionedRoot = [self _constructBlockAndAncestorsForNode:currentDocumentNode
                                                   returningInnermost:&currentPositionedBlock
                                                              inFrame:bottomlessFrame
                                               afterInternalPageBreak:NO];
            currentDocumentNode = currentDocumentNode.nextDisplayable;
        }
                
        BOOL reachedBottomOfFrame = NO;
        
        uint32_t nextRunNodeKey = nodeKey;
        CGFloat nextY = frame.origin.y;
        CGFloat maxY = CGRectGetMaxY(frame);
        do {
            CGRect potentialFrame = currentPositionedBlock.contentRect;
            NSParameterAssert(potentialFrame.size.height == CGFLOAT_MAX);
            
            potentialFrame.origin.y = nextY;
            
            css_computed_style *currentNodeStyle = currentDocumentNode.computedStyle;
            if(!currentNodeStyle || (css_computed_display(currentNodeStyle, false) & CSS_DISPLAY_BLOCK) != CSS_DISPLAY_BLOCK) {
                //THLog(@"Inline: %@", [currentDocumentNode name]);
                
                // This is an inline element - start a run.
                EucHTMLLayoutDocumentRun *documentRun = [[EucHTMLLayoutDocumentRun alloc] initWithNode:currentDocumentNode
                                                                                        underLimitNode:currentDocumentNode.parent
                                                                                                 forId:nextRunNodeKey];
                
                // Position it.
                EucHTMLLayoutPositionedRun *positionedRun = [documentRun positionedRunForFrame:potentialFrame
                                                                                    wordOffset:wordOffset
                                                                                 elementOffset:elementOffset];
                if(positionedRun) {
                    [currentPositionedBlock addSubEntity:positionedRun];
                    
                    BOOL first = YES; // Break before last line doesn't count.
                    for(EucHTMLLayoutLine *line in positionedRun.lines) {
                        if(!first) {
                            EucHTMLLayoutDocumentRunPoint startPoint = line.startPoint;
                            EucHTMLLayoutPoint breakPoint = { nextRunNodeKey, startPoint.word, startPoint.element };
                            pageBreaks.push_back(make_pair(breakPoint, line));
                        } else {
                            first = NO;
                        }
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
                //THLog(@"Block: %@", [currentDocumentNode name]);
                
                // This is a block-level element.

                // Find the block's parent, closing open nodes until we reach it.
                BOOL hasPreviousSibling = NO;
                EucHTMLDocumentNode *currentDocumentNodeBlockLevelParent = currentDocumentNode.blockLevelParent;
                while(currentPositionedBlock.documentNode != currentDocumentNodeBlockLevelParent) {
                    [currentPositionedBlock closeBottomFromYPoint:nextY atInternalPageBreak:NO];
                    nextY = NSMaxY(currentPositionedBlock.frame);
                    currentPositionedBlock = currentPositionedBlock.parent;
                    hasPreviousSibling = YES;
                }
                CGRect potentialFrame = currentPositionedBlock.contentRect;
                NSParameterAssert(potentialFrame.size.height == CGFLOAT_MAX);

                potentialFrame.origin.y = nextY;
                                
                EucHTMLLayoutPositionedBlock *newBlock = [[EucHTMLLayoutPositionedBlock alloc] initWithDocumentNode:currentDocumentNode];
                [newBlock positionInFrame:potentialFrame afterInternalPageBreak:NO];
                [currentPositionedBlock addSubEntity:newBlock];                    
                
                currentPositionedBlock = [newBlock autorelease];

                nextY = newBlock.contentRect.origin.y;
                
                if(hasPreviousSibling) {
                    EucHTMLLayoutPoint breakPoint = { currentDocumentNode.key, 0, 0 };
                    pageBreaks.push_back(make_pair(breakPoint, newBlock));
                }                
                
                // First run in a block has the ID of the block it's in.
                nextRunNodeKey = ((EucHTMLDocumentConcreteNode *)currentDocumentNode).key;  
                
                currentDocumentNode = currentDocumentNode.nextDisplayable;
            }
            reachedBottomOfFrame = nextY >= maxY;
        } while(!reachedBottomOfFrame && currentDocumentNode);
        
        if(!reachedBottomOfFrame) {
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
        }
    
        EucHTMLLayoutPoint nextPoint;
        BOOL nextPointValid = [self _trimBlockToFrame:frame 
                                   returningNextPoint:&nextPoint
                                           pageBreaks:&pageBreaks
                          pageBreaksDisallowedByRuleA:&pageBreaksDisallowedByRuleA
                          pageBreaksDisallowedByRuleB:&pageBreaksDisallowedByRuleB
                          pageBreaksDisallowedByRuleC:&pageBreaksDisallowedByRuleC
                          pageBreaksDisallowedByRuleD:&pageBreaksDisallowedByRuleD];
        
        if(nextPointValid) {
            *returningNextPoint = nextPoint;
            *returningCompleted = NO;
        } else {
            *returningCompleted = YES;
        }
    }
    
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
