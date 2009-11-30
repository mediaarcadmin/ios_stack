//
//  BookViewController.h
//  Eucalyptus
//
//  Created by James Montgomerie on 09/05/2008.
//  Copyright 2008 James Montgomerie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EucPageTurningView.h"
#import "EucBookContentsTableViewController.h"
#import "EucPageView.h"

@class EucPageView, EucGutenbergPageLayoutController, EucBookSection, EucBookContentsTableViewController, THScalableSlider, EucBookReference;
@protocol EucBook, EucBookViewControllerDelegate;

typedef enum {
    BookViewControlleUIFadeStateNone = 0,
    BookViewControlleUIFadeStateFadingOut,
    BookViewControlleUIFadeStateFadingIn,
} BookViewControllerUIFadeState;

@interface EucBookViewController : UIViewController <EucPageTurningViewDelegate, EucPageViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate, BookContentsTableViewControllerDelegate> {
    id<EucBookViewControllerDelegate> _delegate;
    id<EucBook> _book;

    BOOL _firstAppearance;
    
    EucPageTurningView *_pageTurningView;
    NSMutableDictionary *_pageViewToIndexPoint;
    NSCountedSet *_pageViewToIndexPointCounts;
    UIToolbar *_toolbar;
    
    THScalableSlider *_pageSlider;
    BOOL _pageSliderIsTracking;
    UILabel *_pageNumberLabel;
    float _sliderByteToPageRatio;
    BOOL _paginationIsComplete;
    NSInteger _pageNumber;
    
    UIView *_pageSliderTrackingInfoView;
    
    
    id<EucPageLayoutController> _pageLayoutController;
        
    BookViewControllerUIFadeState _fadeState;
    
    UITouch *_touch;
    BOOL _touchMoved;
    
    CGFloat _dimQuotient;
    BOOL _undimAfterAppearance;
    BOOL _appearAtCoverThenOpen;
    BOOL _toolbarsVisibleAfterAppearance;
    
    NSInteger _directionalJumpCount;
    NSInteger _savedJumpPage;
    BOOL _jumpShouldBeSaved;
    
    EucBookContentsTableViewController *_contentsSheet;
    
    BOOL _viewIsDisappearing;
    
    double _scaleCount;
    CFAbsoluteTime _accumulatedScaleTime;
    
    BOOL _scaleUnderway;
    CGFloat _scaleStartPointSize;
    CGFloat _scaleCurrentPointSize;
    
    BOOL _bookWasDeleted;
    
    UIBarStyle _returnToNavigationBarStyle;
    UIStatusBarStyle _returnToStatusBarStyle;
    BOOL _returnToNavigationBarHidden;
    BOOL _returnToStatusBarHidden;
    
    BOOL _overrideReturnToNavigationBarStyle;
    BOOL _overrideReturnToStatusBarStyle;
    BOOL _overrideReturnToNavigationBarHidden;
    BOOL _overrideReturnToStatusBarHidden;
}

// A simple 'init' is the designated initializer.
- (id)init;

@property (nonatomic, retain) EucBookReference<EucBook> * book;

@property (nonatomic, assign) BOOL toolbarsVisibleAfterAppearance;
@property (nonatomic, assign) BOOL appearAtCoverThenOpen;

@property (nonatomic, assign) CGFloat dimQuotient;
@property (nonatomic, assign) BOOL undimAfterAppearance;

@property (nonatomic, assign) id<EucBookViewControllerDelegate> delegate;

@property (nonatomic) NSInteger pageNumber;
@property (nonatomic, readonly) NSString *currentSectionUuid;
@property (nonatomic, readonly) UIImage *currentPageImage;

@property (nonatomic, assign) UIBarStyle returnToNavigationBarStyle;
@property (nonatomic, assign) UIStatusBarStyle returnToStatusBarStyle;
@property (nonatomic, assign) BOOL returnToNavigationBarHidden;
@property (nonatomic, assign) BOOL returnToStatusBarHidden;

@end

@protocol EucBookViewControllerDelegate <NSObject>
@optional
- (BOOL)bookViewController:(EucBookViewController *)controller shouldHandleTapOnHyperlink:(NSURL *)link withAttributes:(NSDictionary *)attributes;
@end
