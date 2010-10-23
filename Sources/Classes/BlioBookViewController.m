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
#import <libEucalyptus/EucBookContentsTableViewController.h>
#import "BlioBookViewControllerProgressPieButton.h"
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
#import "BlioModalPopoverController.h"
#import "BlioBookSearchPopoverController.h"
#import "Reachability.h"

static NSString * const kBlioLastLayoutDefaultsKey = @"lastLayout";
static NSString * const kBlioLastFontSizeDefaultsKey = @"lastFontSize";
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

static const CGFloat kBlioFontPointSizeArray[] = { 14.0f, 16.0f, 18.0f, 20.0f, 22.0f };

static NSString *kBlioFontPageTextureNamesArray[] = { @"paper-white.png", @"paper-black.png", @"paper-neutral.png" };
static const BOOL kBlioFontPageTexturesAreDarkArray[] = { NO, YES, NO };

@interface BlioBookViewController ()

@property (nonatomic, retain) BlioBookSearchViewController *searchViewController;
@property (nonatomic, retain) UIActionSheet *viewSettingsSheet;
@property (nonatomic, retain) BlioModalPopoverController *viewSettingsPopover;
@property (nonatomic, retain) BlioModalPopoverController *contentsPopover;
@property (nonatomic, retain) BlioModalPopoverController *searchPopover;
@property (nonatomic, retain) UIBarButtonItem *contentsButton;
@property (nonatomic, retain) UIBarButtonItem *addButton;
@property (nonatomic, retain) UIBarButtonItem *viewSettingsButton;
@property (nonatomic, retain) UIBarButtonItem *searchButton;
@property (nonatomic, retain) UIBarButtonItem *backButton;
@property (nonatomic, retain) NSMutableArray *historyStack;

- (NSArray *)_toolbarItemsWithTTSInstalled:(BOOL)installed enabled:(BOOL)enabled;
- (void) _updatePageJumpLabelForPage:(NSInteger)page;
- (void) updatePageJumpPanelForPage:(NSInteger)pageNumber animated:(BOOL)animated;
- (void)displayNote:(NSManagedObject *)note atRange:(BlioBookmarkRange *)range animated:(BOOL)animated;
- (void)layoutPauseButton;
@end

@interface BlioBookSlider : UISlider {
    BOOL touchInProgress;
    BlioBookViewController *bookViewController;
}

@property (nonatomic) BOOL touchInProgress;
@property (nonatomic, assign) BlioBookViewController *bookViewController;

@end

@interface BlioBookViewController()

- (void)animateCoverPop;
- (void)animateCoverShrink;
- (void)animateCoverFade;
- (void)initialiseControls;
- (void)initialiseBookView;
- (void)toggleBookmark:(id)sender;
@end

@implementation BlioBookViewController

@synthesize book = _book;
@synthesize bookView = _bookView;
@synthesize pageJumpView = _pageJumpView;
@synthesize pieButton = _pieButton;
@synthesize pauseButton = _pauseButton;

@synthesize returnToNavigationBarStyle = _returnToNavigationBarStyle;
@synthesize returnToStatusBarStyle = _returnToStatusBarStyle;
@synthesize returnToNavigationBarHidden = _returnToNavigationBarHidden;
@synthesize returnToStatusBarHidden = _returnToStatusBarHidden;

@synthesize currentPageColor = _currentPageColor;

@synthesize audioPlaying = _audioPlaying;
@synthesize managedObjectContext = _managedObjectContext;

@synthesize motionControlsEnabled;
@synthesize rotationLocked;

@synthesize searchViewController;
@synthesize delegate;
@synthesize coverView;
@synthesize historyStack;
@synthesize viewSettingsSheet, viewSettingsPopover, contentsPopover, searchPopover, contentsButton, addButton, viewSettingsButton, searchButton, backButton;

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
        
        self.book = newBook;
        self.delegate = aDelegate;
        self.wantsFullScreenLayout = YES;
        [self initialiseControls];
        self.historyStack = [NSMutableArray array];
        
        self.coverView = [self.delegate coverViewViewForOpening];
        
        if (self.coverView) {
            [self animateCoverPop];
            [self setToolbarsVisibleAfterAppearance:NO];
        } else {
            coverOpened = YES;
            [self initialiseBookView];
            [self setToolbarsVisibleAfterAppearance:YES];
            BlioBookmarkPoint *implicitPoint = [newBook implicitBookmarkPoint];
            [self.bookView goToBookmarkPoint:implicitPoint animated:NO saveToHistory:NO];
        }
        
        if([[UIDevice currentDevice] compareSystemVersion:@"4.0"] >= NSOrderedSame) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    } 
    
    return self;
} 
 
- (void)initialiseControls {
    EucBookTitleView *titleView = [[EucBookTitleView alloc] init];
    CGRect frame = titleView.frame;
    frame.size.width = [[UIScreen mainScreen] bounds].size.width;
    [titleView setFrame:frame];
    titleView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    self.navigationItem.titleView = titleView;
    [titleView release];
    
    _firstAppearance = YES;
    
    self.audioPlaying = NO;
    
    _TTSEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kBlioTTSEnabledDefaultsKey];
    
    if (_TTSEnabled) {
        
        if ((![self.book hasAudiobook]) && (![self.book hasTTSRights] || !self.book.paragraphSource)) {
            self.toolbarItems = [self _toolbarItemsWithTTSInstalled:YES enabled:NO];
        }
		else {
            self.toolbarItems = [self _toolbarItemsWithTTSInstalled:YES enabled:YES];
            
            if ([self.book hasAudiobook]) {
//                _audioBookManager = [[BlioAudioBookManager alloc] initWithPath:[self.book timingIndicesPath] metadataPath:[self.book audiobookPath]];        
                _audioBookManager = [[BlioAudioBookManager alloc] initWithBookID:self.book.objectID];        
            } else {
                _acapelaAudioManager = [BlioAcapelaAudioManager sharedAcapelaAudioManager];
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
    
    _pageJumpView = nil;
}

- (void)initialiseBookView {
   
    BlioPageLayout lastLayout = [[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastLayoutDefaultsKey];
    
    if (!([self.book hasEPub] || [self.book hasTextFlow]) && (lastLayout == kBlioPageLayoutSpeedRead)) {
        lastLayout = kBlioPageLayoutPlainText;
    }            
    if (!([self.book hasPdf] || [self.book hasXps]) && (lastLayout == kBlioPageLayoutPageLayout)) {
        lastLayout = kBlioPageLayoutPlainText;
    } else if (((![self.book hasEPub] && ![self.book hasTextFlow]) || ![self.book reflowEnabled]) && (lastLayout == kBlioPageLayoutPlainText)) {
        lastLayout = kBlioPageLayoutPageLayout;
    }

    switch (lastLayout) {
        case kBlioPageLayoutSpeedRead: {
            if ([self.book hasEPub] || [self.book hasTextFlow]) {
                BlioSpeedReadView *aBookView = [[BlioSpeedReadView alloc] initWithFrame:self.view.bounds 
                                                                                 bookID:self.book.objectID
                                                                               animated:YES];
                aBookView.delegate = self;
                self.bookView = aBookView; 
                [aBookView release];
            }   
        }
            break;
        case kBlioPageLayoutPageLayout: {
            if ([self.book hasPdf] || [self.book hasXps]) {
                BlioLayoutView *aBookView = [[BlioLayoutView alloc] initWithFrame:self.view.bounds 
                                                                           bookID:self.book.objectID
                                                                         animated:YES];
                aBookView.delegate = self;
                self.bookView = aBookView;
                [aBookView release];
            }
        }
            break;
        default: {
            if ([self.book hasEPub] || [self.book hasTextFlow]) {
                BlioFlowView *aBookView = [[BlioFlowView alloc] initWithFrame:self.view.bounds 
                                                                       bookID:self.book.objectID
                                                                     animated:YES];
                aBookView.delegate = self;
                self.bookView = aBookView;
                [aBookView release];
            }
        } 
            break;
    }
    
    self.currentPageColor = [[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastPageColorDefaultsKey];
    
    bookReady = YES;
    
    //if (![self.bookView isKindOfClass:[BlioLayoutView class]]) {
        firstPageReady = YES;
    //}
    
}

- (void)firstPageDidRender {
    firstPageReady = YES;
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
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
}

- (void)animateCoverShrink {
    if (!(bookReady && coverReady)) {
        [self performSelector:@selector(animateCoverShrink) withObject:nil afterDelay:0.2f];
        return;
    }
    
    CGRect coverRect = [[self bookView] firstPageRect];
    CGFloat coverRectXScale = CGRectGetWidth(coverRect) / CGRectGetWidth(self.coverView.frame);
    CGFloat coverRectYScale = CGRectGetHeight(coverRect) / CGRectGetHeight(self.coverView.frame);
    
    CABasicAnimation *shrinkAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    [shrinkAnimation setToValue:[NSValue valueWithCATransform3D:CATransform3DMakeScale(coverRectXScale, coverRectYScale, 1)]];
    if (CGRectEqualToRect(coverRect, self.coverView.frame)) {
        [shrinkAnimation setDuration:0];
    } else {
        [shrinkAnimation setDuration:0.5f];
    }
    [shrinkAnimation setRemovedOnCompletion:NO];
    [shrinkAnimation setFillMode:kCAFillModeForwards];
    [shrinkAnimation setDelegate:self];
    [shrinkAnimation setValue:kBlioBookViewControllerCoverShrinkAnimation forKey:@"name"];    
 
    [self.coverView.layer setPosition:[(CALayer *)[self.coverView.layer presentationLayer] position]];
    [self.coverView.layer setTransform:[(CALayer *)[self.coverView.layer presentationLayer] transform]];
    //[self.coverView.layer setZPosition:[(CALayer *)[self.coverView.layer presentationLayer] zPosition]];
    
    [self.coverView.layer removeAllAnimations];
    
    [self.coverView.layer addAnimation:shrinkAnimation forKey:kBlioBookViewControllerCoverShrinkAnimation];        
}

- (void)animateCoverFade {   
    if (!firstPageReady) {
        [self performSelector:@selector(animateCoverFade) withObject:nil afterDelay:0.2f];
        return;
    }
    
    CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [fadeAnimation setToValue:[NSNumber numberWithFloat:0]];
    [fadeAnimation setDuration:0.5f];
    [fadeAnimation setValue:kBlioBookViewControllerCoverFadeAnimation forKey:@"name"];
    [fadeAnimation setDelegate:self];
    [fadeAnimation setRemovedOnCompletion:NO];
    [fadeAnimation setFillMode:kCAFillModeForwards];
    
    [self.coverView.layer setTransform:[(CALayer *)[self.coverView.layer presentationLayer] transform]];
    
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
        
        //[self.bookView goToPageNumber:10 animated:YES];
        BlioBookmarkPoint *implicitPoint = [self.book implicitBookmarkPoint];
        [self.bookView goToBookmarkPoint:implicitPoint animated:YES];
        coverOpened = YES;
    }
}

- (NSArray *)_toolbarItemsWithTTSInstalled:(BOOL)installed enabled:(BOOL)enabled {
    
    NSMutableArray *readingItems = [NSMutableArray array];
    UIBarButtonItem *item;
    /*
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
	*/
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
	
     /*
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];
  
    item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-plus.png"]
                                            style:UIBarButtonItemStylePlain
                                           target:self 
                                           action:@selector(showAddMenu:)];
    
    [item setAccessibilityLabel:NSLocalizedString(@"Add", @"Accessibility label for Book View Controller Add button")];
    [item setAccessibilityHint:NSLocalizedString(@"Adds bookmark or note.", @"Accessibility label for Book View Controller Add hint")];

    [readingItems addObject:item];
    [item release];
 */

	item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];
	
//	UIButton * aButton = [UIButton buttonWithType:UIButtonTypeCustom];
//	aButton.showsTouchWhenHighlighted = YES;
//	[aButton setBackgroundImage:[UIImage imageNamed:@"icon-add.png"] forState:UIControlStateNormal];
//	[[aButton addTarget:self action:@selector(toggleBookmark:) forControlEvents:UIControlEventTouchUpInside];
	item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-add.png"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleBookmark:)];
    [item setAccessibilityLabel:NSLocalizedString(@"Bookmark", @"Accessibility label for Book View Controller Bookmark button")];
    [item setAccessibilityHint:NSLocalizedString(@"Adds bookmark for the current page.", @"Accessibility label for Book View Controller Bookmark hint")];
    self.addButton = item;
    [readingItems addObject:item];
    [item release];

    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];  
    
    item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-search.png"]
                                            style:UIBarButtonItemStylePlain
                                           target:self 
                                           action:@selector(search:)];
    [item setAccessibilityLabel:NSLocalizedString(@"Search", @"Accessibility label for Book View Controller Search button")];
    self.searchButton = item;
    [readingItems addObject:item];
    [item release];
    
    if (installed) {
        item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [readingItems addObject:item];
        [item release];  
        
        UIImage *audioImage = nil;
        if (enabled) {
            audioImage = [UIImage imageNamed:@"icon-play.png"];
            item = [[UIBarButtonItem alloc] initWithImage:audioImage
                                                    style:UIBarButtonItemStylePlain
                                                   target:self 
                                                   action:@selector(toggleAudio:)];
            [item setAccessibilityLabel:NSLocalizedString(@"Play", @"Accessibility label for Book View Controller Play button")];
            [item setAccessibilityHint:NSLocalizedString(@"Starts audio.", @"Accessibility label for Book View Controller Play hint")];
            
            if([[UIDevice currentDevice] compareSystemVersion:@"4.0"] >= NSOrderedSame) {
                [item setAccessibilityTraits:UIAccessibilityTraitButton | UIAccessibilityTraitPlaysSound | UIAccessibilityTraitStartsMediaSession];
            } else {
                [item setAccessibilityTraits:UIAccessibilityTraitButton | UIAccessibilityTraitPlaysSound];
            }
			if ( ([self currentPageLayout] == kBlioPageLayoutPlainText) && [self.book hasAudiobook] )
				[item setEnabled:NO];
            
        } else {
            audioImage = [UIImage imageNamed:@"icon-noTTS.png"];
            item = [[UIBarButtonItem alloc] initWithImage:audioImage
                                                    style:UIBarButtonItemStylePlain
                                                   target:nil 
                                                   action:nil];
            [item setEnabled:NO];
            [item setAccessibilityLabel:NSLocalizedString(@"Audio is not available for this book", @"Accessibility label for Book View Controller Audio unavailable button")];
            if([[UIDevice currentDevice] compareSystemVersion:@"4.0"] >= NSOrderedSame) {
                [item setAccessibilityTraits:UIAccessibilityTraitButton | UIAccessibilityTraitPlaysSound | UIAccessibilityTraitStartsMediaSession| UIAccessibilityTraitNotEnabled];
            } else {
                [item setAccessibilityTraits:UIAccessibilityTraitButton | UIAccessibilityTraitPlaysSound | UIAccessibilityTraitNotEnabled];
            }
        }

    [readingItems addObject:item];
    [item release];
    }
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-eye.png"]
                                            style:UIBarButtonItemStylePlain
                                           target:self 
                                           action:@selector(showViewSettings:)];
    
    [item setAccessibilityLabel:NSLocalizedString(@"Settings", @"Accessibility label for Book View Controller Settings button")];
    self.viewSettingsButton = item;
    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];
    
    return [NSArray arrayWithArray:readingItems];
}

