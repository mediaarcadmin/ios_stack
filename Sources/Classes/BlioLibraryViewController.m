//
//  BlioLibraryViewController.m
//  BlioApp
//
//  Created by James Montgomerie on 16/12/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "BlioLibraryViewController.h"
#import "BlioBookViewController.h"
#import "BlioLayoutView.h"
#import "BlioMockBook.h"
#import "BlioUIImageAdditions.h"
#import "BlioStoreTabViewController.h"
#import "BlioAppSettingsController.h"
#import "BlioLoginViewController.h"
#import "BlioBookVaultManager.h"
#import "BlioProcessingStandardOperations.h"
#import "BlioAccessibilitySegmentedControl.h"

static const CGFloat kBlioLibraryToolbarHeight = 44;

static const CGFloat kBlioLibraryListRowHeight = 76;
static const CGFloat kBlioLibraryListBookHeight = 76;
static const CGFloat kBlioLibraryListBookWidth = 53;
static const CGFloat kBlioLibraryListContentWidth = 220;

static const CGFloat kBlioLibraryGridRowHeight = 140;
static const CGFloat kBlioLibraryGridBookHeight = 140;
static const CGFloat kBlioLibraryGridBookWidth = 106;
static const CGFloat kBlioLibraryGridBookSpacing = 0;

static const CGFloat kBlioLibraryLayoutButtonWidth = 78;
static const CGFloat kBlioLibraryShadowXInset = 0.10276f; // Nasty hack to work out proportion of texture image is shadow
static const CGFloat kBlioLibraryShadowYInset = 0.07737f;

@interface BlioLibraryBookView : UIView {
    UIImageView *imageView;
    UIImageView *textureView;
    UIView *highlightView;
    BlioMockBook *book;
}

@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UIImageView *textureView;
@property (nonatomic, retain) UIView *highlightView;
@property (nonatomic, retain) BlioMockBook *book;
@property (nonatomic, readonly) UIImage *image;

- (void)setBook:(BlioMockBook *)newBook forLayout:(BlioLibraryLayout)layout;

@end

@interface BlioLibraryGridViewCell : MRGridViewCell {
    BlioLibraryBookView *bookView;
    UILabel *titleLabel;
    UILabel *authorLabel;
    UISlider *progressSlider;
    id delegate;
}

@property (nonatomic, retain) BlioLibraryBookView *bookView;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *authorLabel;
@property (nonatomic, retain) UISlider *progressSlider;
@property (nonatomic, assign) BlioMockBook *book;
@property (nonatomic, assign) id delegate;

@end

@interface BlioLibraryListCell : UITableViewCell {
    BlioLibraryBookView *bookView;
    UILabel *titleLabel;
    UILabel *authorLabel;
    UISlider *progressSlider;
    id delegate;
}

@property (nonatomic, retain) BlioLibraryBookView *bookView;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *authorLabel;
@property (nonatomic, retain) UISlider *progressSlider;
@property (nonatomic, assign) BlioMockBook *book;
@property (nonatomic, assign) id delegate;

@end

@interface BlioLibraryViewController (PRIVATE)
- (void)bookSelected:(BlioLibraryBookView *)bookView;
@end


@implementation BlioLibraryViewController

@synthesize currentBookView = _currentBookView;
@synthesize currentPoppedBookCover = _currentPoppedBookCover;
@synthesize libraryLayout = _libraryLayout;
@synthesize bookCoverPopped = _bookCoverPopped;
@synthesize firstPageRendered = _firstPageRendered;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize processingDelegate = _processingDelegate;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize gridView = _gridView;
@synthesize tableView = _tableView;
@synthesize vaultManager = _vaultManager;

- (id)init {
	if ((self = [super init])) {
		_didEdit = NO;
	}
	return self;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.currentBookView = nil;
    self.tableView = nil;
    self.currentPoppedBookCover = nil;
    self.managedObjectContext = nil;
    self.processingDelegate = nil;
    self.fetchedResultsController = nil;
	self.gridView = nil;
	self.tableView = nil;
    [super dealloc];
}

- (void)awakeFromNib {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(orientationChanged:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];

}

- (void)orientationChanged:(NSNotification *)notification {
    [self.view setNeedsLayout];
}

