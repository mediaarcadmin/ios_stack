//
//  BlioGetBooksImportViewController.m
//  BlioApp
//
//  Created by Don Shin on 10/7/10.
//  Copyright 2010 CrossComm, Inc. All rights reserved.
//

#import "BlioGetBooksImportViewController.h"
#import "BlioFileSharingManager.h"
#import "BlioProcessingStandardOperations.h"

@implementation BlioGetBooksImportViewController

@synthesize activityIndicatorView,importableBooks;
@synthesize processingDelegate = _processingDelegate;

#pragma mark -
#pragma mark Initialization


- (id)init {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
		self.title = NSLocalizedString(@"Import",@"\"Import\" view controller header");
		UITabBarItem* theItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Import",@"\"Import\" button title") image:[UIImage imageNamed:@"icon-import.png"] tag:kBlioGetBooksImportTag];
        self.tabBarItem = theItem;
    }
    return self;
}


-(void)onBlioFileSharingScanStarted:(NSNotification*)note {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(onBlioFileSharingScanStarted:) withObject:note waitUntilDone:NO];
		return;
	}
	NSLog(@"%@", NSStringFromSelector(_cmd));	
	[self.activityIndicatorView startAnimating];
	[self.tableView reloadData];
}
-(void)onBlioFileSharingScanUpdate:(NSNotification*)note {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(onBlioFileSharingScanUpdate:) withObject:note waitUntilDone:NO];
		return;
	}
	NSLog(@"%@", NSStringFromSelector(_cmd));	
	self.importableBooks = [[[BlioFileSharingManager sharedFileSharingManager] importableBooks] mutableCopy];
	[self.tableView reloadData];
}
-(void)onBlioFileSharingScanFinished:(NSNotification*)note {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(onBlioFileSharingScanFinished:) withObject:note waitUntilDone:NO];
		return;
	}
	NSLog(@"%@", NSStringFromSelector(_cmd));	
	[self.activityIndicatorView stopAnimating];
	self.importableBooks = [[[BlioFileSharingManager sharedFileSharingManager] importableBooks] mutableCopy];
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark View lifecycle

