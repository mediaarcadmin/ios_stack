//
//  BlioBookSearchPopoverController.h
//  BlioApp
//
//  Created by matt on 10/09/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioModalPopoverController.h"
#import "BlioBookView.h"
#import "BlioBookSearchStatus.h"
#import "BlioBookSearchController.h"

@class BlioBookSearchToolbar, BlioBookSearchResultsTableViewController;

@interface BlioBookSearchPopoverController : BlioModalPopoverController <BlioBookSearchDelegate> {
    BlioBookSearchResultsTableViewController *resultsController;
    UINavigationController *navigationController;
    BlioBookSearchToolbar *toolbar;
    
    BlioBookSearchController *bookSearchController;
    id <BlioBookView> bookView;
    
    BlioBookSearchStatus searchStatus;
    NSInteger currentSearchResult;
    NSTimeInterval resultsInterval;
}

@property (nonatomic, retain) BlioBookSearchController *bookSearchController;
@property (nonatomic, assign) id <BlioBookView> bookView;

- (BOOL)isSearchActive;

@end
