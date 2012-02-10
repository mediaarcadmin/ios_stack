//
//  BookViewController.m
//  libEucalyptus
//
//  Created by James Montgomerie on 09/05/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "BlioBookViewController.h"
#import <libEucalyptus/THNavigationButton.h>
#import <libEucalyptus/THUIDeviceAdditions.h>
#import <libEucalyptus/THPair.h>
#import <libEucalyptus/THEventCapturingWindow.h>
#import <libEucalyptus/EucBookTitleView.h>
#import "BlioBookView.h"
#import "BlioFlowView.h"
#import "BlioLayoutView.h"
#import "BlioSpeedReadView.h"
#import "BlioContentsTabViewController.h"
#import "BlioLightSettingsViewController.h"
#import "BlioBookmark.h"
#import "BlioAppSettingsConstants.h"
#import "BlioAlertManager.h"
#import "BlioBookManager.h"
#import "BlioBeveledView.h"
#import "BlioViewSettingsPopover.h"
#import "BlioViewSettingsContentsView.h"
#import "BlioModalPopoverController.h"
#import "BlioBookSearchPopoverController.h"
#import "Reachability.h"
#import "BlioStoreManager.h"
#import "UIButton+BlioAdditions.h"
#import "BlioUIImageAdditions.h"
#import "BlioPurchaseVoicesViewController.h"

static const CGFloat kBlioBookSliderPreviewWidthPad = 180;
static const CGFloat kBlioBookSliderPreviewHeightPad = 180;
static const CGFloat kBlioBookSliderPreviewWidthPhone = 180;
static const CGFloat kBlioBookSliderPreviewHeightPhone = 180;
static const CGFloat kBlioBookSliderPreviewAnchorOffset = 20;
static const CGFloat kBlioBookSliderPreviewPhoneLandscapeOffset = 26;

static const CGFloat kBlioBookSliderPreviewShadowRadius = 20;
static const CGFloat kBlioBookSliderPreviewEdgeInset = 8;

static const NSUInteger kBlioMaxBookmarkTextLength = 50;

static NSString * const kBlioLastLayoutDefaultsKey = @"lastLayout";
static NSString * const kBlioLastFontNameDefaultsKey = @"lastFontName";
static NSString * const kBlioLastFontSizeIndexDefaultsKey = @"lastFontSize";
static NSString * const kBlioLastJustificationDefaultsKey = @"lastJustification";
static NSString * const kBlioLastPageColorDefaultsKey = @"lastPageColor";
static NSString * const kBlioLastLockRotationDefaultsKey = @"lastLockRotation";

static NSString * const kBlioBookViewControllerCoverPopAnimation = @"BlioBookViewControllerCoverPopAnimation";
static NSString * const kBlioBookViewControllerCoverFadeAnimation = @"BlioBookViewControllerCoverFadeAnimation";
static NSString * const kBlioBookViewControllerCoverShrinkAnimation = @"BlioBookViewControllerCoverShrinkAnimation";

typedef enum {
    kBlioLibraryAddBookmarkAction = 0,
    kBlioLibraryAddNoteAction = 1,
} BlioLibraryAddActions;

typedef enum {
    kBlioLibraryToolbarsStateNoneVisible = 0,
    kBlioLibraryToolbarsStateStatusBarVisible,
    kBlioLibraryToolbarsStateToolbarsVisible,
    kBlioLibraryToolbarsStateStatusBarAndToolbarsVisible,
    kBlioLibraryToolbarsStatePauseButtonVisible,
} BlioLibraryToolbarsState;

static const CGFloat kBlioFontSizesArray[] = { 14, 16, 19, 24, 32, 41 };
static const CGFloat kBlioSpeedReadFontPointSizeArray[] = { 20.0f, 45.0f, 70.0f, 95.0f, 120.0f };

static NSString * const kBlioFontPageTextureNamesArray[] = { @"paper-white.png", @"paper-black.png", @"paper-neutral.png" };
static const BOOL kBlioFontPageTexturesAreDarkArray[] = { NO, YES, NO };

@interface BlioBookViewController ()

@property (nonatomic, retain) UIView *rootView;

@property (nonatomic, retain) BlioBookSearchViewController *searchViewController;
@property (nonatomic, retain) BlioViewSettingsSheet *viewSettingsSheet;
@property (nonatomic, retain) BlioViewSettingsPopover*viewSettingsPopover;
@property (nonatomic, retain) BlioModalPopoverController *contentsPopover;
@property (nonatomic, retain) BlioModalPopoverController *searchPopover;
@property (nonatomic, retain) UIBarButtonItem *contentsButton;
@property (nonatomic, retain) UIBarButtonItem *viewSettingsButton;
@property (nonatomic, retain) UIBarButtonItem *searchButton;
@property (nonatomic, retain) UIBarButtonItem *backButton;
@property (nonatomic, retain) NSMutableArray *historyStack;
@property (nonatomic, retain) BlioBookSliderPreview *thumbPreview;

@property (nonatomic, retain) UIPopoverController *wordToolPopoverController;

@property (nonatomic, retain) NSArray *fontDisplayNames;
@property (nonatomic, retain) NSDictionary *fontDisplayNameToFontName;

- (NSArray *)_toolbarItemsWithTTSInstalled:(BOOL)installed enabled:(BOOL)enabled;
- (void)setPageJumpSliderPreview;
- (void) _updatePageJumpLabelWithLabel:(NSString *)newLabel;
- (void) _updatePageJumpLabelForPercentage:(float)percentage;
- (void) _updatePageJumpLabelForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;
- (void) updatePageJumpPanelForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated;
- (void)displayNote:(NSManagedObject *)note atRange:(BlioBookmarkRange *)range animated:(BOOL)animated;
- (void) togglePageJumpPanel;
- (void)layoutPageJumpView;
- (void)setNavigationBarButtonsForInterfaceOrientation:(UIInterfaceOrientation)orientation;
- (void)updateBookmarkButton;

@end

@interface BlioBookSliderPreview : UIView {
	UIImageView *thumbImage;
}

- (void)setThumb:(UIImage *)thumb;
- (void)setThumbAnchorPoint:(CGPoint)anchor;
- (void)showThumb:(BOOL)show;

@end

@interface BlioBookSlider : UISlider {
    BOOL touchInProgress;
    BlioBookViewController *bookViewController;
}

@property (nonatomic) BOOL touchInProgress;
@property (nonatomic, assign) BlioBookViewController *bookViewController;

@end

@interface BlioBookViewController()

- (void)setPreviewThumb:(UIImage *)thumb;

- (void)animateCoverPop;
- (void)animateCoverShrink;
- (void)animateCoverFade;
- (void)initialiseControls;
- (void)initialisePageJumpPanel;
- (void)uninitialisePageJumpPanel;
- (void)updatePageJumpPanelVisibility;
- (void)initialiseBookView;
- (void)uninitialiseBookView;
@end

@implementation BlioBookViewController

@synthesize rootView = _rootView;

@synthesize book = _book;
@synthesize bookView = _bookView;
@synthesize bookmarkButton = _bookmarkButton;
@synthesize pauseMask = _pauseMask;
@synthesize pauseButton = _pauseButton;

@synthesize returnToNavigationBarStyle = _returnToNavigationBarStyle;
@synthesize returnToStatusBarStyle = _returnToStatusBarStyle;
@synthesize returnToNavigationBarHidden = _returnToNavigationBarHidden;
@synthesize returnToStatusBarHidden = _returnToStatusBarHidden;

@synthesize currentPageColor = _currentPageColor;

@synthesize audioPlaying = _audioPlaying;
@synthesize audioEnabled = _audioEnabled;
@synthesize managedObjectContext = _managedObjectContext;

@synthesize rotationLocked;

@synthesize searchViewController;
@synthesize delegate;
@synthesize coverView;
@synthesize historyStack;
@synthesize thumbPreview;
@synthesize viewSettingsSheet, viewSettingsPopover, contentsPopover, searchPopover, contentsButton, viewSettingsButton, searchButton, backButton;

@synthesize wordToolPopoverController;

@synthesize fontDisplayNames, fontDisplayNameToFontName;

+ (void)initialize {
    if(self == [BlioBookViewController class]) {
        NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                     kBlioOriginalFontName, kBlioLastFontNameDefaultsKey,
                                     [NSNumber numberWithInteger:kBlioPageLayoutPageLayout], kBlioLastLayoutDefaultsKey,
                                     [NSNumber numberWithInteger:2], kBlioLastFontSizeIndexDefaultsKey,
                                     [NSNumber numberWithBool:UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad], kBlioLandscapeTwoPagesDefaultsKey,
                                     nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    }
} 	

- (BOOL)toolbarsVisibleAfterAppearance 
{
    return !self.hidesBottomBarWhenPushed;
}

- (void)setToolbarsVisibleAfterAppearance:(BOOL)visible 
{
    self.hidesBottomBarWhenPushed = !visible;
}

- (void)setReturnToNavigationBarStyle:(UIBarStyle)barStyle
{
    _returnToNavigationBarStyle = barStyle;
    _overrideReturnToNavigationBarStyle = YES;
}

- (void)setReturnToStatusBarStyle:(UIStatusBarStyle)barStyle
{
    _returnToStatusBarStyle = barStyle;
    _overrideReturnToStatusBarStyle = YES;
}

- (void)setReturnToNavigationBarHidden:(BOOL)barHidden
{
    _returnToNavigationBarHidden = barHidden;
    _overrideReturnToNavigationBarHidden = YES;
}

- (void)setReturnToStatusBarHidden:(BOOL)barHidden
{
    _returnToStatusBarHidden = barHidden;
    _overrideReturnToStatusBarHidden = YES;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self init];
}

- (id)initWithBook:(BlioBook *)newBook delegate:(id <BlioCoverViewDelegate>)aDelegate {
    if (!(newBook || aDelegate)) {
        [self release];
        return nil;
    }
    
    if ((self = [super initWithNibName:nil bundle:nil])) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingWillDeleteBookNotification:) name:BlioProcessingWillDeleteBookNotification object:nil];
        self.book = newBook;
        self.delegate = aDelegate;
        self.wantsFullScreenLayout = YES;
        self.historyStack = [NSMutableArray array];
        
        _firstAppearance = YES;
        [self initialiseControls];
        
        self.coverView = [self.delegate coverViewViewForOpening];
        
        if (self.coverView) {
            [self animateCoverPop];
            [self setToolbarsVisibleAfterAppearance:NO];
        } else {
            coverOpened = YES;
            [self setToolbarsVisibleAfterAppearance:YES];
        }
        
        if([[UIDevice currentDevice] compareSystemVersion:@"4.0"] >= NSOrderedSame) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    } 
    
    return self;
} 
 
- (void)initialiseControls {
//	if ([[self.book valueForKey:@"productType"] intValue] == BlioProductTypePreview) {
//		UIButton * buyNowButton = [UIButton buyButton];
//		[buyNowButton setTitle:NSLocalizedString(@"BUY NOW",@"\"BUY NOW\" button label") forState:UIControlStateNormal];
//		CGSize textSize = [buyNowButton.titleLabel.text sizeWithFont:buyNowButton.titleLabel.font];
//		CGFloat buttonHeight = 30;
//		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
//			buttonHeight = 24;
//		}
//		
//		buyNowButton.bounds = CGRectMake(0, 0, textSize.width + 30, buttonHeight);
//		[buyNowButton setAccessibilityHint:NSLocalizedString(@"Opens the book details page within the Blio web store.",@"\"BUY NOW\" button accessibility hint")];
//		[buyNowButton addTarget:self action:@selector(buyBook:) forControlEvents:UIControlEventTouchUpInside];
//		self.navigationItem.titleView = buyNowButton;
//	}
//	else {
		EucBookTitleView *titleView = [[EucBookTitleView alloc] init];
		CGRect frame = titleView.frame;
		frame.size.width = [[UIScreen mainScreen] bounds].size.width;
		[titleView setFrame:frame];
		titleView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
		self.navigationItem.titleView = titleView;
		[titleView release];
//    }
    
    self.audioPlaying = NO;
    
    _TTSEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kBlioTTSEnabledDefaultsKey];
    
    if (_TTSEnabled) {
        
        if (![self.book hasAudiobook] && (![self.book hasTTSRights] || !([self.book hasTextFlow] || [self.book hasEPub]))) {
			self.audioEnabled = NO;
            self.toolbarItems = [self _toolbarItemsWithTTSInstalled:YES enabled:NO];
			
        }
		else {
			self.audioEnabled = YES;
            self.toolbarItems = [self _toolbarItemsWithTTSInstalled:YES enabled:YES];
            
            if ([self.book hasAudiobook]) {
				if (_audioBookManager) [_audioBookManager release];
				_audioBookManager = [[BlioAudioBookManager alloc] initWithBookID:self.book.objectID];        
			}
			// This is not an "else" because the above initialization could have discovered
			// a corrupt audiobook, in which case hasAudiobook would now be false.
			if ( ![self.book hasAudiobook] ) {			
                _acapelaAudioManager = [[BlioAcapelaAudioManager sharedAcapelaAudioManager] retain];
                if ( _acapelaAudioManager != nil )  {
                    [_acapelaAudioManager setPageChanged:YES];
                    [_acapelaAudioManager setDelegate:self];
                } 
            }
            [[AVAudioSession sharedInstance] setDelegate:self];
        }
    } else {
        self.toolbarItems = [self _toolbarItemsWithTTSInstalled:NO enabled:NO];
    }
}

- (NSString *)sanitizedFontNameForName:(NSString *)fontName
{
    // Check the font exists.
    if([fontName isEqualToString:kBlioOriginalFontName] || 
       [UIFont fontWithName:fontName size:12] != nil) {
        return fontName;
    }
    return kBlioOriginalFontName;
}

