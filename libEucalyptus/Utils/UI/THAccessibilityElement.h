//
//  THAccessibilityElement.h
//  libEucalyptus
//
//  Created by James Montgomerie on 24/08/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol THAccessibilityElementDelegate;

@interface THAccessibilityElement : UIAccessibilityElement {
    id<THAccessibilityElementDelegate> _delgate;
}

@property (nonatomic, assign) id<THAccessibilityElementDelegate> delegate;

+ (THAccessibilityElement *)thAccessibilityElementWithContainer:(id)container
                                                          label:(NSString *)label
                                                         traits:(UIAccessibilityTraits)traits
                                                          frame:(CGRect)frame;

@end

@protocol THAccessibilityElementDelegate <NSObject>

@optional
- (void)thAccessibilityElementDidBecomeFocused:(THAccessibilityElement *)element;
- (void)thAccessibilityElementDidLoseFocus:(THAccessibilityElement *)element;

@end