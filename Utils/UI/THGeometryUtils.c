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

CGFloat CGPointDistanceFromRect(CGPoint point, CGRect rect)
{
    Boolean outside = FALSE;
    CGPoint closestPointOnEdge = point;
    if(closestPointOnEdge.x < rect.origin.x) {
        closestPointOnEdge.x = rect.origin.x;
        outside = TRUE;
    } else {
        CGFloat maxXInRect = rect.origin.x + rect.size.width;
        if(closestPointOnEdge.x > maxXInRect) {
            closestPointOnEdge.x = maxXInRect;
            outside = TRUE;
        }
    }
    if(closestPointOnEdge.y < rect.origin.y) {
        closestPointOnEdge.y = rect.origin.y;
        outside = TRUE;
    } else {
        CGFloat maxYInRect = rect.origin.y + rect.size.height;
        if(closestPointOnEdge.y > maxYInRect) {
            closestPointOnEdge.y = maxYInRect;
            outside = TRUE;
        }
    }
    if(outside) {
        return CGPointDistance(point, closestPointOnEdge);
    } else {
        // Point is inside the rect.
        return 0.0f;
    }
}