//
//  EucBookNavPoint.m
//  libEucalyptus
//
//  Created by James Montgomerie on 15/11/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucBookNavPoint.h"

@implementation EucBookNavPoint

@synthesize text = _text;
@synthesize uuid = _uuid;
@synthesize level = _level;

- (id)initWithText:(NSString *)text uuid:(NSString *)uuid level:(NSUInteger)level
{
    if((self = [super init])) {
        _text = [text copy];
        _uuid = [uuid copy];
        _level = level;
    }
    return self;
}

+ (id)navPointWithText:(NSString *)text uuid:(NSString *)uuid level:(NSUInteger)level
{
    return [[[self alloc] initWithText:text uuid:uuid level:level] autorelease];
}

- (void)dealloc
{
    [_text release];
    [_uuid release];
    
    [super dealloc];
}

// Legacy code support - thses used to be pairs of [text, uuid];
- (id)first { return self.text; }
- (id)second { return self.uuid; }

@end
