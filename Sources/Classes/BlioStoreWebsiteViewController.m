    //
//  BlioStoreWebsiteViewController.m
//  BlioApp
//
//  Created by Arnold Chien on 4/8/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioStoreWebsiteViewController.h"
#import "BlioAppSettingsConstants.h"

static NSString * const kBlioWebsiteIntro = @"To buy books for Blio, you must visit the blioreader.com website in a browser.  Purchased books will appear in your Vault for download the next time you start Blio.";

@implementation BlioStoreWebsiteViewController

- (id)init {
    if ((self = [super init])) {
        self.title = @"Buy Books";
        
        UITabBarItem* theItem = [[UITabBarItem alloc] initWithTitle:@"Buy Books" image:[UIImage imageNamed:@"icon-cart.png"] tag:kBlioStoreBuyBooksTag];
        self.tabBarItem = theItem;
        [theItem release];
    }
    return self;
}

+ (UILabel *)labelWithFrame:(CGRect)frame title:(NSString *)title
{
    UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
    
	label.textAlignment = UITextAlignmentLeft;
    label.text = title;
	label.adjustsFontSizeToFitWidth = YES;
	label.numberOfLines = 0;
    label.font = [UIFont boldSystemFontOfSize:14.0];
    label.textColor = [UIColor colorWithRed:76.0/255.0 green:86.0/255.0 blue:108.0/255.0 alpha:1.0];
    label.backgroundColor = [UIColor clearColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
    return label;
}

- (void)createControls
{
	// Display instructions for website.
	CGFloat yPlacement = kTopMargin;
	CGRect frame = CGRectMake(kLeftMargin, yPlacement, self.view.bounds.size.width - kLeftMargin - kRightMargin, 5*kLabelHeight);
	[self.view addSubview:[BlioStoreWebsiteViewController labelWithFrame:frame title:kBlioWebsiteIntro]];
	
	// blioreader.com button.
	yPlacement += kTweenMargin + 5*kLabelHeight;
	launchButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
	launchButton.frame = CGRectMake(kLeftMargin, yPlacement, (2.6)*kStdButtonWidth, kStdButtonHeight);
    launchButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[launchButton setTitle:@"Open blioreader.com in Safari" forState:UIControlStateNormal];
	launchButton.backgroundColor = [UIColor clearColor];
	[launchButton addTarget:self action:@selector(launchWebsite:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:launchButton];
	[launchButton release];
	
}

- (void)loadView
{	
	// create a gradient-based content view	
	UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	contentView.backgroundColor = [UIColor groupTableViewBackgroundColor];	// use the table view background color
	contentView.autoresizesSubviews = YES;
	self.view = contentView;
	[contentView release];
	[self createControls];	
}

- (void)launchWebsite:(id)sender {	
	UIButton* ctl = (UIButton*)sender;
	if ( ctl == launchButton ) {
		NSURL* url = [[NSURL alloc] initWithString:@"http://knfb.theretailerplace.net/KNFB/screens/index.jsp"];
		[[UIApplication sharedApplication] openURL:url];			  
	}
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

@end