//
//  BlioViewSettingsContentsView.m
//  BlioApp
//
//  Created by matt on 31/08/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioViewSettingsContentsView.h"
#import <libEucalyptus/EucPageTurningView.h>
#import "BlioUIImageAdditions.h"
#import "BlioAppSettingsConstants.h"

#define kBlioViewSettingsGreenButton [UIColor colorWithRed:0.053 green:0.613 blue:0.000 alpha:1.000]//[UIColor colorWithRed:0.302 green:0.613 blue:0.289 alpha:1.000]
#define kBlioViewSettingsPopverBlueButton [UIColor colorWithRed:0.100 green:0.152 blue:0.326 alpha:1.000]

static const CGFloat kBlioViewSettingsRowSpacingIPad = 14;
static const CGFloat kBlioViewSettingsXInsetIPad = 20;
static const CGFloat kBlioViewSettingsYInsetIPad = 22;

static const CGFloat kBlioViewSettingsRowSpacingIPhone = 8;
static const CGFloat kBlioViewSettingsXInsetIPhone = 9;
static const CGFloat kBlioViewSettingsYInsetIPhone= 6;

static const CGFloat kBlioViewSettingsSegmentButtonHeight = 36;
static const CGFloat kBlioViewSettingsLabelWidth = 93;

@interface BlioViewSettingsContentsView()

@property (nonatomic, retain) UIImage *lockRotationImage;
@property (nonatomic, retain) UIImage *unlockRotationImage;

- (void)dismiss:(id)sender;
- (void)screenBrightnessDidChange:(NSNotification *)notification;
- (void)screenBrightnessSliderSlid:(UISlider *)slider;

@end

@implementation BlioViewSettingsContentsView

@synthesize delegate;

@synthesize fontSizeLabel;
@synthesize pageColorLabel;
@synthesize tapZoomsToBlockLabel;
@synthesize landscapePageLabel;

@synthesize pageLayoutSegment;
@synthesize fontSizeSegment;
@synthesize pageColorSegment;
@synthesize tapZoomsToBlockSegment;
@synthesize landscapePageSegment;
@synthesize lockButtonSegment;

@synthesize screenBrightnessSlider;

@synthesize doneButton;

@synthesize lockRotationImage, unlockRotationImage;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.delegate = nil;

    self.fontSizeLabel = nil;
    self.pageColorLabel = nil;
	self.tapZoomsToBlockLabel = nil;
	self.landscapePageLabel = nil;
    
    self.pageLayoutSegment = nil;
    self.fontSizeSegment = nil;
    self.pageColorSegment = nil;
	self.tapZoomsToBlockSegment = nil;
	self.landscapePageSegment = nil;
    self.lockButtonSegment = nil;
    
    self.screenBrightnessSlider = nil;

    self.doneButton = nil;
    
    self.lockRotationImage = nil;
    self.unlockRotationImage = nil;
    
    [super dealloc];
}

