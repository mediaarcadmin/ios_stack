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

@interface BlioContentsTabBookmarksViewController : UITableViewController {
    NSMutableSet *bookmarks;
    NSManagedObject *selectedBookmark;
    UIView<BlioBookView> *bookView;
}

@property (nonatomic, retain) NSMutableSet *bookmarks;
@property (nonatomic, retain) NSManagedObject *selectedBookmark;
@property (nonatomic, retain) UIView<BlioBookView> *bookView;

@end

@interface BlioContentsTabNotesViewController : UITableViewController {
    NSMutableSet *notes;
    NSManagedObject *selectedNote;
    UIView<BlioBookView> *bookView;
}

@property (nonatomic, retain) NSMutableSet *notes;
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
        
    EucBookContentsTableViewController *aContentsController = [[EucBookContentsTableViewController alloc] init];
    aContentsController.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    aContentsController.dataSource = aBookView.contentsDataSource;
    aContentsController.currentSectionUuid = [aBookView.contentsDataSource sectionUuidForPageNumber:aBookView.pageNumber];
    
    BlioContentsTabBookmarksViewController *aBookmarksController = [[BlioContentsTabBookmarksViewController alloc] initWithStyle:UITableViewStylePlain];
    aBookmarksController.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    BlioContentsTabNotesViewController *aNotesController = [[BlioContentsTabNotesViewController alloc] initWithStyle:UITableViewStylePlain];
    aNotesController.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
	if ((self = [super initWithRootViewController:aContentsController])) {
        self.bookView = aBookView;
        self.book = aBook;
        self.contentsController = aContentsController;
        
        [aBookmarksController setBookmarks:[aBook mutableSetValueForKey:@"bookmarks"]];
        [aBookmarksController setBookView:aBookView]; // Needed to get display page number
        self.bookmarksController = aBookmarksController;
        
        [aNotesController setNotes:[aBook mutableSetValueForKey:@"notes"]];
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
    
    BlioContentsTabViewTab selectedTab = (BlioContentsTabViewTab)[sender selectedSegmentIndex];
    switch (selectedTab) {
        case kBlioContentsTabViewTabContents:
            [self popToRootViewControllerAnimated:NO];
            break;
        case kBlioContentsTabViewTabBookmarks:
            [self popToRootViewControllerAnimated:NO];
            [self pushViewController:self.bookmarksController animated:NO];
            break;
        case kBlioContentsTabViewTabNotes:
            [self popToRootViewControllerAnimated:NO];
            [self pushViewController:self.notesController animated:NO];
            break;
    }    
}

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
    //CGRect viewBounds = CGRectMake(0, 0, [UIScreen mainScreen].applicationFrame.size.width, [UIScreen mainScreen].applicationFrame.size.height);
    
//    UIView *root = [[UIView alloc] initWithFrame:viewBounds];
//    root.backgroundColor = [UIColor yellowColor];
//    self.view = root;
//    [root release];
    
    UIColor *tintColor = [UIColor colorWithRed:160.0f / 256.0f green:190.0f / 256.0f  blue:190.0f / 256.0f  alpha:1.0f];
    
    NSMutableArray *tabItems = [NSMutableArray array];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [tabItems addObject:item];
    [item release];
    
    NSArray *tabTitles = [NSArray arrayWithObjects: @"Contents", @"Bookmarks", @"Notes", nil];
    UISegmentedControl *aTabSegmentedControl = [[UISegmentedControl alloc] initWithItems:tabTitles];
    aTabSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    aTabSegmentedControl.tintColor = tintColor;
    item = [[UIBarButtonItem alloc] initWithCustomView:aTabSegmentedControl];
    [aTabSegmentedControl release];
    [tabItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [tabItems addObject:item];
    [item release];
    
    //UIToolbar *aToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(viewBounds) - kBlioContentsTabToolbarHeight, CGRectGetWidth(viewBounds), kBlioContentsTabToolbarHeight)];
    //[aToolbar setTintColor:tintColor];
    //[aToolbar setItems:[NSArray arrayWithArray:tabItems]];
    [self setToolbarItems:[NSArray arrayWithArray:tabItems]];
    [self setToolbarHidden:NO];
    
    //[root addSubview:aToolbar];
    //self.toolbar = aToolbar;
    //[aToolbar release];
    
//    EucBookContentsTableViewController *aContentsController = [[EucBookContentsTableViewController alloc] init];
//    aContentsController.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    aContentsController.dataSource = self.bookView.contentsDataSource;
//    aContentsController.delegate = self.delegate;        
//    aContentsController.currentSectionUuid = [self.bookView.contentsDataSource sectionUuidForPageNumber:self.bookView.pageNumber];
//    UINavigationController *aNC = [[UINavigationController alloc] initWithRootViewController:aContentsController];
//    //self.contentsController = aNC;
//    [aContentsController release],
//    [aNC release];
//    
//    [self.view insertSubview:self.contentsController.view belowSubview:self.toolbar];
    //[self pushViewController:self.contentsController animated:NO];
    self.navigationItem.leftBarButtonItem = self.doneButton;
    
    [self.topViewController.view setFrame:[[UIScreen mainScreen] applicationFrame]];
    self.view = self.topViewController.view;
}
*/
- (void)setDelegate:(id)newDelegate {
    delegate = newDelegate;
    [self.contentsController setDelegate:delegate];
}

