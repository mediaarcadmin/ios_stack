//
//  BlioStoreMyVaultController.m
//  BlioApp
//
//  Created by matt on 05/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioStoreMyVaultController.h"
#import "BlioMockBook.h"
#import "BlioLibraryViewController.h"

@implementation BlioStoreMyVaultController

@synthesize vaultManager = _vaultManager;
@synthesize fetchedResultsController;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize processingDelegate;

- (id)initWithVaultManager:(BlioBookVaultManager*)vm {
    if ((self = [super initWithStyle:UITableViewStylePlain])) {
        self.title = @"My Vault";
        self.vaultManager = vm;
        UITabBarItem* theItem = [[UITabBarItem alloc] initWithTitle:@"My Vault" image:[UIImage imageNamed:@"icon-vault.png"] tag:kBlioStoreMyVaultTag];
        self.tabBarItem = theItem;
        [theItem release];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	NSError *error = nil; 
    NSManagedObjectContext *moc = [self managedObjectContext]; 
	if (!moc) NSLog(@"WARNING: ManagedObjectContext is nil inside BlioStoreMyVaultController!");
    // Load any persisted books
    // N.B. Do not set a predicate on this request, if you do there is a risk that
    // the fetchedResultsController won't auto-update correctly
    NSFetchRequest *request = [[NSFetchRequest alloc] init]; 
    NSSortDescriptor *positionSort = [[NSSortDescriptor alloc] initWithKey:@"position" ascending:NO];
    NSArray *sorters = [NSArray arrayWithObject:positionSort]; 
    [positionSort release];
    
    [request setFetchBatchSize:30]; // Never fetch more than 30 books at one time
    [request setEntity:[NSEntityDescription entityForName:@"BlioMockBook" inManagedObjectContext:moc]];
    [request setSortDescriptors:sorters];
	[request setPredicate:[NSPredicate predicateWithFormat:@"processingComplete == %@ && sourceID == %@", [NSNumber numberWithInt:kBlioMockBookProcessingStatePlaceholderOnly],[NSNumber numberWithInt:BlioBookSourceOnlineStore]]];

    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc]
															 initWithFetchRequest:request
															 managedObjectContext:moc
															 sectionNameKeyPath:nil
															 cacheName:@"BlioFetchedBooks"];
    [request release];
    
    [aFetchedResultsController setDelegate:self];
    [aFetchedResultsController performFetch:&error];
	
    if (error) 
        NSLog(@"Error loading from persistent store: %@, %@", error, [error userInfo]);
	
	self.fetchedResultsController = aFetchedResultsController;
    [aFetchedResultsController release];
	
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	
	[self.tableView reloadData];	
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

-(void) configureTableCell:(BlioLibraryListCell*)cell atIndexPath:(NSIndexPath*)indexPath {
	cell.book = [self.fetchedResultsController objectAtIndexPath:indexPath];
	cell.delegate = self;
	
	if ([indexPath row] % 2)
		cell.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"row-light.png"]] autorelease];
	else                         
		cell.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"row-dark.png"]] autorelease];
	
	cell.showsReorderControl = YES;	
}
-(void) pauseProcessingForBook:(BlioMockBook*)book {
	[self.processingDelegate pauseProcessingForBook:book];
}
-(void) enqueueBook:(BlioMockBook*)book {
	[self.processingDelegate enqueueBook:book];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSUInteger count = [[self.fetchedResultsController sections] count];
    if (count == 0) {
        count = 1;
    }
    return count;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSArray *sections = [self.fetchedResultsController sections];
    NSUInteger bookCount = 0;
    if ([sections count]) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
        bookCount = [sectionInfo numberOfObjects];
    }
	return bookCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

            return kBlioLibraryListRowHeight;
}
/*
 - (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
 NSUInteger row = [indexPath row];
 if (row%2 == 1) cell.backgroundColor = [UIColor colorWithRed:(226.0/255) green:(225.0/255) blue:(231.0/255) alpha:1];
 else cell.backgroundColor = [UIColor whiteColor];
 }
 */
// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *ListCellOddIdentifier = @"BlioLibraryListCellOdd";
	static NSString *ListCellEvenIdentifier = @"BlioLibraryListCellEven";
	BlioLibraryListCell *cell;
	
	if ([indexPath row] % 2) {
		cell = (BlioLibraryListCell *)[tableView dequeueReusableCellWithIdentifier:ListCellEvenIdentifier];
		if (cell == nil) {
			cell = [[[BlioLibraryListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ListCellEvenIdentifier] autorelease];
		} 
		//                cell.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"row-light.png"]] autorelease];
	} else {   
		cell = (BlioLibraryListCell *)[tableView dequeueReusableCellWithIdentifier:ListCellOddIdentifier];
		if (cell == nil) {
			cell = [[[BlioLibraryListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ListCellOddIdentifier] autorelease];
		} 
		//                cell.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"row-dark.png"]] autorelease];
	}
	
	[self configureTableCell:cell atIndexPath:indexPath];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	return cell;
	
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
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
#pragma mark Fetched Results Controller Delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	//	NSLog(@"controllerWillChangeContent");
	//    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath {
	//	NSLog(@"controller didChangeObject");
	
		//switch(type) {
				
		//	case NSFetchedResultsChangeInsert:
				//				[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
				//								 withRowAnimation:UITableViewRowAnimationFade];
				//break;
				// this will always be user-instigated				
				//			case NSFetchedResultsChangeDelete:
				//				[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
				//								 withRowAnimation:UITableViewRowAnimationFade];
				//				break;
				
		//	case NSFetchedResultsChangeUpdate:
				//				[self configureTableCell:(BlioLibraryListCell*)[tableView cellForRowAtIndexPath:indexPath]
				//							 atIndexPath:indexPath];
				// this will always be user-instigated
				//			case NSFetchedResultsChangeMove:
				//				[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
				//								 withRowAnimation:UITableViewRowAnimationFade];
				//				[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
				//								 withRowAnimation:UITableViewRowAnimationFade];
				//				break;
		//}
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	// 	NSLog(@"controllerDidChangeContent");
	//   [self.tableView endUpdates];
		[self.tableView reloadData];
	// for debugging purposes
	//	NSArray * testArray = [self.fetchedResultsController fetchedObjects];
	//	for (NSInteger i = 0; i < [testArray count]; i++) {
	//		NSLog(@"mo index: %i, position: %i",i,[[[[self.fetchedResultsController fetchedObjects] objectAtIndex:i] valueForKey:@"position"] intValue]);
	//	}
	
}
/*
#pragma mark -
#pragma mark Core Data Multi-Threading
- (void)mergeChangesFromContextDidSaveNotification:(NSNotification *)notification {
	//	NSLog(@"mergeChangesFromContextDidSaveNotification entered");
    // Fault in all updated objects
	NSArray* updates = [[notification.userInfo objectForKey:NSUpdatedObjectsKey] allObjects];
    for (NSManagedObject *object in updates) {
        [[self.managedObjectContext objectWithID:[object objectID]] willAccessValueForKey:nil];
    }
	//	for (NSInteger i = [updates count]-1; i >= 0; i--)
	//	{
	//		[[managedObjectContext objectWithID:[[updates objectAtIndex:i] objectID]] willAccessValueForKey:nil];
	//	}
    
	// Merge
	[[self managedObjectContext] mergeChangesFromContextDidSaveNotification:notification];
	//    NSArray *updatedObjects = [[notification userInfo] valueForKey:NSUpdatedObjectsKey];
	//    if ([updatedObjects count]) {
	//        [self.tableView reloadData];
	//        NSLog(@"objects updated");
	//    }
	//    NSLog(@"Did save");
}

*/

- (void)dealloc {
	self.vaultManager = nil;
	self.processingDelegate = nil;
	self.fetchedResultsController = nil;
	self.managedObjectContext = nil;
    [super dealloc];
}


@end

