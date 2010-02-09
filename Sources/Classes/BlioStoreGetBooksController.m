//
//  BlioStoreGetBooksController.m
//  BlioApp
//
//  Created by matt on 05/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioStoreGetBooksController.h"


@implementation BlioStoreGetBooksController

@synthesize savedSearchTerm, savedScopeButtonIndex, searchWasActive, searchDisplayController;

- (void)dealloc {
    self.savedSearchTerm = nil;
    self.searchDisplayController = nil;
    [super dealloc];
}

- (id)init {
    if ((self = [super initWithStyle:UITableViewStylePlain])) {
        self.title = @"Get Books";
        
        // UIBarStyleDefault for a UISearchBar doesn't match UIBarStyleDefault for a UINavigationBar
        // This tint is pretty close, but both should be set to make it seamless
        UIColor *matchedTintColor = [UIColor colorWithHue:0.595 saturation:0.267 brightness:0.68 alpha:1];
        self.navigationController.navigationBar.tintColor = matchedTintColor;
        
        UITabBarItem* theItem = [[UITabBarItem alloc] initWithTitle:@"Get Books" image:nil tag:kBlioStoreGetBooksTag];
        self.tabBarItem = theItem;
        [theItem release];
        
        UISearchBar *aSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0,0,320,43)];
        //[aSearchBar setTintColor:[UIColor colorWithRed:0.437 green:0.518 blue:0.635 alpha:1.0f]];
        [aSearchBar setShowsCancelButton:NO];
        [aSearchBar setTintColor:matchedTintColor];
        //[aSearchBar sizeToFit];
        //UIBarButtonItem *aSearchButton = [[UIBarButtonItem alloc] initWithCustomView:aSearchBar];
        //[self.navigationItem setLeftBarButtonItem:aSearchButton];
        //[aSearchButton release];
        [self.navigationItem setTitleView:aSearchBar];
        UISearchDisplayController *aSearchDisplayController = [[UISearchDisplayController alloc]
                                                               initWithSearchBar:aSearchBar contentsController:self];
        aSearchDisplayController.delegate = self;
        aSearchDisplayController.searchResultsDataSource = self;
        aSearchDisplayController.searchResultsDelegate = self;
        [aSearchDisplayController setActive:YES animated:NO];
        self.searchDisplayController = aSearchDisplayController;
        [aSearchDisplayController release];
        [aSearchBar setShowsCancelButton:NO];
        [aSearchBar becomeFirstResponder];
        [aSearchBar release];
    }
    return self;
}
/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

- (void)viewDidLoad
{

	// restore search settings if they were saved in didReceiveMemoryWarning.
    if (self.savedSearchTerm)
	{
        [self.searchDisplayController setActive:self.searchWasActive];
        [self.searchDisplayController.searchBar setSelectedScopeButtonIndex:self.savedScopeButtonIndex];
        [self.searchDisplayController.searchBar setText:savedSearchTerm];
        
        
        self.savedSearchTerm = nil;
    }
	
	[self.tableView reloadData];
	self.tableView.scrollEnabled = YES;
}

- (void)viewDidUnload
{
	// Save the state of the search UI so that it can be restored if the view is re-created.
    self.searchWasActive = [self.searchDisplayController isActive];
    self.savedSearchTerm = [self.searchDisplayController.searchBar text];
    self.savedScopeButtonIndex = [self.searchDisplayController.searchBar selectedScopeButtonIndex];	
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return 2;
    else
        return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{ 
    
	switch (section) 
	{ 
		case 0: 
			return @"Feedbooks"; 
		case 1: 
			return @"Google Books"; 
		default: 
			return @""; 
	}
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    /*
	 If the requesting table view is the search display controller's table view, return the count of the filtered list, otherwise return the count of the main list.
	 */
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        //return [self.filteredListContent count];
        switch (section) 
        { 
            case 0: 
                return 2; 
            case 1: 
                return 1; 
            default: 
                return 0; 
        } 
    }
	else
	{
        return 0;
        //return [self.listContent count];
        switch (section) 
        { 
            case 0: 
                return 7; 
            case 1: 
                return 10; 
            default: 
                return 0; 
        } 
    }
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    // Set up the cell..
    /*
	 If the requesting table view is the search display controller's table view, configure the cell using the filtered content, otherwise use the main list.
	 */
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        cell.textLabel.text = @"Filtered Book";
    }
	else
	{
        cell.textLabel.text = @"Book";
    }
	
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
    UIViewController *detailsViewController = [[UIViewController alloc] init];
    
    /*
	 If the requesting table view is the search display controller's table view, configure the next view controller using the filtered content, otherwise use the main list.
	 */
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        detailsViewController.title = @"Filtered Book";
    }
	else
	{
        detailsViewController.title = @"Book";
    }
    detailsViewController.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
    
    [[self navigationController] pushViewController:detailsViewController animated:YES];
    [detailsViewController release];
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark -
#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
#if 0    
	/*
	 Update the filtered array based on the search text and scope.
	 */
	
	[self.filteredListContent removeAllObjects]; // First clear the filtered array.
	
	/*
	 Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
	 */
	for (Product *product in listContent)
	{
		if ([scope isEqualToString:@"All"] || [product.type isEqualToString:scope])
		{
			NSComparisonResult result = [product.name compare:searchText options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) range:NSMakeRange(0, [searchText length])];
            if (result == NSOrderedSame)
			{
				[self.filteredListContent addObject:product];
            }
		}
	}
#endif
}

#pragma mark -
#pragma mark UISearch Delegate Methods
//
//- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
//    return NO;
//}

//- (void) searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
//    return;
//}

- (void) searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    [controller setActive:YES animated:NO];
}
    
- (void) searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
    [controller setActive:YES animated:NO];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


@end

