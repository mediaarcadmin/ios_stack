//
//  TransitionTestRootViewController.m
//  TransitionTest
//
//  Created by James Montgomerie on 29/11/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//

#import "TransitionTestRootViewController.h"
#import <libEucalyptus/EucBUpeBook.h>
#import <libEucalyptus/EucBookViewController.h>

@implementation TransitionTestRootViewController

/*
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/

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
    return 3;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSUInteger row = indexPath.row;
    switch(row) {
        case 0:
            cell.textLabel.text = @"Book with nav bar";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case 1:	
            cell.textLabel.text = @"Book no nav bar";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case 2:
            cell.textLabel.text = @"Toggle nav bar";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;            
        default:
            break;
    }
    
    return cell;
}




// Override to support row selection in the table view.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = indexPath.row;
    if(row < 2) {
        NSString *bookPath = nil;
        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
        for(NSString *resource in [[NSFileManager defaultManager] directoryContentsAtPath:resourcePath]) {
            NSString *fullPath = [resourcePath stringByAppendingPathComponent:resource];
            BOOL isDirectory = YES;
            if([[NSFileManager defaultManager] fileExistsAtPath:[fullPath stringByAppendingPathComponent:@"META-INF"] isDirectory:&isDirectory] && isDirectory) {
                bookPath = fullPath;
                break;
            }
        }        
        if(bookPath) {
            EucBUpeBook *book = [[EucBUpeBook alloc] initWithPath:bookPath];
            EucBookViewController *bookViewController = [[EucBookViewController alloc] initWithBook:book];
            [book release];
            
            bookViewController.toolbarsVisibleAfterAppearance = (row == 0);
            
            [self.navigationController pushViewController:bookViewController animated:YES];
            [bookViewController release];
        }
    } else {
        [self.navigationController setNavigationBarHidden:!self.navigationController.isNavigationBarHidden
                                                 animated:YES];
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

