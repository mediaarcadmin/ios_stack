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
#import "BlioStoreManager.h"
#import <QuartzCore/CALayer.h>

@implementation BlioStoreWebsitePhoneContentView

@synthesize screenshotView,headerLabel,subHeaderLabel;

- (id)initWithFrame:(CGRect)aFrame {
    if ((self = [super initWithFrame:aFrame])) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}
-(void)dealloc {
	self.screenshotView = nil;
	self.headerLabel = nil;
	self.subHeaderLabel = nil;
	[super dealloc];
}
-(void)layoutSubviews {
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation]; 
    
    
    if(UIInterfaceOrientationIsLandscape(orientation)) {
		self.screenshotView.frame = CGRectMake(10,10,160,202);
		self.headerLabel.hidden = YES;
		self.subHeaderLabel.hidden = YES;
	}
	else {
		self.screenshotView.frame = CGRectMake(10,15,105,132);
		self.headerLabel.hidden = NO;
		self.subHeaderLabel.hidden = NO;
	}
		
}
@end


@implementation BlioStoreWebsiteViewController

@synthesize explanationLabel,phoneContentView;

- (id)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Buy Books",@"\"Buy Books\" view controller title");
        
        UITabBarItem* theItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Buy Books",@"\"Buy Books\" bar button title") image:[UIImage imageNamed:@"icon-cart.png"] tag:kBlioStoreBuyBooksTag];
        self.tabBarItem = theItem;
        [theItem release];
    }
    return self;
}
-(void)dealloc {
	self.explanationLabel = nil;
	self.phoneContentView = nil;
	[super dealloc];
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
	self.view = [[[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
	
	
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
//		self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];	// use the table view background color
		self.view.backgroundColor = [UIColor whiteColor];	// use the table view background color
		self.view.autoresizesSubviews = YES;
		
		self.phoneContentView = [[[BlioStoreWebsitePhoneContentView alloc] initWithFrame:self.view.bounds] autorelease];
		[self.view addSubview:phoneContentView];

		// screenshot image
		UIImageView * screenshotView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"webstore-screenshot-phone.png"]] autorelease];
		screenshotView.frame = CGRectMake(10,15,105,132);
		[self.phoneContentView addSubview:screenshotView];
		self.phoneContentView.screenshotView = screenshotView;
		
		// Header
		UILabel * headerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(120,75,185,28)] autorelease];
		headerLabel.font = [UIFont boldSystemFontOfSize:24.0f];
		headerLabel.backgroundColor = [UIColor clearColor];
		headerLabel.text = NSLocalizedString(@"BlioReader.com",@"Buy Books View Header");
		[self.phoneContentView addSubview:headerLabel];
		self.phoneContentView.headerLabel = headerLabel;
		
		// sub-header
		UILabel * subHeaderLabel = [[[UILabel alloc] initWithFrame:CGRectMake(120,100,185,42)] autorelease];
		subHeaderLabel.font = [UIFont boldSystemFontOfSize:18.0f];
		subHeaderLabel.textColor = [UIColor grayColor];
		subHeaderLabel.backgroundColor = [UIColor clearColor];
		subHeaderLabel.numberOfLines = 2;
		subHeaderLabel.text = NSLocalizedString(@"Where books are more than words.",@"Buy Books View Sub-Header");
		[self.phoneContentView addSubview:subHeaderLabel];
		self.phoneContentView.subHeaderLabel = subHeaderLabel;

		// Display instructions for website.
		
		CGFloat yPlacement = 268;
		CGRect frame = CGRectMake(kLeftMargin, yPlacement, self.view.bounds.size.width - kLeftMargin - kRightMargin, 5*kLabelHeight);
		
		self.explanationLabel = [BlioStoreWebsiteViewController labelWithFrame:frame title:@""];
		self.explanationLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
		[self updateExplanation];
		[self.phoneContentView addSubview:self.explanationLabel];
		
		// blioreader.com button.
		yPlacement += kTweenMargin + 5*kLabelHeight;
		launchButton = [UIButton buttonWithType:UIButtonTypeCustom];
		launchButton.frame = CGRectMake(self.view.bounds.size.width/2 - ((2.6)*kStdButtonWidth)/2, yPlacement, (2.6)*kStdButtonWidth, kStdButtonHeight);
		launchButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
		[[launchButton layer] setCornerRadius:8.0f];
		[[launchButton layer] setMasksToBounds:YES];
		[[launchButton layer] setBorderWidth:2.0f];
		[[launchButton layer] setBorderColor:[[UIColor colorWithRed:100.0f/255.0f green:100.0f/255.0f blue:100.0f/255.0f alpha:1] CGColor]];
		[launchButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//		[launchButton setBackgroundColor:[UIColor whiteColor]];
//		CAGradientLayer * gradientLayer = [[CAGradientLayer alloc] init];
//		[gradientLayer setBounds:[launchButton bounds]];
//		[gradientLayer setPosition:CGPointMake([launchButton bounds].size.width/2,[launchButton bounds].size.height/2)];
//		[[launchButton layer] insertSublayer:gradientLayer atIndex:0];
//		[gradientLayer setColors:[NSArray arrayWithObjects:(id)[[UIColor whiteColor] CGColor],(id)[[UIColor colorWithRed:200.0f/255.0f green:200.0f/255.0f blue:200.0f/255.0f alpha:1] CGColor], nil]];
//		[gradientLayer release];
//		launchButton.backgroundColor = [UIColor clearColor];
		[launchButton setBackgroundImage:[UIImage imageNamed:@"button-background-graygradient.png"] forState:UIControlStateNormal];
		[self.phoneContentView addSubview:launchButton];
		
		
		createAccountButton = [UIButton buttonWithType:UIButtonTypeCustom];
		CGRect createAccountButtonFrame = launchButton.frame;
		createAccountButtonFrame.origin.y = launchButton.frame.origin.y + launchButton.frame.size.height + kTweenMargin;
		createAccountButton.frame = createAccountButtonFrame;
		createAccountButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
		createAccountButton.backgroundColor = [UIColor clearColor];
		[createAccountButton setBackgroundImage:[[UIImage imageNamed:@"button-buybooks.png"] stretchableImageWithLeftCapWidth:14 topCapHeight:14] forState:UIControlStateNormal];
//		[self.phoneContentView addSubview:createAccountButton];
	}
	else {
		self.view.backgroundColor = [UIColor whiteColor]; // the default background color of grouped tableview on iPad
		self.view.autoresizesSubviews = YES;
		
		UIView * contentView = [[[UIView alloc] initWithFrame:CGRectMake(0,0,650,450)] autorelease];
		[self.view addSubview:contentView];
		contentView.center = CGPointMake(self.view.frame.size.width/2,self.view.frame.size.height/2);
		contentView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		contentView.autoresizesSubviews = NO;

		// screenshot image
		UIImageView * screenshotView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"webstore-screenshot-ipad.png"]] autorelease];
		screenshotView.frame = CGRectMake(35,100,300,382);
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
		subHeaderLabel.text = NSLocalizedString(@"Where books are more than words.",@"Buy Books View Sub-Header");

		// explanation
		self.explanationLabel = [[[UILabel alloc] initWithFrame:CGRectMake(360,120,285,230)] autorelease];
		[contentView addSubview:explanationLabel];
		explanationLabel.font = [UIFont boldSystemFontOfSize:12.0f];
		explanationLabel.textColor = [UIColor blackColor];
		explanationLabel.backgroundColor = [UIColor clearColor];
		explanationLabel.numberOfLines = 320;
		explanationLabel.textAlignment = UITextAlignmentCenter;
		[self updateExplanation];
		// blioreader.com button.
		launchButton = [UIButton buttonWithType:UIButtonTypeCustom];
		launchButton.frame = CGRectMake(355,350,298,50);
		launchButton.backgroundColor = [UIColor clearColor];
