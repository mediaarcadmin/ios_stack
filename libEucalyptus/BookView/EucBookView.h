//
//  EucBookView.h
//  libEucalyptus
//
//  Created by James Montgomerie on 17/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EucBookContentsTableViewController.h"
#import "EucPageTurningView.h"
#import "EucPageView.h"

@protocol EucBook, EucPageLayoutController, EucBookViewDelegate;
@class EucBookReference, THScalableSlider;

@interface EucBookView : UIView <EucPageTurningViewDelegate, EucPageViewDelegate> {
    id<EucBookViewDelegate> _delegate;
    EucBookReference<EucBook> *_book;    

    UIImage *_pageTexture;
    BOOL _pageTextureIsDark;
    
    EucPageTurningView *_pageTurningView;
    id<EucPageLayoutController> _pageLayoutController;

    NSInteger _pageNumber;
    
    NSMutableDictionary *_pageViewToIndexPoint;
    NSCountedSet *_pageViewToIndexPointCounts;
    
    CGFloat _dimQuotient;
    BOOL _undimAfterAppearance;
    BOOL _appearAtCoverThenOpen;
    
    NSInteger _directionalJumpCount;
    NSInteger _savedJumpPage;
    BOOL _jumpShouldBeSaved;    
    
    BOOL _scaleUnderway;
    CGFloat _scaleStartPointSize;
    CGFloat _scaleCurrentPointSize;    

    double _scaleCount;
    CFAbsoluteTime _accumulatedScaleTime;
    BOOL _dontSaveIndexPoints;
    
    // Toolbar:
    THScalableSlider *_pageSlider;
    BOOL _pageSliderIsTracking;
    UILabel *_pageNumberLabel;
    float _sliderByteToPageRatio;
    BOOL _paginationIsComplete;
    
    UIView *_pageSliderTrackingInfoView;    
    
    NSInteger _highlightPage;
    uint32_t _highlightParagraph;
    uint32_t _highlightWordOffset;

    NSMutableArray *_highlightLayers;
    BOOL _highlightingDisabled;
}

- (id)initWithFrame:(CGRect)frame book:(EucBookReference<EucBook> *)book;

@property (nonatomic, assign) id<EucBookViewDelegate> delegate;

@property (nonatomic, readonly) EucBookReference<EucBook> *book;

@property (nonatomic, assign) CGFloat dimQuotient;
@property (nonatomic, assign) BOOL undimAfterAppearance;
@property (nonatomic, assign) BOOL appearAtCoverThenOpen;

@property (nonatomic, assign) NSInteger pageNumber;
@property (nonatomic, readonly) NSInteger pageCount;
@property (nonatomic, readonly) NSString *displayPageNumber;
@property (nonatomic, readonly) NSString *pageDescription;

@property (nonatomic, assign) CGFloat fontPointSize;
@property (nonatomic, readonly) id<EucBookContentsTableViewControllerDataSource> contentsDataSource;

// - (void)setPageTexture:(UIImage *)pageTexture isDark:(BOOL)isDark;
// should be used to set these atomically.
@property (nonatomic, retain, readonly) UIImage *pageTexture;
@property (nonatomic, assign, readonly) BOOL pageTextureIsDark;
- (void)setPageTexture:(UIImage *)pageTexture isDark:(BOOL)isDark;

/*
@property (nonatomic, readonly) float percentRead;
@property (nonatomic, readonly) float percentPaginated;
*/

@property (nonatomic, readonly) UIImage *currentPageImage;

- (IBAction)jumpForwards;
- (IBAction)jumpBackwards;

- (void)jumpToUuid:(NSString *)uuid;
- (void)setPageNumber:(NSInteger)pageNumber animated:(BOOL)animated;


- (void)highlightWordAtParagraphId:(uint32_t)paragraphId wordOffset:(uint32_t)wordOffset;

- (void)stopAnimation;

@end

@protocol EucBookViewDelegate <NSObject>
@optional
- (BOOL)bookView:(EucBookView *)controller shouldHandleTapOnHyperlink:(NSURL *)link withAttributes:(NSDictionary *)attributes;
@end
