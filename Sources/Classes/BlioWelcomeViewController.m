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
#import <QuartzCore/QuartzCore.h>
#import "BlioVoiceOverTextController.h"

@interface BlioWelcomeTableViewCell : UITableViewCell {
    UILabel *titleLabel;
    UILabel *descriptionTextLabel;
    id delegate;
}

@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *descriptionTextLabel;
@property (nonatomic, copy) NSString * descriptionText;
@property (nonatomic, assign) id delegate;

@end

@interface BlioWelcomeTableViewCell (private)

-(void)reframeDescriptionTextLabel;

@end

@implementation BlioWelcomeTableViewCell

@synthesize titleLabel,descriptionTextLabel,delegate;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.titleLabel = nil;
    self.descriptionTextLabel = nil;
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
        
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;

        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.selectionStyle = UITableViewCellSelectionStyleGray;
        
		self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
		self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
		self.backgroundView.autoresizesSubviews = YES;
        
        UILabel *aTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kBlioWelcomeCellMargin, 0, self.contentView.frame.size.width - kBlioWelcomeCellMargin*2,40)];
        aTitleLabel.font = [UIFont systemFontOfSize:24.0f];
        aTitleLabel.textColor = [UIColor colorWithRed:43.0f/255.0f green:196.0f/255.0f blue:230.0f/255.0f alpha:1];
        aTitleLabel.backgroundColor = [UIColor clearColor];
		aTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        [self.contentView addSubview:aTitleLabel];
        self.titleLabel = aTitleLabel;
        [aTitleLabel release];
        
        UILabel *aDescriptionTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(kBlioWelcomeCellMargin,CGRectGetMaxY(titleLabel.frame) - 5,self.contentView.frame.size.width - kBlioWelcomeCellMargin*2,200)];
        aDescriptionTextLabel.font = [UIFont systemFontOfSize:15.0f];
        aDescriptionTextLabel.numberOfLines = 0;
        aDescriptionTextLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
        aDescriptionTextLabel.backgroundColor = [UIColor clearColor];
		aDescriptionTextLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        [self.contentView addSubview:aDescriptionTextLabel];
        self.descriptionTextLabel = aDescriptionTextLabel;
        [aDescriptionTextLabel release];
        
        self.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.95f];
        [[self layer] setCornerRadius:10];
        [self setClipsToBounds:YES];
        [[self layer] setBorderColor:[[UIColor colorWithWhite:0.6f alpha:1] CGColor]];
        [[self layer] setBorderWidth:1];

	}
    return self;
}
-(void)prepareForReuse {
	[super prepareForReuse];
    self.selected = NO;
}
-(void)setDescriptionText:(NSString*)aDescriptionText {
    self.descriptionTextLabel.text = aDescriptionText;
    [self reframeDescriptionTextLabel];
}
-(NSString*)descriptionText {
    return self.descriptionTextLabel.text;
}
-(void)reframeDescriptionTextLabel {
    CGSize maximumSize = CGSizeMake(self.contentView.frame.size.width - kBlioWelcomeCellMargin*2,200);
    CGSize stringSize = [self.descriptionTextLabel.text sizeWithFont:self.descriptionTextLabel.font
                               constrainedToSize:maximumSize 
                                   lineBreakMode:self.descriptionTextLabel.lineBreakMode];
    self.descriptionTextLabel.frame = CGRectMake(kBlioWelcomeCellMargin,CGRectGetMaxY(titleLabel.frame) - 5,self.contentView.frame.size.width - kBlioWelcomeCellMargin*2,stringSize.height);

}
-(void)layoutSubviews {
    [super layoutSubviews];
    [self reframeDescriptionTextLabel];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesEnded:touches withEvent:event];
    if ([delegate respondsToSelector:@selector(onCellPressed:)]){
        [delegate performSelector:@selector(onCellPressed:) withObject:self];
    }
}
- (BOOL)isAccessibilityElement {
    return YES;
}

@end

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
		existingUserTextView.text = NSLocalizedString(@"Log in to your Blio.com account to sync your reading list. If you are a new customer, please visit our website to sign up.",@"Existing user message on welcome view controller.");
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
		[firstTimeUserButton setAccessibilityHint:NSLocalizedString(@"Reveals the Book Library screen.", @"Accessibility hint for \"Continue to Library\" welcome screen button.")];
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

