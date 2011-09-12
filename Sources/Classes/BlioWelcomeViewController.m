    //
//  BlioWelcomeViewController.m
//  BlioApp
//
//  Created by Don Shin on 12/16/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "BlioAppSettingsConstants.h"
#import "BlioWelcomeViewController.h"
#import "UIButton+BlioAdditions.h"
#import "BlioStoreManager.h"
#import "BlioCreateAccountViewController.h"
#import "BlioLoginViewController.h"

@implementation BlioWelcomeTitleView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		welcomeToLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		welcomeToLabel.lineBreakMode = UILineBreakModeClip;
		welcomeToLabel.numberOfLines = 1;
		welcomeToLabel.font = [UIFont systemFontOfSize:25.0f];
		welcomeToLabel.textColor = [UIColor colorWithRed:43.0f/255.0f green:196.0f/255.0f blue:230.0f/255.0f alpha:1];
		welcomeToLabel.text = NSLocalizedString(@"Welcome to",@"\"Welcome to\" header on welcome view controller.");
		[self addSubview:welcomeToLabel];
		[welcomeToLabel release];		

		blioLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		blioLabel.lineBreakMode = UILineBreakModeClip;
		blioLabel.numberOfLines = 1;
		blioLabel.font = [UIFont systemFontOfSize:65.0f];
		blioLabel.textColor = [UIColor colorWithRed:54.0f/255.0f green:54.0f/255.0f blue:54.0f/255.0f alpha:1];
		blioLabel.text = NSLocalizedString(@"Blio",@"\"Blio\" header on welcome view controller.");
		[self addSubview:blioLabel];
		[blioLabel release];
		
		[self setAccessibilityLabel:NSLocalizedString(@"Welcome to Blio", @"Accessibility label for \"Welcome to Blio\" welcome screen header.")];

	}
    return self;
}
-(void)layoutSubviews {
	welcomeToLabel.frame = CGRectMake(0, 5, 160, 30);
	blioLabel.frame = CGRectMake(0, 30, 160, 70);
}
- (BOOL)isAccessibilityElement {
    return YES;
}
@end


@implementation BlioWelcomeView

