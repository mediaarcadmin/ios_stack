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
#import "BlioUIImageAdditions.h"
#import "BlioStoreTabViewController.h"
#import "BlioAppSettingsController.h"
#import "BlioLoginViewController.h"
#import "BlioProcessingStandardOperations.h"
#import "BlioAccessibilitySegmentedControl.h"
// TEMPORARY
#import "BlioDrmManager.h"
#import "BlioXpsClient.h"

static NSString * const kBlioLastLibraryLayoutDefaultsKey = @"BlioLastLibraryLayout";

static NSString * const BlioMaxLayoutPageEquivalentCountChanged = @"BlioMaxLayoutPageEquivalentCountChanged";

@interface BlioAccessibleGridElement : UIAccessibilityElement {
    id target;
    CGRect visibleRect;
}

@property (nonatomic, assign) id target;
@property (nonatomic) CGRect visibleRect;

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
@synthesize maxLayoutPageEquivalentCount;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
@synthesize settingsPopoverController;
#endif

- (id)init {
	if ((self = [super init])) {
		_didEdit = NO;
		self.title = @"Bookshelf";

		librarySortType = kBlioLibrarySortTypePersonalized;
	}
	return self;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.managedObjectContext = nil;
    self.currentBookView = nil;
    self.currentPoppedBookCover = nil;
	self.tableView = nil;
	self.gridView = nil;
    self.fetchedResultsController = nil;
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	self.settingsPopoverController = nil;
#endif

    [super dealloc];
}

- (void)awakeFromNib {
//	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
//	[[NSNotificationCenter defaultCenter] addObserver:self
//											 selector:@selector(orientationChanged:)
//												 name:UIDeviceOrientationDidChangeNotification
//											   object:nil];
	
}

- (void)orientationChanged:(NSNotification *)notification {
    [self.view setNeedsLayout];
}

- (void)loadView {
	self.view = [[[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
	NSString * libraryBackgroundFilename = @"librarybackground.png";
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		libraryBackgroundFilename = @"librarybackground-iPad.png";
	}
#endif
	
	UIImageView * backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:libraryBackgroundFilename]];
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
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.gridView setCellSize:CGSizeMake(kBlioLibraryGridBookWidthPad,kBlioLibraryGridBookHeightPad) withBorderSize:kBlioLibraryGridBookSpacingPad];
	}
	else {
		[self.gridView setCellSize:CGSizeMake(kBlioLibraryGridBookWidth,kBlioLibraryGridBookHeight) withBorderSize:kBlioLibraryGridBookSpacing];
	}
#else
	[self.gridView setCellSize:CGSizeMake(kBlioLibraryGridBookWidth,kBlioLibraryGridBookHeight) withBorderSize:kBlioLibraryGridBookSpacing];
#endif
	[self.view addSubview:aGridView];
    [aGridView release];
	self.gridView.gridDelegate = self;
	self.gridView.gridDataSource = self;
}