- (void)initialiseBookView {
    BlioPageLayout lastLayout = [[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastLayoutDefaultsKey];
    
    if (!([self.book hasEPub] || [self.book hasTextFlow]) && (lastLayout == kBlioPageLayoutSpeedRead)) {
        lastLayout = kBlioPageLayoutPlainText;
    }            
    if (![self.book fixedViewEnabled] && (lastLayout == kBlioPageLayoutPageLayout)) {
        lastLayout = kBlioPageLayoutPlainText;
    } else if (((![self.book hasEPub] && ![self.book hasTextFlow]) || ![self.book reflowEnabled]) && (lastLayout == kBlioPageLayoutPlainText)) {
        lastLayout = kBlioPageLayoutPageLayout;
    }

    switch (lastLayout) {
        case kBlioPageLayoutSpeedRead: {
            if ([self.book hasEPub] || [self.book hasTextFlow]) {
                BlioSpeedReadView *aBookView = [[BlioSpeedReadView alloc] initWithFrame:self.view.bounds 
                                                                               delegate:self
                                                                                 bookID:self.book.objectID
                                                                               animated:YES];
                self.bookView = aBookView; 
                [aBookView release];
				for (UIBarButtonItem* item in self.toolbarItems)
					if (item.action==@selector(toggleAudio:))
						[item setEnabled:NO];
            }   
        }
            break;
        case kBlioPageLayoutPageLayout: {
            if ([self.book hasPdf] || [self.book hasXps]) {
                BlioLayoutView *aBookView = [[BlioLayoutView alloc] initWithFrame:self.view.bounds 
                                                                         delegate:self
                                                                           bookID:self.book.objectID
                                                                         animated:YES];
                self.bookView = aBookView;
                [aBookView release];
            }
        }
            break;
        default: {
            if ([self.book hasEPub] || [self.book hasTextFlow]) {
                BlioFlowView *aBookView = [[BlioFlowView alloc] initWithFrame:self.view.bounds 
                                                                     delegate:self
                                                                       bookID:self.book.objectID
                                                                     animated:YES];
                self.bookView = aBookView;
                [aBookView release];
            }
        } 
            break;
    }
    
    self.currentPageColor = [[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastPageColorDefaultsKey];
    if([self.bookView respondsToSelector:@selector(setFontName:)]) {
        self.bookView.fontName = [self sanitizedFontNameForName:[[NSUserDefaults standardUserDefaults] objectForKey:kBlioLastFontNameDefaultsKey]];
    }
    if([self.bookView respondsToSelector:@selector(setFontSizeIndex:)]) {
        NSUInteger fontSizeIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastFontSizeIndexDefaultsKey];
        self.bookView.fontSizeIndex = MIN([self fontSizeCount] - 1, fontSizeIndex);
    }
    if([self.bookView respondsToSelector:@selector(setJustification:)]) {
        self.bookView.justification = [[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastJustificationDefaultsKey];
    }
    if([self.bookView respondsToSelector:@selector(setTwoUp:)]) {
        if(lastLayout == kBlioPageLayoutPageLayout && [self.book twoPageSpread]) {
            self.bookView.twoUp = kBlioTwoUpAlways;
        } else {
            self.bookView.twoUp = [[NSUserDefaults standardUserDefaults] boolForKey:kBlioLandscapeTwoPagesDefaultsKey] ? kBlioTwoUpLandscape : kBlioTwoUpNever;
        }
    }
    if([self.bookView respondsToSelector:@selector(setShouldTapZoom:)]) {
        self.bookView.shouldTapZoom = [[NSUserDefaults standardUserDefaults] boolForKey:kBlioTapZoomsDefaultsKey];
    }
    
    bookReady = YES;
}

- (void)uninitialiseBookView {
    self.bookView = nil;
    self.rootView = nil;
    bookReady = NO;
}

- (void)animateCoverPop {
    CGRect coverFrame = [self.delegate coverViewRectForOpening];
    [self.coverView setFrame:coverFrame];
    UIViewController *controller = [self.delegate coverViewViewControllerForOpening];
    [controller.navigationController.view insertSubview:self.coverView belowSubview:controller.navigationController.toolbar];

    CGFloat zPosToolbar   = 1;
    CGFloat zPosNavBar    = 1;
    CGFloat zPosCoverOrig = 0;
        
    CGFloat fullScreenWidth = CGRectGetWidth(self.coverView.superview.bounds);
    CGFloat fullScreenHeight = CGRectGetHeight(self.coverView.superview.bounds);
    
    BOOL landscape = (fullScreenWidth > fullScreenHeight);
    
    if (landscape) {
        fullScreenHeight = fullScreenWidth * (fullScreenWidth / fullScreenHeight);
    }
    
    CGFloat fullScreenXScale = fullScreenWidth / CGRectGetWidth(self.coverView.frame);
    CGFloat fullScreenYScale = fullScreenHeight / CGRectGetHeight(self.coverView.frame);
    
    CGPoint midPosition = CGPointMake(fullScreenWidth/2.0f, fullScreenHeight / 2.0f);
    CGPoint finalPosition = CGPointMake(fullScreenWidth/2.0f, fullScreenHeight / 2.0f);
    
    if (landscape) {
        CGFloat landscapeScreenHeight = fullScreenWidth * (fullScreenWidth / fullScreenHeight);
        midPosition = CGPointMake(fullScreenWidth/2.0f, landscapeScreenHeight / 2.0f);
    }
    
    CGFloat xOffset = 0;
    CGFloat yOffset = 30;
    CGFloat offsetAngle = -2;
    
    if (CGRectGetMidX(self.coverView.frame) >= midPosition.x) {
        xOffset *= -1;
        offsetAngle *= -1;
    }
    
    if (CGRectGetMidY(self.coverView.frame) >= midPosition.y) {
        yOffset *= -1;
    }
    
    if (landscape) {
        if (CGRectGetMidY(self.coverView.frame) >= midPosition.y) {
            zPosNavBar = 0;
            zPosToolbar = 2;
            zPosCoverOrig = 1;
        } else {
            zPosNavBar = 2;
            zPosToolbar = 0;
            zPosCoverOrig = 1;
        }
    }
    
    CAKeyframeAnimation *positionAnim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    [positionAnim setValues:[NSArray arrayWithObjects:
                              [NSValue valueWithCGPoint:self.coverView.layer.position], 
                              [NSValue valueWithCGPoint:CGPointMake(midPosition.x + xOffset, midPosition.y + yOffset)], 
                              [NSValue valueWithCGPoint:CGPointMake(finalPosition.x, finalPosition.y)],
                              nil]];
    [positionAnim setKeyTimes:[NSArray arrayWithObjects:
                                     [NSNumber numberWithFloat:0],
                                     [NSNumber numberWithFloat:0.5f],
                                     [NSNumber numberWithFloat:1], 
                                     nil]];
    [positionAnim setTimingFunctions:[NSArray arrayWithObjects:
                                      [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                      [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                      [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                      nil]];
    
    CAKeyframeAnimation *scaleAndRotateAnim = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    [scaleAndRotateAnim setValues:[NSArray arrayWithObjects:
                              [NSValue valueWithCATransform3D:CATransform3DIdentity], 
                              [NSValue valueWithCATransform3D:CATransform3DConcat(CATransform3DMakeScale(2, 2, 1), CATransform3DMakeRotation(offsetAngle * M_PI / 180, 0, 0, 1))], 
                              [NSValue valueWithCATransform3D:CATransform3DConcat(CATransform3DMakeScale(2 + (fullScreenXScale - 2)/2.0f, 2 + (fullScreenYScale - 2)/2.0f, 1), CATransform3DMakeRotation(offsetAngle * 0.5f * M_PI / 180, 0, 0, 1))], 
                              [NSValue valueWithCATransform3D:CATransform3DMakeScale(fullScreenXScale, fullScreenYScale, 1)], 
                              nil]];
    [scaleAndRotateAnim setKeyTimes:[NSArray arrayWithObjects:
                                     [NSNumber numberWithFloat:0], 
                                     [NSNumber numberWithFloat:0.5f], 
                                     [NSNumber numberWithFloat:0.75f],
                                     [NSNumber numberWithFloat:1], 
                                     nil]];
    
    CAKeyframeAnimation *zPositionAnim = [CAKeyframeAnimation animationWithKeyPath:@"zPosition"];
    [zPositionAnim setValues:[NSArray arrayWithObjects:
                              [NSNumber numberWithFloat:zPosCoverOrig], 
                              [NSNumber numberWithFloat:zPosCoverOrig], 
                              [NSNumber numberWithFloat:3], 
                              [NSNumber numberWithFloat:3], 
                              nil]];
    [zPositionAnim setKeyTimes:[NSArray arrayWithObjects:
                               [NSNumber numberWithFloat:0],
                               [NSNumber numberWithFloat:0.5f],
                               [NSNumber numberWithFloat:0.5f],
                               [NSNumber numberWithFloat:1], 
                               nil]];
    
    CAAnimationGroup *groupAnim = [CAAnimationGroup animation];
    CGFloat popDuration = 1.0f;
    [groupAnim setAnimations:[NSArray arrayWithObjects:positionAnim, scaleAndRotateAnim, zPositionAnim,  nil]];
    [groupAnim setDuration:popDuration];
    [groupAnim setRemovedOnCompletion:NO];
    [groupAnim setFillMode:kCAFillModeForwards];
    [groupAnim setDelegate:self];
    [groupAnim setValue:kBlioBookViewControllerCoverPopAnimation forKey:@"name"];
    [self.coverView.layer addAnimation:groupAnim forKey:kBlioBookViewControllerCoverPopAnimation];
    
    CAKeyframeAnimation *textureAnim = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    [textureAnim setValues:[NSArray arrayWithObjects:
                            [NSNumber numberWithFloat:1], 
                            [NSNumber numberWithFloat:1],
                            [NSNumber numberWithFloat:0.5f],
                            [NSNumber numberWithFloat:0], 
                            nil]];
    [textureAnim setDuration:popDuration];
    [textureAnim setRemovedOnCompletion:NO];
    [textureAnim setFillMode:kCAFillModeForwards];
    [self.coverView.textureLayer addAnimation:textureAnim forKey:@"texturePop"];
    
    controller.navigationController.toolbar.layer.zPosition = zPosToolbar;
    controller.navigationController.navigationBar.layer.zPosition = zPosNavBar;

    [self performSelector:@selector(setStatusBarTranslucent) withObject:nil afterDelay:popDuration * 0.5f];
}

- (void)setStatusBarTranslucent {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
	} else {
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
	}
}

- (void)animateCoverShrink {
    if (!(bookReady && coverReady)) {
        [self performSelector:@selector(animateCoverShrink) withObject:nil afterDelay:0.2f];
        return;
    }
    
	if (![self bookView]) {
		[self.coverView removeFromSuperview];
		self.coverView = nil;
		_viewIsDisappearing = YES;
		[self.searchViewController removeFromControllerAnimated:YES];
		[self.navigationController popViewControllerAnimated:YES];
		
		if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
			[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		}
			
		return;
	}
    
    [self.rootView addSubview:self.coverView];
			
	CGRect coverRect = [[self bookView] firstPageRect];
    CGFloat coverRectXScale = CGRectGetWidth(coverRect) / CGRectGetWidth(self.coverView.frame);
    CGFloat coverRectYScale = CGRectGetHeight(coverRect) / CGRectGetHeight(self.coverView.frame);
	CGPoint center = CGPointMake(CGRectGetMidX(coverRect), CGRectGetMidY(coverRect));
    
    CABasicAnimation *shrinkAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
	CATransform3D scaleTransform = CATransform3DMakeScale(coverRectXScale, coverRectYScale, 1);
    [shrinkAnimation setToValue:[NSValue valueWithCATransform3D:scaleTransform]];
	CABasicAnimation *offsetAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    [offsetAnimation setToValue:[NSValue valueWithCGPoint:center]];
	CAAnimationGroup *coverAnim = [CAAnimationGroup animation];
	coverAnim.animations = [NSArray arrayWithObjects:shrinkAnimation, offsetAnimation, nil];
	
    if (CGRectEqualToRect(coverRect, self.coverView.frame)) {
        [coverAnim setDuration:0];
    } else {
        [coverAnim setDuration:0.5f];
    }
    [coverAnim setRemovedOnCompletion:NO];
    [coverAnim setFillMode:kCAFillModeForwards];
    [coverAnim setDelegate:self];
    [coverAnim setValue:kBlioBookViewControllerCoverShrinkAnimation forKey:@"name"];    
 
    [self.coverView.layer setPosition:[(CALayer *)[self.coverView.layer presentationLayer] position]];
    [self.coverView.layer setTransform:[(CALayer *)[self.coverView.layer presentationLayer] transform]];
    
    [self.coverView.layer removeAllAnimations];
    
    [self.coverView.layer addAnimation:coverAnim forKey:kBlioBookViewControllerCoverShrinkAnimation];        
}

- (void)animateCoverFade {   
    CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [fadeAnimation setToValue:[NSNumber numberWithFloat:0]];
    [fadeAnimation setDuration:0.5f];
    [fadeAnimation setValue:kBlioBookViewControllerCoverFadeAnimation forKey:@"name"];
    [fadeAnimation setDelegate:self];
    [fadeAnimation setRemovedOnCompletion:NO];
    [fadeAnimation setFillMode:kCAFillModeForwards];
    
    [self.coverView.layer setTransform:[(CALayer *)[self.coverView.layer presentationLayer] transform]];
    [self.coverView.layer setPosition:[(CALayer *)[self.coverView.layer presentationLayer] position]];
	
    [self.coverView.layer removeAllAnimations];
    [self.coverView.layer addAnimation:fadeAnimation forKey:kBlioBookViewControllerCoverFadeAnimation]; 
}

- (void)animationDidStart:(CAAnimation *)anim {
    if ([[anim valueForKey:@"name"] isEqualToString:kBlioBookViewControllerCoverPopAnimation]) {
        [self initialiseBookView];
        [self animateCoverShrink];
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if ([[anim valueForKey:@"name"] isEqualToString:kBlioBookViewControllerCoverPopAnimation]) {
        if ([self.delegate respondsToSelector:@selector(coverViewDidAnimatePop)]) {
            [self.delegate coverViewDidAnimatePop];
        }
        
        coverReady = YES;
        
        UIViewController *controller = [self.delegate coverViewViewControllerForOpening];
        [controller.navigationController pushViewController:self animated:NO];
                
    } else if ([[anim valueForKey:@"name"] isEqualToString:kBlioBookViewControllerCoverShrinkAnimation]) {
        if ([self.delegate respondsToSelector:@selector(coverViewDidAnimateShrink)]) {
            [self.delegate coverViewDidAnimateShrink];
        }
        
        [self animateCoverFade];
    } else if ([[anim valueForKey:@"name"] isEqualToString:kBlioBookViewControllerCoverFadeAnimation]) {
        if ([self.delegate respondsToSelector:@selector(coverViewDidAnimateFade)]) {
            [self.delegate coverViewDidAnimateFade];
        }
        
        [self.coverView removeFromSuperview];
        self.coverView = nil;
        
        BlioBookmarkPoint *implicitPoint = [self.book implicitBookmarkPoint];
        [self.bookView goToBookmarkPoint:implicitPoint animated:YES saveToHistory:NO];
        coverOpened = YES;
    }
}

- (NSArray *)_toolbarItemsWithTTSInstalled:(BOOL)installed enabled:(BOOL)enabled {
    
    NSMutableArray *readingItems = [NSMutableArray array];
    UIBarButtonItem *item;

    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];
	
    item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-back.png"]
                                            style:UIBarButtonItemStylePlain
                                           target:self 
                                           action:@selector(goBackInHistory)];
    
    [item setAccessibilityLabel:NSLocalizedString(@"Back", @"Accessibility label for Book View Controller Back button")];
	
    [readingItems addObject:item];
	item.enabled = NO;
	self.backButton = item;
    [item release]; 
	
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-contents.png"]
                                            style:UIBarButtonItemStylePlain
                                           target:self 
                                           action:@selector(showContents:)];
    [item setAccessibilityLabel:NSLocalizedString(@"Contents", @"Accessibility label for Book View Controller Contents button")];
    [item setAccessibilityHint:NSLocalizedString(@"Shows table of contents, bookmarks and notes.", @"Accessibility label for Book View Controller Contents hint")];
    self.contentsButton = item;
    [readingItems addObject:item];
    [item release];
		
	item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];
	
	if ([self.book hasSearch]) {
		item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-search.png"]
												style:UIBarButtonItemStylePlain
											   target:self 
											   action:@selector(search:)];
		[item setAccessibilityLabel:NSLocalizedString(@"Search", @"Accessibility label for Book View Controller Search button")];
		[item setAccessibilityTraits:UIAccessibilityTraitButton];
	}
	else {
		item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-search.png"]
												style:UIBarButtonItemStylePlain
											   target:nil 
											   action:nil];
		[item setEnabled:NO];
		[item setAccessibilityLabel:NSLocalizedString(@"Search", @"Accessibility label for Book View Controller Search button")];
		[item setAccessibilityTraits:UIAccessibilityTraitButton | UIAccessibilityTraitNotEnabled];
	}
    self.searchButton = item;
    [readingItems addObject:item];
    [item release];
    
		
    if (installed) {
        item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [readingItems addObject:item];
        [item release];  
        
        UIImage *audioItemImage;
        NSString *audioItemAccessibilityHint;
        if (enabled) {
            audioItemImage = [UIImage imageNamed:@"icon-play.png"];
            audioItemAccessibilityHint = NSLocalizedString(@"Starts audio playback.  While audio is playing, double tap again to stop.", @"Accessibility label for Book View Controller Play hint");
        } else {
            audioItemImage = [UIImage imageNamed:@"icon-noTTS.png"];
            audioItemAccessibilityHint = NSLocalizedString(@"Select and double tap the book page to read with VoiceOver.", @"Accessibility label for Book View Controller Audio unavailable button hint");
        }
        item = [[UIBarButtonItem alloc] initWithImage:audioItemImage
                                                style:UIBarButtonItemStylePlain
                                               target:self 
                                               action:@selector(toggleAudio:)];
        item.accessibilityLabel = NSLocalizedString(@"Play", @"Accessibility label for Book View Controller Play button");
        item.enabled = enabled;
        item.accessibilityHint = audioItemAccessibilityHint;
        
        UIAccessibilityTraits audioButtonAccessibiltyTraits = UIAccessibilityTraitButton | UIAccessibilityTraitPlaysSound;
        if([[UIDevice currentDevice] compareSystemVersion:@"4.0"] >= NSOrderedSame) {
            audioButtonAccessibiltyTraits |= UIAccessibilityTraitStartsMediaSession;
        }
        if(!enabled) {
            audioButtonAccessibiltyTraits |= UIAccessibilityTraitNotEnabled;
        }
        item.accessibilityTraits = audioButtonAccessibiltyTraits;
        
        [readingItems addObject:item];
        [item release];
    }
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-wrench.png"]
                                            style:UIBarButtonItemStylePlain
                                           target:self 
                                           action:@selector(showViewSettings:)];
    
    [item setAccessibilityLabel:NSLocalizedString(@"Reading Settings", @"Accessibility label for Book View Controller Reading Settings button")];
    self.viewSettingsButton = item;
    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];
    
    return readingItems;
}

- (void)setBookView:(UIView<BlioBookView> *)bookView
{
        
    if(_bookView != bookView) {
        if(_bookView) {
            [_bookView removeObserver:self forKeyPath:@"fontSizeIndex"];
            [_bookView removeObserver:self forKeyPath:@"currentBookmarkPoint"];
            if(_bookView.superview) {
                if ([_bookView wantsTouchesSniffed]) {
                    THEventCapturingWindow *window = (THEventCapturingWindow *)_bookView.window;
                    [window removeTouchObserver:self forView:_bookView];
                }
                
                if([_bookView respondsToSelector:@selector(didFinishReading)]) {
                    [_bookView performSelector:@selector(didFinishReading)];
                }
                
                [_bookView removeFromSuperview];
            }
        }
        
        [_bookView release];
        
        _bookView = [bookView retain];
        
        if(_bookView) {
            if(self.isViewLoaded) {
				if ([self.navigationItem.titleView isKindOfClass:[EucBookTitleView class]]) {
					EucBookTitleView *titleView = (EucBookTitleView *)self.navigationItem.titleView;
					[titleView setTitle:[self.book title]];
					[titleView setAuthor:[self.book authorsWithStandardFormat]];              
				}                
                if ([_bookView wantsTouchesSniffed]) {
                    [(THEventCapturingWindow *)self.rootView.window addTouchObserver:self forView:_bookView];            
                }                
                
                [self.rootView addSubview:_bookView];
                [self.rootView sendSubviewToBack:_bookView];
            }                        
            [_bookView addObserver:self 
                        forKeyPath:@"currentBookmarkPoint" 
                           options:NSKeyValueObservingOptionNew
                           context:nil];   
            [_bookView addObserver:self 
                        forKeyPath:@"fontSizeIndex" 
                           options:NSKeyValueObservingOptionNew
                           context:nil];   
        }
    }
}

- (void)_backButtonTapped
{
    _viewIsDisappearing = YES;
    [self.searchViewController removeFromControllerAnimated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)updatePageJumpPanelForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated
{
    if (_pageJumpSlider) {
        [_pageJumpSlider setValue:[_bookView percentageForBookmarkPoint:bookmarkPoint] animated:animated];
		if (_pageJumpSlider.touchInProgress) {
            [self setPageJumpSliderPreview];
        }
        [self _updatePageJumpLabelForBookmarkPoint:bookmarkPoint];
    }    
}

- (void)updatePageJumpPanelAnimated:(BOOL)animated
{
    [self updatePageJumpPanelForBookmarkPoint:self.bookView.currentBookmarkPoint animated:YES];
}

- (void)loadView 
{
    UIView *root = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    // Changed to grey background to match Layout View surround color when rotating
    root.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
    root.opaque = YES;    
    self.view = root;

    if(&UIAccessibilityPageScrolledNotification != NULL) {
        // There's a bug in the original implementation (iOS 4.2) of accessibility 
        // scrolling (i.e. supporting three-finger-swipe) in iOS that means that
        // it doesn't work unless the view that implements it is inside a 
        // UIScrollView, so we create an otherwise-inoperative UIScrollView here
        // to put our book view inside.
        // In the future, an extra && ![[UIDevice currentDevice] compareSystemVersion:<version where bug is fixed>] < NSOrderedSame
        // can be added to stop doing this when the bug is fixed.
        UIScrollView *fakeScrollView = [[UIScrollView alloc] initWithFrame:root.bounds];
        fakeScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        fakeScrollView.scrollEnabled = NO;
        fakeScrollView.delaysContentTouches = NO;
        fakeScrollView.canCancelContentTouches = NO;
        fakeScrollView.backgroundColor = root.backgroundColor;
        fakeScrollView.opaque = YES;    
        [root addSubview:fakeScrollView];
        self.rootView = fakeScrollView;
        [fakeScrollView release];
    } else {
        self.rootView = root;
    }
    
    [root release];
    
    if(coverOpened) {
        BlioBookmarkPoint *implicitPoint = [self.book implicitBookmarkPoint];
        [self initialiseBookView];
        [self.bookView goToBookmarkPoint:implicitPoint animated:NO saveToHistory:NO];
    }    
    
    UIView *aPauseMask = [[UIView alloc] initWithFrame:self.rootView.bounds];
    aPauseMask.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.rootView addSubview:aPauseMask];
    self.pauseMask = aPauseMask;
    aPauseMask.alpha = 0;
    [aPauseMask release];
    
    UIButton *aPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *pauseImage = [UIImage imageNamed:@"button-tts-pause.png"];
    [aPauseButton setBackgroundImage:pauseImage forState:UIControlStateNormal];
    [aPauseButton addTarget:self action:@selector(toggleAudio:) forControlEvents:UIControlEventTouchUpInside];
	CGRect buttonFrame = CGRectMake(3, CGRectGetHeight(root.frame) - pauseImage.size.height - 3, pauseImage.size.width, pauseImage.size.height);
    [aPauseButton setFrame:buttonFrame];
	[aPauseButton setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin];
    [aPauseButton setShowsTouchWhenHighlighted:YES];
    [aPauseButton setAccessibilityLabel:NSLocalizedString(@"Pause", @"Accessibility label for Book View Controller Pause button")];
    [aPauseButton setAccessibilityHint:NSLocalizedString(@"Pauses audio playback.", @"Accessibility label for Book View Controller Pause hint")];
    [aPauseMask addSubview:aPauseButton];
    self.pauseButton = aPauseButton;	
}

