//
//  BlioViewSettingsContentsView.m
//  BlioApp
//
//  Created by matt on 31/08/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioViewSettingsContentsView.h"
#import <libEucalyptus/THUIImageAdditions.h>
#import "BlioUIImageAdditions.h"

#define kBlioViewSettingsGreenButton [UIColor colorWithRed:0.053 green:0.613 blue:0.000 alpha:1.000]//[UIColor colorWithRed:0.302 green:0.613 blue:0.289 alpha:1.000]
#define kBlioViewSettingsPopverBlueButton [UIColor colorWithRed:0.100 green:0.152 blue:0.326 alpha:1.000]

static const CGFloat kBlioViewSettingsRowSpacing = 14;
static const CGFloat kBlioViewSettingsYInset = 22;
static const CGFloat kBlioViewSettingsXInset = 20;
static const CGFloat kBlioViewSettingsSegmentButtonHeight = 36;
static const CGFloat kBlioViewSettingsLabelWidth = 93;
static const CGFloat kBlioViewSettingsDoneButtonHeight = 44;

@interface BlioViewSettingsContentsView()

@property (nonatomic, retain) UIImage *tapTurnOnImage;
@property (nonatomic, retain) UIImage *tapTurnOffImage;
@property (nonatomic, retain) UIImage *lockRotationImage;
@property (nonatomic, retain) UIImage *unlockRotationImage;
@end

@implementation BlioViewSettingsContentsView

@synthesize fontSizeLabel;
@synthesize pageColorLabel;
@synthesize pageLayoutSegment;
@synthesize fontSizeSegment;
@synthesize pageColorSegment;
@synthesize lockButtonSegment;
@synthesize doneButton;
@synthesize tapTurnOnImage, tapTurnOffImage, lockRotationImage, unlockRotationImage;
@synthesize viewSettingsDelegate;

- (void)dealloc {
    self.fontSizeLabel = nil;
    self.pageColorLabel = nil;
    self.pageLayoutSegment = nil;
    self.fontSizeSegment = nil;
    self.pageColorSegment = nil;
    self.lockButtonSegment = nil;
    self.doneButton = nil;
    self.tapTurnOnImage = nil;
    self.tapTurnOffImage = nil;
    self.lockRotationImage = nil;
    self.unlockRotationImage = nil;
    self.viewSettingsDelegate = nil;
    [super dealloc];
}