- (void)viewDidLoad {
    
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
    
    [segmentedControl setIsAccessibilityElement:NO];
    [[segmentedControl imageForSegmentAtIndex:0] setAccessibilityLabel:NSLocalizedString(@"Grid layout", @"Accessibility label for Library View grid layout button")];
    [[segmentedControl imageForSegmentAtIndex:0] setAccessibilityTraits:UIAccessibilityTraitButton | UIAccessibilityTraitStaticText];
	
	[[segmentedControl imageForSegmentAtIndex:1] setAccessibilityLabel:NSLocalizedString(@"List layout", @"Accessibility label for Library View list layout button")];
    
    self.libraryLayout = kBlioLibraryLayoutUndefined;
    [segmentedControl setSelectedSegmentIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"kBlioLastLibraryLayoutDefaultsKey"]];
	
    
    UIBarButtonItem *libraryLayoutButton = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
    self.navigationItem.leftBarButtonItem = libraryLayoutButton;
    [libraryLayoutButton release];
    [segmentedControl release];
    
	NSMutableArray *libraryItems = [NSMutableArray array];
    UIBarButtonItem *item;
	
	item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Sort", @"Label for Library View Sort button")
	                                        style:UIBarButtonItemStyleBordered
	                                       target:self 
	                                       action:@selector(showSortOptions:)];
    item.width = 69.0f;
	[item setAccessibilityLabel:NSLocalizedString(@"Sort", @"Accessibility label for Library View Sort button")];
	[item setAccessibilityHint:NSLocalizedString(@"Provides options for sorting the library", @"Accessibility label for Library View Sort hint")];
	[libraryItems addObject:item];
	[item release];
	
	item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	[libraryItems addObject:item];
	[item release];
	
	item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Get Books", @"Label for Library View Sort button")
                                            style:UIBarButtonItemStyleBordered
                                           target:self 
                                           action:@selector(showStore:)];
    [item setAccessibilityLabel:NSLocalizedString(@"Get Books", @"Accessibility label for Library View Get Books button")];
	[libraryItems addObject:item];
    [item release];	
    
	item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	[libraryItems addObject:item];
	[item release];
	
	
    item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Settings", @"Label for Library View Settings button")
                                            style:UIBarButtonItemStyleBordered
                                           target:self 
                                           action:@selector(showSettings:)];
    item.width = 69.0f;
    [item setAccessibilityLabel:NSLocalizedString(@"Settings", @"Accessibility label for Library View Settings button")];
	
    [libraryItems addObject:item];
    [item release];
    
    [self setToolbarItems:[NSArray arrayWithArray:libraryItems] animated:YES];
	
	
	maxLayoutPageEquivalentCount = 0;
	
    
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];
	
	[self calculateMaxLayoutPageEquivalentCount];
	
	[self fetchResults];
	
    if (![[self.fetchedResultsController fetchedObjects] count]) {
        NSLog(@"Creating Mock Books");

        [self.processingDelegate enqueueBookWithTitle:@"Fables: Legends In Exile" 
                                              authors:[NSArray arrayWithObject:@"Bill Willingham"]
											coverPath:@"MockCovers/FablesLegendsInExile.png"
											 ePubPath:nil
											  pdfPath:@"PDFs/Legends.pdf"
											  xpsPath:nil
										 textFlowPath:nil
										audiobookPath:nil
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"Fables: Legends In Exile"
									  placeholderOnly:NO
										   fromBundle:YES		 
		 ];

        [self.processingDelegate enqueueBookWithTitle:@"Three Little Pigs" 
                                              authors:[NSArray arrayWithObject:@"Stella Blackstone"]
											coverPath:@"MockCovers/Three_Little_Pigs.png"
											 ePubPath:nil
		 //                                   pdfPath:@"PDFs/Three Little Pigs.pdf
											  pdfPath:nil
											  xpsPath:@"PDFs/Three Little Pigs.xps"
										 textFlowPath:@"TextFlows/Three Little Pigs.zip"
										audiobookPath:@"AudioBooks/Three Little Pigs.zip"
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"Three Little Pigs"
									  placeholderOnly:NO
										   fromBundle:YES		 
		 ];

        [self.processingDelegate enqueueBookWithTitle:@"Essentials Of Discrete Mathematics" 
                                              authors:[NSArray arrayWithObject:@"David J. Hunter"]
											coverPath:@"MockCovers/Essentials_of_Discrete_Mathematics.png"
											 ePubPath:nil
											  pdfPath:@"PDFs/Essentials_of_Discrete_Mathematics.pdf"
											  xpsPath:nil
										 textFlowPath:nil
										audiobookPath:nil
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"Essentials Of Discrete Mathematics"
									  placeholderOnly:NO
										   fromBundle:YES		 
		 ];
        
        [self.processingDelegate enqueueBookWithTitle:@"Exiles In The Garden" 
                                              authors:[NSArray arrayWithObject:@"Ward Just"]
											coverPath:@"MockCovers/Exiles In The Garden.png"
											 ePubPath:nil
											  pdfPath:@"PDFs/Exiles In The Garden.pdf"
											  xpsPath:nil
										 textFlowPath:@"TextFlows/Exiles In The Garden.zip"
										audiobookPath:nil
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"Exiles In The Garden"
									  placeholderOnly:NO
										   fromBundle:YES		 
		 ];
        
        [self.processingDelegate enqueueBookWithTitle:@"Dead Is So Last Year" 
                                              authors:[NSArray arrayWithObject:@"Marlene Perez"]
											coverPath:@"MockCovers/Dead Is So Last Year.png"
											 ePubPath:nil
											  pdfPath:@"PDFs/Dead Is So Last Year.pdf"
											  xpsPath:nil
										 textFlowPath:@"TextFlows/Dead Is So Last Year.zip"
										audiobookPath:nil
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"Dead Is So Last Year"
									  placeholderOnly:NO
										   fromBundle:YES		 
		 ];
        
        [self.processingDelegate enqueueBookWithTitle:@"Jamberry" 
                                              authors:[NSArray arrayWithObject:@"Bruce Degen"]
											coverPath:@"MockCovers/Jamberry.png"
											 ePubPath:nil
											  pdfPath:@"PDFs/Jamberry.pdf"
											  xpsPath:nil
										 textFlowPath:@"TextFlows/Jamberry.zip"
										audiobookPath:nil
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"Jamberry"
									  placeholderOnly:NO
										   fromBundle:YES		 
		 ];
        
        [self.processingDelegate enqueueBookWithTitle:@"The Pet Dragon" 
                                              authors:[NSArray arrayWithObject:@"Christoph Niemann"]
											coverPath:@"MockCovers/ChristophNiemann.png"
											 ePubPath:nil
											  pdfPath:@"PDFs/Pet Dragon.pdf"
											  xpsPath:nil
										 textFlowPath:@"TextFlows/Pet Dragon.zip"
										audiobookPath:nil
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"The Pet Dragon"
									  placeholderOnly:NO
										   fromBundle:YES		 
		 ];
		
        [self.processingDelegate enqueueBookWithTitle:@"The Graveyard Book" 
                                              authors:[NSArray arrayWithObject:@"Neil Gaiman"]
											coverPath:@"MockCovers/NeilGaiman.png"
											 ePubPath:nil
											  pdfPath:@"PDFs/Graveyard Book.pdf"
											  xpsPath:nil
										 textFlowPath:@"TextFlows/Graveyard Book.zip"
										audiobookPath:@"AudioBooks/Graveyard Book.zip"
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"The Graveyard Book"
									  placeholderOnly:NO
										   fromBundle:YES		 
		 ];
		
        [self.processingDelegate enqueueBookWithTitle:@"Martha Stewart's Cookies" 
                                              authors:[NSArray arrayWithObject:@"Martha Stewart"]
											coverPath:@"MockCovers/Martha Stewart Cookies.png"
											 ePubPath:nil
											  pdfPath:@"PDFs/Martha Stewart Cookies.pdf"
											  xpsPath:nil
										 textFlowPath:@"TextFlows/Martha Stewart Cookies.zip"
										audiobookPath:nil
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"Martha Stewart's Cookies"
									  placeholderOnly:NO
										   fromBundle:YES		 
		 ];
        
        [self.processingDelegate enqueueBookWithTitle:@"Baby Mouse" 
                                              authors:[NSArray arrayWithObjects:@"Jennifer L. Holme", @"Matthew Holme", nil]
											coverPath:@"MockCovers/Baby Mouse.png"
											 ePubPath:nil
											  pdfPath:@"PDFs/Baby Mouse.pdf"
											  xpsPath:nil
										 textFlowPath:@"TextFlows/Baby Mouse.zip"
										audiobookPath:nil
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"Baby Mouse"
									  placeholderOnly:NO
										   fromBundle:YES		 
		 ];
        
        [self.processingDelegate enqueueBookWithTitle:@"Persepolis 2" 
                                              authors:[NSArray arrayWithObject:@"Marjane Satrapi"]
											coverPath:@"MockCovers/Persepolis 2.png"
											 ePubPath:nil
											  pdfPath:@"PDFs/Persepolis 2.pdf"
											  xpsPath:nil
										 textFlowPath:@"TextFlows/Persepolis 2.zip"
										audiobookPath:nil
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"Persepolis 2"
									  placeholderOnly:NO
										   fromBundle:YES		 
		 ];
        
        [self.processingDelegate enqueueBookWithTitle:@"The Art of the Band T-Shirt" 
                                              authors:[NSArray arrayWithObjects:@"Amber Easby", @"Henry Oliver", nil]
											coverPath:@"MockCovers/Art of the Band T-Shirt.png"
											 ePubPath:nil
											  pdfPath:@"PDFs/Art of the Band T-Shirt.pdf"
											  xpsPath:nil
										 textFlowPath:@"TextFlows/Art of the Band T-Shirt.zip"
										audiobookPath:nil
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"The Art of the Band T-Shirt"
									  placeholderOnly:NO
										   fromBundle:YES		 
		 ];
        
        [self.processingDelegate enqueueBookWithTitle:@"Sylvester and the Magic Pebble" 
                                              authors:[NSArray arrayWithObject:@"William Steig"]
											coverPath:@"MockCovers/Sylvester and the Magic Pebble.png"
											 ePubPath:nil
											  pdfPath:@"PDFs/Sylvester and the Magic Pebble.pdf"
											  xpsPath:nil
										 textFlowPath:@"TextFlows/Sylvester and the Magic Pebble.zip"
										audiobookPath:nil
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"Sylvester and the Magic Pebble"
									  placeholderOnly:NO
										   fromBundle:YES		 
		 ];
        
        [self.processingDelegate enqueueBookWithTitle:@"You On A Diet" 
                                              authors:[NSArray arrayWithObjects:@"Michael F. Roizen, M.D.", @"Mehmet C. Oz, M.D.", nil]
											coverPath:@"MockCovers/You On A Diet.png"
											 ePubPath:nil
											  pdfPath:@"PDFs/You On A Diet.pdf"
											  xpsPath:nil
										 textFlowPath:@"TextFlows/You On A Diet.zip"
										audiobookPath:nil
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"You On A Diet"
									  placeholderOnly:NO
										   fromBundle:YES		 
		 ];
        
        [self.processingDelegate enqueueBookWithTitle:@"BakeWise" 
                                              authors:[NSArray arrayWithObjects:@"Shirley O. Corriher", nil]
											coverPath:@"MockCovers/Bakewise.png"
											 ePubPath:nil
											  pdfPath:@"PDFs/Bakewise.pdf"
											  xpsPath:nil
										 textFlowPath:@"TextFlows/Bakewise.zip"
										audiobookPath:nil
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"BakeWise"
									  placeholderOnly:NO
										   fromBundle:YES		 
		 ];
        
        [self.processingDelegate enqueueBookWithTitle:@"Chick Chicka Boom Boom" 
                                              authors:[NSArray arrayWithObjects:@"Bill Martin Jr", @"Joan Archambault", nil]
											coverPath:@"MockCovers/Chicka Chicka Boom Boom.png"
											 ePubPath:nil
											  pdfPath:@"PDFs/Chicka Chicka Boom Boom.pdf"
											  xpsPath:nil
										 textFlowPath:nil
										audiobookPath:nil
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"Chick Chicka Boom Boom"
									  placeholderOnly:NO
										   fromBundle:YES		 
		 ];
		
        [self.processingDelegate enqueueBookWithTitle:@"Five Greatest Warriors" 
                                              authors:[NSArray arrayWithObjects:@"Matthew Reilly", nil]
											coverPath:@"MockCovers/Five Greatest Warriors.png"
											 ePubPath:nil
											  pdfPath:@"PDFs/Five Greatest Warriors.pdf"
											  xpsPath:nil
										 textFlowPath:@"TextFlows/Five Greatest Warriors.zip"
										audiobookPath:nil
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"Five Greatest Warriors"
									  placeholderOnly:NO
										   fromBundle:YES		 
		 ];
        
        [self.processingDelegate enqueueBookWithTitle:@"Spinster Goose" 
                                              authors:[NSArray arrayWithObjects:@"Lisa Wheeler", @"Sophie Blackall", nil]
											coverPath:@"MockCovers/Spinster Goose.png"
											 ePubPath:nil
											  pdfPath:@"PDFs/Spinster Goose.pdf"
											  xpsPath:nil
										 textFlowPath:@"TextFlows/Spinster Goose.zip"
										audiobookPath:nil
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"Spinster Goose"
									  placeholderOnly:NO
										   fromBundle:YES		 
		 ];
        
        [self.processingDelegate enqueueBookWithTitle:@"The Tale of Peter Rabbit" 
                                              authors:[NSArray arrayWithObjects:@"Beatrix Potter", nil]
											coverPath:nil
											 ePubPath:nil
											  pdfPath:nil
											  xpsPath:@"PDFs/The Tale of Peter Rabbit.drm.xps"
										 textFlowPath:nil
										audiobookPath:nil
											 sourceID:BlioBookSourceOnlineStore
									 sourceSpecificID:@"The Tale of Peter Rabbit" // this should normally be ISBN number when downloaded from the Book Store
									  placeholderOnly:NO
										   fromBundle:YES
		 ];
    
        [self.processingDelegate enqueueBookWithTitle:@"Virgin Islands" 
                                              authors:[NSArray arrayWithObjects:@"Lynne M. Sullivan", nil]
											coverPath:nil
											 ePubPath:nil
											  pdfPath:nil
											  xpsPath:@"PDFs/Virgin Islands.drm.xps"
										 textFlowPath:nil
										audiobookPath:nil
											 sourceID:BlioBookSourceOnlineStore
									 sourceSpecificID:@"VirginIslands" // this should normally be ISBN number when downloaded from the Book Store
									  placeholderOnly:NO
										   fromBundle:YES
		 ];
        
    }
	
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
	UIColor *tintColor = [UIColor colorWithRed:160.0f / 256.0f green:190.0f / 256.0f  blue:190.0f / 256.0f  alpha:1.0f];
    self.navigationController.toolbar.tintColor = tintColor;
    self.navigationController.navigationBar.tintColor = tintColor;
	
    UIImage *logoImage = [UIImage appleLikeBeveledImage:[UIImage imageNamed:@"logo-white.png"]];
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:logoImage];
    logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    logoImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [logoImageView setIsAccessibilityElement:YES];
    NSUInteger bookCount = [self numberOfItemsInGridView:self.gridView];
    if (bookCount == 0) {
        [logoImageView setAccessibilityLabel:NSLocalizedString(@"Blio Library. No books", @"Accessibility label for Library View Blio label with no books")];
    } else if (bookCount == 1) {
        [logoImageView setAccessibilityLabel:[NSString stringWithFormat:NSLocalizedString(@"Blio Library. %d book", @"Accessibility label for Library View Blio label with 1 book"), bookCount]];
    } else {
        [logoImageView setAccessibilityLabel:[NSString stringWithFormat:NSLocalizedString(@"Blio Library. %d books", @"Accessibility label for Library View Blio label with more than 1 book"), bookCount]];
    }
	
    [logoImageView setAccessibilityTraits:UIAccessibilityTraitStaticText | UIAccessibilityTraitSummaryElement];
	
    self.navigationItem.titleView = logoImageView;
    [logoImageView release];
    
    [self.navigationController setToolbarHidden:NO];
}