@synthesize firstTimeUserButton,existingUserButton;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor whiteColor];
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            UIGraphicsBeginImageContext(CGSizeMake(100, 100));
            CGContextRef context = UIGraphicsGetCurrentContext();
            UIImage *logoImage = [UIImage imageWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Icon@2x" ofType:@"png"]]];
			
            // Mask off the outside of the icon like the device does.
            CGContextMoveToPoint(context, 0, 0);
            CGContextAddArcToPoint(context, 0, 0, 50, 0, 15);
            CGContextAddArcToPoint(context, 100, 0, 100, 50, 15);
            CGContextAddArcToPoint(context, 100, 100, 50, 100, 15);
            CGContextAddArcToPoint(context, 0, 100, 0, 50, 15);
            CGContextClosePath(context);
            CGContextClip(context);
            [logoImage drawInRect:CGRectMake(-7, -7, 114, 114)];
			
            logoView = [[UIImageView alloc] initWithImage:UIGraphicsGetImageFromCurrentImageContext()];
			
            UIGraphicsEndImageContext();
			
            [self addSubview:logoView];
            [logoView release];
			
			welcomeTitleView = [[BlioWelcomeTitleView alloc] initWithFrame:CGRectZero];
			[self addSubview:welcomeTitleView];
			[welcomeTitleView release];

			welcomeTextView = [[UILabel alloc] initWithFrame:CGRectZero];
			welcomeTextView.lineBreakMode = UILineBreakModeWordWrap;
			welcomeTextView.numberOfLines = 0;
			welcomeTextView.text = NSLocalizedStringWithDefaultValue(@"WELCOME_TEXT",nil,[NSBundle mainBundle],@"With Blio, books are more than just words: there's style, presentation, and a world of color. Now you can read books with the same layout, fonts, and full-color images that you enjoy in the print version of your favorite titles.",@"Welcome message on welcome view controller.");
			[self addSubview:welcomeTextView];
			[welcomeTextView release];
		}    
		existingUserTitleView = [[UILabel alloc] initWithFrame:CGRectZero];
		existingUserTitleView.lineBreakMode = UILineBreakModeWordWrap;
		existingUserTitleView.numberOfLines = 0;
		existingUserTitleView.text = NSLocalizedString(@"Log In",@"\"Log In\" existing user title for welcome view controller.");
		[self addSubview:existingUserTitleView];
		[existingUserTitleView release];
		[existingUserTitleView setAccessibilityHint:NSLocalizedString(@"Section header for existing Blio users.", @"Accessibility hint for \"Already have an account?\" section header on welcome screen.")];
        
		existingUserTextView = [[UILabel alloc] initWithFrame:CGRectZero];
		existingUserTextView.lineBreakMode = UILineBreakModeWordWrap;
		existingUserTextView.numberOfLines = 0;
		existingUserTextView.text = NSLocalizedString(@"Log in to your Blio.com account to sync your reading list.\n\nIf you are a new customer, please visit our website to sign up.",@"Existing user message on welcome view controller.");
		//existingUserTextView.text = NSLocalizedStringWithDefaultValue(nil@"EXISTING_USER_TEXT",nil,[NSBundle mainBundle],@"Log in to your Blio.com account to sync your reading //list.\n\n If you are a new customer, please visit our website to sign up.",@"Existing user message on welcome view controller.");
		[self addSubview:existingUserTextView];
		[existingUserTextView release];
        
		existingUserButton = [UIButton lightButton];
		[existingUserButton setTitle:NSLocalizedString(@"Log in",@"\"Log in\" button title") forState:UIControlStateNormal];
		[self addSubview:existingUserButton];
		[existingUserButton setAccessibilityHint:NSLocalizedString(@"Reveals the Login screen.", @"Accessibility hint for \"Login\" welcome screen button.")];

        
		firstTimeUserTitleView = [[UILabel alloc] initWithFrame:CGRectZero];
		firstTimeUserTitleView.lineBreakMode = UILineBreakModeWordWrap;
		firstTimeUserTitleView.numberOfLines = 0;
		firstTimeUserTitleView.text = NSLocalizedString(@"Explore",@"\"Explore\" first time user title for welcome view controller.");
		[self addSubview:firstTimeUserTitleView];
		[firstTimeUserTitleView release];
		[firstTimeUserTitleView setAccessibilityHint:NSLocalizedString(@"Section header for first time Blio users.", @"Accessibility hint for \"Explore\" section header on welcome screen.")];

		firstTimeUserTextView = [[UILabel alloc] initWithFrame:CGRectZero];
		firstTimeUserTextView.lineBreakMode = UILineBreakModeWordWrap;
		firstTimeUserTextView.numberOfLines = 0;
		firstTimeUserTextView.text = NSLocalizedString(@"We invite you to try the sample books in your library.  You can also import free titles via iTunes.",@"First time user message on welcome view controller.");
		//firstTimeUserTextView.text = NSLocalizedStringWithDefaultValue(@"FIRST_TIME_USER_TEXT",nil,[NSBundle mainBundle],@"We invite you to explore the sample books in your library, or import //free titles.",@"First time user message on welcome view controller.");
		[self addSubview:firstTimeUserTextView];
		[firstTimeUserTextView release];
		
		firstTimeUserButton = [UIButton lightButton];
		[firstTimeUserButton setTitle:NSLocalizedString(@"Continue to Library",@"\"Continue to Library\" button title") forState:UIControlStateNormal];
		[self addSubview:firstTimeUserButton];
		[firstTimeUserButton setAccessibilityHint:NSLocalizedString(@"Reveals the Continue to Library screen.", @"Accessibility hint for \"Continue to Library\" welcome screen button.")];
    }
    return self;
}
-(BOOL)isAccessibilityElement {
	return NO;	
}
- (NSInteger)accessibilityElementCount {
	return [self.subviews count];
}
- (id)accessibilityElementAtIndex:(NSInteger)index {    
    return [self.subviews objectAtIndex:index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
    return [self.subviews indexOfObject:element];
}

-(void)layoutSubviews {
    
     
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		contentMargin = 40;
		firstTimeUserTitleView.text = [firstTimeUserTitleView.text capitalizedString];
		existingUserTitleView.text = [existingUserTitleView.text capitalizedString];
		CGSize titleViewSize;
		CGSize textViewSize;
		CGFloat buttonY = 0;
		logoView.frame = CGRectMake(138, contentMargin/2, 100, 100);
		welcomeTitleView.frame = CGRectMake(260, contentMargin/2, 160, 100);
		welcomeTextView.font = [UIFont systemFontOfSize:20.0f];
		welcomeTextView.frame = CGRectMake(contentMargin, CGRectGetMaxY(logoView.frame) + contentMargin/2, self.frame.size.width - contentMargin*2, 115);
		titleViewSize = [firstTimeUserTitleView.text sizeWithFont:[UIFont boldSystemFontOfSize:18.0f] constrainedToSize:CGSizeMake((self.frame.size.width - contentMargin*3)/2,60) lineBreakMode:UILineBreakModeWordWrap];
        existingUserTitleView.font = [UIFont boldSystemFontOfSize:18.0f];
		existingUserTitleView.frame = CGRectMake(contentMargin, 290, (self.frame.size.width - contentMargin*3)/2, titleViewSize.height);
		textViewSize = [existingUserTextView.text sizeWithFont:[UIFont systemFontOfSize:16.0f] constrainedToSize:CGSizeMake((self.frame.size.width - contentMargin*3)/2,200) lineBreakMode:UILineBreakModeWordWrap];
		existingUserTextView.font = [UIFont systemFontOfSize:16.0f];
		existingUserTextView.frame = CGRectMake(contentMargin, CGRectGetMaxY(existingUserTitleView.frame), (self.frame.size.width - contentMargin*3)/2, textViewSize.height);
		if (CGRectGetMaxY(existingUserTextView.frame) > buttonY) buttonY = CGRectGetMaxY(existingUserTextView.frame);
	
		titleViewSize = [firstTimeUserTitleView.text sizeWithFont:[UIFont boldSystemFontOfSize:18.0f] constrainedToSize:CGSizeMake((self.frame.size.width - contentMargin*3)/2,60) lineBreakMode:UILineBreakModeWordWrap];
		firstTimeUserTitleView.font = [UIFont boldSystemFontOfSize:18.0f];
		firstTimeUserTitleView.frame = CGRectMake((self.frame.size.width+contentMargin)/2, 290, (self.frame.size.width - contentMargin*3)/2, titleViewSize.height);
		textViewSize = [firstTimeUserTextView.text sizeWithFont:[UIFont systemFontOfSize:16.0f] constrainedToSize:CGSizeMake((self.frame.size.width - contentMargin*3)/2,200) lineBreakMode:UILineBreakModeWordWrap];
		firstTimeUserTextView.font = [UIFont systemFontOfSize:16.0f];
		firstTimeUserTextView.frame = CGRectMake((self.frame.size.width+contentMargin)/2, CGRectGetMaxY(firstTimeUserTitleView.frame), (self.frame.size.width - contentMargin*3)/2, textViewSize.height);
		if (CGRectGetMaxY(firstTimeUserTextView.frame) > buttonY) buttonY = CGRectGetMaxY(firstTimeUserTextView.frame);
	
	buttonY = buttonY + kTweenMargin;
	
	existingUserButton	.frame = CGRectMake(contentMargin,buttonY,(self.frame.size.width - contentMargin*3)/2,kStdButtonHeight);
	firstTimeUserButton.frame = CGRectMake((self.frame.size.width+contentMargin)/2,buttonY,(self.frame.size.width - contentMargin*3)/2,kStdButtonHeight);
	}
	else {
		firstTimeUserTitleView.textColor = [UIColor colorWithRed:43.0f/255.0f green:196.0f/255.0f blue:230.0f/255.0f alpha:1];
		existingUserTitleView.textColor = [UIColor colorWithRed:43.0f/255.0f green:196.0f/255.0f blue:230.0f/255.0f alpha:1];

		UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation]; 
        
		if(UIInterfaceOrientationIsLandscape(orientation)) {
			contentMargin = 10;
			CGSize titleViewSize;
			CGSize textViewSize;
			CGFloat buttonY = 0;

			titleViewSize = [existingUserTitleView.text sizeWithFont:[UIFont systemFontOfSize:30.0f] constrainedToSize:CGSizeMake((self.frame.size.width - contentMargin*3)/2,150) lineBreakMode:UILineBreakModeWordWrap];
			existingUserTitleView.font = [UIFont systemFontOfSize:30.0f];
			existingUserTitleView.frame = CGRectMake(contentMargin, contentMargin, (self.frame.size.width - contentMargin*3)/2, titleViewSize.height);
			textViewSize = [existingUserTextView.text sizeWithFont:[UIFont systemFontOfSize:16.0f] constrainedToSize:CGSizeMake((self.frame.size.width - contentMargin*3)/2,200) lineBreakMode:UILineBreakModeWordWrap];
			existingUserTextView.font = [UIFont systemFontOfSize:16.0f];
			existingUserTextView.frame = CGRectMake(contentMargin, CGRectGetMaxY(existingUserTitleView.frame), (self.frame.size.width - contentMargin*3)/2, textViewSize.height);
			if (CGRectGetMaxY(existingUserTextView.frame) > buttonY) buttonY = CGRectGetMaxY(existingUserTextView.frame);
			
			
			firstTimeUserTitleView.numberOfLines = 0;
			firstTimeUserTitleView.adjustsFontSizeToFitWidth = NO;
			titleViewSize = [firstTimeUserTitleView.text sizeWithFont:[UIFont systemFontOfSize:30.0f] constrainedToSize:CGSizeMake((self.frame.size.width - contentMargin*3)/2,150) lineBreakMode:UILineBreakModeWordWrap];
			firstTimeUserTitleView.font = [UIFont systemFontOfSize:30.0f];
			firstTimeUserTitleView.frame = CGRectMake((self.frame.size.width+contentMargin)/2, contentMargin, (self.frame.size.width - contentMargin*3)/2, titleViewSize.height);
			textViewSize = [firstTimeUserTextView.text sizeWithFont:[UIFont systemFontOfSize:16.0f] constrainedToSize:CGSizeMake((self.frame.size.width - contentMargin*3)/2,200) lineBreakMode:UILineBreakModeWordWrap];
			firstTimeUserTextView.font = [UIFont systemFontOfSize:16.0f];
			firstTimeUserTextView.frame = CGRectMake((self.frame.size.width+contentMargin)/2, CGRectGetMaxY(firstTimeUserTitleView.frame), (self.frame.size.width - contentMargin*3)/2, textViewSize.height);
			if (CGRectGetMaxY(firstTimeUserTextView.frame) > buttonY) buttonY = CGRectGetMaxY(firstTimeUserTextView.frame);
			
			buttonY = buttonY + kTweenMargin;
			
			existingUserButton.frame = CGRectMake(contentMargin,buttonY,(self.frame.size.width - contentMargin*3)/2,kStdButtonHeight);
			firstTimeUserButton.frame = CGRectMake((self.frame.size.width+contentMargin)/2,buttonY,(self.frame.size.width - contentMargin*3)/2,kStdButtonHeight);		
		}
		else {
			contentMargin = 20;
			CGSize titleViewSize;
			CGSize textViewSize;
			CGFloat buttonTextWidth;

			titleViewSize = [existingUserTitleView.text sizeWithFont:[UIFont systemFontOfSize:24.0f] constrainedToSize:CGSizeMake((self.frame.size.width - contentMargin*2),75) lineBreakMode:UILineBreakModeWordWrap];
			existingUserTitleView.font = [UIFont systemFontOfSize:24.0f];
			existingUserTitleView.frame = CGRectMake(contentMargin, contentMargin, (self.frame.size.width - contentMargin*2), titleViewSize.height);
			textViewSize = [existingUserTextView.text sizeWithFont:[UIFont systemFontOfSize:16.0f] constrainedToSize:CGSizeMake((self.frame.size.width - contentMargin*2),200) lineBreakMode:UILineBreakModeWordWrap];
			existingUserTextView.font = [UIFont systemFontOfSize:16.0f];
			existingUserTextView.frame = CGRectMake(contentMargin, CGRectGetMaxY(existingUserTitleView.frame), (self.frame.size.width - contentMargin*2), textViewSize.height);
			buttonTextWidth = [[existingUserButton titleForState:UIControlStateNormal] sizeWithFont:existingUserButton.titleLabel.font constrainedToSize:CGSizeMake((self.frame.size.width - contentMargin*2),kStdButtonHeight) lineBreakMode:UILineBreakModeTailTruncation].width;
			existingUserButton.frame = CGRectMake((self.frame.size.width - (buttonTextWidth+100))/2,CGRectGetMaxY(existingUserTextView.frame) + kTweenMargin,buttonTextWidth+100,kStdButtonHeight);

			firstTimeUserTitleView.numberOfLines = 1;
			firstTimeUserTitleView.adjustsFontSizeToFitWidth = YES;			
			titleViewSize = [firstTimeUserTitleView.text sizeWithFont:[UIFont systemFontOfSize:24.0f] constrainedToSize:CGSizeMake((self.frame.size.width - contentMargin*2),24) lineBreakMode:UILineBreakModeTailTruncation];
			firstTimeUserTitleView.font = [UIFont systemFontOfSize:24.0f];
			firstTimeUserTitleView.frame = CGRectMake(contentMargin,CGRectGetMaxY(/*firstTimeUserButton*/existingUserButton.frame) + contentMargin, (self.frame.size.width - contentMargin*2), titleViewSize.height);
			textViewSize = [firstTimeUserTextView.text sizeWithFont:[UIFont systemFontOfSize:16.0f] constrainedToSize:CGSizeMake((self.frame.size.width - contentMargin*2),200) lineBreakMode:UILineBreakModeWordWrap];
			firstTimeUserTextView.font = [UIFont systemFontOfSize:16.0f];
			firstTimeUserTextView.frame = CGRectMake(contentMargin, CGRectGetMaxY(firstTimeUserTitleView.frame), (self.frame.size.width - contentMargin*2), textViewSize.height);						
			buttonTextWidth = [[firstTimeUserButton titleForState:UIControlStateNormal] sizeWithFont:firstTimeUserButton.titleLabel.font constrainedToSize:CGSizeMake((self.frame.size.width - contentMargin*2),kStdButtonHeight) lineBreakMode:UILineBreakModeTailTruncation].width;
			firstTimeUserButton.frame = CGRectMake((self.frame.size.width - (buttonTextWidth+100))/2,CGRectGetMaxY(firstTimeUserTextView.frame) + kTweenMargin,buttonTextWidth+100,kStdButtonHeight);
		}
	}
}
@end

