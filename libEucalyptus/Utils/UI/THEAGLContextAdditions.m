//
//  THEAGLContextAdditions.m
//  libEucalyptus
//
//  Created by James Montgomerie on 02/11/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "THEAGLContextAdditions.h"
#import <pthread.h>

@implementation EAGLContext (THEAGLContextAdditions) 

- (void)thPush
{
    NSMutableArray *contextStack = [[[NSThread currentThread] threadDictionary] objectForKey:@"THEAGLContextAdditionsContextStack"];
    if(!contextStack) {
        contextStack = [NSMutableArray arrayWithCapacity:1];
        [[[NSThread currentThread] threadDictionary] setObject:contextStack forKey:@"THEAGLContextAdditionsContextStack"];
    }
    [EAGLContext setCurrentContext:self];
    [contextStack addObject:self];
}

- (void)thPop
{
    NSMutableArray *contextStack = [[[NSThread currentThread] threadDictionary] objectForKey:@"THEAGLContextAdditionsContextStack"];
    NSParameterAssert([contextStack lastObject] == self);
    [contextStack removeLastObject];
    [EAGLContext setCurrentContext:[contextStack lastObject]];
}

@end
