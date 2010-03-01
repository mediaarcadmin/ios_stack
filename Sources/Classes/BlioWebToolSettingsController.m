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
		self.title = @"Web Tools";
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
	NSArray *segmentTextContent = [NSArray arrayWithObjects: @"Google", @"Yahoo", @"Bing", nil];
	
	// Voice control
	CGFloat yPlacement = kTopMargin;
	CGRect frame = CGRectMake(kLeftMargin, yPlacement, self.view.bounds.size.width - (kRightMargin * 2.0), kLabelHeight);
	[self.view addSubview:[BlioWebToolSettingsController labelWithFrame:frame title:@"Search"]];
	
	yPlacement += kTweenMargin + kLabelHeight;
	searchControl = [[UISegmentedControl alloc] initWithItems:segmentTextContent];
	frame = CGRectMake(	kLeftMargin,
					   yPlacement,
					   self.view.bounds.size.width - (kRightMargin * 2.0),
					   kSegmentedControlHeight);
	searchControl.frame = frame;
	[searchControl addTarget:self action:@selector(changeSearch:) forControlEvents:UIControlEventValueChanged];
	searchControl.segmentedControlStyle = UISegmentedControlStyleBar;
	// If no engine has previously been set, set to the first engine.
	[searchControl setSelectedSegmentIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastSearchEngineDefaultsKey]];
	[self.view addSubview:searchControl];
	[searchControl release];
	
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


@end