- (void)loadView {
	self.view = [[[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
	
	UIImageView * backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed: @"librarybackground.png"]];
	backgroundImageView.frame = self.view.bounds;
    backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:backgroundImageView];
	[backgroundImageView release];
    
	// UITableView subclass so that custom background is only drawn here
    UITableView *aTableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] bounds] style:UITableViewStylePlain];
    self.tableView = aTableView;
	[self.view addSubview:aTableView];
    [aTableView release];

	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	MRGridView *aGridView = [[MRGridView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.gridView = aGridView;
	[self.gridView setCellSize:CGSizeMake(kBlioLibraryGridBookWidth,kBlioLibraryGridBookHeight) withBorderSize:0];
	[self.view addSubview:aGridView];
    [aGridView release];
	self.gridView.gridDelegate = self;
	self.gridView.gridDataSource = self;
	
	self.vaultManager = [[BlioBookVaultManager alloc] init];
    
    NSMutableArray *libraryItems = [NSMutableArray array];
    UIBarButtonItem *item;
    
//    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
//    [libraryItems addObject:item];
//    [item release];

    item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button-sync.png"]
                                            style:UIBarButtonItemStyleBordered
                                           target:self 
                                           action:@selector(showLogin:)];
    [item setAccessibilityLabel:NSLocalizedString(@"Sync", @"Accessibility label for Library View Sync button")];
    [item setAccessibilityHint:NSLocalizedString(@"Syncs to Blio Account.", @"Accessibility label for Library View Sync hint")];
    [libraryItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [libraryItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button-getbooks.png"]
                                            style:UIBarButtonItemStyleBordered
                                           target:self 
                                           action:@selector(showStore:)];
    
    [item setAccessibilityLabel:NSLocalizedString(@"Get Books", @"Accessibility label for Library View Get Books button")];

    [libraryItems addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [libraryItems addObject:item];
    [item release];  
    
    item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button-settings.png"]
                                            style:UIBarButtonItemStyleBordered
                                           target:self 
                                           action:@selector(showSettings:)];
    
    [item setAccessibilityLabel:NSLocalizedString(@"Settings", @"Accessibility label for Library View Settings button")];

    [libraryItems addObject:item];
    [item release];
    
//    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
//    [libraryItems addObject:item];
//    [item release];  
    
    [self setToolbarItems:[NSArray arrayWithArray:libraryItems] animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.libraryLayout = kBlioLibraryLayoutGrid;
    self.tableView.hidden = YES;
	
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    UIEdgeInsets inset = UIEdgeInsetsMake(3, 0, 0, 0);
    
    NSArray *segmentImages = [NSArray arrayWithObjects:
                              [UIImage imageWithShadow:[UIImage imageNamed:@"button-grid.png"] inset:inset],
                              [UIImage imageWithShadow:[UIImage imageNamed:@"button-list.png"] inset:inset],
                              nil];
    BlioAccessibilitySegmentedControl *segmentedControl = [[BlioAccessibilitySegmentedControl alloc] initWithItems:segmentImages];
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    segmentedControl.frame = CGRectMake(0,0, kBlioLibraryLayoutButtonWidth, segmentedControl.frame.size.height);
    [segmentedControl addTarget:self action:@selector(changeLibraryLayout:) forControlEvents:UIControlEventValueChanged];
    [segmentedControl setSelectedSegmentIndex:self.libraryLayout];
    
    [segmentedControl setIsAccessibilityElement:NO];
    [[segmentedControl imageForSegmentAtIndex:0] setAccessibilityLabel:NSLocalizedString(@"Grid layout", @"Accessibility label for Library View grid layout button")];
    [[segmentedControl imageForSegmentAtIndex:0] setAccessibilityTraits:UIAccessibilityTraitButton | UIAccessibilityTraitStaticText];

     [[segmentedControl imageForSegmentAtIndex:1] setAccessibilityLabel:NSLocalizedString(@"List layout", @"Accessibility label for Library View list layout button")];
    
    UIBarButtonItem *libraryLayoutButton = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
    self.navigationItem.leftBarButtonItem = libraryLayoutButton;
    [libraryLayoutButton release];
    [segmentedControl release];
    
    NSError *error = nil; 
    NSManagedObjectContext *moc = [self managedObjectContext]; 
    NSLog(@"moc: %@",moc);
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
    
    if (![[aFetchedResultsController fetchedObjects] count]) {
        NSLog(@"Creating Mock Books");

        [self.processingDelegate enqueueBookWithTitle:@"Fables: Legends In Exile" 
                                              authors:[NSArray arrayWithObject:@"Bill Willingham"]
                                             coverURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"FablesLegendsInExile" ofType:@"png" inDirectory:@"MockCovers"]]
                                              ePubURL:nil
                                               pdfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Legends" ofType:@"pdf" inDirectory:@"PDFs"]]
                                          textFlowURL:nil
                                         audiobookURL:nil];
        
        [self.processingDelegate enqueueBookWithTitle:@"Three Little Pigs" 
                                              authors:[NSArray arrayWithObject:@"Stella Blackstone"]
                                             coverURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Three_Little_Pigs" ofType:@"png" inDirectory:@"MockCovers"]]
                                              ePubURL:nil
                                               pdfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Three Little Pigs" ofType:@"pdf" inDirectory:@"PDFs"]]
                                          textFlowURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Three Little Pigs" ofType:@"zip" inDirectory:@"TextFlows"]]
                                         audiobookURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Three Little Pigs" ofType:@"zip" inDirectory:@"AudioBooks"]]];

        [self.processingDelegate enqueueBookWithTitle:@"Essentials Of Discrete Mathematics" 
                                              authors:[NSArray arrayWithObject:@"David J. Hunter"]
                                             coverURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Essentials_of_Discrete_Mathematics" ofType:@"png" inDirectory:@"MockCovers"]]
                                              ePubURL:nil
                                               pdfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Essentials_of_Discrete_Mathematics" ofType:@"pdf" inDirectory:@"PDFs"]]
                                          textFlowURL:nil
                                         audiobookURL:nil];
        
        [self.processingDelegate enqueueBookWithTitle:@"Exiles In The Garden" 
                                              authors:[NSArray arrayWithObject:@"Ward Just"]
                                             coverURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Exiles In The Garden" ofType:@"png" inDirectory:@"MockCovers"]]
                                              ePubURL:nil
                                               pdfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Exiles In The Garden" ofType:@"pdf" inDirectory:@"PDFs"]]
                                          textFlowURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Exiles In The Garden" ofType:@"zip" inDirectory:@"TextFlows"]]
                                         audiobookURL:nil];
        
        [self.processingDelegate enqueueBookWithTitle:@"Dead Is So Last Year" 
                                              authors:[NSArray arrayWithObject:@"Marlene Perez"]
                                             coverURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Dead Is So Last Year" ofType:@"png" inDirectory:@"MockCovers"]]
                                              ePubURL:nil
                                               pdfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Dead Is So Last Year" ofType:@"pdf" inDirectory:@"PDFs"]]
                                          textFlowURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Dead Is So Last Year" ofType:@"zip" inDirectory:@"TextFlows"]]
                                         audiobookURL:nil];
        
        [self.processingDelegate enqueueBookWithTitle:@"Jamberry" 
                                              authors:[NSArray arrayWithObject:@"Bruce Degen"]
                                             coverURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Jamberry" ofType:@"png" inDirectory:@"MockCovers"]]
                                              ePubURL:nil
                                               pdfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Jamberry" ofType:@"pdf" inDirectory:@"PDFs"]]
                                          textFlowURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Jamberry" ofType:@"zip" inDirectory:@"TextFlows"]]
                                         audiobookURL:nil];
        
        [self.processingDelegate enqueueBookWithTitle:@"The Pet Dragon" 
                                              authors:[NSArray arrayWithObject:@"Christoph Niemann"]
                                             coverURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ChristophNiemann" ofType:@"png" inDirectory:@"MockCovers"]]
                                              ePubURL:nil
                                               pdfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Pet Dragon" ofType:@"pdf" inDirectory:@"PDFs"]]
                                          textFlowURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Pet Dragon" ofType:@"zip" inDirectory:@"TextFlows"]]
                                         audiobookURL:nil];

        [self.processingDelegate enqueueBookWithTitle:@"The Graveyard Book" 
                                              authors:[NSArray arrayWithObject:@"Neil Gaiman"]
                                             coverURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"NeilGaiman" ofType:@"png" inDirectory:@"MockCovers"]]
                                              ePubURL:nil
                                               pdfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Graveyard Book" ofType:@"pdf" inDirectory:@"PDFs"]]
                                          textFlowURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Graveyard Book" ofType:@"zip" inDirectory:@"TextFlows"]]
										 audiobookURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Graveyard Book" ofType:@"zip" inDirectory:@"AudioBooks"]]];

        [self.processingDelegate enqueueBookWithTitle:@"Martha Stewart's Cookies" 
                                              authors:[NSArray arrayWithObject:@"Martha Stewart"]
                                             coverURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Martha Stewart Cookies" ofType:@"png" inDirectory:@"MockCovers"]]
                                              ePubURL:nil
                                               pdfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Martha Stewart Cookies" ofType:@"pdf" inDirectory:@"PDFs"]]
                                          textFlowURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Martha Stewart Cookies" ofType:@"zip" inDirectory:@"TextFlows"]]
                                         audiobookURL:nil];
        
        [self.processingDelegate enqueueBookWithTitle:@"Baby Mouse" 
                                              authors:[NSArray arrayWithObjects:@"Jennifer L. Holme", @"Matthew Holme", nil]
                                             coverURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Baby Mouse" ofType:@"png" inDirectory:@"MockCovers"]]
                                              ePubURL:nil
                                               pdfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Baby Mouse" ofType:@"pdf" inDirectory:@"PDFs"]]
                                          textFlowURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Baby Mouse" ofType:@"zip" inDirectory:@"TextFlows"]]
                                         audiobookURL:nil];
        
        [self.processingDelegate enqueueBookWithTitle:@"Persepolis 2" 
                                              authors:[NSArray arrayWithObject:@"Marjane Satrapi"]
                                             coverURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Persepolis 2" ofType:@"png" inDirectory:@"MockCovers"]]
                                              ePubURL:nil
                                               pdfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Persepolis 2" ofType:@"pdf" inDirectory:@"PDFs"]]
                                          textFlowURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Persepolis 2" ofType:@"zip" inDirectory:@"TextFlows"]]
                                         audiobookURL:nil];
        
        [self.processingDelegate enqueueBookWithTitle:@"The Art of the Band T-Shirt" 
                                              authors:[NSArray arrayWithObjects:@"Amber Easby", @"Henry Oliver", nil]
                                             coverURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Art of the Band T-Shirt" ofType:@"png" inDirectory:@"MockCovers"]]
                                              ePubURL:nil
                                               pdfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Art of the Band T-Shirt" ofType:@"pdf" inDirectory:@"PDFs"]]
                                          textFlowURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Art of the Band T-Shirt" ofType:@"zip" inDirectory:@"TextFlows"]]
                                         audiobookURL:nil];
        
        [self.processingDelegate enqueueBookWithTitle:@"Sylvester and the Magic Pebble" 
                                              authors:[NSArray arrayWithObject:@"William Steig"]
                                             coverURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sylvester and the Magic Pebble" ofType:@"png" inDirectory:@"MockCovers"]]
                                              ePubURL:nil
                                               pdfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sylvester and the Magic Pebble" ofType:@"pdf" inDirectory:@"PDFs"]]
                                          textFlowURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sylvester and the Magic Pebble" ofType:@"zip" inDirectory:@"TextFlows"]]
                                         audiobookURL:nil];
        
        [self.processingDelegate enqueueBookWithTitle:@"You On A Diet" 
                                              authors:[NSArray arrayWithObjects:@"Michael F. Roizen, M.D.", @"Mehmet C. Oz, M.D.", nil]
                                             coverURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"You On A Diet" ofType:@"png" inDirectory:@"MockCovers"]]
                                              ePubURL:nil
                                               pdfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"You On A Diet" ofType:@"pdf" inDirectory:@"PDFs"]]
                                          textFlowURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"You On A Diet" ofType:@"zip" inDirectory:@"TextFlows"]]
                                         audiobookURL:nil];
        
        [self.processingDelegate enqueueBookWithTitle:@"BakeWise" 
                                              authors:[NSArray arrayWithObjects:@"Shirley O. Corriher", nil]
                                             coverURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Bakewise" ofType:@"png" inDirectory:@"MockCovers"]]
                                              ePubURL:nil
                                               pdfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Bakewise" ofType:@"pdf" inDirectory:@"PDFs"]]
                                          textFlowURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Bakewise" ofType:@"zip" inDirectory:@"TextFlows"]]
                                         audiobookURL:nil];
        
        [self.processingDelegate enqueueBookWithTitle:@"Chick Chicka Boom Boom" 
                                              authors:[NSArray arrayWithObjects:@"Bill Martin Jr", @"Joan Archambault", nil]
                                             coverURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Chicka Chicka Boom Boom" ofType:@"png" inDirectory:@"MockCovers"]]
                                              ePubURL:nil
                                               pdfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Chicka Chicka Boom Boom" ofType:@"pdf" inDirectory:@"PDFs"]]
                                          textFlowURL:nil
                                         audiobookURL:nil];
      
        [self.processingDelegate enqueueBookWithTitle:@"Five Greatest Warriors" 
                                              authors:[NSArray arrayWithObjects:@"Matthew Reilly", nil]
                                             coverURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Five Greatest Warriors" ofType:@"png" inDirectory:@"MockCovers"]]
                                              ePubURL:nil
                                               pdfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Five Greatest Warriors" ofType:@"pdf" inDirectory:@"PDFs"]]
                                          textFlowURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Five Greatest Warriors" ofType:@"zip" inDirectory:@"TextFlows"]]
                                         audiobookURL:nil];
        
        [self.processingDelegate enqueueBookWithTitle:@"Spinster Goose" 
                                              authors:[NSArray arrayWithObjects:@"Lisa Wheeler", @"Sophie Blackall", nil]
                                             coverURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Spinster Goose" ofType:@"png" inDirectory:@"MockCovers"]]
                                              ePubURL:nil
                                               pdfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Spinster Goose" ofType:@"pdf" inDirectory:@"PDFs"]]
                                          textFlowURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Spinster Goose" ofType:@"zip" inDirectory:@"TextFlows"]]
                                         audiobookURL:nil];
    }
    
	
    self.fetchedResultsController = aFetchedResultsController;
    [aFetchedResultsController release];
    
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeChangesFromContextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.title = @"Bookshelf";
    
    UIImage *logoImage = [UIImage appleLikeBeveledImage:[UIImage imageNamed:@"logo-white.png"]];
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:logoImage];
    logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    logoImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [logoImageView setIsAccessibilityElement:YES];
    [logoImageView setAccessibilityLabel:NSLocalizedString(@"Blio", @"Accessibility label for Library View Blio label")];
    [logoImageView setAccessibilityTraits:UIAccessibilityTraitStaticText];

    self.navigationItem.titleView = logoImageView;
    [logoImageView release];
    
    [self.navigationController setToolbarHidden:NO];
    UIColor *tintColor = [UIColor colorWithRed:160.0f / 256.0f green:190.0f / 256.0f  blue:190.0f / 256.0f  alpha:1.0f];
    self.navigationController.toolbar.tintColor = tintColor;
    self.navigationController.navigationBar.tintColor = tintColor;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
}