@implementation BlioWelcomeViewController

@synthesize welcomeView,sourceID;

- (id)initWithSourceID:(BlioBookSourceID)aSourceID {
    self = [super init];
    if (self) {
		self.sourceID = aSourceID;
		self.title = NSLocalizedString(@"Welcome to Blio",@"\"Welcome to Blio\" view controller title");
    }
    return self;
}



// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	welcomeView = [[BlioWelcomeView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	welcomeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	welcomeView.autoresizesSubviews = YES;
	self.view = welcomeView;
	[welcomeView release];
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
/*
	UIBarButtonItem * continueBarButton = [[UIBarButtonItem alloc] 
											   initWithTitle:NSLocalizedString(@"Continue",@"\"Continue\" bar button") 
											   style:UIBarButtonItemStyleDone 
											   target:self
											   action:@selector(dismissSelf:)
												];
	self.navigationItem.rightBarButtonItem = continueBarButton;
	[continueBarButton release];
	[continueBarButton setAccessibilityHint:NSLocalizedString(@"Dismisses welcome screen to reveal the book library.", @"Accessibility hint for \"Continue\" bar button in the welcome screen.")];
*/
	[self.welcomeView.firstTimeUserButton addTarget:self action:@selector(firstTimeUserButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.welcomeView.existingUserButton addTarget:self action:@selector(existingUserButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
}



// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
	if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown && UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) return NO;
	return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	welcomeView = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

- (void) dismissSelf: (id) sender {
	[[BlioStoreManager sharedInstance] loginFinishedForSourceID:sourceID];
//	[self dismissModalViewControllerAnimated:YES];
	[[BlioStoreManager sharedInstance] dismissLoginView];
}
-(void)firstTimeUserButtonPressed:(id)sender {
	[[BlioStoreManager sharedInstance] loginFinishedForSourceID:sourceID];
	[[BlioStoreManager sharedInstance] dismissLoginView];
/*
	BlioCreateAccountViewController * createAccountViewController = [[[BlioCreateAccountViewController alloc] initWithSourceID:sourceID] autorelease];
	[self.navigationController pushViewController:createAccountViewController animated:YES];
 */
}
-(void)existingUserButtonPressed:(id)sender {
	BlioLoginViewController * loginViewController = [[[BlioLoginViewController alloc] initWithSourceID:sourceID] autorelease];
	[self.navigationController pushViewController:loginViewController animated:YES];
}
- (void)receivedLoginResult:(BlioLoginResult)loginResult {
	if ([self.navigationController.topViewController respondsToSelector:@selector(receivedLoginResult:)]) {
		[(id)self.navigationController.topViewController receivedLoginResult:loginResult];
	}
}
@end
