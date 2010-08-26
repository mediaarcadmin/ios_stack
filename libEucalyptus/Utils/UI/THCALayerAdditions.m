//
//  THCALayerAdditions.m
//  libEucalyptus
//
//  Created by James Montgomerie on 08/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "THCALayerAdditions.h"


@implementation CALayer (THCALayerAdditions)

- (CATransform3D)absoluteTransform
{
    CALayer *superLayer = self.superlayer;
    if(superLayer) {
        return CATransform3DConcat(superLayer.absoluteTransform, self.transform);
    } else {
        return CATransform3DIdentity;
    }
}

- (CALayer *)windowLayer
{    
    CALayer *windowLayer = self;
    CALayer *superLayer;
    while((superLayer = windowLayer.superlayer)) {
        windowLayer = superLayer;
    }
    return windowLayer;
}

- (CGSize)screenScaleFactors
{
    return [self convertRect:CGRectMake(0, 0, 1, 1) toLayer:self.windowLayer].size;
}

@end