- (NSInteger)columnCount {
    CGRect bounds = [UIScreen mainScreen].bounds;
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        CGFloat width = bounds.size.width;
        bounds.size.width = bounds.size.height;
        bounds.size.height = width;
    }
    return round((bounds.size.width - kBlioLibraryGridBookSpacing*2) / (kBlioLibraryGridBookWidth+kBlioLibraryGridBookSpacing));
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ([[[[NSBundle mainBundle] infoDictionary] objectForKey:@"BlioLibraryViewDisableRotation"] boolValue])
        return NO;
    else
        return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.tableView reloadData];
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	[self.gridView setEditing:editing animated:animated];
	[self.tableView setEditing:editing animated:animated];
}

#pragma mark - 
#pragma mark MRGridViewDataSource methods

-(MRGridViewCell*)gridView:(MRGridView*)gridView cellForGridIndex: (NSInteger)index{
//	NSLog(@"cellForGridIndex: %i",index);
	static NSString* cellIdentifier = @"BlioLibraryGridViewCell";
	BlioLibraryGridViewCell* gridCell = (BlioLibraryGridViewCell*)[gridView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (gridCell == nil) {
//		NSLog(@"creating new cell...");
		gridCell = [[[BlioLibraryGridViewCell alloc]initWithFrame:[gridView frameForCellAtGridIndex: index] reuseIdentifier:cellIdentifier] autorelease];
	}
	else {
//		NSLog(@"fetching recycled cell...");
		gridCell.frame = [gridView frameForCellAtGridIndex: index];
	}
	
	// populate gridCell
	
	NSIndexPath * indexPath = [NSIndexPath indexPathForRow:index inSection:0];
	gridCell.book = [self.fetchedResultsController objectAtIndexPath:indexPath];
	if ([[gridCell.book valueForKey:@"processingComplete"] intValue] != kBlioMockBookProcessingStateComplete) {
		NSOperation * completeOp = [[self processingDelegate] processingCompleteOperationForSourceID:[gridCell.book valueForKey:@"sourceID"] sourceSpecificID:[gridCell.book valueForKey:@"sourceSpecificID"]];
		if (completeOp != nil && [completeOp isKindOfClass:[BlioProcessingCompleteOperation class]]) {
			[[NSNotificationCenter defaultCenter] addObserver:gridCell selector:@selector(onProcessingProgressNotification:) name:BlioProcessingOperationProgressNotification object:completeOp];
			[[NSNotificationCenter defaultCenter] addObserver:gridCell selector:@selector(onProcessingCompleteNotification:) name:BlioProcessingOperationCompleteNotification object:completeOp];
			[[NSNotificationCenter defaultCenter] addObserver:gridCell selector:@selector(onProcessingFailedNotification:) name:BlioProcessingOperationFailedNotification object:completeOp];
		}
	}
	gridCell.delegate = self;
	
	return gridCell;
}

-(NSInteger)numberOfItemsInGridView:(MRGridView*)gridView{
    NSArray *sections = [self.fetchedResultsController sections];
    NSUInteger bookCount = 0;
	id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:0];
	bookCount = [sectionInfo numberOfObjects];
	return bookCount;
}