- (void)viewDidUnload
{   
    [self uninitialiseBookView];
    [self uninitialisePageJumpPanel];
    
    self.pauseMask = nil;
    self.pauseButton = nil;    
}

- (void)setNavigationBarButtonsForInterfaceOrientation:(UIInterfaceOrientation)orientation {
    
    CGFloat buttonHeight = 30;
    CGFloat buttonWidth = 41;

    // Toolbar buttons are 30 pixels high in portrait and 24 pixels high landscape
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && UIInterfaceOrientationIsLandscape(orientation)) {
        buttonHeight = 24;
        buttonWidth  = 33;
    }
    
    CGRect arrowFrame    = CGRectMake(0,0, 41, buttonHeight);
    CGRect bookmarkFrame = CGRectMake(0,0, buttonWidth, buttonHeight);
    
    UIButton *backArrow = [THNavigationButton leftNavigationButtonWithArrowInBarStyle:UIBarStyleBlackTranslucent frame:arrowFrame];

    [backArrow addTarget:self action:@selector(_backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [backArrow setAccessibilityLabel:NSLocalizedString(@"Library Back", @"Accessibility label for Book View Controller Library Back button")];

	backArrow.autoresizingMask = UIViewAutoresizingNone;
	
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backArrow];
    self.navigationItem.leftBarButtonItem = backItem;
    [backItem release];
    
    UIButton *bookmark = [[UIButton alloc] initWithFrame:bookmarkFrame];
	bookmark.autoresizingMask = UIViewAutoresizingNone;
    
    UIImage *add = [UIImage appleLikeBeveledImage:[UIImage imageNamed:@"icon-add"]];
    [bookmark setImage:add forState:UIControlStateNormal];
    [bookmark setImage:add forState:UIControlStateHighlighted];
    [bookmark setAccessibilityLabel:NSLocalizedString(@"Bookmark", @"Accessibility label for Book View Controller Bookmark button")];
    [bookmark setAccessibilityHint:NSLocalizedString(@"Adds bookmark for the current page.", @"Accessibility label for Book View Controller Add Bookmark hint")];
    [bookmark addTarget:self action:@selector(toggleBookmark:) forControlEvents:UIControlEventTouchUpInside];
    self.bookmarkButton = bookmark;
    [bookmark release];
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:self.bookmarkButton];
    [self.navigationItem setRightBarButtonItem:item];
    [item release];

}

- (void)viewWillAppear:(BOOL)animated
{
	if ([[UIApplication sharedApplication] respondsToSelector:@selector(beginReceivingRemoteControlEvents)]) {
//		NSLog(@"start receiving remote control events");
		[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
		[self becomeFirstResponder];
	}
    
    [self.navigationController.navigationBar addObserver:self 
                                              forKeyPath:@"bounds" 
                                                 options:NSKeyValueObservingOptionNew
                                                 context:nil]; 
    
    [self.navigationController.navigationBar addObserver:self 
                                              forKeyPath:@"center" 
                                                 options:NSKeyValueObservingOptionNew
                                                 context:nil]; 
    
    if(_firstAppearance) {        
        UIApplication *application = [UIApplication sharedApplication];
        
        // Store the hidden/visible state and style of the status and navigation
        // bars so that we can restore them when popped.
        UINavigationBar *navigationBar = self.navigationController.navigationBar;
        UIBarStyle navigationBarStyle = navigationBar.barStyle;
        UIColor *navigationBarTint = [navigationBar.tintColor retain];
        BOOL navigationBarHidden = self.navigationController.isNavigationBarHidden;
        
        UIToolbar *toolbar = self.navigationController.toolbar;
        UIBarStyle toolbarStyle = toolbar.barStyle;
        UIColor *toolbarTint = [toolbar.tintColor retain];
        
        UIStatusBarStyle statusBarStyle = application.statusBarStyle;
        BOOL statusBarHidden = application.isStatusBarHidden;
        
        if(!_overrideReturnToNavigationBarStyle) {
            _returnToNavigationBarStyle = navigationBarStyle;
        }
        if(!_overrideReturnToStatusBarStyle) {
            _returnToStatusBarStyle = statusBarStyle;
        }
        if(!_overrideReturnToNavigationBarHidden) {
            _returnToNavigationBarHidden = navigationBarHidden;
        }
        if(!_overrideReturnToStatusBarHidden) {
            _returnToStatusBarHidden = statusBarHidden;
        }
        _returnToToolbarTint = [toolbarTint retain];
        _returnToNavigationBarTint = [navigationBarTint retain];
        _returnToToolbarStyle = toolbarStyle;
        _returnToNavigationBarTranslucent = navigationBar.translucent;
        _returnToToolbarTranslucent = toolbar.translucent;
        
        // Set the status bar and navigation bar styles.
        /*if([_book.author isEqualToString:@"Ward Just"]) {
            navigationBar.barStyle = UIBarStyleBlackTranslucent;
            navigationBar.tintColor = [UIColor blackColor];
            navigationBar.translucent = YES;
            toolbar.barStyle = UIBarStyleBlackTranslucent;
            toolbar.tintColor = [UIColor blackColor];
            toolbar.translucent = YES;
        } else {*/
            navigationBar.translucent = NO;
            navigationBar.tintColor = nil;
            navigationBar.barStyle = UIBarStyleBlackTranslucent;
            toolbar.translucent = NO;
            toolbar.tintColor = nil;
            toolbar.barStyle = UIBarStyleBlackTranslucent;
        /*}*/
        
        if(statusBarStyle != UIStatusBarStyleBlackTranslucent) {
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
				[application setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
			} else {
				[application setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
			}
        }
        // Hide the navigation bar if appropriate.
        // We'll take care of the status bar in -viewDidAppear: (if we do it
        // here, we can see white below on the left as the navigation transition
        // takes place).
        if(self.toolbarsVisibleAfterAppearance) {
            if(navigationBarHidden) {
                [self.navigationController setNavigationBarHidden:NO animated:YES];
            }
        } else {
            if(!navigationBarHidden) {
                [self.navigationController setNavigationBarHidden:YES animated:YES];
            }
            if(!self.navigationController.toolbarHidden) {
                [self.navigationController setToolbarHidden:YES];
            }
        }
        
        if(_bookView && [_bookView wantsTouchesSniffed]) {
            // Couldn't be done at view creation time, because there was
            // no handle to the window.
            UIWindow *window = self.navigationController.view.window;
            [(THEventCapturingWindow *)window addTouchObserver:self forView:_bookView];
        }
        if ([self.navigationItem.titleView isKindOfClass:[EucBookTitleView class]]) {
			EucBookTitleView *titleView = (EucBookTitleView *)self.navigationItem.titleView;
			[titleView setTitle:[self.book title]];
			[titleView setAuthor:[self.book authorsWithStandardFormat]];
		}        
        [self setNavigationBarButtonsForInterfaceOrientation:self.interfaceOrientation];
		
		[self updatePageJumpPanelForBookmarkPoint:_bookView.currentBookmarkPoint animated:NO];
        
        if(animated) {
            CATransition *animation = [CATransition animation];
            animation.type = kCATransitionPush;
            animation.subtype = kCATransitionFromRight;
            animation.duration = 1.0/3.0;
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            
            [animation setValue:_bookView forKey:@"THView"];                
            [[toolbar layer] addAnimation:animation forKey:@"PageViewTransitionIn"];
        } 
    }
    if(!_firstAppearance) {
        [self updatePageJumpPanelVisibility]; 
        _pageJumpView.hidden = !self.toolbarsVisible;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    if(_firstAppearance) {
        UIApplication *application = [UIApplication sharedApplication];
        //if(self.toolbarsVisibleAfterAppearance) {
            if([application isStatusBarHidden]) {
                [application setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
            }
        
        if([self.bookView respondsToSelector:@selector(toolbarsWillShow)]) {
            [self.bookView toolbarsWillShow];
        }
        
        if(!animated) {
            [self.navigationController setNavigationBarHidden:YES animated:YES];
            [self.navigationController setNavigationBarHidden:NO animated:YES];
        } else {
            [self.navigationController setNavigationBarHidden:YES animated:YES];
            [self.navigationController setNavigationBarHidden:NO animated:NO];
        }
        [self.navigationController.toolbar setHidden:NO];
        [self.navigationController setToolbarHidden:NO animated:NO];
        
            if(!animated) {
                CGRect frame = self.navigationController.toolbar.frame;
                frame.origin.y += frame.size.height;
                self.navigationController.toolbar.frame = frame;
                [UIView beginAnimations:@"PullInToolbarAnimations" context:NULL];
                frame.origin.y -= frame.size.height;
                self.navigationController.toolbar.frame = frame;
                [UIView commitAnimations];                
            }                    
        //} //else {
//            UINavigationBar *navBar = self.navigationController.navigationBar;
//            navBar.barStyle = UIBarStyleBlackTranslucent;  
//            if(![application isStatusBarHidden]) {
//				if ([application respondsToSelector:@selector(setStatusBarHidden:withAnimation:)]) 
//                    [application setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
//				else 
//                    [(id)application setStatusBarHidden:YES animated:YES]; // typecast as id to mask deprecation warnings.							
//            }            
//        }
        [self togglePageJumpPanel];
    }
    _firstAppearance = NO;
}


- (void)viewWillDisappear:(BOOL)animated
{
	if ([[UIApplication sharedApplication] respondsToSelector:@selector(endReceivingRemoteControlEvents)]) {
//		NSLog(@"stop receiving remote control events");
		[[UIApplication sharedApplication] endReceivingRemoteControlEvents];
		[self resignFirstResponder];
	}	
    
    [self.navigationController.navigationBar removeObserver:self 
                                              forKeyPath:@"bounds"]; 
    
    [self.navigationController.navigationBar removeObserver:self 
                                                 forKeyPath:@"center"]; 
    
    if(_viewIsDisappearing) {
        [self.book reportReadingIfRequired];
        
        if(_bookView) {
            // Need to do this now before the view is removed and doesn't have a window.
            if ([_bookView wantsTouchesSniffed]) {
                [(THEventCapturingWindow *)_bookView.window removeTouchObserver:self forView:_bookView];
            }
            
            // Save the current progress, for UI display purposes.
            self.book.progress = [NSNumber numberWithFloat:[_bookView percentageForBookmarkPoint:self.book.implicitBookmarkPoint]];
            
            //[self.navigationController setToolbarHidden:YES animated:NO];
//            [self.navigationController setToolbarHidden:NO animated:NO];
            UIToolbar *toolbar = self.navigationController.toolbar;
            toolbar.translucent = _returnToToolbarTranslucent;
            toolbar.barStyle = _returnToToolbarStyle; 
            toolbar.tintColor = _returnToToolbarTint;
            [_returnToToolbarTint release];
            _returnToToolbarTint = nil;
            
            if(animated) {
                CATransition *animation = [CATransition animation];
                animation.type = kCATransitionPush;
                animation.subtype = kCATransitionFromLeft;
                animation.duration = 1.0/3.0;
                animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                
                [animation setValue:_bookView forKey:@"THView"];                
                [[toolbar layer] addAnimation:animation forKey:@"PageViewTransitionOut"];
            } 
            
            // Restore the hiden/visible state of the status bar and 
            // navigation bar.
            // The combination of animation and order below has been found
            // by trial-and-error to give the 'smoothest' looking transition
            // back.
            UIApplication *application = [UIApplication sharedApplication];
            [UIView beginAnimations:@"TransitionBackBarAnimations" context:NULL];
            if(_returnToStatusBarStyle != application.statusBarStyle) {
                [application setStatusBarStyle:_returnToStatusBarStyle
                                      animated:YES];
            }                        
            if(_returnToStatusBarHidden != application.isStatusBarHidden){
                [application setStatusBarHidden:_returnToStatusBarHidden withAnimation:UIStatusBarAnimationFade];
            }           
            UINavigationBar *navBar = self.navigationController.navigationBar;
            navBar.barStyle = UIBarStyleDefault;
            navBar.translucent = _returnToNavigationBarTranslucent;
            navBar.barStyle = _returnToNavigationBarStyle;
            navBar.tintColor = _returnToNavigationBarTint;
            [_returnToNavigationBarTint release];
            _returnToNavigationBarTint = nil;
            
            [UIView commitAnimations];
            
            if(_returnToNavigationBarHidden != self.navigationController.isNavigationBarHidden) {
                [self.navigationController setNavigationBarHidden:_returnToNavigationBarHidden 
                                                         animated:NO];
            }     
            if (self.book.managedObjectContext != nil) {
				NSError *error;
				if (![[self.book managedObjectContext] save:&error])
					NSLog(@"[BlioBookViewController viewWillDisappear] Save failed with error: %@, %@", error, [error userInfo]);            
			}
        }
    }
}


- (void)viewDidDisappear:(BOOL)animated
{    
    _viewIsDisappearing = NO;
}

- (void)didReceiveMemoryWarning 
{
    [self.book flushCaches];
	[super didReceiveMemoryWarning];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
	[self stopAudio];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	[self stopAudio];
    [self.book reportReadingIfRequired];
}
-(void)onProcessingWillDeleteBookNotification:(NSNotification*)notification {
	if ([[notification.userInfo objectForKey:@"bookID"] isEqual:self.book.objectID]) {
		NSLog(@"WARNING: book being viewed is about to be deleted!");
		[self.navigationController popViewControllerAnimated:YES];
	}
}
- (void)dealloc 
{
    //NSLog(@"BookViewController dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIAccelerometer sharedAccelerometer] setUpdateInterval:0];
    [[UIAccelerometer sharedAccelerometer] setDelegate:nil];
	[[AVAudioSession sharedInstance] setDelegate:nil];
    [thumbPreview release], thumbPreview = nil;

    self.searchViewController = nil;
    
    [_pageJumpSlider release];
    [_pageJumpLabel release];
    [_pageJumpView release];
    
    self.bookView = nil;
    self.rootView = nil;
    
    [self.book flushCaches];
    self.book = nil;    
    
    self.bookmarkButton = nil;
    self.pauseMask = nil;
    self.pauseButton = nil;
    self.managedObjectContext = nil;
    self.delegate = nil;
    self.coverView = nil;
    self.viewSettingsSheet = nil;
    self.viewSettingsPopover = nil;
    self.contentsPopover = nil;
    self.searchPopover = nil;
    self.contentsButton = nil;
    self.viewSettingsButton = nil;
    self.searchButton = nil;
	self.backButton = nil;
    self.historyStack = nil;
        
    self.fontDisplayNames = nil;
    self.fontDisplayNameToFontName = nil;
    
	[_audioBookManager release];
	[_acapelaAudioManager release];
    
	[super dealloc];
}


- (void)_fadeDidEnd
{
    if(_fadeState == BookViewControlleUIFadeStateFadingOut) {
        self.navigationController.toolbarHidden = YES;
        if ([self.searchViewController isSearchInline] == YES) {
            self.searchViewController.toolbarHidden = YES;
        }
        self.navigationController.navigationBarHidden = YES;
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        _pageJumpView.hidden = YES;
    } else {
        if (![self audioPlaying])
            [UIApplication sharedApplication].idleTimerDisabled = NO;
        _pageJumpView.hidden = !self.toolbarsVisible;
        [self layoutPageJumpView];
    }
    _fadeState = BookViewControlleUIFadeStateNone;
}
 
- (void)showToolbars
{
    if (![self toolbarsVisible]) {
        [self toggleToolbars];
    }
}

- (BOOL)toolbarsVisible {
    return ([[self.navigationController navigationBar] isHidden] == NO);
}

- (void)delayedToggleToolbars:(NSNumber *)toolbarStateNumber
{
    BlioLibraryToolbarsState toolbarState = [toolbarStateNumber integerValue];
 
    if(_fadeState != BookViewControlleUIFadeStateNone) {
		// Immediately toggle the pause button if required, without animation, before returning
		switch (toolbarState) {
			case kBlioLibraryToolbarsStatePauseButtonVisible:
				self.pauseMask.alpha = 1;
				break;
			default:
				self.pauseMask.alpha = 0;
				break;
		}
		return;
	}
    
    // Set the fade state
    switch (toolbarState) {
        case kBlioLibraryToolbarsStateNoneVisible:
        case kBlioLibraryToolbarsStateStatusBarVisible:
        case kBlioLibraryToolbarsStatePauseButtonVisible:
        //case kBlioLibraryToolbarsStateStatusBarVisible:
            _fadeState = BookViewControlleUIFadeStateFadingOut;
            break;
        default:
            _fadeState = BookViewControlleUIFadeStateFadingIn;
            break;
    }
    
    // Set the status bar settings we don't want to animate 
    switch (toolbarState) {
        case kBlioLibraryToolbarsStateStatusBarVisible:
        case kBlioLibraryToolbarsStateStatusBarAndToolbarsVisible:
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
				[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:NO];
			} else {
				[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
			}
            break;
        default:
            break;
    }
    
    // Set the toolbar settings we don't want to animate 
    switch (toolbarState) {
        case kBlioLibraryToolbarsStateToolbarsVisible:
        case kBlioLibraryToolbarsStateStatusBarAndToolbarsVisible:
            if ([self.searchViewController isSearchInline] == NO) {
                self.navigationController.toolbarHidden = NO;
            } else {
                self.navigationController.toolbarHidden = NO;
                self.searchViewController.toolbarHidden = NO;
            }
            self.navigationController.navigationBarHidden = NO;
            
            break;
        default:
            break;
    }
    
    // Durations below taken from trial-and-error comparison with the 
    // Photos application.
    [UIView beginAnimations:@"ToolbarsFade" context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(_fadeDidEnd)];
        
    switch (toolbarState) {
        case kBlioLibraryToolbarsStateNoneVisible:
        case kBlioLibraryToolbarsStateStatusBarVisible:
        case kBlioLibraryToolbarsStatePauseButtonVisible:
            if([self.bookView respondsToSelector:@selector(toolbarsWillHide)]) {
                [self.bookView toolbarsWillHide];
            }
            break;
        case kBlioLibraryToolbarsStateToolbarsVisible:
        case kBlioLibraryToolbarsStateStatusBarAndToolbarsVisible:
            if([self.bookView respondsToSelector:@selector(toolbarsWillShow)]) {
                [self.bookView toolbarsWillShow];
            }
            break;
    }
    
    // Set the toolbars settings we do want to animate
    switch (toolbarState) {
        case kBlioLibraryToolbarsStateToolbarsVisible:
        case kBlioLibraryToolbarsStateStatusBarAndToolbarsVisible:
            [UIView setAnimationDuration:0];
            if ([self.searchViewController isSearchInline] == NO) {
                self.navigationController.toolbar.alpha = 1;
            } else {
                self.navigationController.toolbar.alpha = 0;
                self.searchViewController.toolbar.alpha = 1;
            }
            
            _pageJumpView.alpha = 1;
            self.navigationController.navigationBar.alpha = 1;
            break;
        default:
            [UIView setAnimationDuration:1.0/3.0];
            self.navigationController.toolbar.alpha = 0;
            if ([self.searchViewController isSearchInline] == YES) {
                self.searchViewController.toolbar.alpha = 0;
            }
            
            _pageJumpView.alpha = 0;
            self.navigationController.navigationBar.alpha = 0;
            break;
    }
    
    // Set the pause button settings we do want to animate
    switch (toolbarState) {
        case kBlioLibraryToolbarsStatePauseButtonVisible:
            self.pauseMask.alpha = 1;
            break;
        default:
            self.pauseMask.alpha = 0;
            break;
    }
    
    [UIView commitAnimations];   
    
    // Set the status bar settings we do want to animate
    switch (toolbarState) {
        case kBlioLibraryToolbarsStateStatusBarVisible:
        case kBlioLibraryToolbarsStateStatusBarAndToolbarsVisible:
            break;
        default:
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
            break;
    }
    
    _toolbarState = toolbarState;
        
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)toggleToolbars:(BlioLibraryToolbarsState)toolbarState
{
    //NSLog(@"toolbar state %d", toolbarState);
    // We do this with performSelector afterDelay 0 so that if something else
    // happens later in this event loop cycle (i.e. a tap-turn starts), the 
    // toggle can be cancelled.
    [self performSelector:@selector(delayedToggleToolbars:) withObject:[NSNumber numberWithInteger:toolbarState] afterDelay:0];
}

- (void)cancelPendingToolbarShow
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedToggleToolbars:) object:[NSNumber numberWithInteger:kBlioLibraryToolbarsStateStatusBarAndToolbarsVisible]];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedToggleToolbars:) object:[NSNumber numberWithInteger:kBlioLibraryToolbarsStateNoneVisible]];
}

