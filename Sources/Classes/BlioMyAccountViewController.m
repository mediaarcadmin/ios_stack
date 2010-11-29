//
//  BlioMyAccountViewController.m
//  BlioApp
//
//  Created by Don Shin on 10/15/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "BlioMyAccountViewController.h"
#import "BlioStoreManager.h"
#import "BlioPaidBooksSettingsController.h"
#import "BlioArchiveSettingsViewController.h"

@implementation BlioMyAccountViewController

@synthesize subControllers;

#pragma mark -
#pragma mark Initialization

- (id)init {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
		self.title = NSLocalizedString(@"My Account",@"\"My Account\" view controller title.");
		UIBarButtonItem * aButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Logout",@"\"Logout\" bar button text label within My Account.") style:UIBarButtonItemStyleBordered target:self action:@selector(logoutButtonPressed:)];
		self.navigationItem.rightBarButtonItem = aButton;
		[aButton release];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			self.contentSizeForViewInPopover = CGSizeMake(320, 600);
		}
		self.subControllers = [NSArray arrayWithObjects:[[[BlioPaidBooksSettingsController alloc] init] autorelease],[[[BlioArchiveSettingsViewController alloc] init] autorelease],nil];
    }
    return self;
}
-(void)logoutButtonPressed:(id)sender {
	[[BlioStoreManager sharedInstance] logoutForSourceID:BlioBookSourceOnlineStore];
	[self.navigationController popViewControllerAnimated:YES];	
}
-(void)loginDismissed:(NSNotification*)note {
	if ([[[note userInfo] valueForKey:@"sourceID"] intValue] == BlioBookSourceOnlineStore) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioLoginFinished object:[BlioStoreManager sharedInstance]];
		[self.tableView reloadData];
	}
}


#pragma mark -
#pragma mark View lifecycle

/*
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self.tableView reloadData];
	
	CGFloat viewHeight = self.tableView.contentSize.height;
	if (viewHeight > 600) viewHeight = 600;
	self.contentSizeForViewInPopover = CGSizeMake(320, viewHeight);	
	
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
    return [subControllers count];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	UITableViewController * tableVC = (UITableViewController*)[subControllers objectAtIndex:section];
    return [tableVC tableView:tableView numberOfRowsInSection:0];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewController * tableVC = (UITableViewController*)[subControllers objectAtIndex:indexPath.section];
	if (tableVC) {
		NSIndexPath * newIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
		return [tableVC tableView:tableView cellForRowAtIndexPath:newIndexPath];
	}
	return nil;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	UITableViewController * tableVC = (UITableViewController*)[subControllers objectAtIndex:section];
	return tableVC.title;
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	UITableViewController * tableVC = (UITableViewController*)[subControllers objectAtIndex:section];
	return [tableVC tableView:tableView titleForFooterInSection:0];
}
/*

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	cell.textLabel.textAlignment = UITextAlignmentLeft;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	switch ( [indexPath section] ) {
		case 0:
			[cell.textLabel setText:@"Device Registration"];
			break;
		case 1:
			[cell.textLabel setText:@"Archive Settings"];
			break;
		default:
			break;
	}
	
    return cell;
}
*/

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
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
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
/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	BlioPaidBooksSettingsController * paidBooksController = nil;
	BlioArchiveSettingsViewController * archiveSettingsViewController = nil;
	switch ( [indexPath section] ) {
		case 0:
			paidBooksController = [[BlioPaidBooksSettingsController alloc] init];
			[self.navigationController pushViewController:paidBooksController animated:YES];
			[paidBooksController release];
			break;
		case 1:
			archiveSettingsViewController = [[BlioArchiveSettingsViewController alloc] init];
			[self.navigationController pushViewController:archiveSettingsViewController animated:YES];
			[archiveSettingsViewController release];
			break;
		default:
			break;
	}
}
*/
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


- (void)dealloc {
	self.subControllers = nil;
    [super dealloc];
}


@end

