//
//  BlioStoreArchiveViewController.m
//  BlioApp
//
//  Created by matt on 05/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioStoreArchiveViewController.h"
#import "BlioBook.h"
#import "BlioLibraryViewController.h"
#import "BlioAlertManager.h"
#import "BlioStoreManager.h"
#import "BlioDrmSessionManager.h"
#import "BlioAppSettingsConstants.h"
#import "Reachability.h"
#import "BlioStoreHelper.h"
#import "BlioLoginService.h"
#import "BlioIdentityProvidersViewController.h"

#define ARCHIVE_DELETE_WARNING_TAG 15
#define ARCHIVE_DELETE_ERROR_TAG 15

@interface BlioStoreArchiveViewController()
@property (nonatomic, retain) BlioBook* currBook;
@end

@implementation BlioStoreArchiveViewController

@synthesize currBook;
@synthesize fetchedResultsController;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize processingDelegate,noResultsLabel,maxLayoutPageEquivalentCount;
@synthesize activityIndicatorView;

- (id)init {
    if ((self = [super initWithStyle:UITableViewStylePlain])) {
        self.title = NSLocalizedString(@"Archive",@"\"Archive\" view controller title");
        UITabBarItem* theItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Archive",@"\"Archive\" button title") image:[UIImage imageNamed:@"icon-vault.png"] tag:kBlioStoreMyVaultTag];
        self.tabBarItem = theItem;
		self.currBook = nil;
        [theItem release];
        viewHasAppearedBefore = NO;
    }
    return self;
}
-(void) loadView {
	[super loadView];
	noResultsLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
	noResultsLabel.textAlignment = UITextAlignmentCenter;
	noResultsLabel.font = [UIFont systemFontOfSize:14.0];
	noResultsLabel.textColor = [UIColor colorWithRed:108.0/255.0 green:108.0/255.0 blue:108.0/255.0 alpha:1.0];
	noResultsLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	noResultsLabel.hidden = YES;
	[self.view addSubview:noResultsLabel];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}