- (void)updatePauseButton {
    if (self.audioPlaying)
        [self toggleToolbars:kBlioLibraryToolbarsStatePauseButtonVisible];
    else 
        [self toggleToolbars:kBlioLibraryToolbarsStateStatusBarAndToolbarsVisible];
}

- (void)toggleToolbars
{   
    if (![self audioPlaying]) {
        if ([self toolbarsVisible]) 
            [self toggleToolbars:kBlioLibraryToolbarsStateNoneVisible];
        else
            [self toggleToolbars:kBlioLibraryToolbarsStateStatusBarAndToolbarsVisible];
    }
}

- (void)hideToolbarsAndStatusBar:(BOOL)hidesStatusBar
{
    if([self toolbarsVisible]) {
        if (hidesStatusBar)
            [self toggleToolbars:kBlioLibraryToolbarsStateNoneVisible];
        else
            [self toggleToolbars:kBlioLibraryToolbarsStateStatusBarVisible];
    }
}

- (void)hideToolbars {
    if (![self audioPlaying])
        [self hideToolbarsAndStatusBar:YES];
}

- (CGRect)nonToolbarRect
{
    CGRect rect = self.bookView.bounds;
    
    if([self toolbarsVisible]) {
        CGRect navRect;
        if(_pageJumpView) {
            navRect = _pageJumpView.frame;
        } else {
            navRect = self.navigationController.navigationBar.frame;
        }
        
        CGFloat navRectBottom = CGRectGetMaxY(navRect);
        rect.size.height -= navRectBottom - rect.origin.y;
        rect.origin.y = navRectBottom;

        CGRect toolbarRect = self.navigationController.toolbar.frame;
        rect.size.height -= toolbarRect.size.height;
    }
    
    return rect;
}

- (void)observeTouch:(UITouch *)touch
{
    UITouchPhase phase = touch.phase;
        
    if(touch != _touch) {
        _touch = nil;
        if(phase == UITouchPhaseBegan) {
            _touch = touch;
            _touchMoved = NO;
        }
    } else if(touch == _touch) {
        if(phase == UITouchPhaseMoved) { 
            _touchMoved = YES;
            if([self toolbarsVisible]) {
                [self toggleToolbars];
            }
        } else if(phase == UITouchPhaseEnded) {
            if(!_touchMoved) {
                if(![self toolbarsVisible]) {
                    if(![self.bookView respondsToSelector:@selector(toolbarShowShouldBeSuppressed)] ||
                       ![self.bookView toolbarShowShouldBeSuppressed]) {
                        [self toggleToolbars];
                    }
                } else if ([self toolbarsVisible])
                    if(![self.bookView respondsToSelector:@selector(toolbarHideShouldBeSuppressed)] ||
                       ![self.bookView toolbarHideShouldBeSuppressed]) {
                        [self toggleToolbars];
                }
            }
            _touch = nil;
        } else if(phase == UITouchPhaseCancelled) {
            _touch = nil;
        }
    }
}

- (void)layoutPageJumpView {
    [_pageJumpView setTransform:CGAffineTransformIdentity];
    
    CGRect navBarFrame = self.navigationController.navigationBar.frame;    
    [_pageJumpView setFrame:CGRectMake(CGRectGetMinX(navBarFrame), CGRectGetMaxY(navBarFrame), CGRectGetWidth(navBarFrame),CGRectGetHeight(navBarFrame))];
    
    if (![_pageJumpView isHidden]) {
        [_pageJumpView setTransform:CGAffineTransformIdentity];
    } else {
        [_pageJumpView setTransform:CGAffineTransformMakeTranslation(0, -_pageJumpView.bounds.size.height)];
    }
}

- (void)setPageJumpSliderPreview {
	if ([self.bookView respondsToSelector:@selector(previewThumbnailForBookmarkPoint:)]) {
        float percentage = _pageJumpSlider.value;
		[self setPreviewThumb:[self.bookView previewThumbnailForBookmarkPoint:[_bookView bookmarkPointForPercentage:percentage]]];
	} else {
		[self setPreviewThumb:nil];
	}
}

- (void)layoutPageJumpSlider {
    _pageJumpSlider.transform = CGAffineTransformIdentity;    
    [_pageJumpSlider sizeToFit];
    
    CGRect sliderBounds = [_pageJumpSlider bounds];
    sliderBounds.size.width = CGRectGetWidth(_pageJumpView.bounds) - 10;
    [_pageJumpSlider setBounds:sliderBounds];
    
    CGFloat scale = 1;

    CGRect _pageJumpViewBounds = _pageJumpView.bounds;

    if(_pageJumpViewBounds.size.height < 40)
        scale = 0.75f;
    
    CGPoint center = CGPointMake(CGRectGetMidX(_pageJumpView.bounds), 
                                 CGRectGetHeight(_pageJumpViewBounds) - (CGRectGetHeight(sliderBounds) / 2.0f + 2.0f) * scale);
    _pageJumpSlider.center = center;
    //NSLog(@"%@", NSStringFromCGPoint(center));
    _pageJumpSlider.transform = CGAffineTransformMakeScale(scale, scale); 
}

- (void)layoutPageJumpLabelText {
    
    NSInteger fontSize = [UIFont smallSystemFontSize] + 1;
    CGSize constrainedSize = CGSizeMake(_pageJumpView.bounds.size.width, floorf(_pageJumpView.bounds.size.height / 2.0f) - 1);
    NSString *labelText = _pageJumpLabel.text ? : @"placeholder";
    
    CGSize stringSize;
    BOOL sizedToFitHeight = NO;
    while (!sizedToFitHeight) {
        stringSize = [labelText sizeWithFont:[UIFont boldSystemFontOfSize:fontSize] constrainedToSize:constrainedSize];
        if (stringSize.height <= constrainedSize.height) 
            sizedToFitHeight = YES;
        else
            fontSize--;
    }
    
    CGRect labelFrame = _pageJumpView.bounds;
    labelFrame.size = constrainedSize;
    labelFrame.origin = CGPointMake(5, 1);
    labelFrame.size.width -= 10;
    [_pageJumpLabel setFrame:labelFrame];
    [_pageJumpLabel setFont:[UIFont boldSystemFontOfSize:fontSize]];
}

- (void)initialisePageJumpPanel {
    if(!_pageJumpView) {
        _pageJumpView = [[BlioBeveledView alloc] initWithFrame:CGRectZero];
        _pageJumpView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        _pageJumpView.hidden = YES;
        [self layoutPageJumpView];
        _pageJumpView.autoresizesSubviews = YES;
            
        // feedback label
        _pageJumpLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _pageJumpLabel.textAlignment = UITextAlignmentCenter;
        _pageJumpLabel.minimumFontSize = 12;
        _pageJumpLabel.adjustsFontSizeToFitWidth = YES;
        _pageJumpLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        _pageJumpLabel.shadowOffset = CGSizeMake(0, -1);
        
        _pageJumpLabel.backgroundColor = [UIColor clearColor];
        _pageJumpLabel.textColor = [UIColor whiteColor];
        _pageJumpLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
        
        [self layoutPageJumpLabelText];
        [_pageJumpView addSubview:_pageJumpLabel];

        // the slider
        BlioBookSlider* slider = [[BlioBookSlider alloc] initWithFrame: CGRectZero];
        slider.bookViewController = self;
		slider.exclusiveTouch = YES;

        slider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [slider setAccessibilityLabel:NSLocalizedString(@"Page Chooser", @"Accessibility label for Book View Controller Progress slider")];
        if([[UIDevice currentDevice] compareSystemVersion:@"4.0"] >= NSOrderedSame) {
            [slider setAccessibilityTraits:UIAccessibilityTraitAdjustable];
            [slider setAccessibilityHint:NSLocalizedString(@"Double-tap and hold, then drag left or right to change the page", @"Accessibility hint for Book View Controller Progress slider")];
        }
        _pageJumpSlider = slider;
        
        UIImage *leftCapImage = [UIImage imageNamed:@"iPodLikeSliderBlueLeftCap.png"];
        leftCapImage = [leftCapImage stretchableImageWithLeftCapWidth:leftCapImage.size.width - 1 topCapHeight:0];
        [slider setMinimumTrackImage:leftCapImage forState:UIControlStateNormal];
        
        UIImage *rightCapImage = [UIImage imageNamed:@"iPodLikeSliderWhiteRightCap.png"];
        if([[UIDevice currentDevice] compareSystemVersion:@"3.2"] >= NSOrderedSame) {
            // Work around a bug in 3.2+ where the cap is used as a right cap in
            // the image when it's used in a slider.
            rightCapImage = [rightCapImage stretchableImageWithLeftCapWidth:rightCapImage.size.width - 1 topCapHeight:0];
        } else {
            rightCapImage = [rightCapImage stretchableImageWithLeftCapWidth:1 topCapHeight:0];
        }
        [slider setMaximumTrackImage:rightCapImage forState:UIControlStateNormal];
        
        UIImage *thumbImage = [UIImage imageNamed:@"iPodLikeSliderKnob-Small.png"];
        [slider setThumbImage:thumbImage forState:UIControlStateNormal];
        [slider setThumbImage:thumbImage forState:UIControlStateHighlighted];            
        
        [slider addTarget:self action:@selector(_pageSliderSlid:) forControlEvents:UIControlEventValueChanged];
        
        slider.minimumValue = 0.0f;
        slider.maximumValue = 1.0f;
        [slider setValue:[_bookView percentageForBookmarkPoint:_bookView.currentBookmarkPoint]];
        [self layoutPageJumpSlider];
        [_pageJumpView addSubview:slider];
		[self setPageJumpSliderPreview];
        
        _pageJumpView.layer.zPosition = 5;

        [self.rootView addSubview:_pageJumpView];  
        
        thumbPreview = [[BlioBookSliderPreview alloc] initWithFrame:self.rootView.bounds];
        thumbPreview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        thumbPreview.userInteractionEnabled = NO;
        thumbPreview.alpha = 0.01f;
        thumbPreview.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7f];
        thumbPreview.layer.zPosition = 5;
        [self.rootView addSubview:thumbPreview];
    }
}

- (void)uninitialisePageJumpPanel {
    [_pageJumpSlider release];
    _pageJumpSlider = nil;
    [_pageJumpLabel release];
    _pageJumpLabel = nil;
    [_pageJumpView release];
    _pageJumpView = nil;
    [thumbPreview release];
    thumbPreview = nil;
}

- (void)updatePageJumpPanelVisibility
{
    [self initialisePageJumpPanel];

    CGSize sz = _pageJumpView.bounds.size;
    BOOL hiding = !self.toolbarsVisible;
    
    [self layoutPageJumpView];
    
    if (hiding) {
        _pageJumpView.alpha = 0.0;
        [_pageJumpView setTransform:CGAffineTransformMakeTranslation(0, -sz.height)];
    } else {
        [self _updatePageJumpLabelForBookmarkPoint:self.bookView.currentBookmarkPoint];
        _pageJumpView.hidden = NO;
        _pageJumpView.alpha = 1.0;
        [_pageJumpView setTransform:CGAffineTransformIdentity];
    }
    
    [_pageJumpView.superview bringSubviewToFront:_pageJumpView];
}

- (void) togglePageJumpPanel { 
    [self initialisePageJumpPanel];
    
    [UIView beginAnimations:@"pageJumpViewToggle" context:NULL];
    [UIView setAnimationDidStopSelector:@selector(_pageJumpPanelDidAnimate)];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.3f];

    [self updatePageJumpPanelVisibility];
    
    [UIView commitAnimations];
    
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

- (void) _pageJumpPanelDidAnimate
{
    if (_pageJumpView.alpha == 0.0) {
        _pageJumpView.hidden = YES;
    }
}

- (void) _pageSliderSlid: (id) sender
{
    BlioBookSlider* slider = (BlioBookSlider*) sender;
    float percentage = slider.value;
        
    [self _updatePageJumpLabelForPercentage:percentage];

    if (!slider.touchInProgress) {
        [self.bookView goToBookmarkPoint:[_bookView bookmarkPointForPercentage:percentage] animated:YES];
    }
    
	[self setPageJumpSliderPreview];
}

- (void) _updatePageJumpLabelWithLabel:(NSString *)newLabel
{
    _pageJumpLabel.text = newLabel;
    
    NSString *currentAccessibilityValue = [_pageJumpSlider accessibilityValue];
    if(![currentAccessibilityValue isEqualToString:newLabel]) {
        [_pageJumpSlider setAccessibilityValue:newLabel];
        if(self.toolbarsVisible && !_pageJumpView.isHidden && 
           !self.viewSettingsPopover && !self.viewSettingsSheet) {
            if([[UIDevice currentDevice] compareSystemVersion:@"4.0"] >= NSOrderedSame) {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, newLabel);
            }
        }
    }
}

- (void) _updatePageJumpLabelForPercentage:(float)percentage
{
    if([self.bookView respondsToSelector:@selector(pageLabelForPercentage:)]) {
        [self _updatePageJumpLabelWithLabel:[self.bookView pageLabelForPercentage:percentage]];
    } else {
        [self _updatePageJumpLabelForBookmarkPoint:[self.bookView bookmarkPointForPercentage:percentage]];
    }
}

- (void) _updatePageJumpLabelForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    [self _updatePageJumpLabelWithLabel:[self.bookView pageLabelForBookmarkPoint:bookmarkPoint]];
}

- (UIImage *)dimPageImage
{
    UIView<BlioBookView> *bookView = [self bookView];
    if([bookView respondsToSelector:@selector(dimPageImage)]) {
        return bookView.dimPageImage;
    }
    return nil;
}

- (void)incrementPage
{
    [self.bookView incrementPage];
}

- (void)decrementPage
{
    [self.bookView decrementPage];
}

#pragma mark -
#pragma mark BookController State Methods

- (BlioPageLayout)currentPageLayout {
    BlioBookViewController *bookViewController = (BlioBookViewController *)self.navigationController.topViewController;
    if([bookViewController.bookView isKindOfClass:[BlioLayoutView class]])
        return kBlioPageLayoutPageLayout;
    else if([bookViewController.bookView isKindOfClass:[BlioSpeedReadView class]])
        return kBlioPageLayoutSpeedRead;
    else
        return kBlioPageLayoutPlainText;
}

