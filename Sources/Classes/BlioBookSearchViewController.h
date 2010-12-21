//
//  BlioBookSearchViewController.h
//  BlioApp
//
//  Created by matt on 07/06/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioBookSearchController.h"
#import "BlioBookSearchToolbar.h"
#import "BlioBookView.h"
#import "BlioBookSearchStatus.h"
#import "BlioBookSearchResultsTableViewController.h"

@interface BlioBookSearchViewController : UIViewController <BlioBookSearchToolbarDelegate, BlioBookSearchDelegate, BlioBookSearchResultsDelegate, BlioBookSearchResultsFormatter> {
    BlioBookSearchResultsTableViewController *resultsController;
    BlioBookSearchToolbar *toolbar;
    BlioBookSearchController *bookSearchController;
    
    UINavigationController *navController;
    id <BlioBookView> bookView;
    
    UIColor *tintColor;
    
    BlioBookSearchStatus searchStatus;
    NSInteger currentSearchResult;
    NSTimeInterval resultsInterval;
}

@property (nonatomic, retain) BlioBookSearchToolbar *toolbar;
@property (nonatomic, retain) BlioBookSearchController *bookSearchController;
@property (nonatomic, assign) id <BlioBookView> bookView;

@property (nonatomic, retain) UIColor *tintColor;
@property (nonatomic, getter=isToolbarHidden) BOOL toolbarHidden; // Defaults to YES, i.e. hidden.

- (void)showInController:(UINavigationController *)controller animated:(BOOL)animated;
- (void)removeFromControllerAnimated:(BOOL)animated;
- (BOOL)isSearchInline;

@end
