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

- (UIView *)closestView
{
    CALayer *layer = self;
    Class uiViewClass = [UIView class];
    UIView *potentialView;
    while(layer && ((potentialView = layer.delegate),
                    ![potentialView isKindOfClass:uiViewClass])) {
        layer = layer.superlayer;
    }
    return potentialView;
}

- (CATransform3D)transformFromAncestor:(CALayer *)ancestor
{   
    CATransform3D transform = self.transform;
    CALayer *layer = self;
    
    // We check for a window with a UIWindow delegate, becase on the Retnia
    // display, the window does in fact have a superlayer, which we don't 
    // want to know about.
    while((layer = layer.superlayer) && layer != ancestor) {
        transform = CATransform3DConcat(layer.transform, transform);
    }
    
    return transform;    
}

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

- (CGSize)screenScaleFactors
{
    return [self convertRect:CGRectMake(0, 0, 1, 1) toLayer:self.windowLayer].size;
}

- (CGSize)scaleFactorFromAncestor:(CALayer *)ancestor
{
    return [self convertRect:CGRectMake(0, 0, 1, 1) toLayer:ancestor].size;
}



@end
