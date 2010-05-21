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
#import "BlioAlertManager.h"
#import "BlioStoreManager.h"

@implementation BlioStoreMyVaultController

@synthesize fetchedResultsController;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize processingDelegate,noResultsLabel,maxLayoutPageEquivalentCount;

- (id)init {
    if ((self = [super initWithStyle:UITableViewStylePlain])) {
        self.title = NSLocalizedString(@"My Vault",@"\"My Vault\" view controller header");
        UITabBarItem* theItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"My Vault",@"\"My Vault\" button title") image:[UIImage imageNamed:@"icon-vault.png"] tag:kBlioStoreMyVaultTag];
        self.tabBarItem = theItem;
        [theItem release];
    }
    return self;
}
-(void) loadView {
	[super loadView];
	noResultsLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
	noResultsLabel.text = NSLocalizedString(@"There are no books in your vault.",@"\"There are no books in your vault.\" indicator"); 
	noResultsLabel.textAlignment = UITextAlignmentCenter;
	noResultsLabel.font = [UIFont systemFontOfSize:14.0];
	noResultsLabel.textColor = [UIColor colorWithRed:108.0/255.0 green:108.0/255.0 blue:108.0/255.0 alpha:1.0];
	noResultsLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:noResultsLabel];

}
- (void)viewDidLoad {
    [super viewDidLoad];
}
-(void)loginDismissed:(NSNotification*)note {
	if ([[[note userInfo] valueForKey:@"sourceID"] intValue] == BlioBookSourceOnlineStore) {
		if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) {
			[[BlioStoreManager sharedInstance] retrieveBooksForSourceID:BlioBookSourceOnlineStore];
		}
		else {
//			[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"For Your Information...",@"\"For Your Information...\" Alert message title")
//										 message:[NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"LOGIN_REQUIRED_FOR_UPDATING_PAID_BOOKS_VAULT",nil,[NSBundle mainBundle],@"Login is required to update your Vault. In the meantime, only previously synced books will display.",@"Alert message informing the end-user that login is required to update the Vault. In the meantime, previously synced books will display.")]
//										delegate:self
//							   cancelButtonTitle:@"OK"
//							   otherButtonTitles:nil];			
		}
		[self fetchResults];
	}
}
- (void)fetchResults {
	NSError *error = nil; 
    NSManagedObjectContext *moc = [self managedObjectContext]; 
	if (!moc) NSLog(@"WARNING: ManagedObjectContext is nil inside BlioStoreMyVaultController!");
	
	[self calculateMaxLayoutPageEquivalentCount];
    NSFetchRequest *request = [[NSFetchRequest alloc] init]; 
    NSSortDescriptor *libraryPositionSort = [[NSSortDescriptor alloc] initWithKey:@"libraryPosition" ascending:NO];
    NSArray *sorters = [NSArray arrayWithObject:libraryPositionSort]; 
    [libraryPositionSort release];
    
    [request setFetchBatchSize:30]; // Never fetch more than 30 books at one time
    [request setEntity:[NSEntityDescription entityForName:@"BlioMockBook" inManagedObjectContext:moc]];
    [request setSortDescriptors:sorters];
	[request setPredicate:[NSPredicate predicateWithFormat:@"processingState <= %@ && sourceID == %@", [NSNumber numberWithInt:kBlioMockBookProcessingStatePlaceholderOnly],[NSNumber numberWithInt:BlioBookSourceOnlineStore]]];

    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc]
															 initWithFetchRequest:request
															 managedObjectContext:moc
															 sectionNameKeyPath:nil
															 cacheName:nil];
    [request release];
    
    [aFetchedResultsController setDelegate:self];
    [aFetchedResultsController performFetch:&error];
	
    if (error) 
        NSLog(@"Error loading from persistent store: %@, %@", error, [error userInfo]);
	
	self.fetchedResultsController = aFetchedResultsController;
    [aFetchedResultsController release];
	
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeChangesFromContextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
	[self.tableView reloadData];	
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) {
		[[BlioStoreManager sharedInstance] retrieveBooksForSourceID:BlioBookSourceOnlineStore];
		[self fetchResults];
	}
	else {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDismissed:) name:BlioLoginFinished object:[BlioStoreManager sharedInstance]];
		[[BlioStoreManager sharedInstance] requestLoginForSourceID:BlioBookSourceOnlineStore];
	}	
}
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

