//
//  BlioContentsTabViewController.m
//  BlioApp
//
//  Created by matt on 15/01/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioContentsTabViewController.h"

#define MAINLABEL_TAG 1
#define SECONDLABEL_TAG 2

typedef enum {
    kBlioContentsTabViewTabContents = 0,
    kBlioContentsTabViewTabBookmarks = 1,
    kBlioContentsTabViewTabNotes = 2
} BlioContentsTabViewTab;

@interface BlioContentsTabContentsViewController : EucBookContentsTableViewController
@end


@interface BlioContentsTabBookmarksViewController : UITableViewController {
    BlioMockBook *book;
    NSManagedObject *selectedBookmark;
    UIView<BlioBookView> *bookView;
}

@property (nonatomic, retain) BlioMockBook *book;
@property (nonatomic, retain) NSManagedObject *selectedBookmark;
@property (nonatomic, retain) UIView<BlioBookView> *bookView;

@end

@interface BlioContentsTabNotesViewController : UITableViewController {
    BlioMockBook *book;
    NSManagedObject *selectedNote;
    UIView<BlioBookView> *bookView;
}

@property (nonatomic, retain) BlioMockBook *book;
@property (nonatomic, retain) NSManagedObject *selectedNote;
@property (nonatomic, retain) UIView<BlioBookView> *bookView;

@end

@implementation BlioContentsTabViewController

@synthesize contentsController, bookmarksController, notesController, bookView, book, delegate, doneButton, tabSegment;

- (void)dealloc {
    self.contentsController = nil;
    self.bookmarksController = nil;
    self.notesController = nil;
    self.bookView = nil;
    self.book = nil;
    self.delegate = nil;
    self.doneButton = nil;
    self.tabSegment = nil;
    [super dealloc];
}

- (id)initWithBookView:(UIView<BlioBookView> *)aBookView book:(BlioMockBook *)aBook {
        
    UIViewController *aRootVC = [[UIViewController alloc] init];
    
    BlioContentsTabContentsViewController *aContentsController = [[BlioContentsTabContentsViewController alloc] init];
    aContentsController.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    aContentsController.dataSource = aBookView.contentsDataSource;
    aContentsController.currentSectionUuid = [aBookView.contentsDataSource sectionUuidForPageNumber:aBookView.pageNumber];
    
    BlioContentsTabBookmarksViewController *aBookmarksController = [[BlioContentsTabBookmarksViewController alloc] initWithStyle:UITableViewStylePlain];
    aBookmarksController.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    BlioContentsTabNotesViewController *aNotesController = [[BlioContentsTabNotesViewController alloc] initWithStyle:UITableViewStylePlain];
    aNotesController.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
	if ((self = [super initWithRootViewController:aRootVC])) {
        self.bookView = aBookView;
        self.book = aBook;
        self.contentsController = aContentsController;
        [self.contentsController setDelegate:self];
        [self pushViewController:self.contentsController animated:NO];
        
        [aBookmarksController setBook:aBook];
        [aBookmarksController setBookView:aBookView]; // Needed to get display page number
        self.bookmarksController = aBookmarksController;
        
        [aNotesController setBook:aBook];
        [aNotesController setBookView:aBookView]; // Needed to get display page number
        self.notesController = aNotesController;
        
        UIColor *tintColor = [UIColor colorWithRed:160.0f / 256.0f green:190.0f / 256.0f  blue:190.0f / 256.0f  alpha:1.0f];
        
        UIBarButtonItem *aDoneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissTabView:)];
        self.doneButton = aDoneButton;
        [aDoneButton release];
                
        NSMutableArray *tabItems = [NSMutableArray array];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [tabItems addObject:item];
        [item release];
        
        NSArray *tabTitles = [NSArray arrayWithObjects: @"Contents", @"Bookmarks", @"Notes", nil];
        UISegmentedControl *aTabSegmentedControl = [[UISegmentedControl alloc] initWithItems:tabTitles];
        aTabSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        aTabSegmentedControl.tintColor = tintColor;
        aTabSegmentedControl.selectedSegmentIndex = 0;
        [aTabSegmentedControl addTarget:self action:@selector(changeTab:) forControlEvents:UIControlEventValueChanged];
        item = [[UIBarButtonItem alloc] initWithCustomView:aTabSegmentedControl];
        self.tabSegment = aTabSegmentedControl;
        [aTabSegmentedControl release];
        [tabItems addObject:item];
        [item release];
        
        item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [tabItems addObject:item];
        [item release];
        
        [self setToolbarHidden:NO];
        [self.toolbar setTintColor:tintColor];
        [self.navigationBar setTintColor:tintColor];
        
        [self.contentsController.navigationItem setLeftBarButtonItem:self.doneButton];
        [self.contentsController setToolbarItems:[NSArray arrayWithArray:tabItems]];
        [self.bookmarksController.navigationItem setLeftBarButtonItem:self.doneButton];
        [self.bookmarksController setToolbarItems:[NSArray arrayWithArray:tabItems]];
        [self.notesController.navigationItem setLeftBarButtonItem:self.doneButton];
        [self.notesController setToolbarItems:[NSArray arrayWithArray:tabItems]];
    }
    
    [aContentsController release];
    [aBookmarksController release];
    [aNotesController release];
    
    return self;
}

