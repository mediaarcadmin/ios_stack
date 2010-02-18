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

@class BlioPDFFontList;
@class BlioPDFParsedPage;
@class BlioPDFDebugView;
@class BlioPDFPageView;
@class BlioPDFContainerScrollView;

@interface BlioLayoutView : UIView <UIScrollViewDelegate, BlioBookView, BlioTTSDataSource, EucBookContentsTableViewControllerDataSource, EucSelectorDataSource, EucSelectorDelegate> {
    id<BlioBookDelegate> delegate;
    BlioMockBook *book;
    CGPDFDocumentRef pdf;
    BlioPDFContainerScrollView *scrollView;
    UIView *containerView;
    NSMutableArray *pageViews;
    NSInteger visiblePageIndex;
    BlioPDFFontList *fonts;
    BlioPDFParsedPage *parsedPage;
    BlioPDFDebugView *debugView;
    BlioPDFPageView *currentPageView;
    BOOL scrollToPageInProgress;
    BOOL disableScrollUpdating;
    MSTiltScroller *tiltScroller;
    NSInteger pageNumber;
    NSInteger pageCount;
    CGFloat lastZoomScale;
    CALayer *sharpLayer;
    EucSelector *selector;
    UIColor *lastHighlightColor;
}

@property (nonatomic, assign) id<BlioBookDelegate> delegate;
@property (nonatomic, retain) BlioMockBook *book;
@property (nonatomic, retain) BlioPDFContainerScrollView *scrollView;
@property (nonatomic, retain) UIView *containerView;
@property (nonatomic, retain) NSMutableArray *pageViews;
@property (nonatomic, retain) BlioPDFPageView *currentPageView;
@property (nonatomic, assign) MSTiltScroller *tiltScroller;
@property (nonatomic, retain) BlioPDFFontList *fonts;
@property (nonatomic, retain) BlioPDFParsedPage *parsedPage;
@property (nonatomic) BOOL scrollToPageInProgress;
@property (nonatomic) BOOL disableScrollUpdating;
@property (nonatomic, readonly) NSInteger pageNumber;
@property (nonatomic, retain) EucSelector *selector;
@property (nonatomic, retain) UIColor *lastHighlightColor;

@end
