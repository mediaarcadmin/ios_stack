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
- (void)_setupContentsButton;
@end

@implementation BlioBookViewController

@synthesize bookView = _bookView;

@synthesize returnToNavigationBarStyle = _returnToNavigationBarStyle;
@synthesize returnToStatusBarStyle = _returnToStatusBarStyle;
@synthesize returnToNavigationBarHidden = _returnToNavigationBarHidden;
@synthesize returnToStatusBarHidden = _returnToStatusBarHidden;

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

- (id)initWithBookView:(UIView<BlioBookView> *)view
{
	if ((self = [super initWithNibName:nil bundle:nil])) {
        self.wantsFullScreenLayout = NO;

        UIButton *backArrow = [THNavigationButton leftNavigationButtonWithArrowInBarStyle:UIBarStyleBlackTranslucent];
        [backArrow addTarget:self
                      action:@selector(_backButtonTapped) 
            forControlEvents:UIControlEventTouchUpInside];

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
        
        self.toolbarItems = [NSArray array];
        
        _bookView = [view retain];        
    }
	return self;
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
        
        /*if([_bookView isKindOfClass:[BlioEPubView class]]) {
            EucBookTitleView *titleView = (EucBookTitleView *)self.navigationItem.titleView;
            // Casts below shouldn't be necessary - the property is of type 'EucBookReference<EucBook> *'...
            [titleView setTitle:((EucBookReference *)((BlioEPubView *)_bookView).book).humanReadableTitle];
            [titleView setAuthor:[((EucBookReference *)((BlioEPubView *)_bookView).book).author humanReadableNameFromLibraryFormattedName]];                
        }*/
        
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

- (void)_contentsButtonTapped
{
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    if(!_contentsSheet) {
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
}


- (void)bookContentsTableViewController:(EucBookContentsTableViewController *)controller didSelectSectionWithUuid:(NSString *)uuid
{
    [self _contentsButtonTapped];
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


- (void)_setupContentsButton
{
    UIImage *contentsImage = [UIImage imageNamed:@"ContentsButton.png"];
    UIButton *contentsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [contentsButton setImage:contentsImage forState:UIControlStateNormal];
    contentsButton.adjustsImageWhenHighlighted = YES;
    contentsButton.showsTouchWhenHighlighted = NO;
    [contentsButton sizeToFit];
    [contentsButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin];
    [contentsButton addTarget:self action:@selector(_contentsButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:contentsButton];
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
                        
        /*if([_bookView isKindOfClass:[BlioEPubView class]]) {
            EucBookTitleView *titleView = (EucBookTitleView *)self.navigationItem.titleView;
            // Casts below shouldn't be necessary - the property is of type 'EucBookReference<EucBook> *'...
            [titleView setTitle:((EucBookReference *)((BlioEPubView *)_bookView).book).humanReadableTitle];
            [titleView setAuthor:[((EucBookReference *)((BlioEPubView *)_bookView).book).author humanReadableNameFromLibraryFormattedName]];                
        }*/
        
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
            [self _contentsButtonTapped];
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

@end