- (void)viewDidLoad {
    [super viewDidLoad];
	BlioStoreHelper * helper = [[BlioStoreManager sharedInstance] storeHelperForSourceID:BlioBookSourceOnlineStore];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBlioStoreRetrieveBooksStarted:) name:BlioStoreRetrieveBooksStarted object:helper];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBlioStoreRetrieveBooksFinished:) name:BlioStoreRetrieveBooksFinished object:helper];
	
	CGRect mainScreenBounds = [[UIScreen mainScreen] bounds];
	CGFloat activityIndicatorDiameter = 50.0f;
	self.activityIndicatorView = [[[BlioRoundedRectActivityView alloc] initWithFrame:CGRectMake((mainScreenBounds.size.width-activityIndicatorDiameter)/2, (mainScreenBounds.size.height-activityIndicatorDiameter)/2, activityIndicatorDiameter, activityIndicatorDiameter)] autorelease];
	[[[UIApplication sharedApplication] keyWindow] addSubview:activityIndicatorView];
	userNum = [[BlioStoreManager sharedInstance] currentUserNum];
    if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore])
        [self fetchResults];
}
-(void)onBlioStoreRetrieveBooksStarted:(NSNotification*)note {
	NSLog(@"%@", NSStringFromSelector(_cmd));
	[self.activityIndicatorView startAnimating];
	[self.tableView reloadData];
}
-(void)onBlioStoreRetrieveBooksFinished:(NSNotification*)note {
	NSLog(@"%@", NSStringFromSelector(_cmd));
	[self.activityIndicatorView stopAnimating];
	[self.tableView reloadData];
}
-(void)loginDismissed:(NSNotification*)note {
	if ([[[note userInfo] valueForKey:@"sourceID"] intValue] == BlioBookSourceOnlineStore) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioLoginFinished object:[BlioStoreManager sharedInstance]];
		if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) {
			NSInteger newUserNum = [[BlioStoreManager sharedInstance] currentUserNum];
			if (newUserNum != userNum) {
				userNum = newUserNum;
                // When called only here, table view was not updated after initial login.
				//[self fetchResults];
			}
            [self fetchResults];

		}
		else {
			// Show alert?
			userDismissedLogin = YES;
		}
	}
    [self.activityIndicatorView stopAnimating];
}
- (void)fetchResults {
	NSError *error = nil; 
    NSManagedObjectContext *moc = [self managedObjectContext]; 
	if (!moc) NSLog(@"WARNING: ManagedObjectContext is nil inside BlioStoreArchiveViewController!");
	
	[self calculateMaxLayoutPageEquivalentCount];
    NSFetchRequest *request = [[NSFetchRequest alloc] init]; 
    NSSortDescriptor *libraryPositionSort = [[NSSortDescriptor alloc] initWithKey:@"libraryPosition" ascending:NO];
    NSArray *sorters = [NSArray arrayWithObject:libraryPositionSort]; 
    [libraryPositionSort release];
    
    [request setFetchBatchSize:30]; // Never fetch more than 30 books at one time
    [request setEntity:[NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:moc]];
    [request setSortDescriptors:sorters];
//	[request setPredicate:[NSPredicate predicateWithFormat:@"processingState <= %@ && sourceID == %@", [NSNumber numberWithInt:kBlioBookProcessingStatePlaceholderOnly],[NSNumber numberWithInt:BlioBookSourceOnlineStore]]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"processingState != %@ && sourceID == %@ && userNum == %@ && transactionType != %@", [NSNumber numberWithInt:kBlioBookProcessingStateComplete],[NSNumber numberWithInt:BlioBookSourceOnlineStore],[NSNumber numberWithInt:userNum],[NSNumber numberWithInt:BlioTransactionTypePreorder]]];

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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeChangesFromContextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
	[self.tableView reloadData];	
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
 */

- (void)viewDidAppear:(BOOL)animated {
	NSLog(@"viewDidAppear");
    [super viewDidAppear:animated];
	self.activityIndicatorView.hidden = NO;
	if ([[BlioStoreManager sharedInstance] storeHelperForSourceID:BlioBookSourceOnlineStore].isRetrievingBooks) {
		[self.activityIndicatorView startAnimating];
	}		
	
	if (userDismissedLogin && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		userDismissedLogin = NO;
		return;
	}
	if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] != NotReachable) {
		if ([[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore]) {
            if (![[NSUserDefaults standardUserDefaults] boolForKey:kBlioHasRestoredPurchasedBooksKey] && [[NSUserDefaults standardUserDefaults] integerForKey:kBlioDownloadNewBooksDefaultsKey] >= 0) {
                self.processingDelegate.notifyProcessingComplete = YES;
            }
			[[BlioStoreManager sharedInstance] retrieveBooksForSourceID:BlioBookSourceOnlineStore];
			// The following is an instructional alert view that only shows once; we've decided to disable it for now, since the Archive view is not as prominent with paid books automatically downloading.
//			if (![[NSUserDefaults standardUserDefaults] objectForKey:@"AlertArchive"]) {
//				[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"AlertArchive"];
//				[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Retrieving Your Books",@"\"Retrieving Your Books\" alert message title") 
//											 message:NSLocalizedStringWithDefaultValue(@"INTRO_ARCHIVE_ALERT",nil,[NSBundle mainBundle],@"The Archive is where you'll find your recently purchased books; although these books have been purchased, they still need to be downloaded to your device. Tap on the \"load\" button to the right of a book's title to start downloading, then tap on the \"Done\" button to see your book's progress in the Library!",@"Alert Text encouraging the end-user to go to start downloading paid books in the archive.")
//											delegate:nil
//								   cancelButtonTitle:@"OK"
//								   otherButtonTitles:nil];		
//			}
			
		}
		else {
            [self.activityIndicatorView startAnimating];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDismissed:) name:BlioLoginFinished object:[BlioStoreManager sharedInstance]];
            if (viewHasAppearedBefore)
                // We no longer repeatedly prompt for login after a user has canceled login.  
                //[self requestLogin];
                [self.activityIndicatorView stopAnimating];
            else
                [self performSelector:@selector(requestLogin) withObject:nil afterDelay:1.0f];
		}		
	}
	else {
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"No Connection",@"\"No Connection\" alert message title")
									 message:NSLocalizedStringWithDefaultValue(@"INTERNET_REQUIRED_FOR_VAULT",nil,[NSBundle mainBundle],@"An internet connection is required to update your Archive.",@"Alert message when the user views the Archive screen without an Internet connection.")
									delegate:nil 
						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
						   otherButtonTitles:nil];		
	}
    viewHasAppearedBefore = YES;
}

