//
//  BlioStoreGetBooksController.h
//  BlioApp
//
//  Created by matt on 05/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>

static const NSInteger kBlioStoreGetBooksTag = 2;

@interface BlioStoreGetBooksController : UITableViewController <UISearchDisplayDelegate, UISearchBarDelegate> {
    // The saved state of the search UI if a memory warning removed the view.
    NSString		*savedSearchTerm;
    NSInteger		savedScopeButtonIndex;
    BOOL			searchWasActive;
    UISearchDisplayController *searchDisplayController;
}

@property (nonatomic, retain) NSString *savedSearchTerm;
@property (nonatomic) NSInteger savedScopeButtonIndex;
@property (nonatomic) BOOL searchWasActive;
@property (nonatomic, retain) UISearchDisplayController *searchDisplayController;

@end