- (void)displayPageAttributes {
    BOOL showFontSize = NO;
    BOOL showPageColor = NO;
    
    if ([(NSObject *)self.viewSettingsDelegate respondsToSelector:@selector(shouldShowFontSizeSettings)]) {
        showFontSize = [self.viewSettingsDelegate shouldShowFontSizeSettings];
    }
    
    if ([(NSObject *)self.viewSettingsDelegate respondsToSelector:@selector(shouldShowPageColorSettings)]) {
        showPageColor = [self.viewSettingsDelegate shouldShowPageColorSettings];
    }
    
    if (showFontSize) {
        self.fontSizeLabel.enabled = YES;
        self.fontSizeSegment.enabled = YES;
        self.fontSizeSegment.alpha = 1.0f;
		self.fontSizeLabel.accessibilityLabel = self.fontSizeLabel.text;
    } else {
        self.fontSizeLabel.enabled = NO;
        self.fontSizeSegment.enabled = NO;
        self.fontSizeSegment.alpha = 0.35f;
		self.fontSizeLabel.accessibilityLabel = [NSString stringWithFormat:@"%@ (%@)", self.fontSizeLabel.text, NSLocalizedString(@"disabled",@"\"disabled\" suffix for accessibility labels")];        
	}
    
    if (showPageColor) {
        self.pageColorLabel.enabled = YES;
        self.pageColorSegment.enabled = YES;
        self.pageColorSegment.alpha = 1.0f;
		self.pageColorLabel.accessibilityLabel = self.pageColorLabel.text;
    } else {
        self.pageColorLabel.enabled = NO;
        self.pageColorSegment.enabled = NO;
        self.pageColorSegment.alpha = 0.35f;
		self.pageColorLabel.accessibilityLabel = [NSString stringWithFormat:@"%@ (%@)", self.pageColorLabel.text, NSLocalizedString(@"disabled",@"\"disabled\" suffix for accessibility labels")];
	} 
    
	UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

- (id)initWithDelegate:(id)newDelegate {
        
	if ((self = [super initWithFrame:CGRectZero])) {
        self.viewSettingsDelegate = newDelegate;
        UIFont *defaultFont = [UIFont boldSystemFontOfSize:12.0f];
        UIColor *white = [UIColor whiteColor];
        UIEdgeInsets inset = UIEdgeInsetsMake(0, 2, 2, 2);
        UIImage *plainImage = [UIImage imageWithIcon:[UIImage imageNamed:@"icon-page.png"] string:@"Flowed" font:defaultFont color:white textInset:inset];
        UIImage *layoutImage = [UIImage imageWithIcon:[UIImage imageNamed:@"icon-layout.png"] string:@"Fixed" font:defaultFont color:white textInset:inset];
        UIImage *speedImage = [UIImage imageWithIcon:[UIImage imageNamed:@"icon-speedread.png"] string:@"Fast" font:defaultFont color:white textInset:inset];
        
        NSArray *segmentImages = [NSArray arrayWithObjects:
                                  plainImage,
                                  layoutImage,
                                  speedImage,
                                  nil];
        
        BlioAccessibilitySegmentedControl *aLayoutSegmentedControl = [[BlioAccessibilitySegmentedControl alloc] initWithItems:segmentImages];
        aLayoutSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            aLayoutSegmentedControl.tintColor = [UIColor darkGrayColor];
        } else {
            aLayoutSegmentedControl.tintColor = kBlioViewSettingsPopverBlueButton;
        }
        
        [[aLayoutSegmentedControl imageForSegmentAtIndex:0] setAccessibilityLabel:NSLocalizedString(@"Flowed layout", @"Accessibility label for View Settings Flowed Layout button")];
        [[aLayoutSegmentedControl imageForSegmentAtIndex:0] setAccessibilityHint:NSLocalizedString(@"Switches to the flowed text view.", @"Accessibility hint for View Settings Flowed Layout button")];
        [[aLayoutSegmentedControl imageForSegmentAtIndex:1] setAccessibilityLabel:NSLocalizedString(@"Fixed layout", @"Accessibility label for View Settings Fixed Layout button")];
        [[aLayoutSegmentedControl imageForSegmentAtIndex:1] setAccessibilityHint:NSLocalizedString(@"Switches to the fixed layout view.", @"Accessibility hint for View Settings Fixed Layout button")];
        [[aLayoutSegmentedControl imageForSegmentAtIndex:2] setAccessibilityLabel:NSLocalizedString(@"Fast layout", @"Accessibility label for View Settings Fast Layout button")];
        [[aLayoutSegmentedControl imageForSegmentAtIndex:2] setAccessibilityHint:NSLocalizedString(@"Switches to the fast reading view.", @"Accessibility hint for View Settings Fast Layout button")];
        
		if (![self.viewSettingsDelegate reflowEnabled]) {
			[aLayoutSegmentedControl setEnabled:NO forSegmentAtIndex:0];
			[[aLayoutSegmentedControl imageForSegmentAtIndex:0] setAccessibilityLabel:[NSString stringWithFormat:@"%@ (%@)",[aLayoutSegmentedControl imageForSegmentAtIndex:0].accessibilityLabel,NSLocalizedString(@"disabled",@"\"disabled\" suffix for accessibility labels")]];
		}		
		if (![self.viewSettingsDelegate fixedViewEnabled]) {
			[aLayoutSegmentedControl setEnabled:NO forSegmentAtIndex:1];
			[[aLayoutSegmentedControl imageForSegmentAtIndex:1] setAccessibilityLabel:[NSString stringWithFormat:@"%@ (%@)",[aLayoutSegmentedControl imageForSegmentAtIndex:1].accessibilityLabel,NSLocalizedString(@"disabled",@"\"disabled\" suffix for accessibility labels")]];
		}		
        [self addSubview:aLayoutSegmentedControl];
        self.pageLayoutSegment = aLayoutSegmentedControl;
        [aLayoutSegmentedControl release];
        
        [aLayoutSegmentedControl setSelectedSegmentIndex:[self.viewSettingsDelegate currentPageLayout]];
        
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
        
        BlioAccessibilitySegmentedControl *aFontSizeSegmentedControl = [[BlioAccessibilitySegmentedControl alloc] initWithItems:fontSizeTitles];    
        aFontSizeSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            aFontSizeSegmentedControl.tintColor = [UIColor darkGrayColor];
        } else {
            aFontSizeSegmentedControl.tintColor = kBlioViewSettingsPopverBlueButton;
        }
        
        [aFontSizeSegmentedControl setContentOffset:CGSizeMake(0, 2) forSegmentAtIndex:0];
        [aFontSizeSegmentedControl setContentOffset:CGSizeMake(0, 1) forSegmentAtIndex:1];
        [aFontSizeSegmentedControl setContentOffset:CGSizeMake(0, 0) forSegmentAtIndex:2];
        [aFontSizeSegmentedControl setContentOffset:CGSizeMake(0, -1) forSegmentAtIndex:3];
        
        [[aFontSizeSegmentedControl imageForSegmentAtIndex:0] setAccessibilityLabel:NSLocalizedString(@"Smallest font size", @"Accessibility label for View Settings Smallest Font Size button")];
        [[aFontSizeSegmentedControl imageForSegmentAtIndex:1] setAccessibilityLabel:NSLocalizedString(@"Smaller font size", @"Accessibility label for View Settings Smaller Font Size button")];
        [[aFontSizeSegmentedControl imageForSegmentAtIndex:2] setAccessibilityLabel:NSLocalizedString(@"Normal font size", @"Accessibility label for View Settings Normal Font Size button")];
        [[aFontSizeSegmentedControl imageForSegmentAtIndex:3] setAccessibilityLabel:NSLocalizedString(@"Larger font size", @"Accessibility label for View Settings Larger Font Size button")];
        [[aFontSizeSegmentedControl imageForSegmentAtIndex:4] setAccessibilityLabel:NSLocalizedString(@"Largest font size", @"Accessibility label for View Settings Largest Font Size button")];
        
        [self addSubview:aFontSizeSegmentedControl];
        self.fontSizeSegment = aFontSizeSegmentedControl;
        [aFontSizeSegmentedControl release];
        
        [aFontSizeSegmentedControl setSelectedSegmentIndex:[self.viewSettingsDelegate currentFontSize]];
        
        [self.fontSizeSegment addTarget:self.viewSettingsDelegate action:@selector(changeFontSize:) forControlEvents:UIControlEventValueChanged];
        
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
        
        BlioAccessibilitySegmentedControl *aPageColorSegmentedControl = [[BlioAccessibilitySegmentedControl alloc] initWithItems:pageColorTitles];
        aPageColorSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            aPageColorSegmentedControl.tintColor = [UIColor darkGrayColor];
        } else {
            aPageColorSegmentedControl.tintColor = kBlioViewSettingsPopverBlueButton;
        }
        
        [[aPageColorSegmentedControl imageForSegmentAtIndex:0] setAccessibilityLabel:NSLocalizedString(@"White page color", @"Accessibility label for View Settings White Page Color button")];
        [[aPageColorSegmentedControl imageForSegmentAtIndex:1] setAccessibilityLabel:NSLocalizedString(@"Black page color", @"Accessibility label for View Settings Black Page Color button")];
        [[aPageColorSegmentedControl imageForSegmentAtIndex:2] setAccessibilityLabel:NSLocalizedString(@"Neutral page color", @"Accessibility label for View Settings Neutral Page Color button")];
        
        [self addSubview:aPageColorSegmentedControl];
        self.pageColorSegment = aPageColorSegmentedControl;
        [aPageColorSegmentedControl release];
        
        [aPageColorSegmentedControl setSelectedSegmentIndex:[self.viewSettingsDelegate currentPageColor]];
        
        [self.pageColorSegment addTarget:self.viewSettingsDelegate action:@selector(changePageColor:) forControlEvents:UIControlEventValueChanged];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            
            BlioAccessibilitySegmentedControl *aLockButtonSegmentedControl = [[BlioAccessibilitySegmentedControl alloc] init];
            aLockButtonSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                aLockButtonSegmentedControl.tintColor = [UIColor darkGrayColor];
            } else {
                aLockButtonSegmentedControl.tintColor = kBlioViewSettingsPopverBlueButton;
            }
            aLockButtonSegmentedControl.momentary = YES;
            [self addSubview:aLockButtonSegmentedControl];
            self.lockButtonSegment = aLockButtonSegmentedControl;
            [aLockButtonSegmentedControl release];
            
            self.unlockRotationImage = [UIImage imageWithIcon:[UIImage imageNamed:@"icon-lock.png"] string:@"Unlock Rotation" font:defaultFont color:white textInset:inset];
            self.lockRotationImage = [UIImage imageWithIcon:[UIImage imageNamed:@"icon-lock.png"] string:@"Lock Rotation" font:defaultFont color:white textInset:inset];
            
            BOOL currentLock = [self.viewSettingsDelegate isRotationLocked];
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
            
            UIButton *aDoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
            aDoneButton.showsTouchWhenHighlighted = NO;
            [aDoneButton setTitle:NSLocalizedString(@"Done",@"\"Done\" bar button") forState:UIControlStateNormal];
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
        }
        
        [self displayPageAttributes];
	}
	return self;
}

