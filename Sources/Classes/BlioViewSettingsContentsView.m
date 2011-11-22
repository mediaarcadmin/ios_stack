//
//  BlioViewSettingsContentsView.m
//  BlioApp
//
//  Created by matt on 31/08/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioViewSettings.h"
#import "BlioViewSettingsContentsView.h"
#import <libEucalyptus/EucPageTurningView.h>
#import "BlioUIImageAdditions.h"

@interface BlioViewSettingsContentsView()

@property (nonatomic, assign) id<BlioViewSettingsDelegate> delegate;

@property (nonatomic, retain) UILabel *fontAndSizeLabel;
@property (nonatomic, retain) UILabel *pageColorLabel;
@property (nonatomic, retain) UILabel *tapZoomsLabel;
@property (nonatomic, retain) UILabel *twoUpLandscapeLabel;

@property (nonatomic, retain) BlioAccessibilitySegmentedControl *pageLayoutSegment;
@property (nonatomic, retain) BlioAccessibilitySegmentedControl *fontAndSizeSegment;
@property (nonatomic, retain) BlioAccessibilitySegmentedControl *pageColorSegment;
@property (nonatomic, retain) BlioAccessibilitySegmentedControl *tapZoomsSegment;
@property (nonatomic, retain) BlioAccessibilitySegmentedControl *twoUpLandscapeSegment;
@property (nonatomic, retain) BlioAccessibilitySegmentedControl *lockButtonSegment;

@property (nonatomic, retain) UIButton *doneButton;
@property (nonatomic, retain) UISlider *screenBrightnessSlider;

@property (nonatomic, assign) BOOL refreshingSettings;

@property (nonatomic, retain) UIImage *lockRotationImage;
@property (nonatomic, retain) UIImage *unlockRotationImage;

- (void)dismiss:(id)sender;
- (void)screenBrightnessDidChange:(NSNotification *)notification;
- (void)screenBrightnessSliderSlid:(UISlider *)slider;

@end

@implementation BlioViewSettingsContentsView

@synthesize delegate;

@synthesize refreshingSettings;

@synthesize fontAndSizeLabel;
@synthesize pageColorLabel;
@synthesize tapZoomsLabel;
@synthesize twoUpLandscapeLabel;

@synthesize pageLayoutSegment;
@synthesize fontAndSizeSegment;
@synthesize pageColorSegment;
@synthesize tapZoomsSegment;
@synthesize twoUpLandscapeSegment;
@synthesize lockButtonSegment;

@synthesize screenBrightnessSlider;

@synthesize doneButton;

@synthesize lockRotationImage, unlockRotationImage;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.delegate = nil;

    self.pageColorLabel = nil;
	self.tapZoomsLabel = nil;
	self.twoUpLandscapeLabel = nil;
    
    self.pageLayoutSegment = nil;
    self.pageColorSegment = nil;
	self.tapZoomsSegment = nil;
	self.twoUpLandscapeSegment = nil;
    self.lockButtonSegment = nil;
    
    self.screenBrightnessSlider = nil;

    self.doneButton = nil;
    
    self.lockRotationImage = nil;
    self.unlockRotationImage = nil;
    
    [super dealloc];
}

- (void)refreshFontLabel
{
    [self.fontAndSizeSegment setTitle:self.delegate.currentFontName forSegmentAtIndex:0];
}

