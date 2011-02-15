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

- (void)dealloc 
{
	self.startPoint = nil;
	self.endPoint = nil;
	self.color = nil;
    
	[super dealloc];
}

- (BOOL)intersects:(EucHighlightRange *)otherRange
{
    return ([self.startPoint compare:otherRange.endPoint] != NSOrderedDescending &&
            [self.endPoint compare:otherRange.startPoint] != NSOrderedAscending);
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
