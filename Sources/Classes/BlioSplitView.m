//
//  BlioSplitView.m
//
//  Created by Don Shin on 6/25/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "BlioSplitView.h"


@implementation BlioSplitView

@synthesize view1,view2;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
    }
    return self;
}
- (void)layoutSubviews {
	[self bringSubviewToFront:view1];
	view1.frame = CGRectMake(0, 0, 320, self.bounds.size.height);
	view2.frame = CGRectMake(322, 0, self.bounds.size.width - 322, self.bounds.size.height);
	[view1 layoutSubviews];
	[view2 layoutSubviews];
}

- (void)dealloc {
	self.view1 = nil;
	self.view2 = nil;
    [super dealloc];
}


@end