@synthesize welcomeTitleView, welcomeTextView, logoView, cellContainerView, sourceID, cell1, cell2, cell3;

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
//	welcomeView = [[BlioWelcomeView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//	welcomeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//	welcomeView.autoresizesSubviews = YES;
//	self.view = welcomeView;
//	[welcomeView release];
    [super loadView];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.autoresizesSubviews = YES;
    self.view.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1];
    
    self.cellContainerView = [[[UIView alloc] initWithFrame:self.view.bounds] autorelease];
    self.cellContainerView.autoresizesSubviews = YES;
    self.cellContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.cellContainerView.backgroundColor = [UIColor clearColor];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGFloat contentMargin = 40;
        
        self.cellContainerView.frame = CGRectMake(contentMargin - kBlioWelcomeCellMargin, self.view.bounds.size.height * 0.45f, self.view.bounds.size.width - contentMargin*2 + kBlioWelcomeCellMargin*2, self.view.bounds.size.height * 0.55f - contentMargin);
        self.view.backgroundColor = [UIColor whiteColor];
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
//        logoView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

        UIGraphicsEndImageContext();
        
        [self.view addSubview:logoView];
        [logoView release];
        
        welcomeTitleView = [[BlioWelcomeTitleView alloc] initWithFrame:CGRectZero];
