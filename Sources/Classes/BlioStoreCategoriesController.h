//
//  BlioStoreCategoriesController.h
//  BlioApp
//
//  Created by matt on 05/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioStoreFeed.h"
#import <CoreData/CoreData.h>

static const NSInteger kBlioStoreCategoriesTag = 1;
static const NSInteger kBlioMoreResultsCellActivityIndicatorViewTag = 99;
static const NSInteger kBlioMoreResultsCellActivityIndicatorViewWidth = 16;

@protocol BlioProcessingDelegate;

@interface BlioStoreCategoriesController : UITableViewController <BlioStoreBooksSourceParserDelegate> {
    NSMutableArray *feeds;
    id <BlioProcessingDelegate> processingDelegate;
	NSManagedObjectContext *managedObjectContext;
	UIActivityIndicatorView * activityIndicatorView;
}

@property (nonatomic, retain) NSMutableArray *feeds;
@property (nonatomic, assign) id <BlioProcessingDelegate> processingDelegate;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicatorView;

@end
