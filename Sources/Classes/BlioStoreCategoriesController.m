//
//  BlioStoreCategoriesController.m
//  BlioApp
//
//  Created by matt on 05/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioStoreCategoriesController.h"
#import "BlioStoreBookViewController.h"
#import "BlioBook.h"
//#import "BlioStoreFeedBooksNonGDataParser.h"

@interface BlioStoreCategoriesController()
- (void)parseFeeds;
@end

@implementation BlioStoreCategoriesController

@synthesize processingDelegate, managedObjectContext,activityIndicatorView,detailViewController;

- (void)dealloc {
	if (self.feeds) {
		for (BlioStoreFeed * feed in self.feeds) {
			if (feed.parser) [feed.parser cancel];
		}
	}
    self.processingDelegate = nil;
	self.detailViewController = nil;
	self.activityIndicatorView = nil;
	if (storeFeedTableViewDataSource) [storeFeedTableViewDataSource release];
    [super dealloc];
}

- (id)init {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        
        self.title = NSLocalizedString(@"Categories",@"\"Categories\" header");

        UITabBarItem* theItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Categories",@"\"Categories\" tab bar title") image:[UIImage imageNamed:@"icon-categories.png"] tag:kBlioStoreCategoriesTag];
        self.tabBarItem = theItem;
        [theItem release];
		
    }
    return self;
}
-(BlioStoreFeedTableViewDataSource*)storeFeedTableViewDataSource {
	if (!storeFeedTableViewDataSource) storeFeedTableViewDataSource = [[BlioStoreFeedTableViewDataSource alloc] init];
	return storeFeedTableViewDataSource;
}
/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

