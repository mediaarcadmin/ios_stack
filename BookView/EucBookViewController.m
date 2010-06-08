//
//  BookViewController.m
//  libEucalyptus
//
//  Created by James Montgomerie on 09/05/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "EucBookViewController.h"
#import "EucBookView.h"
#import "EucPageLayoutController.h"
#import "EucBookReference.h"
#import "THNavigationButton.h"
#import "THLog.h"
#import "THTimer.h"
#import "THUIViewAdditions.h"
#import "THUIImageAdditions.h"
#import "THPair.h"
#import "THRegex.h"
#import "THAlertViewWithUserInfo.h"
#import "THScalableSlider.h"
#import "EucBookTitleView.h"
#import "EucBook.h"
#import "EucBookView.h"
#import "EucBookReference.h"
#import "EucPageTextView.h"
#import "EucBookPageIndexPoint.h"
#import "EucPageView.h"
#import "EucBookContentsTableViewController.h"
#import "THRoundRectView.h"
#import "THCopyWithCoder.h"
#import "EucChapterNameFormatting.h"
#import "THGeometryUtils.h"
#import "THEventCapturingWindow.h"

#define NON_TEXT_PAGE_FAKE_BYTE_COUNT (30 * 20)


@interface EucBookViewController (PRIVATE)
- (void)_toggleToolbars;
- (void)_setupContentsButton;
@end

@implementation EucBookViewController

@synthesize delegate = _delegate;
@synthesize toolbarsVisibleAfterAppearance = _toolbarsVisibleAfterAppearance;
@synthesize overriddenToolbar = _overriddenToolbar;
@synthesize bookView = _bookView;

@synthesize returnToNavigationBarStyle = _returnToNavigationBarStyle;
@synthesize returnToNavigationBarTranslucent = _returnToNavigationBarTranslucent;
@synthesize returnToStatusBarStyle = _returnToStatusBarStyle;
@synthesize returnToNavigationBarHidden = _returnToNavigationBarHidden;
@synthesize returnToStatusBarHidden = _returnToStatusBarHidden;

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

- (id)initWithBookView:(EucBookView *)view
{
	if ((self = [super initWithNibName:nil bundle:nil])) {
        self.wantsFullScreenLayout = YES;
        self.hidesBottomBarWhenPushed = YES;

        UIButton *backArrow = [THNavigationButton leftNavigationButtonWithArrowInBarStyle:UIBarStyleBlackTranslucent];
        [backArrow setAccessibilityLabel:NSLocalizedString(@"Library", @"Back to library button accessibility label")];
        [backArrow addTarget:self
                      action:@selector(_backButtonTapped) 
            forControlEvents:UIControlEventTouchUpInside];
        backArrow.autoresizingMask = UIViewAutoresizingFlexibleHeight;

        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backArrow];
        self.navigationItem.leftBarButtonItem = backItem;
        [backItem release];
        
        [self _setupContentsButton];
        
        EucBookTitleView *titleView = [[EucBookTitleView alloc] init];
        CGRect frame = titleView.frame;
        frame.size.width = [[UIScreen mainScreen] bounds].size.width;
        [titleView setFrame:frame];
        titleView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        self.navigationItem.titleView = titleView;
        [titleView release];
                
        _firstAppearance = YES;
        
        _bookView = [view retain];
        _bookView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
	return self;
}

- (id)initWithBook:(EucBookReference<EucBook> *)book
{
    EucBookView *bookView = [[EucBookView alloc] initWithFrame:[[UIApplication sharedApplication] keyWindow].bounds book:book];
    bookView.delegate = self;
    bookView.allowsSelection = YES;
    
    self = [self initWithBookView:bookView];
    
    
    [bookView release];
    return self;
}