-(void)requestLogin {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDismissed:) name:BlioLoginFinished object:[BlioStoreManager sharedInstance]];
    [[BlioStoreManager sharedInstance] requestLoginForSourceID:BlioBookSourceOnlineStore forceLoginDisplayUponFailure:YES];

}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
//	[self.activityIndicatorView stopAnimating];
	self.activityIndicatorView.hidden = YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioStoreRetrieveBooksStarted object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioStoreRetrieveBooksFinished object:nil];
	if (self.activityIndicatorView)
        [self.activityIndicatorView removeFromSuperview];
	self.activityIndicatorView = nil;

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
-(void) reprocessCoverThumbnailsForBook:(BlioBook*)aBook {
	[self.processingDelegate reprocessCoverThumbnailsForBook:aBook];
}
-(void) pauseProcessingForBook:(BlioBook*)book {
	[self.processingDelegate pauseProcessingForBook:book];
}

-(void) enqueueBook:(BlioBook*)book {
	NSLog(@"reachability: %i",[[Reachability reachabilityForInternetConnection] currentReachabilityStatus]);
	if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Attention",@"\"Attention\" alert message title") 
									 message:NSLocalizedStringWithDefaultValue(@"INTERNET_REQUIRED_TO_RESTORE_VAULT_BOOK",nil,[NSBundle mainBundle],@"An internet connection is required to download this book.",@"Alert message when the user tries to download a Vault book without an Internet connection.")
									delegate:nil 
						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
						   otherButtonTitles:nil];
		return;
	}
	[self.processingDelegate enqueueBook:book];
}

/*
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1) {
		if ([[BlioStoreManager sharedInstance] setDeviceRegistered:BlioDeviceRegisteredStatusRegistered forSourceID:BlioBookSourceOnlineStore] && currBook) [self enqueueBook:currBook];
//	else if ( currBook != nil )
//		[self enqueueBook:currBook]; 
	}
}
*/

