//
//  EucCSSLayoutPositionedTableCell.m
//  libEucalyptus
//
//  Created by James Montgomerie on 11/01/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutPositionedTableCell.h"

#import "EucCSSLayoutSizedTableCell.h"

#import "EucCSSIntermediateDocumentNode.h"

#import "EucCSSInternal.h"

#import <libcss/libcss.h>

@implementation EucCSSLayoutPositionedTableCell

@synthesize sizedTableCell = _sizedTableCell;
@synthesize extraPaddingTop = _extraPaddingTop;
@synthesize extraPaddingBottom = _extraPaddingBottom;


- (id)initWithSizedTableCell:(EucCSSLayoutSizedTableCell *)sizedTableCell
{
    if((self = [super init])) {
        _sizedTableCell = [sizedTableCell retain];
    }
    return self;
}

- (void)dealloc
{
    [_sizedTableCell release];
    
    [super dealloc];
}

- (CGRect)contentRect
{
    CGRect frame = [self frame];
    CGRect contentRect = [super contentRect];
    
    EucCSSIntermediateDocumentNode *documentNode = _sizedTableCell.documentNode;
    if(documentNode) {
        CGFloat scaleFactor = _sizedTableCell.scaleFactor;
        
        css_computed_style *computedStyle = documentNode.computedStyle;
        css_fixed fixed = 0;
        css_unit unit = 0;        
        
        css_computed_padding_top(computedStyle, &fixed, &unit);
        CGFloat paddingTop = EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, frame.size.width, scaleFactor);
        paddingTop += _extraPaddingTop;
        contentRect.origin.y += paddingTop;
        contentRect.size.height -= paddingTop;
        
        css_computed_padding_left(computedStyle, &fixed, &unit);
        CGFloat paddingLeft = EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, frame.size.width, scaleFactor);
        contentRect.origin.x += paddingLeft;
        contentRect.size.width -= paddingLeft;
        
        css_computed_padding_right(computedStyle, &fixed, &unit);
        CGFloat paddingRight = EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, frame.size.width, scaleFactor);
        contentRect.size.width -= paddingRight;
                
        if(frame.size.height != CGFLOAT_MAX) {
            css_computed_padding_bottom(computedStyle, &fixed, &unit);
            CGFloat paddingBottom = EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, frame.size.width, scaleFactor);
            paddingBottom += _extraPaddingBottom;
            contentRect.size.height -= paddingBottom;
        }
    } else {
        if(_extraPaddingTop) {
            contentRect.origin.y += _extraPaddingTop;
            contentRect.size.height -= _extraPaddingTop;
        }
        if(_extraPaddingBottom) {
            contentRect.size.height -= _extraPaddingTop;
        }
    }
    
    return contentRect;
}

- (void)setExtraPaddingTop:(CGFloat)extraPaddingTop
{
    CGFloat difference = extraPaddingTop - _extraPaddingTop;
    CGRect frame = self.frame;
    frame.size.height += difference;
    self.frame = frame;
    _extraPaddingTop = extraPaddingTop;
}

- (void)setExtraPaddingBottom:(CGFloat)extraPaddingBottom
{
    CGFloat difference =  extraPaddingBottom - _extraPaddingBottom;
    CGRect frame = self.frame;
    frame.size.height += difference;
    self.frame = frame;
    _extraPaddingBottom = extraPaddingBottom;
}

- (void)closeBottomWithContentHeight:(CGFloat)height /*atInternalPageBreak:(BOOL)atInternalPageBreak*/
{
    CGRect frame = self.frame;
    CGRect contentRect = self.contentRect;
    frame.size.height = height + contentRect.origin.y;
    //if(!atInternalPageBreak) {
        EucCSSIntermediateDocumentNode *documentNode = _sizedTableCell.documentNode;
        if(documentNode) {
            CGFloat scaleFactor = _sizedTableCell.scaleFactor;
            css_computed_style *computedStyle = documentNode.computedStyle;
            css_fixed fixed = 0;
            css_unit unit = 0;        

            css_computed_padding_bottom(computedStyle, &fixed, &unit);
            frame.size.height += EucCSSLibCSSSizeToPixels(computedStyle, fixed, unit, frame.size.width, scaleFactor);
        }
    //}
    self.frame = frame;
}

@end
