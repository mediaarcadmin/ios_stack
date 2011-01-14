/*
 *  EucCSSInternal.c
 *  LibCSSTest
 *
 *  Created by James Montgomerie on 10/03/2010.
 *  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>
#import <stdlib.h>
#import "EucCSSInternal.h"
#import "THLog.h"

void *EucRealloc(void *ptr, size_t len, void *pw)
{
    if(len == 0) {
        free(ptr);
        return NULL;
    } else {
        return realloc(ptr, len);
    }
}

CGFloat EucCSSLibCSSSizeToPixels(css_computed_style *computed_style, 
                                 css_fixed size, 
                                 css_unit units, 
                                 CGFloat percentageBase,
                                 CGFloat scaleFactor)
{
    CGFloat ret = FIXTOFLT(size);
    
    switch(units) {
        case CSS_UNIT_EX:
            NSCParameterAssert(units != CSS_UNIT_EX);
            break;
        case CSS_UNIT_EM:
        {
            css_fixed fontSize = 0;
            css_unit fontUnit = (css_unit)0;
            css_computed_font_size(computed_style, &fontSize, &fontUnit);
            NSCParameterAssert(fontUnit == CSS_UNIT_PX || fontUnit == CSS_UNIT_PT);
            ret = FIXTOFLT(FMUL(size, fontSize));
        }
            break;
        case CSS_UNIT_IN:
            ret *= 2.54f;        // Convert to cm.
        case CSS_UNIT_CM:  
            ret *= 10.0f;        // Convert to mm.
        case CSS_UNIT_MM:
            ret *= 0.155828221f; // mm per point on an iPhone screen.
            break;
        case CSS_UNIT_PC:
            ret *= 12.0f;
            break;
        case CSS_UNIT_PX:
        case CSS_UNIT_PT:
            break;
        case CSS_UNIT_PCT:
            ret = percentageBase * (ret * 0.01f);
            break;
        default:
            THWarn(@"Unexpected unit %ld (%f size) - not converting.", (long)units, (double)ret);
            break;
    }
    
    if(units != CSS_UNIT_PCT) {
        ret *= scaleFactor;
    }
    return roundf(ret);
}
