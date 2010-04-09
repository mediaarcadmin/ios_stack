//
//  THCALayerAdditions.m
//  libEucalyptus
//
//  Created by James Montgomerie on 08/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "THCALayerAdditions.h"


@implementation CALayer (THCALayerAdditions)

- (CALayer *)topmostLayer
{    
    CALayer *windowLayer = self;
    CALayer *superLayer;
    CALayer *oldSuperlayer = nil;
    while((superLayer = windowLayer.superlayer)) {
        oldSuperlayer = windowLayer;
        windowLayer = superLayer;
    }
    return oldSuperlayer ?: windowLayer;
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
