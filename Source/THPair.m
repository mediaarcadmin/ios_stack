//
//  THPair.m
//  libEucalyptus
//
//  Created by James Montgomerie on 15/07/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "THPair.h"


@implementation THPair

@synthesize first;
@synthesize second;

- (id)initWithFirst:(id)firstIn second:(id)secondIn
{
    if((self = [super init])) {
        first = [firstIn retain];
        second = [secondIn retain];
    }
    return self;
}

+ (id)pairWithFirst:(id)firstIn second:(id)secondIn
{
    return [[[self alloc] initWithFirst:firstIn second:secondIn] autorelease];
}

- (void)dealloc
{
    [first release];
    [second release];
    [super dealloc];
}

- (NSUInteger)hash
{
    return [first hash] ^ [second hash];
}

- (BOOL)isEqual:(id)anObject
{
    if([anObject class] == [self class]) {
        id otherFirst = ((THPair *)anObject)->first;
        if(first == otherFirst || [first isEqual:otherFirst]) {
            id otherSecond = ((THPair *)anObject)->second;
            if(second == otherSecond || [second isEqual:otherSecond]) {
                return YES;
            }
        }
    }
    return NO;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [self retain];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"( %@, %@ )", first, second];
}

@end


@implementation NSMutableArray (THPairAdditions) 

- (void)addPairWithFirst:(id)first second:(id)second
{
    THPair *pair = [[THPair alloc] initWithFirst:first second:second];
    [self addObject:pair];
    [pair release];
}

@end
