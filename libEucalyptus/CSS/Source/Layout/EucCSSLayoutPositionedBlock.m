//
//  EucCSSLayoutPositionedBlock.m
//  LibCSSTest
//
//  Created by James Montgomerie on 12/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutPositionedBlock.h"
#import "EucCSSLayoutPositionedRun.h"
#import "EucCSSIntermediateDocument.h"
#import "EucCSSIntermediateDocumentNode.h"
#import <libcss/libcss.h>

@interface EucCSSLayoutPositionedBlock ()
- (void)_collapseTopMarginUpwards;
@end

@implementation EucCSSLayoutPositionedBlock

@synthesize documentNode = _documentNode;
@synthesize parent = _parent;

@synthesize frame = _frame;
@synthesize borderRect = _borderRect;
@synthesize paddingRect = _paddingRect;
@synthesize contentRect = _contentRect;

@synthesize subEntities = _subEntities;

- (id)init
{
    [NSException raise:NSInternalInconsistencyException 
                format:@"Must be initialized with initWithDocumentNode"];
    return [super init];
}

- (id)initWithDocumentNode:(EucCSSIntermediateDocumentNode *)documentNode
{
    if((self = [super init])) {
        _subEntities = [[NSMutableArray alloc] init];
        _documentNode = [documentNode retain];
    }
    return self;
}

- (void)dealloc
{
    [_subEntities release];
    [_documentNode release];
    
    [super dealloc];
}

- (void)positionInFrame:(CGRect)frame afterInternalPageBreak:(BOOL)afterInternalPageBreak
{
    _frame = frame;
    
    css_computed_style *computedStyle = self.documentNode.computedStyle;
    css_fixed fixed;
    css_unit unit;
    
    CGRect borderRect;
    if(afterInternalPageBreak) {
        borderRect.origin.y = frame.origin.y;
    } else {
        css_computed_margin_top(computedStyle, &fixed, &unit);
        borderRect.origin.y = frame.origin.y + EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, frame.size.width);
    }
    css_computed_margin_left(computedStyle, &fixed, &unit);
    borderRect.origin.x = frame.origin.x + EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, frame.size.width);
    css_computed_margin_right(computedStyle, &fixed, &unit);
    borderRect.size.width = CGRectGetMaxX(frame) - EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, frame.size.width) - borderRect.origin.x;
    borderRect.size.height = CGFLOAT_MAX;
    _borderRect = borderRect;
    
    CGRect paddingRect;
    if(afterInternalPageBreak) {
        paddingRect.origin.y = borderRect.origin.y;
    } else {
        css_computed_border_top_width(computedStyle, &fixed, &unit);
        paddingRect.origin.y = borderRect.origin.y + EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, 0);
    }
    css_computed_border_left_width(computedStyle, &fixed, &unit);
    paddingRect.origin.x = borderRect.origin.x + EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, 0);
    css_computed_border_right_width(computedStyle, &fixed, &unit);
    paddingRect.size.width = CGRectGetMaxX(borderRect) - EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, 0) - paddingRect.origin.x;
    paddingRect.size.height = CGFLOAT_MAX;
    _paddingRect = paddingRect;
    
    CGRect contentRect;
    if(afterInternalPageBreak) {
        contentRect.origin.y = paddingRect.origin.y;
    } else {
        css_computed_padding_top(computedStyle, &fixed, &unit);
        contentRect.origin.y = paddingRect.origin.y + EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, frame.size.width);
    }    
    css_computed_padding_left(computedStyle, &fixed, &unit);
    contentRect.origin.x = paddingRect.origin.x + EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, frame.size.width);
    css_computed_padding_right(computedStyle, &fixed, &unit);
    contentRect.size.width = CGRectGetMaxX(paddingRect) - EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, frame.size.width) - contentRect.origin.x;
    contentRect.size.height = CGFLOAT_MAX;
    _contentRect = contentRect;    
    
    if(frame.size.height != CGFLOAT_MAX) {
        [self closeBottomFromYPoint:frame.size.height atInternalPageBreak:NO];
    }
    
    if(_frame.size.height < 0) {
        NSLog(@"fdsfds");
    }
}

