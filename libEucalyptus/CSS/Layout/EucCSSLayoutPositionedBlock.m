//
//  EucCSSLayoutPositionedBlock.m
//  LibCSSTest
//
//  Created by James Montgomerie on 12/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSInternal.h"
#import "EucCSSLayoutPositionedBlock.h"
#import "EucCSSLayoutPositionedRun.h"
#import "EucCSSIntermediateDocument.h"
#import "EucCSSIntermediateDocument_Package.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "THPair.h"
#import <libcss/libcss.h>

@interface EucCSSLayoutPositionedBlock ()
- (void)_collapseTopMarginUpwards;

@property (nonatomic, assign) CGRect borderRect;
@property (nonatomic, assign) CGRect paddingRect;
@property (nonatomic, assign) CGRect contentRect;
@end

@implementation EucCSSLayoutPositionedBlock

@synthesize documentNode = _documentNode;
@synthesize scaleFactor = _scaleFactor;

@synthesize borderRect = _borderRect;
@synthesize paddingRect = _paddingRect;
@synthesize contentRect = _contentRect;

- (id)init
{
    [NSException raise:NSInternalInconsistencyException 
                format:@"Must be initialized with initWithDocumentNode"];
    return [super init];
}

- (id)initWithDocumentNode:(EucCSSIntermediateDocumentNode *)documentNode
               scaleFactor:(CGFloat)scaleFactor
{
    if((self = [super init])) {
        NSMutableArray *forChildren = [[NSMutableArray alloc] init];
        self.children = forChildren;
        [forChildren release];
        _documentNode = [documentNode retain];
        _scaleFactor = scaleFactor;
    }
    return self;
}

- (void)dealloc
{
    [_documentNode release];
    
    [super dealloc];
}

- (css_computed_style *)computedStyle
{
    return _documentNode.computedStyle;
}

- (void)positionInFrame:(CGRect)frame
 afterInternalPageBreak:(BOOL)afterInternalPageBreak
{
    self.frame = frame;
    CGRect bounds = frame;
    bounds.origin = CGPointZero;
    
    css_computed_style *computedStyle = self.documentNode.computedStyle;
    css_fixed fixed = 0;
    css_unit unit = 0;
    
    CGRect borderRect;
    if(afterInternalPageBreak) {
        borderRect.origin.y = 0;
    } else {
        css_computed_margin_top(computedStyle, &fixed, &unit);
        borderRect.origin.y = 0 + EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, bounds.size.width, _scaleFactor);
    }
    css_computed_margin_left(computedStyle, &fixed, &unit);
    borderRect.origin.x = 0 + EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, bounds.size.width, _scaleFactor);
    css_computed_margin_right(computedStyle, &fixed, &unit);
    borderRect.size.width = CGRectGetMaxX(bounds) - EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, bounds.size.width, _scaleFactor) - borderRect.origin.x;
    borderRect.size.height = CGFLOAT_MAX;
    _borderRect = borderRect;
    
    CGRect paddingRect;
    if(afterInternalPageBreak) {
        paddingRect.origin.y = borderRect.origin.y;
    } else {
        css_computed_border_top_width(computedStyle, &fixed, &unit);
        paddingRect.origin.y = borderRect.origin.y + EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, 0, _scaleFactor);
    }
    css_computed_border_left_width(computedStyle, &fixed, &unit);
    paddingRect.origin.x = borderRect.origin.x + EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, 0, _scaleFactor);
    css_computed_border_right_width(computedStyle, &fixed, &unit);
    paddingRect.size.width = CGRectGetMaxX(borderRect) - EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, 0, _scaleFactor) - paddingRect.origin.x;
    paddingRect.size.height = CGFLOAT_MAX;
    _paddingRect = paddingRect;
    
    CGRect contentRect;
    if(afterInternalPageBreak) {
        contentRect.origin.y = paddingRect.origin.y;
    } else {
        css_computed_padding_top(computedStyle, &fixed, &unit);
        contentRect.origin.y = paddingRect.origin.y + EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, bounds.size.width, _scaleFactor);
    }    
    css_computed_padding_left(computedStyle, &fixed, &unit);
    contentRect.origin.x = paddingRect.origin.x + EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, bounds.size.width, _scaleFactor);
    css_computed_padding_right(computedStyle, &fixed, &unit);
    contentRect.size.width = CGRectGetMaxX(paddingRect) - EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, bounds.size.width, _scaleFactor) - contentRect.origin.x;
    contentRect.size.height = CGFLOAT_MAX;
    _contentRect = contentRect;    
    
    if(bounds.size.height != CGFLOAT_MAX) {
        [self closeBottomWithContentHeight:bounds.size.height atInternalPageBreak:NO];
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

- (void)closeBottomWithContentHeight:(CGFloat)height atInternalPageBreak:(BOOL)atInternalPageBreak
{
    css_computed_style *computedStyle = self.documentNode.computedStyle;
    css_fixed fixed = 0;
    css_unit unit = 0;
    
    if(css_computed_height(computedStyle, &fixed, &unit) != CSS_HEIGHT_AUTO && unit != CSS_UNIT_PCT) {
        CGFloat specifiedHeight = EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, 0, _scaleFactor);
        height = MAX(specifiedHeight, height);
    }
    _contentRect.size.height = height;
    
    if(atInternalPageBreak) {
        _paddingRect.size.height = height + _contentRect.origin.y - _paddingRect.origin.y;
        _borderRect.size.height = height + _contentRect.origin.y - _borderRect.origin.y;
        CGRect frame = self.frame;
        frame.size.height = height + _contentRect.origin.y;
        self.frame = frame;
    } else {
        css_computed_style *computedStyle = self.documentNode.computedStyle;
        css_fixed fixed = 0;
        css_unit unit = 0;
        
        CGFloat width = self.frame.size.width;
        
        height += (_contentRect.origin.y - _paddingRect.origin.y);
        css_computed_padding_bottom(computedStyle, &fixed, &unit);
        height += EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, width, _scaleFactor);
        _paddingRect.size.height = height;
        
        height += (_paddingRect.origin.y - _borderRect.origin.y);
        css_computed_border_bottom_width(computedStyle, &fixed, &unit);
        height += EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, 0, _scaleFactor);
        _borderRect.size.height = height;
        
        css_computed_margin_bottom(computedStyle, &fixed, &unit);
        CGFloat bottomMarginHeight = EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, width, _scaleFactor);
        
        // If we have a bottom margin, and the box is otherwise empty, the margin
        // should collapse upwards.
        CGRect frame = self.frame;
        if(bottomMarginHeight != 0.0f && 
           _contentRect.size.height == 0.0f &&
           _paddingRect.size.height == 0.0f && 
           _borderRect.size.height == 0.0f) {
            
            CGFloat oldTopMarginHeight = _borderRect.origin.y;
            CGFloat newTopMargin = collapse(oldTopMarginHeight, bottomMarginHeight);
            CGFloat topMarginDifference = newTopMargin - oldTopMarginHeight;
            if(topMarginDifference) {
                _contentRect.origin.y += topMarginDifference;
                _paddingRect.origin.y += topMarginDifference;
                _borderRect.origin.y += topMarginDifference;
                if(oldTopMarginHeight == 0.0f) {
                    // Further collapse the margin upwards, if possible.
                    [self _collapseTopMarginUpwards];
                }            
            }
            frame.size.height = CGRectGetMaxY(_contentRect);
        } else {
            height += _borderRect.origin.y;
            height += bottomMarginHeight;
            frame.size.height = height;
        }
        self.frame = frame;
    }
}

