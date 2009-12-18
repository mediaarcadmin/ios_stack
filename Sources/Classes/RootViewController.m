//
//  RootViewController.m
//  BlioApp
//
//  Created by James Montgomerie on 16/12/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//

#import "RootViewController.h"
#import <libEucalyptus/EucEPubBook.h>
#import <libEucalyptus/EucBookViewController.h>
#import "BlioLayoutView.h"

@implementation RootViewController

/*
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
  self.navigationItem.title = @"Books";
  self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
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

/*
 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 */

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release anything that can be recreated in viewDidLoad or on demand.
	// e.g. self.myOutlet = nil;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	// Configure the cell.
  switch (indexPath.row) {
    case 0:
      cell.textLabel.text = @"Dead Is So Last Year ePUB";
      break;
    case 1:
      cell.textLabel.text = @"Exiles In The Garden ePUB";
      break;
    case 2:
      cell.textLabel.text = @"Dead Is So Last Year PDF";
      break;
    case 3:
      cell.textLabel.text = @"Exiles In The Garden PDF";
      break;
    default:
      break;
  }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *path;
  
  switch (indexPath.row) {
    case 0:
      path = [[NSBundle mainBundle] pathForResource:@"Dead Is So Last Year" ofType:@"epub" inDirectory:@"ePubs"];
      break;
    case 1:
      path = [[NSBundle mainBundle] pathForResource:@"Exiles In The Garden" ofType:@"epub" inDirectory:@"ePubs"];
      break;
    case 2:
      path = [[NSBundle mainBundle] pathForResource:@"Dead Is So Last Year" ofType:@"pdf" inDirectory:@"PDFs"];
      break;
    case 3:
      path = [[NSBundle mainBundle] pathForResource:@"Exiles In The Garden" ofType:@"pdf" inDirectory:@"PDFs"];
      break;
    default:
      break;
  }
  
    if(indexPath.row < 2) {
      EucEPubBook *book = [[EucEPubBook alloc] initWithPath:path];
      EucBookViewController *bookViewController = [[EucBookViewController alloc] initWithBook:book];
      bookViewController.toolbarsVisibleAfterAppearance = YES;
      [book release];
      [self.navigationController pushViewController:bookViewController animated:YES];
      [bookViewController release];
    } else {
      BlioLayoutView *layoutView = [[BlioLayoutView alloc] initWithPath:path];
        UIToolbar *emptyToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
        emptyToolbar.barStyle = UIBarStyleBlack;
        emptyToolbar.translucent = YES;
        [emptyToolbar sizeToFit];
        EucBookViewController *bookViewController = [[EucBookViewController alloc] initWithBookView:layoutView];
        bookViewController.overriddenToolbar = emptyToolbar;
        bookViewController.toolbarsVisibleAfterAppearance = YES;
      [layoutView release];
      [self.navigationController pushViewController:bookViewController animated:YES];
      [bookViewController release];
    }
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
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
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


- (void)dealloc {
    [super dealloc];
}


@end

