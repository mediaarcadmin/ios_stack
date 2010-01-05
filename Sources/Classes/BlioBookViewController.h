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
#import "AcapelaTTS.h"
#import "BlioMockBook.h"
#import "BlioBookView.h"
#import "MSTiltScroller.h"
#import "MSTapDetector.h"

@class EucPageView, EucGutenbergPageLayoutController, EucBookSection, EucBookContentsTableViewController, THScalableSlider, EucBookReference;
@protocol EucBook, BlioBookView;

typedef enum {
    BookViewControlleUIFadeStateNone = 0,
    BookViewControlleUIFadeStateFadingOut,
    BookViewControlleUIFadeStateFadingIn,
} BookViewControllerUIFadeState;

typedef enum {
    kBlioPageColorWhite = 0,
    kBlioPageColorBlack = 1,
    kBlioPageColorNeutral = 2,
} BlioPageColor;

@interface BlioBookViewController : UIViewController <THEventCaptureObserver,EucBookContentsTableViewControllerDelegate,UIActionSheetDelegate,UIAccelerometerDelegate> {
    BOOL _firstAppearance;
    
    UIView<BlioBookView> *_bookView;
    
    BookViewControllerUIFadeState _fadeState;
    
    UIToolbar *_toolbar;
    
    UITouch *_touch;
    BOOL _touchMoved;
            
    EucBookContentsTableViewController *_contentsSheet;
    
    BOOL _viewIsDisappearing;
        
    UIBarStyle _returnToNavigationBarStyle;
    UIColor *_returnToNavigationBarTint;
    BOOL _returnToNavigationBarHidden;
    UIBarStyle _returnToToolbarStyle;
    UIColor *_returnToToolbarTint;
    UIStatusBarStyle _returnToStatusBarStyle;
    BOOL _returnToStatusBarHidden;
    
    BOOL _overrideReturnToNavigationBarStyle;
    BOOL _overrideReturnToStatusBarStyle;
    BOOL _overrideReturnToNavigationBarHidden;
    BOOL _overrideReturnToStatusBarHidden;
    BOOL _audioPlaying;
    
    AcapelaTTS* _acapelaTTS;
    
    BlioMockBook *_book;

    MSTiltScroller *tiltScroller;
    MSTapDetector *tapDetector;
    BOOL motionControlsEnabled;
    
    BlioPageColor _currentPageColor;
    
    UIBarButtonItem* _pageJumpButton;
    UIView* _pageJumpView;
    UILabel* _pageJumpLabel;
    UISlider* _pageJumpSlider;
    BOOL _pageJumpSliderTracking;
}

// Designated initializers.
- (id)initWithBook:(BlioMockBook *)newBook;
- (id)initWithBookView:(UIView<BlioBookView> *)view;

@property (nonatomic, retain) BlioMockBook *book;
@property (nonatomic, assign) BOOL toolbarsVisibleAfterAppearance;

@property (nonatomic, assign) UIBarStyle returnToNavigationBarStyle;
@property (nonatomic, assign) UIStatusBarStyle returnToStatusBarStyle;
@property (nonatomic, assign) BOOL returnToNavigationBarHidden;
@property (nonatomic, assign) BOOL returnToStatusBarHidden;

@property (nonatomic, assign) BlioPageColor currentPageColor;

@property (nonatomic, retain) UIView<BlioBookView> *bookView;
@property (nonatomic) BOOL audioPlaying;

@property (nonatomic, retain) MSTiltScroller *tiltScroller;
@property (nonatomic, retain) MSTapDetector *tapDetector;
@property (nonatomic, assign) BOOL motionControlsEnabled;

@property (nonatomic, retain) UIView *pageJumpView;

- (void)tapToNextPage;

- (void)toggleToolbars;

@end