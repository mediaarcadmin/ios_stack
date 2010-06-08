//
//  BlioStoreFreeBooksViewController.h
//  BlioApp
//
//  Created by Don Shin on 6/6/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioStoreCategoriesController.h"

static const NSInteger kBlioStoreFreeBooksTag = 1;

@interface BlioStoreFreeBooksViewController : BlioStoreCategoriesController <UISearchBarDelegate> {
    UIBarButtonItem *doneButton;
    UISearchBar *searchBar;
    UIBarButtonItem *fillerButton;

}
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) UIBarButtonItem *doneButton;
@property (nonatomic, retain) UIBarButtonItem *fillerButton;

@end
