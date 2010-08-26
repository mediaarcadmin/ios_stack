//
//  THCALayerAdditions.h
//  libEucalyptus
//
//  Created by James Montgomerie on 08/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface CALayer (THCALayerAdditions)

- (CATransform3D)absoluteTransform;
- (CALayer *)windowLayer;
- (CGSize)screenScaleFactors;

@end
