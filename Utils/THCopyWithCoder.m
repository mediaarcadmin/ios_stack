//
//  THCopyWithCoder.m
//  libEucalyptus
//
//  Created by James Montgomerie on 09/03/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "THCopyWithCoder.h"


@implementation NSObject (THCopyWithCoder)

- (id)copyWithCoder
{
    return [[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]] retain];
}

@end
