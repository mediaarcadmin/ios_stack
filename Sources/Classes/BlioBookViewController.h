//
//  BookViewController.h
//  libEucalyptus
//
//  Created by James Montgomerie on 09/05/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <libEucalyptus/EucBookContentsTableViewController.h>
#import <libEucalyptus/THEventCapturingWindow.h>

@class EucPageView, EucGutenbergPageLayoutController, EucBookSection, EucBookContentsTableViewController, THScalableSlider, EucBookReference;
@protocol EucBook, BlioBookView;

typedef enum {
    BookViewControlleUIFadeStateNone = 0,
    BookViewControlleUIFadeStateFadingOut,
    BookViewControlleUIFadeStateFadingIn,
} BookViewControllerUIFadeState;

@interface BlioBookViewController : UIViewController <THEventCaptureObserver,EucBookContentsTableViewControllerDelegate> {
    BOOL _firstAppearance;
    
    UIView<BlioBookView> *_bookView;
    
    BookViewControllerUIFadeState _fadeState;
    
    UIToolbar *_toolbar;
    
    UITouch *_touch;
    BOOL _touchMoved;
            
    EucBookContentsTableViewController *_contentsSheet;
    
    BOOL _viewIsDisappearing;
        
    UIBarStyle _returnToNavigationBarStyle;
    UIStatusBarStyle _returnToStatusBarStyle;
    BOOL _returnToNavigationBarHidden;
    BOOL _returnToStatusBarHidden;
    
    BOOL _overrideReturnToNavigationBarStyle;
    BOOL _overrideReturnToStatusBarStyle;
    BOOL _overrideReturnToNavigationBarHidden;
    BOOL _overrideReturnToStatusBarHidden;
}

// Designated initializers.
- (id)initWithBookView:(UIView<BlioBookView> *)view;

@property (nonatomic, assign) BOOL toolbarsVisibleAfterAppearance;

@property (nonatomic, assign) UIBarStyle returnToNavigationBarStyle;
@property (nonatomic, assign) UIStatusBarStyle returnToStatusBarStyle;
@property (nonatomic, assign) BOOL returnToNavigationBarHidden;
@property (nonatomic, assign) BOOL returnToStatusBarHidden;

@property (nonatomic, retain) UIView<BlioBookView> *bookView;

@end

@protocol BlioBookView <NSObject>

@required
- (void)jumpToUuid:(NSString *)uuid;

@property (nonatomic, assign) NSInteger pageNumber;
@property (nonatomic, readonly) id<EucBookContentsTableViewControllerDataSource> contentsDataSource;

@optional
@property (nonatomic, assign) CGFloat fontPointSize;

@end