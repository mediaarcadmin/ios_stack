//
//  BlioStoreCategoriesController.m
//  BlioApp
//
//  Created by matt on 05/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioStoreCategoriesController.h"
#import "BlioStoreBookViewController.h"
//#import "BlioStoreFeedBooksNonGDataParser.h"

@interface BlioStoreCategoriesController()
- (void)parseFeeds;
@end

@implementation BlioStoreCategoriesController

@synthesize feeds, processingDelegate, managedObjectContext,activityIndicatorView;

- (void)dealloc {
    self.feeds = nil;
    self.processingDelegate = nil;
    [super dealloc];
}

- (id)init {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        
        self.title = @"Categories";

        UITabBarItem* theItem = [[UITabBarItem alloc] initWithTitle:@"Categories" image:[UIImage imageNamed:@"icon-categories.png"] tag:kBlioStoreCategoriesTag];
        self.tabBarItem = theItem;
        [theItem release];
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

- (void)loadView {
    [super loadView];
	self.view.autoresizesSubviews =	YES;
	activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[self.view addSubview:activityIndicatorView];
	activityIndicatorView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
	activityIndicatorView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin|
										   UIViewAutoresizingFlexibleRightMargin|
										   UIViewAutoresizingFlexibleTopMargin|
										   UIViewAutoresizingFlexibleBottomMargin);
	[activityIndicatorView startAnimating];
	activityIndicatorView.hidden = NO;
	[activityIndicatorView release];
}
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self parseFeeds];
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

- (NSString *)getMoreCellLabelForSection:(NSUInteger) section {
	return [[self.feeds objectAtIndex:section] title];
}

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
	return [[self.feeds objectAtIndex:section] title];
}



// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    BlioStoreFeed *feed = [self.feeds objectAtIndex:section];
	NSUInteger getMoreResultsCell = 0;
	if (([feed.categories count] + [feed.entities count]) < feed.totalResults) getMoreResultsCell = 1; // our data is less than the totalResults, so we need a "Get More Results" option.
    return [feed.categories count] + [feed.entities count] + getMoreResultsCell;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger row = [indexPath row];
    NSUInteger section = [indexPath section];
	
    BlioStoreFeed *feed = [self.feeds objectAtIndex:section];
	
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

		cell.textLabel.text = [NSString stringWithFormat:@"See More %@...", [self getMoreCellLabelForSection:section]];
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%i shown out of %i total", ([feed.categories count]+[feed.entities count]),feed.totalResults];
		cell.imageView.image = nil;
        [cell setAccessibilityLabel:[NSString stringWithFormat:NSLocalizedString(@"%@, %@", @"Accessibility label for Store Categories View Load More cell"), cell.textLabel.text, cell.detailTextLabel.text]];
        [cell setAccessibilityHint:NSLocalizedString(@"Loads more results.", @"Accessibility hint for Store Categories View Load More cell")];

	}
	else if (row < [feed.categories count]) { // category cell is needed
		cell = [tableView dequeueReusableCellWithIdentifier:CategoryCellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CategoryCellIdentifier] autorelease];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//			cell.textLabel.font = [UIFont boldSystemFontOfSize:12.0]; // we'll use default size
		}
        cell.textLabel.text = [[feed.categories objectAtIndex:indexPath.row] title];
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
			cell.detailTextLabel.text = [[feed.entities objectAtIndex:indexPath.row] author];
            [cell setAccessibilityLabel:[NSString stringWithFormat:NSLocalizedString(@"%@ by %@", @"Accessibility label for Store Categories Entity cell"), cell.textLabel.text, cell.detailTextLabel.text ? : @"Anon"]];
            [cell setAccessibilityHint:nil];
        }               
    }

	return cell;
}

#pragma mark -
#pragma mark UITableViewController Delegate Methods


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    NSUInteger row = [indexPath row];
    NSUInteger section = [indexPath section];

    BlioStoreFeed *feed = [self.feeds objectAtIndex:section];
	if (row == ([feed.categories count]+[feed.entities count])) { // More Results option chosen
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
        [aCategoriesController setFeeds:[NSArray arrayWithObject:aFeed]];
        [aFeed release];
        
        [aCategoriesController setProcessingDelegate:self.processingDelegate];
        
        [aCategoriesController.navigationItem setRightBarButtonItem:self.navigationItem.rightBarButtonItem];
        [self.navigationController pushViewController:aCategoriesController animated:YES];
        [aCategoriesController release];
    } else { // Entity cell selected
        row -= [feed.categories count];
        if (row < [feed.entities count]) {
            BlioStoreParsedEntity *entity = [feed.entities objectAtIndex:[indexPath row]];
            BlioStoreBookViewController *aEntityController = [[BlioStoreBookViewController alloc] initWithNibName:@"BlioStoreBookView"
                                                                                                       bundle:[NSBundle mainBundle]];
            [aEntityController setProcessingDelegate:self.processingDelegate];
			[aEntityController setManagedObjectContext:self.managedObjectContext];
            [aEntityController setTitle:[entity title]];
            [aEntityController setEntity:entity];
            [aEntityController setFeed:feed];
            [aEntityController.navigationItem setRightBarButtonItem:self.navigationItem.rightBarButtonItem];
            
            [self.navigationController pushViewController:aEntityController animated:YES];
            [aEntityController release];
        }                
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    }
}

- (void)parser:(BlioStoreBooksSourceParser *)parser didFailWithError:(NSError *)error {
    // handle errors as appropriate to your application...
}



@end
