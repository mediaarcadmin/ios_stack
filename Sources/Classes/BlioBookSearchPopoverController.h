//
//  BlioBookSearchPopoverController.h
//  BlioApp
//
//  Created by matt on 10/09/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioModalPopoverController.h"
#import "BlioBookSearchToolbar.h"

@interface BlioBookSearchPopoverController : BlioModalPopoverController {
    UITableViewController *searchResultsController;
    UINavigationController *navigationController;
    BlioBookSearchToolbar *searchBar;
}

@end
