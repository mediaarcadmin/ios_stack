//
//  BlioViewSettingsSheet.m
//  BlioApp
//
//  Created by matt on 30/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import "BlioViewSettingsSheet.h"
#import "BlioViewSettingsContentsView.h"

@interface BlioViewSettingsSheet()

@property (nonatomic, retain) BlioViewSettingsContentsView *contentsView;

@end

@implementation BlioViewSettingsSheet

@synthesize contentsView;

- (void)dealloc {
    self.contentsView = nil;
    [super dealloc];
}

- (id)initWithDelegate:(id)newDelegate {
        
	if ((self = [super initWithTitle:nil delegate:newDelegate cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil])) {
        BlioViewSettingsContentsView *aContentsView = [[BlioViewSettingsContentsView alloc] initWithDelegate:newDelegate];
        [self addSubview:aContentsView];
        self.contentsView = aContentsView;
        [aContentsView release];
        
        self.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
 	}
	return self;
}

- (void)layoutSubviews {    
    CGRect origFrame = self.frame;
    [self.contentsView setFrame:CGRectMake(0, 0, origFrame.size.width, [self.contentsView contentsHeight])];
    [self.contentsView layoutSubviews];
    CGFloat heightOffset = self.contentsView.bounds.size.height;
    origFrame.origin.y -= heightOffset;
    origFrame.size.height += heightOffset;
    self.frame = origFrame;    
 
}

@end
