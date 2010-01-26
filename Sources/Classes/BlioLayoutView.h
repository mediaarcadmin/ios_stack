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
#import <libEucalyptus/EucHighlighter.h>

@class BlioPDFFontList;
@class BlioPDFParsedPage;
@class BlioPDFDebugView;
@class BlioPDFPageView;
@class BlioPDFContainerScrollView;

@interface BlioLayoutView : UIView <UIScrollViewDelegate, BlioBookView, EucBookContentsTableViewControllerDataSource, EucHighlighterDataSource> {
    BlioMockBook *book;
    CGPDFDocumentRef pdf;
    BlioPDFContainerScrollView *scrollView;
    UIView *containerView;
    NSMutableArray *pageViews;
    id navigationController;
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
    EucHighlighter *highlighter;
}

@property (nonatomic, retain) BlioMockBook *book;
@property (nonatomic, retain) BlioPDFContainerScrollView *scrollView;
@property (nonatomic, retain) UIView *containerView;
@property (nonatomic, retain) NSMutableArray *pageViews;
@property (nonatomic, assign) id navigationController;
@property (nonatomic, retain) BlioPDFPageView *currentPageView;
@property (nonatomic, assign) MSTiltScroller *tiltScroller;
@property (nonatomic, retain) BlioPDFFontList *fonts;
@property (nonatomic, retain) BlioPDFParsedPage *parsedPage;
@property (nonatomic) BOOL scrollToPageInProgress;
@property (nonatomic) BOOL disableScrollUpdating;
@property (nonatomic, readonly) NSInteger pageNumber;
@property (nonatomic, retain) EucHighlighter *highlighter;

- (void)displayDebug;
- (NSArray *)paragraphWordsForParagraphWithId:(uint32_t)paragraphId;

@end
