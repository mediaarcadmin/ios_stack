//
//  BlioBookSearchViewController.m
//  BlioApp
//
//  Created by matt on 07/06/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "BlioBookSearchViewController.h"

#define BLIOBOOKSEARCHCELLPAGETAG 1233
#define BLIOBOOKSEARCHCELLPREFIXTAG 1234
#define BLIOBOOKSEARCHCELLMATCHTAG 1235
#define BLIOBOOKSEARCHCELLSUFFIXTAG 1236

#define RESULTSPREFIXSTRINGMAXLENGTH 15

@interface BlioBookSearchResults : NSObject {
    NSString *prefix;
    NSString *match;
    NSString *suffix;
    BlioBookmarkPoint *bookmark;
}

@property (nonatomic, retain) NSString *prefix;
@property (nonatomic, retain) NSString *match;
@property (nonatomic, retain) NSString *suffix;
@property (nonatomic, retain) BlioBookmarkPoint *bookmark;

@end


@implementation BlioBookSearchViewController

@synthesize tableView, searchToolbar;
@synthesize bookSearchController, searchController;
@synthesize searchResults, savedSearchTerm;
@synthesize noResultsLabel, noResultsMessage;

- (void)dealloc {
    self.tableView = nil;
    self.searchToolbar = nil;
    self.bookSearchController = nil;
    self.searchController = nil;
    self.searchResults = nil;
    self.savedSearchTerm = nil;
    self.noResultsLabel = nil;
    self.noResultsMessage = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark Initialization


- (id)init {
    if ((self = [super init])) {
        BlioBookSearchToolbar *aSearchToolbar = [[BlioBookSearchToolbar alloc] init];
        [aSearchToolbar setDelegate:self];
        [aSearchToolbar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        self.searchToolbar = aSearchToolbar;
        [aSearchToolbar release];
        
        self.searchResults = [NSMutableArray array];
        //CGRect containerFrame = [[UIScreen mainScreen] applicationFrame];
//        UIView *container = containerFrame
//        UITableView *aTableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
//        self.view = 
//        UISearchBar *aSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
//        [aSearchBar setPlaceholder:NSLocalizedString(@"Search",@"\"Search\" placeholder text in Search bar")];
//        UIColor *matchedTintColor = [UIColor colorWithHue:0.595 saturation:0.267 brightness:0.68 alpha:1];
//        [aSearchBar setTintColor:matchedTintColor];
//        [aSearchBar setDelegate:self];
//        [aSearchBar setShowsCancelButton:YES];
//        [aSearchBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
//        [self.view addSubview:aSearchBar];
//        [self.tableView setBounces:NO];
//        //[self.tableView setContentInset:UIEdgeInsetsMake(CGRectGetHeight(aSearchBar.frame), 0, 0, 0)];
//        self.searchBar = aSearchBar;
//        [aSearchBar release];
        
        //UISearchDisplayController *aSearchController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
//        aSearchController.delegate = self;
//        aSearchController.searchResultsDataSource = self;
//        aSearchController.searchResultsDelegate = self;
//        self.searchController = aSearchController;
//        [aSearchController release];
        
        //[self.searchController setActive:YES];
        //[self.searchBar sizeToFit];
    }
    return self;
}



#pragma mark -
#pragma mark View lifecycle

- (void)loadView {
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    UIView *container = [[UIView alloc] initWithFrame:appFrame];
    container.backgroundColor = [UIColor blueColor];
    container.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = container;
    [container release];
    
    [self.searchToolbar setFrame:CGRectMake(0, 0, CGRectGetWidth(appFrame), 44)];
    [self.view addSubview:self.searchToolbar];
    
    UITableView *aTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.searchToolbar.frame), CGRectGetWidth(appFrame), CGRectGetHeight(appFrame) - CGRectGetMaxY(self.searchToolbar.frame)) style:UITableViewStylePlain];
    [aTableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [aTableView setDataSource:self];
    [aTableView setDelegate:self];
    [self.view addSubview:aTableView];
    self.tableView = aTableView;
    [aTableView release];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //UISearchDisplayController *aSearchController = [[UISearchDisplayController alloc]
//                        initWithSearchBar:self.searchToolbar.searchBar contentsController:self];
//    aSearchController.delegate = self;
//    aSearchController.searchResultsDataSource = self;
//    aSearchController.searchResultsDelegate = self;
//    self.searchController = aSearchController;
//    [aSearchController release];
    
    
    //[self.searchController setActive:YES];
    // Uncomment the following line to preserve selection between presentations.
    //self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)dismissSearchToolbar:(id)sender {
    [self.bookSearchController cancel];
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}

