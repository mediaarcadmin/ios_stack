//
//  EucCSSLayouter.h
//  LibCSSTest
//
//  Created by James Montgomerie on 13/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSInternal.h"
#import "EucCSSLayouter.h"

#import "EucCSSIntermediateDocument.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "EucCSSIntermediateDocumentConcreteNode.h"

#import "EucCSSLayoutPositionedBlock.h"
#import "EucCSSLayoutPositionedRun.h"
#import "EucCSSLayoutRun.h"
#import "EucCSSLayoutSizedRun.h"
#import "EucCSSLayoutPositionedLine.h"
#import "EucCSSLayoutRunExtractor.h"

#import "EucCSSLayoutTableWrapper.h"

#import "THStringRenderer.h"
#import "THPair.h"
#import "THLog.h"
#import "th_just_with_floats.h"

#import <libcss/libcss.h>

#import <vector>
#import <utility>
using namespace std;

@implementation EucCSSLayouter

@synthesize document = _document;
@synthesize scaleFactor = _scaleFactor;

- (id)initWithDocument:(EucCSSIntermediateDocument *)document
           scaleFactor:(CGFloat)scaleFactor
{
    if((self = [super init])) {
        _document = [document retain];
        _scaleFactor = scaleFactor;
    }
    return self;
}

- (id)init
{
    return [self initWithDocument:nil scaleFactor:1.0f];
}

- (void)dealloc
{
    [_document release];
    
    [super dealloc];
}

/*
Return words, 
Line start x positions and widths,
Line end word and hyphenation points, 
Block contents x/y position.
Block completion status.
*/

- (EucCSSLayoutPositionedBlock *)_constructBlockAndAncestorsForNode:(EucCSSIntermediateDocumentNode *)node
                                                 returningInnermost:(EucCSSLayoutPositionedBlock **)innermost
                                                            inFrame:(CGRect)frame
                                             afterInternalPageBreak:(BOOL)afterInternalPageBreak
{
    EucCSSLayoutPositionedBlock *newContainer;
    EucCSSLayoutPositionedBlock *outermost;
    
    EucCSSIntermediateDocumentNode *blockLevelParent = node.blockLevelParent;
    if(blockLevelParent) {
        EucCSSLayoutPositionedBlock *parentContainer = nil;
        outermost = [self _constructBlockAndAncestorsForNode:blockLevelParent
                                          returningInnermost:&parentContainer
                                                     inFrame:frame
                                      afterInternalPageBreak:YES];
        
        newContainer = [[EucCSSLayoutPositionedBlock alloc] initWithDocumentNode:node scaleFactor:_scaleFactor];
        newContainer.documentNode = node;
        CGRect potentialFrame = parentContainer.contentBounds;
        [newContainer positionInFrame:potentialFrame afterInternalPageBreak:afterInternalPageBreak];
        
        [parentContainer addChild:newContainer];
        [newContainer release];
    } else {
        newContainer = [[EucCSSLayoutPositionedBlock alloc] initWithDocumentNode:node scaleFactor:_scaleFactor];
        newContainer.documentNode = node;
        [newContainer positionInFrame:frame afterInternalPageBreak:afterInternalPageBreak];
        
        outermost = [newContainer autorelease];
    }
    
    *innermost = newContainer;
    return outermost;
}


-   (BOOL)_trimBlockToFrame:(CGRect)frame 
         returningNextPoint:(EucCSSLayoutPoint *)returningNextPoint
                 pageBreaks:(vector< pair< EucCSSLayoutPoint, EucCSSLayoutPositionedContainer *> > *)pageBreaks
