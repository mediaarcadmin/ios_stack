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
#import "BlioBookViewControllerProgressPieButton.h"
#import "BlioFlowView.h"
#import "BlioLayoutView.h"
#import "BlioSpeedReadView.h"
#import "BlioContentsTabViewController.h"
#import "BlioLightSettingsViewController.h"
#import "BlioBookmark.h"
#import "BlioAppSettingsConstants.h"

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

static const CGFloat kBlioFontPointSizeArray[] = { 14.0f, 16.0f, 18.0f, 20.0f, 22.0f };

static NSString *kBlioFontPageTextureNamesArray[] = { @"paper-white.png", @"paper-black.png", @"paper-neutral.png" };
static const BOOL kBlioFontPageTexturesAreDarkArray[] = { NO, YES, NO };

@interface BlioBookViewController ()
- (NSArray *)_toolbarItemsForReadingView;
- (void) _updatePageJumpLabelForPage:(NSInteger)page;
- (void) updatePageJumpPanelForPage:(NSInteger)pageNumber animated:(BOOL)animated;
- (void)displayNote:(NSManagedObject *)note atRange:(BlioBookmarkRange *)range animated:(BOOL)animated;
@end

@interface BlioBookSlider : UISlider {
    BOOL touchInProgress;
}

@property (nonatomic) BOOL touchInProgress;

@end


@implementation BlioBookViewController

@synthesize book = _book;
@synthesize bookView = _bookView;
@synthesize pageJumpView = _pageJumpView;
@synthesize pieButton = _pieButton;

@synthesize returnToNavigationBarStyle = _returnToNavigationBarStyle;
@synthesize returnToStatusBarStyle = _returnToStatusBarStyle;
@synthesize returnToNavigationBarHidden = _returnToNavigationBarHidden;
@synthesize returnToStatusBarHidden = _returnToStatusBarHidden;

@synthesize currentPageColor = _currentPageColor;

@synthesize audioPlaying = _audioPlaying;
@synthesize managedObjectContext = _managedObjectContext;

@synthesize tiltScroller, tapDetector, motionControlsEnabled;
@synthesize rotationLocked;

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
    if ((self = [super initWithNibName:nil bundle:nil])) {
        self.book = newBook;

        self.audioPlaying = NO;
        self.wantsFullScreenLayout = YES;
		if (![self.book audioRights]) {
			_acapelaTTS = *[BlioBookViewController getTTSEngine];
			if ( _acapelaTTS != nil )  {
				[_acapelaTTS setPageChanged:YES];
				[_acapelaTTS setDelegate:self];
			} 
		}
        
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
        
        tiltScroller = [[MSTiltScroller alloc] init];
        tapDetector = [[MSTapDetector alloc] init];
        motionControlsEnabled = kBlioTapTurnOff;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tapToNextPage) name:@"TapToNextPage" object:nil];
        
        BlioPageLayout lastLayout = [[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastLayoutDefaultsKey];
        
        if (!([newBook ePubPath] || [newBook textFlowPath]) && (lastLayout == kBlioPageLayoutSpeedRead)) {
            lastLayout = kBlioPageLayoutPlainText;
        }            
        if (![newBook pdfPath] && (lastLayout == kBlioPageLayoutPageLayout)) {
            lastLayout = kBlioPageLayoutPlainText;
        } else if (![newBook ePubPath] && ![newBook textFlowPath] && (lastLayout == kBlioPageLayoutPlainText)) {
            lastLayout = kBlioPageLayoutPageLayout;
        } 
        
        switch (lastLayout) {
            case kBlioPageLayoutSpeedRead: {
                if ([newBook ePubPath] || [newBook textFlowPath]) {
                    BlioSpeedReadView *aBookView = [[BlioSpeedReadView alloc] initWithBook:newBook animated:YES];
                    self.bookView = aBookView; 
                    [aBookView release];
                } else {
                    [self release];
                    return nil;
                }          
            }
                break;
            case kBlioPageLayoutPageLayout: {
                if ([newBook pdfPath]) {
                    BlioLayoutView *aBookView = [[BlioLayoutView alloc] initWithBook:newBook animated:YES];
                    self.bookView = aBookView;
                    [aBookView setDelegate:self];
                    [aBookView release];
                } else {
                    [self release];
                    return nil;
                }
            }
                break;
            default: {
                if ([newBook ePubPath] || [newBook textFlowPath]) {
                    BlioFlowView *aBookView = [[BlioFlowView alloc] initWithBook:newBook animated:YES];
                    self.bookView = aBookView;
                    self.currentPageColor = [[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastPageColorDefaultsKey];
                    [aBookView release];
                } else {
                    [self release];
                    return nil;
                }
            } 
                break;
        }
		
		if ([self.book audiobookFilename] != nil) 
			// We need to do this here instead of lazily when the play button is pushed because it takes too long.
			_audioBookManager = [[BlioAudioBookManager alloc] initWithPath:[self.book timingIndicesPath] metadataPath:[self.book audiobookPath]];        
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
    [item setAccessibilityLabel:NSLocalizedString(@"Contents", @"Accessibility label for Book View Controller Contents button")];
    [item setAccessibilityHint:NSLocalizedString(@"Shows table of contents, bookmarks and notes.", @"Accessibility label for Book View Controller Contents hint")];

    [readingItems addObject:item];
    [item release];
    
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
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];  
    
    item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-search.png"]
                                            style:UIBarButtonItemStylePlain
                                           target:self 
                                           action:@selector(dummyShowParsedText:)];
    [item setAccessibilityLabel:NSLocalizedString(@"Search", @"Accessibility label for Book View Controller Search button")];

    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];  
    
    UIImage *audioImage = nil;
    if (self.audioPlaying) {
        audioImage = [UIImage imageNamed:@"icon-pause.png"];
    } else {
        audioImage = [UIImage imageNamed:@"icon-play.png"];
    }
    
    item = [[UIBarButtonItem alloc] initWithImage:audioImage
                                            style:UIBarButtonItemStylePlain
                                           target:self 
                                           action:@selector(toggleAudio:)];
    
    if (self.audioPlaying) {
        [item setAccessibilityLabel:NSLocalizedString(@"Pause", @"Accessibility label for Book View Controller Pause button")];
        [item setAccessibilityHint:NSLocalizedString(@"Pauses audio playback.", @"Accessibility label for Book View Controller Pause hint")];
        
    } else {
        [item setAccessibilityLabel:NSLocalizedString(@"Play", @"Accessibility label for Book View Controller Play button")];
        [item setAccessibilityHint:NSLocalizedString(@"Starts audio playback.", @"Accessibility label for Book View Controller Play hint")];
        [item setAccessibilityTraits:UIAccessibilityTraitButton | UIAccessibilityTraitPlaysSound];
        
    }

    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-eye.png"]
                                            style:UIBarButtonItemStylePlain
                                           target:self 
                                           action:@selector(showViewSettings:)];
    
    [item setAccessibilityLabel:NSLocalizedString(@"Settings", @"Accessibility label for Book View Controller Settings button")];

    [readingItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [readingItems addObject:item];
    [item release];
    
    return [NSArray arrayWithArray:readingItems];
}