- (void)setTintColor:(UIColor *)tintColor {
    [self.searchToolbar setTintColor:tintColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //[self.searchController setActive:YES animated:NO];

}

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



#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.searchResults count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        UILabel *page = [[UILabel alloc] init];
        page.font = [UIFont systemFontOfSize:17];
        page.adjustsFontSizeToFitWidth = YES;
        page.textColor = [UIColor darkGrayColor];
        page.textAlignment = UITextAlignmentRight;
        page.tag = BLIOBOOKSEARCHCELLPAGETAG;
        [cell.contentView addSubview:page];
        [page release];
        
        UILabel *prefix = [[UILabel alloc] init];
        prefix.font = [UIFont systemFontOfSize:17];
        prefix.tag = BLIOBOOKSEARCHCELLPREFIXTAG;
        [cell.contentView addSubview:prefix];
        [prefix release];
        
        UILabel *match = [[UILabel alloc] init];
        match.font = [UIFont boldSystemFontOfSize:17];
        match.tag = BLIOBOOKSEARCHCELLMATCHTAG;
        [cell.contentView addSubview:match];
        [match release];
        
        UILabel *suffix = [[UILabel alloc] init];
        suffix.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        suffix.font = [UIFont systemFontOfSize:17];
        suffix.tag = BLIOBOOKSEARCHCELLSUFFIXTAG;
        [cell.contentView addSubview:suffix];
        [suffix release];
    }
    
    // Configure the cell...
    BlioBookSearchResults *result = [self.searchResults objectAtIndex:[indexPath row]];
    
    UILabel *page = (UILabel *)[cell.contentView viewWithTag:BLIOBOOKSEARCHCELLPAGETAG];
    page.text = [NSString stringWithFormat:@"p.%d", result.bookmark.layoutPage];
    [page sizeToFit];
    CGRect pageFrame = page.frame;
    pageFrame.origin = CGPointMake(5, (CGRectGetHeight(cell.contentView.frame) - pageFrame.size.height)/2.0f);
    pageFrame.size.width = 50;
    page.frame = pageFrame;
    
    UILabel *prefix = (UILabel *)[cell.contentView viewWithTag:BLIOBOOKSEARCHCELLPREFIXTAG];
    prefix.text = result.prefix;
    [prefix sizeToFit];
    CGRect prefixFrame = prefix.frame;
    prefixFrame.origin = CGPointMake(CGRectGetMaxX(pageFrame) + 10, (CGRectGetHeight(cell.contentView.frame) - prefixFrame.size.height)/2.0f);
    prefix.frame = prefixFrame;
    //prefix.backgroundColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.3];
    
    UILabel *match = (UILabel *)[cell.contentView viewWithTag:BLIOBOOKSEARCHCELLMATCHTAG];
    match.text = result.match;
    [match sizeToFit];
    CGRect matchFrame = match.frame;
    matchFrame.origin = CGPointMake(CGRectGetMaxX(prefixFrame), (CGRectGetHeight(cell.contentView.frame) - matchFrame.size.height)/2.0f);
    match.frame = matchFrame;
    //match.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.3];
    
    UILabel *suffix = (UILabel *)[cell.contentView viewWithTag:BLIOBOOKSEARCHCELLSUFFIXTAG];
    suffix.text = result.suffix;
    suffix.frame = CGRectMake(CGRectGetMaxX(matchFrame), matchFrame.origin.y, CGRectGetWidth(cell.contentView.frame) - CGRectGetMaxX(matchFrame) - 10, prefixFrame.size.height);
    //suffix.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.3];
    
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


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	/*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

#pragma mark -
#pragma mark BlioBookSearchDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self.searchToolbar.searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self.bookSearchController cancel];
    [self.searchResults removeAllObjects];
    [self.tableView reloadData];
    
    if (searchText) {
    //BlioBookmarkPoint *currentBookmarkPoint = self.bookView.currentBookmarkPoint;
        [self.bookSearchController findString:searchText fromBookmarkPoint:nil];
    }
}

#pragma mark -
#pragma mark BlioBookSearchDelegate

- (void)searchController:(BlioBookSearchController *)aSearchController didFindString:(NSString *)searchString atBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint withPrefix:(NSString *)prefix withSuffix:(NSString *)suffix {
    NSLog(@"searchController didFindString '%@' at page %d paragraph %d word %d element %d", searchString, bookmarkPoint.layoutPage, bookmarkPoint.blockOffset, bookmarkPoint.wordOffset, bookmarkPoint.elementOffset);
    //NSString *prefixString = nil;
//    NSString *resultString = searchString;
//    
//    for (int i = [prefix count] - 1; i >= 0; i--) {
//        NSString *nextWord = [prefix objectAtIndex:i];
//        if (([resultString length] + [nextWord length]) <= RESULTSPREFIXSTRINGMAXLENGTH) {
//            if (prefixString) {
//                prefixString = [NSString stringWithFormat:@"%@ %@", nextWord, prefixString];
//            } else {
//                prefixString = [NSString stringWithString:nextWord];
//            }
//            resultString = [NSString stringWithFormat:@"%@ %@", prefixString, searchString];
//        } else {
//            break;
//        }
//    }
    
    //resultString = [NSString stringWithFormat:@"%@ %@", resultString, [suffix componentsJoinedByString:@" "]];
    
    NSString *resultString = [NSString stringWithFormat:@"%@%@%@", prefix, searchString, suffix];
    NSLog(@"resultString: %@", resultString);
    
    BlioBookSearchResults *result = [[BlioBookSearchResults alloc] init];
    result.prefix = prefix;
    result.match  = searchString;
    result.suffix = suffix;
    result.bookmark = bookmarkPoint;
    
//    [self.searchResults addObject:[NSString stringWithFormat:@"p.%d %@", bookmarkPoint.layoutPage, resultString]];
    [self.searchResults addObject:result];
    [result release];
    [self.tableView reloadData];
    [aSearchController findNextOccurrence];
}

- (void)searchControllerDidReachEndOfBook:(BlioBookSearchController *)aSearchController {
    NSLog(@"Search reached end of book");
    [aSearchController findNextOccurrence];
}

- (void)searchControllerDidCompleteSearch:(BlioBookSearchController *)aSearchController {
    NSLog(@"Search complete");
}
    
@end

@implementation BlioBookSearchResults

@synthesize prefix, match, suffix, bookmark;

- (void)dealloc {
    self.prefix = nil;
    self.match = nil;
    self.suffix = nil;
    self.bookmark = nil;
    [super dealloc];
}

@end

