//
//  BlioStoreGetBooksController.h
//  BlioApp
//
//  Created by matt on 05/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioStoreCategoriesController.h"

static const NSInteger kBlioStoreSearchTag = 2;

@class BlioStoreSearchTableView;

@interface BlioStoreSearchController : BlioStoreCategoriesController <UISearchBarDelegate> {
    NSString	*savedSearchTerm;
    UISearchBar *searchBar;
    UIView      *dimmingView;
    UILabel     *noResultsLabel;
    NSString    *noResultsMessage;
    UIBarButtonItem *doneButton;
    UIBarButtonItem *fillerButton;
    BlioStoreSearchTableView *dimmableTableView;
}

@property (nonatomic, retain) NSString *savedSearchTerm;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) UIView      *dimmingView;
@property (nonatomic, retain) UILabel     *noResultsLabel;
@property (nonatomic, retain) NSString    *noResultsMessage;
@property (nonatomic, retain) UIBarButtonItem *doneButton;
@property (nonatomic, retain) UIBarButtonItem *fillerButton;

@end