- (void)setBookView:(UIView<BlioBookView> *)bookView
{
    if(_bookView)
        [self removeObserver:_bookView forKeyPath:@"audioPath"];
        
    if(_bookView != bookView) {
        if(_bookView) {
            [_bookView removeObserver:self forKeyPath:@"pageNumber"];
            [_bookView removeObserver:self forKeyPath:@"pageCount"];        
            if(_bookView.superview) {
                if ([_bookView wantsTouchesSniffed]) {
                    THEventCapturingWindow *window = (THEventCapturingWindow *)_bookView.window;
                    [window removeTouchObserver:self forView:_bookView];
                }
                [_bookView removeFromSuperview];
            }
        }
        
        [_bookView release];
        
        // Could do this here to get rid of e.g. paragraph sources if they're 
        // not needed - causes a bit of a stall though.
        //[self.book flushCaches];
        
        _bookView = [bookView retain];
        
        if(_bookView) {
            if(self.isViewLoaded) {
                EucBookTitleView *titleView = (EucBookTitleView *)self.navigationItem.titleView;
                [titleView setTitle:[self.book title]];
                [titleView setAuthor:[self.book author]];              
                
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
            
            if (nil != _bookView)
                [self addObserver:_bookView forKeyPath:@"audioPath" options:0 context:nil];
        }
    }
}

- (void)_backButtonTapped
{
	if (self.audioPlaying) {
		[self stopAudio];
		self.audioPlaying = NO;  
	}
    _viewIsDisappearing = YES;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)updatePieButtonForPage:(NSInteger)pageNumber animated:(BOOL)animated {
    [self.pieButton setProgress:pageNumber/(CGFloat)self.bookView.pageCount];
}


- (void)updatePieButtonAnimated:(BOOL)animated {
    [self updatePieButtonForPage:self.bookView.pageNumber animated:animated];
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
    
    if(!self.toolbarsVisibleAfterAppearance) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    }    
}

