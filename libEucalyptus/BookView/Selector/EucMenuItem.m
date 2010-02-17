//
//  EucMenuItem.m
//  libEucalyptus
//
//  Created by James Montgomerie on 05/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucMenuItem.h"

@implementation EucMenuItem

@synthesize title = _title;
@synthesize action = _action;

- (id)initWithTitle:(NSString *)title action:(SEL)action
{
    if((self = [super init])) {
        _title = [title copy];
        _action = action;
    }
    return self;
}

- (void)dealloc
{
    [_title release];
    [super dealloc];
}

- (void)invokeAt:(UIResponder *)responder
{
    SEL selector = self.action;
    do {
        if([responder respondsToSelector:selector]) {
            [responder performSelector:selector withObject:[UIApplication sharedApplication]];
            break;
        }
    } while((responder = [responder nextResponder]));
}

@end