- (void)displayPageAttributes {
    if ([self.delegate shouldShowFontSizeSettings]) {
        self.fontSizeLabel.enabled = YES;
        self.fontSizeLabel.accessibilityTraits &= ~UIAccessibilityTraitNotEnabled;

        self.fontSizeSegment.enabled = YES;
        self.fontSizeSegment.alpha = 1.0f;
        self.fontSizeSegment.accessibilityTraits &= ~UIAccessibilityTraitNotEnabled;
    } else {
        self.fontSizeLabel.enabled = NO;
        self.fontSizeLabel.accessibilityTraits |= UIAccessibilityTraitNotEnabled;

        self.fontSizeSegment.enabled = NO;
        self.fontSizeSegment.alpha = 0.35f;
        self.fontSizeSegment.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
	}
    
    if ([self.delegate shouldShowPageColorSettings]) {
        self.pageColorLabel.enabled = YES;
        self.pageColorLabel.accessibilityTraits &= ~UIAccessibilityTraitNotEnabled;

        self.pageColorSegment.enabled = YES;
        self.pageColorSegment.alpha = 1.0f;
        self.pageColorSegment.accessibilityTraits &= ~UIAccessibilityTraitNotEnabled;
    } else {
        self.pageColorLabel.enabled = NO;
        self.pageColorLabel.accessibilityTraits |= UIAccessibilityTraitNotEnabled;

        self.pageColorSegment.enabled = NO;
        self.pageColorSegment.alpha = 0.35f;
        self.pageColorSegment.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
	} 
    
	if ([self.delegate shouldShowTapZoomsToBlockSettings]) {
		self.tapZoomsToBlockLabel.enabled = YES;
        self.tapZoomsToBlockLabel.accessibilityTraits &= ~UIAccessibilityTraitNotEnabled;
        
        self.tapZoomsToBlockSegment.enabled = YES;
        self.tapZoomsToBlockSegment.alpha = 1.0f;
        self.tapZoomsToBlockSegment.accessibilityTraits &= ~UIAccessibilityTraitNotEnabled;
	} else {
		self.tapZoomsToBlockLabel.enabled = NO;
        self.tapZoomsToBlockLabel.accessibilityTraits |= UIAccessibilityTraitNotEnabled;

		self.tapZoomsToBlockSegment.enabled = NO;
        self.tapZoomsToBlockSegment.alpha = 0.35f;
        self.tapZoomsToBlockSegment.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
	}
    
	if ([self.delegate shouldShowLandscapePageSettings]) {
		self.landscapePageLabel.enabled = YES;
        self.landscapePageLabel.accessibilityTraits &= ~UIAccessibilityTraitNotEnabled;
        
        self.landscapePageSegment.enabled = YES;
        self.landscapePageSegment.alpha = 1.0f;
        self.landscapePageSegment.accessibilityTraits &= ~UIAccessibilityTraitNotEnabled;
	} else {
		self.landscapePageLabel.enabled = NO;
        self.landscapePageLabel.accessibilityTraits |= UIAccessibilityTraitNotEnabled;

		self.landscapePageSegment.enabled = NO;
        self.landscapePageSegment.alpha = 0.35f;
        self.landscapePageSegment.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
	}
    
    if(self.window) {
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    }
}

