//
//  BlioTextFlowPageMarker.m
//  Scholastic
//
//  Created by Gordon Christie on 29/03/2011.
//  Copyright 2011 BitWink. All rights reserved.
//

#import "BlioTextFlowPageMarker.h"

@implementation BlioTextFlowPageMarker

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super init])) {
        self.pageIndex = [coder decodeIntegerForKey:@"BlioTextFlowPageMarkerPageIndex"];
        self.byteIndex = [coder decodeIntegerForKey:@"BlioTextFlowPageMarkerByteIndex"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:self.pageIndex forKey:@"BlioTextFlowPageMarkerPageIndex"];
    [coder encodeInteger:self.byteIndex forKey:@"BlioTextFlowPageMarkerByteIndex"];
}

@end