-(void)loadView {
	[super loadView];

	self.importableBooks = [[[BlioFileSharingManager sharedFileSharingManager] importableBooks] mutableCopy];
}
- (void)viewDidLoad {
	NSLog(@"%@", NSStringFromSelector(_cmd));
    [super viewDidLoad];
	CGRect mainScreenBounds = [[UIScreen mainScreen] bounds];
	CGFloat activityIndicatorDiameter = 50.0f;
	self.activityIndicatorView = [[[BlioRoundedRectActivityView alloc] initWithFrame:CGRectMake((mainScreenBounds.size.width-activityIndicatorDiameter)/2, (mainScreenBounds.size.height-activityIndicatorDiameter)/2, activityIndicatorDiameter, activityIndicatorDiameter)] autorelease];
	[[[UIApplication sharedApplication] keyWindow] addSubview:activityIndicatorView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingCompleteNotification:) name:BlioProcessingOperationCompleteNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingFailedNotification:) name:BlioProcessingOperationFailedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBlioFileSharingScanStarted:) name:BlioFileSharingScanStarted object:[BlioFileSharingManager sharedFileSharingManager]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBlioFileSharingScanFinished:) name:BlioFileSharingScanFinished object:[BlioFileSharingManager sharedFileSharingManager]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBlioFileSharingScanUpdate:) name:BlioFileSharingScanUpdate object:[BlioFileSharingManager sharedFileSharingManager]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBlioFileSharingImportAborted:) name:BlioFileSharingImportAborted object:nil];

	if (![BlioFileSharingManager sharedFileSharingManager].isScanningFileSharingDirectory) {
		[[BlioFileSharingManager sharedFileSharingManager] scanFileSharingDirectory];
	}
	else {
		[self.activityIndicatorView startAnimating];
	}	
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)onProcessingCompleteNotification:(NSNotification*)note {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(onProcessingCompleteNotification:) withObject:note waitUntilDone:NO];
		return;
	}
	if ([[note object] isKindOfClass:[BlioProcessingCompleteOperation class]] && [[[note userInfo] objectForKey:@"sourceID"] intValue] == BlioBookSourceFileSharing) {
		NSLog(@"BlioGetBooksImportViewController onProcessingCompleteNotification entered");
		NSInteger row = -1;
		for (int i = 0; i < [self.importableBooks count]; i++) {
			BlioImportableBook * importableBook = (BlioImportableBook*)[self.importableBooks objectAtIndex:i];
			if ([importableBook.sourceSpecificID isEqualToString:[[note userInfo] objectForKey:@"sourceSpecificID"]]) {
				row = i;
				break;
			}
		}
		if (row != -1) {
			[self.importableBooks removeObjectAtIndex:row];
			if ([self.importableBooks count] == 0) [self.tableView reloadData];
			else [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
		}
	}
}
- (void)onProcessingFailedNotification:(NSNotification*)note {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(onProcessingFailedNotification:) withObject:note waitUntilDone:NO];
		return;
	}
	if ([[note object] isKindOfClass:[BlioProcessingCompleteOperation class]] && [[[note userInfo] objectForKey:@"sourceID"] intValue] == BlioBookSourceFileSharing) {
		NSLog(@"BlioGetBooksImportViewController onProcessingFailedNotification entered");
/*
		NSInteger row = -1;
		for (int i = 0; i < [self.importableBooks count]; i++) {
			BlioImportableBook * importableBook = (BlioImportableBook*)[self.importableBooks objectAtIndex:i];
			if ([importableBook.sourceSpecificID isEqualToString:[[note userInfo] objectForKey:@"sourceSpecificID"]]) {
				row = i;
				break;
			}
		}
		if (row != -1) {
			UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
			UIActivityIndicatorView * cellActivityIndicatorView = (UIActivityIndicatorView *)[cell.imageView viewWithTag:kBlioMoreResultsCellActivityIndicatorViewTag];
			cellActivityIndicatorView.hidden = YES;
			[cellActivityIndicatorView stopAnimating];
			cell.imageView.image = nil;		
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;			
		}
 */
		[self.tableView reloadData];
	}		
}
- (void)onBlioFileSharingImportAborted:(NSNotification*)note {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(onBlioFileSharingImportAborted:) withObject:note waitUntilDone:NO];
		return;
	}
	if ([[note object] isKindOfClass:[BlioImportableBook class]]) {
		NSLog(@"BlioGetBooksImportViewController onBlioFileSharingImportAborted entered");
/*
		NSInteger row = -1;
		for (int i = 0; i < [self.importableBooks count]; i++) {
			BlioImportableBook * importableBook = (BlioImportableBook*)[self.importableBooks objectAtIndex:i];
			if (importableBook == [note object]) {
				row = i;
				break;
			}
		}
		NSLog(@"row: %i",row);
		NSLog(@"[NSThread isMainThread]: %i",[NSThread isMainThread]);
		if (row != -1) {
			UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
			NSLog(@"cell: %@",cell);
			NSLog(@"[cell.imageView viewWithTag:kBlioMoreResultsCellActivityIndicatorViewTag]: %@",[cell.imageView viewWithTag:kBlioMoreResultsCellActivityIndicatorViewTag]);
			cell.contentView.backgroundColor = [UIColor redColor];
			UIActivityIndicatorView * cellActivityIndicatorView = (UIActivityIndicatorView *)[cell.imageView viewWithTag:kBlioMoreResultsCellActivityIndicatorViewTag];
			cellActivityIndicatorView.hidden = YES;
			[cellActivityIndicatorView stopAnimating];
			cell.imageView.image = nil;		
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;			
		}
 */		
		[self.tableView reloadData];

	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	if (self.importableBooks) {
		return [importableBooks count];
	}
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	if ([self tableView:self.tableView numberOfRowsInSection:0] == 0) {
		if ([BlioFileSharingManager sharedFileSharingManager].isScanningFileSharingDirectory) return NSLocalizedStringWithDefaultValue(@"SCANNING_IMPORTABLE_BOOKS_EXPLANATION_FOOTER",nil,[NSBundle mainBundle],@"Blio is scanning your Documents folder for importable files. Please wait a moment...",@"Explanatory message that appears at the bottom of the Importable Books table within Import Books View, informing the user that Blio is scanning the Documents folder for importable files.");
		return NSLocalizedStringWithDefaultValue(@"NO_IMPORTABLE_BOOKS_EXPLANATION_FOOTER",nil,[NSBundle mainBundle],@"No files within your Documents folder can be imported. You can add files to your Documents folder by selecting your iOS device within iTunes, selecting the \"Apps\" tab at the top of your content area, then scrolling down to the \"File Sharing\" section.",@"Explanatory message that appears at the bottom of the Importable Books table within Import Books View, informing the user that there are no importable files available.");
	}
	if ([BlioFileSharingManager sharedFileSharingManager].isScanningFileSharingDirectory) return NSLocalizedStringWithDefaultValue(@"IMPORTABLE_BOOKS_FOUND_STILL_SCANNING_EXPLANATION_FOOTER",nil,[NSBundle mainBundle],@"Blio is still scanning your Documents folder for importable files. In the meantime, you may select a file above to move the file into your Blio Library.",@"Explanatory message that appears at the bottom of the Importable Books table within Import Books View, informing the user that the Documents folder is still being scanned, and providing brief instruction on how to import the displayed files in the meantime.");
	return NSLocalizedStringWithDefaultValue(@"IMPORTABLE_BOOKS_EXPLANATION_FOOTER",nil,[NSBundle mainBundle],@"The above files can be imported by Blio. Select a file above to move the file into your Blio Library.",@"Explanatory message that appears at the bottom of the Importable Books table within Import Books View, providing brief instruction on how to import the displayed files.");
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"ImportableBookCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		
		// add activity indicator
		UIActivityIndicatorView * cellActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		cellActivityIndicatorView.frame = CGRectMake(-kBlioImportBookCellActivityIndicatorViewWidth/3,-kBlioImportBookCellActivityIndicatorViewWidth/2,kBlioImportBookCellActivityIndicatorViewWidth,kBlioImportBookCellActivityIndicatorViewWidth);
		cellActivityIndicatorView.hidden = YES;
		
		cellActivityIndicatorView.hidesWhenStopped = YES;
		cellActivityIndicatorView.tag = kBlioImportBookCellActivityIndicatorViewTag;
		[cell.imageView addSubview:cellActivityIndicatorView];
		[cellActivityIndicatorView release];		
    }
    
    // Configure the cell...
	BlioImportableBook * importableBook = ((BlioImportableBook*)[self.importableBooks objectAtIndex:indexPath.row]);
	cell.textLabel.textAlignment = UITextAlignmentLeft;
	cell.textLabel.text = importableBook.fileName;
	cell.detailTextLabel.textAlignment = UITextAlignmentLeft;
	if (!importableBook.title || [importableBook.title length] == 0) {
		cell.detailTextLabel.text = @"";
	}
	else {
		cell.detailTextLabel.text = importableBook.title;
	}
	BlioProcessingCompleteOperation * completeOp = [self.processingDelegate processingCompleteOperationForSourceID:BlioBookSourceFileSharing sourceSpecificID:importableBook.fileName];
