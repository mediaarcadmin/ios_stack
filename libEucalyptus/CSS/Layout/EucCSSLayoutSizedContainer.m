//
//  EucCSSLayoutSizedContainer.m
//  libEucalyptus
//
//  Created by James Montgomerie on 04/01/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutSizedContainer.h"


@implementation EucCSSLayoutSizedContainer

@synthesize scaleFactor = _scaleFactor;
@synthesize parent = _parent;

- (id)initWithScaleFactor:(CGFloat)scaleFactor
{
    if((self = [super init])) {
        _scaleFactor = scaleFactor;
    }
    return self;
}

- (NSArray *)children
{
    return nil;
}

- (CGFloat)minWidth
{
    return 0;
}

- (CGFloat)maxWidth
{
    return 0;
}

@end
