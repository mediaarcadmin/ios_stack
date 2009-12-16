/*
 *  THGeometryUtils.c
 *  Eucalyptus
 *
 *  Created by James Montgomerie on 20/03/2009.
 *  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
 *
 */

#include "THGeometryUtils.h"
#import <math.h>

CGFloat CGPointDistance(CGPoint firstPoint, CGPoint secondPoint)
{
    //Square difference in x
    CGFloat xDifference = firstPoint.x - secondPoint.x;
    CGFloat yDifference = firstPoint.y - secondPoint.y;
    
    return hypotf(xDifference, yDifference);
}
