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
#import <libEucalyptus/THPair.h>
#import <libEucalyptus/THEventCapturingWindow.h>
#import <libEucalyptus/EucBookTitleView.h>
#import <libEucalyptus/EucBookContentsTableViewController.h>
#import <libEucalyptus/EucEPubBook.h>
#import "BlioViewSettingsSheet.h"
#import "BlioNotesView.h"
#import "BlioEPubView.h"
#import "BlioLayoutView.h"

static NSString * const kBlioLastLayoutDefaultsKey = @"lastLayout";
static NSString * const kBlioLastFontSizeDefaultsKey = @"lastFontSize";
static NSString * const kBlioLastPageColorDefaultsKey = @"lastPageColor";
static NSString * const kBlioLastLockRotationDefaultsKey = @"lastLockRotation";
static NSString * const kBlioLastTapAdvanceDefaultsKey = @"lastTapAdvance";
static NSString * const kBlioLastTltScrollDefaultsKey = @"lastTiltScroll";

typedef enum {
    kBlioLibraryAddBookmarkAction = 0,
    kBlioLibraryAddNoteAction = 1,
} BlioLibraryAddActions;

typedef enum {
    kBlioPageLayoutPlainText = 0,
    kBlioPageLayoutPageLayout = 1,
    kBlioPageLayoutSpeedRead = 2,
} BlioPageLayout;

typedef enum {
    kBlioFontSizeVerySmall = 0,
    kBlioFontSizeSmall = 1,
    kBlioFontSizeMedium = 2,
    kBlioFontSizeLarge = 3,
    kBlioFontSizeVeryLarge = 4,
} BlioFontSize;
static const CGFloat kBlioFontPointSizeArray[] = { 14.0f, 16.0f, 18.0f, 20.0f, 22.0f };

static NSString *kBlioFontPageTextureNamesArray[] = { @"paper-white.png", @"paper-black.png", @"paper-neutral.png" };
static const BOOL kBlioFontPageTexturesAreDarkArray[] = { NO, YES, NO };

typedef enum {
    kBlioRotationLockOff = 0,
    kBlioRotationLockOn = 1,
} BlioRotationLock;

typedef enum {
    kBlioTapTurnOff = 0,
    kBlioTapTurnOn = 1,
} BlioTapTurn;

@interface _BlioBookViewControllerTransparentView : UIView {
    BlioBookViewController *controller;
}

@property (nonatomic, assign) BlioBookViewController *controller;
@end

@implementation _BlioBookViewControllerTransparentView

@synthesize controller;

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *ret = [super hitTest:point withEvent:event];
    if(ret == self) {
        UIView *view = controller.bookView;
        CGPoint insidePoint = [self convertPoint:point toView:view];
        ret = [view hitTest:insidePoint withEvent:event];
    }
    return ret;
}

@end


@interface BlioBookViewController (PRIVATE)
- (void)_toggleToolbars;
- (NSArray *)_toolbarItemsForReadingView;
- (void) _updatePageJumpLabelForPage:(NSUInteger)page;

@end

@implementation BlioBookViewController

@synthesize book = _book;
@synthesize bookView = _bookView;
@synthesize pageJumpView = _pageJumpView;

@synthesize returnToNavigationBarStyle = _returnToNavigationBarStyle;
@synthesize returnToStatusBarStyle = _returnToStatusBarStyle;
@synthesize returnToNavigationBarHidden = _returnToNavigationBarHidden;
@synthesize returnToStatusBarHidden = _returnToStatusBarHidden;

@synthesize currentPageColor = _currentPageColor;

@synthesize audioPlaying = _audioPlaying;

@synthesize tiltScroller, tapDetector, motionControlsEnabled;

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

- (id)initWithBook:(BlioMockBook *)newBook {
    tiltScroller = [[MSTiltScroller alloc] init];
    tapDetector = [[MSTapDetector alloc] init];
    motionControlsEnabled = kBlioTapTurnOff;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tapToNextPage) name:@"TapToNextPage" object:nil];
    
    BlioPageLayout lastLayout = [[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastLayoutDefaultsKey];
    
    switch (lastLayout) {
        case kBlioPageLayoutPageLayout: {
            if ([newBook pdfPath]) {
                BlioLayoutView *aBookView = [[BlioLayoutView alloc] initWithPath:[newBook pdfPath]];
                
                if ((self = [self initWithBookView:aBookView])) {
                    self.bookView = aBookView;
                    self.book = newBook;
                }
                [aBookView release];
            } else {
            return nil;
            }
        }
            break;
        default: {
            if ([newBook bookPath]) {
                EucEPubBook *aEPubBook = [[EucEPubBook alloc] initWithPath:[newBook bookPath]];
                BlioEPubView *aBookView = [[BlioEPubView alloc] initWithFrame:[[UIScreen mainScreen] bounds] book:aEPubBook];
                aBookView.appearAtCoverThenOpen = YES;
                if ((self = [self initWithBookView:aBookView])) {
                    self.bookView = aBookView;
                    self.book = newBook;
                    self.currentPageColor = [[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastPageColorDefaultsKey];
                }
                [aBookView release];
                [aEPubBook release];
            } else {
                return nil;
            }
        } 
            break;
    }
    return self;
}

- (id)initWithBookView:(UIView<BlioBookView> *)view
{
	if ((self = [super initWithNibName:nil bundle:nil])) {
        self.audioPlaying = NO;
        self.wantsFullScreenLayout = YES;

        UIButton *backArrow = [THNavigationButton leftNavigationButtonWithArrowInBarStyle:UIBarStyleBlackTranslucent];
        [backArrow addTarget:self
                      action:@selector(_backButtonTapped) 
            forControlEvents:UIControlEventTouchUpInside];

        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backArrow];
        self.navigationItem.leftBarButtonItem = backItem;
        [backItem release];
                
        EucBookTitleView *titleView = [[EucBookTitleView alloc] init];
        CGRect frame = titleView.frame;
        frame.size.width = [[UIScreen mainScreen] bounds].size.width;
        [titleView setFrame:frame];
        titleView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        self.navigationItem.titleView = titleView;
        [titleView release];
                
        _firstAppearance = YES;
        
        self.toolbarItems = [self _toolbarItemsForReadingView];
        
        _pageJumpView = nil;
        _bookView = [view retain];        
    }
	return self;
}