- (void)_backButtonTapped
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)_bugButtonTapped
{
    //_pageSlider.maximumAvailable += floorf(_bookIndex.lastPageNumber * 0.1f);
   /* FeedbackViewController *feedbackSheet = [[FeedbackViewController alloc] initWithNibName:@"FeedbackView" bundle:[NSBundle mainBundle]]; 
    if(feedbackSheet) {
        feedbackSheet.bookViewController = self;
        [self presentModalViewController:feedbackSheet animated:YES];
        [feedbackSheet release];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    }*/
    /*
    for(UIView *view in _toolbar.subviews) {
        UIGraphicsBeginImageContext(view.bounds.size);
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
        NSData *png = UIImagePNGRepresentation(UIGraphicsGetImageFromCurrentImageContext());
        [png writeToFile:[NSString stringWithFormat:@"/tmp/%p.png", png] atomically:NO];
    }
    */
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == actionSheet.destructiveButtonIndex) {
       // _bookWasDeleted = [[Library sharedLibrary] deleteBookForNumber:_book.etextNumber];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == actionSheet.destructiveButtonIndex) {
        //if(_bookWasDeleted) {
            //[((EucalyptusAppDelegate *)[UIApplication sharedApplication].delegate) switchToOrganisationViewFromBookView];
        //}
    }
}
/*
- (void)_trashButtonTapped
{
    NSString *warning = nil;
    if(_bookView.pageNumber > 1) {
        warning = NSLocalizedString(@"If you re-download this book after deleting it,\nit will open at the beginning again.", @"Warning displayed in delete confirmation sheet");
    }
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:warning
                                                             delegate:self 
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", @"'Cancel' button in book deletion confirmation sheet") 
                                               destructiveButtonTitle:NSLocalizedString(@"Delete Book", @"'Delete' button in book deletion confirmation sheet")
                                                    otherButtonTitles:nil];
    [actionSheet showFromToolbar:_toolbar];
    [actionSheet release];
}
*/

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
    
    // Move the page turning view back.
    UIWindow *window = _bookView.window;
    CGRect newFrame = [window convertRect:_bookView.frame toView:self.view];
    [self.view addSubview:_bookView];
    _bookView.frame = newFrame;
    [self.view sendSubviewToBack:_bookView];            
    
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    
    if(newSectionUuid) {
        [((EucBookView *)_bookView) goToUuid:newSectionUuid animated:YES];
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

- (void)_contentsButtonTapped
{
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    if(!_contentsSheet && [_bookView isKindOfClass:[EucBookView class]]) {
        // Move the page turning view to the main window so that it doesn't
        // automatically get shifted down when the oolbar turns opaque.
        UIWindow *window = _bookView.window;
        CGRect newFrame = [_bookView.superview convertRect:_bookView.frame toView:window];
        [window addSubview:_bookView];
        _bookView.frame = newFrame;
        [window sendSubviewToBack:_bookView];
        
        _contentsSheet = [[EucBookContentsTableViewController alloc] init];
        _contentsSheet.dataSource = ((EucBookView *)_bookView).contentsDataSource;
        _contentsSheet.delegate = self;        
        _contentsSheet.currentSectionUuid = [((EucBookView *)_bookView).contentsDataSource sectionUuidForPageNumber:((EucBookView *)_bookView).pageNumber];
        
        UIView *sheetView = _contentsSheet.view;
        
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
        [[sheetView layer] addAnimation:animation forKey:@"ContentSlideIn"];
        
        [window addSubview:sheetView];
        
        // Fade the nav bar and its contents to blue
        animation = [CATransition animation];
        [animation setType:kCATransitionFade];
        [animation setDuration:0.3f];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [[navBar layer] addAnimation:animation forKey:@"NavBarFade"];
        
        navBar.barStyle = UIBarStyleDefault;
        navBar.translucent = NO;
        ((THNavigationButton *)self.navigationItem.leftBarButtonItem.customView).barStyle = UIBarStyleDefault;
        [((UIButton *)self.navigationItem.rightBarButtonItem.customView) setImage:[UIImage imageNamed:@"BookButton.png"]
                                                                         forState:UIControlStateNormal];
        [((UIButton *)self.navigationItem.leftBarButtonItem.customView) setAlpha:0.0f];

        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    } else {
        UIView *sheetView = _contentsSheet.view;
        CGRect contentsViewFinalRect = sheetView.frame;
        contentsViewFinalRect.origin.y = contentsViewFinalRect.origin.y + contentsViewFinalRect.size.height;
        
        // Push out the contents sheet.
        [UIView beginAnimations:@"contentsSheetDisappear" context:NULL];
        [UIView setAnimationDidStopSelector:@selector(_contentsViewDidDisappear)];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDuration:0.3f];
        
        sheetView.frame = contentsViewFinalRect;
        
        
        if(!_viewIsDisappearing) {
            if(_contentsSheet.selectedUuid != nil && !_toolbar.hidden) {
                [self _toggleToolbars];
            }        
            
            // Turn the nav bar and its contents back to translucent.
            UINavigationBar *navBar = self.navigationController.navigationBar;

            CATransition *animation = [CATransition animation];
            [animation setType:kCATransitionFade];
            [animation setDuration:0.3f];
            [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
            [[navBar layer] addAnimation:animation forKey:@"ContentsSlideOut"];
            
            navBar.barStyle = UIBarStyleBlack;
            navBar.translucent = YES;
            ((THNavigationButton *)self.navigationItem.leftBarButtonItem.customView).barStyle = UIBarStyleBlackTranslucent;
            [((UIButton *)self.navigationItem.rightBarButtonItem.customView) setImage:[UIImage imageNamed:@"ContentsButton.png"]
                                                                             forState:UIControlStateNormal];
            [((UIButton *)self.navigationItem.leftBarButtonItem.customView) setAlpha:1.0f];

            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES]; 
        }
        [UIView commitAnimations];
    }
}