- (void)dismissTabView:(id)sender {
    if ([self.delegate respondsToSelector:@selector(dismissContentsTabView:)])
        [self.delegate performSelector:@selector(dismissContentsTabView:) withObject:sender];
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


}

- (void)viewWillAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
    
    BlioContentsTabViewTab selectedTab = (BlioContentsTabViewTab)[self.tabSegment selectedSegmentIndex];
    switch (selectedTab) {
        case kBlioContentsTabViewTabNotes: {
            if (nil != self.notesController.selectedNote) {
                BlioBookmarkPoint *aBookMarkPoint = [[BlioBookmarkPoint alloc] init];
                aBookMarkPoint.ePubParagraphId = [[self.notesController.selectedNote valueForKey:@"ePubParagraphId"] integerValue];
                aBookMarkPoint.ePubWordOffset = [[self.notesController.selectedNote valueForKey:@"ePubWordOffset"] integerValue];
                aBookMarkPoint.ePubHyphenOffset = [[self.notesController.selectedNote valueForKey:@"ePubHyphenOffset"] integerValue];
                aBookMarkPoint.layoutPage = [[self.notesController.selectedNote valueForKey:@"layoutPage"] integerValue];
                if ([self.delegate respondsToSelector:@selector(goToContentsBookmarkPoint:animated:)])
                    [self.delegate goToContentsBookmarkPoint:aBookMarkPoint animated:NO];
                [aBookMarkPoint release];
            }
        } break;
        default:
            break;
    }   
}

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
                BlioBookmarkPoint *aBookMarkPoint = [[BlioBookmarkPoint alloc] init];
                aBookMarkPoint.ePubParagraphId = [[self.bookmarksController.selectedBookmark valueForKey:@"ePubParagraphId"] integerValue];
                aBookMarkPoint.ePubWordOffset = [[self.bookmarksController.selectedBookmark valueForKey:@"ePubWordOffset"] integerValue];
                aBookMarkPoint.ePubHyphenOffset = [[self.bookmarksController.selectedBookmark valueForKey:@"ePubHyphenOffset"] integerValue];
                aBookMarkPoint.layoutPage = [[self.bookmarksController.selectedBookmark valueForKey:@"layoutPage"] integerValue];
                if ([self.delegate respondsToSelector:@selector(goToContentsBookmarkPoint:animated:)])
                    [self.delegate goToContentsBookmarkPoint:aBookMarkPoint animated:YES];
                [aBookMarkPoint release];
            }
        }  break;
        case kBlioContentsTabViewTabNotes:
            if (nil != self.notesController.selectedNote) {
                if ([self.delegate respondsToSelector:@selector(showNote:animated:)])
                    [self.delegate showNote:self.notesController.selectedNote animated:YES];
            }
            break;
    }   
}

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

@end

@implementation BlioContentsTabBookmarksViewController

@synthesize bookmarks, selectedBookmark, bookView;

