//
//  BlioAudioSettingsController.m
//  BlioApp
//
//  Created by Arnold Chien on 2/20/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import "BlioAudioSettingsController.h"
#import "BlioAppSettingsConstants.h"

@implementation BlioAudioSettingsController


- (id)init
{
	self = [super init];
	if (self)
	{
		self.title = @"Audio";
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
	NSArray *segmentTextContent = [NSArray arrayWithObjects: @"Male", @"Female", nil];
	
	// Voice control
	CGFloat yPlacement = kTopMargin;
	CGRect frame = CGRectMake(kLeftMargin, yPlacement, self.view.bounds.size.width - (kRightMargin * 2.0), kLabelHeight);
	[self.view addSubview:[BlioAudioSettingsController labelWithFrame:frame title:@"Text to Speech Voice"]];

	yPlacement += kTweenMargin + kLabelHeight;
	UISegmentedControl * segmentedControl = [[UISegmentedControl alloc] initWithItems:segmentTextContent];
	frame = CGRectMake(	kLeftMargin,
					   yPlacement,
					   self.view.bounds.size.width - (kRightMargin * 2.0),
					   kSegmentedControlHeight);
	segmentedControl.frame = frame;
	[segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.selectedSegmentIndex = 1;
	
	[self.view addSubview:segmentedControl];
	[segmentedControl release];
	
	// Speed control
	yPlacement += (kTweenMargin * 2.0) + kSegmentedControlHeight;
	frame = CGRectMake(	kLeftMargin,
					   yPlacement,
					   self.view.bounds.size.width,
					   kLabelHeight);
	[self.view addSubview:[BlioAudioSettingsController labelWithFrame:frame title:@"Text to Speech Speed"]];
	
	segmentTextContent = [NSArray arrayWithObjects: @"Slow", @"Medium", @"Fast", nil];
	segmentedControl = [[UISegmentedControl alloc] initWithItems:segmentTextContent];
	yPlacement += kTweenMargin + kLabelHeight;
	frame = CGRectMake(	kLeftMargin,
					   yPlacement,
					   self.view.bounds.size.width - (kRightMargin * 2.0),
					   kSegmentedControlHeight);
	segmentedControl.frame = frame;
	[segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;	
	segmentedControl.selectedSegmentIndex = 1;
	
	[self.view addSubview:segmentedControl];
	[segmentedControl release];
	
	// Volume control
	yPlacement += (kTweenMargin * 2.0) + kSegmentedControlHeight;
	frame = CGRectMake(	kLeftMargin,
					   yPlacement,
					   self.view.bounds.size.width,
					   kLabelHeight);
	[self.view addSubview:[BlioAudioSettingsController labelWithFrame:frame title:@"Volume"]];
	yPlacement += kTweenMargin + kLabelHeight;
	frame = CGRectMake(	kLeftMargin,
					   yPlacement,
					   self.view.bounds.size.width - (kRightMargin * 2.0),
					   kSliderHeight);

	UISlider* sliderCtl = [[UISlider alloc] initWithFrame:frame];
	[sliderCtl addTarget:self action:@selector(adjustVolume:) forControlEvents:UIControlEventValueChanged];
	
	// in case the parent view draws with a custom color or gradient, use a transparent color
	sliderCtl.backgroundColor = [UIColor clearColor];
	
	sliderCtl.minimumValue = 0.0;
	sliderCtl.maximumValue = 100.0;
	sliderCtl.continuous = YES;
	sliderCtl.value = 50.0;
	[self.view addSubview:sliderCtl];
	[sliderCtl release];
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

- (void)adjustVolume:(id)sender
{
	
	
}

- (void)segmentAction:(id)sender
{
	//NSLog(@"selected segment = %d", [sender selectedSegmentIndex]);
}

@end