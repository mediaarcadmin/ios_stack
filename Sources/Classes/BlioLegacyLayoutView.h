//
//  BlioLegacyLayoutView.h
//  BlioApp
//
//  Created by matt on 18/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioTextFlow.h"
#import "BlioBookView.h"
#import "BlioSelectableBookView.h"
#import <libEucalyptus/EucBookContentsTableViewController.h>
#import <libEucalyptus/EucSelector.h>
#import "BlioLayoutDataSource.h"
#import "BlioXPSProvider.h"

static const NSUInteger kBlioLegacyLayoutMaxPages = 6; // Must be at least 6 for the go to animations to look right

@class BlioLegacyLayoutScrollView;
@class BlioLegacyLayoutContentView;
@class BlioLegacyLayoutPageLayer;

typedef enum BlioLegacyLayoutPageMode {
    BlioLegacyLayoutPageModePortrait,
    BlioLegacyLayoutPageModeLandscape
} BlioLegacyLayoutPageMode;

@protocol BlioLegacyLayoutRenderingDelegate
- (BOOL)dataSourceContainsPage:(NSInteger)page;
- (void)drawThumbLayer:(CALayer *)aLayer inContext:(CGContextRef)ctx forPage:(NSInteger)page withCacheLayer:(CGLayerRef)cacheLayer;
- (void)drawTiledLayer:(CALayer *)aLayer inContext:(CGContextRef)ctx forPage:(NSInteger)page cacheReadyTarget:(id)target cacheReadySelector:(SEL)readySelector;
- (void)drawShadowLayer:(CALayer *)aLayer inContext:(CGContextRef)ctx forPage:(NSInteger)page;
- (void)drawHighlightsLayer:(CALayer *)aLayer inContext:(CGContextRef)ctx forPage:(NSInteger)page excluding:(BlioBookmarkRange *)excludedBookmark;

@end

@interface BlioLegacyLayoutView : BlioSelectableBookView <BlioLegacyLayoutRenderingDelegate, UIScrollViewDelegate, BlioBookView, EucSelectorDataSource, EucSelectorDelegate> {
    NSManagedObjectID *bookID;
    BlioTextFlow *textFlow;
    CGPDFDocumentRef pdf;
    BlioLegacyLayoutScrollView *scrollView;
    UIView *containerView;
    BlioLegacyLayoutContentView *contentView;
    NSInteger visiblePageIndex;
    BlioLegacyLayoutPageLayer *currentPageLayer;
    BOOL scrollingAnimationInProgress;
    NSInteger pageNumber;
    NSInteger pageCount;
    CGFloat lastZoomScale;
    CGFloat targetZoomScale;
    CGPoint targetContentOffset;
    BOOL shouldZoomOut;
    CALayer *sharpLayer;
    EucSelector *selector;
    NSMutableDictionary *pageCropsCache;
    NSMutableDictionary *viewTransformsCache;
    CGRect firstPageCrop;
    UIImage *checkerBoard;
    UIImage *shadowBottom;
    UIImage *shadowTop;
    UIImage *shadowLeft;
    UIImage *shadowRight;
    UIImage *pageSnapshot;
    UIImage *highlightsSnapshot;
    BOOL isCancelled;
    BlioLegacyLayoutPageMode layoutMode;
    CGAffineTransform cachedViewTransform;
    NSInteger cachedViewTransformPage;
    NSMutableArray *accessibilityElements;
    BlioTimeOrderedCache *accessibilityCache;
    
    BOOL accessibilityRefreshRequired;
    
    BlioXPSProvider *xpsProvider;
    id<BlioLayoutDataSource> dataSource;
    
    NSLock *layoutCacheLock;
    
    BlioTextFlowBlock *lastBlock;
    NSUInteger blockRecursionDepth;
}

@property (nonatomic, retain) NSManagedObjectID *bookID;
@property (nonatomic, retain) BlioTextFlow *textFlow;
@property (nonatomic, retain) BlioLegacyLayoutScrollView *scrollView;
@property (nonatomic, retain) UIView *containerView;
@property (nonatomic, retain) BlioLegacyLayoutContentView *contentView;
@property (nonatomic, retain) BlioLegacyLayoutPageLayer *currentPageLayer;
@property (nonatomic) BOOL scrollingAnimationInProgress;
@property (nonatomic, readonly) NSInteger pageNumber;
@property (nonatomic, retain) EucSelector *selector;
@property (nonatomic, retain) NSMutableDictionary *pageCropsCache;
@property (nonatomic, retain) NSMutableDictionary *viewTransformsCache;
@property (nonatomic, retain) UIImage *checkerBoard;
@property (nonatomic, retain) UIImage *shadowBottom;
@property (nonatomic, retain) UIImage *shadowTop;
@property (nonatomic, retain) UIImage *shadowLeft;
@property (nonatomic, retain) UIImage *shadowRight;

@end