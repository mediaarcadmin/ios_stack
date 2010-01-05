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
@class BlioPDFDebugView;
@class BlioPDFScrollView;

@interface BlioLayoutView : UIView <UIScrollViewDelegate, BlioBookView, EucBookContentsTableViewControllerDataSource> {
    CGPDFDocumentRef pdf;
    UIScrollView *scrollView;
    NSMutableArray *pageViews;
    id navigationController;
    NSInteger visiblePageIndex;
    BlioPDFFontList *fonts;
    BlioPDFDebugView *debugView;
    BlioPDFScrollView *currentPageView;
    BOOL scrollToPageInProgress;
    MSTiltScroller *tiltScroller;
}

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) NSMutableArray *pageViews;
@property (nonatomic, assign) id navigationController;
@property (nonatomic, retain) BlioPDFScrollView *currentPageView;
@property (nonatomic, assign) MSTiltScroller *tiltScroller;
@property (retain) BlioPDFFontList *fonts;
@property (nonatomic) BOOL scrollToPageInProgress;

- (id)initWithPath:(NSString *)path;

@end
