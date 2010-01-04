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
#import <libEucalyptus/THEventCapturingWindow.h>
#import <libEucalyptus/EucBookTitleView.h>
#import <libEucalyptus/EucBookContentsTableViewController.h>
#import <libEucalyptus/EucEPubBook.h>
#import "BlioViewSettingsSheet.h"
#import "BlioNotesView.h"
#import "BlioEPubView.h"
#import "BlioLayoutView.h"

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

typedef enum {
    kBlioPageColorWhite = 0,
    kBlioPageColorBlack = 1,
    kBlioPageColorNeutral = 2,
} BlioPageColor;

typedef enum {
    kBlioRotationLockOff = 0,
    kBlioRotationLockOn = 1,
} BlioRotationLock;

typedef enum {
    kBlioTapTurnOff = 0,
    kBlioTapTurnOn = 1,
} BlioTapTurn;

static const CGFloat kBlioFontPointSizeArray[] = { 14.0f, 16.0f, 18.0f, 20.0f, 22.0f };

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
@end

@implementation BlioBookViewController

@synthesize book = _book;
@synthesize bookView = _bookView;

@synthesize returnToNavigationBarStyle = _returnToNavigationBarStyle;
@synthesize returnToStatusBarStyle = _returnToStatusBarStyle;
@synthesize returnToNavigationBarHidden = _returnToNavigationBarHidden;
@synthesize returnToStatusBarHidden = _returnToStatusBarHidden;
@synthesize audioPlaying = _audioPlaying;

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
    if ([newBook bookPath]) {
        EucEPubBook *aEPubBook = [[EucEPubBook alloc] initWithPath:[newBook bookPath]];
        BlioEPubView *aBookView = [[BlioEPubView alloc] initWithFrame:[[UIScreen mainScreen] bounds] book:aEPubBook];
        aBookView.appearAtCoverThenOpen = YES;
        if ((self = [self initWithBookView:aBookView])) {
            self.bookView = aBookView;
            self.book = newBook;
        }
        [aBookView release];
        [aEPubBook release];
    } else if ([newBook pdfPath]) {
        //Do nowt
    } else {
        self = nil;
    }
    return self;
}

- (id)initWithBookView:(UIView<BlioBookView> *)view
{
	if ((self = [super initWithNibName:nil bundle:nil])) {
        self.audioPlaying = NO;
        self.wantsFullScreenLayout = NO;

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
        
        UINavigationBar *navigationBar = self.navigationController.navigationBar;
        // Store the hidden/visible state and style of the status and navigation
        // bars so that we can restore them when popped.
        UIBarStyle navigationBarStyle = navigationBar.barStyle;
        UIStatusBarStyle statusBarStyle = application.statusBarStyle;
        BOOL navigationBarHidden = self.navigationController.isNavigationBarHidden;
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
        
        // Set the status bar and navigation bar styles.
        if(!(navigationBarStyle == UIBarStyleBlackTranslucent) && self.toolbarsVisibleAfterAppearance) {
            navigationBar.barStyle = UIBarStyleBlackTranslucent;
            self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
        }
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
            toolbar.barStyle = _returnToNavigationBarStyle;            
            
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
    [_bookView release];
    self.book = nil;
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
                        
            self.navigationController.navigationBar.alpha = 1;
        } else {
            [UIView setAnimationDuration:1.0/3.0];
            self.navigationController.toolbar.alpha = 0;
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
        } else if (newLayout == kBlioPageLayoutPageLayout && [self.book pdfPath]) {
            BlioLayoutView *layoutView = [[BlioLayoutView alloc] initWithPath:[self.book pdfPath]];
            bookViewController.bookView = layoutView;
            [layoutView release];
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
        }
        NSLog(@"Attempting to change to BlioFontSize: %d", newSize);
    }
}

- (BlioPageColor)currentPageColor {
    return kBlioPageColorWhite;
}

- (void)changePageColor:(id)sender {
    BlioPageColor newColor = (BlioPageColor)[sender selectedSegmentIndex];
    if([self currentPageColor] != newColor) {
        NSLog(@"Attempting to change to BlioPageColor: %d", newColor);
    }
}

- (BlioRotationLock)currentLockRotation {
    return kBlioRotationLockOff;
}

- (void)changeLockRotation:(id)sender {
    // This is just a placeholder check. Obviously we shouldn't be checking against the string.
    BlioRotationLock newLock = (BlioRotationLock)[[sender titleForSegmentAtIndex:[sender selectedSegmentIndex]] isEqualToString:@"Unlock Rotation"];
    if([self currentLockRotation] != newLock) {
        NSLog(@"Attempting to change to BlioRotationLock: %d", newLock);
    }
}

- (BlioTapTurn)currentTapTurn {
    return kBlioTapTurnOff;
}

- (void)changeTapTurn:(id)sender {
    // This is just a placeholder check. Obviously we shouldn't be checking against the string.
    BlioTapTurn newTapTurn = (BlioTapTurn)[[sender titleForSegmentAtIndex:[sender selectedSegmentIndex]] isEqualToString:@"Disable Tap Turn"];
    if([self currentTapTurn] != newTapTurn) {
        NSLog(@"Attempting to change to BlioTapTurn: %d", newTapTurn);
    }
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
    [self.navigationItem setRightBarButtonItem:nil animated:NO];
    
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