- (CGFloat)contentsHeight {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return kBlioViewSettingsYInset * 1 + kBlioViewSettingsRowSpacing*4 + kBlioViewSettingsSegmentButtonHeight*4 + kBlioViewSettingsDoneButtonHeight;
    } else {
        return kBlioViewSettingsYInset * 2 + kBlioViewSettingsRowSpacing*3 + kBlioViewSettingsSegmentButtonHeight*3;
    }
}

- (void)layoutSubviews {
    CGFloat yInset;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        yInset = kBlioViewSettingsYInset;
    } else {
        yInset = kBlioViewSettingsYInset/2.0f;
    }
    
    [self.pageLayoutSegment setFrame:CGRectMake(kBlioViewSettingsXInset, yInset, CGRectGetWidth(self.bounds) - 2*kBlioViewSettingsXInset, kBlioViewSettingsSegmentButtonHeight)];
    [self.fontSizeLabel setFrame:CGRectMake(kBlioViewSettingsXInset, CGRectGetMaxY([self.pageLayoutSegment frame]) + kBlioViewSettingsRowSpacing, kBlioViewSettingsLabelWidth, kBlioViewSettingsSegmentButtonHeight)];
    [self.fontSizeSegment setFrame:CGRectMake(CGRectGetMaxX([self.fontSizeLabel frame]), CGRectGetMinY([self.fontSizeLabel frame]), CGRectGetWidth(self.bounds) - CGRectGetMaxX([self.fontSizeLabel frame]) - kBlioViewSettingsXInset, kBlioViewSettingsSegmentButtonHeight)];
    [self.pageColorLabel setFrame:CGRectMake(kBlioViewSettingsXInset, CGRectGetMaxY([self.fontSizeSegment frame]) + kBlioViewSettingsRowSpacing, kBlioViewSettingsLabelWidth, kBlioViewSettingsSegmentButtonHeight)];
    [self.pageColorSegment setFrame:CGRectMake(CGRectGetMaxX([self.pageColorLabel frame]), CGRectGetMinY([self.pageColorLabel frame]), CGRectGetWidth(self.bounds) - CGRectGetMaxX([self.pageColorLabel frame]) - kBlioViewSettingsXInset, kBlioViewSettingsSegmentButtonHeight)];
    [self.lockButtonSegment setFrame:CGRectMake(kBlioViewSettingsXInset, CGRectGetMaxY([self.pageColorSegment frame]) + kBlioViewSettingsRowSpacing, (CGRectGetWidth(self.bounds) - 2 * kBlioViewSettingsXInset - kBlioViewSettingsRowSpacing)/2.0f, kBlioViewSettingsSegmentButtonHeight)];
    [self.doneButton setFrame:CGRectMake(kBlioViewSettingsXInset, CGRectGetMaxY([self.lockButtonSegment frame]) + kBlioViewSettingsRowSpacing, CGRectGetWidth(self.bounds) - 2 * kBlioViewSettingsXInset, kBlioViewSettingsDoneButtonHeight)];

    [super layoutSubviews];
}

- (void)changePageLayout:(id)sender {
    
    [self.viewSettingsDelegate changePageLayout:sender];
    
    [self displayPageAttributes];
    
}

- (void)changeLockRotation:(id)sender {
    [self.viewSettingsDelegate changeLockRotation];
    
    BOOL currentLock = [self.viewSettingsDelegate isRotationLocked];
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


- (void)dismissSheet:(id)sender {
    [self.viewSettingsDelegate dismissViewSettings:self];
}

@end