- (NSArray *)_toolbarItemsForReadingView {
    
    NSMutableArray *readingItems = [NSMutableArray array];
    UIBarButtonItem *item;
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-contents.png"]
                                            style:UIBarButtonItemStylePlain
                                           target:self 
                                           action:@selector(showContents:)];
    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-plus.png"]
                                            style:UIBarButtonItemStylePlain
                                           target:self 
                                           action:@selector(showAddMenu:)];
    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];  
    
    item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-search.png"]
                                            style:UIBarButtonItemStylePlain
                                           target:self 
                                           action:nil];
    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];  
    
    UIImage *audioImage = nil;
    if (self.audioPlaying)
        audioImage = [UIImage imageNamed:@"icon-pause.png"];
    else 
        audioImage = [UIImage imageNamed:@"icon-play.png"];
    
    item = [[UIBarButtonItem alloc] initWithImage:audioImage
                                            style:UIBarButtonItemStylePlain
                                           target:self 
                                           action:@selector(toggleAudio:)];
    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-eye.png"]
                                            style:UIBarButtonItemStylePlain
                                           target:self 
                                           action:@selector(showViewSettings:)];
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
        THEventCapturingWindow *window = (THEventCapturingWindow *)[_bookView superview];
        [window removeTouchObserver:self forView:_bookView];
        
        [_bookView removeFromSuperview];
        [_bookView release];
        _bookView = [bookView retain];
        
        [(THEventCapturingWindow *)window addTouchObserver:self forView:_bookView];
        
        EucBookTitleView *titleView = (EucBookTitleView *)self.navigationItem.titleView;
        [titleView setTitle:[self.book title]];
        [titleView setAuthor:[self.book author]];  
        
        [window addSubview:_bookView];
        [window sendSubviewToBack:_bookView];
    }
}

- (void)_backButtonTapped
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)_contentsViewDidAppear
{
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

- (void)_contentsViewDidDisappear
{
    NSString *newSectionUuid = [_contentsSheet.selectedUuid retain];
    
    [_contentsSheet.view removeFromSuperview];
    [_contentsSheet release];
    _contentsSheet = nil;
    
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    
    if(newSectionUuid) {
        [_bookView jumpToUuid:newSectionUuid];
        [newSectionUuid release];
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    NSString *name = [anim valueForKey:@"THName"];
    if([name isEqualToString:@"ContentsSlideIn"]) {
        [self _contentsViewDidAppear];
    } else if([name isEqualToString:@"PageTurningViewSlideOut"]) {
        [(UIView *)[anim valueForKey:@"THView"] removeFromSuperview];   
    }
}

- (void)bookContentsTableViewController:(EucBookContentsTableViewController *)controller didSelectSectionWithUuid:(NSString *)uuid
{
    [self performSelector:@selector(dismissContents)];
}


- (void)loadView 
{
    CGRect mainScreenBounds = [[UIScreen mainScreen] applicationFrame];
    _BlioBookViewControllerTransparentView *mainSuperview = [[_BlioBookViewControllerTransparentView alloc] initWithFrame:mainScreenBounds];
    mainSuperview.controller = self;
    [mainSuperview setBackgroundColor:[UIColor clearColor]];
    [mainSuperview setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    mainSuperview.opaque = NO;
    mainSuperview.multipleTouchEnabled = YES;
    self.view = mainSuperview;
    [mainSuperview release];
        
    if(!self.toolbarsVisibleAfterAppearance) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    }    
}

- (void)viewWillAppear:(BOOL)animated
{
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
        
        // Set the status bar and navigation bar styles.
        navigationBar.tintColor = nil;
        navigationBar.barStyle = UIBarStyleBlackTranslucent;
        toolbar.tintColor = nil;
        toolbar.barStyle = UIBarStyleBlackTranslucent;
        
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
        }

        UIWindow *window = self.navigationController.view.window;
        [(THEventCapturingWindow *)window addTouchObserver:self forView:_bookView];
                        
        EucBookTitleView *titleView = (EucBookTitleView *)self.navigationItem.titleView;
        [titleView setTitle:[self.book title]];
        [titleView setAuthor:[self.book author]];                
        
        _pageJumpButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward 
          target:self action:@selector(togglePageJumpPanel)];
        
        [self.navigationItem setRightBarButtonItem:_pageJumpButton];
        
        [window addSubview:_bookView];
        [window sendSubviewToBack:_bookView];
        
        if(animated) {
            CATransition *animation = [CATransition animation];
            animation.type = kCATransitionPush;
            animation.subtype = kCATransitionFromRight;
            animation.duration = 1.0/3.0;
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            [[_bookView layer] addAnimation:animation forKey:@"PageViewTransitionIn"];
        }        
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    if(_firstAppearance) {
        UIApplication *application = [UIApplication sharedApplication];
        if(self.toolbarsVisibleAfterAppearance) {
            if([application isStatusBarHidden]) {
                [application setStatusBarHidden:NO animated:YES];
                [self.navigationController setNavigationBarHidden:YES animated:YES];
                [self.navigationController setNavigationBarHidden:NO animated:NO];
            }
            //if(animated) {
                CGRect frame = self.navigationController.toolbar.frame;
                frame.origin.y += frame.size.height;
                self.navigationController.toolbar.frame = frame;
                [UIView beginAnimations:@"PullInToolbarAnimations" context:NULL];
                frame.origin.y -= frame.size.height;
                self.navigationController.toolbar.frame = frame;
                [UIView commitAnimations];                
            //}                    
        } else {
            UINavigationBar *navBar = self.navigationController.navigationBar;
            navBar.barStyle = UIBarStyleBlackTranslucent;  
            if(![application isStatusBarHidden]) {
                [application setStatusBarHidden:YES animated:YES];
            }            
        }
    }
    _firstAppearance = NO;
}