- (id)initWithDelegate:(id)newDelegate {
        
	if ((self = [super initWithFrame:CGRectZero])) {
        self.delegate = newDelegate;
		
        UIColor *whiteColor = [UIColor whiteColor];
        UIColor *clearColor = [UIColor clearColor];
        UIColor *tintColor;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            tintColor = [UIColor darkGrayColor];
        } else {
            tintColor = kBlioViewSettingsPopverBlueButton;
        }

		//////// PAGE LAYOUT
		
        UIFont *defaultFont = [UIFont boldSystemFontOfSize:12.0f];
        UIEdgeInsets inset = UIEdgeInsetsMake(0, 2, 2, 2);
        UIImage *plainImage = [UIImage imageWithIcon:[UIImage imageNamed:@"icon-page.png"] string:@"Flowed" font:defaultFont color:whiteColor textInset:inset];
        UIImage *layoutImage = [UIImage imageWithIcon:[UIImage imageNamed:@"icon-layout.png"] string:@"Fixed" font:defaultFont color:whiteColor textInset:inset];
		NSMutableArray *segmentImages = [NSMutableArray arrayWithObjects:
                                         plainImage,
                                         layoutImage,
                                         nil];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [segmentImages addObject:[UIImage imageWithIcon:[UIImage imageNamed:@"icon-speedread.png"] string:@"Fast" font:defaultFont color:whiteColor textInset:inset]];
		}         
        
        BlioAccessibilitySegmentedControl *aLayoutSegmentedControl = [[BlioAccessibilitySegmentedControl alloc] initWithItems:segmentImages];
        aLayoutSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        aLayoutSegmentedControl.tintColor = tintColor;
        
        [aLayoutSegmentedControl setContentOffset:CGSizeMake(0, -1) forSegmentAtIndex:0];
        [aLayoutSegmentedControl setContentOffset:CGSizeMake(0, -1) forSegmentAtIndex:1];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [aLayoutSegmentedControl setContentOffset:CGSizeMake(0, -1) forSegmentAtIndex:2];
        }        
        
        [[aLayoutSegmentedControl imageForSegmentAtIndex:0] setAccessibilityLabel:NSLocalizedString(@"Flowed layout", @"Accessibility label for View Settings Flowed Layout button")];
        [[aLayoutSegmentedControl imageForSegmentAtIndex:0] setAccessibilityHint:NSLocalizedString(@"Switches to the flowed text view.", @"Accessibility hint for View Settings Flowed Layout button")];
        [[aLayoutSegmentedControl imageForSegmentAtIndex:1] setAccessibilityLabel:NSLocalizedString(@"Fixed layout", @"Accessibility label for View Settings Fixed Layout button")];
        [[aLayoutSegmentedControl imageForSegmentAtIndex:1] setAccessibilityHint:NSLocalizedString(@"Switches to the fixed layout view.", @"Accessibility hint for View Settings Fixed Layout button")];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
			[[aLayoutSegmentedControl imageForSegmentAtIndex:2] setAccessibilityLabel:NSLocalizedString(@"Fast layout", @"Accessibility label for View Settings Fast Layout button")];
			[[aLayoutSegmentedControl imageForSegmentAtIndex:2] setAccessibilityHint:NSLocalizedString(@"Switches to the fast reading view.", @"Accessibility hint for View Settings Fast Layout button")];
        }
		
		if (![self.delegate reflowEnabled]) {
			[aLayoutSegmentedControl setEnabled:NO forSegmentAtIndex:0];
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
				[aLayoutSegmentedControl setEnabled:NO forSegmentAtIndex:2];
			}
		}
		if (![self.delegate fixedViewEnabled]) {
			[aLayoutSegmentedControl setEnabled:NO forSegmentAtIndex:1];
		}		
        [self addSubview:aLayoutSegmentedControl];
        self.pageLayoutSegment = aLayoutSegmentedControl;
        [aLayoutSegmentedControl release];
        
        [aLayoutSegmentedControl setSelectedSegmentIndex:[self.delegate currentPageLayout]];
        
        [self.pageLayoutSegment addTarget:self action:@selector(changePageLayout:) forControlEvents:UIControlEventValueChanged];
        
		//////// FONT SIZE

        UILabel *aFontSizeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        aFontSizeLabel.font = [UIFont boldSystemFontOfSize:14.0f];
        aFontSizeLabel.textColor = whiteColor;
        aFontSizeLabel.backgroundColor = clearColor;
        aFontSizeLabel.text = NSLocalizedString(@"Font Size",@"Settings Label for Font Size segmented control.");
        [self addSubview:aFontSizeLabel];
        self.fontSizeLabel = aFontSizeLabel;
        [aFontSizeLabel release];
        
        NSString *letter = NSLocalizedString(@"A",@"Sample letter used for showing font sizes");
        
        // Sizes and offsets for the font size buttons chosen to look 'right' visually
        // rather than being completly accurate to the book view technically.
        CGSize size = CGSizeMake(20, 23);
        CGFloat baseline = 19;
        NSArray *fontSizeTitles = [NSArray arrayWithObjects:
                                   [UIImage blioImageWithString:letter font:[defaultFont fontWithSize:10.5] size:size baseline:baseline color:whiteColor],
                                   [UIImage blioImageWithString:letter font:[defaultFont fontWithSize:13] size:size baseline:baseline color:whiteColor],
                                   [UIImage blioImageWithString:letter font:[defaultFont fontWithSize:15] size:size baseline:baseline color:whiteColor],
                                   [UIImage blioImageWithString:letter font:[defaultFont fontWithSize:19] size:size baseline:baseline color:whiteColor],
                                   [UIImage blioImageWithString:letter font:[defaultFont fontWithSize:23] size:size baseline:baseline color:whiteColor],
                                   nil];
        
        BlioAccessibilitySegmentedControl *aFontSizeSegmentedControl = [[BlioAccessibilitySegmentedControl alloc] initWithItems:fontSizeTitles];    
        aFontSizeSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        aFontSizeSegmentedControl.tintColor = tintColor;
        
        [[aFontSizeSegmentedControl imageForSegmentAtIndex:0] setAccessibilityLabel:NSLocalizedString(@"Smallest font size", @"Accessibility label for View Settings Smallest Font Size button")];
        [[aFontSizeSegmentedControl imageForSegmentAtIndex:1] setAccessibilityLabel:NSLocalizedString(@"Smaller font size", @"Accessibility label for View Settings Smaller Font Size button")];
        [[aFontSizeSegmentedControl imageForSegmentAtIndex:2] setAccessibilityLabel:NSLocalizedString(@"Normal font size", @"Accessibility label for View Settings Normal Font Size button")];
        [[aFontSizeSegmentedControl imageForSegmentAtIndex:3] setAccessibilityLabel:NSLocalizedString(@"Larger font size", @"Accessibility label for View Settings Larger Font Size button")];
        [[aFontSizeSegmentedControl imageForSegmentAtIndex:4] setAccessibilityLabel:NSLocalizedString(@"Largest font size", @"Accessibility label for View Settings Largest Font Size button")];
        
        [self addSubview:aFontSizeSegmentedControl];
        self.fontSizeSegment = aFontSizeSegmentedControl;
        [aFontSizeSegmentedControl release];
        
        [aFontSizeSegmentedControl setSelectedSegmentIndex:[self.delegate currentFontSize]];
        
        [self.fontSizeSegment addTarget:self.delegate action:@selector(changeFontSize:) forControlEvents:UIControlEventValueChanged];
        
		//////// PAGE COLOR
		
        UILabel *aPageColorLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        aPageColorLabel.font = [UIFont boldSystemFontOfSize:14.0f];
        aPageColorLabel.textColor = whiteColor;
        aPageColorLabel.backgroundColor = clearColor;
        aPageColorLabel.text = NSLocalizedString(@"Page Color",@"Settings Label for Page Color segmented control.");
        [self addSubview:aPageColorLabel];
        self.pageColorLabel = aPageColorLabel;
        [aPageColorLabel release];
        
        NSArray *pageColorTitles = [NSArray arrayWithObjects:
                                    NSLocalizedString(@"White",@"\"White\" segment label (for Page Color SegmentedControl)"),
                                    NSLocalizedString(@"Black",@"\"Black\" segment label (for Page Color SegmentedControl)"),
                                    NSLocalizedString(@"Neutral",@"\"Neutral\" segment label (for Page Color SegmentedControl)"),
                                    nil];
        
        BlioAccessibilitySegmentedControl *aPageColorSegmentedControl = [[BlioAccessibilitySegmentedControl alloc] initWithItems:pageColorTitles];
        aPageColorSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        aPageColorSegmentedControl.tintColor = tintColor;
        
		// these lines don't seem to have effect because segmented control is not image-driven...
        [[aPageColorSegmentedControl imageForSegmentAtIndex:0] setAccessibilityLabel:NSLocalizedString(@"White page color", @"Accessibility label for View Settings White Page Color button")];
        [[aPageColorSegmentedControl imageForSegmentAtIndex:1] setAccessibilityLabel:NSLocalizedString(@"Black page color", @"Accessibility label for View Settings Black Page Color button")];
        [[aPageColorSegmentedControl imageForSegmentAtIndex:2] setAccessibilityLabel:NSLocalizedString(@"Neutral page color", @"Accessibility label for View Settings Neutral Page Color button")];
        
        [self addSubview:aPageColorSegmentedControl];
        self.pageColorSegment = aPageColorSegmentedControl;
        [aPageColorSegmentedControl release];
        
        [aPageColorSegmentedControl setSelectedSegmentIndex:[self.delegate currentPageColor]];
        
        [self.pageColorSegment addTarget:self.delegate action:@selector(changePageColor:) forControlEvents:UIControlEventValueChanged];
        
		//////// TAP ZOOMS TO BLOCK
		
        BOOL voiceOverIsRelevant = NO;
