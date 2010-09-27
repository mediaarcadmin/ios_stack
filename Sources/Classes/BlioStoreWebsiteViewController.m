    //
//  BlioStoreWebsiteViewController.m
//  BlioApp
//
//  Created by Arnold Chien on 4/8/10.
//  Copyright 2010 Kurzweil Technologies Inc. All rights reserved.
//

#import "BlioStoreWebsiteViewController.h"
#import "BlioAppSettingsConstants.h"
#import "BlioAlertManager.h"

@implementation BlioStoreWebsiteViewController

- (id)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Buy Books",@"\"Buy Books\" view controller header");
        
        UITabBarItem* theItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Buy Books",@"\"Buy Books\" bar button title") image:[UIImage imageNamed:@"icon-cart.png"] tag:kBlioStoreBuyBooksTag];
        self.tabBarItem = theItem;
        [theItem release];
    }
    return self;
}

+ (UILabel *)labelWithFrame:(CGRect)frame title:(NSString *)title
{
    UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
    
	label.textAlignment = UITextAlignmentCenter;
    label.text = title;
	label.adjustsFontSizeToFitWidth = YES;
	label.numberOfLines = 0;
    label.font = [UIFont boldSystemFontOfSize:14.0];
    label.textColor = [UIColor colorWithRed:76.0/255.0 green:86.0/255.0 blue:108.0/255.0 alpha:1.0];
    label.backgroundColor = [UIColor clearColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
    return label;
}

- (void)loadView
{	
	// create a gradient-based content view	
	self.view = [[[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease];
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
		self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];	// use the table view background color
		self.view.autoresizesSubviews = YES;
		
		// Display instructions for website.
		CGFloat yPlacement = kTopMargin;
		CGRect frame = CGRectMake(kLeftMargin, yPlacement, self.view.bounds.size.width - kLeftMargin - kRightMargin, 5*kLabelHeight);
		[self.view addSubview:[BlioStoreWebsiteViewController labelWithFrame:frame title:NSLocalizedStringWithDefaultValue(@"BUY_BOOKS_EXPLANATION",nil,[NSBundle mainBundle],@"To buy books for Blio, you must visit the blioreader.com website in a browser.  Purchased books will appear in your Vault for download the next time you start Blio.",@"Explanation text for how to buy books through the website/mobile Safari.")]];
		
		// blioreader.com button.
		yPlacement += kTweenMargin + 5*kLabelHeight;
		launchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		launchButton.frame = CGRectMake(self.view.bounds.size.width/2 - ((2.6)*kStdButtonWidth)/2, yPlacement, (2.6)*kStdButtonWidth, kStdButtonHeight);
		launchButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		launchButton.backgroundColor = [UIColor clearColor];
		[self.view addSubview:launchButton];
		
	}
	else {
		self.view.backgroundColor = [UIColor colorWithRed:255.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:1.0f]; // the default background color of grouped tableview on iPad
		self.view.autoresizesSubviews = YES;
		
		UIView * contentView = [[[UIView alloc] initWithFrame:CGRectMake(0,0,650,450)] autorelease];
		[self.view addSubview:contentView];
		contentView.center = CGPointMake(self.view.frame.size.width/2,self.view.frame.size.height/2);
		contentView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		contentView.autoresizesSubviews = NO;

		// screenshot image
		UIImageView * screenshotView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"store-screenshot.png"]] autorelease];
		screenshotView.frame = CGRectMake(0,70,350,375);
		[contentView addSubview:screenshotView];
		
		// Header
		UILabel * headerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(30,10,575,60)] autorelease];
		[contentView addSubview:headerLabel];
		headerLabel.font = [UIFont boldSystemFontOfSize:45.0f];
		headerLabel.backgroundColor = [UIColor clearColor];
		headerLabel.text = NSLocalizedString(@"BlioReader.com",@"Buy Books View Header");
		// sub-header
		UILabel * subHeaderLabel = [[[UILabel alloc] initWithFrame:CGRectMake(125,60,480,40)] autorelease];
		[contentView addSubview:subHeaderLabel];
		subHeaderLabel.font = [UIFont systemFontOfSize:30.0f];
		subHeaderLabel.textColor = [UIColor grayColor];
		subHeaderLabel.backgroundColor = [UIColor clearColor];
		subHeaderLabel.text = NSLocalizedString(@"Over 75,000 Books, Available Now",@"Buy Books View Sub-Header");

		// explanation
		UILabel * explanationLabel = [[[UILabel alloc] initWithFrame:CGRectMake(360,140,285,230)] autorelease];
		[contentView addSubview:explanationLabel];
		explanationLabel.font = [UIFont boldSystemFontOfSize:12.0f];
		explanationLabel.textColor = [UIColor blackColor];
		explanationLabel.backgroundColor = [UIColor clearColor];
		explanationLabel.numberOfLines = 320;
		CGRect explanationFrame = explanationLabel.frame;
		NSString * explanationText = NSLocalizedStringWithDefaultValue(@"BUY_BOOKS_EXPLANATION_IPAD",nil,[NSBundle mainBundle],@"Enjoy a vast selection of cookbooks, travel guides, how-to books, schoolbooks, art books, children's stories, and magazines. Relax, learn, work, or play! The smart display lets you insert highlights, notes, videos, and even webpages. Selected books also go hands-free with Blio's read-aloud feature.\n\nFlexible & accessible. Shop endless titles, right from the Blio Bookstore, with access to over one million free books and a huge library of today's bestsellers. Then, take your library on the road by syncing to your favorite on-the-go mobile device.",@"Explanation text for how to buy books through the website/mobile Safari (for iPad)");
		CGSize explanationSize = [explanationText sizeWithFont:explanationLabel.font constrainedToSize:explanationLabel.frame.size lineBreakMode:UILineBreakModeWordWrap];
		explanationFrame.size.height = explanationSize.height;
		explanationLabel.frame = explanationFrame;
		explanationLabel.text = explanationText;
		explanationLabel.textAlignment = UITextAlignmentCenter;
		
		// blioreader.com button.
		launchButton = [UIButton buttonWithType:UIButtonTypeCustom];
		launchButton.frame = CGRectMake(355,380,298,50);
		launchButton.backgroundColor = [UIColor clearColor];
		[launchButton setBackgroundImage:[[UIImage imageNamed:@"button-buybooks.png"] stretchableImageWithLeftCapWidth:14 topCapHeight:14] forState:UIControlStateNormal];
		[contentView addSubview:launchButton];
	}
	[launchButton addTarget:self action:@selector(launchWebsite:) forControlEvents:UIControlEventTouchUpInside];
	[launchButton setTitle:NSLocalizedString(@"Open blioreader.com in Safari",@"Button label for opening blioreader.com in Mobile Safari.") forState:UIControlStateNormal];

}

- (void)launchWebsite:(id)sender {	
	// TODO: take out this beta alert below!
	[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"We're Sorry...",@"\"We're Sorry...\" alert message title") 
								 message:NSLocalizedStringWithDefaultValue(@"BETA_MOBILE_STORE_NOT_AVAILABLE",nil,[NSBundle mainBundle],@"The Blio Book Store is not available for this beta release.",@"Alert Text informing the end-user that the Blio Book Store is not available for this beta release.")
								delegate:nil 
					   cancelButtonTitle:@"OK"
					   otherButtonTitles:nil];
	return;
	
	UIButton* ctl = (UIButton*)sender;
	if ( ctl == launchButton ) {
		NSURL* url = [[NSURL alloc] initWithString:@"https://hp.theretailerplace.net"];
		[[UIApplication sharedApplication] openURL:url];			  
	}
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

@end