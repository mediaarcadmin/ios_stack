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

@interface BlioBookSearchViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, BlioBookSearchToolbarDelegate, BlioBookSearchDelegate> {
    UITableView *tableView;
    BlioBookSearchToolbar *toolbar;
    BlioBookSearchController *bookSearchController;
    UISearchDisplayController *searchController;
    NSMutableArray *searchResults;
    NSString *savedSearchTerm;
    UILabel *noResultsLabel;
    NSString *noResultsMessage;
    UIColor *tintColor;
    UINavigationController *navController;
    BOOL searchActive;
    NSInteger currentSearchResult;
    id <BlioBookView> bookView;
}

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) BlioBookSearchToolbar *toolbar;
@property (nonatomic, retain) BlioBookSearchController *bookSearchController;
@property (nonatomic, retain) UISearchDisplayController *searchController;
@property (nonatomic, retain) NSMutableArray *searchResults;
@property (nonatomic, retain) NSString *savedSearchTerm;
@property (nonatomic, retain) UILabel *noResultsLabel;
@property (nonatomic, retain) NSString *noResultsMessage;
@property (nonatomic, retain) UIColor *tintColor;
@property (nonatomic, getter=isToolbarHidden) BOOL toolbarHidden; // Defaults to YES, i.e. hidden.
@property (nonatomic, readonly, getter=isSearchActive) BOOL searchActive;
@property (nonatomic, assign) id <BlioBookView> bookView;

- (void)showInController:(UINavigationController *)controller animated:(BOOL)animated;
- (void)removeFromControllerAnimated:(BOOL)animated;

@end
