//
//  THUIViewAdditions.m
//  libEucalyptus
//
//  Created by James Montgomerie on 21/08/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "THUIViewAdditions.h"


@implementation UIView (THUIViewAdditions)


- (void)centerInSuperview
{
    CGSize superViewBoundsSize = self.superview.bounds.size;
    CGSize selfSize = self.bounds.size;
    
    CGPoint newCenter = CGPointMake(floorf(superViewBoundsSize.width / 2), floorf(superViewBoundsSize.height / 2));

    // Pixel-align the edges, not the center.
    if(fmod(selfSize.width, 2) != 0) {
        newCenter.x += 0.5;
    }
    if(fmod(selfSize.width, 2) != 0) {
        newCenter.y += 0.5;
    }

    self.center = newCenter;
}


@end
