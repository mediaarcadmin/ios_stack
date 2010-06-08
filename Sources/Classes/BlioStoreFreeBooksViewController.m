//
//  BlioStoreFreeBooksViewController.m
//  BlioApp
//
//  Created by Don Shin on 6/6/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "BlioStoreFreeBooksViewController.h"
#import "BlioStoreSearchController.h"

#define DONEBUTTONWIDTH 50

@implementation BlioStoreFreeBooksViewController

@synthesize searchBar,fillerButton,doneButton;

- (id)init {
    if ((self = [super init])) {
        
        // UIBarStyleDefault for a UISearchBar doesn't match UIBarStyleDefault for a UINavigationBar
        // This tint is pretty close, but both should be set to make it seamless
        UIColor *matchedTintColor = [UIColor colorWithHue:0.595 saturation:0.267 brightness:0.68 alpha:1];
        self.navigationController.navigationBar.tintColor = matchedTintColor;
        
        UITabBarItem* theItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Free Books",@"\"Free Books\" tab bar title") image:[UIImage imageNamed:@"icon-freebooks.png"] tag:kBlioStoreFreeBooksTag];
        self.tabBarItem = theItem;
        [theItem release];
        
        UISearchBar *aSearchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
        [aSearchBar setShowsCancelButton:NO];
        [aSearchBar setPlaceholder:NSLocalizedString(@"Search",@"\"Search\" placeholder text in Search bar")];
        [aSearchBar setTintColor:matchedTintColor];
        [aSearchBar setDelegate:self];
        [aSearchBar sizeToFit];
        [aSearchBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [self.navigationItem setTitleView:aSearchBar];
        self.searchBar = aSearchBar;
        [aSearchBar release];
		
        UIView *fillerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,DONEBUTTONWIDTH,self.searchBar.frame.size.height)];
        [fillerView setBackgroundColor:[UIColor clearColor]];
        UIBarButtonItem *filler = [[UIBarButtonItem alloc] initWithCustomView:fillerView];
        [fillerView release];
        self.fillerButton = filler;
        [filler release];
        
//        BlioStoreFeed *feedBooksFeed = [[BlioStoreFeed alloc] init];
//        [feedBooksFeed setTitle:@"Feedbooks"];
//        [feedBooksFeed setParserClass:[BlioStoreFeedBooksParser class]];
//        BlioStoreFeed *googleBooksFeed = [[BlioStoreFeed alloc] init];
//        [googleBooksFeed setTitle:@"Google Books"];
//        [googleBooksFeed setParserClass:[BlioStoreGoogleBooksParser class]];
//        [self setFeeds:[NSArray arrayWithObjects:feedBooksFeed, googleBooksFeed, nil]];
//        [feedBooksFeed release];
//        [googleBooksFeed release];
    }
    return self;
}

- (void)layoutSearchBar {
    CGRect searchBounds = self.searchBar.bounds;
    searchBounds.size.height = self.navigationController.navigationBar.frame.size.height;
    [self.searchBar setBounds:searchBounds];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self layoutSearchBar];
}


#pragma mark -
#pragma mark UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [super numberOfSectionsInTableView:tableView]+1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{ 
	if (section > 0) return [super tableView:tableView titleForHeaderInSection:section-1];
	return nil;
}



// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section > 0) return [super tableView:tableView numberOfRowsInSection:section-1];
	else return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    NSUInteger row = [indexPath row];
    NSUInteger section = [indexPath section];

	if (section > 0) return [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section-1]];
		
	static NSString *CategoryCellIdentifier = @"CategoryCell";

    UITableViewCell *cell;
	
	cell = [tableView dequeueReusableCellWithIdentifier:CategoryCellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CategoryCellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		//			cell.textLabel.font = [UIFont boldSystemFontOfSize:12.0]; // we'll use default size
	}
	cell.textLabel.text = NSLocalizedString(@"Browse Categories","\"Browse Categories\" cell label.");
	[cell setAccessibilityLabel:cell.textLabel.text];
	[cell setAccessibilityHint:nil];
	
	
	return cell;
}