- (void)changeTab:(id)sender {  
    [self popToRootViewControllerAnimated:NO];

    BlioContentsTabViewTab selectedTab = (BlioContentsTabViewTab)[sender selectedSegmentIndex];
    switch (selectedTab) {
        case kBlioContentsTabViewTabContents:
            [self pushViewController:self.contentsController animated:NO];
            break;
        case kBlioContentsTabViewTabBookmarks:
            [self pushViewController:self.bookmarksController animated:NO];
            break;
        case kBlioContentsTabViewTabNotes:
            [self pushViewController:self.notesController animated:NO];
            break;
    }    
}

- (void)setDelegate:(id)newDelegate {
    delegate = newDelegate;
}

- (void)bookContentsTableViewController:(EucBookContentsTableViewController *)controller didSelectSectionWithUuid:(NSString *)uuid {
    [self performSelector:@selector(dismissTabView:) withObject:self];
}

- (void)dismissTabView:(id)sender {
    BlioContentsTabViewTab selectedTab = (BlioContentsTabViewTab)[self.tabSegment selectedSegmentIndex];
    switch (selectedTab) {
        case kBlioContentsTabViewTabContents: {
            NSString *selectedUuid = [self.contentsController selectedUuid];
            if (nil != selectedUuid) {
                if ([self.delegate respondsToSelector:@selector(goToContentsUuid:animated:)])
                    [self.delegate goToContentsUuid:selectedUuid animated:YES];
            }
        }  break;
        case kBlioContentsTabViewTabBookmarks: {
            if (nil != self.bookmarksController.selectedBookmark) {
                BlioBookmarkRange *aBookmarkRange = [BlioBookmarkRange bookmarkRangeWithPersistentBookmarkRange:[self.bookmarksController.selectedBookmark valueForKey:@"range"]];
                if ([self.delegate respondsToSelector:@selector(goToContentsBookmarkRange:animated:)])
                    [self.delegate goToContentsBookmarkRange:aBookmarkRange animated:NO];
            }
        }  break;
        case kBlioContentsTabViewTabNotes: {
            NSManagedObject *note = self.notesController.selectedNote;
            if (nil != note) {
                BlioBookmarkRange *range = [BlioBookmarkRange bookmarkRangeWithPersistentBookmarkRange:[note valueForKey:@"range"]];
                if ([self.delegate respondsToSelector:@selector(goToContentsBookmarkRange:animated:)])
                    [self.delegate goToContentsBookmarkRange:range animated:NO];
                
                if ([self.delegate respondsToSelector:@selector(displayNote:atRange:animated:)]) {
                    [self.delegate displayNote:note atRange:range animated:YES];
       //             BOOL animated = YES;
//                    NSMethodSignature * mySignature = [[self.delegate class] instanceMethodSignatureForSelector:@selector(displayNote:atRange:animated:)];
//                    NSInvocation * myInvocation = [NSInvocation invocationWithMethodSignature:mySignature];    
//                    [myInvocation setTarget:self.delegate];    
//                    [myInvocation setSelector:@selector(displayNote:atRange:animated:)];
//                    [myInvocation setArgument:&note atIndex:2];
//                    [myInvocation setArgument:&range atIndex:3];
//                    [myInvocation setArgument:&animated atIndex:4];
//                    [myInvocation performSelector:@selector(invoke) withObject:nil afterDelay:0.2f];
                }
            }
            
        }   break;
    }   
    
    if ([self.delegate respondsToSelector:@selector(dismissContentsTabView:)])
        [self.delegate performSelector:@selector(dismissContentsTabView:) withObject:self];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
}

- (void)deleteBookmark:(NSManagedObject *)bookmark {
    if ([self.delegate respondsToSelector:@selector(deleteBookmark:)])
        [self.delegate performSelector:@selector(deleteBookmark:) withObject:bookmark];
}