pageBreaksDisallowedByRuleA:(vector<EucCSSLayoutPoint> *)pageBreaksDisallowedByRuleA
pageBreaksDisallowedByRuleB:(vector<EucCSSLayoutPoint> *)pageBreaksDisallowedByRuleB
pageBreaksDisallowedByRuleC:(vector<EucCSSLayoutPoint> *)pageBreaksDisallowedByRuleC
pageBreaksDisallowedByRuleD:(vector<EucCSSLayoutPoint> *)pageBreaksDisallowedByRuleD
{
    vector< pair< EucCSSLayoutPoint, EucCSSLayoutPositionedContainer *> >::reverse_iterator pageBreakReverseIterator = pageBreaks->rbegin();
    vector< pair< EucCSSLayoutPoint, EucCSSLayoutPositionedContainer *> >::reverse_iterator pageBreakReverseIteratorEnd = pageBreaks->rend();

    CGFloat maxY = CGRectGetMaxY(frame);

    EucCSSLayoutPositionedContainer *element;
    CGRect elementAbsoluteFrame;

    if(THWillLogVerbose()) {
        THLog(@"All Breaks:");
        while(pageBreakReverseIterator != pageBreakReverseIteratorEnd) {
            EucCSSLayoutPoint point = pageBreakReverseIterator->first;
            element = pageBreakReverseIterator->second;
            elementAbsoluteFrame = element.absoluteFrame;        
            
            THLogVerbose(@"[%ld, %ld, %ld], %@, %@", point.nodeKey, point.word, point.element, NSStringFromCGRect(elementAbsoluteFrame), NSStringFromClass([element class]));
            
            ++pageBreakReverseIterator;
        } 
        
        pageBreakReverseIterator = pageBreaks->rbegin();
    }
    
    THLogVerbose(@"Choosing:");
    while(pageBreakReverseIterator != pageBreakReverseIteratorEnd) {
        element = pageBreakReverseIterator->second;
        elementAbsoluteFrame = element.absoluteFrame;        
        
        if(THWillLogVerbose()) {
            EucCSSLayoutPoint point = pageBreakReverseIterator->first;
            THLogVerbose(@"[%ld, %ld, %ld], %f, %@, %@", point.nodeKey, point.word, point.element, maxY, NSStringFromCGRect(elementAbsoluteFrame), NSStringFromClass([element class]));
        }
        if(elementAbsoluteFrame.origin.y <= maxY) {
            // The origin of the element after the break matches is the 
            // break's y position.  This break is the 'first' one on the page
            // (counting backwards through the possible breaks) so we should 
            // break at it, removing this element and all the ones after it.
            break;
        }
        ++pageBreakReverseIterator;
    } 
    
    if(pageBreakReverseIterator != pageBreakReverseIteratorEnd) {
        EucCSSLayoutPoint point = pageBreakReverseIterator->first;
        EucCSSLayoutPositionedContainer *element = pageBreakReverseIterator->second;
        
        EucCSSLayoutPositionedBlock *block;
        
        BOOL flattenBottomMargin = NO;
        if([element isKindOfClass:[EucCSSLayoutPositionedLine class]]) {
            EucCSSLayoutPositionedLine *line = (EucCSSLayoutPositionedLine *)element;
            EucCSSLayoutPositionedRun *run = (EucCSSLayoutPositionedRun *)line.parent;
            
            block = (EucCSSLayoutPositionedBlock *)run.parent;

            // Remove all the lines from this one on from this run.
            NSMutableArray *lines = run.children;
            NSUInteger lineIndex = [lines indexOfObject:line];
            [lines removeObjectsInRange:NSMakeRange(lineIndex, lines.count - lineIndex)];
            
            CGRect runFrame = run.frame;
            runFrame.size.height = CGRectGetMaxY([lines.lastObject frame]) - runFrame.origin.y;
            run.frame = runFrame;
            
            // Remove all the runs after this one from the block.
            NSMutableArray *children = block.children;
            NSUInteger runIndex = [children indexOfObject:run];
            NSUInteger childrenCount = children.count;
            if(runIndex < childrenCount) {
                NSRange rangeToRemove;
                rangeToRemove.location = runIndex + 1;
                rangeToRemove.length = childrenCount - rangeToRemove.location;       
                [children removeObjectsInRange:rangeToRemove];
            }
        } else {
            // Remove all the blocks from this one on from its parent.
            block = (EucCSSLayoutPositionedBlock *)element;

            EucCSSLayoutPositionedBlock *blockParent = (EucCSSLayoutPositionedBlock *)block.parent;
            NSMutableArray *blockParentChildren = blockParent.children;
            NSUInteger blockIndex = [blockParentChildren indexOfObject:block];
            [blockParentChildren removeObjectsInRange:NSMakeRange(blockIndex, blockParentChildren.count - blockIndex)];
                        
            block = blockParent;
        }
        
        // Resize and close the 'last' block (the parent of the element we just
        // removed).
        CGFloat pageBottom = CGRectGetMaxY(frame);
        CGFloat contentHeightToCloseAt = pageBottom - [block convertRect:block.contentBounds 
                                                             toContainer:nil].origin.y;
        [block closeBottomWithContentHeight:contentHeightToCloseAt atInternalPageBreak:flattenBottomMargin];
        
        // Remove all the blocks after this one, and re-close all the parents
        // on the way up, stretching them down to the bottom of the page.
        EucCSSLayoutPositionedBlock *blockParent = (EucCSSLayoutPositionedBlock *)block.parent;
        while(blockParent) {
            NSMutableArray *blockParentChildren = blockParent.children;
            NSUInteger blockIndex = [blockParentChildren indexOfObject:block];
            NSUInteger blockParentChildrenCount = blockParentChildren.count;
            if(blockIndex < blockParentChildrenCount) {
                NSRange rangeToRemove;
                rangeToRemove.location = blockIndex + 1;
                rangeToRemove.length = blockParentChildrenCount - rangeToRemove.location;       
                [blockParentChildren removeObjectsInRange:rangeToRemove];
            }
            
            CGFloat contentHeightToCloseAt = pageBottom - [blockParent convertRect:blockParent.contentBounds 
                                                                            toContainer:nil].origin.y;
            [blockParent closeBottomWithContentHeight:contentHeightToCloseAt atInternalPageBreak:YES];
            
            block = blockParent;
            blockParent = (EucCSSLayoutPositionedBlock *)block.parent;
        }
        
        *returningNextPoint = point;
        return YES;
    }
    return NO;
}
 

