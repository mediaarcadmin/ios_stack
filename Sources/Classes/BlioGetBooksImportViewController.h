//
//  BlioGetBooksImportViewController.h
//  BlioApp
//
//  Created by Don Shin on 10/7/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioRoundedRectActivityView.h"
#import "BlioAutorotatingViewController.h"

static const NSInteger kBlioImportBookCellActivityIndicatorViewTag = 99;
static const NSInteger kBlioImportBookCellActivityIndicatorViewWidth = 20;

@protocol BlioProcessingDelegate;

static const NSInteger kBlioGetBooksImportTag = 4;

@interface BlioGetBooksImportViewController : BlioAutorotatingTableViewController {
	BlioRoundedRectActivityView * activityIndicatorView;
	NSMutableArray * importableBooks;
	id<BlioProcessingDelegate> _processingDelegate;
}
@property (nonatomic,retain) BlioRoundedRectActivityView* activityIndicatorView;
@property (nonatomic,retain) NSMutableArray * importableBooks;
@property (nonatomic, assign) id <BlioProcessingDelegate> processingDelegate;

@end