- (void)deleteNote:(NSManagedObject *)bookmark {
    if ([self.delegate respondsToSelector:@selector(deleteNote:)])
        [self.delegate performSelector:@selector(deleteNote:) withObject:bookmark];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];

    [[UIApplication sharedApplication] endIgnoringInteractionEvents];

}

/*
- (void)viewWillAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    BlioContentsTabViewTab selectedTab = (BlioContentsTabViewTab)[self.tabSegment selectedSegmentIndex];
    switch (selectedTab) {
        case kBlioContentsTabViewTabContents: {
            NSString *selectedUuid = [self.contentsController selectedUuid];
            if (nil != selectedUuid) {
                if ([self.delegate respondsToSelector:@selector(goToContentsUuid:animated:)])
                    [self.delegate goToContentsUuid:selectedUuid animated:YES];
            }
        }  break;
        case kBlioContentsTabViewTabBookmarks: {
            if (nil != self.bookmarksController.selectedBookmark) {
                BlioBookmarkRange *aBookmarkRange = [BlioBookmarkRange bookmarkRangeWithPersistentBookmarkRange:[self.bookmarksController.selectedBookmark valueForKey:@"range"]];
                if ([self.delegate respondsToSelector:@selector(goToContentsBookmarkRange:animated:)])
                    [self.delegate goToContentsBookmarkRange:aBookmarkRange animated:NO];
            }
        }  break;
        case kBlioContentsTabViewTabNotes: {
            NSManagedObject *note = self.notesController.selectedNote;
            if (nil != note) {
                BlioBookmarkRange *range = [BlioBookmarkRange bookmarkRangeWithPersistentBookmarkRange:[note valueForKey:@"range"]];
                if ([self.delegate respondsToSelector:@selector(goToContentsBookmarkRange:animated:)])
                    [self.delegate goToContentsBookmarkRange:range animated:NO];
                
                if ([self.delegate respondsToSelector:@selector(displayNote:atRange:animated:)])
                    [self.delegate displayNote:note atRange:range animated:YES];
            }
                     
        }   break;
    }   
}
*/

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if ([self.delegate respondsToSelector:@selector(willRotateToInterfaceOrientation:duration:)])
        [self.delegate willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if ([self.delegate respondsToSelector:@selector(didRotateFromInterfaceOrientation:)])
        [self.delegate didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

@end

@implementation BlioContentsTabContentsViewController
/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
@end


@implementation BlioContentsTabBookmarksViewController

@synthesize book, selectedBookmark, bookView;

- (void)dealloc {
    self.book = nil;
    self.selectedBookmark = nil;
    self.bookView = nil;
    [super dealloc];
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
     self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    return [[self.book sortedBookmarks] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger row = [indexPath row];
    UILabel *mainLabel, *secondLabel;
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        mainLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, 65.0, 44.0)] autorelease];
        mainLabel.tag = MAINLABEL_TAG;
        mainLabel.textColor = [UIColor darkGrayColor];
        mainLabel.backgroundColor = [UIColor clearColor];
        mainLabel.font = [UIFont systemFontOfSize:17.0f];
        mainLabel.textAlignment = UITextAlignmentRight;
        mainLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
        [cell.contentView addSubview:mainLabel];
        
        secondLabel = [[[UILabel alloc] initWithFrame:CGRectMake(83.0, 0.0, 220.0, 44.0)] autorelease];
        secondLabel.tag = SECONDLABEL_TAG;
        secondLabel.backgroundColor = [UIColor clearColor];
        secondLabel.font = [UIFont systemFontOfSize:17.0];
        secondLabel.textAlignment = UITextAlignmentLeft;
        secondLabel.textColor = [UIColor blackColor];
        secondLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
        [cell.contentView addSubview:secondLabel];
    } else {
        mainLabel = (UILabel *)[cell.contentView viewWithTag:MAINLABEL_TAG];
        secondLabel = (UILabel *)[cell.contentView viewWithTag:SECONDLABEL_TAG];
    }

    
    // Set up the cell...
    NSArray *sortedBookmarks = [self.book sortedBookmarks];
    NSManagedObject *currentBookmark = [sortedBookmarks objectAtIndex:row];
    BlioBookmarkRange *aBookmarkRange = [BlioBookmarkRange bookmarkRangeWithPersistentBookmarkRange:[currentBookmark valueForKey:@"range"]];    
    
    NSInteger pageNum;
    if ([self.bookView respondsToSelector:@selector(pageNumberForBookmarkRange:)]) {
        pageNum = [self.bookView pageNumberForBookmarkRange:aBookmarkRange];
    } else {
        BlioBookmarkAbsolutePoint *aBookMarkPoint = [BlioBookmarkAbsolutePoint bookmarkAbsolutePointWithBookmarkPoint:aBookmarkRange.startPoint];
        pageNum = [self.bookView pageNumberForBookmarkPoint:aBookMarkPoint];
    }
    
    NSString *displayPage = [[self.bookView contentsDataSource] displayPageNumberForPageNumber:pageNum];
    
    mainLabel.text = [NSString stringWithFormat:@"p.%@", displayPage];
    secondLabel.text = [currentBookmark valueForKey:@"bookmarkText"];
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Setting the selectedBookmarkPoint and then dismissing the view, rather 
    // than just going to the bookmarkPoint directly offers teh flexibility to dismiss the
    // modal view and then animate the goto
    NSArray *sortedBookmarks = [self.book sortedBookmarks];
    self.selectedBookmark = [sortedBookmarks objectAtIndex:[indexPath row]];
    
    [self.navigationController performSelector:@selector(dismissTabView:) withObject:nil];
}


 // Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source        
        NSArray *sortedBookmarks = [self.book sortedBookmarks];
        NSManagedObject *currentBookmark = [sortedBookmarks objectAtIndex:[indexPath row]];
        
        [self.navigationController performSelector:@selector(deleteBookmark:) withObject:currentBookmark];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
}
 