- (void)loadView {
    [super loadView];
	self.view.autoresizesSubviews =	YES;
	activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[activityIndicatorView setIsAccessibilityElement:YES];
    [activityIndicatorView setAccessibilityLabel:NSLocalizedString(@"Retrieving results", @"Accessibility label for Categories Controller Activity spinner")];
    [self.view addSubview:activityIndicatorView];
	activityIndicatorView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
	activityIndicatorView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin|
										   UIViewAutoresizingFlexibleRightMargin|
										   UIViewAutoresizingFlexibleTopMargin|
										   UIViewAutoresizingFlexibleBottomMargin);
	[activityIndicatorView startAnimating];
	activityIndicatorView.hidden = NO;
	self.tableView.dataSource = self.storeFeedTableViewDataSource;
}
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self parseFeeds];
}
-(NSMutableArray*)feeds {
	if (self.storeFeedTableViewDataSource) return self.storeFeedTableViewDataSource.feeds;
	return nil;
}
-(void)setFeeds:(NSMutableArray *)feedsMutableArray {
	if (self.storeFeedTableViewDataSource) self.storeFeedTableViewDataSource.feeds = feedsMutableArray;
}
// This method will be called repeatedly - once each time the user choses to parse.
- (void)parseFeeds {
    if (![self.feeds count]) return;
        
    for (BlioStoreFeed *feed in self.feeds) {
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

        if (feed.parser && feed.feedURL) {
            feed.parser.delegate = self;
            [feed.parser startWithURL:feed.feedURL];
        }
    }    
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


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath feed:(BlioStoreFeed*)feed {
	NSUInteger row = [indexPath row];
	
	if (row == ([feed.categories count]+[feed.entities count])) { // More Results option chosen
		if (([feed.categories count]+[feed.entities count]) < feed.totalResults) {
			// reveal activity indicator
			UIActivityIndicatorView * cellActivityIndicatorView = (UIActivityIndicatorView *)[[tableView cellForRowAtIndexPath:indexPath].imageView viewWithTag:kBlioMoreResultsCellActivityIndicatorViewTag];
			cellActivityIndicatorView.hidden = NO;
			[cellActivityIndicatorView startAnimating];
			UIImage * emptyImage = [[UIImage alloc] init];
			[tableView cellForRowAtIndexPath:indexPath].imageView.image = emptyImage;  // setting a UIImage object allows the view (and activity indicator subview) to show up
			[tableView cellForRowAtIndexPath:indexPath].imageView.frame = CGRectMake(0, 0, kBlioMoreResultsCellActivityIndicatorViewWidth * 1.5, kBlioMoreResultsCellActivityIndicatorViewWidth);
			[emptyImage release];
			//download and parse "next page" feed URL
			[feed.parser startWithURL:feed.nextURL];			
		}
	}
	else if (row < [feed.categories count]) { // Category cell selected
		BlioStoreParsedCategory *category = [feed.categories objectAtIndex:[indexPath row]];
		BlioStoreCategoriesController *aCategoriesController = [[BlioStoreCategoriesController alloc] init];
		[aCategoriesController setManagedObjectContext:self.managedObjectContext];
		[aCategoriesController setTitle:[category title]];
		NSURL *targetFeedURL = [category url];
		BlioStoreFeed *aFeed = [[BlioStoreFeed alloc] init];
		[aFeed setTitle:[category title]];
		[aFeed setFeedURL:targetFeedURL];
		[aFeed setParser:feed.parser];
		[aFeed setParserClass:[category classForType]];
		aFeed.sourceID = feed.sourceID;
		[aCategoriesController setFeeds:[NSArray arrayWithObject:aFeed]];
		[aFeed release];
		
		[aCategoriesController setProcessingDelegate:self.processingDelegate];

		aCategoriesController.detailViewController = self.detailViewController;
		
		[aCategoriesController.navigationItem setRightBarButtonItem:self.navigationItem.rightBarButtonItem];
		[self.navigationController pushViewController:aCategoriesController animated:YES];
		[aCategoriesController release];
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	} 
	else { // Entity cell selected
		row -= [feed.categories count];
		if (row < [feed.entities count]) {
			BlioStoreParsedEntity *entity = [feed.entities objectAtIndex:[indexPath row]];
			BlioStoreBookViewController *aEntityController = nil;
			if (self.detailViewController) aEntityController = self.detailViewController;
			else {
				aEntityController = [[BlioStoreBookViewController alloc] initWithNibName:@"BlioStoreBookView" bundle:[NSBundle mainBundle]];
				[aEntityController.navigationItem setRightBarButtonItem:self.navigationItem.rightBarButtonItem];
				[self.navigationController pushViewController:aEntityController animated:YES];
				[aEntityController release];
				[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
			}
			[aEntityController setProcessingDelegate:self.processingDelegate];
			[aEntityController setManagedObjectContext:self.managedObjectContext];
			[aEntityController setTitle:[entity title]];
			[aEntityController setFeed:feed]; // N.B. - Feed should be set before entity, as the setting of the entity triggers display (which in turn requires the feed to be set by then).
			[aEntityController setEntity:entity];
		}                
	}
}

#pragma mark -
#pragma mark UITableViewController Delegate Methods


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.

	NSUInteger section = [indexPath section];

	NSMutableArray * contentFeeds = [NSMutableArray array];
	for (BlioStoreFeed * aFeed in self.feeds) {
		if ([aFeed.categories count] || [aFeed.entities count]) [contentFeeds addObject:aFeed];
	}
	BlioStoreFeed *feed = [contentFeeds objectAtIndex:section];

	[self tableView:tableView didSelectRowAtIndexPath:indexPath feed:feed];
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

#pragma mark <BlioStoreFeedBooksParserDelegate> Implementation

- (void)parserDidEndParsingData:(BlioStoreBooksSourceParser *)parser {
    // hide UIActivityIndicator
	[activityIndicatorView stopAnimating];
	activityIndicatorView.hidden = YES;
	
	[self.tableView reloadData];
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)parser:(BlioStoreBooksSourceParser *)parser didParseTotalResults:(NSNumber *)volumeTotalResults {
    
    for (BlioStoreFeed *feed in self.feeds) {
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
    // table reloading will be handled when the categories and/or entities are parsed
}
- (void)parser:(BlioStoreBooksSourceParser *)parser didParseIdentifier:(NSString *)identifier {
    
    for (BlioStoreFeed *feed in self.feeds) {
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
    for (BlioStoreFeed *feed in self.feeds) {
        if ([feed.parser isEqual:parser])
            [feed.entities addObjectsFromArray:parsedEntities];
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

- (void)parser:(BlioStoreBooksSourceParser *)parser didFailWithError:(NSError *)error {
    // handle errors as appropriate to your application...
}

@end

@implementation BlioStoreFeedTableViewDataSource

@synthesize feeds;
	
#pragma mark -
#pragma mark UITableViewDataSource Methods
	
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NSUInteger sections = 0;
	for (BlioStoreFeed *feed in self.feeds) {
		if ([feed.categories count] || [feed.entities count]) sections++;
	}
	return sections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{ 
	NSMutableArray * contentFeeds = [NSMutableArray array];	
	for (BlioStoreFeed * aFeed in self.feeds) {
		if ([aFeed.categories count] || [aFeed.entities count]) [contentFeeds addObject:aFeed];
	}	
	BlioStoreFeed *feed = [contentFeeds objectAtIndex:section];
	
	return [feed title];
}



// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSMutableArray * contentFeeds = [NSMutableArray array];
	for (BlioStoreFeed * aFeed in self.feeds) {
		if ([aFeed.categories count] || [aFeed.entities count]) [contentFeeds addObject:aFeed];
	}
	BlioStoreFeed *feed = [contentFeeds objectAtIndex:section];
	NSUInteger getMoreResultsCell = 0;
	if (([feed.categories count] + [feed.entities count]) < feed.totalResults) getMoreResultsCell = 1; // our data is less than the totalResults, so we need a "Get More Results" option.
	return [feed.categories count] + [feed.entities count] + getMoreResultsCell;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSUInteger row = [indexPath row];
	NSUInteger section = [indexPath section];
	
	NSMutableArray * contentFeeds = [NSMutableArray array];	
	for (BlioStoreFeed * aFeed in self.feeds) {
		if ([aFeed.categories count] || [aFeed.entities count]) [contentFeeds addObject:aFeed];
	}	
	BlioStoreFeed *feed = [contentFeeds objectAtIndex:section];
	
	static NSString *MoreResultsCellIdentifier = @"MoreResultsCell";
	static NSString *CategoryCellIdentifier = @"CategoryCell";
	static NSString *EntityCellIdentifier = @"EntityCell";
	
	UITableViewCell *cell;
	
	// for More Results
	if (row == ([feed.categories count]+[feed.entities count])) { // one row beyond categories/entities was selected
		cell = [tableView dequeueReusableCellWithIdentifier:MoreResultsCellIdentifier];
		if (cell == nil) {
			// create cell
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:MoreResultsCellIdentifier] autorelease];
			cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0];
			cell.textLabel.textColor = [UIColor colorWithRed:36.0/255 green:112.0/255 blue:216.0/255 alpha:1];
			cell.detailTextLabel.font = [UIFont systemFontOfSize:12.5];
			
			// add activity indicator
			UIActivityIndicatorView * cellActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
			cellActivityIndicatorView.frame = CGRectMake(-kBlioMoreResultsCellActivityIndicatorViewWidth/3,-kBlioMoreResultsCellActivityIndicatorViewWidth/2,kBlioMoreResultsCellActivityIndicatorViewWidth,kBlioMoreResultsCellActivityIndicatorViewWidth);
			cellActivityIndicatorView.hidden = YES;
			
			cellActivityIndicatorView.hidesWhenStopped = YES;
			cellActivityIndicatorView.tag = kBlioMoreResultsCellActivityIndicatorViewTag;
			[cell.imageView addSubview:cellActivityIndicatorView];
			[cellActivityIndicatorView release];
		}		
		// populate cell with content
		
		
		[(UIActivityIndicatorView *)[cell.imageView viewWithTag:kBlioMoreResultsCellActivityIndicatorViewTag] stopAnimating];
		if (([feed.categories count]+[feed.entities count]) < feed.totalResults) {
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"See More %@...",@"See More %@(Type of Result)..."), [self getMoreCellLabelForSection:section]];
			[cell setAccessibilityHint:NSLocalizedString(@"Loads more results.", @"Accessibility hint for Store Categories View Load More cell")];
		}
		else {
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"No More %@...",@"No More %@(Type of Result)..."), [self getMoreCellLabelForSection:section]];
			[cell setAccessibilityHint:NSLocalizedString(@"No more results.", @"Accessibility hint for Store Categories View No More cell")];
		}
	
		cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%i shown out of %i total",@"%i shown out of %i total"), ([feed.categories count]+[feed.entities count]),feed.totalResults];
		cell.imageView.image = nil;

		[cell setAccessibilityLabel:[NSString stringWithFormat:NSLocalizedString(@"%@, %@", @"Accessibility label for Store Categories View Load More cell"), cell.textLabel.text, cell.detailTextLabel.text]];
		
	}
	else if (row < [feed.categories count]) { // category cell is needed
		cell = [tableView dequeueReusableCellWithIdentifier:CategoryCellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CategoryCellIdentifier] autorelease];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			//			cell.textLabel.font = [UIFont boldSystemFontOfSize:12.0]; // we'll use default size
		}
		cell.textLabel.text = [[feed.categories objectAtIndex:indexPath.row] title];
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		[cell setAccessibilityLabel:cell.textLabel.text];
		[cell setAccessibilityHint:nil];
		
	} else { // entity cell is needed
		cell = [tableView dequeueReusableCellWithIdentifier:EntityCellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:EntityCellIdentifier] autorelease];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0];
			cell.detailTextLabel.font = [UIFont systemFontOfSize:12.5];
		}		
		row -= [feed.categories count];
		if (row < [feed.entities count]) {
			cell.textLabel.text = [[feed.entities objectAtIndex:indexPath.row] title];
			cell.detailTextLabel.text = [BlioBook standardNameFromCanonicalName:[[feed.entities objectAtIndex:indexPath.row] author]];
			[cell setAccessibilityLabel:[NSString stringWithFormat:NSLocalizedString(@"%@ by %@", @"Accessibility label for Store Categories Entity cell"), cell.textLabel.text, cell.detailTextLabel.text ? : @"Anon"]];
			[cell setAccessibilityHint:nil];
		}
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	}
	return cell;
}

- (NSString *)getMoreCellLabelForSection:(NSUInteger) section {
	NSMutableArray * contentFeeds = [NSMutableArray array];
	for (BlioStoreFeed * aFeed in self.feeds) {
		if ([aFeed.categories count] || [aFeed.entities count]) [contentFeeds addObject:aFeed];
	}
	BlioStoreFeed *feed = [contentFeeds objectAtIndex:section];
	
	return [feed title];
}

@end