-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}
- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (CGRect)visibleRect {
    CGRect visibleRect = [self.view.window.layer convertRect:self.view.frame fromLayer:self.view.layer];
    return visibleRect;
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
    
    NSArray * viewableCellIndexes = [self.gridView indexesForCellsInRect:[self.gridView bounds]];
    NSDictionary *cellIndices = [self.gridView cellIndices];
	for (NSNumber * key in viewableCellIndexes) {
		BlioLibraryGridViewCell * gridCell = [cellIndices objectForKey:key];
		gridCell.accessibilityElements = nil;
	}
	
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}
-(BlioLibrarySortType)librarySortType {
	return librarySortType;
}
-(void)setLibrarySortType:(BlioLibrarySortType)sortType {
	if (librarySortType != sortType) {
		librarySortType = sortType;
		if (sortType == kBlioLibrarySortTypePersonalized) {
			self.navigationItem.rightBarButtonItem = self.editButtonItem;	
		}
		else {
			if (self.editing) [self setEditing:NO animated:NO];
			self.navigationItem.rightBarButtonItem = nil;
		}
		[self fetchResults];
	}
}
-(void) calculateMaxLayoutPageEquivalentCount {
	
	// calculateMaxLayoutPageEquivalentCount is deactivated because we have decided to have all reading progress bars display as the same size (instead of relative size); we are intentionally returning prematurely.	
	return;
	
	NSManagedObjectContext * moc = [self managedObjectContext];
	
	NSFetchRequest *maxFetch = [[NSFetchRequest alloc] init];
	[maxFetch setEntity:[NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:moc]];
	[maxFetch setResultType:NSDictionaryResultType];
 	[maxFetch setPredicate:[NSPredicate predicateWithFormat:@"processingState >= %@", [NSNumber numberWithInt:kBlioBookProcessingStateIncomplete]]];
	
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
		[[NSNotificationCenter defaultCenter] postNotificationName:BlioMaxLayoutPageEquivalentCountChanged object:self];
		NSLog(@"max layoutPageEquivalentCount value found: %u",maxLayoutPageEquivalentCount);
	}
	
	[maxFetch release];
	[expressionDescription release];
}
-(void) configureTableCell:(BlioLibraryListCell*)cell atIndexPath:(NSIndexPath*)indexPath {
	cell.book = [self.fetchedResultsController objectAtIndexPath:indexPath];
	cell.delegate = self;
	
	cell.showsReorderControl = YES;	
}
-(void) configureGridCell:(BlioLibraryGridViewCell*)cell atIndex:(NSInteger)index {
	//	NSLog(@"configureGridCell atIndex: %i",index);
	NSIndexPath * indexPath = [NSIndexPath indexPathForRow:index inSection:0];
	cell.book = [self.fetchedResultsController objectAtIndexPath:indexPath];
	cell.accessibilityElements = nil;
}

- (void)moveBookInManagedObjectContextFromPosition:(NSInteger)fromPosition toPosition:(NSInteger)toPosition shouldSave:(BOOL)savePreference {
	if (fromPosition == toPosition) {
		NSLog(@"moveBookInManagedObjectContextFromPosition fromPosition == toPosition. returning prematurely...");
		return;
	}
	
	NSManagedObjectContext *moc = [self managedObjectContext]; 
	
	NSInteger lowerBounds = fromPosition;
	NSInteger upperBounds = toPosition;
	if (toPosition < lowerBounds) {
		lowerBounds = toPosition;
		upperBounds = fromPosition;
	}
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:moc]];
	
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"libraryPosition >= %@ && libraryPosition <= %@", [NSNumber numberWithInt:lowerBounds],[NSNumber numberWithInt:upperBounds]]];
	
	NSError *errorExecute = nil; 
	NSArray *results = [moc executeFetchRequest:fetchRequest error:&errorExecute]; 
	[fetchRequest release];
	
	if (errorExecute) {
		NSLog(@"Error getting executeFetchRequest results. %@, %@", errorExecute, [errorExecute userInfo]);
		return;
	}
	
	for (BlioBook* aBook in results) {
		if ([aBook.libraryPosition intValue] == fromPosition) [aBook setValue:[NSNumber numberWithInt:toPosition] forKey:@"libraryPosition"];
        else {
			NSInteger newPosition = [aBook.libraryPosition intValue];
			if (fromPosition > newPosition) newPosition++;
			if (toPosition >= newPosition) newPosition--;
			[aBook setValue:[NSNumber numberWithInt:newPosition] forKey:@"libraryPosition"];
		}		
	}
	
	if (savePreference) {
		NSError * error;
		if (![moc save:&error]) {
			NSLog(@"Save failed in BlioLibraryViewController (attempted to re-order fetched results): %@, %@", error, [error userInfo]);
		}
	}	
}
-(void) fetchResults {
    NSManagedObjectContext *moc = [self managedObjectContext]; 
	if (!moc) NSLog(@"WARNING: ManagedObjectContext is nil inside BlioLibraryViewController!");
	
    NSFetchRequest *request = [[NSFetchRequest alloc] init]; 
	
    NSSortDescriptor *sortDescriptor = nil;
	switch (librarySortType) {
		case kBlioLibrarySortTypeTitle:
			sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES] autorelease];
			break;
		case kBlioLibrarySortTypeAuthor:
			sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"author" ascending:YES] autorelease];
			break;
        default: {
			sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"libraryPosition" ascending:NO] autorelease];
		}
	}
	NSArray *sorters = [NSArray arrayWithObject:sortDescriptor]; 
    
    [request setFetchBatchSize:30]; // Never fetch more than 30 books at one time
    [request setEntity:[NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:moc]];
    [request setSortDescriptors:sorters];
 	[request setPredicate:[NSPredicate predicateWithFormat:@"processingState >= %@", [NSNumber numberWithInt:kBlioBookProcessingStateIncomplete]]];
    
	self.fetchedResultsController = [[[NSFetchedResultsController alloc]
									  initWithFetchRequest:request
									  managedObjectContext:moc
									  sectionNameKeyPath:nil
									  cacheName:@"BlioFetchedBooks"] autorelease];
    [request release];
    
    [self.fetchedResultsController setDelegate:self];
    NSError *error = nil; 
    [self.fetchedResultsController performFetch:&error];
	
    if (error) 
        NSLog(@"Error loading from persistent store: %@, %@", error, [error userInfo]);
	else {
		[self.tableView reloadData];
		[self.gridView reloadData];		
	}
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
		gridCell.delegate = self;
	}
	else {
		//		NSLog(@"fetching recycled cell...");
		gridCell.frame = [gridView frameForCellAtGridIndex: index];
	}
	
	// populate gridCell
	[self configureGridCell:gridCell atIndex:index];
	
	return gridCell;
}

-(NSInteger)numberOfItemsInGridView:(MRGridView*)gridView{
    NSArray *sections = [self.fetchedResultsController sections];
    NSUInteger bookCount = 0;
	if ([sections count]) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:0];
        bookCount = [sectionInfo numberOfObjects];
    }
	return bookCount;
}

