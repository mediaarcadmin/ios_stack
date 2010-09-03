//
//  THCALayerAdditions.h
//  libEucalyptus
//
//  Created by James Montgomerie on 08/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface CALayer (THCALayerAdditions)

- (CALayer *)windowLayer;
- (UIView *)closestView;

- (CATransform3D)absoluteTransform;
- (CGSize)screenScaleFactors;

@end
