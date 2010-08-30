//
//  THCALayerAdditions.m
//  libEucalyptus
//
//  Created by James Montgomerie on 08/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "THCALayerAdditions.h"
#import <UIKit/UIKit.h>

@implementation CALayer (THCALayerAdditions)

- (CATransform3D)absoluteTransform
{   
    CATransform3D transform = self.transform;
    CALayer *layer = self;
    Class windowClass = [UIWindow class];
    
    // We check for a window with a UIWindow delegate, becase on the Retnia
    // display, the window does in fact have a superlayer, which we don't 
    // want to know about.
    while(![layer.delegate isKindOfClass:windowClass] &&
          (layer = layer.superlayer)) {
        transform = CATransform3DConcat(layer.transform, transform);
    }
    
    return transform;    
}

- (CALayer *)windowLayer
{    
    CALayer *windowLayer = self;
    CALayer *superLayer;
    Class windowClass = [UIWindow class];
    
    // We check for a window with a UIWindow delegate, becase on the Retnia
    // display, the window does in fact have a superlayer, which we don't 
    // want to know about.
    while(![windowLayer.delegate isKindOfClass:windowClass] &&
          (superLayer = windowLayer.superlayer)) {
        windowLayer = superLayer;
    }
    
    return windowLayer;
}

- (CGSize)screenScaleFactors
{
    return [self convertRect:CGRectMake(0, 0, 1, 1) toLayer:self.windowLayer].size;
}

@end