-(NSString*)contentDescriptionForCellAtIndex:(NSInteger)index {
	return [[self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]] title];
}
-(void) gridView:(MRGridView*)gridView moveCellAtIndex: (NSInteger)fromIndex toIndex: (NSInteger)toIndex {
	_didEdit = YES;
//	NSLog(@"fromIndex: %i, toIndex: %i",fromIndex,toIndex);
	BlioBook * fromBook = [[self.fetchedResultsController fetchedObjects] objectAtIndex:fromIndex];
	BlioBook * toBook = [[self.fetchedResultsController fetchedObjects] objectAtIndex:toIndex];
	NSInteger fromPosition = [fromBook.libraryPosition intValue];
	NSInteger toPosition = [toBook.libraryPosition intValue];
//	NSLog(@"fromPosition: %i, toPosition: %i",fromPosition,toPosition);
/*	
	// tracing purposes
	NSInteger fetchedResultsCount = [self.fetchedResultsController.fetchedObjects count];
	for (NSInteger i = 0; i < fetchedResultsCount; i++)
	{
		BlioBook * aBook = [[self.fetchedResultsController fetchedObjects] objectAtIndex:i];
		NSLog(@"index: %i, libraryPosition: %i, title: %@",i,[aBook.libraryPosition intValue],aBook.title);
		
	}
*/	
	[self moveBookInManagedObjectContextFromPosition:fromPosition toPosition:toPosition shouldSave:NO];
	
}
-(void) gridView:(MRGridView*)gridView finishedMovingCellToIndex:(NSInteger)toIndex {
	_didEdit = YES;	
	NSManagedObjectContext *moc = [self managedObjectContext]; 
	NSError * error;
	if (![moc save:&error]) {
		NSLog(@"Save failed in BlioLibraryViewController (attempted to re-order fetched results gridView moveCellAtIndexs): %@, %@", error, [error userInfo]);
	}
	
}
-(void) gridView:(MRGridView*)gridView commitEditingStyle:(MRGridViewCellEditingStyle)editingStyle forIndex:(NSInteger)index {
	//	NSLog(@"gridView:commitEditingStyle:%i forIndex:%i entered",editingStyle,index);
	if (editingStyle == MRGridViewCellEditingStyleDelete) {
		
		
		// Delete the book from the data source.
		
		BlioBook * bookToBeDeleted = [[self.fetchedResultsController fetchedObjects] objectAtIndex:index];
		
		[self.processingDelegate deleteBook:bookToBeDeleted shouldSave:YES];
		
		//		[gridView deleteIndices:[NSArray arrayWithObject:[NSNumber numberWithInt:index]] withCellAnimation:MRGridViewCellAnimationFade];
		
	}   
	
}

#pragma mark - 
#pragma mark MRGridViewDelegate methods

- (void)gridView:(MRGridView *)gridView didSelectCellAtIndex:(NSInteger)index{
	//	NSLog(@"selected cell %i",index);
	BlioLibraryGridViewCell * cell = (BlioLibraryGridViewCell*)[self.gridView cellAtGridIndex:index];
	if ([[cell.book valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateComplete) {
		[self bookSelected:cell.bookView];
	}
}
-(void)gridView:(MRGridView *)gridView confirmationForDeletionAtIndex:(NSInteger)index {
	_keyValueOfCellToBeDeleted = index;
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Please confirm...",@"\"Please confirm...\" alert message title")
													message:[NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"CONFIRM_DELETE_ACTION", nil,[NSBundle mainBundle],@"Are you sure you want to delete %@?",@"Message requesting to confirm delete action within MRGridView"), [self contentDescriptionForCellAtIndex:index] ]
												   delegate:self
										  cancelButtonTitle:NSLocalizedString(@"Cancel",@"\"Cancel\" alert button")
										  otherButtonTitles:nil];
	[alert addButtonWithTitle:NSLocalizedString(@"Delete",@"\"Delete\" alert button")];
	[alert show];
	[alert release];	
}
#pragma mark - 
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	if([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Delete",@"\"Delete\" alert button")])
	{
		
		[self gridView:self.gridView commitEditingStyle:MRGridViewCellEditingStyleDelete forIndex:_keyValueOfCellToBeDeleted];
	}
	[alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
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
	return cell;
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BlioBook *selectedBook = [self.fetchedResultsController objectAtIndexPath:indexPath];
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
	//	NSLog(@"tableView moveRowAtIndexPath fromIndexPath: %i, toIndexPath: %i",fromIndexPath.row,toIndexPath.row);
	_didEdit = YES;
	BlioBook * fromBook = [[self.fetchedResultsController fetchedObjects] objectAtIndex:fromIndexPath.row];
	BlioBook * toBook = [[self.fetchedResultsController fetchedObjects] objectAtIndex:toIndexPath.row];
	NSInteger fromPosition = [fromBook.libraryPosition intValue];
	NSInteger toPosition = [toBook.libraryPosition intValue];
//		NSLog(@"fromPosition: %i, toPosition: %i",fromPosition,toPosition);
		
	 // tracing purposes
//	NSInteger fetchedResultsCount = [self.fetchedResultsController.fetchedObjects count];
//	 for (NSInteger i = 0; i < fetchedResultsCount; i++)
//	 {
//	 BlioBook * aBook = [[self.fetchedResultsController fetchedObjects] objectAtIndex:i];
//	 NSLog(@"PRE index: %i, libraryPosition: %i, title: %@",i,[aBook.libraryPosition intValue],aBook.title);
//	 
//	 }
	
	[self moveBookInManagedObjectContextFromPosition:fromPosition toPosition:toPosition shouldSave:YES];
	
	// moveRowAtIndexPath is called before UITableView updates its internal indexPaths, so we need to calculate what the indexPath for each cell *will* be when the move is complete, and use that value to color the cell background.
	NSArray * indexPaths = [tableView indexPathsForVisibleRows];
	[UIView beginAnimations:@"changeRowBackgroundColor" context:nil];
	for (NSIndexPath * visiblePath in indexPaths) {
		NSInteger newRow = visiblePath.row;
		if (fromIndexPath.row < visiblePath.row) newRow--;
		if (toIndexPath.row < visiblePath.row) newRow++;
		if (toIndexPath.row < fromIndexPath.row && toIndexPath.row == visiblePath.row) newRow++;
		NSLog(@"oldrow: %i newrow: %i",visiblePath.row,newRow);
		[self tableView:tableView willDisplayCell:[tableView cellForRowAtIndexPath:visiblePath] forRowAtIndexPath:[NSIndexPath indexPathForRow:newRow inSection:visiblePath.section]];
	}
	NSLog(@"[tableView cellForRowAtIndexPath:fromIndexPath]: %@",[tableView cellForRowAtIndexPath:fromIndexPath]);
	NSLog(@"[[tableView visibleCells] count]: %i",[[tableView visibleCells] count]);
	[self tableView:tableView willDisplayCell:[tableView cellForRowAtIndexPath:fromIndexPath] forRowAtIndexPath:toIndexPath];
	[UIView commitAnimations];
	if ([tableView cellForRowAtIndexPath:fromIndexPath] == nil) {
		// if fromIndexPath is "off the screen", UITableView provides no way to get a reference to the cell that was just dragged, so we need to update this cell's background color after UITableView has updated its cell's indexPaths.
		[self performSelector:@selector(delayedChangeTableCellBackground:) withObject:toIndexPath afterDelay:.01];
	}
}
-(void)delayedChangeTableCellBackground:(NSIndexPath*)indexPath {
	[UIView beginAnimations:@"changeDraggedRowBackgroundColor" context:nil];
	[self tableView:self.tableView willDisplayCell:[self.tableView cellForRowAtIndexPath:indexPath] forRowAtIndexPath:indexPath];
	[UIView commitAnimations];
}

 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	 if (editingStyle == UITableViewCellEditingStyleDelete) {
		 // Delete the row from the data source.
		 BlioBook * bookToBeDeleted = [[self.fetchedResultsController fetchedObjects] objectAtIndex:indexPath.row];		 
		 NSUInteger bookLayoutPageEquivalentCount = [bookToBeDeleted.layoutPageEquivalentCount unsignedIntValue];
		 [self.processingDelegate deleteBook:bookToBeDeleted shouldSave:YES];
		 if (bookLayoutPageEquivalentCount == maxLayoutPageEquivalentCount) [self calculateMaxLayoutPageEquivalentCount];
	 }   
	 else if (editingStyle == UITableViewCellEditingStyleInsert) {
		 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
	 }   
 }

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

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	//	NSLog(@"controllerWillChangeContent");
	//    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath {
//	BlioBook * book = (BlioBook*)anObject;
//	NSLog(@"controller didChangeObject. type: %i, _didEdit: %i title: %@, libraryPosition: %i",type,_didEdit,book.title,[book.libraryPosition intValue]);
	
	switch(type) {
			
		case NSFetchedResultsChangeInsert:
			//				[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
			//								 withRowAnimation:UITableViewRowAnimationFade];
			switch (self.libraryLayout) {
				case kBlioLibraryLayoutGrid:
					[self.gridView reloadData];
					break;
				case kBlioLibraryLayoutList:
					[self.tableView reloadData];
					break;
                default:
                    break;
			}
			break;
			
		case NSFetchedResultsChangeDelete:
			switch (self.libraryLayout) {
				case kBlioLibraryLayoutGrid:
					[self.gridView deleteIndices:[NSArray arrayWithObject:[NSNumber numberWithInt:indexPath.row]] withCellAnimation:MRGridViewCellAnimationFade];
					break;
				case kBlioLibraryLayoutList: {
					NSArray * indexPaths = [self.tableView indexPathsForVisibleRows];
					[UIView beginAnimations:@"changeRowBackgroundColor" context:nil];
					for (NSIndexPath * visiblePath in indexPaths) {
						if (visiblePath.row > indexPath.row) {
							[self tableView:self.tableView willDisplayCell:[self.tableView cellForRowAtIndexPath:visiblePath] forRowAtIndexPath:[NSIndexPath indexPathForRow:visiblePath.row-1 inSection:visiblePath.section]];
						}
					}				
					[UIView commitAnimations];
					[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
				}
					break;
                default:
                    break;
			}
			break;
			
		case NSFetchedResultsChangeUpdate:
			if (!_didEdit) {
				switch (self.libraryLayout) {
					case kBlioLibraryLayoutGrid:
						[self configureGridCell:(BlioLibraryGridViewCell*)[self.gridView cellAtGridIndex:indexPath.row]
										atIndex:indexPath.row];
						break;
					case kBlioLibraryLayoutList:
						[self configureTableCell:(BlioLibraryListCell*)[self.tableView cellForRowAtIndexPath:indexPath]
									 atIndexPath:indexPath];
						break;
                    default:
                        break;
				}
			}
			break;
			// this will always be user-instigated, so the view will actually be updated before the model, not the other way around.
			//			case NSFetchedResultsChangeMove:
			//				[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
			//								 withRowAnimation:UITableViewRowAnimationFade];
			//				[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
			//								 withRowAnimation:UITableViewRowAnimationFade];
			//				break;
	}
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	// 	NSLog(@"controllerDidChangeContent. _didEdit: %i",_didEdit);
	
	//   [self.tableView endUpdates];
	
}
/*
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
 NSLog(@"BlioLibraryViewController controllerDidChangeContent entered");
 if (!_didEdit) {
 [self.tableView reloadData];
 [self.gridView reloadData];
 }
 else _didEdit = NO;
 
 }
 */
#pragma mark -
#pragma mark Core Data Multi-Threading
- (void)mergeChangesFromContextDidSaveNotification:(NSNotification *)notification {
	//	NSLog(@"BlioLibraryViewController mergeChangesFromContextDidSaveNotification received...");	
	//	if (notification.object == self.managedObjectContext) {
	//		NSLog(@"...from same moc as library- returning.");
	//		return;
	//	}
	//	else NSLog(@"...from a moc other than the library's moc. will continue with merge and save.");
    // Fault in all updated objects
	
	//refresh updated objects and merge changes
	//	NSArray* updates = [[notification.userInfo objectForKey:NSUpdatedObjectsKey] allObjects];
	//  for (NSManagedObject *object in updates) {
	//      [[self.managedObjectContext objectWithID:[object objectID]] willAccessValueForKey:nil];
	//  }
	//	for (NSInteger i = [updates count]-1; i >= 0; i--)
	//	{
	//		[[managedObjectContext objectWithID:[[updates objectAtIndex:i] objectID]] willAccessValueForKey:nil];
	//	}
    
	// Merge
	[[self managedObjectContext] mergeChangesFromContextDidSaveNotification:notification];
	
	// this code below happens after NSFetchedControllerDelegate methods are called.
	
	//    NSArray *updatedObjects = [[notification userInfo] valueForKey:NSUpdatedObjectsKey];
	//    if ([updatedObjects count]) {
	//        [self.tableView reloadData];
	//        NSLog(@"objects updated");
	//    }
	//    NSLog(@"Did save");
}

#pragma mark -
#pragma mark Toolbar Actions

- (void)showStore:(id)sender {    
    BlioStoreTabViewController *aStoreController = [[BlioStoreTabViewController alloc] initWithProcessingDelegate:self.processingDelegate managedObjectContext:self.managedObjectContext];
	[self presentModalViewController:aStoreController animated:YES];
    [aStoreController release];    
}

- (void)showSortOptions:(id)sender {    
	// show sheet interface
	NSString * sheetTitle = NSLocalizedString(@"Select Sort Order:",@"\"Select Sort Order:\" sort sheet title");
	NSString * sort0 = NSLocalizedString(@"Personalized",@"\"Personalized...\" library sort option");
	NSString * sort1 = NSLocalizedString(@"By Title",@"\"By Title...\" library sort option");
	NSString * sort2 = NSLocalizedString(@"By Author",@"\"By Author...\" library sort option");
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:sheetTitle
															 delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",@"\"Cancel\" sheet button") 
											   destructiveButtonTitle:nil
													otherButtonTitles:sort0, sort1, sort2, nil];
	actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
	[actionSheet showInView:self.view];
	[actionSheet release];	
}

- (void)showSettings:(id)sender {    
	UINavigationController *settingsController = [[UINavigationController alloc] initWithRootViewController:[[BlioAppSettingsController alloc] init]];
    
	// TEMPORARY: test code, will be moved
    
    // Fetch all paid books
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entityDescription];
    
    NSError *error;
    NSArray *paidBooks = [self.managedObjectContext executeFetchRequest:request error:&error];
    NSManagedObjectID *virginID = nil;
    NSManagedObjectID *rabbitID = nil;

    // Iterate through the paid books getting their ids
    for (NSManagedObject *book in paidBooks) {
        if ([[book valueForKey:@"title"] isEqualToString:@"Virgin Islands"])
            virginID = book.objectID;
        else if ([[book valueForKey:@"title"] isEqualToString:@"The Tale of Peter Rabbit"])
            rabbitID = book.objectID;
    }
    
    BOOL success = [[BlioDrmManager getDrmManager] getLicenseForBookWithID:virginID];
    NSLog(@"License retrieval for virgin book %@.", success ? @"succeeded" : @"failed");
    success = [[BlioDrmManager getDrmManager] getLicenseForBookWithID:rabbitID];
    NSLog(@"License retrieval for rabbit book %@.", success ? @"succeeded" : @"failed");
    
    BlioXPSProvider *virginXPS = [[[BlioBookManager sharedBookManager] bookWithID:virginID] xpsProvider];
    BlioXPSProvider *rabbitXPS = [[[BlioBookManager sharedBookManager] bookWithID:rabbitID] xpsProvider];

    NSData *decryptedData;


    // Decrypt a textflow file for Virgin Islands.
    decryptedData = [virginXPS dataForComponentAtPath:[encryptedTextflowDir stringByAppendingString:@"Flow_2.xml"]];
    NSLog(@"Virgin Islands decrypted textflow length (%d): %s", [decryptedData length], [decryptedData bytes]);  // Not null-terminated, but gives an idea.
    
    // Decrypt a fixed page for Virgin Islands.
    decryptedData = [virginXPS dataForComponentAtPath:[encryptedPagesDir stringByAppendingString:@"1.fpage.bin"]];
    NSLog(@"Virgin Islands decrypted fixed page 1 length (%d): %s", [decryptedData length], [decryptedData bytes]);  // Not null-terminated, but gives an idea.
	
    // Decrypt a fixed page for Virgin Islands by requesting the dummy page
    decryptedData = [virginXPS dataForComponentAtPath:@"/Documents/1/Pages/2.fpage"];
    NSLog(@"Virgin Islands decrypted fixed page 2 length (%d): %s", [decryptedData length], [decryptedData bytes]);  // Not null-terminated, but gives an idea.

	//	
	// END temporary code
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (self.settingsPopoverController && self.settingsPopoverController.popoverVisible == YES) {
			[self.settingsPopoverController dismissPopoverAnimated:YES];
			self.settingsPopoverController = nil;
		}
		else {
			self.settingsPopoverController = [[[NSClassFromString(@"UIPopoverController") alloc] initWithContentViewController:settingsController] autorelease];
			self.settingsPopoverController.popoverContentSize = CGSizeMake(320, 600);
			self.settingsPopoverController.delegate = self;
			[self.settingsPopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		}
	}
	else {
		[self presentModalViewController:settingsController animated:YES];
	}	
#else
	[self presentModalViewController:settingsController animated:YES];
#endif
	
    [settingsController release];    
}