static inline CGFloat collapse(CGFloat one, CGFloat two) 
{
    if(one < 0) {
        if(two < 0) {
            return MIN(one, two);
        } else {
            return two + one;
        }
    } else {
        if(two < 0) {
            return one + two;
        } else {
            return MAX(one, two);
        }        
    }
}

- (void)closeBottomFromYPoint:(CGFloat)point atInternalPageBreak:(BOOL)atInternalPageBreak
{
    _contentRect.size.height = point - _contentRect.origin.y;
    
    if(atInternalPageBreak) {
        _paddingRect.size.height = point - _paddingRect.origin.y;
        _borderRect.size.height = point - _borderRect.origin.y;
        _frame.size.height = point - _frame.origin.y;
    } else {
        css_computed_style *computedStyle = self.documentNode.computedStyle;
        css_fixed fixed;
        css_unit unit;
        
        CGFloat width = self.frame.size.width;
        css_computed_padding_bottom(computedStyle, &fixed, &unit);
        point += EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, width);
        _paddingRect.size.height = point - _paddingRect.origin.y;
        
        css_computed_border_bottom_width(computedStyle, &fixed, &unit);
        point += EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, 0);
        _borderRect.size.height = point - _borderRect.origin.y;
        
        css_computed_margin_bottom(computedStyle, &fixed, &unit);
        CGFloat bottomMarginHeight = EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, width);
        
        // If we have a bottom margin, and the box is otherwise empty, the margin
        // should collapse upwards.
        if(bottomMarginHeight != 0.0f && 
           _contentRect.size.height == 0.0f &&
           _paddingRect.size.height == 0.0f && 
           _borderRect.size.height == 0.0f) {
            
            CGFloat oldTopMarginHeight = _borderRect.origin.y - _frame.origin.y;
            CGFloat newTopMargin = collapse(oldTopMarginHeight, bottomMarginHeight);
            CGFloat topMarginDifference = newTopMargin - oldTopMarginHeight;
            if(topMarginDifference) {
                _paddingRect.origin.y += topMarginDifference;
                _borderRect.origin.y += topMarginDifference;
                if(oldTopMarginHeight == 0.0f) {
                    // Further collapse the margin upwards, if possible.
                    [self _collapseTopMarginUpwards];
                }            
            }
            _frame.size.height = 0.0f;
        } else {
            point += bottomMarginHeight;
            _frame.size.height = point - _frame.origin.y;
        }
    }
}

- (void)addSubEntity:(id)subEntity
{
    [_subEntities addObject:subEntity];
    
    if([subEntity isKindOfClass:[EucCSSLayoutPositionedBlock class]]) {
        EucCSSLayoutPositionedBlock *subBlock = (EucCSSLayoutPositionedBlock *)subEntity;
        subBlock.parent = self;
        [subBlock _collapseTopMarginUpwards];
    } else if([subEntity isKindOfClass:[EucCSSLayoutPositionedRun class]]) {
        EucCSSLayoutPositionedRun *positionedRun = (EucCSSLayoutPositionedRun *)subEntity;
        positionedRun.containingBlock = self;
    }
}

- (id)_previousSibling
{
    id ret = nil;
    NSArray *siblings = self.parent.subEntities;
    NSUInteger myIndex = [siblings indexOfObject:self];
    if(myIndex != 0) {
        ret = [siblings objectAtIndex:myIndex - 1];
    }
    return ret;
}

