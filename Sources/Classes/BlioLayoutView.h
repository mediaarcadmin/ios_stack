//
//  BlioLayoutView.h
//  BlioApp
//
//  Created by matt on 18/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioBookView.h"
#import "BlioSelectableBookView.h"
#import "BlioMockBook.h"
#import "MSTiltScroller.h"
#import <libEucalyptus/EucBookContentsTableViewController.h>
#import <libEucalyptus/EucSelector.h>
#import "XpsSdk.h"

static const NSUInteger kBlioLayoutMaxPages = 6; // Must be at least 6 for the go to animations to look right

@class BlioLayoutScrollView;
@class BlioLayoutContentView;
@class BlioLayoutPageLayer;

typedef enum BlioLayoutPageMode {
    BlioLayoutPageModePortrait,
    BlioLayoutPageModeLandscape
} BlioLayoutPageMode;

@protocol BlioLayoutRenderingDelegate
- (BOOL)dataSourceContainsPage:(NSInteger)page;
- (void)drawThumbLayer:(CALayer *)aLayer inContext:(CGContextRef)ctx forPage:(NSInteger)page withCacheLayer:(CGLayerRef)cacheLayer;
- (void)drawTiledLayer:(CALayer *)aLayer inContext:(CGContextRef)ctx forPage:(NSInteger)page cacheReadyTarget:(id)target cacheReadySelector:(SEL)readySelector;
- (void)drawShadowLayer:(CALayer *)aLayer inContext:(CGContextRef)ctx forPage:(NSInteger)page;
- (void)drawHighlightsLayer:(CALayer *)aLayer inContext:(CGContextRef)ctx forPage:(NSInteger)page excluding:(BlioBookmarkRange *)excludedBookmark;

@end


@protocol BlioLayoutDataSource
@required

@property(nonatomic, readonly) NSInteger pageCount;

- (CGRect)cropRectForPage:(NSInteger)page;
- (CGRect)mediaRectForPage:(NSInteger)page;
- (CGFloat)dpiRatio;

- (void)openDocumentIfRequired;
- (void)closeDocumentIfRequired;
- (void)closeDocument;

- (void)drawPage:(NSInteger)page inBounds:(CGRect)bounds withInset:(CGFloat)inset inContext:(CGContextRef)ctx inRect:(CGRect)rect withTransform:(CGAffineTransform)transform observeAspect:(BOOL)aspect;

@end

@interface BlioLayoutView : BlioSelectableBookView <BlioLayoutRenderingDelegate, UIScrollViewDelegate, BlioBookView, EucSelectorDataSource, EucSelectorDelegate> {
    BlioMockBook *book;
    CGPDFDocumentRef pdf;
    BlioLayoutScrollView *scrollView;
    BlioLayoutContentView *contentView;
    NSInteger visiblePageIndex;
    BlioLayoutPageLayer *currentPageLayer;
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
    CGAffineTransform cachedViewTransform;
    NSInteger cachedViewTransformPage;
    NSMutableArray *accessibilityElements;
    NSArray *previousAccessibilityElements;
    BOOL accessibilityRefreshRequired;
    NSString *xpsPath;
    RasterImageInfo *imageInfo;
    XPS_HANDLE xpsHandle;
    id<BlioLayoutDataSource> dataSource;
}

@property (nonatomic, retain) BlioMockBook *book;
@property (nonatomic, retain) BlioLayoutScrollView *scrollView;
@property (nonatomic, retain) BlioLayoutContentView *contentView;
@property (nonatomic, retain) BlioLayoutPageLayer *currentPageLayer;
@property (nonatomic, assign) MSTiltScroller *tiltScroller;
@property (nonatomic) BOOL disableScrollUpdating;
@property (nonatomic, readonly) NSInteger pageNumber;
@property (nonatomic, retain) EucSelector *selector;
@property (nonatomic, retain) NSDictionary *pageCropsCache;
@property (nonatomic, retain) NSDictionary *viewTransformsCache;
@property (nonatomic, retain) NSString *pdfPath;
@property (nonatomic, retain) UIImage *checkerBoard;
@property (nonatomic, retain) UIImage *shadowBottom;
@property (nonatomic, retain) UIImage *shadowTop;
@property (nonatomic, retain) UIImage *shadowLeft;
@property (nonatomic, retain) UIImage *shadowRight;
@property (nonatomic, retain) NSString *xpsPath;

@end