- (void)viewWillDisappear:(BOOL)animated
{
    if(!self.modalViewController) {
        _viewIsDisappearing = YES;
        if(_contentsSheet) {
            [self performSelector:@selector(dismissContents)];
        }
        if(_bookView) {
            [(THEventCapturingWindow *)self.view.window removeTouchObserver:self forView:_bookView];

            if([_bookView respondsToSelector:@selector(stopAnimation)]) {
                [_bookView performSelector:@selector(stopAnimation)];
            }

            [self.navigationController setToolbarHidden:YES animated:NO];
            [self.navigationController setToolbarHidden:NO animated:NO];
            UIToolbar *toolbar = self.navigationController.toolbar;
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
                
                // Set some state so that we can remove the pageview from its
                // superview in the animationDidStop delegate.
                [animation setValue:@"PageTurningViewSlideOut" forKey:@"THName"];
                [animation setValue:_bookView forKey:@"THView"];
                animation.delegate = self;
                
                [[_bookView layer] addAnimation:animation forKey:@"PageViewTransitionOut"];
                [[toolbar layer] addAnimation:animation forKey:@"PageViewTransitionOut"];
            } else {
                [_bookView removeFromSuperview];
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
                [application setStatusBarHidden:_returnToStatusBarHidden 
                                       animated:YES];
            }           
            UINavigationBar *navBar = self.navigationController.navigationBar;
            navBar.barStyle = UIBarStyleDefault;
            navBar.barStyle = _returnToNavigationBarStyle;
            navBar.tintColor = _returnToNavigationBarTint;
            [_returnToNavigationBarTint release];
            _returnToNavigationBarTint = nil;
            
            [UIView commitAnimations];
            

            if(_returnToNavigationBarHidden != self.navigationController.isNavigationBarHidden) {
                [self.navigationController setNavigationBarHidden:_returnToNavigationBarHidden 
                                                         animated:NO];
            }     
        }
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    }
}


- (void)viewDidDisappear:(BOOL)animated
{    
    _viewIsDisappearing = NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
}


- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIAccelerometer sharedAccelerometer] setUpdateInterval:0];
    [[UIAccelerometer sharedAccelerometer] setDelegate:nil];
    
    [tapDetector release];
    [tiltScroller release];
    [_bookView release];
    self.book = nil;
    self.pageJumpView = nil;
    
	[super dealloc];
}


- (void)_fadeDidEnd
{
    if(_fadeState == BookViewControlleUIFadeStateFadingOut) {
        self.navigationController.toolbarHidden = YES;
        self.navigationController.navigationBar.hidden = YES;
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    } else {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
    _fadeState = BookViewControlleUIFadeStateNone;
}


- (void)_fadeWillStart
{
    if(_fadeState == BookViewControlleUIFadeStateFadingOut) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES animated:YES];    
    } 
}


