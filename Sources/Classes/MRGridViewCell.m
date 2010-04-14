//
//  MRGridViewCell.m
//
//  Created by Sean Doherty on 3/10/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "MRGridViewCell.h"


@implementation MRGridViewCell
@synthesize reuseIdentifier;

- (id)initWithFrame:(CGRect)frame reuseIdentifier: (NSString*) identifier{
    if ((self = [super initWithFrame:frame])) {
		self.reuseIdentifier = identifier;
		self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];

    }
    return self;
}

//override to clear out cell for reuse.  Similar to UITableViewCell call.
-(void) prepareForReuse{
	
}

- (void)dealloc {
    [super dealloc];
}


@end
