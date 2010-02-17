//
//  EucSelectorRange.m
//  libEucalyptus
//
//  Created by James Montgomerie on 27/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucSelectorRange.h"

@implementation EucSelectorRange

@synthesize startBlockId = _startBlockId;
@synthesize startElementId = _startElementId;
@synthesize endBlockId = _endBlockId;
@synthesize endElementId = _endElementId;

- (BOOL)isEqual:(id)object
{
    if([object isKindOfClass:[EucSelectorRange class]]) {
        EucSelectorRange *rhs = object;
        return _startBlockId == rhs->_startBlockId && _startElementId == rhs->_startElementId && 
               _endBlockId == rhs->_endBlockId && _endElementId == rhs->_endElementId;
    }
    return NO;
}

- (NSUInteger)hash
{
    return [_startBlockId hash] ^ [_startElementId hash] ^ [_endBlockId hash] ^ [_endElementId hash];
}

@end
