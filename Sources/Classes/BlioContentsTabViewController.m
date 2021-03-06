//
//  BlioContentsTabViewController.m
//  BlioApp
//
//  Created by matt on 15/01/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioContentsTabViewController.h"
#import "BlioAutorotatingViewController.h"
#import <libEucalyptus/THUIDeviceAdditions.h>

#define MAINLABEL_TAG 1
#define SECONDLABEL_TAG 2
#define MINPOPOVERHEIGHT 88
#define MAXPOPOVERHEIGHT 585
#define POPOVERSURROUNDHEIGHT 75
#define POPOVERRESIZEDELAY 0.1f

typedef enum {
    kBlioContentsTabViewTabContents = 0,
    kBlioContentsTabViewTabBookmarks = 1,
    kBlioContentsTabViewTabNotes = 2 
} BlioContentsTabViewTab;

@interface BlioContentsTabContentsViewController : EucBookContentsTableViewController <EucBookContentsTableViewControllerDataSource> {
    id<EucBookContentsTableViewControllerDataSource> contentsDataSource;
    UIView<BlioBookView> *bookView;
}

@property (nonatomic, assign) id<EucBookContentsTableViewControllerDataSource> contentsDataSource;
@property (nonatomic, retain) UIView<BlioBookView> *bookView;

@end


@interface BlioContentsTabBookmarksViewController : BlioAutorotatingTableViewController {
    BlioBook *book;
    NSManagedObject *selectedBookmark;
    UIView<BlioBookView> *bookView;
}

@property (nonatomic, retain) BlioBook *book;
@property (nonatomic, retain) NSManagedObject *selectedBookmark;
@property (nonatomic, retain) UIView<BlioBookView> *bookView;

@end

@interface BlioContentsTabNotesViewController : BlioAutorotatingTableViewController {
    BlioBook *book;
    NSManagedObject *selectedNote;
    UIView<BlioBookView> *bookView;
}

@property (nonatomic, retain) BlioBook *book;
@property (nonatomic, retain) NSManagedObject *selectedNote;
@property (nonatomic, retain) UIView<BlioBookView> *bookView;

@end

@implementation BlioContentsTabViewController

@synthesize contentsController, bookmarksController, notesController, bookView, book, delegate, doneButton, tabSegment;
@synthesize popoverController;

- (void)dealloc {
    self.contentsController = nil;
    self.bookmarksController = nil;
    self.notesController = nil;
    self.bookView = nil;
    self.book = nil;
    self.delegate = nil;
    self.doneButton = nil;
    self.tabSegment = nil;
    self.popoverController = nil;
    [super dealloc];
}