//        welcomeTitleView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self.view addSubview:welcomeTitleView];
        [welcomeTitleView release];
        
        welcomeTextView = [[UILabel alloc] initWithFrame:CGRectZero];
        welcomeTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        welcomeTextView.lineBreakMode = UILineBreakModeWordWrap;
        welcomeTextView.numberOfLines = 0;
        welcomeTextView.text = NSLocalizedStringWithDefaultValue(@"WELCOME_TEXT",nil,[NSBundle mainBundle],@"With Blio, books are more than just words: there's style, presentation, and a world of color. Now you can read books with the same layout, fonts, and full-color images that you enjoy in the print version of your favorite titles.",@"Welcome message on welcome view controller.");
        [self.view addSubview:welcomeTextView];
        [welcomeTextView release];
        
        logoView.frame = CGRectMake(138, contentMargin/2, 100, 100);
        welcomeTitleView.frame = CGRectMake(260, contentMargin/2, 160, 100);
		welcomeTextView.font = [UIFont systemFontOfSize:20.0f];
		welcomeTextView.frame = CGRectMake(contentMargin, CGRectGetMaxY(logoView.frame) + contentMargin/2, self.view.frame.size.width - contentMargin*2, 115);

    }    
    
    [self.view addSubview:self.cellContainerView];
    
    self.cell1 = [[[BlioWelcomeTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"] autorelease];
    cell1.titleLabel.text = NSLocalizedString(@"Log In",@"\"Log In\" existing user title for welcome view controller.");
    cell1.descriptionText = NSLocalizedString(@"Log in to your Blio.com account to sync your reading list. If you are a new customer, please visit our website to sign up.",@"Existing user message on welcome view controller.");
    cell1.frame = CGRectMake(kBlioWelcomeCellMargin, kBlioWelcomeCellMargin, self.cellContainerView.frame.size.width - (kBlioWelcomeCellMargin*2), self.cellContainerView.frame.size.height/3.0f);
    cell1.delegate = self;
    [cell1 setAccessibilityLabel:[NSString stringWithFormat:@"%@. %@",cell1.titleLabel.text,cell1.descriptionText]];
    [cell1 setAccessibilityHint:NSLocalizedString(@"Reveals the Login screen.", @"Accessibility hint for \"Login\" welcome screen button.")];
    [self.cellContainerView addSubview:cell1];
    [cell1 setAccessibilityTraits:UIAccessibilityTraitButton];


    self.cell2 = [[[BlioWelcomeTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"] autorelease];
    cell2.titleLabel.text = NSLocalizedString(@"Explore",@"\"Explore\" first time user title for welcome view controller.");
    cell2.descriptionText = NSLocalizedString(@"We invite you to try the sample books in your library.  You can also import free titles via iTunes.",@"First time user message on welcome view controller.");
    cell2.frame = CGRectMake(kBlioWelcomeCellMargin, kBlioWelcomeCellMargin, self.cellContainerView.frame.size.width - (kBlioWelcomeCellMargin*2), self.cellContainerView.frame.size.height/3.0f);
    [self.cellContainerView addSubview:cell2];
    cell2.delegate = self;
    [cell2 setAccessibilityLabel:[NSString stringWithFormat:@"%@. %@",cell2.titleLabel.text,cell2.descriptionText]];
    [cell2 setAccessibilityHint:NSLocalizedString(@"Reveals the Book Library screen.", @"Accessibility hint for \"Explore\" welcome screen button.")];
    [cell2 setAccessibilityTraits:UIAccessibilityTraitButton];


    self.cell3 = [[[BlioWelcomeTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"] autorelease];
    cell3.titleLabel.text = NSLocalizedString(@"VoiceOver Quick Start",@"\"VoiceOver Quick Start\" section header title for welcome view controller.");
    cell3.descriptionText = NSLocalizedString(@"Arnie, you can change the text here. Quid est nomen tibi Romanum?",@"VoiceOver Quick Start message on welcome view controller.");
    cell3.frame = CGRectMake(kBlioWelcomeCellMargin, kBlioWelcomeCellMargin, self.cellContainerView.frame.size.width - (kBlioWelcomeCellMargin*2), self.cellContainerView.frame.size.height/3.0f);
    [self.cellContainerView addSubview:cell3];
    cell3.delegate = self;
    [cell3 setAccessibilityLabel:[NSString stringWithFormat:@"%@. %@",cell3.titleLabel.text,cell3.descriptionText]];
    [cell3 setAccessibilityHint:NSLocalizedString(@"Reveals the VoiceOver Quick Start screen.", @"Accessibility hint for \"VoiceOver QuickStart\" welcome screen button.")];
    [cell3 setAccessibilityTraits:UIAccessibilityTraitButton];

}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

    
//	[self.welcomeView.firstTimeUserButton addTarget:self action:@selector(firstTimeUserButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
//	[self.welcomeView.existingUserButton addTarget:self action:@selector(existingUserButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
}

-(void)viewWillAppear:(BOOL)animated {
    NSInteger cellHeight = (self.cellContainerView.frame.size.height - (kBlioWelcomeCellMargin*4))/3;
    cell1.frame = CGRectMake(kBlioWelcomeCellMargin, kBlioWelcomeCellMargin, self.cellContainerView.frame.size.width - (kBlioWelcomeCellMargin*2), cellHeight);
    cell2.frame = CGRectMake(kBlioWelcomeCellMargin, CGRectGetMaxY(cell1.frame) + kBlioWelcomeCellMargin, self.cellContainerView.frame.size.width - (kBlioWelcomeCellMargin*2), cellHeight);
    cell3.frame = CGRectMake(kBlioWelcomeCellMargin, CGRectGetMaxY(cell2.frame) + kBlioWelcomeCellMargin, self.cellContainerView.frame.size.width - (kBlioWelcomeCellMargin*2), cellHeight);

    [cell1 prepareForReuse];
    [cell2 prepareForReuse];
    [cell3 prepareForReuse];
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
    self.logoView = nil;
    self.welcomeTextView = nil;
    self.welcomeTitleView = nil;
    self.cellContainerView = nil;
    self.cell1 = nil;
    self.cell2 = nil;
    self.cell3 = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    self.logoView = nil;
    self.welcomeTextView = nil;
    self.welcomeTitleView = nil;
    self.cellContainerView = nil;
    self.cell1 = nil;
    self.cell2 = nil;
    self.cell3 = nil;
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
-(void)onCellPressed:(id)cell {
    if (cell == cell1) {
        cell1.selected = YES;
        [self existingUserButtonPressed:cell];
    }
    else if (cell == cell2) {
        cell2.selected = YES;
        [self firstTimeUserButtonPressed:cell];
    }
    else if (cell == cell3) {
        cell3.selected = YES;
        BlioVoiceOverTextController * viewController = [[[BlioVoiceOverTextController alloc] init] autorelease];

        [self.navigationController pushViewController:viewController animated:YES];
    }
}
@end
