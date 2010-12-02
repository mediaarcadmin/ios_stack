//
//  EucSelectorRange.m
//  libEucalyptus
//
//  Created by James Montgomerie on 27/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucSelectorRange.h"
#import "EucBookPageIndexPoint.h"

@implementation EucSelectorRange

@synthesize startBlockId = _startBlockId;
@synthesize startElementId = _startElementId;
@synthesize endBlockId = _endBlockId;
@synthesize endElementId = _endElementId;

-(void)dealloc {
	self.startBlockId = nil;
	self.startElementId = nil;
	self.endBlockId = nil;
	self.endElementId = nil;
	[super dealloc];
}

- (BOOL)overlaps:(EucSelectorRange *)otherRange
{
    NSComparisonResult endStartComparison;
    NSComparisonResult endStartBlockComparison = [_endBlockId compare:otherRange->_startBlockId];
    if(endStartBlockComparison == NSOrderedSame) {
        endStartComparison = [_endElementId compare:otherRange->_startElementId];
    } else {
        endStartComparison = endStartBlockComparison;
    }
    
    if(endStartComparison == NSOrderedAscending) {
        return NO;
    }    
    
    NSComparisonResult startEndComparison;
    NSComparisonResult startEndBlockComparison = [_startBlockId compare:otherRange->_endBlockId];
    if(startEndBlockComparison == NSOrderedSame){
        startEndComparison = [_startElementId compare:otherRange->_endElementId];
    } else {
        startEndComparison = startEndBlockComparison;
    }
    
    if(startEndComparison == NSOrderedDescending) {
        return NO;
    }
    
    return YES;
}

- (BOOL)isEqual:(id)object
{
    if(object == self) {
        return YES;
    } else if([object isKindOfClass:[EucSelectorRange class]]) {
        EucSelectorRange *rhs = object;
        return [_startBlockId compare:rhs->_startBlockId] == NSOrderedSame && [_startElementId compare:rhs->_startElementId] == NSOrderedSame && 
               [_endBlockId compare:rhs->_endBlockId] == NSOrderedSame && [_endElementId compare:rhs->_endElementId] == NSOrderedSame ;
    }
    return NO;
}

- (NSUInteger)hash
{
    return [_startBlockId hash] ^ [_startElementId hash] ^ [_endBlockId hash] ^ [_endElementId hash];
}

@end

@implementation  EucHighlightRange (EucSelectorRangeAdditions)

- (EucSelectorRange *)selectorRange 
{
    EucSelectorRange *ret = [[EucSelectorRange alloc] init];
    
    EucBookPageIndexPoint *startPoint = self.startPoint;
    ret.startBlockId = [NSNumber numberWithUnsignedInt:startPoint.block];
    ret.startElementId = [NSNumber numberWithUnsignedInt:startPoint.word];
    
    EucBookPageIndexPoint *endPoint = self.endPoint;
    ret.endBlockId = [NSNumber numberWithUnsignedInt:endPoint.block];
    ret.endElementId = [NSNumber numberWithUnsignedInt:endPoint.word];
    
    return [ret autorelease];
}

@end

