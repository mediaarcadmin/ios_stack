/*
 *  THRoundRects.h
 *  Eucalyptus
 *
 *  Created by James Montgomerie on 09/03/2009.
 *  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
 *
 */

#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

void THAddRoundedRectToPath(CGContextRef context, CGRect rect, CGFloat ovalWidth, CGFloat ovalHeight);
