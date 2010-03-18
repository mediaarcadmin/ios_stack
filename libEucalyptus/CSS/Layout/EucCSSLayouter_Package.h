//
//  EucCSSLayouter_Package.h
//  libEucalyptus
//
//  Created by James Montgomerie on 15/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif
#import <libcss/libcss.h>

#ifdef __cplusplus
extern "C" {
#endif
    
CGFloat EucCSSLibCSSSizeToPixels(css_computed_style *computed_style,
                                 css_fixed size,
                                 css_unit units,
                                 CGFloat percentageBase,
                                 CGFloat scaleFactor);

#ifdef __cplusplus
}
#endif
