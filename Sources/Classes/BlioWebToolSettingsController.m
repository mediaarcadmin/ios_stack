//
//  BlioWebToolSettingsController.m
//  BlioApp
//
//  Created by Arnold Chien on 2/28/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import "BlioWebToolSettingsController.h"
#import "BlioAppSettingsConstants.h"
//#import "BlioBookViewController.h"

@implementation BlioWebToolSettingsController


- (id)init
{
	self = [super init];
	if (self)
	{
		self.title = NSLocalizedString(@"Web Tools",@"\"Web Tools\" view controller title.");
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
	NSArray *searchOptions = [NSArray arrayWithObjects: @"Google", @"Yahoo", @"Bing", nil];
	
	// Search engine control
	CGFloat yPlacement = kTopMargin;
	CGRect frame = CGRectMake(kLeftMargin, yPlacement, self.view.bounds.size.width - (kRightMargin * 2.0), kLabelHeight);
	[self.view addSubview:[BlioWebToolSettingsController labelWithFrame:frame title:@"Search"]];
	
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
	NSArray *encyclopediaOptions = [NSArray arrayWithObjects: @"Wikipedia", @"Britannica", nil];
	yPlacement += (kTweenMargin * 2.0) + kSegmentedControlHeight;
	frame = CGRectMake(kLeftMargin, yPlacement, self.view.bounds.size.width - (kRightMargin * 2.0), kLabelHeight);
	[self.view addSubview:[BlioWebToolSettingsController labelWithFrame:frame title:@"Encyclopedia"]];
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
	contentView.backgroundColor = [UIColor groupTableViewBackgroundColor];	// use the table view background color
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ([[[[NSBundle mainBundle] infoDictionary] objectForKey:@"BlioLibraryViewDisableRotation"] boolValue])
        return NO;
    else
        return YES;
}

- (void)dealloc {
    [super dealloc];   
}


@end