-(void) calculateMaxLayoutPageEquivalentCount {
	
	// calculateMaxLayoutPageEquivalentCount is deactivated because we have decided to have all reading progress bars display as the same size (instead of relative size); we are intentionally returning prematurely.	
	return;

	NSManagedObjectContext * moc = [self managedObjectContext];
	
	NSFetchRequest *maxFetch = [[NSFetchRequest alloc] init];
	[maxFetch setEntity:[NSEntityDescription entityForName:@"BlioMockBook" inManagedObjectContext:moc]];
	[maxFetch setResultType:NSDictionaryResultType];
	[maxFetch setPredicate:[NSPredicate predicateWithFormat:@"processingState <= %@ && sourceID == %@", [NSNumber numberWithInt:kBlioMockBookProcessingStatePlaceholderOnly],[NSNumber numberWithInt:BlioBookSourceOnlineStore]]];

	NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:@"layoutPageEquivalentCount"];
	NSExpression *maxExpression = [NSExpression expressionForFunction:@"max:" arguments: [NSArray arrayWithObject:keyPathExpression]];
	NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
	[expressionDescription setName:@"maxLayoutPageEquivalentCount"];
	[expressionDescription setExpression:maxExpression];
	[expressionDescription setExpressionResultType:NSDecimalAttributeType];
	[maxFetch setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];
	
	// Execute the fetch.
	NSError *maxError = nil;
	NSArray *objects = nil;
	objects = [moc executeFetchRequest:maxFetch error:&maxError];
	
	if (maxError) {
		NSLog(@"Error finding max layoutPageEquivalentCount: %@, %@", maxError, [maxError userInfo]);
	}
	else if (objects && ([objects count] > 0))
	{
		NSLog(@"[objects count]: %i",[objects count]);
		maxLayoutPageEquivalentCount = [[[objects objectAtIndex:0] valueForKey:@"maxLayoutPageEquivalentCount"] unsignedIntValue];
		NSLog(@"max layoutPageEquivalentCount value found: %u",maxLayoutPageEquivalentCount);
	}
	
	[maxFetch release];
	[expressionDescription release];
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
	if (bookCount == 0) {
		noResultsLabel.frame = self.view.bounds;
		noResultsLabel.hidden = NO;
	}
	else noResultsLabel.hidden = YES;
	return bookCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

            return kBlioLibraryListRowHeight;
}
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
//	NSLog(@"willDisplayCell");
	if ([indexPath row] % 2) {
		cell.backgroundColor = [UIColor whiteColor];
	}
	else {                        
		cell.backgroundColor = [UIColor colorWithRed:(226.0/255) green:(225.0/255) blue:(231.0/255) alpha:1];
	}
}
// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *ListCellIdentifier = @"BlioLibraryListCellIdentifier";
	
	BlioLibraryListCell *cell;
	
	cell = (BlioLibraryListCell *)[tableView dequeueReusableCellWithIdentifier:ListCellIdentifier];
	if (cell == nil) {
		cell = [[[BlioLibraryListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ListCellIdentifier] autorelease];
	} 
	
	[self configureTableCell:cell atIndexPath:indexPath];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // This is intentionally empty.
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
//		NSLog(@"BlioStoreMyVaultController controllerWillChangeContent");
	//    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath {
//		NSLog(@"BlioStoreMyVaultController controller:didChangeObject");
	
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
//	 	NSLog(@"BlioStoreMyVaultController controllerDidChangeContent");
	//   [self.tableView endUpdates];
	[self calculateMaxLayoutPageEquivalentCount];
	[self.tableView reloadData];
	// for debugging purposes
	//	NSArray * testArray = [self.fetchedResultsController fetchedObjects];
	//	for (NSInteger i = 0; i < [testArray count]; i++) {
	//		NSLog(@"mo index: %i, libraryPosition: %i",i,[[[[self.fetchedResultsController fetchedObjects] objectAtIndex:i] valueForKey:@"libraryPosition"] intValue]);
	//	}
	
}

#pragma mark -
#pragma mark Core Data Multi-Threading
- (void)mergeChangesFromContextDidSaveNotification:(NSNotification *)notification {
//	NSLog(@"BlioStoreMyVaultController mergeChangesFromContextDidSaveNotification entered");
}



- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.processingDelegate = nil;
	self.fetchedResultsController = nil;
	self.noResultsLabel = nil;
	self.managedObjectContext = nil;
    [super dealloc];
}


@end

