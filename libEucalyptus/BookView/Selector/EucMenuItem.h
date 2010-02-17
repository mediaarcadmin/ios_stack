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
}

@property(nonatomic, copy) NSString *title;
@property(nonatomic, assign) SEL action;

- (id)initWithTitle:(NSString *)title action:(SEL)action;
- (void)invokeAt:(UIResponder *)responder;

@end