- (void)changePageLayout:(BlioPageLayout)newLayout {
    BlioPageLayout currentLayout = self.currentPageLayout;
    if(currentLayout != newLayout) { 
		if (newLayout == kBlioPageLayoutPlainText && [self reflowEnabled]) {
            BlioFlowView *ePubView = [[BlioFlowView alloc] initWithFrame:self.rootView.bounds delegate:self bookID:self.book.objectID animated:NO];
            self.bookView = ePubView;
            [ePubView release];
            [[NSUserDefaults standardUserDefaults] setInteger:kBlioPageLayoutPlainText forKey:kBlioLastLayoutDefaultsKey];
			// Audio enable status could have been changed by speedread, so confirm status.
			if ( self.audioEnabled )
				for (UIBarButtonItem* item in self.toolbarItems)
					if (item.action==@selector(toggleAudio:))
						[item setEnabled:YES];
				
        } else if (newLayout == kBlioPageLayoutPageLayout && [self fixedViewEnabled]) {
            BlioLayoutView *layoutView = [[BlioLayoutView alloc] initWithFrame:self.rootView.bounds delegate:self bookID:self.book.objectID animated:NO];
            self.bookView = layoutView;            
            [layoutView release];
            [[NSUserDefaults standardUserDefaults] setInteger:kBlioPageLayoutPageLayout forKey:kBlioLastLayoutDefaultsKey]; 
			// Audio enable status could have been changed by speedread, so confirm status.
			if ( self.audioEnabled )
				for (UIBarButtonItem* item in self.toolbarItems)
					if (item.action==@selector(toggleAudio:))
						[item setEnabled:YES];
        } else if (newLayout == kBlioPageLayoutSpeedRead && [self reflowEnabled]) {
            BlioSpeedReadView *speedReadView = [[BlioSpeedReadView alloc] initWithFrame:self.rootView.bounds delegate:self bookID:self.book.objectID animated:NO];
            self.bookView = speedReadView;     
            [speedReadView release];
			for (UIBarButtonItem* item in self.toolbarItems)
				if (item.action==@selector(toggleAudio:))
					[item setEnabled:NO];
            [[NSUserDefaults standardUserDefaults] setInteger:kBlioPageLayoutSpeedRead forKey:kBlioLastLayoutDefaultsKey];
        }
        
        self.currentPageColor = [[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastPageColorDefaultsKey];
        if([self.bookView respondsToSelector:@selector(setFontName:)]) {
            self.bookView.fontName = [self sanitizedFontNameForName:[[NSUserDefaults standardUserDefaults] objectForKey:kBlioLastFontNameDefaultsKey]];
        }
        if([self.bookView respondsToSelector:@selector(setFontSizeIndex:)]) {
            NSUInteger fontSizeIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastFontSizeIndexDefaultsKey];
            self.bookView.fontSizeIndex = MIN([self fontSizeCount] - 1, fontSizeIndex);
        }
        if([self.bookView respondsToSelector:@selector(setJustification:)]) {
            self.bookView.justification = [[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastJustificationDefaultsKey];
        }
        if([self.bookView respondsToSelector:@selector(setTwoUp:)]) {
            if(newLayout == kBlioPageLayoutPageLayout && [self.book twoPageSpread]) {
                self.bookView.twoUp = kBlioTwoUpAlways;
            } else {
                self.bookView.twoUp = [[NSUserDefaults standardUserDefaults] boolForKey:kBlioLandscapeTwoPagesDefaultsKey] ? kBlioTwoUpLandscape : kBlioTwoUpNever;
            }
        }
        if([self.bookView respondsToSelector:@selector(setShouldTapZoom:)]) {
            self.bookView.shouldTapZoom = [[NSUserDefaults standardUserDefaults] boolForKey:kBlioTapZoomsDefaultsKey];
        }

        // Reset the search results
        self.searchViewController = nil;
        self.searchPopover = nil;
        
        [self updatePageJumpPanelAnimated:YES];
        [self updateBookmarkButton];
    }
}

- (BOOL)shouldShowFontSettings {
    return [self.bookView respondsToSelector:@selector(setFontName:)];
}

- (BOOL)shouldShowFontSizeSettings {
    return [self.bookView respondsToSelector:@selector(setFontSizeIndex:)];
}

- (BOOL)shouldShowJustificationSettings {
    return [self.bookView respondsToSelector:@selector(setJustification:)];
}

- (BOOL)shouldShowPageColorSettings {        
    return YES;
}

- (BOOL)shouldShowtapZoomsSettings {
    if ([self currentPageLayout] == kBlioPageLayoutPageLayout) {
        return YES;
    }
    if ([self currentPageLayout] == kBlioPageLayoutPlainText) {
#if TARGET_OS_IPHONE && (__IPHONE_OS_VERSION_MAX_ALLOWED >= 50000)
        if(&UIAccessibilityTraitCausesPageTurn != NULL &&
           [EucPageTurningView conformsToProtocol:@protocol(UIAccessibilityReadingContent)]) {
            if(UIAccessibilityIsVoiceOverRunning()) {
                return YES;
            }
        }
#endif
    }
    return NO;
}
- (BOOL)shouldShowTwoUpLandscapeSettings {
    if(self.currentPageLayout == kBlioPageLayoutPageLayout && self.book.twoPageSpread) {
            return NO;
    } 
    CGSize size = self.bookView.bounds.size;
    return size.width > size.height && [self.bookView respondsToSelector:@selector(setTwoUp:)];
}

- (BOOL)shouldPresentBrightnessSliderVerticallyInPageSettings {
    // Now that the font settings are in their own panel, no need to do this,
    // it's better to have a taller popover.
    /*if(UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        CGSize size = self.bookView.bounds.size;
        return size.width > size.height;
    }*/
    return NO;
}

- (BOOL)shouldShowDoneButtonInPageSettings
{
    // There's no way to escape from the fake popover without a done button using accessability;
    return UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad && 
        &UIAccessibilityIsVoiceOverRunning != NULL && 
        UIAccessibilityIsVoiceOverRunning();
}

- (BOOL)reflowEnabled 
{
	return [self.book reflowEnabled];
}
-(BOOL)fixedViewEnabled 
{
	return [self.book fixedViewEnabled];
}

- (void)changeFontName:(NSString *)fontName
{
    fontName = [self sanitizedFontNameForName:fontName];
    [[NSUserDefaults standardUserDefaults] setObject:fontName forKey:kBlioLastFontNameDefaultsKey];
    self.bookView.fontName = fontName;
}
- (NSString *)currentFontName
{
    return [self sanitizedFontNameForName:[[NSUserDefaults standardUserDefaults] objectForKey:kBlioLastFontNameDefaultsKey]];
}

- (void)_prepareFontInformation {
    NSURL *fontInformationURL = [[NSBundle mainBundle] URLForResource:@"BlioFonts" withExtension:@"plist"];
    NSDictionary *fontInformation = [NSDictionary dictionaryWithContentsOfURL:fontInformationURL];
    fontDisplayNameToFontName = [[fontInformation objectForKey:@"FontDisplayNameToFontName"] retain];
    
    // Filter the array to make sure all the fonts are available (not all are
    // on iOS 4).
    NSArray *unfilteredFontDisplayNames = [fontInformation objectForKey:@"FontDisplayNames"];
    NSMutableArray *buildFontDisplayNames = [[NSMutableArray alloc] initWithCapacity:unfilteredFontDisplayNames.count];
    for(NSString *displayName in unfilteredFontDisplayNames) {
        NSString *fontName = [fontDisplayNameToFontName objectForKey:displayName];
        if([fontName isEqualToString:kBlioOriginalFontName] || 
           [UIFont fontWithName:fontName size:12] != nil) {
            [buildFontDisplayNames addObject:displayName];
        }
    }
    fontDisplayNames = buildFontDisplayNames;
}

- (NSArray *)fontDisplayNames {
    if(!fontDisplayNames) {
        [self _prepareFontInformation];
    }
    return fontDisplayNames;
}

- (NSDictionary *)fontDisplayNameToFontName {
    if(!fontDisplayNameToFontName) {
        [self _prepareFontInformation];
    }
    return fontDisplayNameToFontName;
}

- (NSString *)fontDisplayNameToFontName:(NSString *)fontDisplayName
{
    return [self.fontDisplayNameToFontName objectForKey:fontDisplayName];
}

- (NSString *)fontNameToFontDisplayName:(NSString *)fontName
{
    for(NSString *key in self.fontDisplayNameToFontName) {
        NSString *value = [self.fontDisplayNameToFontName objectForKey:key];
        if([value isEqualToString:fontName]) {
            return key;
        }
    }
    return nil;
}


- (void)changeFontSizeIndex:(NSUInteger)newSize {
    self.bookView.fontSizeIndex = newSize;
    // Will set the default when we get the KVO callback.
    // [[NSUserDefaults standardUserDefaults] setInteger:newSize forKey:kBlioLastFontSizeIndexDefaultsKey];
}

- (NSUInteger)currentFontSizeIndex {
    return self.bookView.fontSizeIndex;
}

- (NSUInteger)fontSizeCount
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 5 : 6;
}

- (NSArray *)fontSizesForBlioBookView:(id<BlioBookView>)bookView
{
    // 5 font sizes on iPhone, 6 on iPad.
    NSUInteger fontSizeCount = [self fontSizeCount];
    NSMutableArray *fontSizes = [[NSMutableArray alloc] initWithCapacity:fontSizeCount];
    if([bookView isKindOfClass:[BlioSpeedReadView class]]) {
        for(size_t i = 0; i < fontSizeCount; ++i) {
            NSParameterAssert(fontSizeCount <= sizeof(kBlioSpeedReadFontPointSizeArray) / sizeof(CGFloat));
            [fontSizes addObject:[NSNumber numberWithFloat:kBlioSpeedReadFontPointSizeArray[i]]];
        }
    } else {
        for(size_t i = 0; i < fontSizeCount; ++i) {
            NSParameterAssert(fontSizeCount <= sizeof(kBlioFontSizesArray) / sizeof(CGFloat));
            [fontSizes addObject:[NSNumber numberWithFloat:kBlioFontSizesArray[i]]];
        }
    }
    return [fontSizes autorelease];
}

- (void)setCurrentPageColor:(BlioPageColor)newColor
{
    UIView<BlioBookView> *bookView = self.bookView;
    if([bookView isKindOfClass:[BlioSpeedReadView class]]) {
        [(BlioSpeedReadView*)bookView setColor:newColor];
    } else {
        if([bookView respondsToSelector:(@selector(setPageTexture:isDark:))]) {
            // First we look for a low-res texture to save RAM.
            // TODO: Remove this.  This was added th allow us to 
            // use 32-bit page textures so that Quark overlays would composit
            // correctly on flat pages (using 16-bit page textures exposes
            // too many rounding errors when used alongside our multiply +
            // alpha mask trick).
            
            UIImage *pageTexture = nil;
            if([[UIDevice currentDevice] compareSystemVersion:@"4"] >= NSOrderedSame) {
                NSString *name = kBlioFontPageTextureNamesArray[newColor];
                name = [[[name stringByDeletingPathExtension] stringByAppendingString:@"-quartered"] stringByAppendingPathExtension:[name pathExtension]];
                pageTexture = [UIImage imageNamed:name];
                if(!pageTexture) {
                    NSString *name = kBlioFontPageTextureNamesArray[newColor];
                    pageTexture = [UIImage imageNamed:name];
                }
            } else {
                NSString *name = kBlioFontPageTextureNamesArray[newColor];
                name = [[[name stringByDeletingPathExtension] stringByAppendingString:@"-quartered"] stringByAppendingPathExtension:[name pathExtension]];
                if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                    // iPad doesn't automatically look for its own images with < OS 4.0
                    name = [[[name stringByDeletingPathExtension] stringByAppendingString:@"~ipad"] stringByAppendingPathExtension:[name pathExtension]];
                    pageTexture = [UIImage imageNamed:name];
                } else {
                    pageTexture = [UIImage imageNamed:name];
                }
                
                if(!pageTexture) {
                    NSString *name = kBlioFontPageTextureNamesArray[newColor];
                    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                        // iPad doesn't automatically look for its own images with < OS 4.0
                        name = [[[name stringByDeletingPathExtension] stringByAppendingString:@"~ipad"] stringByAppendingPathExtension:[name pathExtension]];
                        pageTexture = [UIImage imageNamed:name];
                    } else {
                        pageTexture = [UIImage imageNamed:name];
                    }
                }
            }
            [bookView setPageTexture:pageTexture isDark:kBlioFontPageTexturesAreDarkArray[newColor]];
        }
    }
    _currentPageColor = newColor;
}

- (void)changeJustification:(BlioJustification)newJustification {
    [[NSUserDefaults standardUserDefaults] setInteger:newJustification forKey:kBlioLastJustificationDefaultsKey];
    self.bookView.justification = newJustification;
}
- (BlioJustification)currentJustification
{
    if([self.bookView respondsToSelector:@selector(justification)]) {
        return self.bookView.justification;
    } else {
        return -1;
    }
}

- (void)changePageColor:(BlioPageColor)newPageColor {
    self.currentPageColor = newPageColor;
    [[NSUserDefaults standardUserDefaults] setInteger:self.currentPageColor forKey:kBlioLastPageColorDefaultsKey];
}

- (void)changeTapZooms:(BOOL)newTapZooms {
    [[NSUserDefaults standardUserDefaults] setBool:newTapZooms forKey:kBlioTapZoomsDefaultsKey];
    if([self.bookView respondsToSelector:@selector(setShouldTapZoom:)]) {
        self.bookView.shouldTapZoom = newTapZooms;
    }
}
- (BOOL)currentTapZooms
{
    return self.bookView.shouldTapZoom;
}

- (void)changeTwoUpLandscape:(BOOL)shouldBeTwoUp {
    [[NSUserDefaults standardUserDefaults] setBool:shouldBeTwoUp forKey:kBlioLandscapeTwoPagesDefaultsKey];
    if([self.bookView respondsToSelector:@selector(setTwoUp:)]) {
        self.bookView.twoUp = shouldBeTwoUp ? kBlioTwoUpLandscape : kBlioTwoUpNever;
    }
}
- (BOOL)currentTwoUpLandscape
{
    return self.bookView.twoUp != kBlioTwoUpNever;
}


- (void)toggleRotationLock {
    [self setRotationLocked:![self isRotationLocked]];
    [[NSUserDefaults standardUserDefaults] setInteger:[self isRotationLocked] forKey:kBlioLastLockRotationDefaultsKey];
}

#pragma mark -
#pragma mark KVO Callback

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSParameterAssert([NSThread isMainThread]);
    
    if ([keyPath isEqualToString:@"currentBookmarkPoint"]) {
        [self updatePageJumpPanelAnimated:YES];
        		
		if ( _acapelaAudioManager != nil )
			[_acapelaAudioManager setPageChanged:YES];  
		if ( _audioBookManager != nil )
			[_audioBookManager setPageChanged:YES];
		
        if(coverOpened) {
            BlioBookmarkPoint *newBookmarkPoint = self.bookView.currentBookmarkPoint;
            if (![self.book.implicitBookmarkPoint isEqual:newBookmarkPoint]) {
                self.book.implicitBookmarkPoint = newBookmarkPoint;
                
                if (self.book.managedObjectContext != nil) {
                    NSError *error;
                    if (![[self.book managedObjectContext] save:&error]) {
                        NSLog(@"[BlioBookViewController observeValueForKeyPath] Save failed with error: %@, %@", error, [error userInfo]);            
                    } /*else {
                        NSLog(@"Saved bookmark point [%ld, %ld, %ld, %ld] - page %@",
                              (long)newBookmarkPoint.layoutPage, 
                              (long)newBookmarkPoint.blockOffset,
                              (long)newBookmarkPoint.wordOffset,
                              (long)newBookmarkPoint.elementOffset,
                              [_bookView displayPageNumberForBookmarkPoint:newBookmarkPoint]);
                    }*/
                }
            }
        }
    } else if ([keyPath isEqualToString:@"fontSizeIndex"] &&
               object == self.bookView) {
        [[NSUserDefaults standardUserDefaults] setInteger:self.bookView.fontSizeIndex forKey:kBlioLastFontSizeIndexDefaultsKey];
    } else if (object == self.navigationController.navigationBar) {
        if ([keyPath isEqualToString:@"bounds"] || 
            [keyPath isEqualToString:@"center"]) {            
            [self layoutPageJumpView];
            [self layoutPageJumpLabelText];
            [self layoutPageJumpSlider];
        }
    }
}

#pragma mark -
#pragma mark Action Callback Methods

- (void)setToolbarsForModalOverlayActive:(BOOL)active {
    if (active) {
        _beforeModalOverlayToolbarState = _toolbarState;
        [self toggleToolbars:kBlioLibraryToolbarsStateStatusBarVisible];
    } else {
        [self toggleToolbars:_beforeModalOverlayToolbarState];
    }
}

- (void)showContents:(id)sender {
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (![self.contentsPopover isPopoverVisible]) {
            BlioContentsTabViewController *aContentsTabView = [[BlioContentsTabViewController alloc] initWithBookView:self.bookView book:self.book];
            aContentsTabView.delegate = self;
            BlioModalPopoverController *aContentsPopover = [[BlioModalPopoverController alloc] initWithContentViewController:aContentsTabView];
            aContentsPopover.delegate = aContentsTabView;
            aContentsTabView.popoverController = aContentsPopover;
            [aContentsTabView release];
            [aContentsPopover presentPopoverFromBarButtonItem:(UIBarButtonItem *)sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            self.contentsPopover = aContentsPopover;
            [aContentsPopover release];
        } else {
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        }
    } else {
        BlioContentsTabViewController *aContentsTabView = [[BlioContentsTabViewController alloc] initWithBookView:self.bookView book:self.book];
        aContentsTabView.delegate = self;
        [self presentModalViewController:aContentsTabView animated:YES];
        [aContentsTabView release];  
    }
}

- (void)showViewSettings:(id)sender {    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (![self.viewSettingsPopover isPopoverVisible]) {
            BlioViewSettingsPopover *aSettingsPopover = [[BlioViewSettingsPopover alloc] initWithDelegate:self];
            self.viewSettingsPopover = aSettingsPopover;
            [aSettingsPopover presentPopoverFromBarButtonItem:(UIBarButtonItem *)sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            [aSettingsPopover release];
        }
    } else {
        if (!self.viewSettingsSheet) {
            BlioViewSettingsSheet *aSettingsSheet = [[BlioViewSettingsSheet alloc] initWithDelegate:self];
            self.viewSettingsSheet = aSettingsSheet;
            [aSettingsSheet showFromToolbar:self.navigationController.toolbar];
            [aSettingsSheet release];
        }
    }
}

- (void)dismissViewSettings:(id)sender {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.viewSettingsPopover dismissPopoverAnimated:YES];
    } else {
        [self.viewSettingsSheet dismissAnimated:YES];
    }
}

- (void)viewSettingsDidDismiss:(id)sender {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.viewSettingsPopover = nil;
    } else {
        self.viewSettingsSheet = nil;
    }
}

- (void)viewSettingsShowFontSettings:(id)sender {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.viewSettingsPopover pushFontSettings];
    } else {
        [self.viewSettingsSheet pushFontSettings];
    }

}

- (void)viewSettingsDismissFontSettings:(id)sender {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Navigation is handled by the popover/nav controller,
        // no need to do anything here.
    } else {
        
    }
}

- (void)buyBook:(id)sender {
	[[BlioStoreManager sharedInstance] buyBookWithSourceSpecificID:[self.book valueForKey:@"sourceSpecificID"]];
}

#pragma mark -
#pragma mark TTS Handling 

- (void)speakNextBlock:(NSTimer*)timer {
	if ( _acapelaAudioManager.textToSpeakChanged ) {	
		[_acapelaAudioManager setTextToSpeakChanged:NO];
		if(![_acapelaAudioManager startSpeakingWords:_acapelaAudioManager.blockWords]) {
            // This probably means that the block was empty.  
            // Pretend that we have read everything from it (which, in effect, 
            // we have).
            [self speechSynthesizer:_acapelaAudioManager.engine didFinishSpeaking:YES];
        }
	}
}

- (void) getNextBlockForAudioManager:(BlioAudioManager*)audioMgr {
    id block = audioMgr.currentBlock;
    NSArray *words = nil;
    do {
        block = [_audioParagraphSource nextParagraphIdForParagraphWithID:block];
        words = [_audioParagraphSource wordsForParagraphWithID:block];
    } while(block && words.count == 0); // Loop in case it's a wordless paragraph.
    
    // If we're at the end of the book, 'block' and 'words' will both be nil at this point.
    audioMgr.currentBlock = block;
    audioMgr.currentWordOffset = 0;
    audioMgr.blockWords = words;
}