//	NSLog(@"completeOp: %@",completeOp);
	if (completeOp && ![completeOp isCancelled]) {
//		NSLog(@"showing activity indicator...");
		UIActivityIndicatorView * cellActivityIndicatorView = (UIActivityIndicatorView *)[cell.imageView viewWithTag:kBlioImportBookCellActivityIndicatorViewTag];
//		NSLog(@"cellActivityIndicatorView: %@",cellActivityIndicatorView);
		cellActivityIndicatorView.hidden = NO;
		[cellActivityIndicatorView startAnimating];			
		UIImage * emptyImage = [[UIImage alloc] init];
		cell.imageView.image = emptyImage;  // setting a UIImage object allows the view (and activity indicator subview) to show up
		cell.imageView.frame = CGRectMake(0, 0, kBlioImportBookCellActivityIndicatorViewWidth * 1.5, kBlioImportBookCellActivityIndicatorViewWidth);
		[emptyImage release];	
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	else {
//		NSLog(@"hiding activity indicator...");
		[(UIActivityIndicatorView *)[cell.imageView viewWithTag:kBlioImportBookCellActivityIndicatorViewTag] stopAnimating];
		cell.imageView.image = nil;		
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	BlioImportableBook * importableBook = ((BlioImportableBook*)[self.importableBooks objectAtIndex:indexPath.row]);
	BlioProcessingCompleteOperation * completeOp = [self.processingDelegate processingCompleteOperationForSourceID:BlioBookSourceFileSharing sourceSpecificID:importableBook.fileName];
	if (!completeOp) {
		BlioImportableBook* importableBook = (BlioImportableBook*)[self.importableBooks objectAtIndex:indexPath.row];
		[[BlioFileSharingManager sharedFileSharingManager] importBook:importableBook];
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		
		UIActivityIndicatorView * cellActivityIndicatorView = (UIActivityIndicatorView *)[[tableView cellForRowAtIndexPath:indexPath].imageView viewWithTag:kBlioImportBookCellActivityIndicatorViewTag];
		cellActivityIndicatorView.hidden = NO;
		[cellActivityIndicatorView startAnimating];	
		UIImage * emptyImage = [[UIImage alloc] init];
		[tableView cellForRowAtIndexPath:indexPath].imageView.image = emptyImage;  // setting a UIImage object allows the view (and activity indicator subview) to show up
		[tableView cellForRowAtIndexPath:indexPath].imageView.frame = CGRectMake(0, 0, kBlioImportBookCellActivityIndicatorViewWidth * 1.5, kBlioImportBookCellActivityIndicatorViewWidth);
		[emptyImage release];	
	}
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

-(void)viewDidUnload {
	[super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioProcessingOperationCompleteNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioProcessingOperationFailedNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioFileSharingScanStarted object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioFileSharingScanFinished object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioFileSharingScanUpdate object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioFileSharingImportAborted object:nil];

	self.activityIndicatorView = nil;
}


- (void)dealloc {
	if (self.activityIndicatorView) [self.activityIndicatorView removeFromSuperview];
	self.activityIndicatorView = nil;
	self.importableBooks = nil;
    [super dealloc];
}


@end