-(void) gridView:(MRGridView*)gridView moveCellAtIndex: (NSInteger)fromIndex toIndex: (NSInteger)toIndex {
	NSInteger fetchedResultsCount = [self.fetchedResultsController.fetchedObjects count];
//	NSLog(@"fromIndex: %i, toIndex: %i",fromIndex,toIndex);
	BlioMockBook * fromBook = [[self.fetchedResultsController fetchedObjects] objectAtIndex:fromIndex];
	BlioMockBook * toBook = [[self.fetchedResultsController fetchedObjects] objectAtIndex:toIndex];
	NSInteger fromPosition = [fromBook.position intValue];
	NSInteger toPosition = [toBook.position intValue];
//	NSLog(@"fromPosition: %i, toPosition: %i",fromPosition,toPosition);
/*	
	// tracing purposes
	for (NSInteger i = 0; i < fetchedResultsCount; i++)
	{
		BlioMockBook * aBook = [[self.fetchedResultsController fetchedObjects] objectAtIndex:i];
		NSLog(@"index: %i, position: %i, title: %@",i,[aBook.position intValue],aBook.title);
		
	}
*/	
	for (NSInteger i = 0; i < fetchedResultsCount; i++)
	{
		BlioMockBook * aBook = [[self.fetchedResultsController fetchedObjects] objectAtIndex:i];
		if ([aBook.position intValue] == fromPosition) [aBook setValue:[NSNumber numberWithInt:toPosition] forKey:@"position"];
        else {
			NSInteger newPosition = [aBook.position intValue];
			if (fromPosition > newPosition) newPosition++;
			if (toPosition >= newPosition) newPosition--;
			[aBook setValue:[NSNumber numberWithInt:newPosition] forKey:@"position"];
		}
	}
/*	
	// tracing purposes
	for (NSInteger i = 0; i < fetchedResultsCount; i++)
	{
		BlioMockBook * aBook = [[self.fetchedResultsController fetchedObjects] objectAtIndex:i];
		NSLog(@"index: %i, position: %i, title: %@",i,[aBook.position intValue],aBook.title);
		
	}
 */
	
	_didEdit = YES;
}
-(void) gridView:(MRGridView*)gridView finishedMovingCellToIndex:(NSInteger)toIndex {
	NSManagedObjectContext *moc = [self managedObjectContext]; 
	NSError * error;
	if (![moc save:&error]) {
		NSLog(@"Save failed in BlioLibraryViewController (attempted to re-order fetched results): %@, %@", error, [error userInfo]);
	}
	
	_didEdit = YES;	
}

#pragma mark - 
#pragma mark MRGridViewDelegate methods

- (void)gridView:(MRGridView *)gridView didSelectCellAtIndex:(NSInteger)index{
//	NSLog(@"selected cell %i",index);
	BlioLibraryGridViewCell * cell = (BlioLibraryGridViewCell*)[self.gridView cellAtGridIndex:index];
	[self bookSelected:cell.bookView];
}


