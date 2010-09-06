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

@synthesize delegate = _delagete;
@synthesize kind = _kind;

- (id)initWithKind:(EucSelectorKnobKind)kind 
{
    UIImage *knobImage = [UIImage imageNamed:@"SelectionKnob.png"];
    CGSize imageSize = knobImage.size;
    CGRect frame = CGRectMake(0, 0, imageSize.width, imageSize.height);
    if ((self = [super initWithFrame:frame])) {
        self.layer.contents = (id)knobImage.CGImage;
        self.isAccessibilityElement = YES;
        self.accessibilityTraits = UIAccessibilityTraitAdjustable;
        if(kind == EucSelectorKnobKindLeft) {
            self.accessibilityLabel = NSLocalizedString(@"Leftmost text selection edge", @"Accesibilily label for left-hand text selection knob");
            self.accessibilityHint = NSLocalizedString(@"Double tap and hold, then drag to change the text selection size.",
                                                       @"Accessibility hint for left-hand text selection knob");
        } else {
            self.accessibilityLabel = NSLocalizedString(@"Rightmost text selection edge", @"Accesibilily label for right-hand text selection knob");
            self.accessibilityHint = NSLocalizedString(@"Double tap and hold, then drag to change the text selection size.",
                                                       @"Accessibility hint for left-hand text selection knob");
        }
    }
    return self;
}

- (void)accessibilityIncrement
{
    [self.delegate eucSelectorKnobShouldIncrement:self]; 
}

- (void)accessibilityDecrement
{
    [self.delegate eucSelectorKnobShouldDecrement:self];   
}

@end