- (id)initWithBookView:(UIView<BlioBookView> *)aBookView book:(BlioBook *)aBook delegate:(id<BlioContentsTabViewControllerDelegate>)aDelegate {
    
    isTOCActive = [aBook hasTOC];

    UIViewController *aRootVC = [[UIViewController alloc] init];

	// TODO: do not instantiate TOC view if isTOCActive is false to conserve memory
    BlioContentsTabContentsViewController *aContentsController = [[BlioContentsTabContentsViewController alloc] init];
    aContentsController.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    aContentsController.contentsDataSource = aBookView.contentsDataSource; // N.B. this needs to be set before the dataSource
    aContentsController.tableView.frame = CGRectMake(0, 0, 320, MINPOPOVERHEIGHT);
    aContentsController.maxContentHeight = MAXPOPOVERHEIGHT;
    
    BlioContentsTabBookmarksViewController *aBookmarksController = [[BlioContentsTabBookmarksViewController alloc] initWithStyle:UITableViewStylePlain];
    aBookmarksController.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    aBookmarksController.contentSizeForViewInPopover = CGSizeMake(320, MINPOPOVERHEIGHT);
    
    BlioContentsTabNotesViewController *aNotesController = [[BlioContentsTabNotesViewController alloc] initWithStyle:UITableViewStylePlain];
    aNotesController.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    aNotesController.contentSizeForViewInPopover = CGSizeMake(320, MINPOPOVERHEIGHT);

	if ((self = [super initWithRootViewController:aRootVC])) {
        self.delegate = aDelegate;
        self.bookView = aBookView;
        self.book = aBook;
        
        [aContentsController setBookView:aBookView]; // Needed to get display page number, needs to be set before the datasource
        [aContentsController setDataSource:aContentsController];
        
        self.contentsController = aContentsController;
        if (isTOCActive) [self pushViewController:self.contentsController animated:NO];
        [self.contentsController setDelegate:self];
        
        [aBookmarksController setBook:aBook];
        [aBookmarksController setBookView:aBookView]; // Needed to get display page number
        self.bookmarksController = aBookmarksController;
        if (!isTOCActive) [self pushViewController:self.bookmarksController animated:NO];
        
        [aNotesController setBook:aBook];
        [aNotesController setBookView:aBookView]; // Needed to get display page number
        self.notesController = aNotesController;
        
        UIColor *tintColor = [UIColor colorWithRed:160.0f / 256.0f green:190.0f / 256.0f  blue:190.0f / 256.0f  alpha:1.0f];
        
        UIBarButtonItem *aDoneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done",@"\"Done\" bar button") style:UIBarButtonItemStyleDone target:self action:@selector(dismissTabView:)];
        self.doneButton = aDoneButton;
        [aDoneButton release];
                
        NSMutableArray *tabItems = [NSMutableArray array];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [tabItems addObject:item];
        [item release];
        
        NSArray *tabTitles = [NSArray arrayWithObjects: NSLocalizedString(@"Contents",@"\"Contents\" segmented control title for BlioContentsTabViewController"), NSLocalizedString(@"Bookmarks",@"\"Bookmarks\" segmented control title for BlioContentsTabViewController"), NSLocalizedString(@"Notes",@"\"Notes\" segmented control title for BlioContentsTabViewController"), nil];
        UISegmentedControl *aTabSegmentedControl = [[UISegmentedControl alloc] initWithItems:tabTitles];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            if ([[UIDevice currentDevice] compareSystemVersion:@"7.0"] >= NSOrderedSame)
                aTabSegmentedControl.tintColor = nil;
            else {
                aTabSegmentedControl.tintColor = tintColor;
                aTabSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
            }
        }
        if (isTOCActive) aTabSegmentedControl.selectedSegmentIndex = 0;
		else {
			aTabSegmentedControl.selectedSegmentIndex = 1;
			[aTabSegmentedControl setEnabled:NO forSegmentAtIndex:0];
		}
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
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            if ([self.toolbar respondsToSelector:@selector(setBarTintColor:)]) {
                [self.toolbar setBarTintColor:tintColor];
                [self.navigationBar setBarTintColor:tintColor];
            }
            else {
                [self.toolbar setTintColor:tintColor];
                [self.navigationBar setTintColor:tintColor];
            }
            [self.contentsController.navigationItem setLeftBarButtonItem:self.doneButton];
            [self.bookmarksController.navigationItem setLeftBarButtonItem:self.doneButton];
            [self.notesController.navigationItem setLeftBarButtonItem:self.doneButton];
        } else {
            [self.contentsController.navigationItem setHidesBackButton:YES];
            [self.bookmarksController.navigationItem setHidesBackButton:YES];
            [self.notesController.navigationItem setHidesBackButton:YES];
        }
        
        [self.contentsController setToolbarItems:[NSArray arrayWithArray:tabItems]];
        [self.bookmarksController setToolbarItems:[NSArray arrayWithArray:tabItems]];
        [self.notesController setToolbarItems:[NSArray arrayWithArray:tabItems]];
    }
    
    [aRootVC release];
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

- (void)bookContentsTableViewController:(EucBookContentsTableViewController *)controller didSelectSectionWithIdentifier:(id)identifier {
    [self performSelector:@selector(dismissTabView:) withObject:self];
}

- (id)bookContentsTableViewControllerCurrentSectionIdentifier:(EucBookContentsTableViewController *)contentsTableViewController {
    return [self.delegate currentContentsSectionIdentifier];
}