- (void)layoutNavigationToolbar {
    CGRect navFrame = self.navigationController.navigationBar.frame;
    navFrame.origin.y = 20;
    [self.navigationController.navigationBar setFrame:navFrame];
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
    [backArrow setAccessibilityLabel:NSLocalizedString(@"Back", @"Accessibility label for Book View Controller Back button")];

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
        [titleView setAuthor:[self.book author]];
        
        [self setNavigationBarButtons];
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
            if(!animated) {
                CGRect frame = self.navigationController.toolbar.frame;
                frame.origin.y += frame.size.height;
                self.navigationController.toolbar.frame = frame;
                [UIView beginAnimations:@"PullInToolbarAnimations" context:NULL];
                frame.origin.y -= frame.size.height;
                self.navigationController.toolbar.frame = frame;
                [UIView commitAnimations];                
            }                    
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
    if(_viewIsDisappearing) {
        //        if(_contentsSheet) {
        //            [self performSelector:@selector(dismissContents)];
        //        }
        if(_bookView) {
            // Need to do this now before the view is removed and doesn't have a window.
            if ([_bookView wantsTouchesSniffed]) {
                [(THEventCapturingWindow *)_bookView.window removeTouchObserver:self forView:_bookView];
            }
            
            if([_bookView respondsToSelector:@selector(stopAnimation)]) {
                [_bookView performSelector:@selector(stopAnimation)];
            }
            
            if([_bookView isKindOfClass:[BlioSpeedReadView class]]) {
                // We do this because the current point is usually only saved on a 
                // page switch, so we want to make sure the current point that the 
                // user has reached in SpeedRead view is saved..
                // Usually, the SpeedRead "Page" tracks the layout page that the 
                // current SpeedRead paragraph starts on.
                self.book.implicitBookmarkPoint = self.bookView.currentBookmarkPoint;
            } 
            
            // Save the current progress, for UI display purposes.
            float bookProgress = (float)(_bookView.pageNumber - 1) / (float)(_bookView.pageCount);
            self.book.progress = [NSNumber numberWithFloat:bookProgress];
            
            [self.navigationController setToolbarHidden:YES animated:NO];
            [self.navigationController setToolbarHidden:NO animated:NO];
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
                [application setStatusBarHidden:_returnToStatusBarHidden 
                                       animated:YES];
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
                NSLog(@"Save failed with error: %@, %@", error, [error userInfo]);            
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
    [self.book flushCaches];
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
}


- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIAccelerometer sharedAccelerometer] setUpdateInterval:0];
    [[UIAccelerometer sharedAccelerometer] setDelegate:nil];
	if (_pageJumpButton) [_pageJumpButton release];
    [tapDetector release];
    [tiltScroller release];
    
    self.bookView = nil;
    
    [self.book flushCaches];
    self.book = nil;    
    
    self.pageJumpView = nil;
    self.pieButton = nil;
    self.managedObjectContext = nil;
    
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

- (void)showToolbars
{
    if(self.navigationController.toolbarHidden)
        [self toggleToolbars];
}

- (BOOL)toolbarsVisible {
    return (self.navigationController.toolbarHidden == NO);
}

