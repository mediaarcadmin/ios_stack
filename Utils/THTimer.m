//
//  THTimer.m
//
//  Created by James Montgomerie on 26/04/2008.
//  Copyright 2008 James Montgomerie. All rights reserved.
//

#import "THTimer.h"
#import "THLog.h"

@implementation THTimer

+ (id)timerWithName:(NSString *)name
{
    return [[[[self class] alloc] initWithName:name] autorelease];
}

- (id)initWithName:(NSString *)name
{
    if((self = [super init])) {
        _name = [name retain];
        _creationTime = CFAbsoluteTimeGetCurrent();
    }
    return self;
}

- (void)dealloc
{
    [_name release];
    [super dealloc];
}

- (void)stop
{
    CFAbsoluteTime _nowTime = CFAbsoluteTimeGetCurrent();
    _runTime = _nowTime - _creationTime;
}


- (void)report
{
    if(!_runTime) {
        [self stop];
    }
    
    THLog(@"THTimer %@: %f seconds elapsed", _name, _runTime);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"THTimer %@: %f seconds elapsed", _name, _runTime];
}

@synthesize runTime = _runTime;

@end