- (EucCSSLayoutPoint)layoutPointForNode:(EucCSSIntermediateDocumentNode *)node
{
    EucCSSLayoutPoint ret = {0};
    
    EucCSSLayoutRunExtractor *extractor = [[EucCSSLayoutRunExtractor alloc] initWithDocument:node.document];
    EucCSSLayoutRun *run = [extractor runForNodeWithKey:node.key];
        
    if(run) {
        EucCSSLayoutRunPoint runPoint = [run pointForNode:node];
        ret.nodeKey = run.id;
        ret.word = runPoint.word;
        ret.element = runPoint.element;
    }   
    
    [extractor release];
    
    return ret;
}

- (EucCSSIntermediateDocumentNode *)_layoutNodeForKey:(uint32_t)nodeKey
{
    if(nodeKey == 0) {
        return self.document.rootNode;
    } else {
        return [self.document nodeForKey:nodeKey];
    }
}

- (EucCSSLayoutPositionedBlock *)_layoutFromPoint:(EucCSSLayoutPoint)point
                                          inFrame:(CGRect)frame
                               returningNextPoint:(EucCSSLayoutPoint *)returningNextPoint
                               returningCompleted:(BOOL *)returningCompleted
                                 lastBlockNodeKey:(uint32_t)lastBlockNodeKey
                            stopBeforeNodeWithKey:(uint32_t)stopBeforeNodeKey
                            constructingAncestors:(BOOL)constructingAncestors
{
    EucCSSLayoutPositionedBlock *positionedRoot = nil;      
    
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

    vector< pair< EucCSSLayoutPoint, EucCSSLayoutPositionedContainer *> > pageBreaks;
    vector< EucCSSLayoutPoint > pageBreaksDisallowedByRuleA;
    vector< EucCSSLayoutPoint > pageBreaksDisallowedByRuleB;
    vector< EucCSSLayoutPoint > pageBreaksDisallowedByRuleC;
    vector< EucCSSLayoutPoint > pageBreaksDisallowedByRuleD;

    uint32_t nodeKey = point.nodeKey;
    uint32_t wordOffset = point.word;
    uint32_t elementOffset = point.element;
    
    EucCSSIntermediateDocument *document = self.document;
    EucCSSIntermediateDocumentNode* currentDocumentNode = [self _layoutNodeForKey:nodeKey];

    EucCSSIntermediateDocumentNode *lastBlockNode;
    if(lastBlockNodeKey) {
        lastBlockNode = [_document nodeForKey:lastBlockNodeKey];
    } else {
        lastBlockNode = nil;
    }
    
    EucCSSIntermediateDocumentNode *stopBeforeNode;
    if(stopBeforeNodeKey) {
        stopBeforeNode = [_document nodeForKey:stopBeforeNodeKey];
    } else {
        stopBeforeNode = nil;
    }
    
    if(currentDocumentNode) {
        CGRect bottomlessFrame = CGRectMake(frame.origin.x, frame.origin.x, frame.size.width, CGFLOAT_MAX);
        EucCSSLayoutPositionedBlock *currentPositionedBlock = nil;
        if(constructingAncestors) {
            if(currentDocumentNode.display != CSS_DISPLAY_BLOCK) {
                EucCSSIntermediateDocumentNode *blockLevelParent = currentDocumentNode.blockLevelParent;
                if(!blockLevelParent) {
                    blockLevelParent = document.rootNode;
                }
                positionedRoot = [self _constructBlockAndAncestorsForNode:blockLevelParent
                                                       returningInnermost:&currentPositionedBlock
                                                                  inFrame:bottomlessFrame
                                                   afterInternalPageBreak:YES];               
            } else {
                // We set afterInternalPageBreak to YES on anything but the root 
                // node in order to remove its top margin.  The CSS spec says:
                
                // 5.4. Allowed page breaks
                // In the normal flow, page breaks may occur at the following places:
                // 1. In the vertical margin between block boxes (or rows in a table).
                //    When a page break occurs here, the computed values of the relevant
                //    'margin-top' and 'margin-bottom' properties are set to '0'.
                positionedRoot = [self _constructBlockAndAncestorsForNode:currentDocumentNode
                                                       returningInnermost:&currentPositionedBlock
                                                                  inFrame:bottomlessFrame
                                                   afterInternalPageBreak:nodeKey != document.rootNode.key];
                currentDocumentNode = currentDocumentNode.nextDisplayable;
            } 
        } else {
            positionedRoot = [[EucCSSLayoutPositionedBlock alloc] initWithDocumentNode:currentDocumentNode
                                                                           scaleFactor:_scaleFactor];
            [positionedRoot positionInFrame:frame afterInternalPageBreak:NO];
            currentPositionedBlock = positionedRoot;
            currentDocumentNode = currentDocumentNode.nextDisplayable;
        }
                
        BOOL closedLastNode = NO;
        BOOL reachedBottomOfFrame = NO;
        
        uint32_t nextRunNodeKey = nodeKey;
        CGFloat nextAbsoluteY = [currentPositionedBlock convertRect:currentPositionedBlock.contentBounds toContainer:nil].origin.y;
        CGFloat maxAbsoluteY = CGRectGetMaxY(frame);
        
        THPair *activeFloats = nil;
        
        BOOL pageBreakForced = NO;
        
        while(!pageBreakForced && !reachedBottomOfFrame && 
              !closedLastNode && currentDocumentNode) {     
            if(currentDocumentNode == stopBeforeNode) {
                break;
            }
            
            // Find the node's parent, closing open blocks until we reach it.
            EucCSSIntermediateDocumentNode *currentDocumentNodeBlockLevelParent = currentDocumentNode.blockLevelParent;
            EucCSSIntermediateDocumentNode *currentPositionedBlockNode;
            while((currentPositionedBlockNode = currentPositionedBlock.documentNode) != currentDocumentNodeBlockLevelParent) {
                CGFloat contentHeightToCloseAt = nextAbsoluteY - [currentPositionedBlock convertRect:currentPositionedBlock.contentBounds 
                                                                                         toContainer:nil].origin.y;

                [currentPositionedBlock closeBottomWithContentHeight:contentHeightToCloseAt atInternalPageBreak:NO];
                nextAbsoluteY = CGRectGetMaxY(currentPositionedBlock.absoluteFrame);
                
                currentPositionedBlock = (EucCSSLayoutPositionedBlock *)currentPositionedBlock.parent;
                if(currentPositionedBlockNode == lastBlockNode) {
                    closedLastNode = YES;
                    break;
                }
            }

            if(!closedLastNode) {
                CGRect potentialFrame = currentPositionedBlock.contentBounds;
                NSParameterAssert(potentialFrame.size.height == CGFLOAT_MAX);

                potentialFrame.origin.y = nextAbsoluteY - [currentPositionedBlock convertRect:potentialFrame 
                                                                                  toContainer:nil].origin.y;

                enum css_display_e currentNodeDisplay = (enum css_display_e)currentDocumentNode.display;
                css_computed_style *currentNodeStyle = currentDocumentNode.computedStyle;
                if(currentNodeStyle && css_computed_float(currentNodeStyle) != CSS_FLOAT_NONE) {
                    // Floats should be processed by the inline processing code.
                    currentNodeDisplay = CSS_DISPLAY_INLINE;
                }
                
                switch(currentNodeDisplay) {
                    case CSS_DISPLAY_INHERIT:
                    {
                        THWarn(@"Unexpected node with display:inherit");
                        currentDocumentNode = currentDocumentNode.nextDisplayable;
                        break;
                    }
                    case CSS_DISPLAY_NONE:
                    {
                        THWarn(@"Unexpected node with display:none");
                        currentDocumentNode = currentDocumentNode.nextDisplayable;
                        break;
                    }
                    case CSS_DISPLAY_BLOCK:
                    case CSS_DISPLAY_RUN_IN:
                    case CSS_DISPLAY_INLINE_BLOCK:
                    {
                        //THLog(@"Block: %@", [currentDocumentNode name]);
                        if(THWillLog()) {
                            NSParameterAssert(css_computed_float(currentDocumentNode.computedStyle) == CSS_FLOAT_NONE);
                        }
                        BOOL hasPreviousSibling = [currentPositionedBlock.children count] != 0;
                        
                        if(currentDocumentNode.isImageNode) {
                            THLog(@"Image: %@", [currentDocumentNode.imageSource absoluteString]);
                        }
                        EucCSSLayoutPositionedBlock *newBlock = [[EucCSSLayoutPositionedBlock alloc] initWithDocumentNode:currentDocumentNode scaleFactor:_scaleFactor];
                        [newBlock positionInFrame:potentialFrame afterInternalPageBreak:NO];
                        [currentPositionedBlock addChild:newBlock];
                        if(activeFloats) {
                            newBlock.intrudingLeftFloats = activeFloats.first;
                            newBlock.intrudingRightFloats = activeFloats.second;
                        }
                        
                        nextAbsoluteY = [newBlock convertRect:newBlock.contentBounds toContainer:nil].origin.y;
                        
                        if(hasPreviousSibling) {
                            EucCSSLayoutPoint breakPoint = { currentDocumentNode.key, 0, 0 };
                            pageBreaks.push_back(make_pair(breakPoint, newBlock));
                        }                
                        
                        currentPositionedBlock = [newBlock autorelease];
                        
                        // First run in a block has the ID of the block it's in.
                        nextRunNodeKey = currentDocumentNode.key;  
                        
                        currentDocumentNode = currentDocumentNode.nextDisplayable;
                        
                        break;
                    }
                    case CSS_DISPLAY_TABLE:
                    case CSS_DISPLAY_INLINE_TABLE:
                    case CSS_DISPLAY_TABLE_ROW_GROUP:
                    case CSS_DISPLAY_TABLE_HEADER_GROUP:
                    case CSS_DISPLAY_TABLE_FOOTER_GROUP:
                    case CSS_DISPLAY_TABLE_ROW:
                    case CSS_DISPLAY_TABLE_COLUMN_GROUP:
                    case CSS_DISPLAY_TABLE_COLUMN:
                    case CSS_DISPLAY_TABLE_CELL:
                    case CSS_DISPLAY_TABLE_CAPTION:
                    {
                        EucCSSLayoutTableWrapper *table = [[EucCSSLayoutTableWrapper alloc] initWithNode:currentDocumentNode];
                        currentDocumentNode = table.nextNodeInDocument;
                        break;
                    }
                    case CSS_DISPLAY_LIST_ITEM:
                    case CSS_DISPLAY_INLINE:
                    {
                        //THLog(@"Inline: %@", [currentDocumentNode name]);
                        
                        // This is an inline element - start a run.
                        EucCSSLayoutRun *run = [EucCSSLayoutRun runWithNode:currentDocumentNode
                                                             underLimitNode:currentDocumentNode.blockLevelParent
                                                             stopBeforeNode:stopBeforeNode
                                                                      forId:nextRunNodeKey];
                        EucCSSLayoutSizedRun *sizedRun = [EucCSSLayoutSizedRun sizedRunWithRun:run 
                                                                                   scaleFactor:_scaleFactor];
                        
                        CGRect frameWithMaxHeight = potentialFrame;
                        frameWithMaxHeight.size.height = maxAbsoluteY - nextAbsoluteY;
                        if(!pageBreaks.empty()) {
                            frameWithMaxHeight.size.height += CGRectGetMinY([pageBreaks.back().second absoluteFrame]) - frame.origin.y;
                        }
                        // Position it.
                        EucCSSLayoutPositionedRun *positionedRun = [sizedRun positionRunForFrame:frameWithMaxHeight
                                                                                     inContainer:currentPositionedBlock
                                                                            startingAtWordOffset:wordOffset
                                                                                   elementOffset:elementOffset
                                                                          usingLayouterForFloats:self];
                        
                        if(positionedRun) {
                            BOOL first = YES; // Break before first line doesn't count.
                            for(EucCSSLayoutPositionedLine *line in positionedRun.children) {
                                if(!first) {
                                    EucCSSLayoutRunPoint startPoint = line.startPoint;
                                    EucCSSLayoutPoint breakPoint = { nextRunNodeKey, startPoint.word, startPoint.element };                                
                                    pageBreaks.push_back(make_pair(breakPoint, line));
                                } else {
                                    first = NO;
                                }
                            }
                            nextAbsoluteY = CGRectGetMaxY([positionedRun absoluteFrame]);
                            
                            activeFloats = [currentPositionedBlock floatsOverlappingYPoint:nextAbsoluteY height:0];
                        }
                        
                        if(elementOffset) {
                            elementOffset = 0;
                        }
                        if(wordOffset) {
                            wordOffset = 0;
                        }
                        
                        currentDocumentNode = run.nextNodeInDocument;
                        nextRunNodeKey = currentDocumentNode.key;
                        
                        break;
                    }   
                }
            } else {
                nextRunNodeKey = currentDocumentNode.key;
                currentDocumentNode = currentDocumentNode.nextDisplayable;
            }
            
            reachedBottomOfFrame = nextAbsoluteY >= maxAbsoluteY;            
        }

        if(closedLastNode) {
            *returningCompleted = YES;
            EucCSSLayoutPoint fakeNextPoint = { nextRunNodeKey, 0, 0 };
            *returningNextPoint = fakeNextPoint;
        } else {
            if(reachedBottomOfFrame || pageBreakForced) {
                *returningCompleted = NO;
                EucCSSLayoutPoint nextPoint;
                BOOL nextPointValid = [self _trimBlockToFrame:frame 
                                           returningNextPoint:&nextPoint
                                                   pageBreaks:&pageBreaks
                                  pageBreaksDisallowedByRuleA:&pageBreaksDisallowedByRuleA
                                  pageBreaksDisallowedByRuleB:&pageBreaksDisallowedByRuleB
                                  pageBreaksDisallowedByRuleC:&pageBreaksDisallowedByRuleC
                                  pageBreaksDisallowedByRuleD:&pageBreaksDisallowedByRuleD];
                if(nextPointValid) {
                    *returningNextPoint = nextPoint;
                    
                    reachedBottomOfFrame = NO;
                    closedLastNode = YES;
                } else {
                    // Couldn't find a break.
                    // Not entirely sure of the best thing to do here - for now
                    // just return the next node.
                    if(nextRunNodeKey) {
                        EucCSSLayoutPoint fakeNextPoint = { nextRunNodeKey, 0, 0 };
                        *returningNextPoint = fakeNextPoint;
                    } else {
                        *returningCompleted = YES;
                    }
                }
            } else {
                *returningCompleted = YES;
            }
        }
        
        if(!closedLastNode) {
            while(currentPositionedBlock) {
                CGFloat contentHeightToCloseAt = nextAbsoluteY - [currentPositionedBlock convertRect:currentPositionedBlock.contentBounds 
                                                                                         toContainer:nil].origin.y;
                [currentPositionedBlock closeBottomWithContentHeight:contentHeightToCloseAt atInternalPageBreak:reachedBottomOfFrame];
                nextAbsoluteY = CGRectGetMaxY(currentPositionedBlock.absoluteFrame);
                currentPositionedBlock = (EucCSSLayoutPositionedBlock *)currentPositionedBlock.parent;
            }            
        }
    } else {
        *returningNextPoint = point;
        *returningCompleted = YES;
    }
            
    return positionedRoot;
}

- (EucCSSLayoutPositionedBlock *)layoutFromPoint:(EucCSSLayoutPoint)point
                                         inFrame:(CGRect)frame
                              returningNextPoint:(EucCSSLayoutPoint *)returningNextPoint
                              returningCompleted:(BOOL *)returningCompleted
{    
    EucCSSLayoutPositionedBlock *ret = [self _layoutFromPoint:point
                                                      inFrame:frame
                                           returningNextPoint:returningNextPoint
                                           returningCompleted:returningCompleted
                                             lastBlockNodeKey:0
                                        stopBeforeNodeWithKey:0
                                        constructingAncestors:YES];
    return ret;
}

@end