- (void) prepareTextToSpeakWithAudioManager:(BlioAudioManager*)audioMgr fromBookmarkPoint:(BlioBookmarkPoint *)point {
	if ( !point ) {
		// Continuing to speak, we just need more text.
		[self getNextBlockForAudioManager:audioMgr];
	}
	else {
		// Play button has just been pushed.
        id blockId = nil;
        uint32_t wordOffset = 0;
		[_audioParagraphSource bookmarkPoint:point toParagraphID:&blockId wordOffset:&wordOffset]; 
		
//		NSLog(@"prepareTextToSpeakWithAudioManager. CurrentBookmarkPoint is on page %d. blockId: %@ wordOffset: %d)", self.bookView.currentBookmarkPoint.layoutPage, blockId, wordOffset);

        if ( blockId ) {
            if ( audioMgr.pageChanged ) {  
                // Page has changed since the stop button was last pushed (and pageChanged is initialized to true).
                // So we're starting speech for the first time, or for the first time since changing the 
                // page or book after stopping speech the last time (whew).
                [audioMgr setCurrentBlock:blockId];
                [audioMgr setBlockWords:[_audioParagraphSource wordsForParagraphWithID:blockId]];
                if([audioMgr.blockWords count] == 0) {
                    [self getNextBlockForAudioManager:audioMgr];
                }
                
				//if ( [audioMgr.blockWords count] && (wordOffset < [audioMgr.blockWords count] - 1 )) {
				//	++wordOffset;
				//}
				
                [audioMgr setCurrentWordOffset:wordOffset];
                [audioMgr setPageChanged:NO];
            }
            else {
                // use the current word and block, which is where we last stopped.
                if ( audioMgr.currentWordOffset < [audioMgr.blockWords count] ) {
                    // We last stopped in the middle of a block.
                } else {
                    // We last stopped at the end of a block, so need the next one.
                    [self getNextBlockForAudioManager:audioMgr];
                }
            }
        }
	}
    
    if(audioMgr.currentBlock) {
        [audioMgr setStartedPlaying:YES];
        [audioMgr setTextToSpeakChanged:YES];
    } else {
        // For audiobooks, we'll stop when the audio stops (there may be play-out music etc.)
        // For TTS, stop now.
        if(_acapelaAudioManager) {
            self.audioPlaying = NO;
            [_audioParagraphSource release];
            _audioParagraphSource = nil;
            [[BlioBookManager sharedBookManager] checkInParagraphSourceForBookWithID:self.book.objectID];            
            [self updatePauseButton];  
        }
    }
}

- (void) prepareTextToSpeakWithAudioManager:(BlioAudioManager*)audioMgr {
	[self prepareTextToSpeakWithAudioManager:audioMgr fromBookmarkPoint:nil];
}

- (BOOL)loadAudioFilesForLayoutPageNumber:(NSInteger)layoutPage segmentIndex:(NSInteger)segmentIx {
	NSMutableArray* segmentInfo;
	// Subtract 1 for now from page to match Blio layout page. Can't we have them match?
	if ( !(segmentInfo = [(NSMutableArray*)[_audioBookManager.pagesDict objectForKey:[NSNumber numberWithInteger:layoutPage-1]] objectAtIndex:segmentIx]) )
		return NO;
	if ( ![_audioBookManager loadWordTimesWithIndex:[[segmentInfo objectAtIndex:kAudioRefIndex] intValue]] )  {
		NSLog(@"Timing file could not be initialized.");
		return NO;
	}
	if ( ![_audioBookManager initAudioWithIndex:[[segmentInfo objectAtIndex:kAudioRefIndex] intValue]] ) {
		NSLog(@"Audio player could not be initialized.");
		return NO;
	}
	_audioBookManager.avPlayer.delegate = self;
	
	// Cue up the audio player to where it should start for this page.
	BlioBookmarkPoint* bookmarkPt = self.bookView.currentBookmarkPoint;  
	_audioBookManager.timeIx = [[segmentInfo objectAtIndex:kTimeIndex] intValue] + bookmarkPt.wordOffset;
	if (  bookmarkPt.blockOffset>0 ) {
		NSArray *pageBlocks = [[self.book textFlow] blocksForPageAtIndex:layoutPage - 1 includingFolioBlocks:NO]; 
		NSInteger numPrevWords = 0;
		for ( int i=0; i< bookmarkPt.blockOffset; ++i ) {
			BlioTextFlowBlock *thisBlock = [pageBlocks objectAtIndex:i];
			numPrevWords += [[thisBlock words] count];
		}
		_audioBookManager.timeIx += numPrevWords;
	}
	NSTimeInterval timeOffset = [[_audioBookManager.wordTimes objectAtIndex:_audioBookManager.timeIx] intValue]/1000.0;
	[_audioBookManager.avPlayer setCurrentTime:timeOffset];
	
	// Fixed-view-only implementation:
	// Cue up the audio player to where it starts for this page.
	// In future, could get this from TimeIndex.
	//NSTimeInterval timeOffset = [[segmentInfo objectAtIndex:kTimeOffset] intValue]/1000.0;
	//[_audioBookManager.avPlayer setCurrentTime:timeOffset];
	// Set the timing file index for this page.
	//_audioBookManager.timeIx = [[segmentInfo objectAtIndex:kTimeIndex] intValue]; // need to subtract one...
	
	return YES;
}

#pragma mark -
#pragma mark Acapela Delegate Methods 

- (void)speechSynthesizer:(AcapelaSpeech*)synth didFinishSpeaking:(BOOL)finishedSpeaking
{
	//NSLog(@"%@%i", NSStringFromSelector(_cmd),finishedSpeaking);
	if (finishedSpeaking) {
		// Reached end of block.  Start on the next.
		[self prepareTextToSpeakWithAudioManager:_acapelaAudioManager]; 
	}
	//else stop button pushed before end of block.
}

- (void)speechSynthesizer:(AcapelaSpeech*)sender willSpeakWord:(NSRange)characterRange 
				 ofString:(NSString*)string 
{
	//NSLog(@"%@", NSStringFromSelector(_cmd));
    if(characterRange.location + characterRange.length <= string.length) {
        NSUInteger wordOffset = [_acapelaAudioManager wordOffsetForCharacterRange:characterRange];
        
        id<BlioBookView> bookView = self.bookView;
        if([bookView respondsToSelector:@selector(highlightWordAtBookmarkPoint:)]) {
            BlioBookmarkPoint *point = [_audioParagraphSource bookmarkPointFromParagraphID:_acapelaAudioManager.currentBlock
                                                                                wordOffset:wordOffset];
            [bookView highlightWordAtBookmarkPoint:point];
        }
        [_acapelaAudioManager setCurrentWordOffset:wordOffset];
    }
}

#pragma mark -
#pragma mark AVAudioSession Delegate Methods 
- (void)beginInterruption {
	NSLog(@"%@", NSStringFromSelector(_cmd));
	// update UI (e.g. play/pause button), stop any animations.
}
- (void)endInterruptionWithFlags:(NSUInteger)flags {
	NSLog(@"%@", NSStringFromSelector(_cmd));
	if (flags == AVAudioSessionInterruptionFlags_ShouldResume) {
		
	}
}


#pragma mark -
#pragma mark AVAudioPlayer Delegate Methods 

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag { 
	NSLog(@"%@", NSStringFromSelector(_cmd));
	if (!flag) {
		self.audioPlaying = NO;
        [_audioParagraphSource release];
        _audioParagraphSource = nil;
        [[BlioBookManager sharedBookManager] checkInParagraphSourceForBookWithID:self.book.objectID];        
        [self updatePauseButton];
		NSLog(@"Audio player terminated because of error.");
		return;
	}
	[_audioBookManager.speakingTimer invalidate];
    _audioBookManager.speakingTimer = nil;
	NSInteger layoutPageNumber = [self.bookView.currentBookmarkPoint layoutPage];
	NSLog(@"audioPlayerDidFinishPlaying layoutPage: %d", layoutPageNumber);

	// Subtract 1 to match Blio layout page number.  
	NSMutableArray* pageSegments = (NSMutableArray*)[_audioBookManager.pagesDict objectForKey:[NSNumber numberWithInteger:layoutPageNumber-1]];
	if ([pageSegments count] == 1 ) {
		// Stopped at the exact end of the page.
		BOOL loadedFilesAhead = NO;
        NSInteger highestPageNumber = _audioBookManager.highestPageIndex + 1;
		for ( NSInteger i=layoutPageNumber + 1; i<=highestPageNumber; ++i ) {  
			if ( [self loadAudioFilesForLayoutPageNumber:i segmentIndex:0] ) {
				loadedFilesAhead = YES;
				BOOL animatedPageChange = YES;
				if ([[UIApplication sharedApplication] respondsToSelector:@selector(applicationState)]) {
					if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) animatedPageChange = NO;
				}
				break;
			}
		}
		if ( !loadedFilesAhead ) {
			// End of book.
			self.audioPlaying = NO;
            [_audioParagraphSource release];
            _audioParagraphSource = nil;
            [[BlioBookManager sharedBookManager] checkInParagraphSourceForBookWithID:self.book.objectID];            
            [self updatePauseButton];
		}
		else {
			[self prepareTextToSpeakWithAudioManager:_audioBookManager];
			[_audioBookManager setSpeakingTimer:[NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(checkHighlightTime:) userInfo:nil repeats:YES]];
			[_audioBookManager playAudio];
		}
	}
	else {
		// Stopped in the middle of the page.
		// Kluge: assume there won't be more than two segments on a page.
		if ( [self loadAudioFilesForLayoutPageNumber:layoutPageNumber segmentIndex:1] ) {
			[self prepareTextToSpeakWithAudioManager:_audioBookManager];
			[_audioBookManager setSpeakingTimer:[NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(checkHighlightTime:) userInfo:nil repeats:YES]];
			[_audioBookManager playAudio];
		}
	}
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer*)player error:(NSError*)error { 
	NSLog(@"Audio player error.");
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer*) player { 
	NSLog(@"%@", NSStringFromSelector(_cmd));
	[_audioBookManager playAudio];
}

#pragma mark -
#pragma mark UIResponder Event Handling

- (BOOL)canBecomeFirstResponder {
	return YES;
}

-(void)remoteControlReceivedWithEvent:(UIEvent*)theEvent {
	NSLog(@"%@", NSStringFromSelector(_cmd));
    if (theEvent.type == UIEventTypeRemoteControl) {
        switch(theEvent.subtype) {
            case UIEventSubtypeRemoteControlTogglePlayPause:
				NSLog(@"UIEventSubtypeRemoteControlTogglePlayPause");
				[self toggleAudio:nil];
                break;
            case UIEventSubtypeRemoteControlNextTrack:
				NSLog(@"UIEventSubtypeRemoteControlNextTrack");				
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
				NSLog(@"UIEventSubtypeRemoteControlPreviousTrack");
                break;
            case UIEventSubtypeRemoteControlPlay:
				NSLog(@"UIEventSubtypeRemoteControlPlay");
                if(!self.audioPlaying) {
                    [self toggleAudio:nil];
                }                
                break;
            case UIEventSubtypeRemoteControlPause:
            case UIEventSubtypeRemoteControlStop:
				NSLog(@"UIEventSubtypeRemoteControlPause");
                if(self.audioPlaying) {
                    [self toggleAudio:nil];
                }
                break;
            default:
                return;
		}
	}
}

#pragma mark -
#pragma mark Audiobook and General Audio Handling 

- (void)checkHighlightTime:(NSTimer*)timer {	
	if ( _audioBookManager.timeIx >= [_audioBookManager.wordTimes count] )
		// can get here ahead of audioPlayerDidFinishPlaying
		return;

    
    BOOL highlightShouldMove = NO;
    id moveToBlockID = nil;
    NSUInteger moveToWordOffset = 0;
    
    // Loop through all the words that should have been highlighted before this 
    // time.  A loop because the audio manager might potentially have read more
    // than one word in the time that elapsed between the last checkHighlightTime
    // call was made (this is unlikely since we fire so fast, but possible,
    // especially if the main thread stalls for some reason).    
    int timeElapsed = [_audioBookManager.avPlayer currentTime] * 1000;
	while ( timeElapsed > [[_audioBookManager.wordTimes objectAtIndex:_audioBookManager.timeIx] intValue] ) {
		//NSLog(@"Time is: %ld, Passed time %d", timeElapsed, [[_audioBookManager.wordTimes objectAtIndex:_audioBookManager.timeIx] intValue]);

        // Save these now, because we're about to move on to the next word.
        highlightShouldMove = YES;
        [moveToBlockID release];
        moveToBlockID = [_audioBookManager.currentBlock retain];
        moveToWordOffset = _audioBookManager.currentWordOffset;

		++_audioBookManager.timeIx;
		++_audioBookManager.currentWordOffset;
        
        if ( _audioBookManager.currentWordOffset == _audioBookManager.blockWords.count ) {
            [self prepareTextToSpeakWithAudioManager:_audioBookManager];
        }   
		if ( _audioBookManager.timeIx >= [_audioBookManager.wordTimes count] )
			break;         
	}
    
    if ( highlightShouldMove ) {
        id<BlioBookView> bookView = self.bookView;
        if([bookView respondsToSelector:@selector(highlightWordAtBookmarkPoint:)]) {
            //NSLog(@"%@, %d", moveToBlockID, moveToWordOffset);
            BlioBookmarkPoint *point = [_audioParagraphSource bookmarkPointFromParagraphID:moveToBlockID
                                                                                wordOffset:moveToWordOffset];
            [bookView highlightWordAtBookmarkPoint:point];
        }
    }
    
    [moveToBlockID release];
}

- (void)stopAudio {		
	if ([self.book hasAudiobook]) {
        [_audioBookManager stopAudio];
        [_audioBookManager.speakingTimer invalidate];
        _audioBookManager.speakingTimer = nil; 
    }
    else if ([self.book hasTTSRights]) {
        [_acapelaAudioManager stopSpeaking];
        [_acapelaAudioManager.speakingTimer invalidate];
        _acapelaAudioManager.speakingTimer = nil; 
    }
}

- (void)pauseAudio {		
	if ([self.book hasAudiobook]) {
		[_audioBookManager pauseAudio];
		[_audioBookManager setPageChanged:NO];
        [_audioBookManager.speakingTimer invalidate];
        _audioBookManager.speakingTimer = nil; 
	}	
	else if ([self.book hasTTSRights]) {
		[_acapelaAudioManager pauseSpeaking];
		[_acapelaAudioManager setPageChanged:NO]; // In case speaking continued through a page turn.
        [_acapelaAudioManager.speakingTimer invalidate];
        _acapelaAudioManager.speakingTimer = nil; 
	}
}

- (void)prepareTTSEngine {
    [_acapelaAudioManager setEngineWithPreferences];
	[_acapelaAudioManager setDelegate:self];
}

- (void)toggleAudio:(id)sender {
    if (self.audioPlaying) {
        [self pauseAudio];  // For tts, try again with stopSpeakingAtBoundary when next RC comes.
        self.audioPlaying = NO;  
        [_audioParagraphSource release];
        _audioParagraphSource = nil;
        [[BlioBookManager sharedBookManager] checkInParagraphSourceForBookWithID:self.book.objectID];        
    } else {
        _audioParagraphSource = [[[BlioBookManager sharedBookManager] checkOutParagraphSourceForBookWithID:self.book.objectID] retain];
        
		NSLog(@"[self.book hasTTSRights]: %i",[self.book hasTTSRights]);
		NSLog(@"[self.book hasAudiobook]: %i",[self.book hasAudiobook]);
		
		BlioBookmarkPoint *startPoint = nil;
		
        if ([self.book hasAudiobook]) {
            if ( _audioBookManager.startedPlaying == NO || _audioBookManager.pageChanged) { 
                if ( ![self loadAudioFilesForLayoutPageNumber:[self.bookView.currentBookmarkPoint layoutPage] segmentIndex:0] ) {
                    // No audio files for this page.
                    // Look for next page with files.
                    BOOL loadedFilesAhead = NO;
                    NSInteger highestPageNumber = _audioBookManager.highestPageIndex + 1;
                    for ( NSInteger i=[self.bookView.currentBookmarkPoint layoutPage]+1; i <= highestPageNumber; ++i ) {
                        if ( [self loadAudioFilesForLayoutPageNumber:i segmentIndex:0] ) {
                            loadedFilesAhead = YES;
							BOOL animatedPageChange = YES;
							if ([[UIApplication sharedApplication] respondsToSelector:@selector(applicationState)]) {
								if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) animatedPageChange = NO;
							}							
							startPoint = [[[BlioBookmarkPoint alloc] init] autorelease];
							startPoint.layoutPage = i;
                            break;
                        }
                    }
                    if ( !loadedFilesAhead )
                        return;
                }
				
				if (startPoint) {
					[self prepareTextToSpeakWithAudioManager:_audioBookManager fromBookmarkPoint:startPoint];
				} else {
					[self prepareTextToSpeakWithAudioManager:_audioBookManager fromBookmarkPoint:self.bookView.currentBookmarkPoint];
				}
            }
            [_audioBookManager setSpeakingTimer:[NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(checkHighlightTime:) userInfo:nil repeats:YES]];
            [_audioBookManager playAudio];
            self.audioPlaying = _audioBookManager.startedPlaying;  
        }
        else if ([self.book hasTTSRights]) {
			if ([[[BlioAcapelaAudioManager sharedAcapelaAudioManager] availableVoicesForUse] count] > 0) {
				[self prepareTTSEngine];
				[_acapelaAudioManager setSpeakingTimer:[NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(speakNextBlock:) userInfo:nil repeats:YES]];				
				[self prepareTextToSpeakWithAudioManager:_acapelaAudioManager fromBookmarkPoint:self.bookView.currentBookmarkPoint];
				self.audioPlaying = _acapelaAudioManager.startedPlaying;
			}
			else {
				[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"No Voices Available",@"\"No Voices Available\" alert message title")
											 message:NSLocalizedStringWithDefaultValue(@"TTS_CANNOT_BE_HEARD_WITHOUT_AVAILABLE_VOICES",nil,[NSBundle mainBundle],@"You do not have any voices installed. Would you like to purchase a voice?",@"Alert message shown to end-user when the end-user attempts to hear a book read aloud by the TTS engine without any voices downloaded.")
											delegate:self 
								   cancelButtonTitle:NSLocalizedString(@"No",@"\"No\" label for button used to cancel/dismiss alertview") 
									otherButtonTitles:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview"),nil];
			}
        }
        else {
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"No Audio Rights",@"\"No Audio Rights\" alert message title")
										 message:NSLocalizedStringWithDefaultValue(@"NO_AUDIO_PERMITTED_FOR_THIS_BOOK",nil,[NSBundle mainBundle],@"No audio is permitted for this book.",@"Alert message shown to end-user when the end-user attempts to hear a book read but no audiobook is present and TTS is not enabled.")
										delegate:nil 
							   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview") 
							   otherButtonTitles:nil];
        }
        if(!self.audioPlaying) {
            [_audioParagraphSource release];
            _audioParagraphSource = nil;
            [[BlioBookManager sharedBookManager] checkInParagraphSourceForBookWithID:self.book.objectID];
        }
    }    
    [self updatePauseButton];
}
-(void)dismissVoicesView:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[self.rootView viewWithTag:ACTIVITY_INDICATOR];
	[activityIndicator stopAnimating];
	NSString* errorMsg = [error localizedDescription];
	NSLog(@"Error loading web page: %@",errorMsg);
	[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Error Loading Page",@"\"Error Loading Page\" alert message title")
								 message:errorMsg
								delegate:nil 
					   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview") 
					   otherButtonTitles:nil];
}

