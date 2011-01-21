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

#import "EucCSSLayoutRunExtractor.h"

#import "EucCSSLayoutRun.h"
#import "EucCSSLayoutSizedRun.h"
#import "EucCSSLayoutPositionedRun.h"

#import "EucCSSLayoutPositionedLine.h"

#import "EucCSSLayoutSizedBlock.h"
#import "EucCSSLayoutPositionedBlock.h"

#import "EucCSSLayoutTableWrapper.h"
#import "EucCSSLayoutTableTable.h"
#import "EucCSSLayoutTableRowGroup.h"
#import "EucCSSLayoutTableRow.h"
#import "EucCSSLayoutSizedTable.h"
#import "EucCSSLayoutSizedTableCell.h"
#import "EucCSSLayoutPositionedTable.h"
#import "EucCSSLayoutPositionedTableCell.h"

#import "THStringRenderer.h"
#import "THPair.h"
#import "THLog.h"

#import <libcss/libcss.h>

#import <vector>
#import <utility>
using namespace std;

@implementation EucCSSLayouter

@synthesize document = _document;

- (id)initWithDocument:(EucCSSIntermediateDocument *)document
{
    if((self = [super init])) {
        _document = [document retain];
    }
    return self;
}

- (id)init
{
    return [self initWithDocument:nil];
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
                                                        scaleFactor:(CGFloat)scaleFactor
{
    EucCSSLayoutPositionedBlock *newContainer;
    EucCSSLayoutPositionedBlock *outermost;
    
    EucCSSIntermediateDocumentNode *blockLevelParent = node.blockLevelParent;
    if(blockLevelParent) {
        EucCSSLayoutPositionedBlock *parentContainer = nil;
        outermost = [self _constructBlockAndAncestorsForNode:blockLevelParent
                                          returningInnermost:&parentContainer
                                                     inFrame:frame
                                      afterInternalPageBreak:YES
                                                 scaleFactor:scaleFactor];
        
        newContainer = [[EucCSSLayoutPositionedBlock alloc] initWithDocumentNode:node scaleFactor:scaleFactor];
        newContainer.documentNode = node;
        CGRect potentialFrame = parentContainer.contentBounds;
        [newContainer positionInFrame:potentialFrame afterInternalPageBreak:afterInternalPageBreak];
        
        [parentContainer addChild:newContainer];
        [newContainer release];
    } else {
        newContainer = [[EucCSSLayoutPositionedBlock alloc] initWithDocumentNode:node scaleFactor:scaleFactor];
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
        if(!element) {
            break;
        }
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
    
    // If we found a usable break:
    if(pageBreakReverseIterator != pageBreakReverseIteratorEnd) {
        EucCSSLayoutPoint point = pageBreakReverseIterator->first;
        EucCSSLayoutPositionedContainer *element = pageBreakReverseIterator->second;
        
        if(element) {
            // If there's a 'next element' (there may not be if this is a forced
            // break), remove it an all that follows it.
            EucCSSLayoutPositionedBlock *block;
            
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
            } else if([element isKindOfClass:[EucCSSLayoutPositionedTableCell class]]) {
                EucCSSLayoutPositionedTableCell *cell = (EucCSSLayoutPositionedTableCell *)element;
                EucCSSLayoutPositionedTable *table;
                
                EucCSSLayoutPositionedContainer *potentialTable = (EucCSSLayoutPositionedBlock *)element;
                do {
                    potentialTable = potentialTable.parent;
                } while(![potentialTable isKindOfClass:[EucCSSLayoutPositionedTable class]]);
                table = (EucCSSLayoutPositionedTable *)potentialTable;
                
                [table truncateFromRowContainingPositionedCell:cell];
                
                block = (EucCSSLayoutPositionedBlock *)table.parent;
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
            [block closeBottomWithContentHeight:contentHeightToCloseAt atInternalPageBreak:YES];
            
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
    }
    return NO;
}
 
- (EucCSSIntermediateDocumentNode *)_layoutNodeForKey:(uint32_t)nodeKey
{
    if(nodeKey == 0) {
        return self.document.rootNode;
    } else {
        return [self.document nodeForKey:nodeKey];
    }
}

- (EucCSSLayoutSizedContainer *)sizedContainerFromNodeWithKey:(uint32_t)startNodeKey
                                        stopBeforeNodeWithKey:(uint32_t)stopBeforeNodeKey
                                                  scaleFactor:(CGFloat)scaleFactor
{
    EucCSSLayoutSizedContainer *sizedRoot = nil;

    EucCSSIntermediateDocumentNode *startNode = [self _layoutNodeForKey:startNodeKey];
    EucCSSIntermediateDocumentNode *currentDocumentNode = startNode;

    if(currentDocumentNode) {
        EucCSSIntermediateDocumentNode *stopBeforeNode;
        if(stopBeforeNodeKey) {
            sizedRoot = [[[EucCSSLayoutSizedTableCell alloc] initWithDocumentNode:nil scaleFactor:scaleFactor] autorelease];
            stopBeforeNode = [self _layoutNodeForKey:stopBeforeNodeKey];
        } else {
            if(startNode.display == CSS_DISPLAY_TABLE_CELL) {
                sizedRoot = [[[EucCSSLayoutSizedTableCell alloc] initWithDocumentNode:currentDocumentNode scaleFactor:scaleFactor] autorelease];
            } else {
                sizedRoot = [[[EucCSSLayoutSizedBlock alloc] initWithDocumentNode:currentDocumentNode scaleFactor:scaleFactor] autorelease];
            }
            stopBeforeNode = [startNode.parent displayableNodeAfter:startNode under:nil];
            currentDocumentNode = currentDocumentNode.nextDisplayable;
        }    

        EucCSSLayoutSizedContainer *currentSizedContainer = sizedRoot;
        
        BOOL closedLastNode = NO;
        
        uint32_t nextRunNodeKey = startNodeKey;
        while(!closedLastNode) {             
            if(currentDocumentNode == stopBeforeNode) {
                break;
            }
            
            // Find the node's parent, closing open blocks until we reach it.
            // If we reach a sized block with no document node, it's the 
            // implicit root container, so also stop then.
            EucCSSIntermediateDocumentNode *currentDocumentNodeBlockLevelParent = currentDocumentNode.blockLevelParent;
            if(currentDocumentNodeBlockLevelParent.key < startNodeKey) {
                currentDocumentNodeBlockLevelParent = startNode;
            }
            EucCSSIntermediateDocumentNode *currentPositionedBlockNode;
            while([currentSizedContainer respondsToSelector:@selector(documentNode)] &&
                  (currentPositionedBlockNode = ((EucCSSLayoutSizedBlock *)currentSizedContainer).documentNode) != nil && 
                  currentPositionedBlockNode != currentDocumentNodeBlockLevelParent) {
                currentSizedContainer = (EucCSSLayoutSizedBlock *)currentSizedContainer.parent;
                if(currentSizedContainer == sizedRoot) {
                    closedLastNode = YES;
                    break;
                }
            }
            
            if(!closedLastNode) {
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
                        
                        if(currentDocumentNode.isImageNode) {
                            THLog(@"Image: %@", [currentDocumentNode.imageSource absoluteString]);
                        }
                        EucCSSLayoutSizedBlock *newBlock = [[EucCSSLayoutSizedBlock alloc] initWithDocumentNode:currentDocumentNode 
                                                                                                    scaleFactor:scaleFactor];
                        [currentSizedContainer addChild:newBlock];
                        currentSizedContainer = newBlock;
                        [newBlock release];
                        
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
                        EucCSSLayoutTableWrapper *tableWrapper = [[EucCSSLayoutTableWrapper alloc] initWithNode:currentDocumentNode
                                                                                                       layouter:self];
                        EucCSSLayoutSizedTable *sizedTable = [[EucCSSLayoutSizedTable alloc] initWithTableWrapper:tableWrapper
                                                                                                      scaleFactor:scaleFactor];
                        [currentSizedContainer addChild:sizedTable];
                        [sizedTable release];
                        
                        currentDocumentNode = tableWrapper.nextNodeInDocument;
                        
                        [tableWrapper release];
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
                                                                                   scaleFactor:scaleFactor];
                        
                        if(sizedRun) {
                            [currentSizedContainer addChild:sizedRun];
                        }
                        currentDocumentNode = run.nextNodeInDocument;
                        nextRunNodeKey = currentDocumentNode.key;
                        break;
                    }   
                }
            } 
        }
    }
    
    return sizedRoot;
}