#if TARGET_OS_IPHONE && (__IPHONE_OS_VERSION_MAX_ALLOWED >= 50000)
        if(&UIAccessibilityTraitCausesPageTurn != NULL &&
           [EucPageTurningView conformsToProtocol:@protocol(UIAccessibilityReadingContent)]) {
            if(UIAccessibilityIsVoiceOverRunning()) {
                voiceOverIsRelevant = YES;
            }
        }
#endif
        
		UILabel *aTabZoomsToBlockLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        aTabZoomsToBlockLabel.font = [UIFont boldSystemFontOfSize:14.0f];
        aTabZoomsToBlockLabel.textColor = whiteColor;
        aTabZoomsToBlockLabel.backgroundColor = clearColor;
        if(voiceOverIsRelevant) {
            aTabZoomsToBlockLabel.text = NSLocalizedString(@"Navigate",@"Settings Label for \"Tap Advance\" Segmented Control when VoiceOver is running (for VoiceOver users, the setting is not related to tapping, but to how VoiceOver selects text).");
        } else {
            aTabZoomsToBlockLabel.text = NSLocalizedString(@"Tap Advance",@"Settings Label for \"Tap Advance\" Segmented Control.");
        }
        [self addSubview:aTabZoomsToBlockLabel];
        self.tapZoomsToBlockLabel = aTabZoomsToBlockLabel;
        [aTabZoomsToBlockLabel release];
		
		NSArray *tapAdvanceTitles = [NSArray arrayWithObjects:
                                    NSLocalizedString(@"By Page",@"\"By Page\" segment label (for \"Tap Advance\" SegmentedControl)"),
                                    NSLocalizedString(@"By Block",@"\"By Block\" segment label (for \"Tap Advance\" SegmentedControl)"),
                                    nil];
		
		BlioAccessibilitySegmentedControl *aTapZoomsToBlockSegment = [[BlioAccessibilitySegmentedControl alloc] initWithItems:tapAdvanceTitles];
        aTapZoomsToBlockSegment.segmentedControlStyle = UISegmentedControlStyleBar;
        aTapZoomsToBlockSegment.tintColor = tintColor;
        
        if(voiceOverIsRelevant) {
            [aTapZoomsToBlockSegment setAccessibilityHint:NSLocalizedString(@"In this mode, two finger swipe down to begin reading from the current position. Pages will turn automatically. Tap the page to stop reading, or to read individual lines.", @"Accessibility hint for View Settings \"By Page\" button (for \"Tap Advance\" SegmentedControl)") forSegmentIndex:0];
            [aTapZoomsToBlockSegment setAccessibilityHint:NSLocalizedString(@"In this mode, tap the page to read blocks of text.  Two finger swipe down to read the current page.  Pages will not turn automatically.", @"Accessibility hing for View Settings  \"By Block\" button (for \"Tap Advance\" SegmentedControl)") forSegmentIndex:1];
        }
    
        [self addSubview:aTapZoomsToBlockSegment];
        self.tapZoomsToBlockSegment = aTapZoomsToBlockSegment;
        [aTapZoomsToBlockSegment release];
        
		if ( [[NSUserDefaults standardUserDefaults] boolForKey:kBlioTapZoomsDefaultsKey] == YES ) {
			[self.tapZoomsToBlockSegment setSelectedSegmentIndex:1];
		} else { 
            [self.tapZoomsToBlockSegment setSelectedSegmentIndex:0];
        }
        
        [self.tapZoomsToBlockSegment addTarget:self.delegate action:@selector(changeTapZooms:) forControlEvents:UIControlEventValueChanged];
		
		
		//////// LANDSCAPE PAGE NUMBER

		UILabel *aLandscapePageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        aLandscapePageLabel.font = [UIFont boldSystemFontOfSize:14.0f];
        aLandscapePageLabel.textColor = whiteColor;
        aLandscapePageLabel.backgroundColor = clearColor;
        aLandscapePageLabel.text = NSLocalizedString(@"Landscape",@"Settings Label for number of pages displayed in landscape.");
        [self addSubview:aLandscapePageLabel];
        self.landscapePageLabel = aLandscapePageLabel;
        [aLandscapePageLabel release];
		
		NSArray *landscapePageTitles = [NSArray arrayWithObjects:
									 NSLocalizedString(@"1 Page",@"\"1 Page\" segment label (for Landscape Page SegmentedControl)"),
									 NSLocalizedString(@"2 Pages",@"\"2 Pages\" segment label (for Landscape Page SegmentedControl)"),
									 nil];
		
		BlioAccessibilitySegmentedControl *aLandscapePageSegment = [[BlioAccessibilitySegmentedControl alloc] initWithItems:landscapePageTitles];
        aLandscapePageSegment.segmentedControlStyle = UISegmentedControlStyleBar;
        aLandscapePageSegment.tintColor = tintColor;
                
        [self addSubview:aLandscapePageSegment];
        self.landscapePageSegment = aLandscapePageSegment;
        [aLandscapePageSegment release];
        
		if ( [[NSUserDefaults standardUserDefaults] boolForKey:kBlioLandscapeTwoPagesDefaultsKey] == YES ) {
			[self.landscapePageSegment setSelectedSegmentIndex:1];
		}
		else [self.landscapePageSegment setSelectedSegmentIndex:0];
        
        [self.landscapePageSegment addTarget:self.delegate action:@selector(changeLandscapePage:) forControlEvents:UIControlEventValueChanged];
		
		//////// ORIENTATION LOCK

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            
            BlioAccessibilitySegmentedControl *aLockButtonSegmentedControl = [[BlioAccessibilitySegmentedControl alloc] init];
            aLockButtonSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
            aLockButtonSegmentedControl.tintColor = tintColor;
            aLockButtonSegmentedControl.momentary = YES;
