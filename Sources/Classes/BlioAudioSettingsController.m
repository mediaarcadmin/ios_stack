//
//  BlioAudioSettingsController.m
//  BlioApp
//
//  Created by Arnold Chien on 2/20/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import "BlioAudioSettingsController.h"
#import "BlioAppSettingsConstants.h"
#import "BlioBookViewController.h"

@implementation BlioAudioSettingsController


- (id)init
{
	self = [super init];
	if (self)
	{
		self.title = @"Text to Speech";
	}
	return self;
}

- (void)viewWillDisappear:(BOOL)animated {
	AcapelaTTS** tts = [BlioBookViewController getTTSEngine];
	if ( *tts != nil && [*tts isSpeaking] )
		[*tts stopSpeaking]; 
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
	NSArray *segmentTextContent = [NSArray arrayWithObjects: @"Laura", @"Ryan", nil];
	
	// Voice control
	CGFloat yPlacement = kTopMargin;
	CGRect frame = CGRectMake(kLeftMargin, yPlacement, self.view.bounds.size.width - (kRightMargin * 2.0), kLabelHeight);
	[self.view addSubview:[BlioAudioSettingsController labelWithFrame:frame title:@"Voice"]];

	yPlacement += kTweenMargin + kLabelHeight;
	voiceControl = [[UISegmentedControl alloc] initWithItems:segmentTextContent];
	frame = CGRectMake(	kLeftMargin,
					   yPlacement,
					   self.view.bounds.size.width - (kRightMargin * 2.0),
					   kSegmentedControlHeight);
	voiceControl.frame = frame;
	[voiceControl addTarget:self action:@selector(changeVoice:) forControlEvents:UIControlEventValueChanged];
	voiceControl.segmentedControlStyle = UISegmentedControlStyleBar;
	// If no voice has previously been set, set to the first voice (female).
	[voiceControl setSelectedSegmentIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastVoiceDefaultsKey]];
	[self.view addSubview:voiceControl];
	[voiceControl release];
	
	// Speed control
	yPlacement += (kTweenMargin * 2.0) + kSegmentedControlHeight;
	frame = CGRectMake(	kLeftMargin,
					   yPlacement,
					   self.view.bounds.size.width,
					   kLabelHeight);
	[self.view addSubview:[BlioAudioSettingsController labelWithFrame:frame title:@"Speed"]];
	yPlacement += kTweenMargin + kLabelHeight;
	frame = CGRectMake(	kLeftMargin,
					   yPlacement,
					   self.view.bounds.size.width - (kRightMargin * 2.0),
					   kSliderHeight);
	
	speedControl = [[UISlider alloc] initWithFrame:frame];
	[speedControl addTarget:self action:@selector(changeSpeed:) forControlEvents:UIControlEventValueChanged];
	// in case the parent view draws with a custom color or gradient, use a transparent color
	speedControl.backgroundColor = [UIColor clearColor];
	speedControl.minimumValue = 80.0;
	speedControl.maximumValue = 360.0;
	speedControl.continuous = NO;
	if ( [[NSUserDefaults standardUserDefaults] floatForKey:kBlioLastSpeedDefaultsKey] == 0 )
		// Preference has not been set.  Set to default.
		[[NSUserDefaults standardUserDefaults] setFloat:180.0 forKey:kBlioLastSpeedDefaultsKey];
	speedControl.value = [[NSUserDefaults standardUserDefaults] floatForKey:kBlioLastSpeedDefaultsKey];
	[self.view addSubview:speedControl];
	[speedControl release];
	
	// Volume control
	yPlacement += (kTweenMargin * 2.0) + kSliderHeight + kLabelHeight;
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

	volumeControl = [[UISlider alloc] initWithFrame:frame];
	[volumeControl addTarget:self action:@selector(changeVolume:) forControlEvents:UIControlEventValueChanged];
	volumeControl.backgroundColor = [UIColor clearColor];
	volumeControl.minimumValue = 0.1; 
	volumeControl.maximumValue = 100.0;
	volumeControl.continuous = NO;
	if ( [[NSUserDefaults standardUserDefaults] floatForKey:kBlioLastVolumeDefaultsKey] == 0 )
		// Preference has not been set.  Set to default.
		[[NSUserDefaults standardUserDefaults] setFloat:50.0 forKey:kBlioLastVolumeDefaultsKey];
	volumeControl.value = [[NSUserDefaults standardUserDefaults] floatForKey:kBlioLastVolumeDefaultsKey];
	[self.view addSubview:volumeControl];
	[volumeControl release];
	
	// Play sample button.
	yPlacement += (kTweenMargin * 2.0) + kSliderHeight + kLabelHeight;
	playButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
	playButton.frame = CGRectMake((self.view.bounds.size.width - kStdButtonWidth)/2, yPlacement, kStdButtonWidth, kStdButtonHeight);
	[playButton setTitle:@"Play sample" forState:UIControlStateNormal];
	playButton.backgroundColor = [UIColor clearColor];
	[playButton addTarget:self action:@selector(playSample:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:playButton];
	[playButton release];
	
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


- (void)changeVoice:(id)sender
{
	UISegmentedControl* ctl = (UISegmentedControl*)sender;
	if ( ctl == voiceControl )
		[[NSUserDefaults standardUserDefaults] setInteger:(AcapelaVoice)([sender selectedSegmentIndex]) forKey:kBlioLastVoiceDefaultsKey];
}

- (void)changeSpeed:(id)sender
{
	UISlider* ctl = (UISlider*)sender;
	if ( ctl == speedControl )
		[[NSUserDefaults standardUserDefaults] setFloat:ctl.value forKey:kBlioLastSpeedDefaultsKey];
}

- (void)changeVolume:(id)sender
{
	UISlider* ctl = (UISlider*)sender;
	if ( ctl == volumeControl )
		[[NSUserDefaults standardUserDefaults] setFloat:ctl.value forKey:kBlioLastVolumeDefaultsKey];
}

- (void)playSample:(id)sender {	
	UIButton* ctl = (UIButton*)sender;
	if ( ctl == playButton ) {
		AcapelaTTS** tts = [BlioBookViewController getTTSEngine];
		if ( *tts == nil ) {
			*tts = [[AcapelaTTS alloc] init]; 
			[*tts setEngineWithPreferences:YES];
		}
		else
			[*tts setEngineWithPreferences:[*tts voiceHasChanged]];
		[*tts startSpeaking:@"It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness."]; 
	}
}

@end