//
//  EucCSSLayoutSizedTableCell.m
//  libEucalyptus
//
//  Created by James Montgomerie on 11/01/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutSizedTableCell.h"

#import "EucCSSLayoutSizedTable.h"
#import "EucCSSLayoutSizedBlock.h"
#import "EucCSSLayoutSizedRun.h"


#import "EucCSSInternal.h"

#import "EucCSSIntermediateDocumentNode.h"

#import "EucCSSLayoutPositionedTable.h"
#import "EucCSSLayoutPositionedTableCell.h"

#import "EucCSSLayouter.h"

#import <libcss/libcss.h>

@implementation EucCSSLayoutSizedTableCell

@synthesize documentNode = _documentNode;

- (id)initWithDocumentNode:(EucCSSIntermediateDocumentNode *)documentNode
               scaleFactor:(CGFloat)scaleFactor;
{
    if((self = [super initWithScaleFactor:scaleFactor])) {
        if(documentNode) {
            _documentNode = [documentNode retain];
            
            css_computed_style *computedStyle = documentNode.computedStyle;
            css_fixed fixed = 0;
            css_unit unit = 0;
            
            css_computed_padding_left(computedStyle, &fixed, &unit);
            _widthAddition += EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, 0, scaleFactor);
            css_computed_padding_right(computedStyle, &fixed, &unit);
            _widthAddition += EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, 0, scaleFactor);
        }
    }    
    return self;
}

- (void)dealloc
{
    [_documentNode release];
    
    [super dealloc];
}

- (CGFloat)minWidth
{
    CGFloat ret = [super minWidth];
    
    if(_documentNode) {
        css_computed_style *style = _documentNode.computedStyle;
        if(style) {
            css_fixed width = 0;
            css_unit unit = (css_unit)0;
            if(css_computed_width(style, &width, &unit) == CSS_WIDTH_SET &&
               unit != CSS_UNIT_PCT) {
                CGFloat specifiedWidth = ceilf(EucCSSLibCSSSizeToPixels(style, width, unit, 0, _scaleFactor));
                ret = MAX(specifiedWidth, ret);
            }
            if(css_computed_min_width(style, &width, &unit) == CSS_WIDTH_SET &&
               unit != CSS_UNIT_PCT) {
                CGFloat specifiedWidth = ceilf(EucCSSLibCSSSizeToPixels(style, width, unit, 0, _scaleFactor));
                ret = MAX(specifiedWidth, ret);
            }            
        }
    }
    
    return ret + _widthAddition;
}

- (CGFloat)maxWidth
{
    CGFloat ret = [super maxWidth];
    
    if(_documentNode) {
        css_computed_style *style = _documentNode.computedStyle;
        if(style) {
            css_fixed width = 0;
            css_unit unit = (css_unit)0;
            if(css_computed_max_width(style, &width, &unit) == CSS_WIDTH_SET &&
               unit != CSS_UNIT_PCT) {
                CGFloat specifiedWidth = ceilf(EucCSSLibCSSSizeToPixels(style, width, unit, 0, _scaleFactor));
                ret = MIN(specifiedWidth, ret);
            }
        }
    }
    
    return ret + _widthAddition;
}

- (EucCSSLayoutPositionedTableCell *)positionCellForFrame:(CGRect)cellFrame
                                                  inTable:(EucCSSLayoutPositionedTable *)positionedTable
                                            atColumnIndex:(NSUInteger)columnIndex
                                                 rowIndex:(NSUInteger)rowIndex
                                            usingLayouter:(EucCSSLayouter *)layouter
{
    EucCSSLayoutPositionedTableCell *positionedCell = [[EucCSSLayoutPositionedTableCell alloc] initWithSizedTableCell:self];
    positionedCell.frame = cellFrame;
    
    [self positionChildrenInContainer:positionedCell usingLayouter:layouter];
    
    [positionedTable setPositionedCell:positionedCell
                             forColumn:columnIndex
                                   row:rowIndex];
    
    [positionedCell release];
    
    return positionedCell;
}

@end
