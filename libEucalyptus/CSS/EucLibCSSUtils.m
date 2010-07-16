/*
 *  EucLibCSSUtils.m
 *  libEucalyptus
 *
 *  Created by James Montgomerie on 15/07/2010.
 *  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>
#import "EucLibCSSUtils.h"

CGColorRef CGColorWithCSSColor(css_color color)
{
    CGColorRef ret = CGColorCreateGenericRGB((CGFloat)(color & 0xFF000000) * (1.0f / (CGFloat)0xFF000000),
                                             (CGFloat)(color & 0xFF0000) * (1.0f / (CGFloat)0xFF0000),
                                             (CGFloat)(color & 0xFF00) * (1.0f / (CGFloat)0xFF00),
                                             1.0f);
    [(id)ret autorelease];
    return ret;    
}