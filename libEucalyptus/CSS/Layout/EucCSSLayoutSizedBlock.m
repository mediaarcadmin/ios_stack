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
#import <libcss/libcss.h>

@implementation EucCSSLayoutSizedBlock

@synthesize children = _children;
@synthesize documentNode = _documentNode;

- (id)initWithDocumentNode:(EucCSSIntermediateDocumentNode *)documentNode
               scaleFactor:(CGFloat)scaleFactor;
{
    if((self = [super initWithScaleFactor:scaleFactor])) {
        _documentNode = [documentNode retain];
        _children = [[NSMutableArray alloc] init];
        
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
    return self;
}

- (void)dealloc
{
    [_documentNode release];
    [_children release];
    
    [super dealloc];
}

- (void)addChild:(EucCSSLayoutSizedContainer *)child
{
    [_children addObject:child];
    child.parent = self;
}

- (CGFloat)minWidth
{
    return [[_children valueForKey:@"@max.minWidth"] floatValue] + _widthAddition;
}

- (CGFloat)maxWidth
{
    return [[_children valueForKey:@"@max.maxWidth"] floatValue] + _widthAddition;
}

@end