#pragma mark Table View Methods

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
    
    switch (self.libraryLayout) {
        case kBlioLibraryLayoutGrid: {
            NSInteger columnCount = self.columnCount;
            NSInteger rowCount = bookCount / columnCount;
            if (bookCount % columnCount) rowCount++;
            //NSLog(@"Number of books: %d, rows: %d", bookCount, rowCount);

            return rowCount;
        } break;
        default:
            return bookCount;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (self.libraryLayout) {
/*        case kBlioLibraryLayoutGrid:
            return kBlioLibraryGridRowHeight;
            break;
 */
        default:
            return kBlioLibraryListRowHeight;
            break;
    }
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
    
    switch (self.libraryLayout) {
			/*
        case kBlioLibraryLayoutGrid: {
            static NSString *GridCellIdentifier = @"BlioLibraryGridCell";
            
            BlioLibraryGridCell *cell = (BlioLibraryGridCell *)[tableView dequeueReusableCellWithIdentifier:GridCellIdentifier];
            if (cell == nil) {
                cell = [[[BlioLibraryGridCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:GridCellIdentifier] autorelease];
            }  
            
            cell.books = [self.fetchedResultsController fetchedObjects];
            cell.rowIndex = [indexPath row]; // N.B. currently these need to be set before the column count
            cell.delegate = self; // N.B. currently these need to be set before the column count
            cell.columnCount = self.columnCount;
            
            return cell;
        } break;
			 */
        default: {
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

            
            cell.book = [self.fetchedResultsController objectAtIndexPath:indexPath];
            cell.delegate = self;
            
            if ([indexPath row] % 2)
                cell.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"row-light.png"]] autorelease];
            else                         
                cell.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"row-dark.png"]] autorelease];

			cell.showsReorderControl = YES;
            return cell;
        } break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BlioMockBook *selectedBook = [self.fetchedResultsController objectAtIndexPath:indexPath];
    BlioBookViewController *bookViewController = [[BlioBookViewController alloc] initWithBook:selectedBook];
    
    if (nil != bookViewController) {
        [bookViewController setManagedObjectContext:self.managedObjectContext];
        bookViewController.toolbarsVisibleAfterAppearance = YES;
        [self.navigationController pushViewController:bookViewController animated:YES];
        [bookViewController release];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (self.libraryLayout == kBlioLibraryLayoutList)
        return YES;
//    else
//        return NO;
}
- (BOOL)tableView:(UITableView *)tableview canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;	
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	NSInteger fetchedResultsCount = [self.fetchedResultsController.fetchedObjects count];
	//	NSLog(@"fromIndex: %i, toIndex: %i",fromIndex,toIndex);
	BlioMockBook * fromBook = [[self.fetchedResultsController fetchedObjects] objectAtIndex:fromIndexPath.row];
	BlioMockBook * toBook = [[self.fetchedResultsController fetchedObjects] objectAtIndex:toIndexPath.row];
	NSInteger fromPosition = [fromBook.position intValue];
	NSInteger toPosition = [toBook.position intValue];
	//	NSLog(@"fromPosition: %i, toPosition: %i",fromPosition,toPosition);
	/*	
	 // tracing purposes
	 for (NSInteger i = 0; i < fetchedResultsCount; i++)
	 {
	 BlioMockBook * aBook = [[self.fetchedResultsController fetchedObjects] objectAtIndex:i];
	 NSLog(@"index: %i, position: %i, title: %@",i,[aBook.position intValue],aBook.title);
	 
	 }
	 */	
	for (NSInteger i = 0; i < fetchedResultsCount; i++)
	{
		BlioMockBook * aBook = [[self.fetchedResultsController fetchedObjects] objectAtIndex:i];
		if ([aBook.position intValue] == fromPosition) [aBook setValue:[NSNumber numberWithInt:toPosition] forKey:@"position"];
        else {
			NSInteger newPosition = [aBook.position intValue];
			if (fromPosition > newPosition) newPosition++;
			if (toPosition >= newPosition) newPosition--;
			[aBook setValue:[NSNumber numberWithInt:newPosition] forKey:@"position"];
		}
	}
	/*	
	 // tracing purposes
	 for (NSInteger i = 0; i < fetchedResultsCount; i++)
	 {
	 BlioMockBook * aBook = [[self.fetchedResultsController fetchedObjects] objectAtIndex:i];
	 NSLog(@"index: %i, position: %i, title: %@",i,[aBook.position intValue],aBook.title);
	 
	 }
	 */
	_didEdit = YES;
	NSManagedObjectContext *moc = [self managedObjectContext]; 
	NSError * error;
	if (![moc save:&error]) {
		NSLog(@"Save failed in BlioLibraryViewController (attempted to re-order fetched results): %@, %@", error, [error userInfo]);
	}
	
}


/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source.
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
 }   
 }
 */


#pragma mark -
#pragma mark Fetched Results Controller Delegate
//- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
//    [self.tableView beginUpdates];
//}

/*
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	
	UITableView *aTableView = self.tableView;
	
	switch(type) {
			
		case NSFetchedResultsChangeInsert:
            //[aTableView reloadData];
			//[aTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[aTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeUpdate:
			[aTableView reloadRowsAtIndexPaths: [NSArray arrayWithObject: indexPath] withRowAnimation: UITableViewRowAnimationNone];
			break;
			
		case NSFetchedResultsChangeMove:
			[aTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			// Reloading the section inserts a new row and ensures that titles are updated appropriately.
			[aTableView reloadSections:[NSIndexSet indexSetWithIndex:newIndexPath.section] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}
*/
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	if (!_didEdit) {
		[self.tableView reloadData];
		[self.gridView reloadData];
	}
	else _didEdit = NO;
}

