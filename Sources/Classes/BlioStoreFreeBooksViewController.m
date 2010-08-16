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

@synthesize searchBar,doneButton, savedSearchTerm, savedScopeButtonIndex, searchWasActive, aSearchDisplayController;

- (id)init {
    if ((self = [super init])) {
        
        // UIBarStyleDefault for a UISearchBar doesn't match UIBarStyleDefault for a UINavigationBar
        // This tint is pretty close, but both should be set to make it seamless
        
        UITabBarItem* theItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Free Books",@"\"Free Books\" tab bar title") image:[UIImage imageNamed:@"icon-freebooks.png"] tag:kBlioStoreFreeBooksTag];
        self.tabBarItem = theItem;
        [theItem release];
		resultsDisplayed = NO;
    }
    return self;
}
-(void) dealloc {
	if (storeSearchTableViewDataSource) [storeSearchTableViewDataSource release];
	self.searchBar = nil;
	self.doneButton = nil;
	self.aSearchDisplayController = nil;
	[super dealloc];
}
-(BlioStoreFeedTableViewDataSource*)storeFeedTableViewDataSource {
	if (!storeFeedTableViewDataSource) storeFeedTableViewDataSource = [[BlioStoreFreeBooksTableViewDataSource alloc] init];
	return storeFeedTableViewDataSource;
}

-(BlioStoreFeedTableViewDataSource*)storeSearchTableViewDataSource {
	if (!storeSearchTableViewDataSource) {
		storeSearchTableViewDataSource = [[BlioStoreSearchTableViewDataSource alloc] init];
		BlioStoreFeed *feedBooksFeed = [[BlioStoreFeed alloc] init];
        [feedBooksFeed setTitle:@"Feedbooks"];
        [feedBooksFeed setParserClass:[BlioStoreFeedBooksParser class]];
        BlioStoreFeed *googleBooksFeed = [[BlioStoreFeed alloc] init];
        [googleBooksFeed setTitle:@"Google Books"];
        [googleBooksFeed setParserClass:[BlioStoreGoogleBooksParser class]];
        [storeSearchTableViewDataSource setFeeds:[NSArray arrayWithObjects:feedBooksFeed, googleBooksFeed, nil]];
        [feedBooksFeed release];
        [googleBooksFeed release];
	}
	return storeSearchTableViewDataSource;
}
-(void)loadView {
	[super loadView];
	
	self.searchBar = [[[UISearchBar alloc] initWithFrame:CGRectZero] autorelease];
//	[self.searchBar setShowsCancelButton:YES];
	[self.searchBar setPlaceholder:NSLocalizedString(@"Search",@"\"Search\" placeholder text in Search bar")];
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
		UIColor *matchedTintColor = [UIColor colorWithHue:0.595 saturation:0.267 brightness:0.68 alpha:1];
		self.navigationController.navigationBar.tintColor = matchedTintColor;
		[self.searchBar setTintColor:matchedTintColor];
	}
#else
	UIColor *matchedTintColor = [UIColor colorWithHue:0.595 saturation:0.267 brightness:0.68 alpha:1];
	self.navigationController.navigationBar.tintColor = matchedTintColor;
	[self.searchBar setTintColor:matchedTintColor];
#endif
	
	[self.searchBar setDelegate:self];
	[self.searchBar sizeToFit];
	[self.searchBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
	//        [self.navigationItem setTitleView:self.searchBar];
	
	self.tableView.tableHeaderView = self.searchBar;
	self.aSearchDisplayController = [[[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self] autorelease];
	aSearchDisplayController.delegate = self;
	aSearchDisplayController.searchResultsDataSource = self.storeSearchTableViewDataSource;
	aSearchDisplayController.searchResultsDelegate = self;
	
}
-(void)viewDidLoad {
	[super viewDidLoad];

}
- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    // save the state of the search UI so that it can be restored if the view is re-created
    self.searchWasActive = [self.searchDisplayController isActive];
    NSLog(@"self.searchBar: %@",self.searchBar);
	NSLog(@"self.searchBar.text: %@",self.searchBar.text);
	self.savedSearchTerm = self.searchBar.text;
//    self.savedScopeButtonIndex = [self.searchDisplayController.searchBar selectedScopeButtonIndex];
}

#pragma mark -
#pragma mark UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSUInteger row = [indexPath row];
    NSUInteger section = [indexPath section];

	if (tableView == self.searchDisplayController.searchResultsTableView) {
		NSMutableArray * contentFeeds = [NSMutableArray array];
		for (BlioStoreFeed * aFeed in self.storeSearchTableViewDataSource.feeds) {
			if ([aFeed.categories count] || [aFeed.entities count]) [contentFeeds addObject:aFeed];
		}
		BlioStoreFeed *feed = [contentFeeds objectAtIndex:section];
		[self tableView:tableView didSelectRowAtIndexPath:indexPath feed:feed];
		return;
	}
	
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
	
	vc2.detailViewController = self.detailViewController;

	[vc2.navigationItem setRightBarButtonItem:self.navigationItem.rightBarButtonItem];	

	[self.navigationController pushViewController:vc2 animated:YES];
	[vc2 release];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods
- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
	resultsDisplayed = NO;
}
- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    for (BlioStoreFeed *feed in self.storeSearchTableViewDataSource.feeds) {
        [feed.categories removeAllObjects];
        [feed.entities removeAllObjects];
    }
}
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{   
	if (!resultsDisplayed) {
		// TODO: Check if difference between OS versions, or between device idioms.
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//		if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 3.2) {
			[controller.searchResultsTableView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.5]];
		}
		else {
			[controller.searchResultsTableView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.8]];
		}
		[controller.searchResultsTableView setRowHeight:2009];
	}	
    // Return YES to cause the search result table view to be reloaded.
    return NO;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{    
    // Return YES to cause the search result table view to be reloaded.
    return NO;
}
//- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView {
//	[self.activityIndicatorView removeFromSuperview];
//}
//- (void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView {
//	[tableView addSubview:self.activityIndicatorView];
//}
- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView {
	NSLog(@"willHideSearchResultsTableView entered");
	[self.activityIndicatorView removeFromSuperview];
	resultsDisplayed = NO;
	for (BlioStoreFeed *feed in self.storeSearchTableViewDataSource.feeds) {
        [feed.categories removeAllObjects];
        [feed.entities removeAllObjects];
    }
    [self.searchDisplayController.searchResultsTableView reloadData];
}
- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView {
	NSLog(@"didHideSearchResultsTableView entered");
	[self.view addSubview:self.activityIndicatorView];
}

#pragma mark -
#pragma mark UISearch Delegate Methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {

}

//
//- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
//    [self.navigationItem setRightBarButtonItem:self.doneButton animated:YES];
//    [UIView beginAnimations:@"showDoneButton" context:nil];
//    [UIView setAnimationDuration:0.35f];
//    [self.searchBar sizeToFit];
//    [self layoutSearchBar];
//    [UIView commitAnimations];
//}

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar {
	self.savedSearchTerm = aSearchBar.text;
	resultsDisplayed = YES;
    [self performSearch];
    [self.searchBar resignFirstResponder];
}
#pragma mark -
#pragma mark Search-Specific Methods

- (void)performSearch {
	NSLog(@"performSearch entered");
    if (![self.storeSearchTableViewDataSource.feeds count]) return;
	
	[activityIndicatorView startAnimating];
	activityIndicatorView.hidden = NO;
	
    for (BlioStoreFeed *feed in self.storeSearchTableViewDataSource.feeds) {
        [feed.categories removeAllObjects];
        [feed.entities removeAllObjects];
        if (nil != feed.parserClass) {
            feed.parser = nil;
            @try {
                BlioStoreBooksSourceParser* aParser = [[feed.parserClass alloc] init];
                feed.parser = aParser;
                [aParser release];
            }
            @catch (NSException * e) {
                NSLog(@"Warning: BlioStore couldn't create Parser of class: %@", feed.parserClass);
            }
        }
        
        if (feed.parser && self.searchBar.text) {
            NSURL *queryUrl = [feed.parser queryUrlForString:self.searchBar.text];
            feed.parser.delegate = self;
            if (nil != queryUrl) [feed.parser startWithURL:queryUrl];
        }
    }    
}

#pragma mark <BlioStoreFeedBooksParserDelegate> Implementation

- (void)parserDidEndParsingData:(BlioStoreBooksSourceParser *)parser {
	NSLog(@"BlioStoreFreeBooksViewController parserDidEndParsingData entered. parser: %@",parser);
	NSArray * currentModeFeeds = nil;
	if (self.searchDisplayController.active) {
		currentModeFeeds = self.storeSearchTableViewDataSource.feeds;
	}
	else currentModeFeeds = self.feeds;
	BOOL stillParsing = NO;
	for (BlioStoreFeed *feed in currentModeFeeds) {
		if (feed.parser.isParsing) {
			stillParsing = YES;
			break;
		}
	}
	if (!stillParsing) {
		NSLog(@"stillParsing is NO, hiding UIActivityIndicator");
		// hide UIActivityIndicator
		[activityIndicatorView stopAnimating];
		activityIndicatorView.hidden = YES;
		if (self.searchDisplayController.active) {
			[activityIndicatorView removeFromSuperview];
			[self.searchDisplayController.searchResultsTableView addSubview:self.activityIndicatorView];
		}
	}
	
	if (self.searchDisplayController.active) {
		// prepare it to appear on the searchResultsTableView for subsequent searches
		
		[self.searchDisplayController.searchResultsTableView reloadData];
		[self.searchDisplayController.searchResultsTableView setBackgroundColor:[UIColor whiteColor]];
		[self.searchDisplayController.searchResultsTableView setRowHeight:44];
	}
		else [self.tableView reloadData];
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)parser:(BlioStoreBooksSourceParser *)parser didParseTotalResults:(NSNumber *)volumeTotalResults {
    
    for (BlioStoreFeed *feed in self.feeds) {
        if ([feed.parser isEqual:parser])
            if (volumeTotalResults) feed.totalResults = [volumeTotalResults unsignedIntegerValue];
    }
    for (BlioStoreFeed *feed in self.storeSearchTableViewDataSource.feeds) {
        if ([feed.parser isEqual:parser])
            if (volumeTotalResults) feed.totalResults = [volumeTotalResults unsignedIntegerValue];
    }
    // table reloading will be handled when the categories and/or entities are parsed
}

