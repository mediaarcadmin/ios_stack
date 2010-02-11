//
//  BlioStoreCategoriesController.m
//  BlioApp
//
//  Created by matt on 05/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioStoreCollectionController.h"
#import "BlioStoreEntityController.h"

@interface BlioStoreCollectionController()
@property (nonatomic, retain) NSMutableArray *categories;
@property (nonatomic, retain) NSMutableArray *entities;
@property (nonatomic, retain) BlioStoreFeedBooksParser *parser;
- (void)parseFeed;
@end

@implementation BlioStoreCollectionController

@synthesize categories, entities, parser, feedURL;

- (void)dealloc {
    self.categories = nil;
    self.entities = nil;
    [self.parser setDelegate:nil]; // Required to stop background parsing trheads messaging this controller
    self.parser = nil;
    self.feedURL = nil;
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
    
    [self parseFeed];
}

// This method will be called repeatedly - once each time the user choses to parse.
- (void)parseFeed {
    // Allocate the arrays for category & entity storage, or empty the results of previous parses
    if (self.categories == nil) {
        self.categories = [NSMutableArray array];
    } else {
        [self.categories removeAllObjects];
        [self.tableView reloadData];
    }
    if (self.entities == nil) {
        self.entities = [NSMutableArray array];
    } else {
        [self.entities removeAllObjects];
        [self.tableView reloadData];
    }
    
    if (nil == self.feedURL) return;
    // Create the parser, set its delegate, and start it.
    BlioStoreFeedBooksParser* aParser = [[BlioStoreFeedBooksParser alloc] init];
    aParser.delegate = self;
    self.parser = aParser;
    
    [aParser startWithURL:self.feedURL];
    [aParser release];
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
    return 1;
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
    switch (section) 
	{ 
		case 0: 
			return [self.categories count] + [self.entities count];
		case 1: 
			return 7; 
		default: 
			return 0; 
	} 
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger row = [indexPath row];
    NSUInteger section = [indexPath section];
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    // Set up the cell...
    switch (section) 
	{ 
		case 0:
            if (row < [self.categories count]) {
                cell.textLabel.text = [[self.categories objectAtIndex:indexPath.row] title];
                cell.detailTextLabel.text = [[self.categories objectAtIndex:indexPath.row] url];
			} else {
                row -= [self.categories count];
                if (row < [self.entities count]) {
                    cell.textLabel.text = [[self.entities objectAtIndex:indexPath.row] title];
                    cell.detailTextLabel.text = [[self.entities objectAtIndex:indexPath.row] url];
                }                
            }
            break;
		case 1: 
			break;
		default: 
			break;
	} 
    
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    NSUInteger row = [indexPath row];
    
    if (row < [self.categories count]) {
        BlioStoreParsedCategory *category = [self.categories objectAtIndex:[indexPath row]];
        BlioStoreCollectionController *aCategoriesController = [[BlioStoreCollectionController alloc] init];
        [aCategoriesController setTitle:[category title]];
        NSURL *targetFeedURL = [NSURL URLWithString:[category url]];
        [aCategoriesController setFeedURL:targetFeedURL];
        [aCategoriesController.navigationItem setRightBarButtonItem:self.navigationItem.rightBarButtonItem];

        [self.navigationController pushViewController:aCategoriesController animated:YES];
        [aCategoriesController release];
    } else {
        row -= [self.categories count];
        if (row < [self.entities count]) {
            BlioStoreParsedEntity *entity = [self.entities objectAtIndex:[indexPath row]];
            BlioStoreEntityController *aEntityController = [[BlioStoreEntityController alloc] init];
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

- (void)parserDidEndParsingData:(BlioStoreFeedBooksParser *)parser {
    [self.tableView reloadData];
    self.parser = nil;
}

- (void)parser:(BlioStoreFeedBooksParser *)parser didParseCategories:(NSArray *)parsedCategories {
    [self.categories addObjectsFromArray:parsedCategories];
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

- (void)parser:(BlioStoreFeedBooksParser *)parser didParseEntities:(NSArray *)parsedEntities {
    //[self.categories addObjectsFromArray:parsedCategories];
    [self.entities addObjectsFromArray:parsedEntities];
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

- (void)parser:(BlioStoreFeedBooksParser *)parser didFailWithError:(NSError *)error {
    // handle errors as appropriate to your application...
}



@end