#pragma mark -
#pragma mark Core Data Multi-Threading
- (void)mergeChangesFromContextDidSaveNotification:(NSNotification *)notification {
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

#pragma mark -
#pragma mark Toolbar Actions

- (void)showLogin:(id)sender {     
	BlioLoginViewController *loginController = [[BlioLoginViewController alloc] init];
    loginController.vaultManager = self.vaultManager;
	[self presentModalViewController:[[UINavigationController alloc] initWithRootViewController:loginController] animated:YES];
    [loginController release]; 
	/*
	BlioLoginView* loginView = [[BlioLoginView alloc] initWithTitle: @"Sign in to Blio" 
															message:@"\n\n\n"
														   delegate:nil
												  cancelButtonTitle:@"Cancel"
												  otherButtonTitles:@"Log In", nil]; 
	loginView.delegate = loginView;
	loginView.loginManager = self.loginManager;
	[loginView display];
	[loginView release];
	 */
}


- (void)showStore:(id)sender {    
    BlioStoreTabViewController *aStoreController = [[BlioStoreTabViewController alloc] initWithProcessingDelegate:self.processingDelegate managedObjectContext:self.managedObjectContext];
	[self presentModalViewController:aStoreController animated:YES];
    [aStoreController release];    
}

- (void)showSettings:(id)sender {    
	BlioAppSettingsController *settingsController = [[UINavigationController alloc] initWithRootViewController:[[BlioAppSettingsController alloc] init]];
    [self presentModalViewController:settingsController animated:YES];
    [settingsController release];    
}

#pragma mark -
#pragma mark Library Actions

- (void)changeLibraryLayout:(id)sender {
    
    BlioLibraryLayout newLayout = (BlioLibraryLayout)[sender selectedSegmentIndex];
    
    if (self.libraryLayout != newLayout) {
        self.libraryLayout = newLayout;
        
        switch (newLayout) {
            case kBlioLibraryLayoutGrid:
				[self.view bringSubviewToFront:self.gridView];
				[self.gridView reloadData];
				self.gridView.hidden = NO;
				self.tableView.hidden = YES;
                // [self.tableView setBackgroundColor:[UIColor clearColor]];
                break;
            case kBlioLibraryLayoutList:
				[self.view bringSubviewToFront:self.tableView];
				[self.tableView reloadData];
				self.gridView.hidden = YES;
				self.tableView.hidden = NO;
                [self.tableView setBackgroundColor:[UIColor whiteColor]];
                break;
            default:
                NSLog(@"Unexpected library layout %ld", (long)newLayout);
        }
        
    }
    
}

- (void)bookSelected:(BlioLibraryBookView *)bookView {
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    bookView.alpha = 0.0f;
    UIView *targetView = self.navigationController.view;
    
    UIView *poppedImageView = [[UIView alloc] initWithFrame:[[bookView superview] convertRect:[bookView frame] toView:targetView]];
    poppedImageView.backgroundColor = [UIColor clearColor];
    UIImage *bookImage = [[bookView book] coverImage];
    
    CGFloat xInset = poppedImageView.bounds.size.width * kBlioLibraryShadowXInset;
    CGFloat yInset = poppedImageView.bounds.size.height * kBlioLibraryShadowYInset;
    CGRect insetFrame = CGRectInset(poppedImageView.bounds, xInset, yInset);
    UIImageView *aCoverImageView = [[UIImageView alloc] initWithFrame:insetFrame];
    aCoverImageView.contentMode = UIViewContentModeScaleToFill;
    aCoverImageView.image = bookImage;
    aCoverImageView.backgroundColor = [UIColor clearColor];
    aCoverImageView.autoresizesSubviews = YES;
    aCoverImageView.autoresizingMask = 
        UIViewAutoresizingFlexibleLeftMargin  |
        UIViewAutoresizingFlexibleWidth       |
        UIViewAutoresizingFlexibleRightMargin |
        UIViewAutoresizingFlexibleTopMargin   |
        UIViewAutoresizingFlexibleHeight      |
        UIViewAutoresizingFlexibleBottomMargin;
    
    [poppedImageView addSubview:aCoverImageView];
    
    UIImageView *aTextureView = [[UIImageView alloc] initWithFrame:poppedImageView.bounds];
    aTextureView.contentMode = UIViewContentModeScaleToFill;
    aTextureView.image = [UIImage imageNamed:@"booktextureandshadowsubtle.png"];
    aTextureView.backgroundColor = [UIColor clearColor];
    aTextureView.autoresizesSubviews = YES;
    aTextureView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [poppedImageView addSubview:aTextureView];
    
    [targetView addSubview:poppedImageView];
    
    [UIView beginAnimations:@"popBook" context:poppedImageView];
    [aCoverImageView release];
    [UIView setAnimationDuration:0.65f];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(popBookDidStop:finished:context:)];
    [UIView setAnimationWillStartSelector:@selector(popBookWillStart:context:)];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    
    CGFloat widthRatio = (targetView.bounds.size.width)/aCoverImageView.frame.size.width;
    CGFloat heightRatio = (targetView.bounds.size.height)/aCoverImageView.frame.size.height;
    CGRect poppedRect;
    
    // If the targetView is landscape, use the widthRatio for both and top align if necessary
    if (targetView.bounds.size.width > targetView.bounds.size.height) {
        CGSize poppedSize = CGSizeMake(poppedImageView.frame.size.width * widthRatio, poppedImageView.frame.size.height * widthRatio);
        poppedRect = CGRectIntegral(CGRectMake((targetView.bounds.size.width-poppedSize.width)/2.0f, (targetView.bounds.size.height-poppedSize.height)/2.0f, poppedSize.width, poppedSize.height));
        CGPoint topLeft = [self.view convertPoint:CGPointZero fromView:targetView];
        poppedRect.origin.y = topLeft.y;
    } else {
        CGSize poppedSize = CGSizeMake(poppedImageView.frame.size.width * widthRatio, poppedImageView.frame.size.height * heightRatio);
        poppedRect = CGRectIntegral(CGRectMake((targetView.bounds.size.width-poppedSize.width)/2.0f, (targetView.bounds.size.height-poppedSize.height)/2.0f, poppedSize.width, poppedSize.height));

    }

    [poppedImageView setFrame:poppedRect];
    [self.tableView setAlpha:0.0f];
    [aTextureView setAlpha:0.0f];
    
    [UIView commitAnimations];
    
    [aTextureView release];
    [poppedImageView release];
    
    self.currentBookView = bookView;
    self.currentPoppedBookCover = aCoverImageView;
    self.bookCoverPopped = NO;
    self.firstPageRendered = NO;
}

- (void)popBookWillStart:(NSString *)animationID context:(void *)context {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
    [self.tableView setUserInteractionEnabled:NO];    
}

- (void)popBookDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    if (finished) {        
        // Reset table view and clicked book
        [self.currentBookView setAlpha:1.0f]; // This is the current book in the grid or list which was hidden
        [self.tableView setUserInteractionEnabled:YES];
        [self.tableView setAlpha:1.0f];
        
        BlioMockBook *currentBook = [self.currentBookView book];
        BlioBookViewController *bookViewController = [[BlioBookViewController alloc] initWithBook:currentBook];
        
        CGRect coverRect;
        BOOL shrinkCover = NO;
        
        if (nil != bookViewController) {
            [bookViewController setManagedObjectContext:self.managedObjectContext];
            self.navigationController.navigationBarHidden = YES; // We already animated the cover over it.
            coverRect = [[bookViewController bookView] firstPageRect];
            if (!CGRectEqualToRect([[UIScreen mainScreen] bounds], coverRect)) shrinkCover = YES;
            
            bookViewController.toolbarsVisibleAfterAppearance = !shrinkCover;
            bookViewController.returnToNavigationBarHidden = NO;
            bookViewController.returnToStatusBarStyle = UIStatusBarStyleDefault;
            [self.navigationController pushViewController:bookViewController animated:NO];
            
            [bookViewController release];
        } else {
            [(UIView *)context removeFromSuperview];
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            return;
        }

        
        if (!shrinkCover) {
            self.bookCoverPopped = YES;
            self.firstPageRendered = YES;
            [(UIView *)context removeFromSuperview];
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        } else {            
            [UIView beginAnimations:@"shrinkBook" context:context];
            [UIView setAnimationDuration:0.35f];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(shrinkBookDidStop:finished:context:)];
            //[self.currentPoppedBookCover setBounds:CGRectMake(0,0, coverRect.size.width, coverRect.size.height)];
            //UIView *targetView = self.navigationController.view;
            //CGPoint midPoint = [self.currentPoppedBookCover convertPoint:CGPointMake(CGRectGetMidX(coverRect), CGRectGetMidY(coverRect)) fromView:targetView];
            //CGRect viewCoverRect  = [self.currentPoppedBookCover convertRect:coverRect fromView:targetView];
            [self.currentPoppedBookCover setBounds:coverRect];
//            [self.currentPoppedBookCover setCenter:midPoint];
//            [[self.currentPoppedBookCover superview] setCenter:CGPointMake(240,160)];
            
            [UIView commitAnimations];
            
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(blioCoverPageDidFinishRender:) 
                                                         name:@"blioCoverPageDidFinishRender" object:nil];
        }            
            
    }
}

