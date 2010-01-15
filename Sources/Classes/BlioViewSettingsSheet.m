//
//  BlioViewSettingsSheet.m
//  BlioApp
//
//  Created by matt on 30/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import "BlioViewSettingsSheet.h"
#import <libEucalyptus/THUIImageAdditions.h>
#import "BlioUIImageAdditions.h"

static const CGFloat kBlioViewSettingsRowSpacing = 14;
static const CGFloat kBlioViewSettingsYInset = 22;
static const CGFloat kBlioViewSettingsXInset = 20;
static const CGFloat kBlioViewSettingsSegmentButtonHeight = 36;
static const CGFloat kBlioViewSettingsLabelWidth = 93;
static const CGFloat kBlioViewSettingsDoneButtonHeight = 44;

@interface BlioViewSettingsSheet()

@property (nonatomic, retain) UIImage *tapTurnOnImage;
@property (nonatomic, retain) UIImage *tapTurnOffImage;
@property (nonatomic, retain) UIImage *lockRotationImage;
@property (nonatomic, retain) UIImage *unlockRotationImage;

@end

@implementation BlioViewSettingsSheet

@synthesize fontSizeLabel;
@synthesize pageColorLabel;
@synthesize pageLayoutSegment;
@synthesize fontSizeSegment;
@synthesize pageColorSegment;
@synthesize lockButtonSegment;
@synthesize tapTurnButtonSegment;
@synthesize doneButton;
@synthesize tapTurnOnImage, tapTurnOffImage, lockRotationImage, unlockRotationImage;

- (void)dealloc {
    self.fontSizeLabel = nil;
    self.pageColorLabel = nil;
    self.pageLayoutSegment = nil;
    self.fontSizeSegment = nil;
    self.pageColorSegment = nil;
    self.lockButtonSegment = nil;
    self.tapTurnButtonSegment = nil;
    self.doneButton = nil;
    self.tapTurnOnImage = nil;
    self.tapTurnOffImage = nil;
    self.lockRotationImage = nil;
    self.unlockRotationImage = nil;
    [super dealloc];
}

