//
//  NSObject+BlioAdditions.m
//  BlioApp
//
//  Created by James Montgomerie on 02/07/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "NSObject+BlioAdditions.h"

@implementation NSObject (BlioAdditions)

- (id)blioPerformSelectorOnMainThreadReturningResult:(SEL)aSelector
{
    return [self blioPerformSelectorOnMainThreadReturningResult:aSelector withObjects:nil];
}

- (id)blioPerformSelectorOnMainThreadReturningResult:(SEL)aSelector withObjects:(id)arg1, ...
{
    NSMethodSignature *methodSignature = [self methodSignatureForSelector:aSelector];
    NSInvocation *mainThreadInvocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    mainThreadInvocation.selector = aSelector;
    
    NSUInteger argumentCount = [methodSignature numberOfArguments];
    if(argumentCount >= 3) {
        va_list args;
        va_start(args, arg1);
        
        while(--argumentCount >= 2) {
            id object = va_arg(args, id);
            [mainThreadInvocation setArgument:&object atIndex:argumentCount];
        }
    }
    [mainThreadInvocation performSelectorOnMainThread:@selector(invokeWithTarget:) withObject:self waitUntilDone:YES];
    
    id ret = nil;
    [mainThreadInvocation getReturnValue:&ret];
    return ret;
}
     

@end