- (void)_toggleToolbars
{
    if(_fadeState == BookViewControlleUIFadeStateNone) {
        if(self.navigationController.toolbarHidden == YES) {
            [[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO]; 
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:NO];
            self.navigationController.navigationBarHidden = NO;
            self.navigationController.navigationBar.hidden = NO;
            self.navigationController.toolbarHidden = NO;
            self.navigationController.toolbar.alpha = 0;
            _fadeState = BookViewControlleUIFadeStateFadingIn;
        } else {
            _fadeState = BookViewControlleUIFadeStateFadingOut;
        }
                
        // Durations below taken from trial-and-error comparison with the 
        // Photos application.
        [UIView beginAnimations:@"ToolbarsFade" context:nil];
        
        if(_fadeState == BookViewControlleUIFadeStateFadingIn) {
            [UIView setAnimationDuration:0.0];
            self.navigationController.toolbar.alpha = 1;          
            self.pageJumpView.alpha = 1;
            self.navigationController.navigationBar.alpha = 1;
        } else {
            [UIView setAnimationDuration:1.0/3.0];
            self.navigationController.toolbar.alpha = 0;
            self.pageJumpView.alpha = 0;
            self.navigationController.navigationBar.alpha = 0;
        }
        
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(_fadeDidEnd)];
        [UIView setAnimationWillStartSelector:@selector(_fadeWillStart)];
        
        [UIView commitAnimations];        
    }
}


- (void)observeTouch:(UITouch *)touch
{
    UITouchPhase phase = touch.phase;
        
    if(touch != _touch) {
        [_touch release];
        _touch = nil;
        if(phase == UITouchPhaseBegan) {
            _touch = [touch retain];
            _touchMoved = NO;
        }
    } else if(touch == _touch) {
        if(phase == UITouchPhaseMoved) { 
            _touchMoved = YES;
            if(!self.navigationController.toolbarHidden) {
                [self _toggleToolbars];
            }
        } else if(phase == UITouchPhaseEnded) {
            if(!_touchMoved) {
                [self _toggleToolbars];
            }
            [_touch release];
            _touch = nil;
        } else if(phase == UITouchPhaseCancelled) {
            [_touch release];
            _touch = nil;
        }
    }
}

- (void) togglePageJumpPanel
{ 
  CGPoint navBarBottomLeft = CGPointMake(0.0, self.navigationController.navigationBar.frame.size.height);
  CGPoint xt = [self.view convertPoint:navBarBottomLeft fromView:self.navigationController.navigationBar];
    
  if(!_pageJumpView) {
    self.pageJumpView = [[UIView alloc] init];
    [self.pageJumpView release];
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    [_pageJumpView setFrame:CGRectMake(xt.x, xt.y, screenSize.width, 46)];
    _pageJumpView.hidden = YES;
    _pageJumpView.opaque = NO;
    _pageJumpView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];

    CGRect labelFrame = _pageJumpView.bounds;
    labelFrame.size.height = 20;
    CGRect sliderFrame = _pageJumpView.bounds;
    sliderFrame.origin.y = 20;
    sliderFrame.origin.x = 4;
    sliderFrame.size.height = 24;
    sliderFrame.size.width -= 8;
    
  // the slider
    UISlider* slider = [[UISlider alloc] initWithFrame: sliderFrame];
    _pageJumpSlider = slider;
    
    UIImage *leftCapImage = [UIImage imageNamed:@"iPodLikeSliderBlueLeftCap.png"];
    leftCapImage = [leftCapImage stretchableImageWithLeftCapWidth:leftCapImage.size.width - 1 topCapHeight:leftCapImage.size.height];
    [slider setMinimumTrackImage:leftCapImage forState:UIControlStateNormal];
    
    UIImage *rightCapImage = [UIImage imageNamed:@"iPodLikeSliderWhiteRightCap.png"];
    rightCapImage = [rightCapImage stretchableImageWithLeftCapWidth:1 topCapHeight:0];
    [slider setMaximumTrackImage:rightCapImage forState:UIControlStateNormal];
    
    UIImage *thumbImage = [UIImage imageNamed:@"iPodLikeSliderKnob-Small.png"];
    [slider setThumbImage:thumbImage forState:UIControlStateNormal];
    [slider setThumbImage:thumbImage forState:UIControlStateHighlighted];            
    
    [slider addTarget:self action:@selector(_pageSliderSlid:) forControlEvents:UIControlEventValueChanged];
    
    slider.maximumValue = self.bookView.pageCount;
    slider.minimumValue = 1;
    [slider setValue:self.bookView.pageNumber];
  
    _pageJumpSliderTracking = NO;
    
  // feedback label
    _pageJumpLabel = [[UILabel alloc] initWithFrame:labelFrame];
    _pageJumpLabel.textAlignment = UITextAlignmentCenter;
    _pageJumpLabel.adjustsFontSizeToFitWidth = YES;
    _pageJumpLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    _pageJumpLabel.minimumFontSize = 8;
    _pageJumpLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
    _pageJumpLabel.shadowOffset = CGSizeMake(0, -1);
        
    _pageJumpLabel.backgroundColor = [UIColor clearColor];
    _pageJumpLabel.textColor = [UIColor whiteColor];
    
    [_pageJumpView addSubview:_pageJumpLabel];
    [_pageJumpView addSubview:slider];
  
    [self.view addSubview:_pageJumpView];
  }
  
  CGSize sz = _pageJumpView.bounds.size;
  BOOL hiding = !_pageJumpView.hidden;
  
  if (!hiding) {
    _pageJumpView.alpha = 0.0;
    _pageJumpView.hidden = NO;
    [self _updatePageJumpLabelForPage:self.bookView.pageNumber];
    [_pageJumpView setFrame:CGRectMake(0, xt.y - sz.height, sz.width, sz.height)];
  }
  
  [UIView beginAnimations:@"pageJumpViewToggle" context:NULL];
  [UIView setAnimationDidStopSelector:@selector(_pageJumpPanelDidAnimate)];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDuration:0.3f];

  if (hiding) {
    _pageJumpView.alpha = 0.0;
    [_pageJumpView setFrame:CGRectMake(0, xt.y - sz.height, sz.width, sz.height)];
  } else {
    _pageJumpView.alpha = 1.0;
    [_pageJumpView setFrame:CGRectMake(0, xt.y, sz.width, sz.height)];
  }
  
  [UIView commitAnimations];
}