- (void)search:(id)sender {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (!self.searchViewController) {
            BlioBookSearchController *aBookSearchController = [[BlioBookSearchController alloc] initWithBookID:self.book.objectID];
            [aBookSearchController setMaxPrefixAndMatchLength:20];
            [aBookSearchController setMaxSuffixLength:100];
            
			// Cannot use _returnToNavigationBarTint because it is not being set when launching directly to book
			UIColor *tintColor = [UIColor colorWithRed:160.0f / 256.0f green:190.0f / 256.0f  blue:190.0f / 256.0f  alpha:1.0f];
			
            BlioBookSearchViewController *aSearchViewController = [[BlioBookSearchViewController alloc] init];
            [aSearchViewController setTintColor:tintColor];
            [aSearchViewController setBookView:self.bookView];
            [aSearchViewController setBookSearchController:aBookSearchController]; // this retains the BlioBookSearchController
            [aBookSearchController setDelegate:aSearchViewController]; // this delegate is assigned to avoid a retain loop
            self.searchViewController = aSearchViewController;
            
            [aSearchViewController release];
            [aBookSearchController release];
        }
        [self.searchViewController showInController:self.navigationController animated:YES];
    } else {
        if (!self.searchPopover) {
            BlioBookSearchController *aBookSearchController = [[BlioBookSearchController alloc] initWithBookID:self.book.objectID];
            [aBookSearchController setMaxPrefixAndMatchLength:20];
            [aBookSearchController setMaxSuffixLength:100];
            
            BlioBookSearchPopoverController *aSearchPopover = [[BlioBookSearchPopoverController alloc] init];
            [aSearchPopover setBookView:self.bookView];
            [aSearchPopover setBookSearchController:aBookSearchController]; // this retains the BlioBookSearchController
            [aBookSearchController setDelegate:aSearchPopover]; // this delegate is assigned to avoid a retain loop
            self.searchPopover = aSearchPopover;
            [aSearchPopover release];
            [aBookSearchController release];
        }
        if (![self.searchPopover isPopoverVisible]) {
            [self.searchPopover presentPopoverFromBarButtonItem:(UIBarButtonItem *)sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }
}

#pragma mark - 
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex == 0) {
        
	}
	else if (buttonIndex == 1) {
        BlioPurchaseVoicesViewController * purchaseVoicesViewController = [[BlioPurchaseVoicesViewController alloc] initWithStyle:UITableViewStyleGrouped];
        purchaseVoicesViewController.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] 
                                                  initWithTitle:NSLocalizedString(@"Done",@"\"Done\" bar button")
                                                  style:UIBarButtonItemStyleDone 
                                                  target:self
                                                  action:@selector(dismissVoicesView:)]
                                                 autorelease];		

        UINavigationController * purchaseVoicesNavigationController = [[UINavigationController alloc] initWithRootViewController:purchaseVoicesViewController];
        [purchaseVoicesViewController release];
        [self presentModalViewController:purchaseVoicesNavigationController animated:YES];
//        [self.navigationController pushViewController:purchaseVoicesViewController animated:YES];
        [purchaseVoicesNavigationController release];
	}
}

    
#pragma mark -
#pragma mark NotesView Methods

- (void)notesViewCreateNote:(BlioNotesView *)notesView {    
    NSManagedObject *newNote = [NSEntityDescription
                                insertNewObjectForEntityForName:@"BlioNote"
                                inManagedObjectContext:[self managedObjectContext]];
    
    BlioBookmarkRange *noteRange = notesView.range;
    NSManagedObject *existingHighlight = [self.book fetchHighlightWithBookmarkRange:noteRange];
    
    if (nil != existingHighlight) {
        [newNote setValue:existingHighlight forKey:@"highlight"];
        [newNote setValue:[existingHighlight valueForKey:@"range"] forKey:@"range"];
        [newNote setValue:notesView.textView.text forKey:@"noteText"];
        
        // N.B. the mutable set must be fetched just before it is used to avoid a bookManager 
        // refresh in a side-effect (e.g. checking out a textflow) invalidating it
        NSMutableSet *notes = [self.book mutableSetValueForKey:@"notes"];
        [notes addObject:newNote];
    } else {
        if ([self.bookView respondsToSelector:@selector(selectedRange)]) {
            noteRange = [self.bookView selectedRange];
            
            NSManagedObject *newRange = [noteRange persistentBookmarkRangeInContext:[self managedObjectContext]];
            [newNote setValue:newRange forKey:@"range"];
            [newNote setValue:notesView.textView.text forKey:@"noteText"];
            
            // N.B. the mutable set must be fetched just before it is used to avoid a bookManager 
            // refresh in a side-effect (e.g. checking out a textflow) invalidating it
            NSMutableSet *notes = [self.book mutableSetValueForKey:@"notes"];
            [notes addObject:newNote];
        }
    }
    if (self.book.managedObjectContext != nil) {
		NSError *error;
		if (![[self managedObjectContext] save:&error]) 
			NSLog(@"[BlioBookViewController notesViewCreateNote:] Save failed with error: %@, %@", error, [error userInfo]);
		else 
			notesView.noteSaved = YES;
	}
}

- (void)notesViewUpdateNote:(BlioNotesView *)notesView {
    if (nil != notesView.note) {
        [notesView.note setValue:notesView.textView.text forKey:@"noteText"];
        
        BlioBookmarkRange *highlightRange = notesView.range;
        if (nil != highlightRange) {
            
            NSManagedObject *highlight = [self.book fetchHighlightWithBookmarkRange:highlightRange];

            if (nil != highlight) {
                [notesView.note setValue:highlight forKey:@"highlight"];
                [notesView.note setValue:[highlight valueForKey:@"range"] forKey:@"range"];
            }
        }
        
		if (self.book.managedObjectContext != nil) {
			NSError *error;
			if (![[self managedObjectContext] save:&error]) 
				NSLog(@"[BlioBookViewController notesViewUpdateNote:] Save failed with error: %@, %@", error, [error userInfo]);
			else 
				notesView.noteSaved = YES; 
		}
    }
}

- (void)notesViewDismissed {
    [self setToolbarsForModalOverlayActive:NO];
}

- (NSString *)displayPageNumberForBookmarkPoint:(BlioBookmarkPoint *)bookPoint {
    return [self.bookView displayPageNumberForBookmarkPoint:bookPoint];
}

