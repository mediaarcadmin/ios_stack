//
//  UIButton+BlioAdditions.m
//  BlioApp
//
//  Created by Don Shin on 12/16/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "UIButton+BlioAdditions.h"
#import <QuartzCore/CALayer.h>

@implementation UIButton (BlioAdditions)
+(UIButton*)lightButton {
	UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
	[[button layer] setCornerRadius:8.0f];
	[[button layer] setMasksToBounds:YES];
	[[button layer] setBorderWidth:2.0f];
	[[button layer] setBorderColor:[[UIColor colorWithRed:100.0f/255.0f green:100.0f/255.0f blue:100.0f/255.0f alpha:1] CGColor]];
	[button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	//	button.titleLabel.adjustsFontSizeToFitWidth = YES;
	//	button.titleLabel.font = [UIFont systemFontOfSize:14.0f];
	[button setBackgroundImage:[UIImage imageNamed:@"button-background-graygradient.png"] forState:UIControlStateNormal];
	return button;
}
+(UIButton*)buyButton {
	UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
//	[[button layer] setCornerRadius:8.0f];
//	[[button layer] setMasksToBounds:YES];
//	[[button layer] setBorderWidth:2.0f];
//	[[button layer] setBorderColor:[[UIColor colorWithRed:100.0f/255.0f green:100.0f/255.0f blue:100.0f/255.0f alpha:1] CGColor]];
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	//	button.titleLabel.adjustsFontSizeToFitWidth = YES;
	button.titleLabel.font = [UIFont boldSystemFontOfSize:14.0f];
	[button setBackgroundImage:[[UIImage imageNamed:@"downloadButton.png"] stretchableImageWithLeftCapWidth:3 topCapHeight:0] forState:UIControlStateNormal];
	return button;
}
@end