- (void)parser:(BlioStoreBooksSourceParser *)parser didParseNextLink:(NSURL *)nextLink {
    
    for (BlioStoreFeed *feed in self.feeds) {
        if ([feed.parser isEqual:parser]) {
            feed.nextURL = nextLink;
		}
    }
    for (BlioStoreFeed *feed in self.storeSearchTableViewDataSource.feeds) {
        if ([feed.parser isEqual:parser]) {
            feed.nextURL = nextLink;
		}
    }
    // table reloading will be handled when the categories and/or entities are parsed
}
- (void)parser:(BlioStoreBooksSourceParser *)parser didParseIdentifier:(NSString *)identifier {
    
    for (BlioStoreFeed *feed in self.feeds) {
        if ([feed.parser isEqual:parser]) {
            feed.id = identifier;
		}
    }
    for (BlioStoreFeed *feed in self.storeSearchTableViewDataSource.feeds) {
        if ([feed.parser isEqual:parser]) {
            feed.id = identifier;
		}
    }
    // table reloading will be handled when the categories and/or entities are parsed
}


- (void)parser:(BlioStoreBooksSourceParser *)parser didParseCategories:(NSArray *)parsedCategories {
    
    for (BlioStoreFeed *feed in self.feeds) {
        if ([feed.parser isEqual:parser])
            [feed.categories addObjectsFromArray:parsedCategories];
    }
    
    // Three scroll view properties are checked to keep the user interface smooth during parse. 
    // When new objects are delivered by the parser, the table view is reloaded to display them. 
    // If the table is reloaded while the user is scrolling, this can result in eratic behavior. 
    // dragging, tracking, and decelerating can be checked for this purpose. 
    // When the parser finishes, reloadData will be called in parserDidEndParsingData:, 
    // guaranteeing that all data will ultimately be displayed even if reloadData is not 
    // called in this method because of user interaction.
    if (!self.tableView.dragging && !self.tableView.tracking && !self.tableView.decelerating) {
        [self.tableView reloadData];
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
    }
}

- (void)parser:(BlioStoreBooksSourceParser *)parser didParseEntities:(NSArray *)parsedEntities {
	BOOL standardFeed = NO;
	//BOOL searchFeed = NO;
    for (BlioStoreFeed *feed in self.feeds) {
        if ([feed.parser isEqual:parser]) {
            [feed.entities addObjectsFromArray:parsedEntities];
			standardFeed = YES;
		}
    }
    //for (BlioStoreFeed *feed in self.storeSearchTableViewDataSource.feeds) {
//        if ([feed.parser isEqual:parser]) {
//            [feed.entities addObjectsFromArray:parsedEntities];
//			searchFeed = YES;
//		}
//    }
    // Three scroll view properties are checked to keep the user interface smooth during parse. 
    // When new objects are delivered by the parser, the table view is reloaded to display them. 
    // If the table is reloaded while the user is scrolling, this can result in eratic behavior. 
    // dragging, tracking, and decelerating can be checked for this purpose. 
    // When the parser finishes, reloadData will be called in parserDidEndParsingData:, 
    // guaranteeing that all data will ultimately be displayed even if reloadData is not 
    // called in this method because of user interaction.
	if (standardFeed) {
		if (!self.tableView.dragging && !self.tableView.tracking && !self.tableView.decelerating) {
			[self.tableView reloadData];
			UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
			UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
		}
	}
//	if (searchFeed) {
//		UITableView * searchTableView = self.searchDisplayController.searchResultsTableView;
//		if (!searchTableView.dragging && !searchTableView.tracking && !searchTableView.decelerating) {
//
//			[searchTableView reloadData];
//			[searchTableView setBackgroundColor:[UIColor whiteColor]];
//			[searchTableView setRowHeight:44];
//			UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
//			UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
//		}
//	}
}

- (void)parser:(BlioStoreBooksSourceParser *)parser didFailWithError:(NSError *)error {
    // handle errors as appropriate to your application...
}

@end

@implementation BlioStoreFreeBooksTableViewDataSource

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

@end

@implementation BlioStoreSearchTableViewDataSource

- (NSString *)getMoreCellLabelForSection:(NSUInteger) section {
	NSMutableArray * contentFeeds = [NSMutableArray array];
	for (BlioStoreFeed * aFeed in self.feeds) {
		if ([aFeed.categories count] || [aFeed.entities count]) [contentFeeds addObject:aFeed];
	}
	BlioStoreFeed *feed = [contentFeeds objectAtIndex:section];
	
	return [NSString stringWithFormat:NSLocalizedString(@"%@ Results",@"\"%@ Results\" See More Cell label"),[feed title]];
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger results = [super tableView:tableView numberOfRowsInSection:section];
	if (results > 0) return results;
	return 1;
}

@end