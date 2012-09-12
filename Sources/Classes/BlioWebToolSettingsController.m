//
//  BlioWebToolSettingsController.m
//  BlioApp
//
//  Created by Arnold Chien on 2/28/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import "BlioWebToolSettingsController.h"
#import "BlioAppSettingsConstants.h"

@implementation BlioWebToolSettingsController


- (id)init
{
	self = [super init];
	if (self)
	{
		self.title = NSLocalizedString(@"Reference Tools",@"\"Reference Tools\" view controller title.");
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.contentSizeForViewInPopover = CGSizeMake(320, 200);
		}		
	}
	return self;
}


+ (UILabel *)labelWithFrame:(CGRect)frame title:(NSString *)title
{
    UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
    
	label.textAlignment = UITextAlignmentLeft;
    label.text = title;
    label.font = [UIFont boldSystemFontOfSize:17.0];
    label.textColor = [UIColor colorWithRed:76.0/255.0 green:86.0/255.0 blue:108.0/255.0 alpha:1.0];
    label.backgroundColor = [UIColor clearColor];
	
    return label;
}

- (void)createControls
{
	NSArray *searchOptions = [NSArray arrayWithObjects: NSLocalizedString(@"Google",@"\"Google\" search option within web tool settings"), NSLocalizedString(@"Yahoo",@"\"Yahoo\" search option within web tool settings"), NSLocalizedString(@"Bing",@"\"Bing\" search option within web tool settings"), nil];
	
	// Search engine control
	CGFloat yPlacement = kTopMargin;
	CGRect frame = CGRectMake(kLeftMargin, yPlacement, self.view.bounds.size.width - (kRightMargin * 2.0), kLabelHeight);
	[self.view addSubview:[BlioWebToolSettingsController labelWithFrame:frame title:NSLocalizedString(@"Search",@"\"Search\" label within web tool settings")]];
	
	yPlacement += kTweenMargin + kLabelHeight;
	searchControl = [[UISegmentedControl alloc] initWithItems:searchOptions];
	frame = CGRectMake(	kLeftMargin,
					   yPlacement,
					   self.view.bounds.size.width - (kRightMargin * 2.0),
					   kSegmentedControlHeight);
	searchControl.frame = frame;
	[searchControl addTarget:self action:@selector(changeSearch:) forControlEvents:UIControlEventValueChanged];
	searchControl.segmentedControlStyle = UISegmentedControlStyleBar;
    searchControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	// If no engine has previously been set, set to the first engine.
	[searchControl setSelectedSegmentIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastSearchEngineDefaultsKey]];
	[self.view addSubview:searchControl];
	[searchControl release];
	
	// Encyclopedia control
	NSArray *encyclopediaOptions = [NSArray arrayWithObjects: NSLocalizedString(@"Wikipedia",@"\"Wikipedia\" encyclopedia option within web tool settings"), NSLocalizedString(@"Britannica",@"\"Britannica\" encyclopedia option within web tool settings"), nil];
	yPlacement += (kTweenMargin * 2.0) + kSegmentedControlHeight;
	frame = CGRectMake(kLeftMargin, yPlacement, self.view.bounds.size.width - (kRightMargin * 2.0), kLabelHeight);
	[self.view addSubview:[BlioWebToolSettingsController labelWithFrame:frame title:NSLocalizedString(@"Encyclopedia",@"\"Encyclopedia\" label within web tool settings")]];
	yPlacement += kTweenMargin + kLabelHeight;
	encyclopediaControl = [[UISegmentedControl alloc] initWithItems:encyclopediaOptions];
	frame = CGRectMake(	kLeftMargin,
					   yPlacement,
					   self.view.bounds.size.width - (kRightMargin * 2.0),
					   kSegmentedControlHeight);
	encyclopediaControl.frame = frame;
	[encyclopediaControl addTarget:self action:@selector(changeEncyclopedia:) forControlEvents:UIControlEventValueChanged];
	encyclopediaControl.segmentedControlStyle = UISegmentedControlStyleBar;
    encyclopediaControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	// If no encyclopedia has previously been set, set to the first encyclopedia.
	[encyclopediaControl setSelectedSegmentIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastEncyclopediaDefaultsKey]];
	[self.view addSubview:encyclopediaControl];
	[encyclopediaControl release];
	
}

- (void)loadView
{	
	// create a gradient-based content view	
	UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		contentView.backgroundColor = [UIColor colorWithRed:224.0f/255.0f green:227.0f/255.0f blue:232.0f/255.0f alpha:1];
	}
	else contentView.backgroundColor = [UIColor groupTableViewBackgroundColor];	// use the table view background color

	contentView.autoresizesSubviews = YES;
	self.view = contentView;
	[contentView release];
	[self createControls];	
}


- (void)changeSearch:(id)sender
{
	UISegmentedControl* ctl = (UISegmentedControl*)sender;
	if ( ctl == searchControl )
		[[NSUserDefaults standardUserDefaults] setInteger:[sender selectedSegmentIndex] forKey:kBlioLastSearchEngineDefaultsKey];
}

- (void)changeEncyclopedia:(id)sender
{
	UISegmentedControl* ctl = (UISegmentedControl*)sender;
	if ( ctl == encyclopediaControl )
		[[NSUserDefaults standardUserDefaults] setInteger:[sender selectedSegmentIndex] forKey:kBlioLastEncyclopediaDefaultsKey];
}

- (void)dealloc {
    [super dealloc];   
}


@end