-(void) calculateMaxLayoutPageEquivalentCount {
	
	// calculateMaxLayoutPageEquivalentCount is deactivated because we have decided to have all reading progress bars display as the same size (instead of relative size); we are intentionally returning prematurely.	
	return;

	NSManagedObjectContext * moc = [self managedObjectContext];
	
	NSFetchRequest *maxFetch = [[NSFetchRequest alloc] init];
	[maxFetch setEntity:[NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:moc]];
	[maxFetch setResultType:NSDictionaryResultType];
	[maxFetch setPredicate:[NSPredicate predicateWithFormat:@"processingState <= %@ && sourceID == %@", [NSNumber numberWithInt:kBlioBookProcessingStatePlaceholderOnly],[NSNumber numberWithInt:BlioBookSourceOnlineStore]]];

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
    BOOL isLoggedIn = [[BlioStoreManager sharedInstance] isLoggedInForSourceID:BlioBookSourceOnlineStore];
	if (bookCount == 0 || !isLoggedIn) {
		noResultsLabel.frame = self.view.bounds;
		noResultsLabel.hidden = NO;
		tableView.scrollEnabled = NO;
		if (!isLoggedIn) {
            noResultsLabel.text = NSLocalizedString(@"You must be logged in to view your Archive.",@"\"You must be logged in to view your Archive.\" indicator");
        }
        else if ([[BlioStoreManager sharedInstance] storeHelperForSourceID:BlioBookSourceOnlineStore].isRetrievingBooks)
            noResultsLabel.text = NSLocalizedString(@"Retrieving books into your Archive...",@"\"Retrieving books into your Archive.\" indicator");
        else
            noResultsLabel.text = NSLocalizedString(@"There are no books in your Archive.",@"\"There are no books in your Archive.\" indicator");
	}
	else {
		noResultsLabel.hidden = YES;
		tableView.scrollEnabled = YES;
	}
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
	
	BlioLibraryListCell * cell = nil;
	
	cell = (BlioLibraryListCell *)[tableView dequeueReusableCellWithIdentifier:ListCellIdentifier];
	if (cell == nil) {
		cell = [[[BlioLibraryListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ListCellIdentifier] autorelease];
	} 
    cell.delegate = self;
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


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        currBook = [self.fetchedResultsController objectAtIndexPath:indexPath];
		[BlioAlertManager showTaggedAlertWithTitle:NSLocalizedString(@"Delete from Archive",@"\"Delete from Archive\" alert message title")
                                           message:NSLocalizedStringWithDefaultValue(@"DELETE_FROM_ARCHIVE_EXPLANATION",nil,[NSBundle mainBundle],@"Deleting this book from your archive means that it will no longer be available to download.  Would you like to proceed?",@"alert message explaining the implications of deleting a book from the archive")
                                          delegate:self
                                               tag:ARCHIVE_DELETE_WARNING_TAG
                                 cancelButtonTitle:NSLocalizedString(@"No",@"\"No\" label for button used to cancel/dismiss alertview")
                                 otherButtonTitles: @"OK", nil];
       
    }
}


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
//		NSLog(@"BlioStoreArchiveViewController controllerWillChangeContent");
	//    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath {
//		NSLog(@"BlioStoreArchiveViewController controller:didChangeObject");
	
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
//	 	NSLog(@"BlioStoreArchiveViewController controllerDidChangeContent");
	//   [self.tableView endUpdates];
	[self calculateMaxLayoutPageEquivalentCount];
	[self.tableView reloadData];
	// for debugging purposes
	//	NSArray * testArray = [self.fetchedResultsController fetchedObjects];
	//	for (NSInteger i = 0; i < [testArray count]; i++) {
	//		NSLog(@"mo index: %i, libraryPosition: %i",i,[[[[self.fetchedResultsController fetchedObjects] objectAtIndex:i] valueForKey:@"libraryPosition"] intValue]);
	//	}
	
}

#pragma mark UIAlertViewDelegate methods

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            break;
        case 1:
            if (alertView.tag == ARCHIVE_DELETE_WARNING_TAG) {
                NSLog(@"Delete %@ from archive.", currBook.title);
                /*
                BookVaultSoap *vaultBinding = [[BookVault BookVaultSoap] retain];
                vaultBinding.logXMLInOut = YES;
                BookVault_DeleteBook* deleteBookRequest = [[BookVault_DeleteBook new] autorelease];
                deleteBookRequest.token = [[BlioStoreManager sharedInstance] tokenForSourceID:BlioBookSourceOnlineStore];
                deleteBookRequest.productTypeId = [currBook valueForKey:@"productType"];
                deleteBookRequest.ISBN = [currBook valueForKey:@"isbn"];
                [vaultBinding DeleteBookAsyncUsingParameters:deleteBookRequest delegate:self];
                [vaultBinding release];
                */
            }
            break;
        default:
            break;
    }
}

#pragma mark -
#pragma mark Core Data Multi-Threading
- (void)mergeChangesFromContextDidSaveNotification:(NSNotification *)notification {
//	NSLog(@"BlioStoreArchiveViewController mergeChangesFromContextDidSaveNotification entered");
}



- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	if (self.activityIndicatorView)
        [self.activityIndicatorView removeFromSuperview];
	self.activityIndicatorView = nil;
	self.processingDelegate = nil;
	self.fetchedResultsController = nil;
	self.noResultsLabel = nil;
	self.managedObjectContext = nil;
    [super dealloc];
}


@end