- (void) _pageJumpPanelDidAnimate
{
  if (_pageJumpView.alpha == 0.0) {
    _pageJumpView.hidden = YES;
  }
}

- (void) _pageSliderSlid: (id) sender
{
  UISlider* slider = (UISlider*) sender;
  NSUInteger page = (NSUInteger) slider.value;
  [self _updatePageJumpLabelForPage:page];
  
  if (slider.isTracking) {
    _pageJumpSliderTracking = YES;
  } else if (_pageJumpSliderTracking) {
    [self.bookView setPageNumber:page animated:YES];
    _pageJumpSliderTracking = NO;
  }
}

- (void) _updatePageJumpLabelForPage:(NSUInteger)page
{
  NSString* section = [self.bookView.contentsDataSource sectionUuidForPageNumber:page];
  THPair* chapter = [self.bookView.contentsDataSource presentationNameAndSubTitleForSectionUuid:section];
  NSString* pageStr = [self.bookView.contentsDataSource displayPageNumberForPageNumber:page];
  
  if (section && chapter.first) {
    if (pageStr) {
      _pageJumpLabel.text = [NSString stringWithFormat:@"%@ - %@", pageStr, chapter.first];
    } else {
      _pageJumpLabel.text = [NSString stringWithFormat:@"%@", chapter.first];
    }
  } else {
    if (pageStr) {
      _pageJumpLabel.text = [NSString stringWithFormat:@"Page %@ of %d", pageStr, self.bookView.pageCount];
    } else {
      _pageJumpLabel.text = self.book.title;
    }
  } // of no section name
}

#pragma mark -
#pragma mark AccelerometerControl Methods