- (void)addChild:(EucCSSLayoutPositionedContainer *)child
{
    [self.children addObject:child];
    child.parent = self;

    if([child isKindOfClass:[EucCSSLayoutPositionedBlock class]]) {
        EucCSSLayoutPositionedBlock *subBlock = (EucCSSLayoutPositionedBlock *)child;
        if(css_computed_float(subBlock.documentNode.computedStyle) == CSS_FLOAT_NONE) {
            [subBlock _collapseTopMarginUpwards];
        }
    }
}

- (id)_previousSibling
{
    id ret = nil;
    NSArray *siblings = self.parent.children;
    NSUInteger myIndex = [siblings indexOfObject:self];
    if(myIndex != 0) {
        ret = [siblings objectAtIndex:myIndex - 1];
    }
    return ret;
}

- (void)_collapseTopMarginUpwards
{
    //NSParameterAssert(self.children.count == 0);
    if(self.children.count != 0) {
        for(EucCSSLayoutPositionedContainer *child in self.children) {
            NSParameterAssert(child.frame.size.height == 0);
        }
    }
    
    CGFloat oldTopMarginHeight = _borderRect.origin.y;
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
                potentiallyCollapseInto = (EucCSSLayoutPositionedBlock *)previouslyExamining.parent;
            }
            if(potentiallyCollapseInto) {
                if(potentiallyCollapseInto.frame.size.height == 0.0f) {
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
                CGFloat collapseIntoBottomMarginHeight = CGRectGetHeight(potentiallyCollapseIntoFrame) - CGRectGetMaxY(potentiallyCollapseInto.borderRect);
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
                        CGFloat collapseIntoTopMarginHeight = potentiallyCollapseIntoBorderRect.origin.y;
                        CGFloat newTopMarginHeight = collapse(oldTopMarginHeight, collapseIntoTopMarginHeight);
                        if(collapseIntoTopMarginHeight != newTopMarginHeight) {  
                            CGFloat marginDifference = newTopMarginHeight - collapseIntoTopMarginHeight;
                            adjustBy = marginDifference;
                            
                            potentiallyCollapseIntoFrame.size.height += adjustBy;
                            potentiallyCollapseInto.frame = potentiallyCollapseIntoFrame;

                            potentiallyCollapseIntoBorderRect.origin.y += adjustBy;
                            potentiallyCollapseInto.borderRect = potentiallyCollapseIntoBorderRect;
                            
                            potentiallyCollapseIntoPaddingRect.origin.y += adjustBy;
                            potentiallyCollapseInto.paddingRect = potentiallyCollapseIntoPaddingRect;
                            
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
                }
            }
        }
    }
}

- (CGFloat)minimumWidth
{
    CGFloat largestContentWidth = 0;
    for(EucCSSLayoutPositionedContainer *child in self.children) {
        CGFloat childMinimum = child.minimumWidth;
        if(childMinimum > largestContentWidth) {
            largestContentWidth = childMinimum;
        }
    }
    CGFloat difference = _contentRect.size.width - largestContentWidth;
    return self.frame.size.width - difference;
}

- (void)sizeToFitInWidth:(CGFloat)width
{
    CGFloat difference = self.frame.size.width - width;
    if(difference > 0) {
        CGFloat newContentWidth = _contentRect.size.width - difference;
        
        for(EucCSSLayoutPositionedContainer *child in self.children) {
            [child sizeToFitInWidth:newContentWidth];
        }
        
        _contentRect.size.width -= difference;
        _paddingRect.size.width -= difference;
        _borderRect.size.width -= difference;
        CGRect frame = self.frame;
        frame.size.width -= difference;
        self.frame = frame;
    }    
}

@end
