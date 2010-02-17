//
//  EucMenuItem.h
//  libEucalyptus
//
//  Created by James Montgomerie on 05/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EucMenuItem : NSObject {
    NSString *_title;
    SEL _action;
    UIColor *_color;
}

@property(nonatomic, copy) NSString *title;
@property(nonatomic, assign) SEL action;
@property(nonatomic, retain) UIColor* color;

- (id)initWithTitle:(NSString *)title action:(SEL)action;
- (void)invokeAt:(UIResponder *)responder;

@end