- (void)refreshSettings {
    self.refreshingSettings = YES;
    
    [self.pageLayoutSegment setSelectedSegmentIndex:[self.delegate currentPageLayout]];

    if ([self.delegate shouldShowFontSettings]) {
        self.fontAndSizeLabel.enabled = YES;
        self.fontAndSizeLabel.accessibilityTraits &= ~UIAccessibilityTraitNotEnabled;
        
        self.fontAndSizeSegment.enabled = YES;
        self.fontAndSizeSegment.alpha = 1.0f;
        self.fontAndSizeSegment.accessibilityTraits &= ~UIAccessibilityTraitNotEnabled;
    } else {
        self.fontAndSizeLabel.enabled = NO;
        self.fontAndSizeLabel.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
        
        self.fontAndSizeSegment.enabled = NO;
        self.fontAndSizeSegment.alpha = 0.35f;
        self.fontAndSizeSegment.accessibilityTraits |= UIAccessibilityTraitNotEnabled;        
    }
    [self refreshFontLabel];
    
    if ([self.delegate shouldShowPageColorSettings]) {
        self.pageColorLabel.enabled = YES;
        self.pageColorLabel.accessibilityTraits &= ~UIAccessibilityTraitNotEnabled;
        
        self.pageColorSegment.enabled = YES;
        self.pageColorSegment.alpha = 1.0f;
        self.pageColorSegment.accessibilityTraits &= ~UIAccessibilityTraitNotEnabled;
        
        [self.pageColorSegment setSelectedSegmentIndex:[self.delegate currentPageColor]];
    } else {
        self.pageColorLabel.enabled = NO;
        self.pageColorLabel.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
        
        self.pageColorSegment.enabled = NO;
        self.pageColorSegment.alpha = 0.35f;
        self.pageColorSegment.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
        
        [self.pageColorSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
	} 
    
	if ([self.delegate shouldShowtapZoomsSettings]) {
		self.tapZoomsLabel.enabled = YES;
        self.tapZoomsLabel.accessibilityTraits &= ~UIAccessibilityTraitNotEnabled;
        
        self.tapZoomsSegment.enabled = YES;
        self.tapZoomsSegment.alpha = 1.0f;
        self.tapZoomsSegment.accessibilityTraits &= ~UIAccessibilityTraitNotEnabled;
        
        if ( self.delegate.currentTapZooms ) {
            [self.tapZoomsSegment setSelectedSegmentIndex:1];
        } else { 
            [self.tapZoomsSegment setSelectedSegmentIndex:0];
        }
	} else {
		self.tapZoomsLabel.enabled = NO;
        self.tapZoomsLabel.accessibilityTraits |= UIAccessibilityTraitNotEnabled;

		self.tapZoomsSegment.enabled = NO;
        self.tapZoomsSegment.alpha = 0.35f;
        self.tapZoomsSegment.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
        
        [self.tapZoomsSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
	}
    
	if ([self.delegate shouldShowTwoUpLandscapeSettings]) {
		self.twoUpLandscapeLabel.enabled = YES;
        self.twoUpLandscapeLabel.accessibilityTraits &= ~UIAccessibilityTraitNotEnabled;
        
        self.twoUpLandscapeSegment.enabled = YES;
        self.twoUpLandscapeSegment.alpha = 1.0f;
        self.twoUpLandscapeSegment.accessibilityTraits &= ~UIAccessibilityTraitNotEnabled;
        if ( self.delegate.currentTwoUpLandscape) {
			[self.twoUpLandscapeSegment setSelectedSegmentIndex:1];
		} else {
            [self.twoUpLandscapeSegment setSelectedSegmentIndex:0];
        }
	} else {
		self.twoUpLandscapeLabel.enabled = NO;
        self.twoUpLandscapeLabel.accessibilityTraits |= UIAccessibilityTraitNotEnabled;

		self.twoUpLandscapeSegment.enabled = NO;
        self.twoUpLandscapeSegment.alpha = 0.35f;
        self.twoUpLandscapeSegment.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
        
        [self.twoUpLandscapeSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
	}
    
    self.refreshingSettings = NO;
    
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
                
        [self.pageLayoutSegment addTarget:self action:@selector(changePageLayout:) forControlEvents:UIControlEventValueChanged];
                
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
        
        [self.pageColorSegment addTarget:self action:@selector(changePageColor:) forControlEvents:UIControlEventValueChanged];
        
        
		//////// FONT AND SIZE BUTTON
		
        UILabel *aFontAndSizeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        aFontAndSizeLabel.font = [UIFont boldSystemFontOfSize:14.0f];
        aFontAndSizeLabel.textColor = whiteColor;
        aFontAndSizeLabel.backgroundColor = clearColor;
        aFontAndSizeLabel.text = NSLocalizedString(@"Font & Size",@"Settings Label for Font and Size button.");
        [self addSubview:aFontAndSizeLabel];
        self.fontAndSizeLabel = aFontAndSizeLabel;
        [aFontAndSizeLabel release];
                
        BlioAccessibilitySegmentedControl *aFontAndSizeSegmentedControl = [[BlioAccessibilitySegmentedControl alloc] initWithItems:[NSArray arrayWithObject:aFontAndSizeLabel.text]];
        aFontAndSizeSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        aFontAndSizeSegmentedControl.tintColor = tintColor;
        aFontAndSizeSegmentedControl.momentary = YES;
        
        [[aFontAndSizeSegmentedControl imageForSegmentAtIndex:0] setAccessibilityLabel:NSLocalizedString(@"White page color", @"Accessibility label for View Settings White Page Color button")];
        
        [self addSubview:aFontAndSizeSegmentedControl];
        self.fontAndSizeSegment = aFontAndSizeSegmentedControl;
        [aFontAndSizeSegmentedControl release];
        
        [self.fontAndSizeSegment addTarget:self action:@selector(displayFontSettings:) forControlEvents:UIControlEventValueChanged];

        
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
            aTabZoomsToBlockLabel.text = NSLocalizedString(@"Read Mode",@"Settings Label for \"Tap Advance\" Segmented Control when VoiceOver is running (for VoiceOver users, the setting is not related to tapping, but to how VoiceOver reads text).");
        } else {
            aTabZoomsToBlockLabel.text = NSLocalizedString(@"Tap Advance",@"Settings Label for \"Tap Advance\" Segmented Control.");
        }
        [self addSubview:aTabZoomsToBlockLabel];
        self.tapZoomsLabel = aTabZoomsToBlockLabel;
        [aTabZoomsToBlockLabel release];
		
		NSArray *tapAdvanceTitles;
        if(voiceOverIsRelevant) 
            tapAdvanceTitles = [NSArray arrayWithObjects:
                                NSLocalizedString(@"Continuous",@"\"Continuous\" segment label (for \"Read Mode\" SegmentedControl)"),
                                NSLocalizedString(@"By Block",@"\"By Block\" segment label (for \"Read Mode\" SegmentedControl)"),
                                nil];
        else
            tapAdvanceTitles = [NSArray arrayWithObjects:
                                NSLocalizedString(@"By Page",@"\"By Page\" segment label (for \"Tap Advance\" SegmentedControl)"),
                                NSLocalizedString(@"By Block",@"\"By Block\" segment label (for \"Tap Advance\" SegmentedControl)"),
                                nil];
		
		BlioAccessibilitySegmentedControl *atapZoomsSegment = [[BlioAccessibilitySegmentedControl alloc] initWithItems:tapAdvanceTitles];
        atapZoomsSegment.segmentedControlStyle = UISegmentedControlStyleBar;
        atapZoomsSegment.tintColor = tintColor;
        
        if(voiceOverIsRelevant) {
            [atapZoomsSegment setAccessibilityHint:NSLocalizedString(@"In this mode, two finger swipe down to begin reading from the current position. Pages will turn automatically. Tap the page to stop reading, or to read individual lines.", @"Accessibility hint for View Settings \"By Page\" button (for \"Tap Advance\" SegmentedControl)") forSegmentIndex:0];
            [atapZoomsSegment setAccessibilityHint:NSLocalizedString(@"In this mode, tap the page to read blocks of text.  Two finger swipe down to read the current page.  Pages will not turn automatically.", @"Accessibility hing for View Settings  \"By Block\" button (for \"Tap Advance\" SegmentedControl)") forSegmentIndex:1];
        }
    
        [self addSubview:atapZoomsSegment];
        self.tapZoomsSegment = atapZoomsSegment;
        [atapZoomsSegment release];
        
        [self.tapZoomsSegment addTarget:self action:@selector(changeTapZooms:) forControlEvents:UIControlEventValueChanged];
		
		
		//////// LANDSCAPE PAGE NUMBER

		UILabel *atwoUpLandscapeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        atwoUpLandscapeLabel.font = [UIFont boldSystemFontOfSize:14.0f];
        atwoUpLandscapeLabel.textColor = whiteColor;
        atwoUpLandscapeLabel.backgroundColor = clearColor;
        atwoUpLandscapeLabel.text = NSLocalizedString(@"Landscape",@"Settings Label for number of pages displayed in landscape.");
        [self addSubview:atwoUpLandscapeLabel];
        self.twoUpLandscapeLabel = atwoUpLandscapeLabel;
        [atwoUpLandscapeLabel release];
		
		NSArray *twoUpLandscapeTitles = [NSArray arrayWithObjects:
									 NSLocalizedString(@"1 Page",@"\"1 Page\" segment label (for Landscape Page SegmentedControl)"),
									 NSLocalizedString(@"2 Pages",@"\"2 Pages\" segment label (for Landscape Page SegmentedControl)"),
									 nil];
		
		BlioAccessibilitySegmentedControl *atwoUpLandscapeSegment = [[BlioAccessibilitySegmentedControl alloc] initWithItems:twoUpLandscapeTitles];
        atwoUpLandscapeSegment.segmentedControlStyle = UISegmentedControlStyleBar;
        atwoUpLandscapeSegment.tintColor = tintColor;
                
        [self addSubview:atwoUpLandscapeSegment];
        self.twoUpLandscapeSegment = atwoUpLandscapeSegment;
        [atwoUpLandscapeSegment release];
                
        [self.twoUpLandscapeSegment addTarget:self action:@selector(changeTwoUpLandscape:) forControlEvents:UIControlEventValueChanged];
		
		//////// ORIENTATION LOCK

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            
            BlioAccessibilitySegmentedControl *aLockButtonSegmentedControl = [[BlioAccessibilitySegmentedControl alloc] initWithItems:nil];
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
        
        [self refreshSettings];
	}
	return self;
}


- (BOOL)hasScreenBrightnessSlider
{
    return self.screenBrightnessSlider != nil;
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
    
    [self.fontAndSizeLabel setFrame:CGRectMake(xInset, currentY, labelWidth, rowHeight)];
    [self.fontAndSizeSegment setFrame:CGRectMake(segmentX, currentY, segmentWidth, rowHeight)];
    currentY += rowStride;

    [self.pageColorLabel setFrame:CGRectMake(xInset, currentY, labelWidth, rowHeight)];
    [self.pageColorSegment setFrame:CGRectMake(segmentX, currentY, segmentWidth, rowHeight)];
    currentY += rowStride;

    [self.tapZoomsLabel setFrame:CGRectMake(xInset, currentY, labelWidth, rowHeight)];
    [self.tapZoomsSegment setFrame:CGRectMake(segmentX, currentY, segmentWidth, rowHeight)];
    currentY += rowStride;

    [self.twoUpLandscapeLabel setFrame:CGRectMake(xInset, currentY, labelWidth, rowHeight)];
    [self.twoUpLandscapeSegment setFrame:CGRectMake(segmentX, currentY, segmentWidth, rowHeight)];
    currentY += rowStride;

//		[self.lockButtonSegment setFrame:CGRectMake(xInset, CGRectGetMaxY([self.twoUpLandscapeLabel frame]) + kBlioViewSettingsRowSpacing, (CGRectGetWidth(self.bounds) - 2 * xInset - kBlioViewSettingsRowSpacing)/2.0f, buttonHeight)];
        
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
    if(!self.refreshingSettings) {
        [self.delegate changePageLayout:((UISegmentedControl*)sender).selectedSegmentIndex];
        [self refreshSettings];
    }
}

- (void)displayFontSettings:(id)sender {
    [self.delegate viewSettingsShowFontSettings:self];
}

- (void)changePageColor:(id)sender {
    if(!self.refreshingSettings) {
        [self.delegate changePageColor:((UISegmentedControl*)sender).selectedSegmentIndex];
    }
}

- (void)changeTapZooms:(id)sender {
    if(!self.refreshingSettings) {
        [self.delegate changeTapZooms:((UISegmentedControl*)sender).selectedSegmentIndex == 1];
    }
}

- (void)changeTwoUpLandscape:(id)sender {
    if(!self.refreshingSettings) {
        [self.delegate changeTwoUpLandscape:((UISegmentedControl*)sender).selectedSegmentIndex == 1];
    }
}

- (void)changeLockRotation:(id)sender {
    if(!self.refreshingSettings) {
        [self.delegate toggleRotationLock];
        
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
}

- (void)screenBrightnessSliderSlid:(UISlider *)slider
{
    if(!self.refreshingSettings) {
        // Weird valueForKey stuff to allow compilation with iOS SDK 4.3
        [[UIScreen mainScreen] setValue:[NSNumber numberWithFloat:slider.value] forKey:@"brightness"];
    }
}

- (void)screenBrightnessDidChange:(NSNotification *)notification
{
#if TARGET_OS_IPHONE && (__IPHONE_OS_VERSION_MAX_ALLOWED >= 50000)
    [self.screenBrightnessSlider setValue:[[notification object] brightness]];
#endif
}

- (void)dismiss:(id)sender {
    [self.delegate dismissViewSettings:self];
}

@end
 