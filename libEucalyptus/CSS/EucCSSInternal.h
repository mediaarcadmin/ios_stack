/*
 *  EucCSSInternal.h
 *  LibCSSTest
 *
 *  Created by James Montgomerie on 10/03/2010.
 *  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
 *
 */

#import <TargetConditionals.h>
#import <memory.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif
#import <libcss/libcss.h>

void *EucRealloc(void *ptr, size_t len, void *pw);

CGFloat EucCSSLibCSSSizeToPixels(css_computed_style *computed_style,
                                 css_fixed size,
                                 css_unit units,
                                 CGFloat percentageBase,
                                 CGFloat scaleFactor);

#if !TARGET_OS_IPHONE

#define NSStringFromCGRect(x) NSStringFromRect(NSRectFromCGRect(x))

#endif