- (void)setupTiltScrollerWithBookView {
    if ([self.bookView isKindOfClass:[BlioLayoutView class]]) {
        [(BlioLayoutView *)self.bookView setTiltScroller:tiltScroller];
    }    
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acc {    
    if (!motionControlsEnabled) return;
    
    BlioBookViewController *bookViewController = (BlioBookViewController *)self.navigationController.topViewController;
    if([bookViewController.bookView isKindOfClass:[BlioLayoutView class]]) {
        if (![(BlioLayoutView *)bookViewController.bookView tiltScroller]) [self setupTiltScrollerWithBookView];
        [tiltScroller accelerometer:accelerometer didAccelerate:acc];        
    } else {
        [tapDetector updateFilterWithAcceleration:acc];
    }
    
    /*    if ([self currentPageLayout] == kBlioPageLayoutPageLayout) {
     [tapDetector updateHistoryWithX:acc.x Y:acc.y Z:acc.z];
     } else if ([self currentPageLayout] == kBlioPageLayoutPlainText) {
     [tiltScroller accelerometer:accelerometer didAccelerate:acc];
     }
     */    
}


- (void)tapToNextPage {
    if ([self.bookView isKindOfClass:[BlioEPubView class]]) {
        int currentPage = [self.bookView pageNumber];
        [self.bookView setPageNumber:currentPage+1 animated:YES];

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
    else
        return kBlioPageLayoutPlainText;
}

- (void)changePageLayout:(id)sender {
    
    BlioPageLayout newLayout = (BlioPageLayout)[sender selectedSegmentIndex];
    
    if([self currentPageLayout] != newLayout) {
        BlioBookViewController *bookViewController = (BlioBookViewController *)self.navigationController.topViewController;
        
        if (newLayout == kBlioPageLayoutPlainText && [self.book bookPath]) {
            EucEPubBook *book = [[EucEPubBook alloc] initWithPath:[self.book bookPath]];
            BlioEPubView *bookView = [[BlioEPubView alloc] initWithFrame:[[UIScreen mainScreen] bounds] 
                                                                    book:book];
            bookViewController.bookView = bookView;
            [bookView release];
            [book release];
            [[NSUserDefaults standardUserDefaults] setInteger:kBlioPageLayoutPlainText forKey:kBlioLastLayoutDefaultsKey];    
        } else if (newLayout == kBlioPageLayoutPageLayout && [self.book pdfPath]) {
            BlioLayoutView *layoutView = [[BlioLayoutView alloc] initWithPath:[self.book pdfPath]];
            bookViewController.bookView = layoutView;
            
            [layoutView release];
            [[NSUserDefaults standardUserDefaults] setInteger:kBlioPageLayoutPageLayout forKey:kBlioLastLayoutDefaultsKey];    
        }
    }
    
}

- (BOOL)shouldShowPageAttributeSettings {
    if ([self currentPageLayout] == kBlioPageLayoutPageLayout)
        return NO;
    else
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
    if(newColor != self.currentPageColor) {
        UIView<BlioBookView> *bookView = self.bookView;
        if([bookView respondsToSelector:(@selector(setPageTexture:isDark:))]) {
            NSString *imagePath = [[NSBundle mainBundle] pathForResource:kBlioFontPageTextureNamesArray[newColor]
                                                                  ofType:@""];
            UIImage *pageTexture = [UIImage imageWithData:[NSData dataWithContentsOfMappedFile:imagePath]];
            [bookView setPageTexture:pageTexture isDark:kBlioFontPageTexturesAreDarkArray[newColor]];
        }  
        _currentPageColor = newColor;
    }
}

- (void)changePageColor:(id)sender {
    self.currentPageColor = (BlioPageColor)[sender selectedSegmentIndex];
    [[NSUserDefaults standardUserDefaults] setInteger:self.currentPageColor forKey:kBlioLastPageColorDefaultsKey];
}

- (BlioRotationLock)currentLockRotation {
    return kBlioRotationLockOff;
}

- (void)changeLockRotation:(id)sender {
    // This is just a placeholder check. Obviously we shouldn't be checking against the string.
    BlioRotationLock newLock = (BlioRotationLock)[[sender titleForSegmentAtIndex:[sender selectedSegmentIndex]] isEqualToString:@"Unlock Rotation"];
    if([self currentLockRotation] != newLock) {
        [[NSUserDefaults standardUserDefaults] setInteger:newLock forKey:kBlioLastLockRotationDefaultsKey];
    }
}

- (BlioTapTurn)currentTapTurn {
    return motionControlsEnabled;

}

- (void)changeTapTurn:(id)sender {
    if (motionControlsEnabled == kBlioTapTurnOff) {
        motionControlsEnabled = kBlioTapTurnOn;
        [tiltScroller resetAngle];
        [self setupTiltScrollerWithBookView];
        
        [[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / 40)];
        [[UIAccelerometer sharedAccelerometer] setDelegate:self];   
    } else {
        motionControlsEnabled = kBlioTapTurnOff;
        [[UIAccelerometer sharedAccelerometer] setUpdateInterval:0];
        [[UIAccelerometer sharedAccelerometer] setDelegate:nil];
    }
    [[NSUserDefaults standardUserDefaults] setInteger:motionControlsEnabled forKey:kBlioLastTapAdvanceDefaultsKey];
}

#pragma mark -
#pragma mark Action Callback Methods

- (void)showContents:(id)sender {
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissContents)];
    [self.navigationItem setRightBarButtonItem:rightItem animated:YES];
    [rightItem release];
    
    _contentsSheet = [[EucBookContentsTableViewController alloc] init];
    _contentsSheet.dataSource = _bookView.contentsDataSource;
    _contentsSheet.delegate = self;        
    _contentsSheet.currentSectionUuid = [_bookView.contentsDataSource sectionUuidForPageNumber:_bookView.pageNumber];
    
    UIView *sheetView = _contentsSheet.view;
    
    UIView *window = self.view.window;    
    CGRect windowFrame = window.frame;
    UINavigationBar *navBar = self.navigationController.navigationBar;
    CGRect navBarRect = [navBar.superview convertRect:navBar.frame toView:window];
    
    sheetView.frame = CGRectMake(0, (navBarRect.origin.y + navBarRect.size.height), windowFrame.size.width, windowFrame.size.height - (navBarRect.origin.y + navBarRect.size.height)); 
    
    // Push in the contents sheet.
    CATransition *animation = [CATransition animation];
    [animation setType:kCATransitionMoveIn];
    [animation setSubtype:kCATransitionFromTop];
    [animation setDuration:0.3f];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [animation setValue:@"ContentsSlideIn" forKey:@"THName"];
    [animation setDelegate:self];
    [[sheetView layer] addAnimation:animation forKey:@"ContentSlide"];
    
    [window addSubview:sheetView];
    
    // Fade the nav bar and its contents to blue
    animation = [CATransition animation];
    [animation setType:kCATransitionFade];
    [animation setDuration:0.3f];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [[navBar layer] addAnimation:animation forKey:@"NavBarFade"];
    
    navBar.barStyle = UIBarStyleDefault;
    navBar.tintColor = _returnToNavigationBarTint;
    ((THNavigationButton *)self.navigationItem.leftBarButtonItem.customView).barStyle = UIBarStyleDefault;
    [((UIButton *)self.navigationItem.rightBarButtonItem.customView) setImage:[UIImage imageNamed:@"BookButton.png"]
                                                                     forState:UIControlStateNormal];
    [((UIButton *)self.navigationItem.leftBarButtonItem.customView) setAlpha:0.0f];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)dismissContents {
    
    UIView *sheetView = _contentsSheet.view;
    CGRect contentsViewFinalRect = sheetView.frame;
    contentsViewFinalRect.origin.y = contentsViewFinalRect.origin.y + contentsViewFinalRect.size.height;
    
    // Push out the contents sheet.
    [UIView beginAnimations:@"contentsSheetDisappear" context:NULL];
    [UIView setAnimationDidStopSelector:@selector(_contentsViewDidDisappear)];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.3f];
    
    sheetView.frame = contentsViewFinalRect;
    [self.navigationItem setRightBarButtonItem:_pageJumpButton animated:NO];
    
    if(!_viewIsDisappearing) {
        if(_contentsSheet.selectedUuid != nil && self.navigationController.toolbarHidden) {
            [self _toggleToolbars];
        }        
        
        // Turn the nav bar and its contents back to translucent.
        UINavigationBar *navBar = self.navigationController.navigationBar;
        
        CATransition *animation = [CATransition animation];
        [animation setType:kCATransitionFade];
        [animation setDuration:0.3f];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [[navBar layer] addAnimation:animation forKey:@"animation"];
        
        navBar.tintColor = nil;
        navBar.barStyle = UIBarStyleBlackTranslucent;
        ((THNavigationButton *)self.navigationItem.leftBarButtonItem.customView).barStyle = UIBarStyleBlackTranslucent;
        [((UIButton *)self.navigationItem.rightBarButtonItem.customView) setImage:[UIImage imageNamed:@"ContentsButton.png"]
                                                                         forState:UIControlStateNormal];
        [((UIButton *)self.navigationItem.leftBarButtonItem.customView) setAlpha:1.0f];
        
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES]; 
    }
    [UIView commitAnimations];
}


