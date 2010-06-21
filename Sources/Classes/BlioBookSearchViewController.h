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

@interface BlioBookSearchViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, BlioBookSearchToolbarDelegate, BlioBookSearchDelegate> {
    UITableView *tableView;
    BlioBookSearchToolbar *searchToolbar;
    BlioBookSearchController *bookSearchController;
    UISearchDisplayController *searchController;
    NSMutableArray *searchResults;
    NSString *savedSearchTerm;
    UILabel *noResultsLabel;
    NSString *noResultsMessage;
}

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) BlioBookSearchToolbar *searchToolbar;
@property (nonatomic, retain) BlioBookSearchController *bookSearchController;
@property (nonatomic, retain) UISearchDisplayController *searchController;
@property (nonatomic, retain) NSMutableArray *searchResults;
@property (nonatomic, retain) NSString *savedSearchTerm;
@property (nonatomic, retain) UILabel *noResultsLabel;
@property (nonatomic, retain) NSString *noResultsMessage;

- (void)setTintColor:(UIColor *)tintColor;

@end
