//
//  ScalableSlider.h
//  libEucalyptus
//
//  Created by James Montgomerie on 06/02/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface THScalableSlider : UISlider {
    float _maximumAvailable;
    CGRect _lastThumbRect;
    float _lastThumbRectScaledValue;
}

@property (nonatomic, assign) float maximumAvailable;
@property (nonatomic, assign) float scaledValue;
- (void)setScaledValue:(float)scaledValue animated:(BOOL)animated;


@end
