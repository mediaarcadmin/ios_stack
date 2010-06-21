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

@interface BlioStoreFeedTableViewDataSource : NSObject <UITableViewDataSource> {
    NSMutableArray *feeds;
}
@property (nonatomic, retain) NSMutableArray *feeds;
- (NSString *)getMoreCellLabelForSection:(NSUInteger) section;
@end

@interface BlioStoreCategoriesController : UITableViewController <BlioStoreBooksSourceParserDelegate> {
    id <BlioProcessingDelegate> processingDelegate;
	NSManagedObjectContext *managedObjectContext;
	UIActivityIndicatorView * activityIndicatorView;
	BlioStoreFeedTableViewDataSource * storeFeedTableViewDataSource;
}

@property (nonatomic, assign) id <BlioProcessingDelegate> processingDelegate;
@property (nonatomic, assign) NSMutableArray *feeds;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, readonly) BlioStoreFeedTableViewDataSource * storeFeedTableViewDataSource;

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath feed:(BlioStoreFeed*)feed;

@end