#pragma mark - UIPopoverControllerDelegate
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	// N.B. - from Apple's documentation: The popover controller does not call this method in response to programmatic calls to the dismissPopoverAnimated: method.
	self.settingsPopoverController = nil;
}

#endif

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	//	NSLog(@"buttonIndex: %i",buttonIndex);
	if (buttonIndex == actionSheet.cancelButtonIndex) {
		NSLog(@"Sort Sheet cancelled");
		return;
	}
	
	self.librarySortType = buttonIndex;	
}

#pragma mark -
#pragma mark Library Actions

-(void) pauseProcessingForBook:(BlioBook*)book {
		[self.processingDelegate pauseProcessingForBook:book];
}
-(void) enqueueBook:(BlioBook*)book {
		[self.processingDelegate enqueueBook:book];
}

- (void)changeLibraryLayout:(id)sender {
    
    BlioLibraryLayout newLayout = (BlioLibraryLayout)[sender selectedSegmentIndex];
    
    if (self.libraryLayout != newLayout) {
        self.libraryLayout = newLayout;
        [[NSUserDefaults standardUserDefaults] setInteger:self.libraryLayout forKey:@"kBlioLastLibraryLayoutDefaultsKey"];
        
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
        
        BlioBook *currentBook = [self.currentBookView book];
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
    
    if (self.bookCoverPopped && !self.firstPageRendered) {
        self.firstPageRendered = YES;
        [self removeShrinkBookAnimation:[self.currentPoppedBookCover superview]];
        [(BlioBookViewController *)self.navigationController.topViewController toggleToolbars];
        
        self.currentPoppedBookCover = nil;
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                        name:@"blioCoverPageDidFinishRender" 
                                                      object:nil];
    }    
    
	
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
        self.userInteractionEnabled = NO;
        
        UIImageView *aTextureView = [[UIImageView alloc] initWithFrame:self.bounds];
        aTextureView.contentMode = UIViewContentModeScaleToFill;
        aTextureView.image = [UIImage imageNamed:@"booktextureandshadowsubtle.png"];
        aTextureView.backgroundColor = [UIColor clearColor];
        aTextureView.alpha = 0.0f;
        aTextureView.userInteractionEnabled = NO;
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
        aImageView.userInteractionEnabled = NO;
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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)setBook:(BlioBook *)newBook {
    [self setBook:newBook forLayout:kBlioLibraryLayoutGrid];
}

- (void)setBook:(BlioBook *)newBook forLayout:(BlioLibraryLayout)layout {
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

@synthesize bookView, titleLabel, authorLabel, progressSlider,progressView, progressBackgroundView,delegate,pauseButton,resumeButton,pausedLabel;
@synthesize accessibilityElements;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.bookView = nil;
    self.titleLabel = nil;
    self.authorLabel = nil;
    self.progressSlider = nil;
	self.progressView = nil;
	self.pauseButton = nil;
	self.resumeButton = nil;
	self.progressBackgroundView = nil;
	self.pausedLabel = nil;
    self.delegate = nil;
    self.accessibilityElements = nil;
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame reuseIdentifier: (NSString*) identifier{
    if ((self = [super initWithFrame:frame reuseIdentifier:identifier])) {
        
		CGFloat bookWidth = kBlioLibraryGridBookWidth;
		CGFloat bookHeight = kBlioLibraryGridBookHeight;
		
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			bookWidth = kBlioLibraryGridBookWidthPad;
			bookHeight = kBlioLibraryGridBookHeightPad;
		}
#endif
        BlioLibraryBookView* aBookView = [[BlioLibraryBookView alloc] initWithFrame:CGRectMake(0,0, bookWidth, bookHeight)];
		//        [aBookView addTarget:self.delegate action:@selector(bookTouched:)
		//            forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:aBookView];
		self.bookView = aBookView;
		
		progressBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"library-progress-background.png"]];
		progressBackgroundView.center = CGPointMake(self.frame.size.width/2, kBlioLibraryGridBookHeight-25);
		progressBackgroundView.hidden = YES;
		[self.contentView addSubview:progressBackgroundView];
		
		pausedLabel = [[UILabel alloc] initWithFrame:progressBackgroundView.bounds];
		pausedLabel.textAlignment = UITextAlignmentCenter;
		pausedLabel.backgroundColor = [UIColor clearColor];
		pausedLabel.textColor = [UIColor whiteColor];
		pausedLabel.text = NSLocalizedString(@"Paused...","\"Paused...\" status indicator in BlioLibraryGridViewCell");
		pausedLabel.hidden = YES;
		pausedLabel.font = [UIFont boldSystemFontOfSize:12.0];
		[progressBackgroundView addSubview:pausedLabel];
		
		progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
		progressView.frame = CGRectMake(0, 0, kBlioLibraryGridProgressViewWidth, 10);
        progressView.center = progressBackgroundView.center;
		progressView.hidden = YES;
		[self.contentView addSubview:progressView];
		
		pauseButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 33, 33)];
		[pauseButton setImage:[UIImage imageNamed:@"library-pausebutton.png"] forState:UIControlStateNormal];
		pauseButton.showsTouchWhenHighlighted = YES;
		[pauseButton addTarget:delegate action:@selector(onPauseButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		pauseButton.center = CGPointMake(self.frame.size.width/2, kBlioLibraryGridBookHeight/2);
		pauseButton.hidden = YES;
		[self.contentView addSubview:pauseButton];
		
		resumeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 33, 33)];
		[resumeButton setImage:[UIImage imageNamed:@"library-resumebutton.png"] forState:UIControlStateNormal];
		resumeButton.showsTouchWhenHighlighted = YES;
		[resumeButton addTarget:delegate action:@selector(onResumeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		resumeButton.center = CGPointMake(self.frame.size.width/2, kBlioLibraryGridBookHeight/2);
		resumeButton.hidden = YES;
		[self.contentView addSubview:resumeButton];
		
        [aBookView release];
	}
    return self;
}
-(void) prepareForReuse{
	[super prepareForReuse];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	progressBackgroundView.hidden = YES;
	progressView.hidden = YES;
	pauseButton.hidden = YES;
	resumeButton.hidden = YES;
	pausedLabel.hidden = YES;
	self.bookView.alpha = 1;
}
-(void)onPauseButtonPressed:(id)sender {
	[delegate pauseProcessingForBook:[self book]];
}
-(void)onResumeButtonPressed:(id)sender {
	[delegate enqueueBook:[self book]];
}
- (BOOL)isAccessibilityElement {
    return NO;
}

- (NSInteger)accessibilityElementCount {
    if (nil == self.accessibilityElements) {
        NSMutableArray *accArray = [NSMutableArray array];
        
        if (![self.deleteButton isHidden] && [self.deleteButton alpha]) {
            BlioAccessibleGridElement *deleteElement = [[BlioAccessibleGridElement alloc] initWithAccessibilityContainer:self];
            [deleteElement setTarget:self.deleteButton];
            [deleteElement setAccessibilityLabel:[NSString stringWithFormat:NSLocalizedString(@"Delete: %@", @"Accessibility label for Library View cell book delete"), 
                                                  [[self.bookView book] title]]];
            [deleteElement setAccessibilityTraits:UIAccessibilityTraitButton];
            [deleteElement setVisibleRect:[self.delegate visibleRect]];
            [accArray addObject:deleteElement];
        }
		
        BlioAccessibleGridElement *bookElement = [[BlioAccessibleGridElement alloc] initWithAccessibilityContainer:self];
        [bookElement setTarget:self];
        [bookElement setAccessibilityLabel:[NSString stringWithFormat:NSLocalizedString(@"%@ by %@, %.0f%% complete", @"Accessibility label for Library View cell book description"), 
											[[self.bookView book] title], [[self.bookView book] author], 100 * [[[self.bookView book] progress] floatValue]]];
		
        [bookElement setAccessibilityTraits:UIAccessibilityTraitButton];
        [bookElement setVisibleRect:[self.delegate visibleRect]];
        if (![self.deleteButton isHidden] && [self.deleteButton alpha]) {
            [bookElement setAccessibilityHint:NSLocalizedString(@"Draggable. Double-tap and hold then move to desired location.", @"Accessibility hint for Library View cell book when editing")];
        } else {
            [bookElement setAccessibilityHint:NSLocalizedString(@"Opens book.", @"Accessibility hint for Library View cell book when not editing")];
        }
        [accArray addObject:bookElement];
        
        self.accessibilityElements = accArray;
    }
    
    return [self.accessibilityElements count];
}

