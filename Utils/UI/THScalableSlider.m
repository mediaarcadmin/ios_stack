//
//  ScalableSlider.m
//  Eucalyptus
//
//  Created by James Montgomerie on 06/02/2009.
//  Copyright 2009 James Montgomerie. All rights reserved.
//

#import "THScalableSlider.h"


@implementation THScalableSlider

- (id)initWithFrame:(CGRect)frame
{
    if((self = [super initWithFrame:frame])) {
        _maximumAvailable = -1;
        _lastThumbRectScaledValue = -1;
    }
    return self;
}

- (float)maximumAvailable 
{
    return _maximumAvailable;
}

- (void)setMaximumAvailable:(float)maximumAvailable;
{
    float scaledValue = self.scaledValue;
    if(maximumAvailable < self.maximumValue) {
        _maximumAvailable = maximumAvailable;
    } else {
        _maximumAvailable = -1;
    }
    self.scaledValue = scaledValue;
    [self setNeedsLayout];
}

- (float)scaledValue
{
    if(_maximumAvailable >= 0) {
        return self.value * (self.maximumAvailable / self.maximumValue);
    } else {
        return self.value;
    }
}

- (void)setScaledValue:(float)scaledValue
{
    if(_maximumAvailable >= 0) {
        self.value = scaledValue / (self.maximumAvailable / self.maximumValue);
    } else {
        self.value = scaledValue;
    }
}

- (void)setScaledValue:(float)scaledValue animated:(BOOL)animated
{
    if(_maximumAvailable >= 0) {
        [super setValue:scaledValue / (self.maximumAvailable / self.maximumValue) animated:animated];
    } else {
        [super setValue:scaledValue animated:animated];
    }
}


- (CGRect)trackRectForBounds:(CGRect)bounds
{
    if(_maximumAvailable >= 0) {
        CGRect trackRect = [super trackRectForBounds:bounds];
        CGRect thumbRectAtEnd = [super thumbRectForBounds:bounds trackRect:trackRect value:self.maximumValue];
        CGRect thumbRectAtMax = [super thumbRectForBounds:bounds trackRect:trackRect value:self.maximumAvailable];
        
        CGFloat thumbToTrackDiff = (trackRect.origin.x + trackRect.size.width) - (thumbRectAtEnd.origin.x + thumbRectAtEnd.size.width);
        
        trackRect.size.width = (thumbRectAtMax.size.width + thumbRectAtMax.origin.x) - trackRect.origin.x + thumbToTrackDiff;
        
        return trackRect;
    } else {
        return [super trackRectForBounds:bounds];
    }
}

- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value
{
    CGRect ret;
    if(_maximumAvailable >= 0) {
        // If the rect has moved by less than a whole pixel since the last time we 
        // were called, we return the cached last rect.
        // This avoids jitter in the thumb as the available length changes if it's
        // value places it near a pixel boundry.
        
        float scaledValue = value * (self.maximumAvailable / self.maximumValue);
        if(_lastThumbRectScaledValue == -1 ||
           fabsf(scaledValue - _lastThumbRectScaledValue) > (self.maximumAvailable / rect.size.width)) {
            _lastThumbRectScaledValue = scaledValue;
            _lastThumbRect = [super thumbRectForBounds:bounds trackRect:rect value:value];
        }
        ret = _lastThumbRect;
    } else {
        ret = [super thumbRectForBounds:bounds trackRect:rect value:value];
    }
    return CGRectInset(ret, -8, -8);
}

@end
