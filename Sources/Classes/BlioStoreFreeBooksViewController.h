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

@interface BlioStoreFreeBooksTableViewDataSource : BlioStoreFeedTableViewDataSource {
	
}

@end

@interface BlioStoreSearchTableViewDataSource : BlioStoreFeedTableViewDataSource {
	
}

@end

@interface BlioStoreFreeBooksViewController : BlioStoreCategoriesController <UISearchBarDelegate,UISearchDisplayDelegate> {
    UIBarButtonItem *doneButton;
    UISearchBar *searchBar;

	// The saved state of the search UI if a memory warning removed the view.
    NSString		*savedSearchTerm;
    NSInteger		savedScopeButtonIndex;
    BOOL			searchWasActive;
	
	UISearchDisplayController * aSearchDisplayController;
	BlioStoreFeedTableViewDataSource * storeSearchTableViewDataSource;
	BOOL resultsDisplayed;
}
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) UIBarButtonItem *doneButton;

@property (nonatomic, copy) NSString *savedSearchTerm;
@property (nonatomic, assign) NSInteger savedScopeButtonIndex;
@property (nonatomic, assign) BOOL searchWasActive;

@property (nonatomic, retain) UISearchDisplayController *aSearchDisplayController;
@property (nonatomic, readonly) BlioStoreFeedTableViewDataSource * storeSearchTableViewDataSource;

-(void)performSearch;

@end
