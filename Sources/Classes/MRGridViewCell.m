//
//  MRGridViewCell.m
//
//  Created by Sean Doherty on 3/10/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "MRGridViewCell.h"

@interface BlioAccessibleButton : UIButton
@end


@implementation MRGridViewCell
@synthesize reuseIdentifier,contentView,deleteButton,cellContentDescription;

- (id)initWithFrame:(CGRect)frame reuseIdentifier: (NSString*) identifier{
    if ((self = [super initWithFrame:frame])) {
		self.reuseIdentifier = identifier;
		self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];
		self.autoresizesSubviews = YES;
		contentView = [[UIView alloc] initWithFrame:self.bounds];
		contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self addSubview:contentView];
		
		deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 33, 33)];
        deleteButton = [[BlioAccessibleButton alloc] initWithFrame:CGRectMake(0, 0, 33, 33)];
		deleteButton.alpha = 0;
		deleteButton.showsTouchWhenHighlighted = YES;
		[deleteButton setImage:[UIImage imageNamed:@"button-delete-red.png"] forState:UIControlStateNormal];
//        [deleteButton setIsAccessibilityElement:YES];
//        [deleteButton setAccessibilityLabel:NSLocalizedString(@"Delete book", @"Accessibility label for Grid View cell Delete button")];
//		[deleteButton setAccessibilityFrame:CGRectMake(0,0,100,100)];
        [self addSubview:deleteButton];
    }
    return self;
}

//override to clear out cell for reuse.  Similar to UITableViewCell call.
-(void) prepareForReuse{
	deleteButton.alpha = 0;
	self.transform = CGAffineTransformIdentity;
}

- (void)dealloc {
	self.contentView = nil;
	self.deleteButton = nil;
	self.cellContentDescription = nil;
    [super dealloc];
}

@end

@implementation BlioAccessibleButton

- (BOOL)isAccessibilityElement {
    return YES;
}

- (NSString *)accessibilityLabel {
    return @"Delete button";
}

@end