- (void)dismissTabView:(id)sender {
    BlioContentsTabViewTab selectedTab = (BlioContentsTabViewTab)[self.tabSegment selectedSegmentIndex];
    switch (selectedTab) {
        case kBlioContentsTabViewTabContents: {
            id selectedContentsIdentifier = [self.contentsController selectedIdentifier];
            if (nil != selectedContentsIdentifier) {
                if ([self.delegate respondsToSelector:@selector(goToContentsSectionIdentifier:animated:)]) {
                    BOOL animated = YES;
                    NSMethodSignature * mySignature = [[self.delegate class] instanceMethodSignatureForSelector:@selector(goToContentsSectionIdentifier:animated:)];
                    NSInvocation * myInvocation = [NSInvocation invocationWithMethodSignature:mySignature];    
                    [myInvocation setTarget:self.delegate];  
                    [myInvocation setSelector:@selector(goToContentsSectionIdentifier:animated:)];
                    [myInvocation setArgument:&selectedContentsIdentifier atIndex:2];
                    [myInvocation setArgument:&animated atIndex:3];
                    [myInvocation retainArguments];
                    [myInvocation performSelector:@selector(invoke) withObject:nil afterDelay:0.2f];
                    
                }
            }
        }  break;
        case kBlioContentsTabViewTabBookmarks: {
            if (nil != self.bookmarksController.selectedBookmark) {
                BlioBookmarkRange *aBookmarkRange = [BlioBookmarkRange bookmarkRangeWithPersistentBookmarkRange:[self.bookmarksController.selectedBookmark valueForKey:@"range"]];
                if ([self.delegate respondsToSelector:@selector(goToContentsBookmarkRange:animated:)]) {                    
                    BOOL animated = YES;
                    NSMethodSignature * mySignature = [[self.delegate class] instanceMethodSignatureForSelector:@selector(goToContentsBookmarkRange:animated:)];
                    NSInvocation * myInvocation = [NSInvocation invocationWithMethodSignature:mySignature];    
                    [myInvocation setTarget:self.delegate];  
                    [myInvocation setSelector:@selector(goToContentsBookmarkRange:animated:)];
                    [myInvocation setArgument:&aBookmarkRange atIndex:2];
                    [myInvocation setArgument:&animated atIndex:3];
                    [myInvocation retainArguments];
                    [myInvocation performSelector:@selector(invoke) withObject:nil afterDelay:0.2f];
                }
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
                }
            }
            
        }   break;
    }   
    
    if ([self.delegate respondsToSelector:@selector(dismissContentsTabView:)])
        [self.delegate performSelector:@selector(dismissContentsTabView:) withObject:self];
    
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
	} else {
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
	}
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (duration) {
            if ([self.delegate respondsToSelector:@selector(willRotateToInterfaceOrientation:duration:)])
                [self.delegate willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
        }
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if ([self.delegate respondsToSelector:@selector(didRotateFromInterfaceOrientation:)])
            [self.delegate didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    } else {
        // Need to hide and show nav bar to workaround bug when rotating which hides the nav bar and toolbar
        [self setNavigationBarHidden:YES];
        [self setNavigationBarHidden:NO];
    }
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark Popover Delegate methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    if ([self.delegate respondsToSelector:@selector(dismissContentsTabView:)])
        [self.delegate performSelector:@selector(dismissContentsTabView:) withObject:self];
}

@end

@implementation BlioContentsTabContentsViewController

@synthesize contentsDataSource;
@synthesize bookView;

- (void)dealloc {
    [bookView release], bookView = nil;
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
        
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.navigationItem setTitle:NSLocalizedString(@"Jump to\u2026", "Title for Contents Popover")];
        [self.tableView setShowsVerticalScrollIndicator:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [self performSelector:@selector(adjustPopoverContentSize) withObject:nil afterDelay:POPOVERRESIZEDELAY];
    [super viewDidAppear:animated];
}

- (void)adjustPopoverContentSize {
    CGSize contentSize = self.tableView.contentSize;
    contentSize.height = MIN(MAX(contentSize.height, MINPOPOVERHEIGHT), MAXPOPOVERHEIGHT);
    contentSize.height += POPOVERSURROUNDHEIGHT; // Accomodates the toolbar and navbar

    [[(BlioContentsTabViewController *)self.navigationController popoverController] setPopoverContentSize:contentSize];
}

#pragma mark - EucBookContentsTableViewControllerDataSource

