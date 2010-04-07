//
//  BlioLayoutView.h
//  BlioApp
//
//  Created by matt on 18/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioBookView.h"
#import "BlioMockBook.h"
#import "MSTiltScroller.h"
#import <libEucalyptus/EucBookContentsTableViewController.h>
#import <libEucalyptus/EucSelector.h>

static const NSUInteger kBlioLayoutMaxPages = 6; // Must be at least 6 for the go to animations to look right

@class BlioLayoutScrollView;
@class BlioLayoutContentView;
@class BlioLayoutPageLayer;

typedef enum BlioLayoutPageMode {
    BlioLayoutPageModePortrait,
    BlioLayoutPageModeLandscape
} BlioLayoutPageMode;

@protocol BlioLayoutDataSource
@required
- (BOOL)dataSourceContainsPage:(NSInteger)page;
- (CGRect)cropForPage:(NSInteger)page;
- (CGAffineTransform)viewTransformForPage:(NSInteger)page;
- (CGPoint)contentOffsetToCenterPage:(NSInteger)aPageNumber zoomScale:(CGFloat)zoomScale;
- (CGPoint)contentOffsetToFillPage:(NSInteger)aPageNumber zoomScale:(CGFloat *)zoomScale;

- (void)drawThumbLayer:(CALayer *)aLayer inContext:(CGContextRef)ctx forPage:(NSInteger)aPageNumber withCacheLayer:(CGLayerRef)cacheLayer;
- (void)drawTiledLayer:(CALayer *)aLayer inContext:(CGContextRef)ctx forPage:(NSInteger)aPageNumber cacheReadyTarget:(id)target cacheReadySelector:(SEL)readySelector;
- (void)drawShadowLayer:(CALayer *)aLayer inContext:(CGContextRef)ctx forPage:(NSInteger)page;
- (void)drawHighlightsLayer:(CALayer *)aLayer inContext:(CGContextRef)ctx forPage:(NSInteger)page excluding:(BlioBookmarkRange *)excludedBookmark;

@end

@interface BlioLayoutView : UIView <BlioLayoutDataSource, UIScrollViewDelegate, BlioBookView, BlioTTSDataSource, EucBookContentsTableViewControllerDataSource, EucSelectorDataSource, EucSelectorDelegate> {
    id<BlioBookDelegate> delegate;
    BlioMockBook *book;
    CGPDFDocumentRef pdf;
    BlioLayoutScrollView *scrollView;
    BlioLayoutContentView *contentView;
    NSInteger visiblePageIndex;
    BlioLayoutPageLayer *currentPageLayer;
    BOOL scrollToPageInProgress;
    BOOL disableScrollUpdating;
    MSTiltScroller *tiltScroller;
    NSInteger pageNumber;
    NSInteger pageCount;
    CGFloat lastZoomScale;
    CGFloat targetZoomScale;
    CGPoint targetContentOffset;
    BOOL shouldZoomOut;
    CALayer *sharpLayer;
    EucSelector *selector;
    UIColor *lastHighlightColor;
    NSString *pdfPath;
    NSData *pdfData;
    NSDictionary *pageCropsCache;
    NSDictionary *viewTransformsCache;
    UIImage *checkerBoard;
    UIImage *shadowBottom;
    UIImage *shadowTop;
    UIImage *shadowLeft;
    UIImage *shadowRight;
    UIImage *pageSnapshot;
    UIImage *highlightsSnapshot;
    BOOL isCancelled;
    BlioTextFlowBlock *lastBlock;
    BlioLayoutPageMode layoutMode;
}

@property (nonatomic, assign) id<BlioBookDelegate> delegate;
@property (nonatomic, retain) BlioMockBook *book;
@property (nonatomic, retain) BlioLayoutScrollView *scrollView;
@property (nonatomic, retain) BlioLayoutContentView *contentView;
@property (nonatomic, retain) BlioLayoutPageLayer *currentPageLayer;
@property (nonatomic, assign) MSTiltScroller *tiltScroller;
@property (nonatomic) BOOL scrollToPageInProgress;
@property (nonatomic) BOOL disableScrollUpdating;
@property (nonatomic, readonly) NSInteger pageNumber;
@property (nonatomic, retain) EucSelector *selector;
@property (nonatomic, retain) UIColor *lastHighlightColor;
@property (nonatomic, retain) NSDictionary *pageCropsCache;
@property (nonatomic, retain) NSDictionary *viewTransformsCache;
@property (nonatomic, retain) NSString *pdfPath;
@property (nonatomic, retain) UIImage *checkerBoard;
@property (nonatomic, retain) UIImage *shadowBottom;
@property (nonatomic, retain) UIImage *shadowTop;
@property (nonatomic, retain) UIImage *shadowLeft;
@property (nonatomic, retain) UIImage *shadowRight;

@end
