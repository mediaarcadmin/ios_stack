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

@class TransitionView, EucBookPageIndex, EucPageView, EucGutenbergPageLayoutController, EucBookSection, EucBookContentsTableViewController, THScalableSlider, EucBookReference;
@protocol EucBook, EucBookViewControllerDelegate;

typedef enum {
    BookViewControlleUIFadeStateNone = 0,
    BookViewControlleUIFadeStateFadingOut,
    BookViewControlleUIFadeStateFadingIn,
} BookViewControllerUIFadeState;

@interface EucBookViewController : UIViewController <EucPageTurningViewDelegate, EucPageViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate, BookContentsTableViewControllerDelegate> {
    id<EucBookViewControllerDelegate> _delegate;
    
    BOOL _showToolbarsOnFirstAppearance;
    BOOL _firstAppearance;
    
    TransitionView *_transitionView;
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
    
    id<EucBook> _book;
    
    id<EucPageLayoutController> _pageLayoutController;
        
    BookViewControllerUIFadeState _fadeState;
    
    UITouch *_touch;
    BOOL _touchMoved;
    
    CGFloat _dimQuotient;
    BOOL _undimAfterAppearance;
    
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
}
@property (nonatomic, assign) id<EucBookViewControllerDelegate> delegate;
@property (nonatomic, retain) TransitionView *transitionView;
@property (nonatomic, retain) EucBookReference<EucBook> * book;
@property (nonatomic) NSInteger pageNumber;
@property (nonatomic, readonly) UIImage *currentPageImage;
@property (nonatomic, assign) CGFloat dimQuotient;
@property (nonatomic, assign) BOOL undimAfterAppearance;

- (id)initWithTransitionViewForBookContent:(TransitionView *)transitionView withToolbars:(BOOL)withToolbars;

@end

@protocol EucBookViewControllerDelegate <NSObject>
@optional
- (BOOL)bookViewController:(EucBookViewController *)controller shouldHandleTapOnHyperlink:(NSURL *)link withAttributes:(NSDictionary *)attributes;
@end