- (NSArray *)contentsTableViewControllerSectionIdentifiers:(EucBookContentsTableViewController *)contentsTableViewController {
    
    return [self.contentsDataSource contentsTableViewControllerSectionIdentifiers:contentsTableViewController];
}

- (THPair *)contentsTableViewController:(EucBookContentsTableViewController *)contentsTableViewController
presentationNameAndSubTitleForSectionIdentifier:(id)sectionIdentifier {
    
    return [self.contentsDataSource contentsTableViewController:contentsTableViewController
                presentationNameAndSubTitleForSectionIdentifier:sectionIdentifier];
}

- (NSUInteger)contentsTableViewController:(EucBookContentsTableViewController *)contentsTableViewController
                  pageIndexForSectionIdentifier:(id)sectionIdentifier {
    
    return [self.contentsDataSource contentsTableViewController:contentsTableViewController
                                  pageIndexForSectionIdentifier:sectionIdentifier];
}

// A "display number" i.e. cover -> nil, 2 -> @"1" etc;
// Could also do things like convert to roman numerals when appropriate.
- (NSString *)contentsTableViewController:(EucBookContentsTableViewController *)contentsTableViewController
            displayPageNumberForPageIndex:(NSUInteger)pageNumber {
    
    if ([self.bookView respondsToSelector:@selector(displayPageNumberForPageAtIndex:)]) {
        return [self.bookView displayPageNumberForPageAtIndex:pageNumber];
    } else {
        return [self.contentsDataSource contentsTableViewController:contentsTableViewController
                                      displayPageNumberForPageIndex:pageNumber];
    }
}

- (NSUInteger)contentsTableViewController:(EucBookContentsTableViewController *)contentsTableViewController
                      levelForSectionIdentifier:(id)sectionIdentifier {
    
    if ([self.contentsDataSource respondsToSelector:@selector(contentsTableViewController:levelForSectionUuid:)]) {
        return [self.contentsDataSource contentsTableViewController:contentsTableViewController
                                          levelForSectionIdentifier:sectionIdentifier];
    } else {
        return 0;
    }
    
}

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
     if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
         [self.navigationItem setTitle:NSLocalizedString(@"Jump to\u2026", "Title for Contents Popover")];
         [self.tableView setShowsVerticalScrollIndicator:NO];
     }
 }

- (void)viewDidAppear:(BOOL)animated {
    [self performSelector:@selector(adjustPopoverContentSize) withObject:nil afterDelay:POPOVERRESIZEDELAY];
    [super viewDidAppear:animated];
}

- (void)adjustPopoverContentSize {
    CGSize contentSize = self.tableView.contentSize;
    contentSize.height = MIN(MAX(contentSize.height, MINPOPOVERHEIGHT), MAXPOPOVERHEIGHT);
    contentSize.height += POPOVERSURROUNDHEIGHT; // Accomodates the toolbar and navbar
    

    [[(BlioContentsTabViewController *)self.navigationController popoverController] setPopoverContentSize:contentSize];
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
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        mainLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, 65.0, 44.0)] autorelease];
        mainLabel.tag = MAINLABEL_TAG;
        mainLabel.textColor = [UIColor darkGrayColor];
        mainLabel.backgroundColor = [UIColor clearColor];
        mainLabel.font = [UIFont systemFontOfSize:17.0f];
        mainLabel.textAlignment = UITextAlignmentRight;
        mainLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        [cell.contentView addSubview:mainLabel];
        
        secondLabel = [[[UILabel alloc] initWithFrame:CGRectMake(83.0, 0.0, 220.0, 44.0)] autorelease];
        secondLabel.tag = SECONDLABEL_TAG;
        secondLabel.backgroundColor = [UIColor clearColor];
        secondLabel.font = [UIFont systemFontOfSize:17.0];
        secondLabel.textAlignment = UITextAlignmentLeft;
        secondLabel.textColor = [UIColor blackColor];
        secondLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [cell.contentView addSubview:secondLabel];
    } else {
        mainLabel = (UILabel *)[cell.contentView viewWithTag:MAINLABEL_TAG];
        secondLabel = (UILabel *)[cell.contentView viewWithTag:SECONDLABEL_TAG];
    }

    
    // Set up the cell...
    NSArray *sortedBookmarks = [self.book sortedBookmarks];
    NSManagedObject *currentBookmark = [sortedBookmarks objectAtIndex:row];
    BlioBookmarkRange *aBookmarkRange = [BlioBookmarkRange bookmarkRangeWithPersistentBookmarkRange:[currentBookmark valueForKey:@"range"]];    
    
    NSString *displayPage = [self.bookView displayPageNumberForBookmarkPoint:aBookmarkRange.startPoint];
    //NSLog(@"[self.bookView contentsDataSource]: %@",[self.bookView contentsDataSource]);
	//NSLog(@"displayPage: %@",displayPage);
	if (displayPage) {
		mainLabel.text = displayPage;
	}
	else mainLabel.text = @"";
    secondLabel.text = [currentBookmark valueForKey:@"bookmarkText"];
	
	[cell setAccessibilityTraits:UIAccessibilityTraitButton];
	
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
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.navigationItem setTitle:NSLocalizedString(@"Jump to\u2026", "Title for Contents Popover")];
        [self.tableView setShowsVerticalScrollIndicator:NO];
    }
}


