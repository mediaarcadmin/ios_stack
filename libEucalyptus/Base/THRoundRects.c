/*
 *  THRoundRects.c
 *  Eucalyptus
 *
 *  Created by James Montgomerie on 09/03/2009.
 *  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
 *
 */

#include "THRoundRects.h"

// From:
// http://developer.apple.com/documentation/Carbon/Conceptual/QuickDrawToQuartz2D/tq_other/chapter_3_section_6.html

void THAddRoundedRectToPath(CGContextRef context, CGRect rect, CGFloat ovalWidth, CGFloat ovalHeight)
{
    CGFloat fw, fh;
    
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    
    CGContextSaveGState(context);
    
    CGContextTranslateCTM (context, CGRectGetMinX(rect),
                           CGRectGetMinY(rect));
    CGContextScaleCTM (context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth (rect) / ovalWidth;
    fh = CGRectGetHeight (rect) / ovalHeight;
    
    CGContextMoveToPoint(context, fw, fh/2);
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1); 
    CGContextClosePath(context);
    
    CGContextRestoreGState(context);
}
