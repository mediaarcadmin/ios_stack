//
//  EucSelectorKnob.m
//  libEucalyptus
//
//  Created by James Montgomerie on 01/09/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "EucSelectorKnob.h"

@implementation EucSelectorKnob

- (id)init {
    UIImage *knobImage = [UIImage imageNamed:@"SelectionKnob.png"];
    CGSize imageSize = knobImage.size;
    CGRect frame = CGRectMake(0, 0, imageSize.width, imageSize.height);
    if ((self = [super initWithFrame:frame])) {
        self.layer.contents = (id)knobImage.CGImage;
        self.isAccessibilityElement = YES;
        self.accessibilityLabel = @"Knob";
    }
    return self;
}

@end
