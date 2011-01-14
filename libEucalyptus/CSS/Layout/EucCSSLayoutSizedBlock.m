//
//  EucCSSLayoutSizedBlock.m
//  libEucalyptus
//
//  Created by James Montgomerie on 04/01/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutSizedBlock.h"

#import "EucCSSInternal.h"

#import "EucCSSIntermediateDocumentNode.h"

#import "EucCSSLayouter.h"
#import "EucCSSLayoutPositionedContainer.h"
#import "EucCSSLayoutPositionedBlock.h"

#import <libcss/libcss.h>

@implementation EucCSSLayoutSizedBlock

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
            
            css_computed_margin_left(computedStyle, &fixed, &unit);
            _widthAddition += EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, 0, scaleFactor);
            css_computed_margin_right(computedStyle, &fixed, &unit);
            _widthAddition += EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, 0, scaleFactor);

            css_computed_border_left_width(computedStyle, &fixed, &unit);
            _widthAddition += EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, 0, scaleFactor);
            css_computed_border_right_width(computedStyle, &fixed, &unit);
            _widthAddition += EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, 0, scaleFactor);

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

- (EucCSSLayoutPositionedBlock *)positionBlockForFrame:(CGRect)frame
                                           inContainer:(EucCSSLayoutPositionedContainer *)container
                                         usingLayouter:(EucCSSLayouter *)layouter
{
    EucCSSLayoutPositionedBlock *newBlock = [[EucCSSLayoutPositionedBlock alloc] initWithDocumentNode:self.documentNode
                                                                                          scaleFactor:self.scaleFactor];
    [newBlock positionInFrame:frame afterInternalPageBreak:NO];
    
    [container addChild:newBlock];
    
    [self positionChildrenInContainer:newBlock usingLayouter:layouter];

    return newBlock;
}

@end
