//
//  EucHTMLLayoutBlock.m
//  LibCSSTest
//
//  Created by James Montgomerie on 12/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucHTMLLayoutPositionedBlock.h"
#import "EucHTMLDocument.h"
#import "EucHTMLDocumentNode.h"
#import <libcss/libcss.h>

@implementation EucHTMLLayoutPositionedBlock

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

- (id)initWithDocumentNode:(EucHTMLDocumentNode *)documentNode
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

- (void)positionInFrame:(CGRect)frame collapsingTop:(BOOL)collapsingTop
{
    _frame = frame;
    
    css_computed_style *computedStyle = self.documentNode.computedStyle;
    css_fixed fixed;
    css_unit unit;
    
    CGRect borderRect;
    if(collapsingTop) {
        borderRect.origin.y = frame.origin.y;
    } else {
        css_computed_margin_top(computedStyle, &fixed, &unit);
        borderRect.origin.y = frame.origin.y + libcss_size_to_pixels(computedStyle, fixed, unit);
    }
    css_computed_margin_left(computedStyle, &fixed, &unit);
    borderRect.origin.x = frame.origin.x + libcss_size_to_pixels(computedStyle, fixed, unit);
    css_computed_margin_right(computedStyle, &fixed, &unit);
    borderRect.size.width = CGRectGetMaxY(frame) - libcss_size_to_pixels(computedStyle, fixed, unit) - borderRect.origin.x;
    borderRect.size.height = CGFLOAT_MAX;
    _borderRect = borderRect;
    
    CGRect paddingRect;
    if(collapsingTop) {
        paddingRect.origin.y = borderRect.origin.y;
    } else {
        css_computed_border_top_width(computedStyle, &fixed, &unit);
        paddingRect.origin.y = borderRect.origin.y + libcss_size_to_pixels(computedStyle, fixed, unit);
    }
    css_computed_border_left_width(computedStyle, &fixed, &unit);
    paddingRect.origin.x = borderRect.origin.x + libcss_size_to_pixels(computedStyle, fixed, unit);
    css_computed_border_right_width(computedStyle, &fixed, &unit);
    paddingRect.size.width = CGRectGetMaxY(borderRect) - libcss_size_to_pixels(computedStyle, fixed, unit) - paddingRect.origin.x;
    paddingRect.size.height = CGFLOAT_MAX;
    _paddingRect = paddingRect;
    
    CGRect contentRect;
    if(collapsingTop) {
        contentRect.origin.y = paddingRect.origin.y;
    } else {
        css_computed_padding_top(computedStyle, &fixed, &unit);
        contentRect.origin.y = paddingRect.origin.y + libcss_size_to_pixels(computedStyle, fixed, unit);
    }    
    css_computed_padding_left(computedStyle, &fixed, &unit);
    contentRect.origin.x = paddingRect.origin.x + libcss_size_to_pixels(computedStyle, fixed, unit);
    css_computed_padding_right(computedStyle, &fixed, &unit);
    contentRect.size.width = CGRectGetMaxY(paddingRect) - libcss_size_to_pixels(computedStyle, fixed, unit) - contentRect.origin.x;
    contentRect.size.height = CGFLOAT_MAX;
    _contentRect = contentRect;    
    
    if(frame.size.height != CGFLOAT_MAX) {
        [self closeBottomFromYPoint:frame.size.height];
    }
}

- (void)closeBottomFromYPoint:(CGFloat)point
{
    _contentRect.size.height = point - _contentRect.origin.y;
    
    css_computed_style *computedStyle = self.documentNode.computedStyle;
    css_fixed fixed;
    css_unit unit;
    
    css_computed_padding_bottom(computedStyle, &fixed, &unit);
    point += libcss_size_to_pixels(computedStyle, fixed, unit);
    _paddingRect.size.height = point - _paddingRect.origin.y;
    
    css_computed_border_bottom_width(computedStyle, &fixed, &unit);
    point += libcss_size_to_pixels(computedStyle, fixed, unit);
    _borderRect.size.height = point - _borderRect.origin.y;
    
    css_computed_margin_bottom(computedStyle, &fixed, &unit);
    point += libcss_size_to_pixels(computedStyle, fixed, unit);
    _frame.size.height = point - _frame.origin.y;
}

- (void)addSubEntity:(id)subEntity
{
    [_subEntities addObject:subEntity];
}

@end
