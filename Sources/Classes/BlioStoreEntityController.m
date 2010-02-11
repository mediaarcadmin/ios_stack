//
//  BlioStoreEntityController.m
//  BlioApp
//
//  Created by matt on 10/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioStoreEntityController.h"

@interface BlioStoreEntityController()
@property (nonatomic, retain) BlioStoreFeedBooksParser *parser;
- (void)parseFeed;
@end


@implementation BlioStoreEntityController

@synthesize entity, parser;

- (void)dealloc {
    self.entity = nil;
    [self.parser setDelegate:nil]; // Required to stop background parsing threads messaging this controller
    self.parser = nil;
    [super dealloc];
}

- (id)init {
    if ((self = [super initWithStyle:UITableViewStylePlain])) {
        
        self.title = @"Categories";
        
//        UITabBarItem* theItem = [[UITabBarItem alloc] initWithTitle:@"Categories" image:nil tag:kBlioStoreCategoriesTag];
//        self.tabBarItem = theItem;
//        [theItem release];
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
    NSURL *feedURL = [NSURL URLWithString:[self.entity url]];
    if (nil == feedURL) return;
    
    // Create the parser, set its delegate, and start it.
    BlioStoreFeedBooksParser* aParser = [[BlioStoreFeedBooksParser alloc] init];
    aParser.delegate = self;
    self.parser = aParser;
    
    [aParser startWithURL:feedURL];
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

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) 
	{ 
		case 0: 
			return 9;
		default: 
			return 0; 
	} 
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger row = [indexPath row];
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell...
    switch (row) 
	{ 
		case 0:
            cell.textLabel.text = [self.entity title];
            break;
        case 1:
            cell.textLabel.text = [self.entity author];
            break;
        case 2:
            cell.textLabel.text = [self.entity summary];
            break;
        case 3:
            cell.textLabel.text = [self.entity ePubUrl];
            break;
        case 4:
            cell.textLabel.text = [self.entity pdfUrl];
            break;
        case 5:
            cell.textLabel.text = [self.entity thumbUrl];
            break;
        case 6:
            cell.textLabel.text = [self.entity coverUrl];
            break;
        case 7:
            cell.textLabel.text = [self.entity releasedYear];
            break;
        case 8: {
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateStyle:NSDateFormatterLongStyle];
            NSString *dateString = [dateFormat stringFromDate:[self.entity publishedDate]];
            [dateFormat release];
            cell.textLabel.text = dateString;
        }  break;
		default: 
			break;
	} 
    
    
    return cell;
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

- (void)parser:(BlioStoreFeedBooksParser *)parser didParseEntity:(BlioStoreParsedEntity *)parsedEntity {
    //[self.categories addObjectsFromArray:parsedCategories];
    self.entity = parsedEntity;
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

