//
//  BlioTextFlowPageRange.m
//  Scholastic
//
//  Created by Gordon Christie on 29/03/2011.
//  Copyright 2011 BitWink. All rights reserved.
//

#import "BlioTextFlowPageRange.h"

@implementation BlioTextFlowPageRange

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super init])) {
        self.startPageIndex = [coder decodeIntegerForKey:@"BlioTextFlowPageRangePageIndex"];
        self.endPageIndex = [coder decodeIntegerForKey:@"BlioTextFlowPageRangeEndPageIndex"];
        //self.path = [coder decodeObjectForKey:@"BlioTextFlowPageRangePagePath"];
        self.fileName = [coder decodeObjectForKey:@"BlioTextFlowPageRangePageFileName"];
        self.pageMarkers = [NSMutableSet setWithSet:[coder decodeObjectForKey:@"BlioTextFlowPageRangeImmutablePageMarkers"]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:self.startPageIndex forKey:@"BlioTextFlowPageRangePageIndex"];
    [coder encodeInteger:self.endPageIndex forKey:@"BlioTextFlowPageRangeEndPageIndex"];
    //[coder encodeObject:self.path forKey:@"BlioTextFlowPageRangePagePath"];
    [coder encodeObject:self.fileName forKey:@"BlioTextFlowPageRangePageFileName"];
    [coder encodeObject:[NSSet setWithSet:self.pageMarkers] forKey:@"BlioTextFlowPageRangeImmutablePageMarkers"];
}

@end