//          [self addSubview:aLockButtonSegmentedControl];
            self.lockButtonSegment = aLockButtonSegmentedControl;
            [aLockButtonSegmentedControl release];
            
            self.unlockRotationImage = [UIImage imageWithIcon:[UIImage imageNamed:@"icon-lock.png"] string:NSLocalizedString(@"Unlock Rotation",@"\"Unlock Rotation\" label for Lock button") font:defaultFont color:whiteColor textInset:inset];
            self.lockRotationImage = [UIImage imageWithIcon:[UIImage imageNamed:@"icon-lock.png"] string:NSLocalizedString(@"Lock Rotation",@"\"Lock Rotation\" label for Lock button") font:defaultFont color:whiteColor textInset:inset];
            
            BOOL currentLock = [self.delegate isRotationLocked];
            if (currentLock) {
                [aLockButtonSegmentedControl insertSegmentWithImage:self.unlockRotationImage atIndex:0 animated:NO];
                [aLockButtonSegmentedControl setTintColor:kBlioViewSettingsGreenButton];
                [[aLockButtonSegmentedControl imageForSegmentAtIndex:0] setAccessibilityLabel:NSLocalizedString(@"Unlock rotation", @"Accessibility label for View Settings Unlock Rotation button")];
                [[aLockButtonSegmentedControl imageForSegmentAtIndex:0] setAccessibilityTraits:UIAccessibilityTraitButton | UIAccessibilityTraitSelected];
            } else {
                [aLockButtonSegmentedControl insertSegmentWithImage:self.lockRotationImage atIndex:0 animated:NO];
                [[aLockButtonSegmentedControl imageForSegmentAtIndex:0] setAccessibilityLabel:NSLocalizedString(@"Lock Rotation", @"Accessibility label for View Settings Lock Rotation button")];
                [[aLockButtonSegmentedControl imageForSegmentAtIndex:0] setAccessibilityTraits:UIAccessibilityTraitButton];
            }
            
            
            [self.lockButtonSegment addTarget:self action:@selector(changeLockRotation:) forControlEvents:UIControlEventValueChanged];  
        }
                
        UIScreen *mainScreen = [UIScreen mainScreen];
        if([mainScreen respondsToSelector:@selector(setBrightness:)]) {
            // Weird valueForKey stuff to allow compilation with iOS SDK 4.3
            [mainScreen setValue:[NSNumber numberWithBool:YES] forKey:@"wantsSoftwareDimming"];
            CGFloat currentBrightness = [[mainScreen valueForKey:@"brightness"] floatValue];
            
            UISlider *slider = [[UISlider alloc] initWithFrame:CGRectZero];
            slider.accessibilityLabel = NSLocalizedString(@"Brightness", @"Accessibility label for screen brightness slider");
            
            UIImage *leftCapImage = [UIImage imageNamed:@"iPodLikeSliderBlueLeftCap.png"];
            leftCapImage = [leftCapImage stretchableImageWithLeftCapWidth:leftCapImage.size.width - 1 topCapHeight:0];
            [slider setMinimumTrackImage:leftCapImage forState:UIControlStateNormal];
            
            UIImage *rightCapImage = [UIImage imageNamed:@"iPodLikeSliderWhiteRightCap.png"];
            rightCapImage = [rightCapImage stretchableImageWithLeftCapWidth:rightCapImage.size.width - 1 topCapHeight:0];
            [slider setMaximumTrackImage:rightCapImage forState:UIControlStateNormal];
                        
            slider.minimumValueImage = [UIImage imageNamed:@"brightness-sun-dim.png"];
            slider.maximumValueImage = [UIImage imageNamed:@"brightness-sun-bright.png"];
            
            [slider addTarget:self action:@selector(screenBrightnessSliderSlid:) forControlEvents:UIControlEventValueChanged];
            slider.value = currentBrightness;
            
            [self addSubview:slider];
            self.screenBrightnessSlider = slider;
            [slider release];
            
#if TARGET_OS_IPHONE && (__IPHONE_OS_VERSION_MAX_ALLOWED >= 50000)
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenBrightnessDidChange:) name:UIScreenBrightnessDidChangeNotification object:[UIScreen mainScreen]];
#endif
        }
        
        if([newDelegate shouldShowDoneButtonInPageSettings]) {
            UIButton *aDoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
            aDoneButton.showsTouchWhenHighlighted = NO;
            [aDoneButton setTitle:NSLocalizedString(@"Done",@"\"Done\" bar button title") forState:UIControlStateNormal];
            [aDoneButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20.0f]];
            [aDoneButton setTitleShadowColor:whiteColor forState:UIControlStateNormal];
            [aDoneButton setTitleShadowColor:clearColor forState:UIControlStateHighlighted];
            [aDoneButton.titleLabel setShadowOffset:CGSizeMake(0.0f, 1.0f)];
            [aDoneButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [aDoneButton setTitleColor:whiteColor forState:UIControlStateHighlighted];
            [aDoneButton setBackgroundImage:[[UIImage imageNamed:@"done-button-up.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:0] forState:UIControlStateNormal];
            [aDoneButton setBackgroundImage:[[UIImage imageNamed:@"done-button-down.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:0] forState:UIControlStateHighlighted];
            [aDoneButton addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:aDoneButton];
            self.doneButton = aDoneButton;
        }
        
        [self displayPageAttributes];
	}
	return self;
}



- (CGFloat)contentsHeight {
    CGFloat height;
    CGFloat yInset, rowSpacing, rowHeight;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        yInset = kBlioViewSettingsYInsetIPhone;
        rowSpacing = kBlioViewSettingsRowSpacingIPhone;
        
        [self.pageLayoutSegment sizeToFit];
        rowHeight = self.pageLayoutSegment.frame.size.height;
    } else {
        yInset = kBlioViewSettingsYInsetIPad;
        rowSpacing = kBlioViewSettingsRowSpacingIPad;
        rowHeight = kBlioViewSettingsSegmentButtonHeight;
    }
    height =  yInset * 2 + rowSpacing * 4 + rowHeight * 5;
    
    if(self.screenBrightnessSlider && !self.delegate.shouldPresentBrightnessSliderVerticallyInPageSettings) {
        height += rowSpacing + rowHeight;
    }
    
    if(self.doneButton) {
        height += rowSpacing + rowHeight;
    }
    
    return height;
}

- (void)layoutSubviews {
    CGFloat xInset, yInset, rowHeight, rowSpacing;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        xInset = kBlioViewSettingsXInsetIPhone;
        yInset = kBlioViewSettingsYInsetIPhone;
        rowSpacing = kBlioViewSettingsRowSpacingIPhone;
        [self.pageLayoutSegment sizeToFit];
        rowHeight = self.pageLayoutSegment.frame.size.height;
    } else {
        xInset = kBlioViewSettingsXInsetIPad;
        yInset = kBlioViewSettingsYInsetIPad;
        rowHeight = kBlioViewSettingsSegmentButtonHeight;
        rowSpacing = kBlioViewSettingsRowSpacingIPad;
    }

    UISlider *myScreenBrightnessSlider = self.screenBrightnessSlider;
    myScreenBrightnessSlider.transform = CGAffineTransformIdentity;
    BOOL brightnessSliderShouldBeVertical = screenBrightnessSlider && self.delegate.shouldPresentBrightnessSliderVerticallyInPageSettings;
    
    CGFloat innerWidth = CGRectGetWidth(self.bounds) - 2 * xInset;
    CGFloat innerWidthWithoutSlider = innerWidth;
    if(brightnessSliderShouldBeVertical) {
        [myScreenBrightnessSlider sizeToFit];
        innerWidthWithoutSlider -= myScreenBrightnessSlider.frame.size.height + rowSpacing;
    }
    
    CGFloat labelWidth = kBlioViewSettingsLabelWidth;
    
    CGFloat segmentX = labelWidth + xInset;
    CGFloat segmentWidth = innerWidthWithoutSlider - segmentX + xInset;
    
    CGFloat rowStride = rowSpacing + rowHeight;
    CGFloat currentY = yInset;

    [self.pageLayoutSegment setFrame:CGRectMake(xInset, currentY, innerWidthWithoutSlider, rowHeight)];
    currentY += rowStride;
    
    [self.fontSizeLabel setFrame:CGRectMake(xInset, currentY, labelWidth, rowHeight)];
    [self.fontSizeSegment setFrame:CGRectMake(segmentX, currentY, segmentWidth, rowHeight)];
    currentY += rowStride;
    
    [self.pageColorLabel setFrame:CGRectMake(xInset, currentY, labelWidth, rowHeight)];
    [self.pageColorSegment setFrame:CGRectMake(segmentX, currentY, segmentWidth, rowHeight)];
    currentY += rowStride;

    [self.tapZoomsToBlockLabel setFrame:CGRectMake(xInset, currentY, labelWidth, rowHeight)];
    [self.tapZoomsToBlockSegment setFrame:CGRectMake(segmentX, currentY, segmentWidth, rowHeight)];
    currentY += rowStride;

    [self.landscapePageLabel setFrame:CGRectMake(xInset, currentY, labelWidth, rowHeight)];
    [self.landscapePageSegment setFrame:CGRectMake(segmentX, currentY, segmentWidth, rowHeight)];
    currentY += rowStride;

//		[self.lockButtonSegment setFrame:CGRectMake(xInset, CGRectGetMaxY([self.landscapePageLabel frame]) + kBlioViewSettingsRowSpacing, (CGRectGetWidth(self.bounds) - 2 * xInset - kBlioViewSettingsRowSpacing)/2.0f, buttonHeight)];
        
    if(myScreenBrightnessSlider) {
        UIImage *thumbImage;
        if(!brightnessSliderShouldBeVertical) {
            [myScreenBrightnessSlider setFrame:CGRectMake(xInset + 8, currentY, innerWidth - 14,  rowHeight)];
            currentY += rowStride;
            thumbImage = [UIImage imageNamed:@"iPodLikeSliderKnob.png"];
        } else {
            myScreenBrightnessSlider.transform = CGAffineTransformMakeRotation(-(CGFloat)M_PI_2);
            [myScreenBrightnessSlider setFrame:CGRectMake(xInset + innerWidthWithoutSlider + rowSpacing, yInset + 4, myScreenBrightnessSlider.bounds.size.height, currentY - rowSpacing - yInset - 8)];
            
            // Use the small thumb image, and rotate it so that it'll be upright after the slider is 
            // vertical.
            thumbImage = [UIImage imageNamed:@"iPodLikeSliderKnob-Small.png"];
            thumbImage = [thumbImage blioImageByRotatingTo:UIImageOrientationLeft];
        }
        [myScreenBrightnessSlider setThumbImage:thumbImage forState:UIControlStateNormal];
        [myScreenBrightnessSlider setThumbImage:thumbImage forState:UIControlStateHighlighted];            
    }
    
    if(self.doneButton) {
        [self.doneButton setFrame:CGRectMake(xInset, currentY, innerWidth,  rowHeight)];
    }
    
    [super layoutSubviews];
}

- (void)changePageLayout:(id)sender {
    [self.delegate changePageLayout:sender];
    [self displayPageAttributes];
}


- (void)changeLockRotation:(id)sender {
    [self.delegate changeLockRotation];
    
    BOOL currentLock = [self.delegate isRotationLocked];
    if (currentLock) {
        [sender setImage:self.unlockRotationImage forSegmentAtIndex:0];
        [sender setTintColor:kBlioViewSettingsGreenButton];
        [[sender imageForSegmentAtIndex:0] setAccessibilityLabel:NSLocalizedString(@"Unlock rotation", @"Accessibility label for View Settings Unlock Rotation button")];
        [[sender imageForSegmentAtIndex:0] setAccessibilityTraits:UIAccessibilityTraitButton | UIAccessibilityTraitSelected];
    } else {
        [sender setImage:self.lockRotationImage forSegmentAtIndex:0];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [sender setTintColor:[UIColor darkGrayColor]];
        } else {
            [sender setTintColor:kBlioViewSettingsPopverBlueButton];
        }
        [[sender imageForSegmentAtIndex:0] setAccessibilityLabel:NSLocalizedString(@"Lock Rotation", @"Accessibility label for View Settings Lock Rotation button")];
        [[sender imageForSegmentAtIndex:0] setAccessibilityTraits:UIAccessibilityTraitButton];
    }
}

- (void)dismiss:(id)sender {
    [self.delegate dismissViewSettings:self];
}

- (void)screenBrightnessSliderSlid:(UISlider *)slider
{
    // Weird valueForKey stuff to allow compilation with iOS SDK 4.3
    [[UIScreen mainScreen] setValue:[NSNumber numberWithFloat:slider.value] forKey:@"brightness"];
}

- (void)screenBrightnessDidChange:(NSNotification *)notification
{
#if TARGET_OS_IPHONE && (__IPHONE_OS_VERSION_MAX_ALLOWED >= 50000)
    [self.screenBrightnessSlider setValue:[[notification object] brightness]];
#endif
}

@end
 