//		[launchButton setBackgroundImage:[[UIImage imageNamed:@"button-buybooks.png"] stretchableImageWithLeftCapWidth:14 topCapHeight:14] forState:UIControlStateNormal];
		[[launchButton layer] setCornerRadius:8.0f];
		[[launchButton layer] setMasksToBounds:YES];
		[[launchButton layer] setBorderWidth:2.0f];
		[[launchButton layer] setBorderColor:[[UIColor colorWithRed:100.0f/255.0f green:100.0f/255.0f blue:100.0f/255.0f alpha:1] CGColor]];
		[launchButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		[launchButton setBackgroundImage:[UIImage imageNamed:@"button-background-graygradient.png"] forState:UIControlStateNormal];
		[contentView addSubview:launchButton];
		
		createAccountButton = [UIButton buttonWithType:UIButtonTypeCustom];
		CGRect createAccountButtonFrame = launchButton.frame;
		createAccountButtonFrame.origin.y = launchButton.frame.origin.y + launchButton.frame.size.height + kTweenMargin;
		createAccountButton.frame = createAccountButtonFrame;
		createAccountButton.backgroundColor = [UIColor clearColor];
		[createAccountButton setBackgroundImage:[[UIImage imageNamed:@"button-buybooks.png"] stretchableImageWithLeftCapWidth:14 topCapHeight:14] forState:UIControlStateNormal];
//		[contentView addSubview:createAccountButton];
		
	}
	[createAccountButton setTitle:NSLocalizedString(@"Create Account",@"\"Create Account\" text label for cell in Store Website View Controller") forState:UIControlStateNormal];
	[createAccountButton addTarget:self action:@selector(openModalCreateAccount:) forControlEvents:UIControlEventTouchUpInside];
	[self updateLogin];
}
-(void)updateLogin {	
	if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) {
		[launchButton addTarget:self action:@selector(launchWebsite:) forControlEvents:UIControlEventTouchUpInside];
		[launchButton setTitle:NSLocalizedString(@"Open blioreader.com in Safari",@"Button label for opening blioreader.com in Mobile Safari.") forState:UIControlStateNormal];
		createAccountButton.hidden = YES;
	}
	else {
		[launchButton addTarget:self action:@selector(confirmLaunch:) forControlEvents:UIControlEventTouchUpInside];
//		[launchButton setTitle:NSLocalizedString(@"Login",@"Button label for opening login window.") forState:UIControlStateNormal];
		[launchButton setTitle:NSLocalizedString(@"Open blioreader.com in Safari",@"Button label for opening blioreader.com in Mobile Safari.") forState:UIControlStateNormal];
		createAccountButton.hidden = NO;
	}
}
-(void)updateExplanation {
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
		NSString * labelTitle = NSLocalizedStringWithDefaultValue(@"BUY_BOOKS_EXPLANATION",nil,[NSBundle mainBundle],@"In the Blio bookstore, you can browse today's hot titles as well as full-color cookbooks, travel guides, children's books, and textbooks from over a hundred top publishers.",@"Explanation text for how to buy books through the website/mobile Safari.");
		//if (![[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) {
		//	NSString * getStarted = NSLocalizedStringWithDefaultValue(@"TO_GET_STARTED_PLEASE_LOGIN",nil,[NSBundle mainBundle],@"To get started, please log in or create an account.",@"Explanation encouraging the end user to get started purchasing books by first logging in.");
		//	labelTitle = [NSString stringWithFormat:@"%@ %@",labelTitle,getStarted];
		//}
		explanationLabel.text = labelTitle;
	}
	else {
		CGRect explanationFrame = explanationLabel.frame;
		NSString * explanationText = NSLocalizedStringWithDefaultValue(@"BUY_BOOKS_EXPLANATION_IPAD",nil,[NSBundle mainBundle],@"In the Blio bookstore, you can browse today's hot titles as well as full-color cookbooks, travel guides, children's books, and textbooks from over a hundred top publishers.\n\nMany books can be read aloud in Blio by a TTS voice (separate purchase required) or recorded audio, with words highlighted as they are spoken.  And many books preserve the original print layout, which can be navigated by block with Blio's ReadLogic eliminating the need to scroll and zoom.  Head to Blio for the coolest digital reading experience available today.",@"Explanation text for how to buy books through the website/mobile Safari (for iPad)");
//		if (![[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) {
//			NSString * getStarted = NSLocalizedStringWithDefaultValue(@"TO_GET_STARTED_PLEASE_LOGIN",nil,[NSBundle mainBundle],@"To get started, please log in or create an account.",@"Explanation encouraging the end user to get started purchasing books by first logging in.");
//			explanationText = [NSString stringWithFormat:@"%@ %@",explanationText,getStarted];
//		}			
		CGSize explanationSize = [explanationText sizeWithFont:explanationLabel.font constrainedToSize:explanationLabel.frame.size lineBreakMode:UILineBreakModeWordWrap];
		explanationFrame.size.height = explanationSize.height;
		explanationLabel.frame = explanationFrame;
		explanationLabel.text = explanationText;		
	}
}
- (void)confirmLaunch:(id)sender {	
	if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) {
		[self launchWebsite:sender];
	}
	else {
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Attention",@"\"Attention...\" alert message title") 
									 message:NSLocalizedStringWithDefaultValue(@"LOGIN_BEFORE_BROWSING_WEBSTORE",nil,[NSBundle mainBundle],@"If you log in now, Blio will be able to automatically download your bookstore purchases when you return. Would you like to log in?  You'll be able to create an account if you don't yet have one.",@"Alert Text encouraging the end-user to log in before leaving for the webstore.")
									delegate:self 
						   cancelButtonTitle:nil
						   otherButtonTitles:NSLocalizedString(@"Not Now",@"\"Not Now\" button title"),NSLocalizedString(@"Log in",@"\"Log in\" button title"),nil];	
	}
}
- (void)launchWebsite:(id)sender {	
	// Open question whether we will go to a single top-level URL here for both iphone and ipad.
//	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//		UIButton* ctl = (UIButton*)sender;
//		if ( ctl == launchButton ) {
//			NSURL* url = [[NSURL alloc] initWithString:@"https://hp.theretailerplace.net"];
//			NSURL* url = [[NSURL alloc] initWithString:@"http://bliodemo.crosscomm.net"];
			NSURL* url = [[NSURL alloc] initWithString:@"https://Iphone.Bliodigitallocker.com"];
			
			[[UIApplication sharedApplication] openURL:url];			  
//		}
//	}
	// TODO: take out this beta alert below!
//	else {
//		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"We're Sorry...",@"\"We're Sorry...\" alert message title") 
//								 message:NSLocalizedStringWithDefaultValue(@"BETA_MOBILE_STORE_NOT_AVAILABLE",nil,[NSBundle mainBundle],@"The Blio Book Store cannot be accessed through this link during the beta testing period.",@"Alert Text informing the end-user that the Blio Book Store is not available for this beta release.")
//								delegate:nil 
//					   cancelButtonTitle:@"OK"
//					   otherButtonTitles:nil];
//	}
}
- (void)openModalLogin:(id)sender {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDismissed:) name:BlioLoginFinished object:[BlioStoreManager sharedInstance]];
	[[BlioStoreManager sharedInstance] showLoginViewForSourceID:BlioBookSourceOnlineStore];
}
- (void)openModalCreateAccount:(id)sender {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDismissed:) name:BlioLoginFinished object:[BlioStoreManager sharedInstance]];
	[[BlioStoreManager sharedInstance] showCreateAccountViewForSourceID:BlioBookSourceOnlineStore];
}
-(void)loginDismissed:(NSNotification*)note {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioLoginFinished object:[BlioStoreManager sharedInstance]];
	if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) {
		[self launchWebsite:nil];
	}
}
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
//	[self.phoneContentView layoutSubviews];
}
#pragma mark - 
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex == 0) {
		[self launchWebsite:alertView];
	}
	else if (buttonIndex == 1) {
		[self openModalLogin:alertView];
	}
}

@end