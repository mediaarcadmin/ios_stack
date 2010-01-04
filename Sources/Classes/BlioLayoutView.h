//
//  BlioLayoutView.h
//  BlioApp
//
//  Created by matt on 18/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioBookViewController.h"

@class BlioPDFFontList;
@class BlioPDFDebugView;

@interface BlioLayoutView : UIView <UIScrollViewDelegate, BlioBookView> {
    CGPDFDocumentRef pdf;
    UIScrollView *scrollView;
    NSMutableArray *pageViews;
    id navigationController;
    NSInteger visiblePageIndex;
    BlioPDFFontList *fonts;
    BlioPDFDebugView *debugView;
}

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) NSMutableArray *pageViews;
@property (nonatomic, assign) id navigationController;

- (id)initWithPath:(NSString *)path;

@end
