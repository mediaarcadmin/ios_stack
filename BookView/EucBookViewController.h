//
//  BookViewController.h
//  libEucalyptus
//
//  Created by James Montgomerie on 09/05/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EucPageTurningView.h"
#import "EucBookContentsTableViewController.h"
#import "EucBookView.h"
#import "EucPageView.h"
#import "THEventCapturingWindow.h"

@class EucPageView, EucGutenbergPageLayoutController, EucBookSection, EucBookContentsTableViewController, THScalableSlider, EucBookReference;
@protocol EucBook, EucBookViewControllerDelegate;

typedef enum {
    BookViewControlleUIFadeStateNone = 0,
    BookViewControlleUIFadeStateFadingOut,
    BookViewControlleUIFadeStateFadingIn,
} BookViewControllerUIFadeState;

@interface EucBookViewController : UIViewController <THEventCaptureObserver, EucBookViewDelegate, EucPageViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate, BookContentsTableViewControllerDelegate> {
    id<EucBookViewControllerDelegate> _delegate;
    
    BOOL _firstAppearance;
    
    EucBookView *_bookView;
    
    UIToolbar *_overriddenToolbar;
    UIToolbar *_toolbar;
        
    BookViewControllerUIFadeState _fadeState;
    
    UITouch *_touch;
    BOOL _touchMoved;
    
    BOOL _toolbarsVisibleAfterAppearance;
        
    EucBookContentsTableViewController *_contentsSheet;
    
    BOOL _viewIsDisappearing;
        
    UIBarStyle _returnToNavigationBarStyle;
    BOOL _returnToNavigationBarTranslucent;
    UIStatusBarStyle _returnToStatusBarStyle;
    BOOL _returnToNavigationBarHidden;
    BOOL _returnToStatusBarHidden;
    
    BOOL _overrideReturnToNavigationBarStyle;
    BOOL _overrideReturnToNavigationBarTranslucent;
    BOOL _overrideReturnToStatusBarStyle;
    BOOL _overrideReturnToNavigationBarHidden;
    BOOL _overrideReturnToStatusBarHidden;
}

// Designated initializers.
- (id)initWithBook:(EucBookReference<EucBook> *)book;
- (id)initWithBookView:(UIView *)view;

@property (nonatomic, assign) id<EucBookViewControllerDelegate> delegate;

@property (nonatomic, assign) BOOL toolbarsVisibleAfterAppearance;

@property (nonatomic, assign) UIBarStyle returnToNavigationBarStyle;
@property (nonatomic, assign) BOOL returnToNavigationBarTranslucent;
@property (nonatomic, assign) UIStatusBarStyle returnToStatusBarStyle;
@property (nonatomic, assign) BOOL returnToNavigationBarHidden;
@property (nonatomic, assign) BOOL returnToStatusBarHidden;

@property (nonatomic, retain) UIView *bookView;
@property (nonatomic, retain) UIToolbar *overriddenToolbar;


@end