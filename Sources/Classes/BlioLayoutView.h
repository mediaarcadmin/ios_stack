//
//  BlioLayoutView.h
//  BlioApp
//
//  Created by matt on 18/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BlioLayoutView : UIView <UIScrollViewDelegate> {
    CGPDFDocumentRef pdf;
    UIScrollView *scrollView;
    NSMutableArray *pageViews;
    id navigationController;
}

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) NSMutableArray *pageViews;
@property (nonatomic, assign) id navigationController;

- (id)initWithPath:(NSString *)path;
- (NSInteger)currentPageNumber;

@end
