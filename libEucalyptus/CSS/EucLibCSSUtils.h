/*
 *  EucLibCSSUtils.h
 *  libEucalyptus
 *
 *  Created by James Montgomerie on 15/07/2010.
 *  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
 *
 */

#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

#import <libcss/libcss.h>

CGColorRef CGColorWithCSSColor(css_color cssColor);