- (void)fadeBookDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    if ([(UIView *)context superview])
        [(UIView *)context removeFromSuperview];
}

- (void)removeShrinkBookAnimation:(UIView *)viewToRemove {
    [UIView beginAnimations:@"fadeCover" context:viewToRemove];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(fadeBookDidStop:finished:context:)];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDuration:0.5f];
    [viewToRemove setAlpha:0.0f];
    [UIView commitAnimations];
}

- (void)blioCoverPageDidFinishRenderAfterDelay:(NSNotification *)notification {
    self.firstPageRendered = YES;
    
    if (self.bookCoverPopped) {
        [self removeShrinkBookAnimation:[self.currentPoppedBookCover superview]];
        [(BlioBookViewController *)self.navigationController.topViewController toggleToolbars];
        
        self.currentPoppedBookCover = nil;
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }    
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:@"blioCoverPageDidFinishRender" 
                                                  object:nil];

}

- (void)blioCoverPageDidFinishRenderOnMainThread:(NSNotification *)notification {
    // To allow the tiled view to do its fading in.
    [self performSelector:@selector(blioCoverPageDidFinishRenderAfterDelay:) withObject:notification afterDelay:0.25];
}

- (void)blioCoverPageDidFinishRender:(NSNotification *)notification  {
    [self performSelectorOnMainThread:@selector(blioCoverPageDidFinishRenderOnMainThread:) withObject:notification waitUntilDone:YES];
}

- (void)shrinkBookDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    self.bookCoverPopped = YES;
    
    if (self.firstPageRendered) {
        [self removeShrinkBookAnimation:[self.currentPoppedBookCover superview]];
        [(BlioBookViewController *)self.navigationController.topViewController toggleToolbars];

        self.currentPoppedBookCover = nil;
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }
}

@end

@implementation BlioLibraryBookView

@synthesize imageView, textureView, highlightView, book;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = YES;
        
        UIImageView *aTextureView = [[UIImageView alloc] initWithFrame:self.bounds];
        aTextureView.contentMode = UIViewContentModeScaleToFill;
        aTextureView.image = [UIImage imageNamed:@"booktextureandshadowsubtle.png"];
        aTextureView.backgroundColor = [UIColor clearColor];
        aTextureView.alpha = 0.0f;
//        aTextureView.userInteractionEnabled = NO;
        [self addSubview:aTextureView];
        self.textureView = aTextureView;
        [aTextureView release];
        
        CGFloat xInset = self.bounds.size.width * kBlioLibraryShadowXInset;
        CGFloat yInset = self.bounds.size.height * kBlioLibraryShadowYInset;
        CGRect insetFrame = CGRectInset(self.bounds, xInset, yInset);
        UIImageView *aImageView = [[UIImageView alloc] initWithFrame:insetFrame];
        aImageView.contentMode = UIViewContentModeScaleToFill;
        aImageView.backgroundColor = [UIColor clearColor];
//        aImageView.userInteractionEnabled = NO;
        [self insertSubview:aImageView belowSubview:self.textureView];
        self.imageView = aImageView;
        [aImageView release];
   /*     
        UIView *aHighlightView = [[UIView alloc] initWithFrame:insetFrame];
        aHighlightView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
        aHighlightView.alpha = 0.0f;
//        aHighlightView.userInteractionEnabled = NO;
        [self insertSubview:aHighlightView aboveSubview:self.imageView];
        self.highlightView = aHighlightView;
        [aHighlightView release];
      */  
    }
    return self;
}

- (void)dealloc {
    self.imageView = nil;
    self.textureView = nil;
    self.book = nil;
    [super dealloc];
}

- (void)setFrame:(CGRect)newFrame {
    [super setFrame:newFrame];
    [self.textureView setFrame:CGRectMake(0, 0, newFrame.size.width, newFrame.size.height)];
    CGFloat xInset = self.textureView.bounds.size.width * kBlioLibraryShadowXInset;
    CGFloat yInset = self.textureView.bounds.size.height * kBlioLibraryShadowYInset;
    CGRect insetFrame = CGRectInset(self.textureView.bounds, xInset, yInset);
    [self.imageView setFrame:insetFrame];
    [self.highlightView setFrame:insetFrame];
}

- (UIImage *)image {
    return [self.imageView image];
}

- (void)setBook:(BlioMockBook *)newBook {
    [self setBook:newBook forLayout:kBlioLibraryLayoutGrid];
}

- (void)setBook:(BlioMockBook *)newBook forLayout:(BlioLibraryLayout)layout {
    [newBook retain];
    [book release];
    book = newBook;
    
    UIImage *newImage;
    if (layout == kBlioLibraryLayoutList)
        newImage = [newBook coverThumbForList];
    else
        newImage = [newBook coverThumbForGrid];
    
    [[self imageView] setImage:newImage];
    
    if (nil != newImage) 
        self.textureView.alpha = 1.0f;
    else
        self.textureView.alpha = 0.0f;
    
    [[self imageView] setNeedsDisplay];
}
/*
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    self.highlightView.alpha = 1.0f;
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    self.highlightView.alpha = 0.0f;
}
*/
@end

@implementation BlioLibraryGridViewCell

@synthesize bookView, titleLabel, authorLabel, progressSlider, delegate;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.bookView = nil;
    self.titleLabel = nil;
    self.authorLabel = nil;
    self.progressSlider = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame reuseIdentifier: (NSString*) identifier{
    if ((self = [super initWithFrame:frame reuseIdentifier:identifier])) {
        
        BlioLibraryBookView* aBookView = [[BlioLibraryBookView alloc] initWithFrame:CGRectMake(0,0, kBlioLibraryGridBookWidth, kBlioLibraryGridBookHeight)];
//        [aBookView addTarget:self.delegate action:@selector(bookTouched:)
//            forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:aBookView];
        self.bookView = aBookView;
        [aBookView release];
        
    }
    return self;
}
-(void) prepareForReuse{
	NSLog(@"BlioLibraryGridViewCell prepareForReuse entered");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (BOOL)isAccessibilityElement {
    return YES;
}

- (NSString *)accessibilityLabel {
    return [NSString stringWithFormat:NSLocalizedString(@"%@ by %@, %.0f%% complete", @"Accessibility label for Library View cell book description"), 
            [[self.bookView book] title], [[self.bookView book] author], 100 * [[[self.bookView book] progress] floatValue]];
}

- (CGRect)accessibilityFrame {
    return CGRectInset([super accessibilityFrame], CGRectGetWidth(self.bookView.bounds) * kBlioLibraryShadowXInset, CGRectGetHeight(self.bookView.bounds) * kBlioLibraryShadowYInset);
}

- (NSString *)accessibilityHint {
    return NSLocalizedString(@"Opens book.", @"Accessibility label for Library View cell book hint");
}

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitButton;
}

