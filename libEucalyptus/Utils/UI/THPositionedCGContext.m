//
//  THPositionedCGContext.m
//  libEucalyptus
//
//  Created by James Montgomerie on 23/02/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import "THPositionedCGContext.h"

@implementation THPositionedCGContext

@synthesize CGContext = _CGContext;
@synthesize origin = _origin;
@synthesize backing = _backing;

- (id)initWithCGContext:(CGContextRef)CGContext origin:(CGPoint)origin backing:(id)backing
{
    if((self = [super init])) {
        _CGContext = CGContextRetain(CGContext);
        _origin = origin;
        _backing = [backing retain];
    }
    return self;
}

- (id)initWithCGContext:(CGContextRef)CGContext backing:(id)backing
{
    return [self initWithCGContext:CGContext origin:CGPointZero backing:backing];
}

- (void)dealloc
{
    CGContextRelease(_CGContext);
    [_backing release];
    
    [super dealloc];
}

@end