- (void)showAddMenu:(id)sender {
    UIActionSheet *aActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Add Bookmark", @"Add Notes", nil];
    aActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    aActionSheet.delegate = self;
    UIToolbar *toolbar = self.navigationController.toolbar;
    [aActionSheet showFromToolbar:toolbar];
    [aActionSheet release];
}

- (void)showViewSettings:(id)sender {
    BlioViewSettingsSheet *aSettingsSheet = [[BlioViewSettingsSheet alloc] initWithDelegate:self];
    UIToolbar *toolbar = self.navigationController.toolbar;
    [aSettingsSheet showFromToolbar:toolbar];
    [aSettingsSheet release];
}

- (void)dismissViewSettings:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)speakNextPargraph:(NSTimer*)timer {
	if ( _acapelaTTS.textToSpeakChanged ) {	
		[_acapelaTTS setTextToSpeakChanged:NO];
		NSRange pageRange;
		pageRange.location = [_acapelaTTS currentWordOffset];
		pageRange.length = [_acapelaTTS.paragraphWords count] - [_acapelaTTS currentWordOffset]; 	
		[_acapelaTTS startSpeaking:[[_acapelaTTS.paragraphWords subarrayWithRange:pageRange] componentsJoinedByString:@" "]];
	}
}

- (void) prepareTextToSpeak:(BOOL)continuingSpeech {
	BlioBookViewController *bookViewController = (BlioBookViewController *)self.navigationController.topViewController;
	BlioEPubView *bookView = (BlioEPubView *)bookViewController.bookView;
	EucEPubBook *book = (EucEPubBook*)bookView.book;
	uint32_t paragraphId, wordOffset;
	if ( continuingSpeech ) {
		// Continuing to speak, we just need more text.
		paragraphId = [book paragraphIdForParagraphAfterParagraphWithId:_acapelaTTS.currentParagraph];
		wordOffset = 0;
		[_acapelaTTS setCurrentWordOffset:wordOffset];
		[_acapelaTTS setCurrentParagraph:paragraphId];
		[_acapelaTTS.paragraphWords release];
		[_acapelaTTS setParagraphWords:nil];
		[_acapelaTTS setParagraphWords:[book paragraphWordsForParagraphWithId:[_acapelaTTS currentParagraph]]];
	}
	else {
		[book getCurrentParagraphId:&paragraphId wordOffset:&wordOffset];
		// Play button has just been pushed.
		if ( (paragraphId + wordOffset)!=[_acapelaTTS currentPage] ) {
			// Starting speech for the first time, or for the first time since changing the 
			// page or book after stopping speech the last time (whew).
			[_acapelaTTS setCurrentPage:(paragraphId + wordOffset)]; // Not very robust page-identifier
			[_acapelaTTS setCurrentWordOffset:wordOffset];
			[_acapelaTTS setCurrentParagraph:paragraphId];
			if ( _acapelaTTS.paragraphWords != nil ) {
				[_acapelaTTS.paragraphWords release];
				[_acapelaTTS setParagraphWords:nil];
			}
			[_acapelaTTS setParagraphWords:[book paragraphWordsForParagraphWithId:[_acapelaTTS currentParagraph]]];
		}
		// else use the current word and paragraph, which is where we last stopped.
		// edge case:  what if you stopped speech right after the end of the paragraph?
	}
	[_acapelaTTS setTextToSpeakChanged:YES];
}

