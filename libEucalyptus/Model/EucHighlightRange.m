//
//  EucHighlight.m
//  libEucalyptus
//
//  Created by James Montgomerie on 13/05/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucHighlightRange.h"
#import "EucBookPageIndexPoint.h"

@implementation EucHighlightRange

@synthesize startPoint = _startPoint;
@synthesize endPoint = _endPoint;
@synthesize color = _color;

- (BOOL)isEqual:(id)object
{
    if([object isKindOfClass:[EucHighlightRange class]]) {
        EucHighlightRange *rhs = (EucHighlightRange *)object;
        return [self.startPoint isEqual:rhs.startPoint] && [self.endPoint isEqual:rhs.endPoint]; 
    }
    return NO;
}

- (NSUInteger)hash
{
    return [self.startPoint hash] ^ [self.endPoint hash];
}

- (id)copyWithZone:(NSZone *)zone
{
    EucHighlightRange *copy = [[EucHighlightRange allocWithZone:zone] init];
    
    EucBookPageIndexPoint *newStartPoint = [_startPoint copy];
    copy.startPoint = newStartPoint;
    [newStartPoint release];
    
    EucBookPageIndexPoint *newEndPoint = [_endPoint copy];
    copy.endPoint = newEndPoint;
    [newEndPoint release];
    
    copy.color = _color;
    return copy;
}

@end
