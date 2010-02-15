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

@synthesize feeds;

- (void)dealloc {
    self.feeds = nil;
    [super dealloc];
}

- (id)init {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        
        self.title = @"Categories";
        
        UITabBarItem* theItem = [[UITabBarItem alloc] initWithTitle:@"Categories" image:nil tag:kBlioStoreCategoriesTag];
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

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


#pragma mark Table view methods

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
    return [feed.categories count] + [feed.entities count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger row = [indexPath row];
    NSUInteger section = [indexPath section];
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    BlioStoreFeed *feed = [self.feeds objectAtIndex:section];
    if (row < [feed.categories count]) {
        cell.textLabel.text = [[feed.categories objectAtIndex:indexPath.row] title];
    } else {
        row -= [feed.categories count];
        if (row < [feed.entities count]) {
            cell.textLabel.text = [[feed.entities objectAtIndex:indexPath.row] title];
        }                
    }
    
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    NSUInteger row = [indexPath row];
    NSUInteger section = [indexPath section];

    BlioStoreFeed *feed = [self.feeds objectAtIndex:section];
    if (row < [feed.categories count]) {
        BlioStoreParsedCategory *category = [feed.categories objectAtIndex:[indexPath row]];
        BlioStoreCategoriesController *aCategoriesController = [[BlioStoreCategoriesController alloc] init];
        [aCategoriesController setTitle:[category title]];
        NSURL *targetFeedURL = [category url];
        BlioStoreFeed *aFeed = [[BlioStoreFeed alloc] init];
        [aFeed setFeedURL:targetFeedURL];
        [aFeed setParser:feed.parser];
        [aFeed setParserClass:[category classForType]];
        [aCategoriesController setFeeds:[NSArray arrayWithObject:aFeed]];
        [aFeed release];
        
        [aCategoriesController.navigationItem setRightBarButtonItem:self.navigationItem.rightBarButtonItem];
        [self.navigationController pushViewController:aCategoriesController animated:YES];
        [aCategoriesController release];
    } else {
        row -= [feed.categories count];
        if (row < [feed.entities count]) {
            BlioStoreParsedEntity *entity = [feed.entities objectAtIndex:[indexPath row]];
            BlioStoreBookViewController *aEntityController = [[BlioStoreBookViewController alloc] initWithNibName:@"BlioStoreBookView"
                                                                                                       bundle:[NSBundle mainBundle]];
            [aEntityController setTitle:[entity title]];
            [aEntityController setEntity:entity];
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
    [self.tableView reloadData];
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
