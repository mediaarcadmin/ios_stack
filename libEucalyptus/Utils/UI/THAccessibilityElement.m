//
//  THAccessibilityElement.m
//  libEucalyptus
//
//  Created by James Montgomerie on 24/08/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "THAccessibilityElement.h"

@implementation THAccessibilityElement

@synthesize delegate = _delegate;

+ (THAccessibilityElement *)thAccessibilityElementWithContainer:(id)container
                                                          label:(NSString *)label
                                                         traits:(UIAccessibilityTraits)traits
                                                          frame:(CGRect)frame
{
    THAccessibilityElement *ret = nil;
    if((ret = [[THAccessibilityElement alloc] initWithAccessibilityContainer:container])) {
        ret.accessibilityLabel = label;
        ret.accessibilityTraits = traits;
        ret.accessibilityFrame = frame;
        [ret autorelease];
    }
    return ret;
}

- (void)accessibilityElementDidBecomeFocused
{
    [super accessibilityElementDidBecomeFocused];
    if(_delegate && [_delegate respondsToSelector:@selector(thAccessibilityElementDidBecomeFocused:)]) {
        [_delegate thAccessibilityElementDidBecomeFocused:self];
    }
}

- (void)accessibilityElementDidLoseFocus
{
    [super accessibilityElementDidLoseFocus];
    if(_delegate && [_delegate respondsToSelector:@selector(thAccessibilityElementDidLoseFocus:)]) {
        [_delegate thAccessibilityElementDidLoseFocus:self];
    }
}

@end