- (id)accessibilityElementAtIndex:(NSInteger)index {    
    return [self.accessibilityElements objectAtIndex:index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
    return [self.accessibilityElements indexOfObject:element];
}

- (BlioBook *)book {
    return [(BlioLibraryBookView *)self.bookView book];
}

- (void)setBook:(BlioBook *)newBook {
	[self stopListeningToProcessingNotifications];
    [(BlioLibraryBookView *)self.bookView setBook:newBook forLayout:0];
    self.titleLabel.text = [newBook title];
	self.cellContentDescription = [newBook title];
    self.authorLabel.text = [[newBook author] uppercaseString];
    if ([newBook audioRights]) {
        self.authorLabel.text = [NSString stringWithFormat:@"%@ %@", self.authorLabel.text, @"♫"];
    }
    self.progressSlider.value = [[newBook progress] floatValue];
    //CGRect progressFrame = self.progressSlider.frame;
    //self.progressSlider.frame = CGRectMake(progressFrame.origin.x, progressFrame.origin.y, [[newBook proportionateSize] floatValue] * kBlioLibraryListContentWidth, progressFrame.size.height);
    [self setNeedsLayout];
//	NSLog(@"[[self.book valueForKey:@processingState] intValue]: %i",[[self.book valueForKey:@"processingState"] intValue]);
	if ([[self.book valueForKey:@"processingState"] intValue] == kBlioBookProcessingStatePlaceholderOnly) {
		self.progressBackgroundView.hidden = YES;
		self.progressView.hidden = YES;
		self.pauseButton.hidden = YES;
		self.resumeButton.hidden = NO;
		self.pausedLabel.hidden = YES;
	}	
	else if ([[self.book valueForKey:@"processingState"] intValue] != kBlioBookProcessingStateComplete) {
		[self listenToProcessingNotifications];
		// set appearance to reflect incomplete state
		self.bookView.alpha = 0.35f;
		self.progressBackgroundView.hidden = NO;
		
		if ([[self.book valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateIncomplete) {
			self.progressView.hidden = NO;
			BlioProcessingCompleteOperation * completeOp = [[delegate processingDelegate] processingCompleteOperationForSourceID:[[self.book valueForKey:@"sourceID"] intValue] sourceSpecificID:[self.book valueForKey:@"sourceSpecificID"]];
			if (completeOp) {
				[completeOp calculateProgress];
				progressView.progress = ((float)(completeOp.percentageComplete)/100.0f);
			}
			else {
				// NSLog(@"WARNING: could not find completeOp for obtaining processing progress for book: %@",[newBook title]);
				progressView.progress = 0;
			}
			self.pauseButton.hidden = NO;
			self.resumeButton.hidden = YES;
			self.pausedLabel.hidden = YES;
		}
		if ([[self.book valueForKey:@"processingState"] intValue] == kBlioBookProcessingStatePaused) {
			self.resumeButton.hidden = NO;
			self.pausedLabel.hidden = NO;
			self.progressView.hidden = YES;
			self.pauseButton.hidden = YES;
		}
	}
	else {
		self.resumeButton.hidden = YES;
		self.pausedLabel.hidden = YES;
		self.progressView.hidden = YES;
		self.pauseButton.hidden = YES;
		self.progressBackgroundView.hidden = YES;
		bookView.alpha = 1;
	}
}
-(void) listenToProcessingNotifications {
	//	NSOperation * completeOp = [[delegate processingDelegate] processingCompleteOperationForSourceID:[[self.book valueForKey:@"sourceID"] intValue] sourceSpecificID:[self.book valueForKey:@"sourceSpecificID"]];
	//	if (completeOp != nil && [completeOp isKindOfClass:[BlioProcessingCompleteOperation class]]) {
	//			NSLog(@"adding table cell as observer...");
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingProgressNotification:) name:BlioProcessingOperationProgressNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingCompleteNotification:) name:BlioProcessingOperationCompleteNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingFailedNotification:) name:BlioProcessingOperationFailedNotification object:nil];
	//	}	
}
-(void) stopListeningToProcessingNotifications {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioProcessingOperationProgressNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioProcessingOperationCompleteNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioProcessingOperationFailedNotification object:nil];
}

- (void)setDelegate:(id)newDelegate {
	//    [self.bookView removeTarget:delegate action:@selector(bookTouched:)
	//               forControlEvents:UIControlEventTouchUpInside];
    
    delegate = newDelegate;
	//    [self.bookView addTarget:delegate action:@selector(bookTouched:)
	//            forControlEvents:UIControlEventTouchUpInside];
}
- (void)onProcessingProgressNotification:(NSNotification*)note {
	if ([[note object] isKindOfClass:[BlioProcessingCompleteOperation class]] && [note userInfo] && self.book && [[note userInfo] objectForKey:@"bookID"] == [self.book objectID]) {
		//	NSLog(@"BlioLibraryGridViewCell onProcessingProgressNotification entered. percentage: %u",completeOp.percentageComplete);
		BlioProcessingCompleteOperation * completeOp = [note object];
		progressView.progress = ((float)(completeOp.percentageComplete)/100.0f);
	}
}
- (void)onProcessingCompleteNotification:(NSNotification*)note {
	if ([[note object] isKindOfClass:[BlioProcessingCompleteOperation class]] && [note userInfo] && self.book && [[note userInfo] objectForKey:@"bookID"] == [self.book objectID]) {
		//	NSLog(@"BlioLibraryGridViewCell onProcessingCompleteNotification entered");
		progressBackgroundView.hidden = YES;
		pauseButton.hidden = YES;	
		resumeButton.hidden = YES;	
		progressView.hidden = YES;
		bookView.alpha = 1;
		self.pausedLabel.hidden = YES;
	}
}
- (void)onProcessingFailedNotification:(NSNotification*)note {
	if ([[note object] isKindOfClass:[BlioProcessingCompleteOperation class]] && [note userInfo] && self.book && [[note userInfo] objectForKey:@"bookID"] == [self.book objectID]) {
		NSLog(@"BlioLibraryGridViewCell onProcessingFailedNotification entered");
	}
}
@end

@implementation BlioLibraryListCell

@synthesize bookView, titleLabel, authorLabel, progressSlider,proportionalProgressView, delegate,progressView,pauseButton,resumeButton;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.bookView = nil;
    self.titleLabel = nil;
    self.authorLabel = nil;
    self.progressSlider = nil;
    self.progressView = nil;
	self.pauseButton = nil;
	self.resumeButton = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.selectionStyle = UITableViewCellSelectionStyleGray;
        
		self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
		self.backgroundView.autoresizesSubviews = YES;
		UIImageView * dividerView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SearchCellDivider.png"]];
		dividerView.frame = CGRectMake(0,0,self.bounds.size.width,2);
		[self.backgroundView addSubview:dividerView];
		dividerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
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
        
        BlioProgressView *aSlider = [[BlioProgressView alloc] init];
        [aSlider setIsAccessibilityElement:NO];
        aSlider.userInteractionEnabled = NO;
        aSlider.value = 0.0f;
        [aSlider setFrame:CGRectMake(CGRectGetMaxX(self.bookView.frame) + 6, 54, kBlioLibraryListContentWidth, 9)];
        [self.contentView addSubview:aSlider];
        self.progressSlider = aSlider;
        [aSlider release];
		
		progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
		progressView.frame = CGRectMake(68, 52, kBlioLibraryListProgressViewWidth, 10);
		progressView.hidden = YES;
		[self.contentView addSubview:progressView];
		
		pauseButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 33, 33)];
		[pauseButton setImage:[UIImage imageNamed:@"library-pausebutton.png"] forState:UIControlStateNormal];
		pauseButton.showsTouchWhenHighlighted = YES;
		[pauseButton addTarget:delegate action:@selector(onPauseButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		pauseButton.center = CGPointMake(self.frame.size.width/2, kBlioLibraryGridBookHeight/2);
		
		resumeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 33, 33)];
		[resumeButton setImage:[UIImage imageNamed:@"library-resumebutton.png"] forState:UIControlStateNormal];
		resumeButton.showsTouchWhenHighlighted = YES;
		[resumeButton addTarget:delegate action:@selector(onResumeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		resumeButton.center = CGPointMake(self.frame.size.width/2, kBlioLibraryGridBookHeight/2);
	}
    return self;
}
-(void)prepareForReuse {
	[super prepareForReuse];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.accessoryView = nil;
	progressView.hidden = YES;
	progressSlider.hidden = YES;
}
-(void)onPauseButtonPressed:(id)sender {
	[delegate pauseProcessingForBook:[self book]];
}
-(void)onResumeButtonPressed:(id)sender {
	[delegate enqueueBook:[self book]];
}

- (NSString *)accessibilityLabel {
    return [NSString stringWithFormat:NSLocalizedString(@"%@ by %@, %.0f%% complete", @"Accessibility label for Library View cell book description"), 
            [[self.bookView book] title], [[self.bookView book] author], 100 * [[[self.bookView book] progress] floatValue]];
	
}

- (NSString *)accessibilityHint {
    return NSLocalizedString(@"Opens book.", @"Accessibility label for Library View cell book hint");
}