- (void)viewDidAppear:(BOOL)animated {
    [self performSelector:@selector(adjustPopoverContentSize) withObject:nil afterDelay:POPOVERRESIZEDELAY];
    [super viewDidAppear:animated];
}

- (void)adjustPopoverContentSize {
    CGSize contentSize = self.tableView.contentSize;
    contentSize.height = MIN(MAX(contentSize.height, MINPOPOVERHEIGHT), MAXPOPOVERHEIGHT);
    contentSize.height += POPOVERSURROUNDHEIGHT; // Accomodates the toolbar and navbar
    
    
    [[(BlioContentsTabViewController *)self.navigationController popoverController] setPopoverContentSize:contentSize];
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

- (void)setEditing:(BOOL)editing animated:(BOOL)animate {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		if ( editing )
			[[(BlioContentsTabViewController*)self.navigationController doneButton] setEnabled:NO];
		else 
			[[(BlioContentsTabViewController*)self.navigationController doneButton] setEnabled:YES];
	}
	[super setEditing:editing animated:animate];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger row = [indexPath row];
    UILabel *mainLabel, *secondLabel;
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        mainLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, 65.0, 44.0)] autorelease];
        mainLabel.tag = MAINLABEL_TAG;
        mainLabel.textColor = [UIColor darkGrayColor];
        mainLabel.backgroundColor = [UIColor clearColor];
        mainLabel.font = [UIFont systemFontOfSize:17.0f];
        mainLabel.textAlignment = UITextAlignmentRight;
        mainLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        [cell.contentView addSubview:mainLabel];
        
        secondLabel = [[[UILabel alloc] initWithFrame:CGRectMake(83.0, 0.0, 220.0, 44.0)] autorelease];
        secondLabel.tag = SECONDLABEL_TAG;
        secondLabel.backgroundColor = [UIColor clearColor];
        secondLabel.font = [UIFont boldSystemFontOfSize:17.0];
        secondLabel.textAlignment = UITextAlignmentLeft;
        secondLabel.textColor = [UIColor blackColor];
        secondLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [cell.contentView addSubview:secondLabel];
    } else {
        mainLabel = (UILabel *)[cell.contentView viewWithTag:MAINLABEL_TAG];
        secondLabel = (UILabel *)[cell.contentView viewWithTag:SECONDLABEL_TAG];
    }
    
    
    // Set up the cell...
    NSArray *sortedNotes = [self.book sortedNotes];
    NSManagedObject *currentNote = [sortedNotes objectAtIndex:row];
    BlioBookmarkRange *aBookmarkRange = [BlioBookmarkRange bookmarkRangeWithPersistentBookmarkRange:[currentNote valueForKey:@"range"]];    
    
    NSString *displayPage = [self.bookView displayPageNumberForBookmarkPoint:aBookmarkRange.startPoint];
        
    mainLabel.text = displayPage;
    secondLabel.text = [currentNote valueForKey:@"noteText"];
	
	[cell setAccessibilityTraits:UIAccessibilityTraitButton];
	
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


