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

@class BlioPDFFontList;
@class BlioPDFParsedPage;
@class BlioPDFDebugView;
@class BlioPDFPageView;
@class BlioLayoutScrollView;
@class BlioLayoutContentView;
@class BlioLayoutPageLayer;

@protocol BlioLayoutDataSource
@optional
- (BOOL)dataSourceContainsPage:(NSInteger)page;
- (CGAffineTransform)viewTransformForPage:(NSInteger)page;
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx forPage:(NSInteger)page;
- (void)drawInContext:(CGContextRef)ctx forPage:(NSInteger)page;
- (void)drawThumbInContext:(CGContextRef)ctx forPage:(NSInteger)page;
- (void)drawShadowInContext:(CGContextRef)ctx forPage:(NSInteger)page;
- (void)drawHighlightsInContext:(CGContextRef)ctx forPage:(NSInteger)page;

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
    CALayer *sharpLayer;
    EucSelector *selector;
    UIColor *lastHighlightColor;
    NSOperationQueue *fetchHighlightsQueue;
    NSOperationQueue *renderThumbsQueue;
    NSMutableDictionary *thumbCache;
    NSString *pdfPath;
    NSData *pdfData;
    NSDictionary *pageCropsCache;
    NSDictionary *viewTransformsCache;
    UIImage *checkerBoard;
    UIImage *shadowBottom;
    UIImage *shadowTop;
    UIImage *shadowLeft;
    UIImage *shadowRight;
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
@property (nonatomic, retain) NSOperationQueue *fetchHighlightsQueue;
@property (nonatomic, retain) NSOperationQueue *renderThumbsQueue;
@property (nonatomic, retain) NSMutableDictionary *thumbCache;
@property (nonatomic, retain) NSDictionary *pageCropsCache;
@property (nonatomic, retain) NSDictionary *viewTransformsCache;
@property (nonatomic, retain) NSString *pdfPath;
@property (nonatomic, retain) UIImage *checkerBoard;
@property (nonatomic, retain) UIImage *shadowBottom;
@property (nonatomic, retain) UIImage *shadowTop;
@property (nonatomic, retain) UIImage *shadowLeft;
@property (nonatomic, retain) UIImage *shadowRight;

@end