- (BlioBook *)book {
    return [(BlioLibraryBookView *)self.bookView book];
}

- (void)setBook:(BlioBook *)newBook {
	[self stopListeningToProcessingNotifications];
    [(BlioLibraryBookView *)self.bookView setBook:newBook forLayout:kBlioLibraryLayoutList];
    self.titleLabel.text = [newBook title];
	layoutPageEquivalentCount = [self.book.layoutPageEquivalentCount unsignedIntValue];
    self.progressSlider.value = [[newBook progress] floatValue];
	
	[self resetProgressSlider];
	
	if ([[self.book valueForKey:@"processingState"] intValue] == kBlioBookProcessingStatePlaceholderOnly) {
		self.progressView.hidden = YES;
		self.accessoryView = resumeButton;
		[self resetAuthorText];
		self.progressSlider.hidden = NO;
	}			
	else if ([[self.book valueForKey:@"processingState"] intValue] != kBlioBookProcessingStateComplete) {
		[self listenToProcessingNotifications];
		// set appearance to reflect incomplete state
		// self.bookView.alpha = 0.35f;
		if ([[self.book valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateIncomplete) {
			self.progressView.hidden = NO;
			self.progressSlider.hidden = YES;
			BlioProcessingCompleteOperation * completeOp = [[delegate processingDelegate] processingCompleteOperationForSourceID:[[self.book valueForKey:@"sourceID"] intValue] sourceSpecificID:[self.book valueForKey:@"sourceSpecificID"]];
			if (completeOp) {
				[completeOp calculateProgress];
				progressView.progress = ((float)(completeOp.percentageComplete)/100.0f);
			}
			else {
				// NSLog(@"WARNING: could not find completeOp for obtaining processing progress for book: %@",[newBook title]);
				progressView.progress = 0;
			}
			self.accessoryView = pauseButton;
			self.authorLabel.text = NSLocalizedString(@"Downloading...","\"Downloading...\" status indicator in BlioLibraryListCell");
		}
		if ([[self.book valueForKey:@"processingState"] intValue] == kBlioBookProcessingStatePaused) {
			self.accessoryView = resumeButton;
			self.authorLabel.text = @"Paused...";
			self.progressSlider.hidden = YES;
		}
	}
	else {
		self.progressSlider.hidden = NO;
		progressView.hidden = YES;
		[self resetAuthorText];
		self.accessoryView = nil;
	}
    [self setNeedsLayout];
}
-(void) listenToProcessingNotifications {
	//	NSOperation * completeOp = [[delegate processingDelegate] processingCompleteOperationForSourceID:[[self.book valueForKey:@"sourceID"] intValue] sourceSpecificID:[self.book valueForKey:@"sourceSpecificID"]];
	//	if (completeOp != nil && [completeOp isKindOfClass:[BlioProcessingCompleteOperation class]]) {
	//			NSLog(@"adding table cell as observer...");
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingProgressNotification:) name:BlioProcessingOperationProgressNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingCompleteNotification:) name:BlioProcessingOperationCompleteNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingFailedNotification:) name:BlioProcessingOperationFailedNotification object:nil];
	//	}	
}
-(void) stopListeningToProcessingNotifications {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioProcessingOperationProgressNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioProcessingOperationCompleteNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioProcessingOperationFailedNotification object:nil];
}
-(void) resetProgressSlider {
    CGRect progressFrame = self.progressSlider.frame;
	CGFloat targetProgressWidth = 0;
	if (((BlioLibraryViewController*)delegate).maxLayoutPageEquivalentCount != 0) {
		
		// N.B. this condition is for when maxLayoutPageEquivalentCount is honored and progress bars should be relatively sized.
		
		CGFloat layoutPageEquivalentCountFloat = layoutPageEquivalentCount;
		targetProgressWidth = (layoutPageEquivalentCountFloat/((BlioLibraryViewController*)delegate).maxLayoutPageEquivalentCount) * kBlioLibraryListContentWidth;
		if (targetProgressWidth > kBlioLibraryListContentWidth) {
			NSLog(@"WARNING: this book's layoutPageEquivalentCount may be larger than maxLayoutPageEquivalentCount- which should never happen!");
			targetProgressWidth = kBlioLibraryListContentWidth; // should never happen but this is a safeguard.
		}
	}
	else {
		
		// N.B. this condition is for when maxLayoutPageEquivalentCount is NOT honored and progress bars should all be a standard size.
		if ([self.book.progress floatValue] > 0) {
			targetProgressWidth = kBlioLibraryListContentWidth;
		}
	}
	
	self.progressSlider.frame = CGRectMake(progressFrame.origin.x, progressFrame.origin.y, targetProgressWidth, progressFrame.size.height);	
}
-(void) resetAuthorText {
    self.authorLabel.text = [[self.book author] uppercaseString];
    if ([self.book audioRights]) {
        self.authorLabel.text = [NSString stringWithFormat:@"%@ %@", self.authorLabel.text, @"♫"];
    }	
}
- (void)setDelegate:(id)newDelegate {
	//    [self.bookView removeTarget:delegate action:@selector(bookTouched:)
	//               forControlEvents:UIControlEventTouchUpInside];
    
    delegate = newDelegate;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBlioMaxLayoutPageEquivalentCountChanged:) name:BlioMaxLayoutPageEquivalentCountChanged object:newDelegate];
	
	//    [self.bookView addTarget:delegate action:@selector(bookTouched:)
	//            forControlEvents:UIControlEventTouchUpInside];
}
-(void) onBlioMaxLayoutPageEquivalentCountChanged:(NSNotification*)note {
	NSLog(@"onBlioMaxLayoutPageEquivalentCountChanged entered");
	if (delegate == [note object]) [self resetProgressSlider];
}
- (void)onProcessingProgressNotification:(NSNotification*)note {
	if ([[note object] isKindOfClass:[BlioProcessingCompleteOperation class]] && [note userInfo] && self.book && [[note userInfo] objectForKey:@"bookID"] == [self.book objectID]) {
		BlioProcessingCompleteOperation * completeOp = [note object];
		//	NSLog(@"BlioLibraryListViewCell onProcessingProgressNotification entered. percentage: %u",completeOp.percentageComplete);
		progressView.progress = ((float)(completeOp.percentageComplete)/100.0f);
	}
}

- (void)onProcessingCompleteNotification:(NSNotification*)note {
	if ([[note object] isKindOfClass:[BlioProcessingCompleteOperation class]] && [note userInfo] && self.book && [[note userInfo] objectForKey:@"bookID"] == [self.book objectID]) {
		//	NSLog(@"BlioLibraryListViewCell onProcessingCompleteNotification entered");
		//	progressView.hidden = YES;
		//	[self resetAuthorText];
		//	self.accessoryView = nil;
		// bookView.alpha = 1;
		[(BlioLibraryViewController*)delegate calculateMaxLayoutPageEquivalentCount];
	}
}
- (void)onProcessingFailedNotification:(NSNotification*)note {
	if ([[note object] isKindOfClass:[BlioProcessingCompleteOperation class]] && [note userInfo] && self.book && [[note userInfo] objectForKey:@"bookID"] == [self.book objectID]) {
		NSLog(@"BlioLibraryListViewCell onProcessingFailedNotification entered");
	}
}

@end

@implementation BlioAccessibleGridElement

@synthesize target, visibleRect;

- (void)dealloc {
    self.target = nil;
    [super dealloc];
}

- (BOOL)isAccessibilityElement {
    CGRect accFrame = [self.target accessibilityFrame];
    CGPoint midPoint = CGPointMake(CGRectGetMidX(accFrame), CGRectGetMidY(accFrame));
    if (CGRectContainsPoint(self.visibleRect, midPoint))
        return YES;
    else
        return NO;
}

- (CGRect)accessibilityFrame {
    CGRect accFrame = [self.target accessibilityFrame];
	//    CGPoint midPoint = CGPointMake(CGRectGetMidX(accFrame), CGRectGetMidY(accFrame));
	//    if (CGRectContainsPoint(self.visibleRect, midPoint))
	return accFrame;
	//    else
	//        return CGRectMake(-1000, -1000, 0, 0);
}

@end

@implementation BlioProgressView

@synthesize value;

- (id)init {
    if ((self = [super init])) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)setValue:(CGFloat)newValue {
    value = newValue;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextClearRect(ctx, rect);
    
    CGRect progressRect = CGRectInset(rect, 3, 3);
    progressRect.size.width = progressRect.size.width * self.value;
    [[UIColor blackColor] set];
    CGContextFillRect(ctx, progressRect);
    
    [[UIColor colorWithRed:0.424f green:0.424f blue:0.443f alpha:0.25f] set];
    CGContextSetLineWidth(ctx, 2);
    CGContextStrokeRect(ctx, CGRectInset(rect, 1, 1));
    
}

@end