@end

@implementation BlioContentsTabNotesViewController

@synthesize book, selectedNote, bookView;

- (void)dealloc {
    self.book = nil;
    self.selectedNote = nil;
    self.bookView = nil;
    [super dealloc];
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
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
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
    return [[self.book sortedNotes] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger row = [indexPath row];
    UILabel *mainLabel, *secondLabel;
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        mainLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, 65.0, 44.0)] autorelease];
        mainLabel.tag = MAINLABEL_TAG;
        mainLabel.textColor = [UIColor darkGrayColor];
        mainLabel.backgroundColor = [UIColor clearColor];
        mainLabel.font = [UIFont systemFontOfSize:17.0f];
        mainLabel.textAlignment = UITextAlignmentRight;
        mainLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
        [cell.contentView addSubview:mainLabel];
        
        secondLabel = [[[UILabel alloc] initWithFrame:CGRectMake(83.0, 0.0, 220.0, 44.0)] autorelease];
        secondLabel.tag = SECONDLABEL_TAG;
        secondLabel.backgroundColor = [UIColor clearColor];
        secondLabel.font = [UIFont boldSystemFontOfSize:17.0];
        secondLabel.textAlignment = UITextAlignmentLeft;
        secondLabel.textColor = [UIColor blackColor];
        secondLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
        [cell.contentView addSubview:secondLabel];
    } else {
        mainLabel = (UILabel *)[cell.contentView viewWithTag:MAINLABEL_TAG];
        secondLabel = (UILabel *)[cell.contentView viewWithTag:SECONDLABEL_TAG];
    }
    
    
    // Set up the cell...
    NSArray *sortedNotes = [self.book sortedNotes];
    NSManagedObject *currentNote = [sortedNotes objectAtIndex:row];
    BlioBookmarkRange *aBookmarkRange = [BlioBookmarkRange bookmarkRangeWithPersistentBookmarkRange:[currentNote valueForKey:@"range"]];    

    NSInteger pageNum;
    if ([self.bookView respondsToSelector:@selector(pageNumberForBookmarkRange:)]) {
        pageNum = [self.bookView pageNumberForBookmarkRange:aBookmarkRange];
    } else {
        BlioBookmarkAbsolutePoint *aBookMarkPoint = [BlioBookmarkAbsolutePoint bookmarkAbsolutePointWithBookmarkPoint:aBookmarkRange.startPoint];
        pageNum = [self.bookView pageNumberForBookmarkPoint:aBookMarkPoint];
    }
    
    NSString *displayPage = [[self.bookView contentsDataSource] displayPageNumberForPageNumber:pageNum];
        
    mainLabel.text = [NSString stringWithFormat:@"p.%@", displayPage];
    secondLabel.text = [currentNote valueForKey:@"noteText"];
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Setting the selectedBookmarkPoint and then dismissing the view, rather 
    // than just going to the bookmarkPoint directly offers the flexibility to dismiss the
    // modal view and then animate the goto
    NSArray *sortedNotes = [self.book sortedNotes];
    self.selectedNote = [sortedNotes objectAtIndex:[indexPath row]];
    
    [self.navigationController performSelector:@selector(dismissTabView:) withObject:nil];
}


 // Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source        
        NSArray *sortedNotes = [self.book sortedNotes];
        NSManagedObject *currentNote = [sortedNotes objectAtIndex:[indexPath row]];
        
        [self.navigationController performSelector:@selector(deleteNote:) withObject:currentNote];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
}

@end