- (void)_collapseTopMarginUpwards
{
    NSParameterAssert(self.subEntities.count == 0);
                      
    CGFloat oldTopMarginHeight = _borderRect.origin.y - _frame.origin.y;
    if(oldTopMarginHeight) {
        NSMutableArray *blocksToAdjust = [NSMutableArray arrayWithObject:self];
        
        CGFloat adjustBy = 0.0f;
        BOOL didCollapse = NO;
        
        EucCSSLayoutPositionedBlock *previouslyExamining = self;
        EucCSSLayoutPositionedBlock *potentiallyCollapseInto = nil;

        Class EucCSSLayoutPositionedBlockClass = [EucCSSLayoutPositionedBlock class];
        while(previouslyExamining) {
            potentiallyCollapseInto = previouslyExamining._previousSibling;
            if(![potentiallyCollapseInto isKindOfClass:EucCSSLayoutPositionedBlockClass]) {
                potentiallyCollapseInto = nil;
                break;
            }
            if(!potentiallyCollapseInto) {
                potentiallyCollapseInto = previouslyExamining.parent;
            }
            if(potentiallyCollapseInto) {
                if(!potentiallyCollapseInto.frame.size.height) {
                    [blocksToAdjust addObject:potentiallyCollapseInto];
                    previouslyExamining = potentiallyCollapseInto;
                } else {
                    break;
                }
            }
        }
        
        if(potentiallyCollapseInto) {
            CGRect potentiallyCollapseIntoFrame = potentiallyCollapseInto.frame;
            if(potentiallyCollapseIntoFrame.size.height) {
                CGFloat collapseIntoBottomMarginHeight = CGRectGetMaxY(potentiallyCollapseIntoFrame) - CGRectGetMaxY(potentiallyCollapseInto.borderRect);
                if(collapseIntoBottomMarginHeight) {
                    CGFloat newBottomMarginHeight = collapse(oldTopMarginHeight, collapseIntoBottomMarginHeight);
                    if(collapseIntoBottomMarginHeight != newBottomMarginHeight) {
                        CGFloat marginDifference = newBottomMarginHeight - collapseIntoBottomMarginHeight;
                        
                        potentiallyCollapseIntoFrame.size.height += marginDifference;
                        potentiallyCollapseInto.frame = potentiallyCollapseIntoFrame;
                        
                        adjustBy = marginDifference;
                    }
                    didCollapse = YES;
                } else {
                    CGRect potentiallyCollapseIntoBorderRect = potentiallyCollapseInto.borderRect;
                    CGRect potentiallyCollapseIntoPaddingRect = potentiallyCollapseInto.paddingRect;
                    CGRect potentiallyCollapseIntoContentRect = potentiallyCollapseInto.contentRect;
                    if(potentiallyCollapseIntoBorderRect.size.height == 0 &&
                       potentiallyCollapseIntoPaddingRect.size.height == 0 &&
                       potentiallyCollapseIntoContentRect.size.height == 0) {
                        CGFloat collapseIntoTopMarginHeight = potentiallyCollapseIntoBorderRect.origin.y - potentiallyCollapseIntoFrame.origin.y;
                        CGFloat newTopMarginHeight = collapse(oldTopMarginHeight, collapseIntoTopMarginHeight);
                        if(collapseIntoTopMarginHeight != newTopMarginHeight) {  
                            CGFloat marginDifference = newTopMarginHeight - collapseIntoTopMarginHeight;
                            adjustBy = marginDifference;
                            
                            potentiallyCollapseIntoFrame.size.height += adjustBy;
                            potentiallyCollapseInto.frame = potentiallyCollapseIntoFrame;

                            potentiallyCollapseIntoBorderRect.origin.y += adjustBy;
                            potentiallyCollapseInto.borderRect = potentiallyCollapseIntoBorderRect;
                            
                            potentiallyCollapseIntoPaddingRect.origin.y += adjustBy;
                            potentiallyCollapseInto.borderRect = potentiallyCollapseIntoPaddingRect;
                            
                            potentiallyCollapseIntoContentRect.origin.y += adjustBy;
                            potentiallyCollapseInto.contentRect = potentiallyCollapseIntoContentRect;                            
                        }
                        didCollapse = YES;
                    }
                }
            }
        }
        
        if(didCollapse) {    
            // Collapse my top margin.
            _borderRect.origin.y -= oldTopMarginHeight;
            _paddingRect.origin.y -= oldTopMarginHeight;
            _contentRect.origin.y -= oldTopMarginHeight; 
            
            // Move ourselves, and any intervening empty blocks, to adjust
            // for the moved margin.
            if(adjustBy != 0.0f) {
                for(EucCSSLayoutPositionedBlock *block in blocksToAdjust) {
                    CGRect rect = block.frame;
                    rect.origin.y += adjustBy;
                    block.frame = rect;
                    
                    rect = block.borderRect;
                    rect.origin.y += adjustBy;
                    block.borderRect = rect;

                    rect = block.paddingRect;
                    rect.origin.y += adjustBy;
                    block.borderRect = rect;
                    
                    rect = block.contentRect;
                    rect.origin.y += adjustBy;
                    block.contentRect = rect;
                }
            }
        }
    }
}

@end