- (BlioMockBook *)book {
    return [(BlioLibraryBookView *)self.bookView book];
}

- (void)setBook:(BlioMockBook *)newBook {
    [(BlioLibraryBookView *)self.bookView setBook:newBook forLayout:0];
    self.titleLabel.text = [newBook title];
    self.authorLabel.text = [[newBook author] uppercaseString];
    if ([newBook audioRights]) {
        self.authorLabel.text = [NSString stringWithFormat:@"%@ %@", self.authorLabel.text, @"♫"];
    }
    self.progressSlider.value = [[newBook progress] floatValue];
    CGRect progressFrame = self.progressSlider.frame;
    self.progressSlider.frame = CGRectMake(progressFrame.origin.x, progressFrame.origin.y, [[newBook proportionateSize] floatValue] * kBlioLibraryListContentWidth, progressFrame.size.height);
    [self setNeedsLayout];
}
- (void)setDelegate:(id)newDelegate {
//    [self.bookView removeTarget:delegate action:@selector(bookTouched:)
//               forControlEvents:UIControlEventTouchUpInside];
    
    delegate = newDelegate;
//    [self.bookView addTarget:delegate action:@selector(bookTouched:)
//            forControlEvents:UIControlEventTouchUpInside];
}
- (void)onProcessingProgressNotification:(NSNotification*)note {
	BlioProcessingCompleteOperation * completeOp = [note object];
	NSLog(@"BlioLibraryGridViewCell onProcessingProgressNotification entered. percentage: %u",completeOp.percentageComplete);
}
- (void)onProcessingCompleteNotification:(NSNotification*)note {
	NSLog(@"BlioLibraryGridViewCell onProcessingCompleteNotification entered");
}
- (void)onProcessingFailedNotification:(NSNotification*)note {
	NSLog(@"BlioLibraryGridViewCell onProcessingFailedNotification entered");
}
@end

@implementation BlioLibraryListCell

@synthesize bookView, titleLabel, authorLabel, progressSlider, delegate;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.bookView = nil;
    self.titleLabel = nil;
    self.authorLabel = nil;
    self.progressSlider = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.selectionStyle = UITableViewCellSelectionStyleGray;
        
        BlioLibraryBookView* aBookView = [[BlioLibraryBookView alloc] initWithFrame:CGRectMake(8,0, kBlioLibraryListBookWidth, kBlioLibraryListBookHeight)];
//        [aBookView addTarget:self.delegate action:@selector(bookTouched:)
//            forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:aBookView];
        self.bookView = aBookView;
        [aBookView release];
        
        UILabel *aTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.bookView.frame) + 6, 12, kBlioLibraryListContentWidth, 20)];
        aTitleLabel.font = [UIFont boldSystemFontOfSize:17.0f];
        aTitleLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:aTitleLabel];
        self.titleLabel = aTitleLabel;
        [aTitleLabel release];
        
        UILabel *aAuthorLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.bookView.frame) + 6, 28, kBlioLibraryListContentWidth, 20)];
        aAuthorLabel.font = [UIFont boldSystemFontOfSize:13.0f];
        aAuthorLabel.textColor = [UIColor colorWithRed:0.424f green:0.424f blue:0.443f alpha:1.0f];
        aAuthorLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:aAuthorLabel];
        self.authorLabel = aAuthorLabel;
        [aAuthorLabel release];
        
        UISlider *aSlider = [[UISlider alloc] init];
        [aSlider setIsAccessibilityElement:NO];
        UIImage *minImage = [[UIImage imageNamed:@"minimum-progress.png"] stretchableImageWithLeftCapWidth:2 topCapHeight:0];
        //UIImage *maxImage = [[UIImage imageNamed:@"maximum-progress.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
        [aSlider setMinimumTrackImage:minImage forState:UIControlStateNormal];
        [aSlider setMaximumTrackImage:[UIImage imageNamed:@"maximum-progress.png"] forState:UIControlStateNormal];
        aSlider.userInteractionEnabled = NO;
        aSlider.value = 0.0f;
        [aSlider.layer setBorderColor:[UIColor colorWithRed:0.424f green:0.424f blue:0.443f alpha:0.25f].CGColor];
        [aSlider.layer setBorderWidth:2.0f];
        [aSlider setFrame:CGRectMake(CGRectGetMaxX(self.bookView.frame) + 6, 54, kBlioLibraryListContentWidth, 9)];
        [self.contentView addSubview:aSlider];
        self.progressSlider = aSlider;
        [aSlider release];
    }
    return self;
}

- (NSString *)accessibilityLabel {
    return [NSString stringWithFormat:NSLocalizedString(@"%@ by %@, %.0f%% complete", @"Accessibility label for Library View cell book description"), 
            [[self.bookView book] title], [[self.bookView book] author], 100 * [[[self.bookView book] progress] floatValue]];

}

- (NSString *)accessibilityHint {
    return NSLocalizedString(@"Opens book.", @"Accessibility label for Library View cell book hint");
}

- (BlioMockBook *)book {
    return [(BlioLibraryBookView *)self.bookView book];
}

- (void)setBook:(BlioMockBook *)newBook {
    [(BlioLibraryBookView *)self.bookView setBook:newBook forLayout:kBlioLibraryLayoutList];
    self.titleLabel.text = [newBook title];
    self.authorLabel.text = [[newBook author] uppercaseString];
    if ([newBook audioRights]) {
        self.authorLabel.text = [NSString stringWithFormat:@"%@ %@", self.authorLabel.text, @"♫"];
    }
    self.progressSlider.value = [[newBook progress] floatValue];
    CGRect progressFrame = self.progressSlider.frame;
    self.progressSlider.frame = CGRectMake(progressFrame.origin.x, progressFrame.origin.y, [[newBook proportionateSize] floatValue] * kBlioLibraryListContentWidth, progressFrame.size.height);
    [self setNeedsLayout];
}

- (void)setDelegate:(id)newDelegate {
//    [self.bookView removeTarget:delegate action:@selector(bookTouched:)
//               forControlEvents:UIControlEventTouchUpInside];
    
    delegate = newDelegate;
//    [self.bookView addTarget:delegate action:@selector(bookTouched:)
//            forControlEvents:UIControlEventTouchUpInside];
}

@end