- (BOOL)isEucalyptusWord:(NSRange)characterRange ofString:(NSString*)string {
	// For testing
	//NSString* thisWord = [string substringWithRange:characterRange];
	//NSLog(thisWord);
	
	BOOL wordIsNotPunctuation = ([string rangeOfCharacterFromSet:[[NSCharacterSet punctuationCharacterSet] invertedSet]
                                                         options:0 
                                                           range:characterRange].location != NSNotFound);
	// A hack to get around an apparent Acapela bug.
	BOOL wordIsNotRepeated = ([[string substringWithRange:characterRange] compare:[_acapelaTTS currentWord]] != NSOrderedSame)
    && ([[[NSString stringWithString:@"\""] stringByAppendingString:[string substringWithRange:characterRange]] compare:[_acapelaTTS currentWord]] != NSOrderedSame);  // E.g. "I and I (a case I've seen)
	
	/* Acapela does assemble hyphenated words, so I'm keeping this condition around
     just in case it turns out they slip up sometimes.
     // possible problem:  hyphen as a pause ("He waited- and then spoke.")
     NSRange lastCharacter;
     lastCharacter.length = 1;
     lastCharacter.location = characterRange.location + characterRange.length -1;
     BOOL wordIsNotHyphenated = ([[string substringWithRange:lastCharacter] compare:@"-"] != NSOrderedSame);
	 */
	
	return wordIsNotPunctuation && wordIsNotRepeated;
}

- (void)speechSynthesizer:(AcapelaSpeech*)synth didFinishSpeaking:(BOOL)finishedSpeaking
{
	if (finishedSpeaking) {
		// Reached end of paragraph.  Start on the next.
		[self prepareTextToSpeak:YES]; 
	}
	//else stop button pushed before end of paragraph.
}

- (void)speechSynthesizer:(AcapelaSpeech*)sender willSpeakWord:(NSRange)characterRange 
				 ofString:(NSString*)string 
{
	// The first string that comes in here after speaking has resumed has invalid range: 
	// location not zero but a high number.
    if(characterRange.location + characterRange.length < string.length) {
		if ( [self isEucalyptusWord:characterRange ofString:string] ) {
			NSLog(@"About to speak a word: \"%@\"", [string substringWithRange:characterRange]);
            BlioBookViewController *bookViewController = (BlioBookViewController *)self.navigationController.topViewController;
            BlioEPubView *bookView = (BlioEPubView *)bookViewController.bookView;
            [bookView highlightWordAtParagraphId:_acapelaTTS.currentParagraph wordOffset:_acapelaTTS.currentWordOffset];
            [_acapelaTTS setCurrentWordOffset:[_acapelaTTS currentWordOffset]+1];
			[_acapelaTTS setCurrentWord:[string substringWithRange:characterRange]];  
        }
    }
}

- (void)toggleAudio:(id)sender {
	if ([self currentPageLayout] == kBlioPageLayoutPlainText) {
		UIBarButtonItem *item = (UIBarButtonItem *)sender;
		
		UIImage *audioImage = nil;
		if (self.audioPlaying) {
			/* For testing
             [_testParagraphWords stopParagraphGetting];
             [_testParagraphWords release];
             _testParagraphWords = nil;
             */
			//[_acapelaTTS stopSpeaking];
			[_acapelaTTS stopSpeakingAtBoundary:1];
			audioImage = [UIImage imageNamed:@"icon-play.png"];
		} else { 
			/* For testing.  If this is uncommented, comment out the call to startSpeakingParagraph below.
			 BlioBookViewController *bookViewController = (BlioBookViewController *)self.navigationController.topViewController;
			 BlioEPubView *bookView = (BlioEPubView *)bookViewController.bookView;
			 EucEPubBook *book = (EucEPubBook*)bookView.book;
			 uint32_t paragraphId, wordOffset;
			 [book getCurrentParagraphId:&paragraphId wordOffset:&wordOffset];
			 _testParagraphWords = [[BlioTestParagraphWords alloc] init];
			 [_testParagraphWords startParagraphGettingFromBook:book atParagraphWithId:paragraphId];
			 */
			if (!self.navigationController.toolbarHidden) {
                [self _toggleToolbars];
            }
			if (_acapelaTTS == nil) {
				_acapelaTTS = [[AcapelaTTS alloc] init];
				[_acapelaTTS initTTS];
				[_acapelaTTS setDelegate:self];
				[_acapelaTTS setRate:180];   // Will get from settings.
				[_acapelaTTS setVolume:70];  // Likewise.
				[_acapelaTTS setSpeakingTimer:[NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(speakNextPargraph:) userInfo:nil repeats:YES]];
			}
			[self prepareTextToSpeak:NO];
			audioImage = [UIImage imageNamed:@"icon-pause.png"];
		}
		self.audioPlaying = !self.audioPlaying;  
		[item setImage:audioImage];
	}
}

#pragma mark -
#pragma mark Add ActionSheet Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == kBlioLibraryAddNoteAction) {
        UIView *container = self.navigationController.visibleViewController.view;
        NSString *pageNumber = [self currentPageNumber];
        BlioNotesView *aNotesView = [[BlioNotesView alloc] initWithPage:pageNumber];
        [aNotesView showInView:container];
        [aNotesView release];
    }
}

@end