- (void)bookContentsTableViewController:(EucBookContentsTableViewController *)controller didSelectSectionWithUuid:(NSString *)uuid
{
    [self _contentsButtonTapped];
}


- (void)loadView 
{
    CGRect mainScreenBounds = [[UIScreen mainScreen] applicationFrame];
    UIView *mainSuperview = [[UIView alloc] initWithFrame:mainScreenBounds];
    mainSuperview.opaque = YES;
    mainSuperview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if(_bookView) {
        _bookView.frame = mainSuperview.bounds;
        [mainSuperview addSubview:_bookView];
        [mainSuperview sendSubviewToBack:_bookView];
    }
    self.view = mainSuperview;
    [mainSuperview release];
        
    if(!self.toolbarsVisibleAfterAppearance) {
        _toolbar.hidden = YES;
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    }    
}


- (void)_setupContentsButton
{
    UIImage *contentsImage = [UIImage imageNamed:@"ContentsButton.png"];
    UIButton *contentsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [contentsButton setImage:contentsImage forState:UIControlStateNormal];
    [contentsButton setAccessibilityLabel:NSLocalizedString(@"Contents", @"Contents button accessibility label")];
    contentsButton.adjustsImageWhenHighlighted = YES;
    contentsButton.showsTouchWhenHighlighted = NO;
    [contentsButton sizeToFit];
    [contentsButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin];
    [contentsButton addTarget:self action:@selector(_contentsButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:contentsButton];
    [rightItem setAccessibilityLabel:NSLocalizedString(@"Contents", @"Contents button accessibility label")];
    self.navigationItem.rightBarButtonItem = rightItem;
    [rightItem release];
}
    

- (void)viewWillAppear:(BOOL)animated
{
    if(!self.modalViewController) {        
        UIApplication *application = [UIApplication sharedApplication];
        
        UINavigationBar *navigationBar = self.navigationController.navigationBar;
        // Store the hidden/visible state and style of the status and navigation
        // bars so that we can restore them when popped.
        UIBarStyle navigationBarStyle = navigationBar.barStyle;
        BOOL navigationBarTranslucent = navigationBar.translucent;
        UIStatusBarStyle statusBarStyle = application.statusBarStyle;
        BOOL navigationBarHidden = self.navigationController.isNavigationBarHidden;
        BOOL statusBarHidden = application.isStatusBarHidden;
        
        if(!_overrideReturnToNavigationBarStyle) {
            _returnToNavigationBarStyle = navigationBarStyle;
        }
        if(!_overrideReturnToNavigationBarTranslucent) {
            _returnToNavigationBarTranslucent = navigationBarTranslucent;
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
        if(!(navigationBarStyle == UIBarStyleBlack && navigationBarTranslucent) && self.toolbarsVisibleAfterAppearance) {
            navigationBar.barStyle = UIBarStyleBlack;
            navigationBar.translucent = YES;
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
        
        if(!_toolbar && !_overriddenToolbar) {
            if([_bookView respondsToSelector:@selector(bookNavigationToolbar)]) {
                _toolbar = [[_bookView performSelector:@selector(bookNavigationToolbar)] retain];
            }
        } else {
            _toolbar = [_overriddenToolbar retain];
        }
        
        _toolbar.exclusiveTouch = YES;
        _toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        CGRect viewBounds = self.view.bounds;
        CGFloat toolbarFrameHeight = _toolbar.frame.size.height;
        [_toolbar setFrame:CGRectMake(viewBounds.origin.x,
                                      viewBounds.origin.y + viewBounds.size.height - toolbarFrameHeight,
                                      viewBounds.size.width,
                                      toolbarFrameHeight)];
        
        [self.view addSubview:_toolbar];
                
        _toolbar.hidden = !self.toolbarsVisibleAfterAppearance;

        if([_bookView isKindOfClass:[EucBookView class]]) {
            EucBookTitleView *titleView = (EucBookTitleView *)self.navigationItem.titleView;
            // Casts below shouldn't be necessary - the property is of type 'EucBookReference<EucBook> *'...
            [titleView setTitle:((EucBookReference *)((EucBookView *)_bookView).book).humanReadableTitle];
            [titleView setAuthor:[((EucBookReference *)((EucBookView *)_bookView).book).author humanReadableNameFromLibraryFormattedName]];                
        }
        
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
#ifdef __IPHONE_3_2
				if([application respondsToSelector:@selector(setStatusBarHidden:withAnimation:)]) {
                    [application setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
                } else  {
                    [(id)application setStatusBarHidden:NO animated:YES]; // typecast as id to mask deprecation warnings.
                }
#else
                [application setStatusBarHidden:NO animated:YES];
#endif
                [self.navigationController setNavigationBarHidden:YES animated:YES];
                [self.navigationController setNavigationBarHidden:NO animated:NO];
            }            
        } else {
            UINavigationBar *navBar = self.navigationController.navigationBar;
            navBar.barStyle = UIBarStyleBlack;  
            navBar.translucent = YES;
            if(![application isStatusBarHidden]) {
#ifdef __IPHONE_3_2
				if([application respondsToSelector:@selector(setStatusBarHidden:withAnimation:)]) {
                    [application setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
                } else  {
                    [(id)application setStatusBarHidden:YES animated:YES]; // typecast as id to mask deprecation warnings.
                }
#else
                [application setStatusBarHidden:YES animated:YES];
#endif
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
            [self _contentsButtonTapped];
        }
        if(_bookView) {
            [(THEventCapturingWindow *)self.view.window removeTouchObserver:self forView:_bookView];

            if([_bookView respondsToSelector:@selector(stopAnimation)]) {
                [_bookView performSelector:@selector(stopAnimation)];
            }

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
#ifdef __IPHONE_3_2
				if([application respondsToSelector:@selector(setStatusBarHidden:withAnimation:)]) {
                    [application setStatusBarHidden:_returnToStatusBarHidden withAnimation:UIStatusBarAnimationFade];
                } else  {
                    [(id)application setStatusBarHidden:_returnToStatusBarHidden animated:YES]; // typecast as id to mask deprecation warnings.
                }
#else
                [application setStatusBarHidden:_returnToStatusBarHidden animated:YES];
#endif
            }           
            UINavigationBar *navBar = self.navigationController.navigationBar;
            navBar.barStyle = UIBarStyleDefault;
            navBar.barStyle = _returnToNavigationBarStyle;
            navBar.translucent = _returnToNavigationBarTranslucent;
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
	return YES;
}


- (void)didReceiveMemoryWarning 
{
    if(_toolbar && !self.isViewLoaded) {
        [_toolbar release];
        _toolbar = nil;
        [_bookView release];
        _bookView = nil;
    }
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
}


- (void)dealloc 
{
    [_bookView release];
    [_overriddenToolbar release];
    [_toolbar release];

	[super dealloc];
}


- (void)_fadeDidEnd
{
    if(_fadeState == BookViewControlleUIFadeStateFadingOut) {
        _toolbar.hidden = YES;
        self.navigationController.navigationBar.hidden = YES;
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    } else {
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    }
    _fadeState = BookViewControlleUIFadeStateNone;
}


- (void)_fadeWillStart
{
    if(_fadeState == BookViewControlleUIFadeStateFadingOut) {
        UIApplication *application = [UIApplication sharedApplication];
#ifdef __IPHONE_3_2
        if([application respondsToSelector:@selector(setStatusBarHidden:withAnimation:)]) {
            [application setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        } else  {
            [(id)application setStatusBarHidden:YES animated:YES]; // typecast as id to mask deprecation warnings.
        }
#else
        [application setStatusBarHidden:YES animated:YES];
#endif
    } 
}

- (void)_toggleToolbars
{
    if(_fadeState == BookViewControlleUIFadeStateNone) {
        if(_toolbar.hidden) {
            UIApplication *application = [UIApplication sharedApplication];
#ifdef __IPHONE_3_2
            if([application respondsToSelector:@selector(setStatusBarHidden:withAnimation:)]) {
                [application setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
            } else  {
                [(id)application setStatusBarHidden:NO animated:NO]; // typecast as id to mask deprecation warnings.
            }
#else
            [application setStatusBarHidden:NO animated:NO];
#endif
            [application setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:NO];
            
            UINavigationBar *navigationBar = self.navigationController.navigationBar;
    
            // For some reason, the position of the navigation bar is not updated
            // correctly by the frameworks if it's hidden during a rotation,
            // so we proactively set it here.
            CGRect frame = navigationBar.frame;
            CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
            if(UIInterfaceOrientationIsLandscape([self interfaceOrientation])) {
                frame.origin.y = applicationFrame.origin.x;
            } else {
                frame.origin.y = applicationFrame.origin.y;
            }
            navigationBar.frame = frame;
               
            navigationBar.hidden = NO;
            self.navigationController.navigationBarHidden = NO;
            
            _toolbar.hidden = NO;
            _toolbar.alpha = 0;
            _fadeState = BookViewControlleUIFadeStateFadingIn;
        } else {
            _fadeState = BookViewControlleUIFadeStateFadingOut;
        }
                
        // Durations below taken from trial-and-error comparison with the 
        // Photos application.
        [UIView beginAnimations:@"ToolbarsFade" context:nil];
        
        if(_fadeState == BookViewControlleUIFadeStateFadingIn) {
            [UIView setAnimationDuration:0.0];
            _toolbar.alpha = 1;          
                        
            self.navigationController.navigationBar.alpha = 1;
        } else {
            [UIView setAnimationDuration:1.0/3.0];
            _toolbar.alpha = 0;
            self.navigationController.navigationBar.alpha = 0;
        }
        
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(_fadeDidEnd)];
        [UIView setAnimationWillStartSelector:@selector(_fadeWillStart)];
        
        [UIView commitAnimations];        
    }
}

- (void)bookViewPageTurnWillBegin:(EucBookView *)bookView
{
    if(!_toolbar.hidden) {
        [self _toggleToolbars];
    }    
    _pageViewIsTurning = YES;
}

- (void)bookViewPageTurnDidEnd:(EucBookView *)bookView
{
    _pageViewIsTurning = NO;
}

- (BOOL)bookViewToolbarsVisible:(EucBookView *)bookView
{
    return !_toolbar.hidden;
}

- (CGRect)bookViewNonToolbarRect:(EucBookView *)bookView
{
    CGRect rect = [bookView convertRect:self.bookView.bounds toView:nil];
    
    if([self bookViewToolbarsVisible:bookView]) {
        UINavigationBar *navBar = self.navigationController.navigationBar;
        CGRect navRect = [navBar convertRect:navBar.bounds toView:nil];
        
        CGFloat navRectBottom = CGRectGetMaxY(navRect);
        rect.size.height -= navRectBottom - rect.origin.y;
        rect.origin.y = navRectBottom;
        
        CGRect toolbarRect = [_toolbar convertRect:navBar.bounds toView:nil];
        rect.size.height = toolbarRect.origin.y - rect.origin.y;
    }
    
    return [bookView convertRect:rect fromView:nil];
}

- (void)observeTouch:(UITouch *)touch
{
    UITouchPhase phase = touch.phase;
        
    if(!_touch) {
        _touch = touch;
        _touchMoved = NO;
    } else if(touch == _touch) {
        if(phase == UITouchPhaseMoved) { 
            _touchMoved = YES;
            if(!_toolbar.hidden) {
                [self _toggleToolbars];
            }            
        } else if(phase == UITouchPhaseEnded) {
            if(!_touchMoved) {
                if(!_pageViewIsTurning) {
                    [self _toggleToolbars];
                }
            }
            _touch = nil;
        } else if(phase == UITouchPhaseCancelled) {
            _touch = nil;
        }
    }
}

@end
