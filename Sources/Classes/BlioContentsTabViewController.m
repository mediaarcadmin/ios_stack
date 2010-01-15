//
//  BlioContentsTabViewController.m
//  BlioApp
//
//  Created by matt on 15/01/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioContentsTabViewController.h"

static const CGFloat kBlioContentsTabToolbarHeight = 44;

@implementation BlioContentsTabViewController

@synthesize toolbar, contentsController, bookmarksController, notesController, bookView, delegate;

- (void)dealloc {
    self.toolbar = nil;
    self.contentsController = nil;
    self.bookmarksController = nil;
    self.notesController = nil;
    self.bookView = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithBookView:(UIView<BlioBookView> *)aBookView {
	if ((self = [super init])) {
        self.bookView = aBookView;
    }
    return self;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
    CGRect viewBounds = CGRectMake(0, 0, [UIScreen mainScreen].applicationFrame.size.width, [UIScreen mainScreen].applicationFrame.size.height);
    
    UIView *root = [[UIView alloc] initWithFrame:viewBounds];
    root.backgroundColor = [UIColor yellowColor];
    self.view = root;
    [root release];
    
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
    
    UIToolbar *aToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(viewBounds) - kBlioContentsTabToolbarHeight, CGRectGetWidth(viewBounds), kBlioContentsTabToolbarHeight)];
    [aToolbar setTintColor:tintColor];
    [aToolbar setItems:[NSArray arrayWithArray:tabItems]];
    
    [root addSubview:aToolbar];
    self.toolbar = aToolbar;
    [aToolbar release];
    
    EucBookContentsTableViewController *aContentsController = [[EucBookContentsTableViewController alloc] init];
    aContentsController.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    aContentsController.dataSource = self.bookView.contentsDataSource;
    aContentsController.delegate = self.delegate;        
    aContentsController.currentSectionUuid = [self.bookView.contentsDataSource sectionUuidForPageNumber:self.bookView.pageNumber];
    UINavigationController *aNC = [[UINavigationController alloc] initWithRootViewController:aContentsController];
    self.contentsController = aNC;
    [aContentsController release],
    [aNC release];
    
    [self.view insertSubview:self.contentsController.view belowSubview:self.toolbar];
    //[self pushViewController:self.contentsController animated:NO];
}

- (void)setDelegate:(id)newDelegate {
    delegate = newDelegate;
    [(EucBookContentsTableViewController *)[self.contentsController topViewController] setDelegate:delegate];
}


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
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

@end