#pragma mark -
#pragma mark Rotation Handling

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    if ([self isRotationLocked])
        return NO;
    else if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown && UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) return NO;
        return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if ([self.bookView respondsToSelector:@selector(willRotateToInterfaceOrientation:duration:)])
        [self.bookView willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    if ([self.searchPopover isPopoverVisible]) {
        shouldDisplaySearchAfterRotation = YES;
    }
    
    [self.wordToolPopoverController dismissPopoverAnimated:NO];
    self.wordToolPopoverController = nil;
    
    [self.searchViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.contentsPopover willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.viewSettingsPopover willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    if(self.viewSettingsSheet) {
        [self.viewSettingsSheet dismissAnimated:NO];
    }
    
    [self setNavigationBarButtonsForInterfaceOrientation:toInterfaceOrientation];
    
    [self.bookView setNeedsLayout];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if ([self.bookView respondsToSelector:@selector(didRotateFromInterfaceOrientation:)])
        [self.bookView didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [self.searchViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    [self.contentsPopover presentPopoverFromBarButtonItem:self.contentsButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    [self.contentsPopover didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [self.viewSettingsPopover presentPopoverFromBarButtonItem:self.viewSettingsButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    [self.viewSettingsPopover didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    if (shouldDisplaySearchAfterRotation) {
        shouldDisplaySearchAfterRotation = NO;
        [self.searchPopover presentPopoverFromBarButtonItem:self.searchButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        [self.searchPopover didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    }
    
    [self updateBookmarkButton];
}

- (void)pageTurnDidComplete
{
    [self updateBookmarkButton];
}

#pragma mark -
#pragma mark Back button history

- (void)pushBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint {
    [self.historyStack addObject:bookmarkPoint];
	
	if ([self.historyStack count] > 20) {
		[self.historyStack removeObjectAtIndex:0];
	}
	
	[self.backButton setEnabled:YES];
}

- (BlioBookmarkPoint *)popBookmarkPoint {
    BlioBookmarkPoint *bookmarkPoint = [[[self.historyStack lastObject] retain] autorelease];
    if (bookmarkPoint) {
        [self.historyStack removeLastObject];
    }
	
	if ([self.historyStack count] == 0) {
		[self.backButton setEnabled:NO];
	}
	
    return bookmarkPoint;
}

- (void)goBackInHistory {
    BlioBookmarkPoint *targetPoint = nil;
    BlioBookmarkPoint *savedPoint = nil;
	
    while (((savedPoint = [self popBookmarkPoint])) != nil) {
        if (![_bookView currentPageContainsBookmarkPoint:savedPoint]) {
            targetPoint = savedPoint;
            break;
        }
    }
    
    if (targetPoint != nil) {
        [self.bookView goToBookmarkPoint:targetPoint animated:YES saveToHistory:NO];
    }
}

#pragma mark -
#pragma mark BlioContentsTabViewControllerDelegate

- (void)dismissContentsTabView:(id)sender {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (self.contentsPopover) {
            [self.contentsPopover dismissPopoverAnimated:YES];
            self.contentsPopover = nil;
        }
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
}

- (void)displayNote:(NSManagedObject *)note atRange:(BlioBookmarkRange *)range animated:(BOOL)animated {
    [self setToolbarsForModalOverlayActive:YES];
    UIView *container = self.rootView;
    
    BlioNotesView *aNotesView = [[BlioNotesView alloc] initWithRange:range note:note];
    [aNotesView setDelegate:self];
    [aNotesView showInView:container animated:animated];
    [aNotesView release];
}

- (void)goToContentsBookmarkRange:(BlioBookmarkRange *)bookmarkRange animated:(BOOL)animated {
    BlioBookmarkPoint *aBookMarkPoint = bookmarkRange.startPoint;
    
    [self updatePageJumpPanelForBookmarkPoint:aBookMarkPoint animated:animated];
    [self.bookView goToBookmarkPoint:aBookMarkPoint animated:animated];
}

- (void)goToContentsUuid:(NSString *)sectionUuid animated:(BOOL)animated {
 /*   BlioBookmarkPoint *aBookMarkPoint = [_book bookm;

    [self updatePageJumpPanelForPage:newPageNumber animated:animated];
    [self updatePieButtonForPage:newPageNumber animated:animated];
*/
    [_bookView goToUuid:sectionUuid animated:animated];
}

- (void)deleteNote:(NSManagedObject *)note {
	NSManagedObject *noteRange = [note valueForKey:@"range"];
	
    // N.B. the mutable set must be fetched just before it is used to avoid a bookManager 
    // refresh in a side-effect (e.g. checking out a textflow) invalidating it
    NSMutableSet *notes = [self.book mutableSetValueForKey:@"notes"];
    [notes removeObject:note];
    
    [[self managedObjectContext] deleteObject:note];
	[[self managedObjectContext] deleteObject:noteRange];

	if (self.book.managedObjectContext != nil) {
		NSError *error;
		if (![[self managedObjectContext] save:&error]) {
			NSLog(@"[BlioBookViewController deleteNote:] Save failed with error: %@, %@", error, [error userInfo]);
		}
	}
	[self refreshHighlights];
}

#pragma mark -
#pragma mark BlioBookDelegate 

- (NSArray *)rangesToHighlightForLayoutPage:(NSInteger)pageNumber {
    return [NSArray arrayWithArray:[self.book sortedHighlightRangesForLayoutPage:pageNumber]];
}

- (NSArray *)rangesToHighlightForRange:(BlioBookmarkRange *)range {    
    return [NSArray arrayWithArray:[self.book sortedHighlightRangesForRange:range]];
}

- (void)updateHighlightAtRange:(BlioBookmarkRange *)fromRange toRange:(BlioBookmarkRange *)toRange withColor:(UIColor *)newColor {
    
    NSManagedObject *highlight = [self.book fetchHighlightWithBookmarkRange:fromRange];

    if (nil != highlight) {
        [highlight setValue:[NSNumber numberWithInteger:toRange.startPoint.layoutPage] forKeyPath:@"range.startPoint.layoutPage"];
        [highlight setValue:[NSNumber numberWithInteger:toRange.startPoint.blockOffset] forKeyPath:@"range.startPoint.blockOffset"];
        [highlight setValue:[NSNumber numberWithInteger:toRange.startPoint.wordOffset] forKeyPath:@"range.startPoint.wordOffset"];
        [highlight setValue:[NSNumber numberWithInteger:toRange.startPoint.elementOffset] forKeyPath:@"range.startPoint.elementOffset"];
        [highlight setValue:[NSNumber numberWithInteger:toRange.endPoint.layoutPage] forKeyPath:@"range.endPoint.layoutPage"];
        [highlight setValue:[NSNumber numberWithInteger:toRange.endPoint.blockOffset] forKeyPath:@"range.endPoint.blockOffset"];
        [highlight setValue:[NSNumber numberWithInteger:toRange.endPoint.wordOffset] forKeyPath:@"range.endPoint.wordOffset"];
        [highlight setValue:[NSNumber numberWithInteger:toRange.endPoint.elementOffset] forKeyPath:@"range.endPoint.elementOffset"];
        if (nil != newColor) [highlight setValue:newColor forKeyPath:@"range.color"];
        
		if (self.book.managedObjectContext != nil) {
			NSError *error;
			if (![[self managedObjectContext] save:&error])
				NSLog(@"Save after updating highlight failed with error: %@, %@", error, [error userInfo]);
		}
    }
}

- (void)removeHighlightAtRange:(BlioBookmarkRange *)range {
    // This also removes any note attached to the highlight
    NSManagedObject *existingHighlight = [self.book fetchHighlightWithBookmarkRange:range];
    
    if (nil != existingHighlight) {
        
        NSManagedObject *associatedNote = [existingHighlight valueForKey:@"note"];
        if (nil != associatedNote) {
            [[self managedObjectContext] deleteObject:associatedNote];        
        }
        
        [[self managedObjectContext] deleteObject:existingHighlight];
        
		if (self.book.managedObjectContext != nil) {
			NSError *error;
			if (![[self managedObjectContext] save:&error])
				NSLog(@"Save after removing highlight failed with error: %@, %@", error, [error userInfo]);
		}
     }
}

- (void)refreshHighlights {
	if ([self.bookView respondsToSelector:@selector(refreshHighlights)]) {
		[self.bookView refreshHighlights];
	}
}

- (void)copyWithRange:(BlioBookmarkRange*)range {
	NSArray *wordStrings = [self.book wordStringsForBookmarkRange:range];
	[[UIPasteboard generalPasteboard] setStrings:[NSArray arrayWithObject:[wordStrings componentsJoinedByString:@" "]]];
}

- (void)dismissWebTool:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)webNavigate:(id)sender {	
	BlioWebToolsViewController* webViewController = (BlioWebToolsViewController*)self.modalViewController;
	switch([sender selectedSegmentIndex] )
	{
		case 0: 
			[(UIWebView*)webViewController.topViewController.view goBack];
			break;
		case 1: 
			[(UIWebView*)webViewController.topViewController.view goForward];
			break;
		//case 2: 
		//	[(UIWebView*)webViewController.topViewController.view reload];
		//	break;
		default: 
			break;
	}
}       
       
- (void)openWebToolWithRange:(BlioBookmarkRange *)range toolType:(BlioWordToolsType)type { 
    if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
        [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Internet Connection Not Found",@"\"Internet Connection Not Found\" alert message title")
                                     message:NSLocalizedStringWithDefaultValue(@"INTERNET_REQUIRED_WEBTOOL",nil,[NSBundle mainBundle],@"An internet connection is required to perform this function.",@"Alert message when the user tries to download a book without an Internet connection.")
                                    delegate:nil 
                           cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview") 
                           otherButtonTitles:nil];		
        return;
    }
    
    NSArray *wordStrings = [self.book wordStringsForBookmarkRange:range];
    NSString *encodedParam = [[[wordStrings componentsJoinedByString:@" "] 
                               stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] 
                              stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];	
    NSString *queryString = nil;
    NSString *titleString = nil;
    switch (type) {
        case dictionaryTool:
            // TODO: get from preference
            queryString = [NSString stringWithFormat: @"http://dictionary.reference.com/browse/%@", encodedParam];
            titleString = [NSString stringWithString:NSLocalizedString(@"Dictionary",@"\"Dictionary\" web tool title")];
            break;
        case encyclopediaTool:
            switch ((BlioEncyclopediaOption)[[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastEncyclopediaDefaultsKey]) {
                case wikipediaOption:
                    queryString = [NSString stringWithFormat:@"http://en.wikipedia.org/wiki/%@", encodedParam];
                    break;
                case britannicaOption:
                    queryString = [NSString stringWithFormat: @"http://www.britannica.com/bps/search?query=%@", encodedParam];
                    break;
                default:
                    break;
            }  
            titleString = [NSString stringWithString:NSLocalizedString(@"Encyclopedia",@"\"Encyclopedia\" web tool title")];
            break;			
        case searchTool:
            switch ((BlioSearchEngineOption)[[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastSearchEngineDefaultsKey]) {
                case googleOption:
                    queryString = [NSString stringWithFormat: @"http://www.google.com/search?hl=en&source=hp&q=%@", encodedParam];
                    break;
                case yahooOption:
                    queryString = [NSString stringWithFormat: @"http://search.yahoo.com/search?p=%@", encodedParam];
                    break;
                case bingOption:
                    queryString = [NSString stringWithFormat: @"http://www.bing.com/search?q=%@", encodedParam];
                    break;
                default:
                    break;
            }  
            titleString = [NSString stringWithString:NSLocalizedString(@"Web Search",@"\"Web Search\" web tool title")];
            break;
        default:
            break;
    }
    NSURL *url = [NSURL URLWithString:queryString];
    if (nil != url) {
        BlioWebToolsViewController *aWebToolController = [[BlioWebToolsViewController alloc] initWithURL:url];
        UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done",@"\"Done\" bar button") style:UIBarButtonItemStyleDone target:self action:@selector(dismissWebTool:)];
        aWebToolController.topViewController.navigationItem.rightBarButtonItem = rightItem; 
        [rightItem release];
        aWebToolController.topViewController.navigationItem.title = titleString;
        
        //NSArray *buttonNames = [NSArray arrayWithObjects:@"B", @"F", nil]; // until there's icons...
        NSArray *buttonNames = [NSArray arrayWithObjects:[UIImage imageNamed:@"back-black.png"], [UIImage imageNamed:@"forward-black.png"], nil]; // until there's icons...
        UISegmentedControl* segmentedControl = [[UISegmentedControl alloc] initWithItems:buttonNames];
        segmentedControl.momentary = YES;
        segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        segmentedControl.frame = CGRectMake(0, 0, 70, 30);
        [segmentedControl addTarget:self action:@selector(webNavigate:) forControlEvents:UIControlEventValueChanged];
        [segmentedControl setEnabled:NO forSegmentAtIndex:0];
        [segmentedControl setEnabled:NO forSegmentAtIndex:1];
        UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
        [segmentedControl release];
        aWebToolController.topViewController.navigationItem.leftBarButtonItem = segmentBarItem;
        [segmentBarItem release];
        
        aWebToolController.navigationBar.tintColor = _returnToNavigationBarTint;
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        [self presentModalViewController:aWebToolController animated:YES];
        [aWebToolController release];
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if(popoverController == self.wordToolPopoverController) {
        self.wordToolPopoverController = nil;
    }
}

- (void)openWordToolWithRange:(BlioBookmarkRange *)range atRect:(CGRect)rect toolType:(BlioWordToolsType)type { 
    if(type == dictionaryTool && NSClassFromString(@"UIReferenceLibraryViewController")) { 
        NSString *words = [[[self.book wordStringsForBookmarkRange:range] componentsJoinedByString:@" "] stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
        
        UIReferenceLibraryViewController *libraryViewController = [[UIReferenceLibraryViewController alloc] initWithTerm:words];
        
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            // Would be great to size this to an appropriate size for the actual content of
            // the library view, but there's no way to get that.
            libraryViewController.view.frame = CGRectMake(0, 0, 320, 320);
            libraryViewController.contentSizeForViewInPopover = CGSizeMake(320, 320);
            UIPopoverController *dictionaryPopover = [[UIPopoverController alloc] initWithContentViewController:libraryViewController];
            [dictionaryPopover presentPopoverFromRect:rect
                                               inView:self.bookView
                             permittedArrowDirections:UIPopoverArrowDirectionAny
                                             animated:YES];
            dictionaryPopover.delegate = self;
            self.wordToolPopoverController = dictionaryPopover;
            [dictionaryPopover release];
        } else {
            [[self navigationController] presentModalViewController:libraryViewController animated:YES];
        }
    
        [libraryViewController release];
    } else { 
        [self openWebToolWithRange:range toolType:type];
    }
}

#pragma mark -
#pragma mark Edit Menu Responder Actions 

- (void)addHighlightWithColor:(UIColor *)color {
    if ([self.bookView respondsToSelector:@selector(selectedRange)]) {
        BlioBookmarkRange *selectedRange = [self.bookView selectedRange];
        NSManagedObject *existingHighlight = [self.book fetchHighlightWithBookmarkRange:selectedRange];
        
        if (nil != existingHighlight) {
            [existingHighlight setValue:color forKeyPath:@"range.color"];
        } else {

            NSManagedObject *newHighlight = [NSEntityDescription
                                             insertNewObjectForEntityForName:@"BlioHighlight"
                                             inManagedObjectContext:[self managedObjectContext]];
            
            NSManagedObject *newRange = [selectedRange persistentBookmarkRangeInContext:[self managedObjectContext]];
            [newRange setValue:color forKey:@"color"];
            [newHighlight setValue:newRange forKey:@"range"];
            
            // N.B. the mutable set must be fetched just before it is used to avoid a bookManager 
            // refresh in a side-effect (e.g. checking out a textflow) invalidating it
            NSMutableSet *highlights = [self.book mutableSetValueForKey:@"highlights"];
            [highlights addObject:newHighlight];
        }
        if (self.book.managedObjectContext != nil) {
			NSError *error;
			if (![[self managedObjectContext] save:&error])
				NSLog(@"[BlioBookViewController addHighlightWithColor:] Save failed with error: %@, %@", error, [error userInfo]);
		}
    }
    
    //if ([self.bookView respondsToSelector:@selector(refreshHighlights)])
        //[self.bookView refreshHighlights];
}

- (BOOL)hasNoteOverlappingSelectedRange {
	return ([[self.book fetchHighlightWithBookmarkRange:[self.bookView selectedRange]] valueForKey:@"note"] != nil);
}

- (void)addHighlightNoteWithColor:(UIColor *)color {
	
	[self addHighlightWithColor:color];
    
    if ([self.bookView respondsToSelector:@selector(selectedRange)]) {
        BlioBookmarkRange *range = [self.bookView selectedRange];
        [self displayNote:nil atRange:range animated:YES];
    }
	
}

- (void)updateHighlightNoteAtRange:(BlioBookmarkRange *)highlightRange toRange:(BlioBookmarkRange *)toRange withColor:(UIColor *)newColor {
    if ([self.bookView respondsToSelector:@selector(selectedRange)]) {
        NSManagedObject *existingNote = nil;
        NSManagedObject *highlight = [self.book fetchHighlightWithBookmarkRange:highlightRange];
        
        if (nil != highlight) {
            if(toRange) {
                [highlight setValue:[NSNumber numberWithInteger:toRange.startPoint.layoutPage] forKeyPath:@"range.startPoint.layoutPage"];
                [highlight setValue:[NSNumber numberWithInteger:toRange.startPoint.blockOffset] forKeyPath:@"range.startPoint.blockOffset"];
                [highlight setValue:[NSNumber numberWithInteger:toRange.startPoint.wordOffset] forKeyPath:@"range.startPoint.wordOffset"];
                [highlight setValue:[NSNumber numberWithInteger:toRange.startPoint.elementOffset] forKeyPath:@"range.startPoint.elementOffset"];
                [highlight setValue:[NSNumber numberWithInteger:toRange.endPoint.layoutPage] forKeyPath:@"range.endPoint.layoutPage"];
                [highlight setValue:[NSNumber numberWithInteger:toRange.endPoint.blockOffset] forKeyPath:@"range.endPoint.blockOffset"];
                [highlight setValue:[NSNumber numberWithInteger:toRange.endPoint.wordOffset] forKeyPath:@"range.endPoint.wordOffset"];
                [highlight setValue:[NSNumber numberWithInteger:toRange.endPoint.elementOffset] forKeyPath:@"range.endPoint.elementOffset"];
            } else {
                toRange = [BlioBookmarkRange bookmarkRangeWithPersistentBookmarkRange:[highlight valueForKey:@"range"]];
            }
            if (nil != newColor) [highlight setValue:newColor forKeyPath:@"range.color"];
            
			if (self.book.managedObjectContext != nil) {
				NSError *error;
				if (![[self managedObjectContext] save:&error])
					NSLog(@"Save after updating highlight failed with error: %@, %@", error, [error userInfo]);
            }
            existingNote = [highlight valueForKey:@"note"];
        }
        
        
        [self displayNote:existingNote atRange:toRange animated:YES];
    }
}

- (void)setPreviewThumb:(UIImage *)thumb {
	[thumbPreview setThumb:thumb];
	
	if (thumb && (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {
		CGFloat sliderMin = _pageJumpSlider.minimumValue;
		CGFloat sliderMax = _pageJumpSlider.maximumValue;
		CGFloat sliderMaxMinDiff = sliderMax - sliderMin;
		CGFloat sliderValue = _pageJumpSlider.value;
	
		CGRect sliderFrame = [_pageJumpView convertRect:_pageJumpSlider.frame toView:self.rootView];
		CGFloat xCoord = CGRectGetMinX(sliderFrame) + ((sliderValue-sliderMin)/sliderMaxMinDiff) * CGRectGetWidth(sliderFrame);	
		CGFloat yCoord = CGRectGetMidY(sliderFrame);
		
		[thumbPreview setThumbAnchorPoint:CGPointMake(xCoord, yCoord)];
	}
}

#pragma mark - Bookmarked Pages

- (void)deleteBookmark:(NSManagedObject *)bookmark {
    // N.B. the mutable set must be fetched just before it is used to avoid a bookManager 
    // refresh in a side-effect (e.g. checking out a textflow) invalidating it
    NSMutableSet *bookmarks = [self.book mutableSetValueForKey:@"bookmarks"];
    [bookmarks removeObject:bookmark];
    
    NSError *error;
    
    if (self.book.managedObjectContext != nil) {
        if (![[self managedObjectContext] save:&error]) {
            NSLog(@"[BlioBookViewController deleteBookmark:] Save failed with error: %@, %@", error, [error userInfo]);
        }
    }
    
    [self updateBookmarkButton];
}

- (void)updateBookmarkButton
{
    id<BlioBookView> myBookView = self.bookView;
    
    // Might be inclusive /or/ exclusive of the endpoint.
    BlioBookmarkRange *currentPageRange = [myBookView bookmarkRangeForCurrentPage];
    
    // Looks up inclusively of the endpoint.
    NSArray *bookmarksForCurrentPage = [self.book sortedBookmarksForRange:currentPageRange];

    // Because the range might really be meant to be exclusive, check explicitly
    // whether any returned bookmark is actually in the current page.
    BOOL pageContainsAtLeastOneBookmark = NO;
    for (NSManagedObject *persistedBookmark in bookmarksForCurrentPage) {
        BlioBookmarkRange *range = [BlioBookmarkRange bookmarkRangeWithPersistentBookmarkRange:[persistedBookmark valueForKey:@"range"]];
        BlioBookmarkPoint *startPoint = range.startPoint;
        if ([myBookView currentPageContainsBookmarkPoint:startPoint]){
            pageContainsAtLeastOneBookmark = YES;
            break;
        }
    }
    
    if (pageContainsAtLeastOneBookmark) {
        UIImage *bookmarked = [UIImage appleLikeBeveledImage:[UIImage imageNamed:@"icon-bookmarked"]];

        [self.bookmarkButton setImage:bookmarked forState:UIControlStateNormal];
        [self.bookmarkButton setImage:bookmarked forState:UIControlStateHighlighted];
        [self.bookmarkButton setAccessibilityHint:NSLocalizedString(@"Removes bookmark for the current page.", @"Accessibility label for Book View Controller Remove Bookmark hint")];
    } else {
        UIImage *add = [UIImage appleLikeBeveledImage:[UIImage imageNamed:@"icon-add"]];

        [self.bookmarkButton setImage:add forState:UIControlStateNormal];
        [self.bookmarkButton setImage:add forState:UIControlStateHighlighted];
        [self.bookmarkButton setAccessibilityHint:NSLocalizedString(@"Adds bookmark for the current page.", @"Accessibility label for Book View Controller Add Bookmark hint")];
    }
}

- (void)toggleBookmark:(id)sender 
{	   
    id<BlioBookView> myBookView = self.bookView;
    
    // Might be inclusive /or/ exclusive of the endpoint.
    BlioBookmarkRange *currentPageRange = [myBookView bookmarkRangeForCurrentPage];
    
    // Looks up inclusively of the endpoint.
    NSArray *bookmarksForCurrentPage = [self.book sortedBookmarksForRange:currentPageRange];

    BOOL removedBookmark = NO;
    if ([bookmarksForCurrentPage count]) {
        for (NSManagedObject *persistedBookmark in bookmarksForCurrentPage) {
            
            // Because the range might really be meant to be exclusive, check explicitly
            // whether any returned bookmark is actually in the current page before
            // deleting it.
            BlioBookmarkRange *range = [BlioBookmarkRange bookmarkRangeWithPersistentBookmarkRange:[persistedBookmark valueForKey:@"range"]];
            BlioBookmarkPoint *startPoint = range.startPoint;
            if ([myBookView currentPageContainsBookmarkPoint:startPoint]){
                [[self managedObjectContext] deleteObject:persistedBookmark];
                removedBookmark = YES;
            }
        }
    } 
    
    if(!removedBookmark) {
        // If we haven't removed any bookmarks, there were none in the current
        // page, so make one.
        BlioBookmarkPoint *currentBookmarkPoint = self.bookView.currentBookmarkPoint;
        BlioBookmarkRange *currentBookmarkRange = [BlioBookmarkRange bookmarkRangeWithBookmarkPoint:currentBookmarkPoint];
                
        if (currentBookmarkRange) {
            NSManagedObject *newBookmarkRange = [currentBookmarkRange persistentBookmarkRangeInContext:[self managedObjectContext]];
            
            if (newBookmarkRange) {
                
                NSArray *wordStrings = [self.book wordStringsForBookmarkRange:currentPageRange];
                NSString *bookmarkText = nil;
                
                if ([wordStrings count] > 0) {
                    bookmarkText = [wordStrings componentsJoinedByString:@" "];
                }
                
                if ([bookmarkText length] > kBlioMaxBookmarkTextLength) {
                    bookmarkText = [bookmarkText substringToIndex:kBlioMaxBookmarkTextLength];
                }
                
                NSManagedObject *newBookmark = [NSEntityDescription
                                                insertNewObjectForEntityForName:@"BlioBookmark"
                                                inManagedObjectContext:[self managedObjectContext]];
                [newBookmark setValue:newBookmarkRange forKey:@"range"];
                
                if (bookmarkText) {
                    [newBookmark setValue:bookmarkText forKey:@"bookmarkText"];
                }

                // N.B. the mutable set must be fetched just before it is used to avoid a bookManager 
                // refresh in a side-effect (e.g. checking out a textflow) invalidating it
                NSMutableSet *allBookmarks = [self.book mutableSetValueForKey:@"bookmarks"];
                [allBookmarks addObject:newBookmark];
            }
        }
    }
    
    NSError *error;
    
    if (self.book.managedObjectContext != nil) {
        if (![[self managedObjectContext] save:&error]) {
            NSLog(@"BlioBookViewController toggleBookmark save failed with error: %@, %@", error, [error userInfo]);
        }
    }
    
    [self updateBookmarkButton];
}

@end

@implementation BlioBookSlider 

@synthesize touchInProgress, bookViewController;

- (void)dealloc {
    self.bookViewController = nil;
    [super dealloc];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	touchInProgress = YES;

	BOOL shouldBeginTracking = [super beginTrackingWithTouch:touch withEvent:event];

	if (shouldBeginTracking) {
        [self.bookViewController setPageJumpSliderPreview];
		[self.bookViewController.thumbPreview showThumb:YES];
	} else {
		touchInProgress = NO;
	}
    return shouldBeginTracking;
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    touchInProgress = NO;
	[self.bookViewController.thumbPreview showThumb:NO];
    [super cancelTrackingWithEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    touchInProgress = NO;
	[self.bookViewController.thumbPreview showThumb:NO];
    [super endTrackingWithTouch:touch withEvent:event];
}

- (void)accessibilityIncrement {
    [self.bookViewController performSelectorOnMainThread:@selector(incrementPage) withObject:nil waitUntilDone:YES];
}

- (void)accessibilityDecrement {
    [self.bookViewController performSelectorOnMainThread:@selector(decrementPage) withObject:nil waitUntilDone:YES];
}

@end

@implementation BlioBookSliderPreview

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		
		CGFloat width, height;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			width = kBlioBookSliderPreviewWidthPad;
			height = kBlioBookSliderPreviewHeightPad;
		} else {
			width = kBlioBookSliderPreviewWidthPhone;
			height = kBlioBookSliderPreviewHeightPhone;
		}
		
		thumbImage = [[UIImageView alloc] initWithFrame:CGRectInset(self.bounds, (CGRectGetWidth(self.bounds) - width)/2.0f, (CGRectGetHeight(self.bounds) - height)/2.0f)];
		thumbImage.contentMode = UIViewContentModeScaleAspectFit;
		thumbImage.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		[self addSubview:thumbImage];
		
		thumbImage.layer.shadowRadius = kBlioBookSliderPreviewShadowRadius;
		thumbImage.layer.shadowOpacity = 0.7f;
		thumbImage.layer.shouldRasterize = YES;
		thumbImage.layer.shadowOffset = CGSizeZero;
		thumbImage.layer.zPosition = 1000; // to raise it's shadow above the slider
		
		self.backgroundColor = [UIColor redColor];
	}
	return self;
}

- (void)dealloc {
	[thumbImage release], thumbImage = nil;
	[super dealloc];
}

- (void)showThumb:(BOOL)show {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:0.2f];
	if (thumbImage.image) {
		if (show) {
			[self setAlpha:1];
		} else {
			[self setAlpha:0.01f];
		}
	} else {
		[self setAlpha:0.01f];
	}
	[UIView commitAnimations];
}

- (void)layoutSubviews {	
	[super layoutSubviews];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		CGRect viewBounds = self.bounds;
		BOOL isLandscape = CGRectGetWidth(viewBounds) > CGRectGetHeight(viewBounds);

		CGRect thumbFrame = thumbImage.frame;
		thumbFrame.origin.y = floorf((CGRectGetHeight(self.frame) - CGRectGetHeight(thumbFrame)) / 2.0f);
		if (isLandscape) {
			thumbFrame.origin.y += kBlioBookSliderPreviewPhoneLandscapeOffset;
		}
		
		thumbImage.frame = thumbFrame;
	}
}

- (CGRect)thumbBounds {
	CGSize thumbSize = thumbImage.image.size;
	CGFloat scale = MIN(CGRectGetWidth(thumbImage.bounds) / thumbSize.width, CGRectGetHeight(thumbImage.bounds) / thumbSize.height);
	CGRect thumbBounds = CGRectMake(0, 0, thumbSize.width * scale, thumbSize.height * scale);
	thumbBounds.origin.x = (CGRectGetWidth(thumbImage.bounds) - CGRectGetWidth(thumbBounds))/2.0f;
	thumbBounds.origin.y = (CGRectGetHeight(thumbImage.bounds) - CGRectGetHeight(thumbBounds))/2.0f;
	return thumbBounds;
}

- (void)setThumb:(UIImage *)newThumb {
	[thumbImage setImage:newThumb];
	
	CGMutablePathRef shadowPath = CGPathCreateMutable();
	CGPathAddRect(shadowPath, NULL, [self thumbBounds]);
	[thumbImage.layer setShadowPath:shadowPath];
	CGPathRelease(shadowPath);
}

- (void)setThumbAnchorPoint:(CGPoint)anchor {
	CGRect thumbBounds = [self thumbBounds];
	
	CGPoint center = CGPointMake(anchor.x, anchor.y + kBlioBookSliderPreviewAnchorOffset + CGRectGetHeight(thumbBounds)/2.0f);
	
	center.x = MAX(center.x, CGRectGetWidth(thumbBounds)/2.0f + kBlioBookSliderPreviewEdgeInset);
	center.x = MIN(center.x, CGRectGetWidth(self.superview.frame) - CGRectGetWidth(thumbBounds)/2.0f - kBlioBookSliderPreviewEdgeInset);
	
	[thumbImage setCenter:center];

}

@end

