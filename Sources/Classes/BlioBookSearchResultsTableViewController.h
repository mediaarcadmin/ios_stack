//
//  BlioBookSearchResultsTableViewController.h
//  BlioApp
//
//  Created by matt on 11/09/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioBookSearchStatus.h"
#import "BlioAutorotatingViewController.h"

@class BlioBookSearchResultsTableViewController, BlioBookSearchStatusView, BlioBookmarkPoint, BlioBookSearchResult;

@protocol BlioBookSearchResultsDelegate

- (void)resultsController:(BlioBookSearchResultsTableViewController *)resultsController didSelectResultAtIndex:(NSUInteger)index;
- (void)resultsControllerDidContinueSearch:(BlioBookSearchResultsTableViewController *)resultsController;

@end

@protocol BlioBookSearchResultsFormatter

- (NSString *)displayPageNumberForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;

@end

@interface BlioBookSearchResultsTableViewController : BlioAutorotatingTableViewController {
    NSMutableArray *searchResults;
    BlioBookSearchStatusView *statusView;
    UIView *dimmingView;
    
    id <BlioBookSearchResultsDelegate> resultsDelegate;
    id <BlioBookSearchResultsFormatter> resultsFormatter;
}

@property (nonatomic, assign) id <BlioBookSearchResultsDelegate> resultsDelegate;
@property (nonatomic, assign) id <BlioBookSearchResultsFormatter> resultsFormatter;
@property (nonatomic, retain) NSMutableArray *searchResults;

- (void)setSearchStatus:(BlioBookSearchStatus)newStatus;
- (void)addResult:(BlioBookSearchResult *)result;

@end