- (void)toggleToolbarsAndStatusBar:(BOOL)toggleStatusBar
{
    if(_fadeState == BookViewControlleUIFadeStateNone) {
        if(self.navigationController.toolbarHidden == YES) {
            if (toggleStatusBar) {
                [[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO]; 
                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:NO];
            }
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
        if (toggleStatusBar)
            [UIView setAnimationWillStartSelector:@selector(_fadeWillStart)];
        
        [UIView commitAnimations];   
        
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
        if([self.bookView respondsToSelector:@selector(setNeedsAccessibilityElementsRebuild)]) {
            [self.bookView performSelector:@selector(setNeedsAccessibilityElementsRebuild)];
        }
    }
}

- (void)toggleToolbars
{
    [self toggleToolbarsAndStatusBar:YES];
}

- (void)hideToolbarsAndStatusBar:(BOOL)hidesStatusBar
{
    if(!self.navigationController.toolbarHidden)
        [self toggleToolbarsAndStatusBar:hidesStatusBar];
}

- (void)hideToolbars {
    [self hideToolbarsAndStatusBar:YES];
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
            if(!self.navigationController.toolbarHidden) {
                [self toggleToolbars];
            }
        } else if(phase == UITouchPhaseEnded) {
            if(!_touchMoved) {
                if(!self.navigationController.toolbarHidden ||
                   ![self.bookView respondsToSelector:@selector(toolbarShowShouldBeSuppressed)] ||
                   ![self.bookView toolbarShowShouldBeSuppressed]) {
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
    CGRect sliderBounds = [_pageJumpSlider bounds];
    sliderBounds.size.width = CGRectGetWidth(_pageJumpView.bounds) - 8;
    [_pageJumpSlider setBounds:sliderBounds];
    
    CGFloat scale = 1;
    
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
        scale = 0.75f;
    
    _pageJumpSlider.transform = CGAffineTransformMakeScale(scale, scale);
    _pageJumpSlider.center = CGPointMake(_pageJumpView.center.x, CGRectGetHeight(_pageJumpView.frame) - ((CGRectGetHeight(sliderBounds) / 2.0f) * scale));

}

- (void)layoutPageJumpLabelText {
    
    NSInteger fontSize = 14;
    CGSize constrainedSize = CGSizeMake(_pageJumpView.bounds.size.width, floorf(_pageJumpView.bounds.size.height / 2.0f) - 2);
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
    labelFrame.size.height = stringSize.height;
    labelFrame.origin = CGPointMake(0, 4);
    [_pageJumpLabel setFrame:labelFrame];
    [_pageJumpLabel setFont:[UIFont boldSystemFontOfSize:fontSize]];
}

- (void) togglePageJumpPanel { 
    
    if(!_pageJumpView) {
        self.pageJumpView = [[UIView alloc] init];
        [self.pageJumpView release];
        
        _pageJumpView.hidden = YES;
        [self layoutPageJumpView];
        _pageJumpView.opaque = NO;
        _pageJumpView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
        _pageJumpView.autoresizesSubviews = YES;
            
        // feedback label
        _pageJumpLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _pageJumpLabel.textAlignment = UITextAlignmentCenter;
        _pageJumpLabel.adjustsFontSizeToFitWidth = YES;
        _pageJumpLabel.minimumFontSize = 6;
        _pageJumpLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        _pageJumpLabel.shadowOffset = CGSizeMake(0, -1);
        
        _pageJumpLabel.backgroundColor = [UIColor clearColor];
        _pageJumpLabel.textColor = [UIColor whiteColor];
        _pageJumpLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
        
        [self layoutPageJumpLabelText];
        [_pageJumpView addSubview:_pageJumpLabel];
        
        CGRect sliderFrame = _pageJumpView.bounds;
        sliderFrame.origin.y = _pageJumpLabel.bounds.size.height + 2;
        sliderFrame.origin.x = floorf(_pageJumpLabel.bounds.size.height / 10.0f);
        sliderFrame.size.height = _pageJumpLabel.bounds.size.height;
        sliderFrame.size.width -= 8;
        
        // the slider
        BlioBookSlider* slider = [[BlioBookSlider alloc] initWithFrame: sliderFrame];
        slider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [slider setAccessibilityLabel:NSLocalizedString(@"Progress", @"Accessibility label for Book View Controller Progress slider")];
        [slider setAccessibilityHint:NSLocalizedString(@"Jumps to new position in book.", @"Accessibility hint for Book View Controller Progress slider")];

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
    [self.bookView goToPageNumber:[pageNumber integerValue] animated:YES];
}

- (void) _updatePageJumpLabelForPage:(NSInteger)page
{
    _pageJumpLabel.text = [self.bookView pageLabelForPageNumber:page];
    [_pageJumpSlider setAccessibilityValue:_pageJumpLabel.text];
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
    if ([self.bookView isKindOfClass:[BlioFlowView class]]) {
        int currentPage = [self.bookView pageNumber] + 1;
        if (currentPage >= [self.bookView pageCount]) currentPage = [self.bookView pageCount];

        [self.bookView goToPageNumber:currentPage animated:YES];
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
		if (self.audioPlaying) {
			UIBarButtonItem *item = (UIBarButtonItem *)[self.toolbarItems objectAtIndex:7];
			[item setImage:[UIImage imageNamed:@"icon-play.png"]];
            [item setAccessibilityLabel:NSLocalizedString(@"Play", @"Accessibility label for Book View Controller Play button")];
            [item setAccessibilityHint:NSLocalizedString(@"Starts audio playback.", @"Accessibility label for Book View Controller Play hint")];
            [item setAccessibilityTraits:UIAccessibilityTraitButton | UIAccessibilityTraitPlaysSound];

            [self stopAudio];
			self.audioPlaying = NO;  
		}
        if (newLayout == kBlioPageLayoutPlainText && ([self.book ePubPath] || [self.book textFlowPath])) {
            BlioFlowView *ePubView = [[BlioFlowView alloc] initWithBook:self.book animated:NO];
            self.bookView = ePubView;
            self.currentPageColor = [[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastPageColorDefaultsKey];
            [ePubView release];
            [[NSUserDefaults standardUserDefaults] setInteger:kBlioPageLayoutPlainText forKey:kBlioLastLayoutDefaultsKey];    
        } else if (newLayout == kBlioPageLayoutPageLayout && [self.book pdfPath]) {
            BlioLayoutView *layoutView = [[BlioLayoutView alloc] initWithBook:self.book animated:NO];
            [layoutView setDelegate:self];
            self.bookView = layoutView;            
            [layoutView release];
            [[NSUserDefaults standardUserDefaults] setInteger:kBlioPageLayoutPageLayout forKey:kBlioLastLayoutDefaultsKey];    
        } else if (newLayout == kBlioPageLayoutSpeedRead && ([self.book ePubPath] || [self.book textFlowPath])) {
            BlioSpeedReadView *speedReadView = [[BlioSpeedReadView alloc] initWithBook:self.book animated:NO];
            self.bookView = speedReadView;     
            [speedReadView release];
            [[NSUserDefaults standardUserDefaults] setInteger:kBlioPageLayoutSpeedRead forKey:kBlioLastLayoutDefaultsKey];
        }
    }
}

- (BOOL)shouldShowPageAttributeSettings {
    //Dave changed this line to connect the settings buttons to tilt scrolling directions!
    //if ([self currentPageLayout] == kBlioPageLayoutPageLayout || [self currentPageLayout] == kBlioPageLayoutSpeedRead)
    if ([self currentPageLayout] == kBlioPageLayoutSpeedRead)    
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
    
    //Dave added this to control the tiltscrolling direction settings!
    if ([self currentPageLayout] == kBlioPageLayoutPageLayout) {
        switch ([sender selectedSegmentIndex]) {
            case 0:
                tiltScroller.directionModifierH = 1;
                tiltScroller.directionModifierV = 1;                
                break;
            case 1:
                tiltScroller.directionModifierH = -1;
                tiltScroller.directionModifierV = -1;                
                break;
            case 3:
                tiltScroller.directionModifierH = 1;
                tiltScroller.directionModifierV = -1;                
                break;
            case 4:
                tiltScroller.directionModifierH = -1;
                tiltScroller.directionModifierV = 1;                
                break;                
            default:
                break;
        }
        
    }
}

- (void)setCurrentPageColor:(BlioPageColor)newColor
{
    UIView<BlioBookView> *bookView = self.bookView;
    if([bookView respondsToSelector:(@selector(setPageTexture:isDark:))]) {
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:kBlioFontPageTextureNamesArray[newColor]
                                                              ofType:@""];
        UIImage *pageTexture = [UIImage imageWithData:[NSData dataWithContentsOfMappedFile:imagePath]];
        [bookView setPageTexture:pageTexture isDark:kBlioFontPageTexturesAreDarkArray[newColor]];
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

- (BlioTapTurn)currentTapTurn {
    return motionControlsEnabled;

}

- (void)changeTapTurn {
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
#pragma mark KVO Callback

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSParameterAssert([NSThread isMainThread]);
    
    if ([keyPath isEqual:@"pageNumber"]) {
        [self updatePageJumpPanelAnimated:YES];
        [self updatePieButtonAnimated:YES];
        		
		if ( _acapelaTTS != nil )
			[_acapelaTTS setPageChanged:YES];  
		if ( _audioBookManager != nil )
			[_audioBookManager setPageChanged:YES];
		
        if(_lastSavedPageNumber != self.bookView.pageNumber) {
            self.book.implicitBookmarkPoint = self.bookView.currentBookmarkPoint;
            
            NSError *error;
            if (![[self.book managedObjectContext] save:&error])
                NSLog(@"Save failed with error: %@, %@", error, [error userInfo]);            
        }
    }
    
    if ([keyPath isEqual:@"pageCount"]) {
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
    
    BlioContentsTabViewController *aContentsTabView = [[BlioContentsTabViewController alloc] initWithBookView:self.bookView book:self.book];
    aContentsTabView.delegate = self;
    [self presentModalViewController:aContentsTabView animated:YES];
    [aContentsTabView release];    
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
    // Hide toolbars so the view settings don't overlap them
    [self setToolbarsForModalOverlayActive:YES];
    
    BlioViewSettingsSheet *aSettingsSheet = [[BlioViewSettingsSheet alloc] initWithDelegate:self];
    UIToolbar *toolbar = self.navigationController.toolbar;
    [aSettingsSheet showFromToolbar:toolbar];
    [aSettingsSheet release];
}

- (void)dismissViewSettings:(id)sender {
    [(BlioViewSettingsSheet *)sender dismissWithClickedButtonIndex:0 animated:YES];
    
    [self setToolbarsForModalOverlayActive:NO];
}


#pragma mark -
#pragma mark TTS Handling 

- (void)speakNextBlock:(NSTimer*)timer {
	if ( _acapelaTTS.textToSpeakChanged ) {	
		[_acapelaTTS setTextToSpeakChanged:NO];
		[_acapelaTTS startSpeakingWords:_acapelaTTS.blockWords];
	}
}

- (void) getNextBlockForAudioManager:(BlioAudioManager*)audioMgr {
    id<BlioParagraphSource> paragraphSource = self.book.paragraphSource;
	do {
		audioMgr.currentBlock = [paragraphSource nextParagraphIdForParagraphWithID:audioMgr.currentBlock];
		[audioMgr setCurrentWordOffset:0];
		[audioMgr setBlockWords:[paragraphSource wordsForParagraphWithID:audioMgr.currentBlock]];
		if ( audioMgr.blockWords == nil ) {
			// end of the book
			UIBarButtonItem *item = (UIBarButtonItem *)[self.toolbarItems objectAtIndex:7];
			[item setImage:[UIImage imageNamed:@"icon-play.png"]];
            [item setAccessibilityLabel:NSLocalizedString(@"Play", @"Accessibility label for Book View Controller Play button")];
            [item setAccessibilityHint:NSLocalizedString(@"Starts audio playback.", @"Accessibility label for Book View Controller Play hint")];
            [item setAccessibilityTraits:UIAccessibilityTraitButton | UIAccessibilityTraitPlaysSound];

			[self stopAudio];
			self.audioPlaying = NO;
            break;
		}
    } while ( [audioMgr.blockWords count] == 0 ); // Loop in case the block's empty.
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
	[audioMgr setStartedPlaying:YES];
	[audioMgr setTextToSpeakChanged:YES];
}

- (BOOL)loadAudioFiles:(NSInteger)layoutPage segmentIndex:(NSInteger)segmentIx {
	NSMutableArray* segmentInfo;
	// Subtract 1 for now from page to match Blio layout page. Can't we have them match?
	if ( !(segmentInfo = [(NSMutableArray*)[_audioBookManager.pagesDict objectForKey:[NSString stringWithFormat:@"%d",layoutPage-1]] objectAtIndex:segmentIx]) )
		return NO;
	NSString* audiobooksPath = [self.book.bookCacheDirectory stringByAppendingPathComponent:@"Audiobook"];
	// For testing
	//NSString* audiobooksPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/AudioBooks/Graveyard Book/"];
	NSString* timingPath = [audiobooksPath stringByAppendingPathComponent:[_audioBookManager.timeFiles objectAtIndex:[[segmentInfo objectAtIndex:kAudioRefIndex] intValue]]];
	if ( ![_audioBookManager loadWordTimesFromFile:timingPath] )  {
		NSLog(@"Timing file could not be initialized.");
		return NO;
	}
	NSString* audioPath = [audiobooksPath stringByAppendingPathComponent:[_audioBookManager.audioFiles objectAtIndex:[[segmentInfo objectAtIndex:kAudioRefIndex] intValue]]];
	if ( ![_audioBookManager initAudioWithBook:audioPath] ) {
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

// Singleton pattern
+ (AcapelaTTS**)getTTSEngine {
	static AcapelaTTS* ttsEngine = nil; // can't initialize here unfortunately
	return &ttsEngine;
}

#pragma mark -
#pragma mark Acapela Delegate Methods 

- (void)speechSynthesizer:(AcapelaSpeech*)synth didFinishSpeaking:(BOOL)finishedSpeaking
{
	if (finishedSpeaking) {
		// Reached end of block.  Start on the next.
		[self prepareTextToSpeakWithAudioManager:_acapelaTTS continuingSpeech:YES]; 
	}
	//else stop button pushed before end of block.
}

- (void)speechSynthesizer:(AcapelaSpeech*)sender willSpeakWord:(NSRange)characterRange 
				 ofString:(NSString*)string 
{
    if(characterRange.location + characterRange.length <= string.length) {
        NSUInteger wordOffset = [_acapelaTTS wordOffsetForCharacterRange:characterRange];
        
        id<BlioBookView> bookView = self.bookView;
        if([bookView respondsToSelector:@selector(highlightWordAtBookmarkPoint:)]) {
            BlioBookmarkPoint *point = [self.book.paragraphSource bookmarkPointFromParagraphID:_acapelaTTS.currentBlock
                                                                                   wordOffset:wordOffset];
            [bookView highlightWordAtBookmarkPoint:point];
        }
        [_acapelaTTS setCurrentWordOffset:wordOffset];
    }
}

#pragma mark -
#pragma mark AVAudioPlayer Delegate Methods 

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag { 
	if (!flag) {
		UIBarButtonItem *item = (UIBarButtonItem *)[self.toolbarItems objectAtIndex:7];
		[item setImage:[UIImage imageNamed:@"icon-play.png"]];
        [item setAccessibilityLabel:NSLocalizedString(@"Play", @"Accessibility label for Book View Controller Play button")];
        [item setAccessibilityHint:NSLocalizedString(@"Starts audio playback.", @"Accessibility label for Book View Controller Play hint")];
        [item setAccessibilityTraits:UIAccessibilityTraitButton | UIAccessibilityTraitPlaysSound];

		self.audioPlaying = NO;
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
				[self.bookView goToPageNumber:i animated:YES];
				break;
			}
		}
		if ( !loadedFilesAhead ) {
			// End of book.
			UIBarButtonItem *item = (UIBarButtonItem *)[self.toolbarItems objectAtIndex:7];
			[item setImage:[UIImage imageNamed:@"icon-play.png"]];
            [item setAccessibilityLabel:NSLocalizedString(@"Play", @"Accessibility label for Book View Controller Play button")];
            [item setAccessibilityHint:NSLocalizedString(@"Starts audio playback.", @"Accessibility label for Book View Controller Play hint")];
            [item setAccessibilityTraits:UIAccessibilityTraitButton | UIAccessibilityTraitPlaysSound];

			self.audioPlaying = NO;
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
		if (![self.book audioRights]) 
			[_acapelaTTS stopSpeaking];
		else if ([self.book audiobookFilename] != nil) 
			[_audioBookManager stopAudio];
}

- (void)pauseAudio {			
	if (![self.book audioRights]) {
		[_acapelaTTS pauseSpeaking];
		[_acapelaTTS setPageChanged:NO]; // In case speaking continued through a page turn.
	}
	else if ([self.book audiobookFilename] != nil) {
		[_audioBookManager pauseAudio];
		[_audioBookManager setPageChanged:NO];
	}
}

- (void)prepareTTSEngine {
	if (*[BlioBookViewController getTTSEngine] == nil) {
		*[BlioBookViewController getTTSEngine] = [[AcapelaTTS alloc] init];
		[*[BlioBookViewController getTTSEngine] setEngineWithPreferences:YES];  
		_acapelaTTS = *[BlioBookViewController getTTSEngine]; 
		[_acapelaTTS setDelegate:self];
	}
	else
		[*[BlioBookViewController getTTSEngine] setEngineWithPreferences:[*[BlioBookViewController getTTSEngine] voiceHasChanged]]; 
}

- (void)toggleAudio:(id)sender {
    UIBarButtonItem *item = (UIBarButtonItem *)sender;
    UIImage *audioImage = nil;
    if (self.audioPlaying) {
        [self pauseAudio];  // For tts, try again with stopSpeakingAtBoundary when next RC comes.
        audioImage = [UIImage imageNamed:@"icon-play.png"];
        [item setAccessibilityLabel:NSLocalizedString(@"Play", @"Accessibility label for Book View Controller Play button")];
        [item setAccessibilityHint:NSLocalizedString(@"Starts audio playback.", @"Accessibility label for Book View Controller Play hint")];
        [item setAccessibilityTraits:UIAccessibilityTraitButton | UIAccessibilityTraitPlaysSound];
    } else { 
        if (!self.navigationController.toolbarHidden) {
            [self toggleToolbars];
        }
        if (![self.book audioRights]) {
            [self prepareTTSEngine];
            [_acapelaTTS setSpeakingTimer:[NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(speakNextBlock:) userInfo:nil repeats:YES]];				
            [self prepareTextToSpeakWithAudioManager:_acapelaTTS continuingSpeech:NO];
        }
        else if ([self.book audiobookFilename] != nil) {
            if ( _audioBookManager.startedPlaying == NO || _audioBookManager.pageChanged) { 
                // So far this only would work for fixed view.
                //if ( ![self findTimes:[self.bookView.currentBookmarkPoint layoutPage]] < 0 ) 
                if ( ![self loadAudioFiles:[self.bookView.currentBookmarkPoint layoutPage] segmentIndex:0] ) {
                    // No audio files for this page.
                    // Look for next page with files.
                    BOOL loadedFilesAhead = NO;
                    for ( int i=[self.bookView.currentBookmarkPoint layoutPage]+1;;++i ) {
                        if ( [self loadAudioFiles:i segmentIndex:0] ) {
                            loadedFilesAhead = YES;
                            [self.bookView goToPageNumber:i animated:YES];
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
        }
        else {
            UIAlertView *errorAlert = [[UIAlertView alloc] 
                                       initWithTitle:@"" message:@"No audio is permitted for this book." // TODO: try Voiceover; how to word?
                                       delegate:self cancelButtonTitle:nil
                                       otherButtonTitles:@"OK", nil];
            [errorAlert show];
            [errorAlert release];
        }
        audioImage = [UIImage imageNamed:@"icon-pause.png"];
        [item setAccessibilityLabel:NSLocalizedString(@"Pause", @"Accessibility label for Book View Controller Pause button")];
        [item setAccessibilityHint:NSLocalizedString(@"Pauses audio playback.", @"Accessibility label for Book View Controller Pause hint")];
    }
    self.audioPlaying = !self.audioPlaying;  
    [item setImage:audioImage];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[alertView release];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[self.view viewWithTag:ACTIVITY_INDICATOR];
	[activityIndicator stopAnimating];
	NSString* errorMsg = [error localizedDescription];
	NSLog(@"Error loading web page: %@",errorMsg);
	UIAlertView *errorAlert = [[UIAlertView alloc] 
							   initWithTitle:@"" message:errorMsg 
							   delegate:self cancelButtonTitle:nil
							   otherButtonTitles:@"OK", nil];
	[errorAlert show];
}


- (void)dummyShowParsedText:(id)sender {
    if ([self.bookView isKindOfClass:[BlioLayoutView class]]) {
        UITextView *aTextView = [[UITextView alloc] initWithFrame:self.view.bounds];
        [aTextView setEditable:NO];
        [aTextView setContentInset:UIEdgeInsetsMake(10, 0, 10, 0)];
        NSInteger pageIndex = self.bookView.pageNumber - 1;
        [aTextView setText:[[self.book textFlow] stringForPageAtIndex:pageIndex]];
        [aTextView setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
        UIViewController *aVC = [[UIViewController alloc] init];
        aVC.view = aTextView;
        [aTextView release];
        UINavigationController *aNC = [[UINavigationController alloc] initWithRootViewController:aVC];
        [self presentModalViewController:aNC animated:YES];
        aVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done",@"\"Done\" bar button") style:UIBarButtonItemStyleDone target:self action:@selector(dummyDismissParsedText:)];                                                 
        aVC.navigationItem.title = [NSString stringWithFormat:@"Page %d Text", self.bookView.pageNumber];
        aNC.navigationBar.tintColor = _returnToNavigationBarTint;
        [aVC release];
        [aNC release];
    } else {
        BlioLightSettingsViewController *controller = [[BlioLightSettingsViewController alloc] initWithNibName:@"Lighting"
                                                                                                        bundle:[NSBundle mainBundle]];
        controller.pageTurningView = [(BlioFlowView *)self.bookView pageTurningView];
        [self.navigationController presentModalViewController:controller animated:YES];
        [controller release];
    }
}
                                                  
- (void)dummyDismissParsedText:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
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
        if (nil != existingBookmark) return;
        
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
            NSLog(@"Save failed with error: %@, %@", error, [error userInfo]);
        
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
        NSLog(@"Save failed with error: %@, %@", error, [error userInfo]);
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
            NSLog(@"Save failed with error: %@, %@", error, [error userInfo]);
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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if ([self.bookView respondsToSelector:@selector(willRotateToInterfaceOrientation:duration:)])
        [self.bookView willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self layoutNavigationToolbar];
    [self setNavigationBarButtons];
    if (_pageJumpView) {
        [self layoutPageJumpView];
        [self layoutPageJumpLabelText];
        [self layoutPageJumpSlider];
    }
    
    if ([self.bookView respondsToSelector:@selector(didRotateFromInterfaceOrientation:)])
        [self.bookView didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

#pragma mark -
#pragma mark BlioContentsTabViewControllerDelegate

- (void)dismissContentsTabView:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)displayNote:(NSManagedObject *)note atRange:(BlioBookmarkRange *)range animated:(BOOL)animated {
    //if (_pageJumpView && ![_pageJumpView isHidden]) [self performSelector:@selector(togglePageJumpPanel)];
    [self setToolbarsForModalOverlayActive:YES];
    //UIView *container = self.navigationController.visibleViewController.view;
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
    
    if ([self.bookView respondsToSelector:@selector(pageNumberForBookmarkRange:)]) {
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
        NSLog(@"Save failed with error: %@, %@", error, [error userInfo]);
}

- (void)deleteBookmark:(NSManagedObject *)bookmark {
    NSMutableSet *bookmarks = [self.book mutableSetValueForKey:@"bookmarks"];
    [bookmarks removeObject:bookmark];
    [[self managedObjectContext] deleteObject:bookmark];
    
    NSError *error;
    if (![[self managedObjectContext] save:&error])
        NSLog(@"Save failed with error: %@, %@", error, [error userInfo]);
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
	NSArray *wordStrings = [self.book wordStringsForBookmarkRange:range];
    NSString *encodedParam = [[wordStrings componentsJoinedByString:@" "] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
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
            NSLog(@"Save failed with error: %@, %@", error, [error userInfo]);
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

@synthesize touchInProgress;

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

@end