- (void)setBookView:(UIView<BlioBookView> *)bookView
{
        
    if(_bookView != bookView) {
        if(_bookView) {
            //if (bookView != nil) [self removeObserver:_bookView forKeyPath:@"audioPlaying"];
            [_bookView removeObserver:self forKeyPath:@"pageNumber"];
            [_bookView removeObserver:self forKeyPath:@"pageCount"];        
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
                EucBookTitleView *titleView = (EucBookTitleView *)self.navigationItem.titleView;
                [titleView setTitle:[self.book title]];
                [titleView setAuthor:[self.book authorsWithStandardFormat]];              
                
                [self.view addSubview:_bookView];
                [self.view sendSubviewToBack:_bookView];
                
                if ([_bookView wantsTouchesSniffed]) {
                    [(THEventCapturingWindow *)_bookView.window addTouchObserver:self forView:_bookView];            
                }
            }
            
            // Pretend that we last saved this page number, so that we 
            // don't save it again until the user switched a page.  This keeps
            // the saved point stable when the user switches between different
            // views repeatedly.
            _lastSavedPageNumber = _bookView.pageNumber;
            
            [_bookView addObserver:self 
                        forKeyPath:@"pageNumber" 
                           options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                           context:nil];
            
            [_bookView addObserver:self 
                        forKeyPath:@"pageCount" 
                           options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                           context:nil];   
            
            /*[self addObserver:_bookView 
                   forKeyPath:@"audioPlaying" 
                      options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                      context:nil];*/
        }
    }
}