- (void)dealloc {
    self.bookmarks = nil;
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
    return [self.bookmarks count];
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
    NSSortDescriptor *sortPageDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"layoutPage" ascending:YES] autorelease];
    NSSortDescriptor *sortParaDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"ePubParagraphId" ascending:YES] autorelease];

    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortPageDescriptor, sortParaDescriptor, nil];
    NSArray *sortedBookmarks = [[self.bookmarks allObjects] sortedArrayUsingDescriptors:sortDescriptors];
    NSManagedObject *currentBookmark = [sortedBookmarks objectAtIndex:row];
    
    // Seems a bit pointless having to jump through these hoops to get the display name
    BlioBookmarkPoint *aBookMarkPoint = [[BlioBookmarkPoint alloc] init];
    aBookMarkPoint.ePubParagraphId = [[currentBookmark valueForKey:@"ePubParagraphId"] integerValue];
    aBookMarkPoint.ePubWordOffset = [[currentBookmark valueForKey:@"ePubWordOffset"] integerValue];
    aBookMarkPoint.ePubHyphenOffset = [[currentBookmark valueForKey:@"ePubHyphenOffset"] integerValue];
    aBookMarkPoint.layoutPage = [[currentBookmark valueForKey:@"layoutPage"] integerValue];    
    NSInteger pageNum = [self.bookView pageNumberForBookmarkPoint:aBookMarkPoint];
    [aBookMarkPoint release];
    NSString *displayPage = [[self.bookView contentsDataSource] displayPageNumberForPageNumber:pageNum];
    
    mainLabel.text = [NSString stringWithFormat:@"p.%@", displayPage];
    secondLabel.text = [currentBookmark valueForKey:@"bookmarkText"];
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Setting the selectedBookmarkPoint and then dismissing the view, rather 
    // than just going to the bookmarkPoint directly offers teh flexibility to dismiss the
    // modal view and then animate the goto
    NSSortDescriptor *sortPageDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"layoutPage" ascending:YES] autorelease];
    NSSortDescriptor *sortParaDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"ePubParagraphId" ascending:YES] autorelease];
    
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortPageDescriptor, sortParaDescriptor, nil];
    NSArray *sortedBookmarks = [[self.bookmarks allObjects] sortedArrayUsingDescriptors:sortDescriptors];
    self.selectedBookmark = [sortedBookmarks objectAtIndex:[indexPath row]];
    
    [self.navigationController performSelector:@selector(dismissTabView:) withObject:nil];
}


 // Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source        
        NSSortDescriptor *sortPageDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"layoutPage" ascending:YES] autorelease];
        NSSortDescriptor *sortParaDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"ePubParagraphId" ascending:YES] autorelease];
        
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sortPageDescriptor, sortParaDescriptor, nil];
        NSArray *sortedBookmarks = [[self.bookmarks allObjects] sortedArrayUsingDescriptors:sortDescriptors];
        NSManagedObject *currentBookmark = [sortedBookmarks objectAtIndex:[indexPath row]];
        
        [self.navigationController performSelector:@selector(deleteBookmark:) withObject:currentBookmark];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
}
 

@end

@implementation BlioContentsTabNotesViewController

@synthesize notes, selectedNote, bookView;

- (void)dealloc {
    self.notes = nil;
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
    return [self.notes count];
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
    NSSortDescriptor *sortPageDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"layoutPage" ascending:YES] autorelease];
    NSSortDescriptor *sortParaDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"ePubParagraphId" ascending:YES] autorelease];
    
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortPageDescriptor, sortParaDescriptor, nil];
    NSArray *sortedNotes = [[self.notes allObjects] sortedArrayUsingDescriptors:sortDescriptors];
    NSManagedObject *currentNote = [sortedNotes objectAtIndex:row];
    
    // Seems a bit pointless having to jump through these hoops to get the display name
    BlioBookmarkPoint *aBookMarkPoint = [[BlioBookmarkPoint alloc] init];
    aBookMarkPoint.ePubParagraphId = [[currentNote valueForKey:@"ePubParagraphId"] integerValue];
    aBookMarkPoint.ePubWordOffset = [[currentNote valueForKey:@"ePubWordOffset"] integerValue];
    aBookMarkPoint.ePubHyphenOffset = [[currentNote valueForKey:@"ePubHyphenOffset"] integerValue];
    aBookMarkPoint.layoutPage = [[currentNote valueForKey:@"layoutPage"] integerValue];    
    NSInteger pageNum = [self.bookView pageNumberForBookmarkPoint:aBookMarkPoint];
    [aBookMarkPoint release];
    NSString *displayPage = [[self.bookView contentsDataSource] displayPageNumberForPageNumber:pageNum];
    
    mainLabel.text = [NSString stringWithFormat:@"p.%@", displayPage];
    secondLabel.text = [currentNote valueForKey:@"noteText"];
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Setting the selectedBookmarkPoint and then dismissing the view, rather 
    // than just going to the bookmarkPoint directly offers teh flexibility to dismiss the
    // modal view and then animate the goto
    NSSortDescriptor *sortPageDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"layoutPage" ascending:YES] autorelease];
    NSSortDescriptor *sortParaDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"ePubParagraphId" ascending:YES] autorelease];
    
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortPageDescriptor, sortParaDescriptor, nil];
    NSArray *sortedNotes = [[self.notes allObjects] sortedArrayUsingDescriptors:sortDescriptors];
    self.selectedNote = [sortedNotes objectAtIndex:[indexPath row]];
    
    [self.navigationController performSelector:@selector(dismissTabView:) withObject:nil];
}


 // Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source        
        NSSortDescriptor *sortPageDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"layoutPage" ascending:YES] autorelease];
        NSSortDescriptor *sortParaDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"ePubParagraphId" ascending:YES] autorelease];
        
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sortPageDescriptor, sortParaDescriptor, nil];
        NSArray *sortedNotes = [[self.notes allObjects] sortedArrayUsingDescriptors:sortDescriptors];
        NSManagedObject *currentNotes = [sortedNotes objectAtIndex:[indexPath row]];
        
        [self.navigationController performSelector:@selector(deleteNote:) withObject:currentNotes];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
}

@end