- (EucCSSLayoutPositionedBlock *)_layoutFromPoint:(EucCSSLayoutPoint)point
                                          inFrame:(CGRect)frame
                               returningNextPoint:(EucCSSLayoutPoint *)returningNextPoint
                               returningCompleted:(BOOL *)returningCompleted
                                 lastBlockNodeKey:(uint32_t)lastBlockNodeKey
                            stopBeforeNodeWithKey:(uint32_t)stopBeforeNodeKey
                            constructingAncestors:(BOOL)constructingAncestors
                                      scaleFactor:(CGFloat)scaleFactor
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

    uint32_t startNodeKey = point.nodeKey;
    uint32_t wordOffset = point.word;
    uint32_t elementOffset = point.element;
    
    NSUInteger rowOffset = 0;
    
    EucCSSIntermediateDocument *document = self.document;
    EucCSSIntermediateDocumentNode *currentDocumentNode = [self _layoutNodeForKey:startNodeKey];
    
    if(currentDocumentNode) {
        EucCSSIntermediateDocumentNode *lastBlockNode;
        if(lastBlockNodeKey) {
            lastBlockNode = [self _layoutNodeForKey:lastBlockNodeKey];
        } else {
            lastBlockNode = nil;
        }
        
        EucCSSIntermediateDocumentNode *stopBeforeNode;
        if(stopBeforeNodeKey) {
            stopBeforeNode = [self _layoutNodeForKey:stopBeforeNodeKey];
        } else {
            stopBeforeNode = nil;
        }
        
        CGRect bottomlessFrame = CGRectMake(frame.origin.x, frame.origin.x, frame.size.width, CGFLOAT_MAX);
        EucCSSLayoutPositionedBlock *currentPositionedBlock = nil;
        if(constructingAncestors) {
            uint32_t topLevelTableParentKey = currentDocumentNode.topLevelTableParentKey;
            
            if(topLevelTableParentKey != UINT32_MAX) {
                EucCSSIntermediateDocumentNode *topLevelTableParent = [self.document nodeForKey:topLevelTableParentKey];
                EucCSSLayoutTableWrapper *tableWrapper = [[EucCSSLayoutTableWrapper alloc] initWithNode:topLevelTableParent layouter:self];
                rowOffset = [tableWrapper rowForDocumentNode:currentDocumentNode];
                currentDocumentNode = topLevelTableParent;
                [tableWrapper release];
            }
            
        	css_computed_style *currentNodeStyle = currentDocumentNode.computedStyle;
            if(!currentNodeStyle || 
               css_computed_float(currentNodeStyle) != CSS_FLOAT_NONE ||
               css_computed_display(currentNodeStyle, false) != CSS_DISPLAY_BLOCK) {
                EucCSSIntermediateDocumentNode *blockLevelParent = currentDocumentNode.blockLevelParent;
                if(!blockLevelParent) {
                    blockLevelParent = document.rootNode;
                }
                positionedRoot = [self _constructBlockAndAncestorsForNode:blockLevelParent
                                                       returningInnermost:&currentPositionedBlock
                                                                  inFrame:bottomlessFrame
                                                   afterInternalPageBreak:YES
                                                              scaleFactor:scaleFactor];               
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
                                                   afterInternalPageBreak:startNodeKey != document.rootNode.key
                                                              scaleFactor:scaleFactor];
                currentDocumentNode = currentDocumentNode.nextDisplayable;
            } 
        } else {
            positionedRoot = [[[EucCSSLayoutPositionedBlock alloc] initWithDocumentNode:currentDocumentNode
                                                                            scaleFactor:scaleFactor] autorelease];
            [positionedRoot positionInFrame:frame afterInternalPageBreak:NO];
            currentPositionedBlock = positionedRoot;
            currentDocumentNode = currentDocumentNode.nextDisplayable;
        }
                
        BOOL closedLastNode = NO;
        BOOL reachedBottomOfFrame = NO;
        
        uint32_t nextRunNodeKey = startNodeKey;
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
                
                if(css_computed_page_break_after(currentPositionedBlock.documentNode.computedStyle) >= CSS_PAGE_BREAK_AFTER_ALWAYS) {
                    EucCSSLayoutPoint breakPoint = { nextRunNodeKey, 0, 0 };
                    pageBreaks.push_back(make_pair(breakPoint, (EucCSSLayoutPositionedContainer *)nil));
                    pageBreakForced = YES;
                }
                
                currentPositionedBlock = (EucCSSLayoutPositionedBlock *)currentPositionedBlock.parent;
                if(currentPositionedBlockNode == lastBlockNode) {
                    closedLastNode = YES;
                    break;
                }
            }

            if(!pageBreakForced && !closedLastNode) {
                CGRect potentialFrame = currentPositionedBlock.contentBounds;
                NSParameterAssert(potentialFrame.size.height == CGFLOAT_MAX);

                potentialFrame.origin.y = nextAbsoluteY - [currentPositionedBlock convertRect:potentialFrame 
                                                                                  toContainer:nil].origin.y;

                enum css_display_e currentNodeDisplay = (enum css_display_e)currentDocumentNode.display;
                css_computed_style *currentNodeStyle = currentDocumentNode.computedStyle;
                if(currentNodeStyle) {
                    if(css_computed_float(currentNodeStyle) != CSS_FLOAT_NONE) {
                        // Floats should be processed by the inline processing code.
                        currentNodeDisplay = CSS_DISPLAY_INLINE;
                    }
                    if(css_computed_page_break_before(currentDocumentNode.computedStyle) >= CSS_PAGE_BREAK_BEFORE_ALWAYS &&
                       !pageBreaks.empty() && 
                       currentNodeDisplay != CSS_DISPLAY_INLINE && 
                       !stopBeforeNode // stopBeforeNode being set implies we're not doing page-based layout.
                       ) {
                        EucCSSLayoutPoint breakPoint = { nextRunNodeKey, 0, 0 };
                        pageBreaks.push_back(make_pair(breakPoint, (EucCSSLayoutPositionedContainer *)nil));
                        pageBreakForced = YES;
                        break;
                    }                        
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
                        EucCSSLayoutPositionedBlock *newBlock = [[EucCSSLayoutPositionedBlock alloc] initWithDocumentNode:currentDocumentNode scaleFactor:scaleFactor];
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
                        
                        currentPositionedBlock = newBlock;
                        [newBlock release];
                        
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
                        BOOL hasPreviousSibling = [currentPositionedBlock.children count] != 0;

                        EucCSSLayoutTableWrapper *tableWrapper = [[EucCSSLayoutTableWrapper alloc] initWithNode:currentDocumentNode layouter:self];
                        EucCSSLayoutSizedTable *sizedTable = [[EucCSSLayoutSizedTable alloc] initWithTableWrapper:tableWrapper
                                                                                                      scaleFactor:scaleFactor];
                        EucCSSLayoutPositionedTable *positionedTable = [sizedTable positionTableForFrame:potentialFrame
                                                                                             inContainer:currentPositionedBlock
                                                                                           usingLayouter:self
                                                                                           fromRowOffset:rowOffset];
                        
                        if(rowOffset != 0) {
                            if(hasPreviousSibling) {
                                EucCSSLayoutPoint breakPoint = { currentDocumentNode.key, 0, 0 };
                                pageBreaks.push_back(make_pair(breakPoint, positionedTable));
                            }                        
                        }                            
                        
                        //if(positionedTable.size.height > ) {
                        NSUInteger rowCount = positionedTable.rowCount;
                        for(NSUInteger rowIndex = rowOffset; rowIndex < rowCount; ++rowIndex) {
                            EucCSSLayoutPositionedTableCell *startCell = [positionedTable positionedCellForColumn:0 row:rowIndex];
                            EucCSSLayoutPoint breakPoint = { startCell.sizedTableCell.documentNode.key, 0, 0 };
                            pageBreaks.push_back(make_pair(breakPoint, startCell));
                        }
                        //}
                        
                        if(rowOffset) {
                            rowOffset = 0;
                        }
                        
                        currentDocumentNode = tableWrapper.nextNodeInDocument;
                        nextRunNodeKey = currentDocumentNode.key;
                        nextAbsoluteY = CGRectGetMaxY([positionedTable absoluteFrame]);

                        [sizedTable release];
                        [tableWrapper release];
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
                                                                                   scaleFactor:scaleFactor];
                        
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
                                     scaleFactor:(CGFloat)scaleFactor
{    
    EucCSSLayoutPositionedBlock *ret = [self _layoutFromPoint:point
                                                      inFrame:frame
                                           returningNextPoint:returningNextPoint
                                           returningCompleted:returningCompleted
                                             lastBlockNodeKey:0
                                        stopBeforeNodeWithKey:0
                                        constructingAncestors:YES
                                                  scaleFactor:scaleFactor];
    return ret;
}

@end