- (void)_backButtonTapped
{
    _viewIsDisappearing = YES;
    [self.searchViewController removeFromControllerAnimated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)updatePieButtonForPage:(NSInteger)pageNumber animated:(BOOL)animated {
    [self.pieButton setProgress:pageNumber/(CGFloat)self.bookView.pageCount];
}


- (void)updatePieButtonAnimated:(BOOL)animated {
    [self updatePieButtonForPage:self.bookView.pageNumber animated:animated];
}

-(void)updateBookmarkButton {
	NSLog(@"%@", NSStringFromSelector(_cmd));
//	BlioBookmarkPoint *currentBookmarkPoint = self.bookView.currentBookmarkPoint;
//	BlioBookmarkRange *currentBookmarkRange = [BlioBookmarkRange bookmarkRangeWithBookmarkPoint:currentBookmarkPoint];
	
	NSMutableSet *bookmarks = [self.book mutableSetValueForKey:@"bookmarks"];
	NSManagedObject *existingBookmark = nil;
	
	for (NSManagedObject *bookmark in bookmarks) {
		BlioBookmarkRange *aBookmarkRange = [BlioBookmarkRange bookmarkRangeWithPersistentBookmarkRange:[bookmark valueForKey:@"range"]];    
		
		NSInteger pageNum;
		if ([self.bookView respondsToSelector:@selector(pageNumberForBookmarkRange:)]) {
			pageNum = [self.bookView pageNumberForBookmarkRange:aBookmarkRange];
		} else {
			BlioBookmarkPoint *aBookMarkPoint = aBookmarkRange.startPoint;
			pageNum = [self.bookView pageNumberForBookmarkPoint:aBookMarkPoint];
		}
		
		NSLog(@"bookmarkPageNum: %i and currentPageNum: %i",pageNum,self.bookView.pageNumber);
		if (pageNum == self.bookView.pageNumber) {
			existingBookmark = bookmark;
			break;
		}
	}
//	NSLog(@"existingBookmark: %@",existingBookmark);
	if (nil != existingBookmark) {
		self.addButton.image = [UIImage imageNamed:@"icon-bookmarked.png"];
	}
	else {
		self.addButton.image = [UIImage imageNamed:@"icon-add.png"];
	}
}

- (void)updatePageJumpPanelForPage:(NSInteger)pageNumber animated:(BOOL)animated
{
    if (_pageJumpSlider) {
        _pageJumpSlider.maximumValue = self.bookView.pageCount;
        _pageJumpSlider.minimumValue = 1;
        [_pageJumpSlider setValue:pageNumber animated:animated];
        [self _updatePageJumpLabelForPage:pageNumber];
    }    
}

- (void)updatePageJumpPanelAnimated:(BOOL)animated
{
    [self updatePageJumpPanelForPage:self.bookView.pageNumber animated:YES];
}

//- (void)bookContentsTableViewController:(EucBookContentsTableViewController *)controller didSelectSectionWithUuid:(NSString *)uuid {
//    [self performSelector:@selector(dismissContentsTabView:)];
//}


- (void)loadView 
{
    UIView *root = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    // Changed to grey background to match Layout View surround color when rotating
    root.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
    root.opaque = YES;
    if(_bookView) {
        [root addSubview:_bookView];
        [root sendSubviewToBack:_bookView];
    }
    self.view = root;
    [root release];
    
    UIButton *aPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *pauseImage = [UIImage imageNamed:@"button-tts-pause.png"];
    [aPauseButton setBackgroundImage:pauseImage forState:UIControlStateNormal];
    [aPauseButton addTarget:self action:@selector(toggleAudio:) forControlEvents:UIControlEventTouchUpInside];
    [aPauseButton setFrame:CGRectMake(0, 0, pauseImage.size.width, pauseImage.size.height)];
    [aPauseButton setShowsTouchWhenHighlighted:YES];
    [aPauseButton setAccessibilityLabel:NSLocalizedString(@"Pause", @"Accessibility label for Book View Controller Pause button")];
    [aPauseButton setAccessibilityHint:NSLocalizedString(@"Pauses audio playback.", @"Accessibility label for Book View Controller Pause hint")];
    [aPauseButton setAlpha:0];
    [self.view addSubview:aPauseButton];
    self.pauseButton = aPauseButton;
}

- (void)layoutNavigationToolbar {
    CGRect navFrame = self.navigationController.navigationBar.frame;
    navFrame.origin.y = 20;
    [self.navigationController.navigationBar setFrame:navFrame];
}

- (void)layoutPauseButton {
    CGRect buttonFrame = self.pauseButton.frame;
    buttonFrame.origin.y = CGRectGetHeight(self.bookView.frame) - CGRectGetHeight(buttonFrame) - 3;
    buttonFrame.origin.x = 3;
    [self.pauseButton setFrame:buttonFrame];
}

- (void)setNavigationBarButtons {
    
    CGFloat buttonHeight = 30;

    // Toolbar buttons are 30 pixels high in portrait and 24 pixels high landscape
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        buttonHeight = 24;
    }
    
    CGRect buttonFrame = CGRectMake(0,0, 41, buttonHeight);
    
    UIButton *backArrow = [THNavigationButton leftNavigationButtonWithArrowInBarStyle:UIBarStyleBlackTranslucent frame:buttonFrame];
    //UIButton *backArrow = [THNavigationButton leftNavigationButtonWithArrowInBarStyle:UIBarStyleBlackTranslucent];

    [backArrow addTarget:self action:@selector(_backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [backArrow setAccessibilityLabel:NSLocalizedString(@"Library Back", @"Accessibility label for Book View Controller Library Back button")];

    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backArrow];
    self.navigationItem.leftBarButtonItem = backItem;
    [backItem release];
    
    BlioBookViewControllerProgressPieButton *aPieButton = [[BlioBookViewControllerProgressPieButton alloc] initWithFrame:buttonFrame];
    [aPieButton addTarget:self action:@selector(togglePageJumpPanel) forControlEvents:UIControlEventTouchUpInside];
    
    if (_pageJumpButton) [_pageJumpButton release];
    _pageJumpButton = [[UIBarButtonItem alloc] initWithCustomView:aPieButton];
    
    self.pieButton = aPieButton;
    [aPieButton release];
    
    [self.navigationItem setRightBarButtonItem:_pageJumpButton];
    [self updatePieButtonAnimated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
	if ([[UIApplication sharedApplication] respondsToSelector:@selector(beginReceivingRemoteControlEvents)]) {
//		NSLog(@"start receiving remote control events");
		[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
		[self becomeFirstResponder];
	}
    if(!self.modalViewController) {        
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
            [application setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
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
        
        EucBookTitleView *titleView = (EucBookTitleView *)self.navigationItem.titleView;
        [titleView setTitle:[self.book title]];
        [titleView setAuthor:[self.book authorsWithStandardFormat]];
        
        [self setNavigationBarButtons];
        [self layoutPauseButton];     
        
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
}

- (void)viewDidAppear:(BOOL)animated
{
    if(_firstAppearance) {
        UIApplication *application = [UIApplication sharedApplication];
        //if(self.toolbarsVisibleAfterAppearance) {
            if([application isStatusBarHidden]) {
				if ([application respondsToSelector:@selector(setStatusBarHidden:withAnimation:)]) 
                    [application setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
				else
                    [(id)application setStatusBarHidden:NO animated:YES]; // typecast as id to mask deprecation warnings.
                
            }
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [self.navigationController setNavigationBarHidden:NO animated:NO];
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
    if(_viewIsDisappearing) {
        //        if(_contentsSheet) {
        //            [self performSelector:@selector(dismissContents)];
        //        }
        [self.book reportReadingIfRequired];
        
        if(_bookView) {
            // Need to do this now before the view is removed and doesn't have a window.
            if ([_bookView wantsTouchesSniffed]) {
                [(THEventCapturingWindow *)_bookView.window removeTouchObserver:self forView:_bookView];
            }
            
            if([_bookView respondsToSelector:@selector(stopAnimation)]) {
                [_bookView performSelector:@selector(stopAnimation)];
            }
            
            //[self removeObserver:_bookView forKeyPath:@"audioPlaying"];
            
            if([_bookView isKindOfClass:[BlioSpeedReadView class]]) {
                // We do this because the current point is usually only saved on a 
                // page switch, so we want to make sure the current point that the 
                // user has reached in SpeedRead view is saved..
                // Usually, the SpeedRead "Page" tracks the layout page that the 
                // current SpeedRead paragraph starts on.
                self.book.implicitBookmarkPoint = self.bookView.currentBookmarkPoint;
            } 
            
            // Save the current progress, for UI display purposes.
            // Subtract 1 from pageNumber and count so that when we are on page 0 we actually get progress of 0
            float bookProgress = (float)(_bookView.pageNumber - 1) / (float)(_bookView.pageCount - 1);
            self.book.progress = [NSNumber numberWithFloat:bookProgress];
            
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
				if ([application respondsToSelector:@selector(setStatusBarHidden:withAnimation:)]) 
                    [application setStatusBarHidden:_returnToStatusBarHidden withAnimation:UIStatusBarAnimationFade];
				else 
                    [(id)application setStatusBarHidden:_returnToStatusBarHidden animated:YES]; // typecast as id to mask deprecation warnings.							
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
            
            NSError *error;
            if (![[self.book managedObjectContext] save:&error])
                NSLog(@"[BlioBookViewController viewWillDisappear] Save failed with error: %@, %@", error, [error userInfo]);            
        }
    }
}


- (void)viewDidDisappear:(BOOL)animated
{    
    _viewIsDisappearing = NO;
}


- (void)viewDidUnload
{
    self.bookView = nil;
}

- (void)didReceiveMemoryWarning 
{
    [self.book reportReadingIfRequired];
    [self.book flushCaches];
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    [self.book reportReadingIfRequired];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [self.book reportReadingIfRequired];
}

- (void)dealloc 
{
    //NSLog(@"BookViewController dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIAccelerometer sharedAccelerometer] setUpdateInterval:0];
    [[UIAccelerometer sharedAccelerometer] setDelegate:nil];
	[[AVAudioSession sharedInstance] setDelegate:nil];
	if (_pageJumpButton) [_pageJumpButton release];
    
    self.searchViewController = nil;
    
    self.bookView = nil;
    
    [self.book flushCaches];
    self.book = nil;    
    
    self.pageJumpView = nil;
    self.pieButton = nil;
    self.pauseButton = nil;
    self.managedObjectContext = nil;
    self.delegate = nil;
    self.coverView = nil;
    self.viewSettingsSheet = nil;
    self.viewSettingsPopover = nil;
    self.contentsPopover = nil;
    self.searchPopover = nil;
    self.contentsButton = nil;
    self.addButton = nil;
    self.viewSettingsButton = nil;
    self.searchButton = nil;
	self.backButton = nil;
    self.historyStack = nil;
	[super dealloc];
}


- (void)_fadeDidEnd
{
    if(_fadeState == BookViewControlleUIFadeStateFadingOut) {
        self.navigationController.toolbarHidden = YES;
        if ([self.searchViewController isSearchActive] == YES) {
            self.searchViewController.toolbarHidden = YES;
        }
        self.navigationController.navigationBar.hidden = YES;
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    } else {
        if (![self audioPlaying])
            [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
    _fadeState = BookViewControlleUIFadeStateNone;
}


- (void)_fadeWillStart
{
    if(_fadeState == BookViewControlleUIFadeStateFadingOut) {
		if ([[UIApplication sharedApplication] respondsToSelector:@selector(setStatusBarHidden:withAnimation:)]) 
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
		else
            [(id)[UIApplication sharedApplication] setStatusBarHidden:YES animated:YES]; // typecast as id to mask deprecation warnings.							
    } 
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
    
    if(_fadeState != BookViewControlleUIFadeStateNone) return;
    
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
			if ([[UIApplication sharedApplication] respondsToSelector:@selector(setStatusBarHidden:withAnimation:)]) 
                [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
			else 
                [(id)[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO]; // typecast as id to mask deprecation warnings.							
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:NO];
            break;
        default:
            break;
    }
    
    // Set the toolbar settings we don't want to animate 
    switch (toolbarState) {
        case kBlioLibraryToolbarsStateToolbarsVisible:
        case kBlioLibraryToolbarsStateStatusBarAndToolbarsVisible:
            if ([self.searchViewController isSearchActive] == NO) {
                self.navigationController.toolbarHidden = NO;
            } else {
                self.navigationController.toolbarHidden = YES;
                self.searchViewController.toolbarHidden = NO;
            }
            self.navigationController.navigationBarHidden = NO;
            self.navigationController.navigationBar.hidden = NO;
            
            break;
        default:
            break;
    }
    
    // Durations below taken from trial-and-error comparison with the 
    // Photos application.
    [UIView beginAnimations:@"ToolbarsFade" context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(_fadeDidEnd)];
    
    // Set the status bar settings we do want to animate
    switch (toolbarState) {
        case kBlioLibraryToolbarsStateStatusBarVisible:
        case kBlioLibraryToolbarsStateStatusBarAndToolbarsVisible:
            break;
        default:
            [UIView setAnimationWillStartSelector:@selector(_fadeWillStart)];
            break;
    }
    
    // Set the toolbars settings we do want to animate
    switch (toolbarState) {
        case kBlioLibraryToolbarsStateToolbarsVisible:
        case kBlioLibraryToolbarsStateStatusBarAndToolbarsVisible:
            [UIView setAnimationDuration:0];
            if ([self.searchViewController isSearchActive] == NO) {
                self.navigationController.toolbar.alpha = 1;
            } else {
                self.navigationController.toolbar.alpha = 0;
                self.searchViewController.toolbar.alpha = 1;
            }
            
            self.pageJumpView.alpha = 1;
            self.navigationController.navigationBar.alpha = 1;
            break;
        default:
            [UIView setAnimationDuration:1.0/3.0];
            self.navigationController.toolbar.alpha = 0;
            if ([self.searchViewController isSearchActive] == YES) {
                self.searchViewController.toolbar.alpha = 0;
            }
            
            self.pageJumpView.alpha = 0;
            self.navigationController.navigationBar.alpha = 0;
            break;
    }
    
    // Set the pause button settings we do want to animate
    switch (toolbarState) {
        case kBlioLibraryToolbarsStatePauseButtonVisible:
            self.pauseButton.alpha = 1;
            break;
        default:
            self.pauseButton.alpha = 0;
            break;
    }
    
    [UIView commitAnimations];   
        
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)toggleToolbars:(BlioLibraryToolbarsState)toolbarState
{
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
    UIView *bookView = self.bookView;
    CGRect rect = [bookView convertRect:self.bookView.bounds toView:nil];
    
    if([self toolbarsVisible]) {
        CGRect navRect;
        if(_pageJumpView) {
            navRect = [_pageJumpView convertRect:_pageJumpView.bounds toView:nil];
        } else {
            UINavigationBar *navBar = self.navigationController.navigationBar;
            navRect = [navBar convertRect:navBar.bounds toView:nil];
        }
        
        CGFloat navRectBottom = CGRectGetMaxY(navRect);
        rect.size.height -= navRectBottom - rect.origin.y;
        rect.origin.y = navRectBottom;

        UIToolbar *toolbar = self.navigationController.toolbar;
        CGRect toolbarRect = [toolbar convertRect:toolbar.bounds toView:nil];
        rect.size.height = toolbarRect.origin.y - rect.origin.y;
    }
    
    return [bookView convertRect:rect fromView:nil];
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
                if([self toolbarsVisible] &&
                   (![self.bookView respondsToSelector:@selector(toolbarShowShouldBeSuppressed)] ||
					![self.bookView toolbarShowShouldBeSuppressed])) {
					   [self toggleToolbars];
				   } else if (![self toolbarsVisible] &&
							  (![self.bookView respondsToSelector:@selector(toolbarHideShouldBeSuppressed)] ||
							   ![self.bookView toolbarHideShouldBeSuppressed])) {
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
    
    ///CGSize viewBounds = [self.bookView bounds].size;
    UINavigationBar *currentNavBar = self.navigationController.visibleViewController.navigationController.navigationBar;
    CGPoint navBarBottomLeft = CGPointMake(0.0, 20 + currentNavBar.frame.size.height);
    //CGPoint xt = [self.view convertPoint:navBarBottomLeft fromView:currentNavBar];

    [_pageJumpView setFrame:CGRectMake(navBarBottomLeft.x, navBarBottomLeft.y, currentNavBar.frame.size.width, currentNavBar.frame.size.height)];
    if (![_pageJumpView isHidden]) {
        [_pageJumpView setTransform:CGAffineTransformIdentity];
    } else {
        [_pageJumpView setTransform:CGAffineTransformMakeTranslation(0, -_pageJumpView.bounds.size.height)];
    }
}

- (void)layoutPageJumpSlider {
    _pageJumpSlider.transform = CGAffineTransformIdentity;    
    [_pageJumpSlider sizeToFit];
    
    CGRect sliderBounds = [_pageJumpSlider bounds];
    sliderBounds.size.width = CGRectGetWidth(_pageJumpView.bounds) - 10;
    [_pageJumpSlider setBounds:sliderBounds];
    
    CGFloat scale = 1;
    
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
        scale = 0.75f;
    
    CGRect _pageJumpViewBounds = _pageJumpView.bounds;
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

- (void) togglePageJumpPanel { 
    
    if(!_pageJumpView) {
        self.pageJumpView = [[BlioBeveledView alloc] init];
        [self.pageJumpView release];
        
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
        slider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [slider setAccessibilityLabel:NSLocalizedString(@"Page Chooser", @"Accessibility label for Book View Controller Progress slider")];
        if([[UIDevice currentDevice] compareSystemVersion:@"4.0"] >= NSOrderedSame) {
            [slider setAccessibilityTraits:UIAccessibilityTraitAdjustable];
            [slider setAccessibilityHint:NSLocalizedString(@"Double-tap and hold, then drag left or right to change the page", @"Accessibility hint for Book View Controller Progress slider")];
        }
        //[
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
        
        slider.maximumValue = self.bookView.pageCount;
        slider.minimumValue = 1;
        [slider setValue:self.bookView.pageNumber];
        
        [self layoutPageJumpSlider];
        [_pageJumpView addSubview:slider];
        
        [self.view addSubview:_pageJumpView];
	
    }
    
    CGSize sz = _pageJumpView.bounds.size;
    BOOL hiding = ![_pageJumpView isHidden];
    [self.pieButton setToggled:!hiding];
    
    if (!hiding) {
        _pageJumpView.alpha = 0.0;
        _pageJumpView.hidden = NO;
        [self _updatePageJumpLabelForPage:self.bookView.pageNumber];
    }
    
    [UIView beginAnimations:@"pageJumpViewToggle" context:NULL];
    [UIView setAnimationDidStopSelector:@selector(_pageJumpPanelDidAnimate)];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.3f];
    
    if (hiding) {
        _pageJumpView.alpha = 0.0;
        [_pageJumpView setTransform:CGAffineTransformMakeTranslation(0, -sz.height)];
    } else {
        [self _updatePageJumpLabelForPage:self.bookView.pageNumber];
        _pageJumpView.alpha = 1.0;
        [_pageJumpView setTransform:CGAffineTransformIdentity];
    }
    
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
    NSInteger page = (NSInteger) slider.value;
    [self _updatePageJumpLabelForPage:page];

    if (!slider.touchInProgress) {
        if (page != [self.bookView pageNumber]) {
            [self.bookView goToPageNumber:page animated:YES];
        }
    }
    
    [self.pieButton setProgress:_pageJumpSlider.value/_pageJumpSlider.maximumValue];
    
    // When we come to set this later, after the page turn,
    // it's often a pixel out (due to rounding?), so set it here.
    [_pageJumpSlider setValue:page animated:NO];
}

- (void)goToPageNumberAnimated:(NSNumber *)pageNumber {
	//NSLog(@"BlioBookViewController goToPageNumber: %i",pageNumber);
    [self.bookView goToPageNumber:[pageNumber integerValue] animated:YES];
}

- (void)incrementPage {
    NSInteger currentPage = self.bookView.pageNumber;
    [self.bookView goToPageNumber:++currentPage animated:NO];
}

- (void)decrementPage {
    NSInteger currentPage = self.bookView.pageNumber;
    [self.bookView goToPageNumber:--currentPage animated:NO];
}

- (void) _updatePageJumpLabelForPage:(NSInteger)page
{
    _pageJumpLabel.text = [self.bookView pageLabelForPageNumber:page];
    NSString *pageNumber = [[self.bookView contentsDataSource] displayPageNumberForPageNumber:page];
    NSString *currentValue = [_pageJumpSlider accessibilityValue];
    NSString *newValue;
                              
    if (pageNumber) {
        newValue = [NSString stringWithFormat:NSLocalizedString(@"Page %@", @"Accessibility label for Page Jump Slider value format"), pageNumber];
    } else {
        newValue = _pageJumpLabel.text;
    }
    
    if(![currentValue isEqualToString:newValue]) {
        [_pageJumpSlider setAccessibilityValue:newValue];
        if(self.toolbarsVisible && !_pageJumpView.isHidden) {
            if([[UIDevice currentDevice] compareSystemVersion:@"4.0"] >= NSOrderedSame) {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, newValue);
            }
        }
    }
}

#pragma mark -
#pragma mark BookController State Methods

- (NSString *)currentPageNumber {
    UIView<BlioBookView> *bookView = [(BlioBookViewController *)self.navigationController.topViewController bookView];
    if ([bookView respondsToSelector:@selector(pageNumber)]) {
        NSInteger currentPage = (NSInteger)[bookView performSelector:@selector(pageNumber)];
        if ([[bookView contentsDataSource] respondsToSelector:@selector(displayPageNumberForPageNumber:)])
            return [[bookView contentsDataSource] displayPageNumberForPageNumber:currentPage];
    }
    return nil;
}

- (BlioPageLayout)currentPageLayout {
    BlioBookViewController *bookViewController = (BlioBookViewController *)self.navigationController.topViewController;
    if([bookViewController.bookView isKindOfClass:[BlioLayoutView class]])
        return kBlioPageLayoutPageLayout;
    else if([bookViewController.bookView isKindOfClass:[BlioSpeedReadView class]])
        return kBlioPageLayoutSpeedRead;
    else
        return kBlioPageLayoutPlainText;
}

- (void)changePageLayout:(id)sender {
    
    BlioPageLayout newLayout = (BlioPageLayout)[sender selectedSegmentIndex];
    
    BlioPageLayout currentLayout = self.currentPageLayout;
    if(currentLayout != newLayout) { 
        if([self.bookView isKindOfClass:[BlioSpeedReadView class]]) {
            // We do this because the current point is usually only saved on a 
            // page switch, so we want to make sure the current point that the 
            // user has reached in SpeedRead view is up to date.
            // Usually, the SpeedRead "Page" tracks the layout page that the 
            // current SpeedRead paragraph starts on.
            self.book.implicitBookmarkPoint = self.bookView.currentBookmarkPoint;
        }
        if (newLayout == kBlioPageLayoutPlainText && [self reflowEnabled]) {
            BlioFlowView *ePubView = [[BlioFlowView alloc] initWithFrame:self.view.bounds bookID:self.book.objectID animated:NO];
            ePubView.delegate = self;
            self.bookView = ePubView;
            [ePubView release];
            [[NSUserDefaults standardUserDefaults] setInteger:kBlioPageLayoutPlainText forKey:kBlioLastLayoutDefaultsKey];  
			if ( [self.book hasAudiobook] ) {
				for (UIBarButtonItem * item in self.toolbarItems)
					if ( item.action == @selector(toggleAudio:) )
						 [item setEnabled:NO];
			}
        } else if (newLayout == kBlioPageLayoutPageLayout && [self fixedViewEnabled]) {
            BlioLayoutView *layoutView = [[BlioLayoutView alloc] initWithFrame:self.view.bounds bookID:self.book.objectID animated:NO];
            layoutView.delegate = self;
            self.bookView = layoutView;            
            [layoutView release];
            [[NSUserDefaults standardUserDefaults] setInteger:kBlioPageLayoutPageLayout forKey:kBlioLastLayoutDefaultsKey]; 
			if ( [self.book hasAudiobook] ) {
				for (UIBarButtonItem * item in self.toolbarItems)
					if ( item.action == @selector(toggleAudio:) )
						[item setEnabled:YES];
			}   
        } else if (newLayout == kBlioPageLayoutSpeedRead && [self reflowEnabled]) {
            BlioSpeedReadView *speedReadView = [[BlioSpeedReadView alloc] initWithFrame:self.view.bounds bookID:self.book.objectID animated:NO];
            speedReadView.delegate = self;
            self.bookView = speedReadView;     
            [speedReadView release];
            [[NSUserDefaults standardUserDefaults] setInteger:kBlioPageLayoutSpeedRead forKey:kBlioLastLayoutDefaultsKey];
        }
        
        self.currentPageColor = [[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastPageColorDefaultsKey];
        
        // Reset the search resultsi
        self.searchViewController = nil;
        self.searchPopover = nil;
    }
}

- (BOOL)shouldShowFontSizeSettings {
    if ([self currentPageLayout] == kBlioPageLayoutPageLayout) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)shouldShowPageColorSettings {        
    return YES;
}

- (BlioFontSize)currentFontSize {
    BlioFontSize fontSize = kBlioFontSizeMedium;
    BlioBookViewController *bookViewController = (BlioBookViewController *)self.navigationController.topViewController;
    id<BlioBookView> bookView = bookViewController.bookView;
    
    if([bookView respondsToSelector:(@selector(fontPointSize))]) {
        CGFloat actualFontSize = bookView.fontPointSize;
        CGFloat bestDifference = CGFLOAT_MAX;
        BlioFontSize bestFontSize = kBlioFontSizeMedium;
        for(BlioFontSize i = kBlioFontSizeVerySmall; i <= kBlioFontSizeVeryLarge; ++i) {
            CGFloat thisDifference = fabsf(kBlioFontPointSizeArray[i] - actualFontSize);
            if(thisDifference < bestDifference) {
                bestDifference = thisDifference;
                bestFontSize = i;
            }
        }
        fontSize = bestFontSize;
    } 
    return fontSize;
}

- (BOOL)reflowEnabled {
	return [self.book reflowEnabled];
}
-(BOOL)fixedViewEnabled {
	return [self.book fixedViewEnabled];
}
- (void)changeFontSize:(id)sender {
    BlioFontSize newSize = (BlioFontSize)[sender selectedSegmentIndex];
    BlioBookViewController *bookViewController = (BlioBookViewController *)self.navigationController.topViewController;
    id<BlioBookView> bookView = bookViewController.bookView;
    if([bookView respondsToSelector:(@selector(setFontPointSize:))]) {        
        if([self currentFontSize] != newSize) {
            bookView.fontPointSize = kBlioFontPointSizeArray[newSize];
            [[NSUserDefaults standardUserDefaults] setInteger:newSize forKey:kBlioLastFontSizeDefaultsKey];
        }
    }
}

- (void)setCurrentPageColor:(BlioPageColor)newColor
{
    UIView<BlioBookView> *bookView = self.bookView;
    if([bookView isKindOfClass:[BlioSpeedReadView class]]) {
        [(BlioSpeedReadView*)bookView setColor:newColor];
    } else {
        if([bookView respondsToSelector:(@selector(setPageTexture:isDark:))]) {
            UIImage *pageTexture = nil;
            if ((newColor == kBlioPageColorWhite) && (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {
                pageTexture = [UIImage imageWithData:[NSData dataWithContentsOfMappedFile:[[NSBundle mainBundle] pathForResource:@"paper-white-ipad" ofType:@"png"]]];
            } else {
                NSString *imagePath = [[NSBundle mainBundle] pathForResource:kBlioFontPageTextureNamesArray[newColor]
                                                                  ofType:@""];
                pageTexture = [UIImage imageWithData:[NSData dataWithContentsOfMappedFile:imagePath]];
            }
            [bookView setPageTexture:pageTexture isDark:kBlioFontPageTexturesAreDarkArray[newColor]];
        }
    }
    _currentPageColor = newColor;
}

- (void)changePageColor:(id)sender {
    self.currentPageColor = (BlioPageColor)[sender selectedSegmentIndex];
    [[NSUserDefaults standardUserDefaults] setInteger:self.currentPageColor forKey:kBlioLastPageColorDefaultsKey];
}

- (void)changeLockRotation {
    [self setRotationLocked:![self isRotationLocked]];
    [[NSUserDefaults standardUserDefaults] setInteger:[self isRotationLocked] forKey:kBlioLastLockRotationDefaultsKey];
}


#pragma mark -
#pragma mark KVO Callback

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSParameterAssert([NSThread isMainThread]);
    
    if ([keyPath isEqual:@"pageNumber"] && coverOpened) {
		NSLog(@"self.bookView.pageNumber: %i",self.bookView.pageNumber);
        [self updatePageJumpPanelAnimated:YES];
        [self updatePieButtonAnimated:YES];
        [self updateBookmarkButton];
        		
		if ( _acapelaAudioManager != nil )
			[_acapelaAudioManager setPageChanged:YES];  
		if ( _audioBookManager != nil )
			[_audioBookManager setPageChanged:YES];
		
        if(_lastSavedPageNumber != self.bookView.pageNumber) {
            self.book.implicitBookmarkPoint = self.bookView.currentBookmarkPoint;
            
            NSError *error;
            if (![[self.book managedObjectContext] save:&error])
                NSLog(@"[BlioBookViewController observeValueForKeyPath] Save failed with error: %@, %@", error, [error userInfo]);            
        }
    }
    
    if ([keyPath isEqual:@"pageCount"] && coverOpened) {
        [self updatePageJumpPanelAnimated:YES];
        [self updatePieButtonAnimated:YES];
    }
}

#pragma mark -
#pragma mark Action Callback Methods

- (void)setToolbarsForModalOverlayActive:(BOOL)active {
    if (active) {
        [self hideToolbarsAndStatusBar:NO];
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    } else {
        [self showToolbars];
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

- (void)showAddMenu:(id)sender {
    [self setToolbarsForModalOverlayActive:YES];
    
    UIActionSheet *aActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Add Bookmark", @"Add Notes", nil];
    aActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    aActionSheet.delegate = self;
    UIToolbar *toolbar = self.navigationController.toolbar;
    [aActionSheet showFromToolbar:toolbar];
    [aActionSheet release];
}

- (void)showViewSettings:(id)sender {    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (![self.viewSettingsPopover isPopoverVisible]) {
            BlioViewSettingsPopover *aSettingsPopover = [[BlioViewSettingsPopover alloc] initWithDelegate:self];
            [aSettingsPopover presentPopoverFromBarButtonItem:(UIBarButtonItem *)sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            self.viewSettingsPopover = aSettingsPopover;
            [aSettingsPopover release];
        }
    } else {
        if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
            // Hide toolbars so the view settings don't overlap them
            [self setToolbarsForModalOverlayActive:YES];
        }
        BlioViewSettingsSheet *aSettingsSheet = [[BlioViewSettingsSheet alloc] initWithDelegate:self];
        [aSettingsSheet showFromToolbar:self.navigationController.toolbar];
        self.viewSettingsSheet = aSettingsSheet;
        [aSettingsSheet release];
    }
    
}

- (void)dismissViewSettings:(id)sender {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.viewSettingsPopover = nil;
    } else {
        [self.viewSettingsSheet dismissWithClickedButtonIndex:0 animated:YES];
        self.viewSettingsSheet = nil;
    }
    [self setToolbarsForModalOverlayActive:NO];
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
    id<BlioParagraphSource> paragraphSource = self.book.paragraphSource;
    
    id newBlock  = [paragraphSource nextParagraphIdForParagraphWithID:audioMgr.currentBlock];
    if(newBlock) {
        audioMgr.currentBlock = newBlock;
        audioMgr.currentWordOffset = 0;
        audioMgr.blockWords = [paragraphSource wordsForParagraphWithID:audioMgr.currentBlock];
    } else {        
        // end of the book

        audioMgr.currentBlock = nil;
        audioMgr.currentWordOffset = 0;
        audioMgr.blockWords = nil;
        
        [self stopAudio];
        self.audioPlaying = NO;
        [self updatePauseButton];
    }
}

- (void) prepareTextToSpeakWithAudioManager:(BlioAudioManager*)audioMgr continuingSpeech:(BOOL)continuingSpeech {
	if ( continuingSpeech ) {
		// Continuing to speak, we just need more text.
		[self getNextBlockForAudioManager:audioMgr];
	}
	else {
		// Play button has just been pushed.
        id<BlioParagraphSource> paragraphSource = self.book.paragraphSource;
        id blockId = nil;
        uint32_t wordOffset = 0;
		[paragraphSource bookmarkPoint:self.bookView.currentBookmarkPoint toParagraphID:&blockId wordOffset:&wordOffset]; 
        if ( blockId ) {
            if ( audioMgr.pageChanged ) {  
                // Page has changed since the stop button was last pushed (and pageChanged is initialized to true).
                // So we're starting speech for the first time, or for the first time since changing the 
                // page or book after stopping speech the last time (whew).
                [audioMgr setCurrentBlock:blockId];
                [audioMgr setCurrentWordOffset:wordOffset];
                [audioMgr setBlockWords:[paragraphSource wordsForParagraphWithID:blockId]];
                [audioMgr setPageChanged:NO];
            }
            else {
                // use the current word and block, which is where we last stopped.
                if ( audioMgr.currentWordOffset + 1 < [audioMgr.blockWords count] ) {
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
    }
}

- (BOOL)loadAudioFiles:(NSInteger)layoutPage segmentIndex:(NSInteger)segmentIx {
	NSMutableArray* segmentInfo;
	// Subtract 1 for now from page to match Blio layout page. Can't we have them match?
	if ( !(segmentInfo = [(NSMutableArray*)[_audioBookManager.pagesDict objectForKey:[NSString stringWithFormat:@"%d",layoutPage-1]] objectAtIndex:segmentIx]) )
		return NO;
//	NSString* audiobooksPath = [self.book.bookCacheDirectory stringByAppendingPathComponent:@"Audiobook"];
	// For testing
	//NSString* audiobooksPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/AudioBooks/Graveyard Book/"];
//	NSString* timingPath = [audiobooksPath stringByAppendingPathComponent:[_audioBookManager.timeFiles objectAtIndex:[[segmentInfo objectAtIndex:kAudioRefIndex] intValue]]];
	if ( ![_audioBookManager loadWordTimesWithIndex:[[segmentInfo objectAtIndex:kAudioRefIndex] intValue]] )  {
		NSLog(@"Timing file could not be initialized.");
		return NO;
	}
//	NSString* audioPath = [audiobooksPath stringByAppendingPathComponent:[_audioBookManager.audioFiles objectAtIndex:[[segmentInfo objectAtIndex:kAudioRefIndex] intValue]]];
	if ( ![_audioBookManager initAudioWithIndex:[[segmentInfo objectAtIndex:kAudioRefIndex] intValue]] ) {
		NSLog(@"Audio player could not be initialized.");
		return NO;
	}
	_audioBookManager.avPlayer.delegate = self;
	// Cue up the audio player to where it starts for this page.
	// In future, could get this from TimeIndex.
	NSTimeInterval timeOffset = [[segmentInfo objectAtIndex:kTimeOffset] intValue]/1000.0;
	[_audioBookManager.avPlayer setCurrentTime:timeOffset];
	// Set the timing file index for this page.
	_audioBookManager.timeIx = [[segmentInfo objectAtIndex:kTimeIndex] intValue]; // need to subtract one...
	return YES;
}

#pragma mark -
#pragma mark Acapela Delegate Methods 

- (void)speechSynthesizer:(AcapelaSpeech*)synth didFinishSpeaking:(BOOL)finishedSpeaking
{
	if (finishedSpeaking) {
		// Reached end of block.  Start on the next.
		[self prepareTextToSpeakWithAudioManager:_acapelaAudioManager continuingSpeech:YES]; 
	}
	//else stop button pushed before end of block.
}

- (void)speechSynthesizer:(AcapelaSpeech*)sender willSpeakWord:(NSRange)characterRange 
				 ofString:(NSString*)string 
{
    if(characterRange.location + characterRange.length <= string.length) {
        NSUInteger wordOffset = [_acapelaAudioManager wordOffsetForCharacterRange:characterRange];
        
        id<BlioBookView> bookView = self.bookView;
        if([bookView respondsToSelector:@selector(highlightWordAtBookmarkPoint:)]) {
            BlioBookmarkPoint *point = [self.book.paragraphSource bookmarkPointFromParagraphID:_acapelaAudioManager.currentBlock
                                                                                   wordOffset:wordOffset];
            [bookView highlightWordAtBookmarkPoint:point];
        }
        [_acapelaAudioManager setCurrentWordOffset:wordOffset];
    }
}

#pragma mark -
#pragma mark AVAudioSession Delegate Methods 
- (void)beginInterruption {

}
- (void)endInterruptionWithFlags:(NSUInteger)flags {

}


#pragma mark -
#pragma mark AVAudioPlayer Delegate Methods 

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag { 
	if (!flag) {
		self.audioPlaying = NO;
        [self updatePauseButton];
		NSLog(@"Audio player terminated because of error.");
		return;
	}
	[_audioBookManager.speakingTimer invalidate];
	NSInteger layoutPage = [self.bookView.currentBookmarkPoint layoutPage];
	// Subtract 1 to match Blio layout page number.  
	NSMutableArray* pageSegments = (NSMutableArray*)[_audioBookManager.pagesDict objectForKey:[NSString stringWithFormat:@"%d",layoutPage-1]];
	if ([pageSegments count] == 1 ) {
		// Stopped at the exact end of the page.
		BOOL loadedFilesAhead = NO;
		for ( int i=layoutPage+1;i<=[self.bookView pageCount];++i ) {  
			if ( [self loadAudioFiles:i segmentIndex:0] ) {
				loadedFilesAhead = YES;
				BOOL animatedPageChange = YES;
				if ([[UIApplication sharedApplication] respondsToSelector:@selector(applicationState)]) {
					if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) animatedPageChange = NO;
				}
				[self.bookView goToPageNumber:i animated:animatedPageChange];
				break;
			}
		}
		if ( !loadedFilesAhead ) {
			// End of book.
			self.audioPlaying = NO;
            [self updatePauseButton];
		}
		else {
			[self prepareTextToSpeakWithAudioManager:_audioBookManager continuingSpeech:YES];
			[_audioBookManager setSpeakingTimer:[NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(checkHighlightTime:) userInfo:nil repeats:YES]];
			[_audioBookManager playAudio];
		}
	}
	else {
		// Stopped in the middle of the page.
		// Kluge: assume there won't be more than two segments on a page.
		if ( [self loadAudioFiles:layoutPage segmentIndex:1] ) {
			[self prepareTextToSpeakWithAudioManager:_audioBookManager continuingSpeech:YES];
			[_audioBookManager setSpeakingTimer:[NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(checkHighlightTime:) userInfo:nil repeats:YES]];
			[_audioBookManager playAudio];
		}
	}
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer*)player error:(NSError*)error { 
	NSLog(@"Audio player error.");
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer*) player { 
	[_audioBookManager playAudio];
}

#pragma mark -
#pragma mark UIResponder Event Handling

- (BOOL)canBecomeFirstResponder {
	return YES;
}

-(void)remoteControlReceivedWithEvent:(UIEvent*)theEvent {
	//NSLog(@"remoteControlReceivedWithEvent");
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
	//int timeElapsed = (int) (([_audioBookManager.avPlayer currentTime] - _audioBookManager.timeStarted) * 1000.0);
	//int timeElapsed = [_audioBookManager.avPlayer currentTime] * 1000;
	//NSLog(@"Elapsed time %d",timeElapsed);
	if ( ([_audioBookManager.avPlayer currentTime] * 1000 ) >= ([[_audioBookManager.wordTimes objectAtIndex:_audioBookManager.timeIx] intValue]) ) {
		//NSLog(@"Passed time %d",[[_audioBookManager.wordTimes objectAtIndex:_audioBookManager.timeIx] intValue]);

        id<BlioBookView> bookView = self.bookView;
        if([bookView respondsToSelector:@selector(highlightWordAtBookmarkPoint:)]) {
            BlioBookmarkPoint *point = [self.book.paragraphSource bookmarkPointFromParagraphID:_audioBookManager.currentBlock
                                                                                    wordOffset:_audioBookManager.currentWordOffset];
            [bookView highlightWordAtBookmarkPoint:point];
        }
		
        ++_audioBookManager.currentWordOffset;
		++_audioBookManager.timeIx;
	}
    if ( _audioBookManager.currentWordOffset == [_audioBookManager.blockWords count] ) {
		// Last word of block, get more words.  
		NSLog(@"Reached end of block, getting more words.");
		[self prepareTextToSpeakWithAudioManager:_audioBookManager continuingSpeech:YES];
	}    
}

- (void)stopAudio {		
	if ([self.book hasAudiobook]) 
        [_audioBookManager stopAudio];	
    else if ([self.book hasTTSRights]) 
        [_acapelaAudioManager stopSpeaking];
}

- (void)pauseAudio {		
	if ([self.book hasAudiobook]) {
		[_audioBookManager pauseAudio];
		[_audioBookManager setPageChanged:NO];
	}	
	else if ([self.book hasTTSRights]) {
		[_acapelaAudioManager pauseSpeaking];
		[_acapelaAudioManager setPageChanged:NO]; // In case speaking continued through a page turn.
	}
}

- (void)prepareTTSEngine {
	[_acapelaAudioManager setEngineWithPreferences:YES];  
	[_acapelaAudioManager setDelegate:self];
}

- (void)toggleAudio:(id)sender {
    if (self.audioPlaying) {
        [self pauseAudio];  // For tts, try again with stopSpeakingAtBoundary when next RC comes.
        self.audioPlaying = NO;  
    } else { 
		NSLog(@"[self.book hasTTSRights]: %i",[self.book hasTTSRights]);
		NSLog(@"[self.book hasAudiobook]: %i",[self.book hasAudiobook]);
		
        if ([self.book hasAudiobook]) {
            if ( _audioBookManager.startedPlaying == NO || _audioBookManager.pageChanged) { 
                // So far this only would work for fixed view.
                if ( ![self loadAudioFiles:[self.bookView.currentBookmarkPoint layoutPage] segmentIndex:0] ) {
                    // No audio files for this page.
                    // Look for next page with files.
                    BOOL loadedFilesAhead = NO;
                    for ( int i=[self.bookView.currentBookmarkPoint layoutPage]+1;;++i ) {
                        if ( [self loadAudioFiles:i segmentIndex:0] ) {
                            loadedFilesAhead = YES;
							BOOL animatedPageChange = YES;
							if ([[UIApplication sharedApplication] respondsToSelector:@selector(applicationState)]) {
								if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) animatedPageChange = NO;
							}							
                            [self.bookView goToPageNumber:i animated:animatedPageChange];
                            break;
                        }
                    }
                    if ( !loadedFilesAhead )
                        return;
                }
                
                [self prepareTextToSpeakWithAudioManager:_audioBookManager continuingSpeech:NO];
            }
            [_audioBookManager setSpeakingTimer:[NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(checkHighlightTime:) userInfo:nil repeats:YES]];
            [_audioBookManager playAudio];
            self.audioPlaying = _audioBookManager.startedPlaying;  
        }
        else if ([self.book hasTTSRights]) {
			if ([[[BlioAcapelaAudioManager sharedAcapelaAudioManager] availableVoicesForUse] count] > 0) {
				[self prepareTTSEngine];
				[_acapelaAudioManager setSpeakingTimer:[NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(speakNextBlock:) userInfo:nil repeats:YES]];				
				[self prepareTextToSpeakWithAudioManager:_acapelaAudioManager continuingSpeech:NO];
				self.audioPlaying = _acapelaAudioManager.startedPlaying;
			}
			else {
				[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"We're Sorry...",@"\"We're Sorry...\" alert message title")
											 message:NSLocalizedStringWithDefaultValue(@"TTS_CANNOT_BE_HEARD_WITHOUT_AVAILABLE_VOICES",nil,[NSBundle mainBundle],@"You must first download Text-To-Speech voices if you wish to hear this book read aloud. Please download a voice in the Library Settings section and try again.",@"Alert message shown to end-user when the end-user attempts to hear a book read aloud by the TTS engine without any voices downloaded.")
											delegate:nil 
								   cancelButtonTitle:@"OK"
								   otherButtonTitles: nil];
				return;
			}
        }
        else {
			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"We're Sorry...",@"\"We're Sorry...\" alert message title")
										 message:NSLocalizedStringWithDefaultValue(@"NO_AUDIO_PERMITTED_FOR_THIS_BOOK",nil,[NSBundle mainBundle],@"No audio is permitted for this book.",@"Alert message shown to end-user when the end-user attempts to hear a book read but no audiobook is present and TTS is not enabled.")
										delegate:nil 
							   cancelButtonTitle:@"OK"
							   otherButtonTitles: nil];
			return;
        }
    }    
    [self updatePauseButton];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[self.view viewWithTag:ACTIVITY_INDICATOR];
	[activityIndicator stopAnimating];
	NSString* errorMsg = [error localizedDescription];
	NSLog(@"Error loading web page: %@",errorMsg);
	[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"An Error Has Occurred...",@"\"An Error Has Occurred...\" alert message title")
								 message:errorMsg
								delegate:nil 
					   cancelButtonTitle:@"OK"
					   otherButtonTitles: nil];
}

- (void)search:(id)sender {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (!self.searchViewController) {
            BlioBookSearchController *aBookSearchController = [[BlioBookSearchController alloc] initWithParagraphSource:[self.book paragraphSource]];
            [aBookSearchController setMaxPrefixAndMatchLength:20];
            [aBookSearchController setMaxSuffixLength:100];
            
            BlioBookSearchViewController *aSearchViewController = [[BlioBookSearchViewController alloc] init];
            [aSearchViewController setTintColor:_returnToNavigationBarTint];
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
            BlioBookSearchController *aBookSearchController = [[BlioBookSearchController alloc] initWithParagraphSource:[self.book paragraphSource]];
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
#pragma mark Add ActionSheet Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == kBlioLibraryAddNoteAction) {
        if ([self.bookView respondsToSelector:@selector(selectedRange)]) {
            BlioBookmarkRange *range = [self.bookView selectedRange];
            [self displayNote:nil atRange:range animated:YES];
        }
    } else if (buttonIndex == kBlioLibraryAddBookmarkAction) {
		[self toggleBookmark:actionSheet];
    } else {
        // Cancel
        [self setToolbarsForModalOverlayActive:NO];
    }
}

- (void)notesViewCreateNote:(BlioNotesView *)notesView {
    NSMutableSet *notes = [self.book mutableSetValueForKey:@"notes"];
    
    NSManagedObject *newNote = [NSEntityDescription
                                insertNewObjectForEntityForName:@"BlioNote"
                                inManagedObjectContext:[self managedObjectContext]];
    
    BlioBookmarkRange *noteRange = notesView.range;
    NSManagedObject *existingHighlight = [self.book fetchHighlightWithBookmarkRange:noteRange];
    
    if (nil != existingHighlight) {
        [newNote setValue:existingHighlight forKey:@"highlight"];
        [newNote setValue:[existingHighlight valueForKey:@"range"] forKey:@"range"];
        [newNote setValue:notesView.textView.text forKey:@"noteText"];
        [notes addObject:newNote];
    } else {
        if ([self.bookView respondsToSelector:@selector(selectedRange)]) {
            noteRange = [self.bookView selectedRange];
            
            NSManagedObject *newRange = [noteRange persistentBookmarkRangeInContext:[self managedObjectContext]];
            [newNote setValue:newRange forKey:@"range"];
            [newNote setValue:notesView.textView.text forKey:@"noteText"];
            [notes addObject:newNote];
        }
    }
    
    NSError *error;
    if (![[self managedObjectContext] save:&error])
        NSLog(@"[BlioBookViewController notesViewCreateNote:] Save failed with error: %@, %@", error, [error userInfo]);
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
        
        NSError *error;
        if (![[self managedObjectContext] save:&error])
            NSLog(@"[BlioBookViewController notesViewUpdateNote:] Save failed with error: %@, %@", error, [error userInfo]);
    }
}

- (void)notesViewDismissed {
    [self setToolbarsForModalOverlayActive:NO];
}

#pragma mark -
#pragma mark Rotation Handling

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    if ([self isRotationLocked])
        return NO;
    else
        return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration 
{
    // Doing this here instead of in the 'didRotate' callback results in smoother
    // animation that happens simultaneously with the rotate.
    [self layoutNavigationToolbar];
    [self layoutPauseButton];
    [self setNavigationBarButtons];
    if (_pageJumpView) {
        [self layoutPageJumpView];
        [self layoutPageJumpLabelText];
        [self layoutPageJumpSlider];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if ([self.bookView respondsToSelector:@selector(willRotateToInterfaceOrientation:duration:)])
        [self.bookView willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    if ([self.searchPopover isPopoverVisible]) {
        shouldDisplaySearchAfterRotation = YES;
    }
    
    [self.searchViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.contentsPopover willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.viewSettingsPopover willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
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
    NSInteger bookmarkedPage;
	
    while (((savedPoint = [self popBookmarkPoint])) != nil) {
        NSInteger currentPage = [self.bookView pageNumber];
        bookmarkedPage = [self.bookView pageNumberForBookmarkPoint:savedPoint];
        if (currentPage != bookmarkedPage) {
            targetPoint = savedPoint;
            break;
        }
    }
    
    if (targetPoint != nil) {
		if ([self.bookView respondsToSelector:@selector(goToPageNumber:animated:saveToHistory:)]) {
			[self.bookView goToPageNumber:bookmarkedPage animated:YES saveToHistory:NO];
		} else {
			[self.bookView goToBookmarkPoint:targetPoint animated:YES saveToHistory:NO];
		}
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
    UIView *container = self.view;
    
    BlioNotesView *aNotesView = [[BlioNotesView alloc] initWithRange:range note:note];
    [aNotesView setDelegate:self];
    [aNotesView showInView:container animated:animated];
    [aNotesView release];
}

- (void)goToContentsBookmarkRange:(BlioBookmarkRange *)bookmarkRange animated:(BOOL)animated {
    NSInteger pageNum;
    if ([self.bookView respondsToSelector:@selector(pageNumberForBookmarkRange:)]) {
        pageNum = [self.bookView pageNumberForBookmarkRange:bookmarkRange];
    } else {
        BlioBookmarkPoint *aBookMarkPoint = bookmarkRange.startPoint;
        pageNum = [self.bookView pageNumberForBookmarkPoint:aBookMarkPoint];
    }
    
    [self updatePageJumpPanelForPage:pageNum animated:animated];
    [self updatePieButtonForPage:pageNum animated:animated];
    
    if ([self.bookView respondsToSelector:@selector(goToBookmarkRange:animated:)]) {
        [self.bookView goToBookmarkRange:bookmarkRange animated:animated];
    } else {
        BlioBookmarkPoint *aBookMarkPoint = bookmarkRange.startPoint;
        [self.bookView goToBookmarkPoint:aBookMarkPoint animated:animated];
    }
}

- (void)goToContentsUuid:(NSString *)sectionUuid animated:(BOOL)animated {
    NSInteger newPageNumber = [[self.bookView contentsDataSource] pageNumberForSectionUuid:sectionUuid];

    [self updatePageJumpPanelForPage:newPageNumber animated:animated];
    [self updatePieButtonForPage:newPageNumber animated:animated];
    [_bookView goToUuid:sectionUuid animated:animated];
}

- (void)deleteNote:(NSManagedObject *)note {
    NSMutableSet *notes = [self.book mutableSetValueForKey:@"notes"];
    [notes removeObject:note];
    [[self managedObjectContext] deleteObject:note];
    
    NSError *error;
    if (![[self managedObjectContext] save:&error])
        NSLog(@"[BlioBookViewController deleteNote:] Save failed with error: %@, %@", error, [error userInfo]);
}

- (void)deleteBookmark:(NSManagedObject *)bookmark {
    NSMutableSet *bookmarks = [self.book mutableSetValueForKey:@"bookmarks"];
    [bookmarks removeObject:bookmark];
    [[self managedObjectContext] deleteObject:bookmark];
    
    NSError *error;
    if (![[self managedObjectContext] save:&error])
        NSLog(@"[BlioBookViewController deleteBookmark:] Save failed with error: %@, %@", error, [error userInfo]);
	[self updateBookmarkButton];
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
        
        NSError *error;
        if (![[self managedObjectContext] save:&error])
            NSLog(@"Save after updating highlight failed with error: %@, %@", error, [error userInfo]);
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
        
        NSError *error;
        if (![[self managedObjectContext] save:&error])
        NSLog(@"Save after removing highlight failed with error: %@, %@", error, [error userInfo]);
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

- (void)openWebToolWithRange:(BlioBookmarkRange *)range toolType:(BlioWebToolsType)type { 
	if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"We're Sorry...",@"\"We're Sorry...\" alert message title")
									 message:NSLocalizedStringWithDefaultValue(@"INTERNET_REQUIRED_WEBTOOL",nil,[NSBundle mainBundle],@"An Internet connection was not found; Internet access is required to use this web tool.",@"Alert message when the user tries to download a book without an Internet connection.")
									delegate:nil 
						   cancelButtonTitle:@"OK"
						   otherButtonTitles: nil];		
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
			titleString = [NSString stringWithString:@"Dictionary"];
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
			titleString = [NSString stringWithString:@"Encyclopedia"];
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
			titleString = [NSString stringWithString:@"Web Search"];
			break;
		default:
			break;
	}
    NSURL *url = [NSURL URLWithString:queryString];
    if (nil != url) {
        BlioWebToolsViewController *aWebToolController = [[BlioWebToolsViewController alloc] initWithURL:url];
        aWebToolController.topViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done",@"\"Done\" bar button") style:UIBarButtonItemStyleDone target:self action:@selector(dismissWebTool:)];                                                 
        aWebToolController.topViewController.navigationItem.title = titleString;
		
		//NSArray *buttonNames = [NSArray arrayWithObjects:@"B", @"F", nil]; // until there's icons...
		NSArray *buttonNames = [NSArray arrayWithObjects:[UIImage imageNamed:@"back-gray.png"], [UIImage imageNamed:@"forward-gray.png"], nil]; // until there's icons...
		UISegmentedControl* segmentedControl = [[UISegmentedControl alloc] initWithItems:buttonNames];
		segmentedControl.momentary = YES;
		segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
		segmentedControl.frame = CGRectMake(0, 0, 70, 30);
		[segmentedControl addTarget:self action:@selector(webNavigate:) forControlEvents:UIControlEventValueChanged];
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

#pragma mark -
#pragma mark Edit Menu Responder Actions 
-(void)addBookmark {
	NSLog(@"%@", NSStringFromSelector(_cmd));
	[self setToolbarsForModalOverlayActive:NO];
	
	BlioBookmarkPoint *currentBookmarkPoint = self.bookView.currentBookmarkPoint;
	BlioBookmarkRange *currentBookmarkRange = [BlioBookmarkRange bookmarkRangeWithBookmarkPoint:currentBookmarkPoint];
	
	NSMutableSet *bookmarks = [self.book mutableSetValueForKey:@"bookmarks"];
	NSManagedObject *existingBookmark = nil;
	
	for (NSManagedObject *bookmark in bookmarks) {
		if ([BlioBookmarkRange bookmark:bookmark isEqualToBookmarkRange:currentBookmarkRange]) {
			existingBookmark = bookmark;
			break;
		}
	}
	
	// Don't allow duplicate bookmarks to be created
	if (nil != existingBookmark) {
		return;
	}
	// TODO clean this up to consolodate Bookmark range and getCurrentBlockId
	NSString *bookmarkText = nil;
	if ([self currentPageLayout] == kBlioPageLayoutPlainText) {
		/*  EucEPubBook *book = (EucEPubBook*)[(BlioEPubView *)self.bookView book];
		 uint32_t blockId, wordOffset;
		 [book getCurrentBlockId:&blockId wordOffset:&wordOffset];
		 bookmarkText = [[book blockWordsForBlockWithId:blockId] componentsJoinedByString:@" "];
		 */
	} else if ([self currentPageLayout] == kBlioPageLayoutPageLayout) {
		NSInteger pageIndex = self.bookView.pageNumber - 1;
		bookmarkText = [[self.book textFlow] stringForPageAtIndex:pageIndex];
	}
	
	NSManagedObject *newBookmark = [NSEntityDescription
									insertNewObjectForEntityForName:@"BlioBookmark"
									inManagedObjectContext:[self managedObjectContext]];
	
	NSManagedObject *newRange = [currentBookmarkRange persistentBookmarkRangeInContext:[self managedObjectContext]];
	[newBookmark setValue:newRange forKey:@"range"];
	[newBookmark setValue:bookmarkText forKey:@"bookmarkText"];
	[bookmarks addObject:newBookmark];
	
	NSError *error;
	if (![[self managedObjectContext] save:&error])
		NSLog(@"[BlioBookViewController actionSheet:clickedButtonAtIndex:] Save failed with error: %@, %@", error, [error userInfo]);
	else {
		[self updateBookmarkButton];
	}
}

-(void)toggleBookmark:(id)sender {
	NSLog(@"%@", NSStringFromSelector(_cmd));
	[self setToolbarsForModalOverlayActive:NO];
	
	BlioBookmarkPoint *currentBookmarkPoint = self.bookView.currentBookmarkPoint;
	BlioBookmarkRange *currentBookmarkRange = [BlioBookmarkRange bookmarkRangeWithBookmarkPoint:currentBookmarkPoint];
	
	NSMutableSet *bookmarks = [self.book mutableSetValueForKey:@"bookmarks"];
	NSManagedObject *existingBookmark = nil;
	NSInteger pageNum;
	// try to find exact match.
	for (NSManagedObject *bookmark in bookmarks) {
		if ([BlioBookmarkRange bookmark:bookmark isEqualToBookmarkRange:currentBookmarkRange]) {
			existingBookmark = bookmark;
			break;
		}
	}
	// try to find match with equal page numbers.
	for (NSManagedObject *bookmark in bookmarks) {
		BlioBookmarkRange *aBookmarkRange = [BlioBookmarkRange bookmarkRangeWithPersistentBookmarkRange:[bookmark valueForKey:@"range"]];    
		if ([self.bookView respondsToSelector:@selector(pageNumberForBookmarkRange:)]) {
			pageNum = [self.bookView pageNumberForBookmarkRange:aBookmarkRange];
		} else {			
			BlioBookmarkPoint *aBookMarkPoint = aBookmarkRange.startPoint;
			pageNum = [self.bookView pageNumberForBookmarkPoint:aBookMarkPoint];
		}
		NSLog(@"bookmarkPageNum: %i and currentPageNum: %i",pageNum,self.bookView.pageNumber);		
		if (pageNum == self.bookView.pageNumber) {
			existingBookmark = bookmark;
			break;
		}
	}

	// Don't allow duplicate bookmarks to be created
	if (nil != existingBookmark) {
		NSLog(@"deleting bookmark...");
		[self deleteBookmark:existingBookmark];
		[self updateBookmarkButton];
		return;
	}
	NSLog(@"creating bookmark...");
	// TODO clean this up to consolodate Bookmark range and getCurrentBlockId
	NSString *bookmarkText = nil;
	if ([self currentPageLayout] == kBlioPageLayoutPlainText) {
		/*  EucEPubBook *book = (EucEPubBook*)[(BlioEPubView *)self.bookView book];
		 uint32_t blockId, wordOffset;
		 [book getCurrentBlockId:&blockId wordOffset:&wordOffset];
		 bookmarkText = [[book blockWordsForBlockWithId:blockId] componentsJoinedByString:@" "];
		 */
	} else if ([self currentPageLayout] == kBlioPageLayoutPageLayout) {
		NSInteger pageIndex = self.bookView.pageNumber - 1;
		bookmarkText = [[self.book textFlow] stringForPageAtIndex:pageIndex];
	}
	NSLog(@"bookmarkText: %@",bookmarkText);
	
	NSManagedObject *newBookmark = [NSEntityDescription
									insertNewObjectForEntityForName:@"BlioBookmark"
									inManagedObjectContext:[self managedObjectContext]];
	NSInteger newBookmarkPointPageNum;
	if ([self.bookView respondsToSelector:@selector(pageNumberForBookmarkRange:)]) {
		newBookmarkPointPageNum = [self.bookView pageNumberForBookmarkRange:currentBookmarkRange];
	}
	else newBookmarkPointPageNum = [self.bookView pageNumberForBookmarkPoint:currentBookmarkRange.startPoint];
	NSLog(@"newBookmarkPointPageNum: %i and current view pageNumber: %i and bookmarkpoint.layoutpage: %i", newBookmarkPointPageNum,self.bookView.pageNumber,currentBookmarkRange.startPoint.layoutPage);
	NSManagedObject *newRange = [currentBookmarkRange persistentBookmarkRangeInContext:[self managedObjectContext]];
	[newBookmark setValue:newRange forKey:@"range"];
	[newBookmark setValue:bookmarkText forKey:@"bookmarkText"];
	[bookmarks addObject:newBookmark];
	
	NSError *error;
	
	if (![[self managedObjectContext] save:&error])
		NSLog(@"[BlioBookViewController actionSheet:clickedButtonAtIndex:] Save failed with error: %@, %@", error, [error userInfo]);
	else {
		NSLog(@"bookmark save complete.");
		[self updateBookmarkButton];
	}
}

- (void)addHighlightWithColor:(UIColor *)color {
    if ([self.bookView respondsToSelector:@selector(selectedRange)]) {
        BlioBookmarkRange *selectedRange = [self.bookView selectedRange];
        NSManagedObject *existingHighlight = [self.book fetchHighlightWithBookmarkRange:selectedRange];
        
        if (nil != existingHighlight) {
            [existingHighlight setValue:color forKeyPath:@"range.color"];
        } else {
            NSMutableSet *highlights = [self.book mutableSetValueForKey:@"highlights"];

            NSManagedObject *newHighlight = [NSEntityDescription
                                             insertNewObjectForEntityForName:@"BlioHighlight"
                                             inManagedObjectContext:[self managedObjectContext]];
            
            NSManagedObject *newRange = [selectedRange persistentBookmarkRangeInContext:[self managedObjectContext]];
            [newRange setValue:color forKey:@"color"];
            [newHighlight setValue:newRange forKey:@"range"];
            [highlights addObject:newHighlight];
        }
        
        NSError *error;
        if (![[self managedObjectContext] save:&error])
            NSLog(@"[BlioBookViewController addHighlightWithColor:] Save failed with error: %@, %@", error, [error userInfo]);
    }
    
    //if ([self.bookView respondsToSelector:@selector(refreshHighlights)])
        //[self.bookView refreshHighlights];
}

- (void)addHighlightNoteWithColor:(UIColor *)color {
    [self addHighlightWithColor:color];
    
    if ([self.bookView respondsToSelector:@selector(selectedRange)]) {
        BlioBookmarkRange *range = [self.bookView selectedRange];
        [self displayNote:nil atRange:range animated:YES];
    }
}

- (void)updateHighlightNoteAtRange:(BlioBookmarkRange *)highlightRange withColor:(UIColor *)newColor {
    if ([self.bookView respondsToSelector:@selector(selectedRange)]) {
        
        BlioBookmarkRange *toRange = [self.bookView selectedRange];
        NSManagedObject *existingNote = nil;
        NSManagedObject *highlight = [self.book fetchHighlightWithBookmarkRange:highlightRange];
        
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
            
            NSError *error;
            if (![[self managedObjectContext] save:&error])
                NSLog(@"Save after updating highlight failed with error: %@, %@", error, [error userInfo]);
            
            existingNote = [highlight valueForKey:@"note"];
        }
        
        
        [self displayNote:existingNote atRange:toRange animated:YES];
    }
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
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    touchInProgress = NO;
    [super cancelTrackingWithEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    touchInProgress = NO;
    [super endTrackingWithTouch:touch withEvent:event];
}

- (void)accessibilityIncrement {
    [self.bookViewController performSelectorOnMainThread:@selector(incrementPage) withObject:nil waitUntilDone:YES];
}

- (void)accessibilityDecrement {
    [self.bookViewController performSelectorOnMainThread:@selector(decrementPage) withObject:nil waitUntilDone:YES];
}

@end
