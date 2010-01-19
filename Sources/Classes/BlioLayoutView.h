//
//  BlioLayoutView.h
//  BlioApp
//
//  Created by matt on 18/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioBookView.h"
#import "MSTiltScroller.h"
#import <libEucalyptus/EucBookContentsTableViewController.h>

@class BlioPDFFontList;
@class BlioPDFParsedPage;
@class BlioPDFDebugView;
@class BlioPDFScrollView;
@class BlioPDFContainerScrollView;

@interface BlioLayoutView : UIView <UIScrollViewDelegate, BlioBookView, EucBookContentsTableViewControllerDataSource> {
    CGPDFDocumentRef pdf;
    BlioPDFContainerScrollView *scrollView;
    UIView *containerView;
    NSMutableArray *pageViews;
    id navigationController;
    NSInteger visiblePageIndex;
    BlioPDFFontList *fonts;
    BlioPDFParsedPage *parsedPage;
    BlioPDFDebugView *debugView;
    BlioPDFScrollView *currentPageView;
    BOOL scrollToPageInProgress;
    BOOL zoomPageInProgress;
    MSTiltScroller *tiltScroller;
    NSInteger pageNumber;
    NSInteger pageCount;
    CGFloat lastZoomScale;
}

@property (nonatomic, retain) BlioPDFContainerScrollView *scrollView;
@property (nonatomic, retain) UIView *containerView;
@property (nonatomic, retain) NSMutableArray *pageViews;
@property (nonatomic, assign) id navigationController;
@property (nonatomic, retain) BlioPDFScrollView *currentPageView;
@property (nonatomic, assign) MSTiltScroller *tiltScroller;
@property (nonatomic, retain) BlioPDFFontList *fonts;
@property (nonatomic, retain) BlioPDFParsedPage *parsedPage;
@property (nonatomic) BOOL scrollToPageInProgress;
@property (nonatomic) BOOL zoomPageInProgress;
@property (nonatomic, readonly) NSInteger pageNumber;

- (id)initWithPath:(NSString *)path;
- (id)initWithPath:(NSString *)path page:(NSUInteger)page animated:(BOOL)animated;
- (NSString *)parsedText;
- (void)displayDebug;

@end
