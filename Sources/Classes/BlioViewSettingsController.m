//
//  BlioViewSettingsController.m
//  BlioApp
//
//  Created by matt on 22/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import "BlioViewSettingsController.h"
#import <libEucalyptus/THUIImageAdditions.h>

@interface BlioViewSettingsControllerView : UIView

@end

static const CGFloat kBlioViewSettingsRowSpacing = 14;
static const CGFloat kBlioViewSettingsShadow = 100;
static const CGFloat kBlioViewSettingsXInset = 20;
static const CGFloat kBlioViewSettingsSegmentButtonHeight = 36;
static const CGFloat kBlioViewSettingsLabelWidth = 93;
static const CGFloat kBlioViewSettingsDoneButtonHeight = 44;

@implementation BlioViewSettingsController

@synthesize delegate;
@synthesize fontSizeLabel;
@synthesize pageColorLabel;
@synthesize fontSizeSegment;
@synthesize pageColorSegment;

- (void)dealloc {
  self.delegate = nil;
  self.fontSizeLabel = nil;
  self.pageColorLabel = nil;
  self.fontSizeSegment = nil;
  self.pageColorSegment = nil;
  [super dealloc];
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
  UIView *container = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
  
  CGFloat contentsHeight = kBlioViewSettingsRowSpacing*6 + kBlioViewSettingsSegmentButtonHeight*4 + kBlioViewSettingsDoneButtonHeight + kBlioViewSettingsShadow;
  
  BlioViewSettingsControllerView *settingsView = [[BlioViewSettingsControllerView alloc] initWithFrame:CGRectMake(0,CGRectGetHeight(container.frame) - contentsHeight, CGRectGetWidth(container.frame), contentsHeight)];
  [container addSubview:settingsView];
  
  settingsView.backgroundColor = [UIColor clearColor];
  
  NSArray *segmentTitles = [NSArray arrayWithObjects:
                            @"Plain Text",
                            @"Page Layout",
                            @"Speed Read",
                            nil];
  
  UISegmentedControl *aLayoutSegmentedControl = [[UISegmentedControl alloc] initWithItems:segmentTitles];
  aLayoutSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
  aLayoutSegmentedControl.frame = CGRectMake(kBlioViewSettingsXInset, kBlioViewSettingsShadow + kBlioViewSettingsRowSpacing, settingsView.bounds.size.width - 2*kBlioViewSettingsXInset, kBlioViewSettingsSegmentButtonHeight);
  aLayoutSegmentedControl.tintColor = [UIColor colorWithRed:0.282f green:0.310f blue:0.345f alpha:1.0f];
  [aLayoutSegmentedControl addTarget:self.delegate action:@selector(changePageLayout:) forControlEvents:UIControlEventValueChanged];
  [aLayoutSegmentedControl addTarget:self action:@selector(changePageLayout:) forControlEvents:UIControlEventValueChanged];
  [settingsView addSubview:aLayoutSegmentedControl];
  [aLayoutSegmentedControl release];
  
  if ([self.delegate respondsToSelector:@selector(currentPageLayout)])
    [aLayoutSegmentedControl setSelectedSegmentIndex:(NSInteger)[self.delegate performSelector:@selector(currentPageLayout)]];
  
  UILabel *aFontSizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(kBlioViewSettingsXInset, CGRectGetMaxY(aLayoutSegmentedControl.frame) + kBlioViewSettingsRowSpacing, kBlioViewSettingsLabelWidth, kBlioViewSettingsSegmentButtonHeight)];
  aFontSizeLabel.font = [UIFont boldSystemFontOfSize:14.0f];
  aFontSizeLabel.textColor = [UIColor whiteColor];
  aFontSizeLabel.backgroundColor = [UIColor clearColor];
  aFontSizeLabel.text = @"Font Size";
  [settingsView addSubview:aFontSizeLabel];
  self.fontSizeLabel = aFontSizeLabel;
  [aFontSizeLabel release];
  
  NSString *letter = @"A";
  UIFont *defaultFont = [UIFont boldSystemFontOfSize:14.0f];
  UIColor *white = [UIColor whiteColor];
    
  // Sizes and offsets for the font size buttons chosen to look 'right' visually
  // rather than being completly accurate to the book view technically.
  NSArray *fontSizeTitles = [NSArray arrayWithObjects:
                             [UIImage imageWithString:letter font:defaultFont size:CGSizeMake(20.0f, 10.0f) color:white],
                             [UIImage imageWithString:letter font:defaultFont size:CGSizeMake(20.0f, 11.0f) color:white],
                             [UIImage imageWithString:letter font:defaultFont size:CGSizeMake(20.0f, 12.0f) color:white],
                             [UIImage imageWithString:letter font:defaultFont size:CGSizeMake(20.0f, 13.0f) color:white],
                             [UIImage imageWithString:letter font:defaultFont size:CGSizeMake(20.0f, 14.0f) color:white],
                            nil];
  
  UISegmentedControl *aFontSizeSegmentedControl = [[UISegmentedControl alloc] initWithItems:fontSizeTitles];    
  aFontSizeSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
  aFontSizeSegmentedControl.frame = CGRectMake(CGRectGetMaxX(aFontSizeLabel.frame), CGRectGetMinY(aFontSizeLabel.frame), settingsView.bounds.size.width - CGRectGetMaxX(aFontSizeLabel.frame) - kBlioViewSettingsXInset, kBlioViewSettingsSegmentButtonHeight);
  aFontSizeSegmentedControl.tintColor = [UIColor colorWithRed:0.282f green:0.310f blue:0.345f alpha:1.0f];
  [aFontSizeSegmentedControl addTarget:self.delegate action:@selector(changeFontSize:) forControlEvents:UIControlEventValueChanged];
  
  [aFontSizeSegmentedControl setContentOffset:CGSizeMake(0, 2) forSegmentAtIndex:0];
  [aFontSizeSegmentedControl setContentOffset:CGSizeMake(0, 1) forSegmentAtIndex:1];
  [aFontSizeSegmentedControl setContentOffset:CGSizeMake(0, 0) forSegmentAtIndex:2];
  [aFontSizeSegmentedControl setContentOffset:CGSizeMake(0, -1) forSegmentAtIndex:3];
    
  [settingsView addSubview:aFontSizeSegmentedControl];
  self.fontSizeSegment = aFontSizeSegmentedControl;
  [aFontSizeSegmentedControl release];
  
  if ([self.delegate respondsToSelector:@selector(currentFontSize)])
    [aFontSizeSegmentedControl setSelectedSegmentIndex:(NSInteger)[self.delegate performSelector:@selector(currentFontSize)]];
  
  UILabel *aPageColorLabel = [[UILabel alloc] initWithFrame:CGRectMake(kBlioViewSettingsXInset, CGRectGetMaxY(aFontSizeSegmentedControl.frame) + kBlioViewSettingsRowSpacing, kBlioViewSettingsLabelWidth, kBlioViewSettingsSegmentButtonHeight)];
  aPageColorLabel.font = [UIFont boldSystemFontOfSize:14.0f];
  aPageColorLabel.textColor = [UIColor whiteColor];
  aPageColorLabel.backgroundColor = [UIColor clearColor];
  aPageColorLabel.text = @"Page Color";
  [settingsView addSubview:aPageColorLabel];
  self.pageColorLabel = aPageColorLabel;
  [aPageColorLabel release];
  
  NSArray *pageColorTitles = [NSArray arrayWithObjects:
                             @"White",
                             @"Neutral",
                             @"Black",
                             nil];
  
  UISegmentedControl *aPageColorSegmentedControl = [[UISegmentedControl alloc] initWithItems:pageColorTitles];
  aPageColorSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
  aPageColorSegmentedControl.frame = CGRectMake(CGRectGetMaxX(aPageColorLabel.frame), CGRectGetMinY(aPageColorLabel.frame), settingsView.bounds.size.width - CGRectGetMaxX(aPageColorLabel.frame) - kBlioViewSettingsXInset, kBlioViewSettingsSegmentButtonHeight);
  aPageColorSegmentedControl.tintColor = [UIColor colorWithRed:0.282f green:0.310f blue:0.345f alpha:1.0f];
  [aPageColorSegmentedControl addTarget:self.delegate action:@selector(changePageColor:) forControlEvents:UIControlEventValueChanged];
  [settingsView addSubview:aPageColorSegmentedControl];
  self.pageColorSegment = aPageColorSegmentedControl;
  [aPageColorSegmentedControl release];
  
  if ([self.delegate respondsToSelector:@selector(currentPageColor)])
    [aPageColorSegmentedControl setSelectedSegmentIndex:(NSInteger)[self.delegate performSelector:@selector(currentPageColor)]];
  
  NSArray *lockButtonTitles = [NSArray arrayWithObjects:
                              @"",
                              nil];
  
  UISegmentedControl *aLockButtonSegmentedControl = [[UISegmentedControl alloc] initWithItems:lockButtonTitles];
  aLockButtonSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
  aLockButtonSegmentedControl.frame = CGRectMake(kBlioViewSettingsXInset, CGRectGetMaxY(aPageColorSegmentedControl.frame) + kBlioViewSettingsRowSpacing, (CGRectGetWidth(container.frame) - 2 * kBlioViewSettingsXInset - kBlioViewSettingsRowSpacing)/2.0f, kBlioViewSettingsSegmentButtonHeight);
  aLockButtonSegmentedControl.tintColor = [UIColor colorWithRed:0.282f green:0.310f blue:0.345f alpha:1.0f];
  aLockButtonSegmentedControl.momentary = YES;
  [aLockButtonSegmentedControl addTarget:self.delegate action:@selector(changeLockRotation:) forControlEvents:UIControlEventValueChanged];
  [aLockButtonSegmentedControl addTarget:self action:@selector(changeLockRotation:) forControlEvents:UIControlEventValueChanged];  
  [settingsView addSubview:aLockButtonSegmentedControl];
  [aLockButtonSegmentedControl release];
  
  if ([self.delegate respondsToSelector:@selector(currentLockRotation)]) {
    NSInteger currentLock = (NSInteger)[self.delegate performSelector:@selector(currentLockRotation)];
    if (currentLock)
      [aLockButtonSegmentedControl setTitle:@"Unlock Rotation" forSegmentAtIndex:0];
    else
      [aLockButtonSegmentedControl setTitle:@"Lock Rotation" forSegmentAtIndex:0];
  }
  
  NSArray *tapTurnTitles = [NSArray arrayWithObjects:
                               @"",
                               nil];
  
  UISegmentedControl *aTapTurnButtonSegmentedControl = [[UISegmentedControl alloc] initWithItems:tapTurnTitles];
  aTapTurnButtonSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
  aTapTurnButtonSegmentedControl.frame = CGRectMake(CGRectGetMaxX(aLockButtonSegmentedControl.frame) + kBlioViewSettingsRowSpacing, CGRectGetMinY(aLockButtonSegmentedControl.frame), CGRectGetWidth(aLockButtonSegmentedControl.frame), kBlioViewSettingsSegmentButtonHeight);
  aTapTurnButtonSegmentedControl.tintColor = [UIColor colorWithRed:0.282f green:0.310f blue:0.345f alpha:1.0f];
  
  aTapTurnButtonSegmentedControl.momentary = YES;
  [aTapTurnButtonSegmentedControl addTarget:self.delegate action:@selector(changeTapTurn:) forControlEvents:UIControlEventValueChanged];
  [aTapTurnButtonSegmentedControl addTarget:self action:@selector(changeTapTurn:) forControlEvents:UIControlEventValueChanged];  
  [settingsView addSubview:aTapTurnButtonSegmentedControl];
  [aTapTurnButtonSegmentedControl release];
  
  if ([self.delegate respondsToSelector:@selector(currentTapTurn)]) {
    NSInteger currentTapTurn = (NSInteger)[self.delegate performSelector:@selector(currentTapTurn)];
    if (currentTapTurn)
      [aTapTurnButtonSegmentedControl setTitle:@"Enable Tap Turn" forSegmentAtIndex:0];
    else
      [aTapTurnButtonSegmentedControl setTitle:@"Disable Tap Turn" forSegmentAtIndex:0];
  }
  
  UIButton *aDoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
  aDoneButton.frame = CGRectMake(kBlioViewSettingsXInset, CGRectGetMaxY(aLockButtonSegmentedControl.frame) + kBlioViewSettingsRowSpacing, CGRectGetWidth(container.frame) - 2 * kBlioViewSettingsXInset, kBlioViewSettingsDoneButtonHeight);
  aDoneButton.showsTouchWhenHighlighted = NO;
  [aDoneButton setTitle:@"Done" forState:UIControlStateNormal];
  [aDoneButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20.0f]]; 
  [aDoneButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [aDoneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
  [aDoneButton setBackgroundImage:[UIImage imageNamed:@"done-button-up.png"] forState:UIControlStateNormal];
  [aDoneButton setBackgroundImage:[UIImage imageNamed:@"done-button-down.png"] forState:UIControlStateHighlighted];
  [aDoneButton addTarget:self.delegate action:@selector(dismissViewSettings:) forControlEvents:UIControlEventTouchUpInside];
  [settingsView addSubview:aDoneButton];
  
  [settingsView release];
  self.view = container;
  [container release];
}

- (void)changePageLayout:(id)sender {
  
  BOOL showPageAttributes = NO;
  
  if ([self.delegate respondsToSelector:@selector(shouldShowPageAttributeSettings)])
    showPageAttributes = (NSInteger)[self.delegate performSelector:@selector(shouldShowPageAttributeSettings)];

  if (showPageAttributes) {
    self.fontSizeLabel.enabled = YES;
    self.pageColorLabel.enabled = YES;
    self.fontSizeSegment.enabled = YES;
    self.pageColorSegment.enabled = YES;
    self.fontSizeSegment.alpha = 1.0f;
    self.pageColorSegment.alpha = 1.0f;
  } else {
    self.fontSizeLabel.enabled = NO;
    self.pageColorLabel.enabled = NO;
    self.fontSizeSegment.enabled = NO;
    self.pageColorSegment.enabled = NO;
    self.fontSizeSegment.alpha = 0.35f;
    self.pageColorSegment.alpha = 0.35f;
  }  
}

- (void)changeLockRotation:(id)sender {
  /*
  if ([self.delegate respondsToSelector:@selector(currentLockRotation)]) {
    NSInteger currentLock = (NSInteger)[self.delegate performSelector:@selector(currentLockRotation)];
    if (currentLock)
      [sender setTitle:@"Unlock Rotation" forSegmentAtIndex:0];
    else
      [sender setTitle:@"Lock Rotation" forSegmentAtIndex:0];
  }
   */
  if ([[sender titleForSegmentAtIndex:[sender selectedSegmentIndex]] isEqualToString:@"Unlock Rotation"])
    [sender setTitle:@"Lock Rotation" forSegmentAtIndex:0];
  else
    [sender setTitle:@"Unlock Rotation" forSegmentAtIndex:0];
}

- (void)changeTapTurn:(id)sender {
  /*
  if ([self.delegate respondsToSelector:@selector(currentTapTurn)]) {
    NSInteger currentTapTurn = (NSInteger)[self.delegate performSelector:@selector(currentTapTurn)];
    if (currentTapTurn)
      [sender setTitle:@"Tap Turn On" forSegmentAtIndex:0];
    else
      [sender setTitle:@"Tap Turn Off" forSegmentAtIndex:0];
  } 
   */
  if ([[sender titleForSegmentAtIndex:[sender selectedSegmentIndex]] isEqualToString:@"Disable Tap Turn"])
    [sender setTitle:@"Enable Tap Turn" forSegmentAtIndex:0];
  else
    [sender setTitle:@"Disable Tap Turn" forSegmentAtIndex:0];
}
/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


@end

@implementation BlioViewSettingsControllerView

- (void)drawRect:(CGRect)rect {
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  
  CGContextSaveGState(ctx);
  CGContextSetShadowWithColor(ctx, CGSizeMake(0, kBlioViewSettingsShadow*0.1f), kBlioViewSettingsShadow*0.9f, [UIColor colorWithWhite:0.0f alpha:0.3f].CGColor);
  CGContextBeginTransparencyLayer(ctx, NULL);  
  CGRect inRect = CGRectOffset(rect, 0, kBlioViewSettingsShadow);
  CGContextFillRect(ctx, CGRectInset(inRect, -kBlioViewSettingsShadow, 0));
  CGContextEndTransparencyLayer(ctx);
  CGContextRestoreGState(ctx);
  
  CGContextClearRect(ctx, inRect);
  CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:0.239f green:0.259f blue:0.302f alpha:0.95f].CGColor);
  CGContextFillRect(ctx, inRect);
  
  CGGradientRef glossGradient;
  CGColorSpaceRef rgbColorspace;
  size_t num_locations = 2;
  CGFloat locations[2] = { 0.0, 1.0 };
  CGFloat components[8] = { 1.0, 1.0, 1.0, 0.35,  // Start color
    1.0, 1.0, 1.0, 0.06 }; // End color
  
  rgbColorspace = CGColorSpaceCreateDeviceRGB();
  glossGradient = CGGradientCreateWithColorComponents(rgbColorspace, components, locations, num_locations);
  
  CGPoint topCenter = CGPointMake(CGRectGetMidX(inRect), CGRectGetMinY(inRect));
  CGPoint midCenter = CGPointMake(CGRectGetMidX(inRect), CGRectGetMinY(inRect) + 20.0f);
  CGContextDrawLinearGradient(ctx, glossGradient, topCenter, midCenter, 0);
  
  CGGradientRelease(glossGradient);
  CGColorSpaceRelease(rgbColorspace); 
  
  CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:0.0f alpha:0.4f].CGColor);
  CGContextSetLineWidth(ctx, 0.5f);
  CGContextStrokeRect(ctx, CGRectMake(inRect.origin.x, inRect.origin.y, inRect.size.width, 0.0f));
  
}

@end