- (void)displayPageAttributes {
    
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

- (id)initWithDelegate:(id)newDelegate {
    
    self = [super initWithTitle:nil delegate:newDelegate cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
	if (self) {
        UIFont *defaultFont = [UIFont boldSystemFontOfSize:12.0f];
        UIColor *white = [UIColor whiteColor];
        UIEdgeInsets inset = UIEdgeInsetsMake(0, 2, 2, 2);
        UIImage *plainImage = [UIImage imageWithIcon:[UIImage imageNamed:@"icon-page.png"] string:@"Flowed" font:defaultFont color:white textInset:inset];
        UIImage *layoutImage = [UIImage imageWithIcon:[UIImage imageNamed:@"icon-layout.png"] string:@"Fixed" font:defaultFont color:white textInset:inset];
        UIImage *speedImage = [UIImage imageWithIcon:[UIImage imageNamed:@"icon-speedread.png"] string:@"SpeedRead" font:defaultFont color:white textInset:inset];
        
        NSArray *segmentImages = [NSArray arrayWithObjects:
                                  plainImage,
                                  layoutImage,
                                  speedImage,
                                  nil];
        
        UISegmentedControl *aLayoutSegmentedControl = [[UISegmentedControl alloc] initWithItems:segmentImages];
        aLayoutSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        aLayoutSegmentedControl.tintColor = [UIColor darkGrayColor];
        [self addSubview:aLayoutSegmentedControl];
        self.pageLayoutSegment = aLayoutSegmentedControl;
        [aLayoutSegmentedControl release];
        
        if ([newDelegate respondsToSelector:@selector(currentPageLayout)])
            [aLayoutSegmentedControl setSelectedSegmentIndex:(NSInteger)[newDelegate performSelector:@selector(currentPageLayout)]];
        
        [self.pageLayoutSegment addTarget:self action:@selector(changePageLayout:) forControlEvents:UIControlEventValueChanged];

        UILabel *aFontSizeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        aFontSizeLabel.font = [UIFont boldSystemFontOfSize:14.0f];
        aFontSizeLabel.textColor = [UIColor whiteColor];
        aFontSizeLabel.backgroundColor = [UIColor clearColor];
        aFontSizeLabel.text = @"Font Size";
        [self addSubview:aFontSizeLabel];
        self.fontSizeLabel = aFontSizeLabel;
        [aFontSizeLabel release];
        
        NSString *letter = @"A";
        
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
        aFontSizeSegmentedControl.tintColor = [UIColor darkGrayColor];
        
        [aFontSizeSegmentedControl setContentOffset:CGSizeMake(0, 2) forSegmentAtIndex:0];
        [aFontSizeSegmentedControl setContentOffset:CGSizeMake(0, 1) forSegmentAtIndex:1];
        [aFontSizeSegmentedControl setContentOffset:CGSizeMake(0, 0) forSegmentAtIndex:2];
        [aFontSizeSegmentedControl setContentOffset:CGSizeMake(0, -1) forSegmentAtIndex:3];
        
        [self addSubview:aFontSizeSegmentedControl];
        self.fontSizeSegment = aFontSizeSegmentedControl;
        [aFontSizeSegmentedControl release];
        
        if ([newDelegate respondsToSelector:@selector(currentFontSize)])
            [aFontSizeSegmentedControl setSelectedSegmentIndex:(NSInteger)[newDelegate performSelector:@selector(currentFontSize)]];
        
        [self.fontSizeSegment addTarget:newDelegate action:@selector(changeFontSize:) forControlEvents:UIControlEventValueChanged];

        UILabel *aPageColorLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        aPageColorLabel.font = [UIFont boldSystemFontOfSize:14.0f];
        aPageColorLabel.textColor = [UIColor whiteColor];
        aPageColorLabel.backgroundColor = [UIColor clearColor];
        aPageColorLabel.text = @"Page Color";
        [self addSubview:aPageColorLabel];
        self.pageColorLabel = aPageColorLabel;
        [aPageColorLabel release];
        
        NSArray *pageColorTitles = [NSArray arrayWithObjects:
                                    @"White",
                                    @"Black",
                                    @"Neutral",
                                    nil];
        
        UISegmentedControl *aPageColorSegmentedControl = [[UISegmentedControl alloc] initWithItems:pageColorTitles];
        aPageColorSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        aPageColorSegmentedControl.tintColor = [UIColor darkGrayColor];
        [self addSubview:aPageColorSegmentedControl];
        self.pageColorSegment = aPageColorSegmentedControl;
        [aPageColorSegmentedControl release];
        
        if ([newDelegate respondsToSelector:@selector(currentPageColor)])
            [aPageColorSegmentedControl setSelectedSegmentIndex:(NSInteger)[newDelegate performSelector:@selector(currentPageColor)]];
        
        [self.pageColorSegment addTarget:newDelegate action:@selector(changePageColor:) forControlEvents:UIControlEventValueChanged];

        NSArray *lockButtonTitles = [NSArray arrayWithObjects:
                                     @"",
                                     nil];
        
        UISegmentedControl *aLockButtonSegmentedControl = [[UISegmentedControl alloc] initWithItems:lockButtonTitles];
        aLockButtonSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        aLockButtonSegmentedControl.tintColor = [UIColor darkGrayColor];
        aLockButtonSegmentedControl.momentary = YES;
        [self addSubview:aLockButtonSegmentedControl];
        self.lockButtonSegment = aLockButtonSegmentedControl;
        [aLockButtonSegmentedControl release];
        
        self.unlockRotationImage = [UIImage imageWithIcon:[UIImage imageNamed:@"icon-lock.png"] string:@"Unlock Rotation" font:defaultFont color:white textInset:inset];
        self.lockRotationImage = [UIImage imageWithIcon:[UIImage imageNamed:@"icon-lock.png"] string:@"Lock Rotation" font:defaultFont color:white textInset:inset];

        if ([newDelegate respondsToSelector:@selector(currentLockRotation)]) {
            NSInteger currentLock = (NSInteger)[newDelegate performSelector:@selector(currentLockRotation)];
            if (currentLock) {
                [aLockButtonSegmentedControl setImage:self.unlockRotationImage forSegmentAtIndex:0];
                [aLockButtonSegmentedControl setTintColor:[UIColor colorWithRed:160.0f / 256.0f green:190.0f / 256.0f  blue:190.0f / 256.0f  alpha:1.0f]];
            } else {
                [aLockButtonSegmentedControl setImage:self.lockRotationImage forSegmentAtIndex:0];
            }
        }
        
        [self.lockButtonSegment addTarget:self action:@selector(changeLockRotation:) forControlEvents:UIControlEventValueChanged];  

        
        NSArray *tapTurnTitles = [NSArray arrayWithObjects:
                                  @"",
                                  nil];
        
        UISegmentedControl *aTapTurnButtonSegmentedControl = [[UISegmentedControl alloc] initWithItems:tapTurnTitles];
        aTapTurnButtonSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        aTapTurnButtonSegmentedControl.tintColor = [UIColor darkGrayColor];
        aTapTurnButtonSegmentedControl.momentary = YES;
        [self addSubview:aTapTurnButtonSegmentedControl];
        self.tapTurnButtonSegment = aTapTurnButtonSegmentedControl;
        [aTapTurnButtonSegmentedControl release];
        
        self.tapTurnOnImage = [UIImage imageWithIcon:[UIImage imageNamed:@"icon-finger.png"] string:@"Tilt Advance On" font:defaultFont color:white textInset:inset];
        self.tapTurnOffImage = [UIImage imageWithIcon:[UIImage imageNamed:@"icon-finger.png"] string:@"Tilt Advance Off" font:defaultFont color:white textInset:inset];

        if ([newDelegate respondsToSelector:@selector(currentTapTurn)]) {
            NSInteger currentTapTurn = (NSInteger)[newDelegate performSelector:@selector(currentTapTurn)];
            if (!currentTapTurn) {
                [aTapTurnButtonSegmentedControl setImage:self.tapTurnOffImage forSegmentAtIndex:0];
            } else {
                [aTapTurnButtonSegmentedControl setImage:self.tapTurnOnImage forSegmentAtIndex:0];
                [aTapTurnButtonSegmentedControl setTintColor:[UIColor colorWithRed:160.0f / 256.0f green:190.0f / 256.0f  blue:190.0f / 256.0f  alpha:1.0f]];
            }
        }
        [self.tapTurnButtonSegment addTarget:self action:@selector(changeTapTurn:) forControlEvents:UIControlEventValueChanged];  

        
        UIButton *aDoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        aDoneButton.showsTouchWhenHighlighted = NO;
        [aDoneButton setTitle:@"Done" forState:UIControlStateNormal];
        [aDoneButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20.0f]];
        [aDoneButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [aDoneButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateHighlighted];
        [aDoneButton.titleLabel setShadowOffset:CGSizeMake(0.0f, 1.0f)];
        [aDoneButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [aDoneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [aDoneButton setBackgroundImage:[UIImage imageNamed:@"done-button-up.png"] forState:UIControlStateNormal];
        [aDoneButton setBackgroundImage:[UIImage imageNamed:@"done-button-down.png"] forState:UIControlStateHighlighted];
        [aDoneButton addTarget:self action:@selector(dismissSheet:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:aDoneButton];
        self.doneButton = aDoneButton;
        
        [self displayPageAttributes];
	}
	return self;
}

- (void)layoutSubviews {    
    CGRect origFrame = self.frame;
    CGFloat heightOffset = kBlioViewSettingsYInset * 2 + kBlioViewSettingsRowSpacing*4 + kBlioViewSettingsSegmentButtonHeight*4 + kBlioViewSettingsDoneButtonHeight - origFrame.size.height;
    origFrame.origin.y -= heightOffset;
    origFrame.size.height += heightOffset;
    self.frame = origFrame;
    
    [self.pageLayoutSegment setFrame:CGRectMake(kBlioViewSettingsXInset, kBlioViewSettingsYInset, CGRectGetWidth(self.bounds) - 2*kBlioViewSettingsXInset, kBlioViewSettingsSegmentButtonHeight)];
    [self.fontSizeLabel setFrame:CGRectMake(kBlioViewSettingsXInset, CGRectGetMaxY([self.pageLayoutSegment frame]) + kBlioViewSettingsRowSpacing, kBlioViewSettingsLabelWidth, kBlioViewSettingsSegmentButtonHeight)];
    [self.fontSizeSegment setFrame:CGRectMake(CGRectGetMaxX([self.fontSizeLabel frame]), CGRectGetMinY([self.fontSizeLabel frame]), CGRectGetWidth(self.bounds) - CGRectGetMaxX([self.fontSizeLabel frame]) - kBlioViewSettingsXInset, kBlioViewSettingsSegmentButtonHeight)];
    [self.pageColorLabel setFrame:CGRectMake(kBlioViewSettingsXInset, CGRectGetMaxY([self.fontSizeSegment frame]) + kBlioViewSettingsRowSpacing, kBlioViewSettingsLabelWidth, kBlioViewSettingsSegmentButtonHeight)];
    [self.pageColorSegment setFrame:CGRectMake(CGRectGetMaxX([self.pageColorLabel frame]), CGRectGetMinY([self.pageColorLabel frame]), CGRectGetWidth(self.bounds) - CGRectGetMaxX([self.pageColorLabel frame]) - kBlioViewSettingsXInset, kBlioViewSettingsSegmentButtonHeight)];
    [self.lockButtonSegment setFrame:CGRectMake(kBlioViewSettingsXInset, CGRectGetMaxY([self.pageColorSegment frame]) + kBlioViewSettingsRowSpacing, (CGRectGetWidth(self.bounds) - 2 * kBlioViewSettingsXInset - kBlioViewSettingsRowSpacing)/2.0f, kBlioViewSettingsSegmentButtonHeight)];
    [self.tapTurnButtonSegment setFrame:CGRectMake(CGRectGetMaxX([self.lockButtonSegment frame]) + kBlioViewSettingsRowSpacing, CGRectGetMinY([self.lockButtonSegment frame]), CGRectGetWidth([self.lockButtonSegment frame]), kBlioViewSettingsSegmentButtonHeight)];
    [self.doneButton setFrame:CGRectMake(kBlioViewSettingsXInset, CGRectGetMaxY([self.lockButtonSegment frame]) + kBlioViewSettingsRowSpacing, CGRectGetWidth(self.bounds) - 2 * kBlioViewSettingsXInset, kBlioViewSettingsDoneButtonHeight)];

    [super layoutSubviews];
}

- (void)changePageLayout:(id)sender {
    
    if ([self.delegate respondsToSelector:@selector(changePageLayout:)])
        [self.delegate performSelector:@selector(changePageLayout:) withObject:sender];
    
    [self displayPageAttributes];
    
}

- (void)changeLockRotation:(id)sender {
    if ([self.delegate respondsToSelector:@selector(changeLockRotation:)])
        [self.delegate performSelector:@selector(changeLockRotation:) withObject:sender];
    /*
     if ([self.delegate respondsToSelector:@selector(currentLockRotation)]) {
     NSInteger currentLock = (NSInteger)[self.delegate performSelector:@selector(currentLockRotation)];
     if (currentLock)
     [sender setTitle:@"Unlock Rotation" forSegmentAtIndex:0];
     else
     [sender setTitle:@"Lock Rotation" forSegmentAtIndex:0];
     }
     */
    if ([[sender imageForSegmentAtIndex:[sender selectedSegmentIndex]] isEqual:self.lockRotationImage]) {
        [sender setImage:self.unlockRotationImage forSegmentAtIndex:0];
        [sender setTintColor:[UIColor colorWithRed:160.0f / 256.0f green:190.0f / 256.0f  blue:190.0f / 256.0f  alpha:1.0f]];
    } else {
        [sender setImage:self.lockRotationImage forSegmentAtIndex:0];
        [sender setTintColor:[UIColor darkGrayColor]];
    }
}

- (void)changeTapTurn:(id)sender {
    if ([self.delegate respondsToSelector:@selector(changeTapTurn:)])
        [self.delegate performSelector:@selector(changeTapTurn:) withObject:sender];
    /*
     if ([self.delegate respondsToSelector:@selector(currentTapTurn)]) {
     NSInteger currentTapTurn = (NSInteger)[self.delegate performSelector:@selector(currentTapTurn)];
     if (currentTapTurn)
     [sender setTitle:@"Tap Turn On" forSegmentAtIndex:0];
     else
     [sender setTitle:@"Tap Turn Off" forSegmentAtIndex:0];
     } 
     */
    if ([[sender imageForSegmentAtIndex:[sender selectedSegmentIndex]] isEqual:self.tapTurnOffImage]) {
        [sender setImage:self.tapTurnOnImage forSegmentAtIndex:0];
        [sender setTintColor:[UIColor colorWithRed:160.0f / 256.0f green:190.0f / 256.0f  blue:190.0f / 256.0f  alpha:1.0f]];
    } else {
        [sender setImage:self.tapTurnOffImage forSegmentAtIndex:0];
        [sender setTintColor:[UIColor darkGrayColor]];
    }
}


- (void)dismissSheet:(id)sender {
  [self dismissWithClickedButtonIndex:0 animated:YES];
}



@end
