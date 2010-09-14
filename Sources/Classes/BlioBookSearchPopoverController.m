    //
//  BlioBookSearchPopoverController.m
//  BlioApp
//
//  Created by matt on 10/09/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioBookSearchPopoverController.h"

@interface BlioBookSearchPopoverController()

@property (nonatomic, retain) UITableViewController *searchResultsController;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) BlioBookSearchToolbar *searchBar;

@end

@implementation BlioBookSearchPopoverController

@synthesize searchResultsController, navigationController, searchBar;

- (void)dealloc {
    self.searchResultsController = nil;
    self.navigationController = nil;
    self.searchBar = nil;
    [super dealloc];
}

- (id)init {
    
    UITableViewController *aSearchResultsController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:aSearchResultsController];
    
    if ((self = [super initWithContentViewController:aNavigationController])) {
        self.searchResultsController = aSearchResultsController;
        self.navigationController = aNavigationController;
        
        BlioBookSearchToolbar *aSearchBar = [[BlioBookSearchToolbar alloc] init];
        [aSearchBar setFrame:self.navigationController.navigationBar.bounds];
        [self.navigationController.navigationBar addSubview:aSearchBar];
        self.searchBar = aSearchBar;
        [aSearchBar release];
        
        self.popoverContentSize = CGSizeMake(320, 75 + 88);
    }
    
    [aSearchResultsController release];
    [aNavigationController release];
    return self;
}
/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

@end