#pragma mark -
#pragma mark UITableViewController Delegate Methods


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    NSUInteger row = [indexPath row];
    NSUInteger section = [indexPath section];
	
	if (section > 0) {
		[super tableView:tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section-1]];
		return;
	}

	BlioStoreCategoriesController* vc2 = [[BlioStoreCategoriesController alloc] init];
	[vc2 setManagedObjectContext:self.managedObjectContext];
	NSURL *feedbooksFeedURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"feedbooks" ofType:@"atom" inDirectory:@"Feeds"]];
	BlioStoreFeed *feedBooksFeed = [[BlioStoreFeed alloc] init];
	[feedBooksFeed setTitle:@"Feedbooks"];
	[feedBooksFeed setFeedURL:feedbooksFeedURL];
	[feedBooksFeed setParserClass:[BlioStoreLocalParser class]];
	feedBooksFeed.sourceID = BlioBookSourceFeedbooks;
	NSURL *googleFeedURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"googlebooks" ofType:@"atom" inDirectory:@"Feeds"]];
	BlioStoreFeed *googleBooksFeed = [[BlioStoreFeed alloc] init];
	[googleBooksFeed setTitle:@"Google Books"];
	[googleBooksFeed setFeedURL:googleFeedURL];
	[googleBooksFeed setParserClass:[BlioStoreLocalParser class]];
	googleBooksFeed.sourceID = BlioBookSourceGoogleBooks;
	[vc2 setFeeds:[NSArray arrayWithObjects:feedBooksFeed, googleBooksFeed, nil]];
	[feedBooksFeed release];
	[googleBooksFeed release];
	
	[vc2 setProcessingDelegate:self.processingDelegate];
	[vc2.navigationItem setRightBarButtonItem:self.navigationItem.rightBarButtonItem];	

	[self.navigationController pushViewController:vc2 animated:YES];
	[vc2 release];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark UISearch Delegate Methods



- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.doneButton = self.navigationItem.rightBarButtonItem;
    [self.navigationItem setRightBarButtonItem:self.fillerButton animated:YES];
    [self performSelector:@selector(hideDoneButton) withObject:nil afterDelay:0.35f];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [self.navigationItem setRightBarButtonItem:self.doneButton animated:YES];
    [UIView beginAnimations:@"showDoneButton" context:nil];
    [UIView setAnimationDuration:0.35f];
    [self.searchBar sizeToFit];
    [self layoutSearchBar];
    [UIView commitAnimations];
}

- (void)hideDoneButton {
    [UIView beginAnimations:@"hideDoneButton" context:nil];
    [UIView setAnimationDuration:0.35f];
    [self.navigationItem setRightBarButtonItem:nil animated:NO];
    [self.searchBar sizeToFit];
    [self layoutSearchBar];
    [UIView commitAnimations];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar {
	BlioStoreSearchController* vc3 = [[BlioStoreSearchController alloc] init];
	[vc3 setManagedObjectContext:self.managedObjectContext];
	[vc3 setProcessingDelegate:self.processingDelegate];
	
	UITabBarItem* theItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Free Books",@"\"Free Books\" tab bar title") image:[UIImage imageNamed:@"icon-freebooks.png"] tag:kBlioStoreFreeBooksTag];
	vc3.tabBarItem = theItem;
	[theItem release];
	
    [self.searchBar resignFirstResponder];

	vc3.savedSearchTerm = self.searchBar.text;
	vc3.searchBar.text = self.searchBar.text;
    [self.navigationController setViewControllers:[NSArray arrayWithObject:vc3] animated:NO];
	[vc3.navigationItem setRightBarButtonItem:self.navigationItem.rightBarButtonItem];	
	[vc3 searchBarSearchButtonClicked:vc3.searchBar];
	[vc3 release];
}

@end
