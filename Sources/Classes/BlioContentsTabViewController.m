//
//  BlioContentsTabViewController.m
//  BlioApp
//
//  Created by matt on 15/01/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioContentsTabViewController.h"

@interface BlioContentsTabBookmarksViewController : UITableViewController
@end

@interface BlioContentsTabNotesViewController : UITableViewController
@end

@implementation BlioContentsTabViewController

@synthesize contentsController, bookmarksController, notesController, bookView, delegate, doneButton;

- (void)dealloc {
    self.contentsController = nil;
    self.bookmarksController = nil;
    self.notesController = nil;
    self.bookView = nil;
    self.delegate = nil;
    self.doneButton = nil;
    [super dealloc];
}

- (id)initWithBookView:(UIView<BlioBookView> *)aBookView {
        
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
        self.contentsController = aContentsController;
        self.bookmarksController = aBookmarksController;
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
    
    return self;
}

- (void)changeTab:(id)sender {
    
    NSUInteger selectedTab = [sender selectedSegmentIndex];
    switch (selectedTab) {
        case 0:
            [self popToRootViewControllerAnimated:NO];
            break;
        case 1:
            [self popToRootViewControllerAnimated:NO];
            [self pushViewController:self.bookmarksController animated:NO];
            break;
        case 2:
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
    if ([(NSObject *)self.delegate respondsToSelector:@selector(dismissContents:)])
        [(NSObject *)self.delegate performSelector:@selector(dismissContents:) withObject:sender];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];


}

- (void)viewWillAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
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
    return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell...
	
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


- (void)dealloc {
    [super dealloc];
}


@end

@implementation BlioContentsTabNotesViewController

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
    return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell...
	
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


- (void)dealloc {
    [super dealloc];
}


@end


