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
#import "BlioProcessingStandardOperations.h"
#import "BlioStoreArchiveViewController.h"
#import "BlioAlertManager.h"
#import "BlioSocialManager.h"
#import "BlioAppSettingsConstants.h"
#import <libEucalyptus/THUIDeviceAdditions.h>

static NSString * const kBlioLastLibraryLayoutDefaultsKey = @"BlioLastLibraryLayout";

static NSString * const BlioMaxLayoutPageEquivalentCountChanged = @"BlioMaxLayoutPageEquivalentCountChanged";

@interface BlioAccessibleGridElement : UIAccessibilityElement {
    id target;
    CGRect visibleRect;
}

@property (nonatomic, assign) id target;
@property (nonatomic) CGRect visibleRect;

@end

@interface BlioAccessibleGridBookElement : BlioAccessibleGridElement {
	id delegate;
}
@property (nonatomic, assign) id delegate;

@end

@interface BlioLibraryViewController ()

@property (nonatomic, retain) BlioLogoView *logoView;
@property (nonatomic, retain) BlioLibraryBookView *selectedLibraryBookView;
@property (nonatomic, retain) BlioBookViewController *openBookViewController;
@property (nonatomic, retain) NSArray * tableData;

- (void)bookSelected:(BlioLibraryBookView *)bookView;
- (IBAction)changeLibraryLayout:(id)sender;
-(NSMutableArray *)partitionObjects:(NSArray *)array collationStringSelector:(SEL)selector;
-(NSInteger)tableView:(UITableView *)tableView realRowNumberForIndexPath:(NSIndexPath *)indexPath;

@end

@implementation BlioLibraryViewController

@synthesize currentBookView = _currentBookView;
@synthesize libraryLayout = _libraryLayout;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize processingDelegate = _processingDelegate;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize gridView = _gridView;
@synthesize tableView = _tableView;
@synthesize maxLayoutPageEquivalentCount;
@synthesize logoView;
@synthesize selectedLibraryBookView;
@synthesize openBookViewController;
@synthesize libraryVaultButton;
@synthesize showArchiveCell;
@synthesize tintColor;
@synthesize settingsPopoverController;
@synthesize tableData;

- (id)init {
	if ((self = [super init])) {
		_didEdit = NO;
		self.title = NSLocalizedString(@"Bookshelf",@"\"Bookshelf\" title for Library View Controller");
		showArchiveCell = NO;
		librarySortType = kBlioLibrarySortTypePersonalized;
	}
	return self;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.managedObjectContext = nil;
    self.currentBookView = nil;
	self.tableView = nil;
	self.gridView = nil;
    self.fetchedResultsController = nil;
    self.logoView = nil;
    self.selectedLibraryBookView = nil;
    self.openBookViewController = nil;
	self.libraryVaultButton = nil;
	self.tintColor = nil;
	self.settingsPopoverController = nil;
    self.tableData = nil;

    [super dealloc];
}

- (void)loadView {
    // Avoids CFURLCache crash in 6.1.
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
	self.view = [[[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
	NSString * libraryBackgroundFilename = @"librarybackground.png";
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		libraryBackgroundFilename = @"librarybackground-iPad.png";
	}

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
	
	CGRect mainScreenBounds = [[UIScreen mainScreen] bounds];
	
	UIView * headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, mainScreenBounds.size.width, 60)];
//	self.tableView.tableHeaderView = headerView;
	UIView * tableBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, -mainScreenBounds.size.height, mainScreenBounds.size.width, mainScreenBounds.size.height)];
	tableBackgroundView.backgroundColor = [UIColor colorWithRed:226.0f/255.0f green:231.0f/255.0f blue:237.0f/255.0f alpha:1];
	tableBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[headerView addSubview:tableBackgroundView];
	[tableBackgroundView release];
	self.libraryVaultButton = [UIButton buttonWithType: UIButtonTypeCustom];
	self.libraryVaultButton.frame = CGRectMake(0, -1, mainScreenBounds.size.width, 61);
	self.libraryVaultButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.libraryVaultButton.titleLabel.font = [UIFont boldSystemFontOfSize: 16];
	self.libraryVaultButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
	[self.libraryVaultButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[self.libraryVaultButton setTitle:NSLocalizedString(@"View Your Archive",@"Label for button in library that shows the Archive.") forState:UIControlStateNormal];
	[self.libraryVaultButton setTitleShadowColor:[UIColor colorWithWhite:1 alpha:0.75f] forState:UIControlStateNormal];
	[self.libraryVaultButton setBackgroundImage:[UIImage imageNamed:@"table-headerbar-background.png"] forState:UIControlStateNormal];
	[self.libraryVaultButton addTarget:self action:@selector(showStore:) forControlEvents:UIControlEventTouchUpInside];
	[headerView addSubview:self.libraryVaultButton];
	self.tableView.backgroundColor = [UIColor whiteColor];
	[headerView release];
	
	MRGridView *aGridView = [[MRGridView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.gridView = aGridView;
#ifdef TOSHIBA
    UIImage *logoImage = [UIImage appleLikeBeveledImage:[UIImage imageNamed:@"logo-white-Toshiba.png"]];
#else
    UIImage *logoImage = [UIImage appleLikeBeveledImage:[UIImage imageNamed:@"logo-white.png"]];
#endif
    BlioLogoView *aLogoView = [[BlioLogoView alloc] initWithFrame:CGRectMake(0, 0, logoImage.size.width, logoImage.size.height)];
    aLogoView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    [aLogoView setImage:logoImage];
    self.logoView = aLogoView;
    [aLogoView release];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.gridView setCellSize:CGSizeMake(kBlioLibraryGridBookWidthPad,kBlioLibraryGridBookHeightPad) withBorderSize:kBlioLibraryGridBookSpacingPad];
	}
	else {
		[self.gridView setCellSize:CGSizeMake(kBlioLibraryGridBookWidthPhone,kBlioLibraryGridBookHeightPhone) withBorderSize:kBlioLibraryGridBookSpacing];
	}

	[self.view addSubview:aGridView];
    [aGridView release];
	self.gridView.gridDelegate = self;
	self.gridView.gridDataSource = self;
}


- (void)viewDidLoad {
    // N.B. on iOS 4.0 it is important to set the toolbar tint before adding the UIBarButtonItems
#ifdef TOSHIBA
	self.tintColor = [UIColor colorWithRed:177.0f / 256.0f green:179.0f / 256.0f  blue:182.0f / 256.0f  alpha:1.0f];
#else
	self.tintColor = [UIColor colorWithRed:160.0f / 256.0f green:190.0f / 256.0f  blue:190.0f / 256.0f  alpha:1.0f];
#endif

	BlioLibraryLayout loadedLibraryLayout = [[NSUserDefaults standardUserDefaults] integerForKey:@"kBlioLastLibraryLayoutDefaultsKey"];
	
    [self.navigationController setToolbarHidden:NO ];
    if ([self.navigationController.toolbar respondsToSelector:@selector(setBarTintColor:)])
        [self.navigationController.toolbar setBarTintColor:tintColor];
    else
        [self.navigationController.toolbar setTintColor:tintColor];
    if ([self.navigationController.navigationBar respondsToSelector:@selector(setBarTintColor:)])
        [self.navigationController.navigationBar setBarTintColor:tintColor];
    else
        [self.navigationController.navigationBar setTintColor:tintColor];
    
    self.tableView.hidden = YES;
	
    self.navigationItem.titleView = self.logoView;
	
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    NSArray *segmentImages = [NSArray arrayWithObjects:
                              [UIImage appleLikeBeveledImage:[UIImage imageNamed:@"button-grid.png"]],
                              [UIImage appleLikeBeveledImage:[UIImage imageNamed:@"button-list.png"]],
                              nil];
    BlioAccessibilitySegmentedControl *segmentedControl = [[BlioAccessibilitySegmentedControl alloc] initWithItems:segmentImages];
    
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    segmentedControl.frame = CGRectMake(0,0, kBlioLibraryLayoutButtonWidth, segmentedControl.frame.size.height);
    [segmentedControl setContentOffset:CGSizeMake(0, 1) forSegmentAtIndex:0];
    [segmentedControl setContentOffset:CGSizeMake(0, 1) forSegmentAtIndex:1];

    [segmentedControl addTarget:self action:@selector(changeLibraryLayout:) forControlEvents:UIControlEventValueChanged];
    
    [segmentedControl setIsAccessibilityElement:NO];
	
    [[segmentedControl imageForSegmentAtIndex:0] setAccessibilityLabel:NSLocalizedString(@"Grid layout", @"Accessibility label for Library View grid layout button")];
    [[segmentedControl imageForSegmentAtIndex:0] setAccessibilityTraits:UIAccessibilityTraitButton | UIAccessibilityTraitStaticText];
	[[segmentedControl imageForSegmentAtIndex:1] setAccessibilityLabel:NSLocalizedString(@"List layout", @"Accessibility label for Library View list layout button")];
    [[segmentedControl imageForSegmentAtIndex:1] setAccessibilityTraits:UIAccessibilityTraitButton | UIAccessibilityTraitStaticText];
    
    [segmentedControl setSelectedSegmentIndex:loadedLibraryLayout];
    
    // This will not get automatically called by the setSelectedSegmentIndex:
    // above if it does not change the selected index.
    [self changeLibraryLayout:segmentedControl]; 
    
    UIBarButtonItem *libraryLayoutButton = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
    self.navigationItem.leftBarButtonItem = libraryLayoutButton;
    [libraryLayoutButton release];
    [segmentedControl release];
    
	if (libraryItems) [libraryItems release];
	libraryItems = [[NSMutableArray alloc] initWithCapacity:4];
	if (sortLibraryItems) [sortLibraryItems release];
	sortLibraryItems = [[NSMutableArray alloc] initWithCapacity:5];
    UIBarButtonItem *item;
	
	item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Get Books", @"Label for Library View Sort button")
                                            style:UIBarButtonItemStyleBordered
                                           target:self 
                                           action:@selector(showStore:)];
    [item setAccessibilityLabel:NSLocalizedString(@"Get Books", @"Accessibility label for Library View Get Books button")];
	[libraryItems addObject:item];
	[sortLibraryItems addObject:item];
	[item release];
	
	item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	[libraryItems addObject:item];
	[sortLibraryItems addObject:item];
	[item release];
	
	// sort segmented control start
	NSArray *sortSegmentImages = [NSArray arrayWithObjects:
								  [UIImage appleLikeBeveledImage:[UIImage imageNamed:@"icon-arbitrary.png"]],
								  [UIImage appleLikeBeveledImage:[UIImage imageNamed:@"icon-title.png"]],
								  [UIImage appleLikeBeveledImage:[UIImage imageNamed:@"icon-author.png"]],
								  nil];
    if (sortSegmentedControl) [sortSegmentedControl release];
	sortSegmentedControl = [[BlioAccessibilitySegmentedControl alloc] initWithItems:sortSegmentImages];
    sortSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    sortSegmentedControl.frame = CGRectMake(0,0, kBlioLibrarySortButtonWidth, sortSegmentedControl.frame.size.height);
    
    if([[UIDevice currentDevice] compareSystemVersion:@"7"] >= NSOrderedSame) {
        [sortSegmentedControl setContentOffset:CGSizeMake(0, -1) forSegmentAtIndex:0];
    }
    
    [sortSegmentedControl addTarget:self action:@selector(setSortOption:) forControlEvents:UIControlEventValueChanged];
    
    [sortSegmentedControl setIsAccessibilityElement:NO];
    [[sortSegmentedControl imageForSegmentAtIndex:0] setAccessibilityLabel:NSLocalizedString(@"View by Grid Order", @"Accessibility label for Library View view by grid order button")];
    [[sortSegmentedControl imageForSegmentAtIndex:0] setAccessibilityTraits:UIAccessibilityTraitButton | UIAccessibilityTraitStaticText];
	[[sortSegmentedControl imageForSegmentAtIndex:1] setAccessibilityLabel:NSLocalizedString(@"View by Title", @"Accessibility label for Library View view by title button")];
    [[sortSegmentedControl imageForSegmentAtIndex:1] setAccessibilityTraits:UIAccessibilityTraitButton | UIAccessibilityTraitStaticText];
	[[sortSegmentedControl imageForSegmentAtIndex:2] setAccessibilityLabel:NSLocalizedString(@"View by Author", @"Accessibility label for Library View view by author button")];
    [[sortSegmentedControl imageForSegmentAtIndex:2] setAccessibilityTraits:UIAccessibilityTraitButton | UIAccessibilityTraitStaticText];
	
	[sortSegmentedControl setSelectedSegmentIndex:self.librarySortType];
	
    item = [[UIBarButtonItem alloc] initWithCustomView:sortSegmentedControl];
	[sortLibraryItems addObject:item];
    [item release];	
	
	// sort segmented control end
    
	item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	[libraryItems addObject:item];
	[sortLibraryItems addObject:item];
	[item release];
	
	
    item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Settings", @"Label for Library View Settings button")
                                            style:UIBarButtonItemStyleBordered
                                           target:self 
                                           action:@selector(showSettings:)];
    item.width = 69.0f;
    [item setAccessibilityLabel:NSLocalizedString(@"Application Settings", @"Accessibility label for Library View Settings button")];
	
    [libraryItems addObject:item];
	[sortLibraryItems addObject:item];
    [item release];
    
    if (loadedLibraryLayout == kBlioLibraryLayoutGrid) [self setToolbarItems:[NSArray arrayWithArray:libraryItems] animated:YES];
    else [self setToolbarItems:[NSArray arrayWithArray:sortLibraryItems] animated:YES];
    
	maxLayoutPageEquivalentCount = 0;
	
	self.libraryLayout = loadedLibraryLayout;

    
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	
	[self calculateMaxLayoutPageEquivalentCount];
	
	[self fetchResults];
	
    if (![[self.fetchedResultsController fetchedObjects] count]) {
		
        NSLog(@"Creating Books");  
		
        NSArray * bundledBookArray = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"BundledBooks"];
        for (NSDictionary * bundledBookDictionary in bundledBookArray) {
            [self.processingDelegate enqueueBookWithTitle:[bundledBookDictionary objectForKey:@"title"] 
                                                  authors:[bundledBookDictionary objectForKey:@"authors"]
                                                coverPath:[bundledBookDictionary objectForKey:@"coverPath"]
                                                 ePubPath:[bundledBookDictionary objectForKey:@"ePubPath"]
                                                  pdfPath:[bundledBookDictionary objectForKey:@"pdfPath"]
                                                  xpsPath:[bundledBookDictionary objectForKey:@"xpsPath"]
                                             textFlowPath:[bundledBookDictionary objectForKey:@"textFlowPath"]
                                            audiobookPath:[bundledBookDictionary objectForKey:@"audiobookPath"]
                                                 sourceID:BlioBookSourceLocalBundle
                                         sourceSpecificID:[bundledBookDictionary objectForKey:@"sourceSpecificID"] // this should normally be BTKey number when downloaded from the Book Store
                                          placeholderOnly:[[bundledBookDictionary objectForKey:@"placeholderOnly"] boolValue]
             ];
        }
        /*
		[self.processingDelegate enqueueBookWithTitle:@"Peter Rabbit" 
											  authors:[NSArray arrayWithObjects:@"Potter, Beatrix", nil]
											coverPath:nil
											 ePubPath:nil
											  pdfPath:nil
											  xpsPath:@"XPS-Starters/Peter Rabbit.xps"
										 textFlowPath:nil
										audiobookPath:nil
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"PeterRabbit" // this should normally be BTKey number when downloaded from the Book Store
									  placeholderOnly:NO
		 ];
		
        [self.processingDelegate enqueueBookWithTitle:@"The Legend of Sleepy Hollow" 
                                              authors:[NSArray arrayWithObjects:@"Irving, Washington", nil]
											coverPath:nil
											 ePubPath:nil
											  pdfPath:nil
											  xpsPath:@"XPS-Starters/The Legend of Sleepy Hollow.xps"
										 textFlowPath:nil
										audiobookPath:nil
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"SleepyHollow" // this should normally be BTKey number when downloaded from the Book Store
									  placeholderOnly:NO
		 ];
         */
/*
		[self.processingDelegate enqueueBookWithTitle:@"Maskerade" 
                                              authors:[NSArray arrayWithObjects:@"Pratchett, Terry", nil]
											coverPath:nil
											 ePubPath:nil
											  pdfPath:nil
											  xpsPath:@"XPS-Starters/Maskerade.xps"
										 textFlowPath:nil
										audiobookPath:nil
											 sourceID:BlioBookSourceLocalBundleDRM
									 sourceSpecificID:@"Maskerade" // this should normally be BTKey number when downloaded from the Book Store
									  placeholderOnly:NO
		 ];
*/	
#ifdef DEMO_MODE		
		
        [self.processingDelegate enqueueBookWithTitle:@"Toy Story" 
                                              authors:[NSArray arrayWithObject:@"Disney"]
											coverPath:nil
											 ePubPath:nil
											  pdfPath:nil
											  xpsPath:@"XPS-Demo/Toy Story.xps"
										 textFlowPath:nil
										audiobookPath:nil
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"Toy Story"
									  placeholderOnly:NO
		 ];
		
        [self.processingDelegate enqueueBookWithTitle:@"Three Little Pigs" 
                                              authors:[NSArray arrayWithObjects:@"Blackstone, Stella", nil]
											coverPath:nil
											 ePubPath:nil
											  pdfPath:nil
											  xpsPath:@"XPS-Demo/Three Little Pigs.xps"
										 textFlowPath:nil
										audiobookPath:nil
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"Three Little Pigs" // this should normally be BTKey number when downloaded from the Book Store
									  placeholderOnly:NO
		 ];
			
		 [self.processingDelegate enqueueBookWithTitle:@"Frommer's Cancun" 
											authors:[NSArray arrayWithObjects:@"Baird, David", nil]
											coverPath:nil
											  ePubPath:nil
											   pdfPath:nil
											   xpsPath:@"XPS-Demo/Frommer's Cancun.xps"
										  textFlowPath:nil
										 audiobookPath:nil
											  sourceID:BlioBookSourceLocalBundle
									  sourceSpecificID:@"FrommersCancun" // this should normally be BTKey number when downloaded from the Book Store
									   placeholderOnly:NO
		 ];
		 
/*
        [self.processingDelegate enqueueBookWithTitle:@"There Was An Old Lady Who Swallowed a Shell" 
                                              authors:[NSArray arrayWithObjects:@"Colandro, Lucille", nil]
											coverPath:nil
											 ePubPath:nil
											  pdfPath:nil
											  xpsPath:@"XPS-Demo/OldLady.xps"
										 textFlowPath:nil
										audiobookPath:nil
											 sourceID:BlioBookSourceLocalBundle
									 sourceSpecificID:@"OldLady" // this should normally be BTKey number when downloaded from the Book Store
									  placeholderOnly:NO
		 ];
*/		
		
#endif // DEMO_MODE
		
        
    }
}

- (void)viewWillAppear:(BOOL)animated {
	
	[super viewWillAppear:animated];

	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
	[self.navigationController.toolbar setBarStyle:UIBarStyleDefault];
	[self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
	[self.navigationController.toolbar setTranslucent:NO];
	[self.navigationController.navigationBar setTranslucent:NO];

	if ([self.navigationController.navigationBar respondsToSelector:@selector(setBarTintColor:)])
        [self.navigationController.navigationBar setBarTintColor:tintColor];
    else
        [self.navigationController.navigationBar setTintColor:tintColor];
    if ([self.navigationController.toolbar respondsToSelector:@selector(setBarTintColor:)]) {
        [self.navigationController.toolbar setBarTintColor:tintColor];
        // Returning to the library from reading would otherwise set tint color (for bar items) to match reading toolbar's tint color.
        [self.navigationController.toolbar setTintColor:nil];
    }
    else
        [self.navigationController.toolbar setTintColor:tintColor];
 
    // Workaround to properly set the UIBarButtonItem's tint color in iOS 4
    // From http://stackoverflow.com/questions/3151549/uitoolbar-tint-on-ios4
    for (UIBarButtonItem * item in self.toolbarItems)
    {
        item.style = UIBarButtonItemStylePlain;
        item.style = UIBarButtonItemStyleBordered;
    }
    
}

-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	/* Not needed if starter books are bundled rather than downloaded through the bookvault.
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"AlertLibrary"] && [[NSUserDefaults standardUserDefaults] objectForKey:@"AlertWelcome"]) {
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"AlertLibrary"];
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Introducing Your Library",@"\"Introducing Your Library\" alert message title") 
									 message:NSLocalizedStringWithDefaultValue(@"INTRO_LIBRARY_ALERT",nil,[NSBundle mainBundle],@"The library is where you'll find all your downloaded books. Since you're just getting started, tap on the \"View Your Archive\" option to retrieve a few complimentary books!",@"Alert Text encouraging the end-user to go to the Archive and download complimentary books.")
									delegate:nil
						   cancelButtonTitle:@"OK"
						   otherButtonTitles:nil];		
	}
	 */
	
	// resume suspended operations related to paid books.
//	[self.processingDelegate resumeSuspendedProcessingForSourceID:BlioBookSourceOnlineStore];
	
	
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
    [sortSegmentedControl release];
    sortSegmentedControl = nil;
    
    self.tableView = nil;
    self.gridView = nil;
    self.libraryVaultButton = nil;
    
    self.libraryLayout = 0;
}

- (NSInteger)columnCount {
    CGRect bounds = [UIScreen mainScreen].bounds;
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        CGFloat width = bounds.size.width;
        bounds.size.width = bounds.size.height;
        bounds.size.height = width;
    }
    return round((bounds.size.width - kBlioLibraryGridBookSpacing*2) / (kBlioLibraryGridBookWidthPhone+kBlioLibraryGridBookSpacing));
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
//		if (sortType == kBlioLibrarySortTypePersonalized) {
//			self.navigationItem.rightBarButtonItem = self.editButtonItem;	
//		}
//		else {
//			if (self.editing) [self setEditing:NO animated:NO];
//			self.navigationItem.rightBarButtonItem = nil;
//		}
		[self fetchResults];
	}
}
-(void) needsAccessibilityLayoutChanged {
//	NSLog(@"%@", NSStringFromSelector(_cmd));
	UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
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
    if (librarySortType != kBlioLibrarySortTypePersonalized) {
        cell.book = [[self.tableData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    }
	else cell.book = [self.fetchedResultsController objectAtIndexPath:indexPath];
	cell.showsReorderControl = YES;	
}
-(void) configureGridCell:(BlioLibraryGridViewCell*)cell atIndex:(NSInteger)index {
	//	NSLog(@"configureGridCell atIndex: %i",index);
	NSIndexPath * indexPath = [NSIndexPath indexPathForRow:index inSection:0];
	cell.book = [self.fetchedResultsController objectAtIndexPath:indexPath];
	cell.accessibilityElements = nil;
}
-(NSIndexPath*)adjustedIndexPathForRealIndexPath:(NSIndexPath*)indexPath {
    BlioBook * book = [self.fetchedResultsController objectAtIndexPath:indexPath];
//    NSLog(@"book: %@",book);
//    NSLog(@"collationStringSelector: %@",NSStringFromSelector(collationStringSelector));
    NSInteger adjustedSectionIndex = [[UILocalizedIndexedCollation currentCollation] sectionForObject:book collationStringSelector:collationStringSelector];
//    NSLog(@"adjustedSectionIndex: %i",adjustedSectionIndex);
//    NSLog(@"[self.tableData objectAtIndex:adjustedSectionIndex]: %@",[self.tableData objectAtIndex:adjustedSectionIndex]);
//    NSLog(@"[[self.tableData objectAtIndex:adjustedSectionIndex] indexOfObject:book]: %u",[[self.tableData objectAtIndex:adjustedSectionIndex] indexOfObject:book]);
//    NSLog(@"self.tableData: %@",self.tableData);
    if ([[self.tableData objectAtIndex:adjustedSectionIndex] indexOfObject:book] == NSNotFound) return nil;
    return [NSIndexPath indexPathForRow:[[self.tableData objectAtIndex:adjustedSectionIndex] indexOfObject:book] inSection:adjustedSectionIndex];
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
		if (savePreference) [self.managedObjectContext refreshObject:aBook mergeChanges:YES];
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
	if (self.libraryLayout == kBlioLibraryLayoutGrid) {
		sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"libraryPosition" ascending:NO] autorelease];
	}
	else {
		switch (librarySortType) {
			case kBlioLibrarySortTypeTitle:
				sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"titleSortable" ascending:YES] autorelease];
				break;
			case kBlioLibrarySortTypeAuthor:
				sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"author" ascending:YES] autorelease];
				break;
			default: {
				sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"libraryPosition" ascending:NO] autorelease];
			}
		}
	}
	NSArray *sorters = [NSArray arrayWithObject:sortDescriptor]; 
    
    [request setFetchBatchSize:30]; // Never fetch more than 30 books at one time
    [request setEntity:[NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:moc]];
    [request setSortDescriptors:sorters];
 	[request setPredicate:[NSPredicate predicateWithFormat:@"processingState >= %@ && transactionType != %@", [NSNumber numberWithInt:kBlioBookProcessingStateIncomplete],[NSNumber numberWithInt:BlioTransactionTypePreorder]]];
    
	self.fetchedResultsController = [[[NSFetchedResultsController alloc]
									  initWithFetchRequest:request
									  managedObjectContext:moc
									  sectionNameKeyPath:nil
									  cacheName:nil] autorelease];
    [request release];
    
    [self.fetchedResultsController setDelegate:self];
    NSError *error = nil; 
    [self.fetchedResultsController performFetch:&error];
	
    if (error) 
        NSLog(@"Error loading from persistent store: %@, %@", error, [error userInfo]);
	else {
        collationStringSelector = @selector(titleSortable);
        if (librarySortType == kBlioLibrarySortTypeAuthor) collationStringSelector = @selector(author);
        self.tableData = [self partitionObjects:[self.fetchedResultsController fetchedObjects] collationStringSelector:collationStringSelector];
        /*
         // debugging NSLogs for sections and member books
        for (int s = 0; s < [self.tableData count]; s++) {
            NSLog(@"sectionName: %@",[[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:s]);
            NSArray * sectionArray = [self.tableData objectAtIndex:s];
            for (BlioBook * book in sectionArray) {
                NSLog(@"book sortableTitle: %@",[book titleSortable]);
                
            }
        }
         */
        [self.tableView reloadData];
		[self.gridView reloadData];	
	}
}
-(NSMutableArray *)partitionObjects:(NSArray *)array collationStringSelector:(SEL)selector {
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];
    
    NSInteger sectionCount = [[collation sectionTitles] count];
    NSMutableArray *unsortedSections = [NSMutableArray arrayWithCapacity:sectionCount];
    
    //create an array to hold the data for each section
    for(int i = 0; i < sectionCount; i++)
    {
        [unsortedSections addObject:[NSMutableArray array]];
    }
    
    //put each object into a section
    for (id object in array)
    {
        NSInteger index = [collation sectionForObject:object collationStringSelector:selector];
        [[unsortedSections objectAtIndex:index] addObject:object];
    }
    
    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:sectionCount];
    
    //sort each section
    for (NSMutableArray *section in unsortedSections)
    {
        [sections addObject:[[[collation sortedArrayFromArray:section collationStringSelector:selector] mutableCopy] autorelease]];
    }
    
    return sections;
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
        self.logoView.numberOfBooksInLibrary = bookCount;
    }
	return bookCount;
}

-(NSString*)contentDescriptionForCellAtIndex:(NSInteger)index {
	return [[self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]] title];
}
-(BOOL) gridView:(MRGridView*)gridView canMoveCellAtIndex: (NSInteger)index {
//	if (librarySortType != kBlioLibrarySortTypePersonalized) return NO; // grid view is only personalized order, so we can always move cells around.
	return YES;
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
//		if ([[cell.book valueForKey:@"sourceID"] intValue] == BlioBookSourceOnlineStore) {
//			// cancel all other operations related to paid books.
//			[self.processingDelegate suspendProcessingForSourceID:BlioBookSourceOnlineStore];
//		}
		cell.statusBadge.hidden = YES;
		cell.previewBadge.alpha = 0;
		cell.bookTypeBadge.alpha = 0;
		selectedGridIndex = index;
		if ([cell.bookView.book isEncrypted]) {
            if ([cell.bookView.book checkBindToLicense])
				[self bookSelected:cell.bookView];
            else {
                cell.statusBadge.hidden = NO;
                cell.previewBadge.alpha = 1;
                cell.bookTypeBadge.alpha = 1;
            }
		}
		else {
			[self bookSelected:cell.bookView];
		}
	}
}
- (void)gridView:(MRGridView *)gridView didTapAndHoldCellAtIndex:(NSInteger)index{
#ifndef TOSHIBA
    NSLog(@"%@",NSStringFromSelector(_cmd));
    sharedGridIndex = index;
    [self showSocialOptions];
#endif
}
-(void)gridView:(MRGridView *)gridView confirmationForDeletionAtIndex:(NSInteger)index {
	_keyValueOfCellToBeDeleted = index;
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Confirmation Request",@"\"Confirmation Request\" alert message title")
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
	if([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Settings",@"\"Settings\" alert button")]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=TWITTER"]];
    }
	else if([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Delete",@"\"Delete\" alert button")])
	{
		
		[self gridView:self.gridView commitEditingStyle:MRGridViewCellEditingStyleDelete forIndex:_keyValueOfCellToBeDeleted];
	}
	[alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
}

-(void)delayedChangeTableCellBackground:(NSIndexPath*)indexPath {
	[UIView beginAnimations:@"changeDraggedRowBackgroundColor" context:nil];
	[self tableView:self.tableView willDisplayCell:[self.tableView cellForRowAtIndexPath:indexPath] forRowAtIndexPath:indexPath];
	[UIView commitAnimations];
}

#pragma mark -
#pragma mark UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return kBlioLibraryListRowHeight;
}

-(NSInteger)tableView:(UITableView *)tableView realRowNumberForIndexPath:(NSIndexPath *)indexPath
{
	NSInteger retInt = 0;
	if (!indexPath.section)
	{
		return indexPath.row;
	}
	for (int i=0; i < indexPath.section;i++)
	{
		retInt += [tableView numberOfRowsInSection:i];
	}
    
	return retInt + indexPath.row;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	UIColor * lightColor = [UIColor whiteColor];
    UIColor * darkColor = [UIColor colorWithRed:(226.0/255) green:(225.0/255) blue:(231.0/255) alpha:1];
    NSInteger rowNumber = [indexPath row];
    if (librarySortType != kBlioLibrarySortTypePersonalized) rowNumber = [self tableView:tableView realRowNumberForIndexPath:indexPath];
    cell.backgroundColor = (rowNumber%2)?lightColor:darkColor;
}

- (void)openBook:(BlioBook *)selectedBook  {
    //if ([[selectedBook valueForKey:@"sourceID"] intValue] == BlioBookSourceOnlineStore) {
    //	// cancel all other operations related to paid books.
    //	[self.processingDelegate suspendProcessingForSourceID:BlioBookSourceOnlineStore];
    //}
    BlioBookViewController *aBookViewController = [[BlioBookViewController alloc] initWithBook:selectedBook delegate:nil];
    if (nil != aBookViewController) {
        [aBookViewController setManagedObjectContext:self.managedObjectContext];
        aBookViewController.toolbarsVisibleAfterAppearance = YES;
        [self.navigationController pushViewController:aBookViewController animated:YES];
        [aBookViewController release];
    }
}
                  
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (showArchiveCell) {
        NSArray *sections = [self.fetchedResultsController sections];
        NSUInteger bookCount = 0;        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:[indexPath section]];
        bookCount = [sectionInfo numberOfObjects];
		if ([indexPath row] == bookCount) {
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
			[self showStore:[tableView cellForRowAtIndexPath:indexPath]];
			return;
		}
	}

    BlioBook *selectedBook = nil;
    if (librarySortType != kBlioLibrarySortTypePersonalized) {
        selectedBook = [[self.tableData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    }
    else selectedBook = [self.fetchedResultsController objectAtIndexPath:indexPath];
	if ([[selectedBook valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateComplete) {
        if ([selectedBook isEncrypted]) {
			if ([selectedBook checkBindToLicense])
				[self openBook:selectedBook];
		}
		else {
			[self openBook:selectedBook];
		}
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	}    
	else [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
	
}

#pragma mark -
#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (librarySortType != kBlioLibrarySortTypePersonalized) {
        return [[[UILocalizedIndexedCollation currentCollation] sectionTitles] count];
    }
    NSUInteger count = [[self.fetchedResultsController sections] count];
    if (count == 0) {
        count = 1;
    }
    return count;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (librarySortType != kBlioLibrarySortTypePersonalized) {
        return [[self.tableData objectAtIndex:section] count];
    }
    NSArray *sections = [self.fetchedResultsController sections];
    NSUInteger bookCount = 0;
    if ([sections count]) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
        bookCount = [sectionInfo numberOfObjects];
        self.logoView.numberOfBooksInLibrary = bookCount;
    }
	if (showArchiveCell) return bookCount + 1;
	return bookCount;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {    
    if (librarySortType != kBlioLibrarySortTypePersonalized) {
        return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
    }
    return nil;
}
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index];
}
// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	static NSString *GenericTableCellIdentifier = @"GenericTableCellIdentifier";

	static NSString *ListCellIdentifier = @"BlioLibraryListCellIdentifier";
	
	NSArray *sections = [self.fetchedResultsController sections];
    NSUInteger bookCount = 0;
    NSUInteger sectionCount = [sections count];
    if (librarySortType != kBlioLibrarySortTypePersonalized) {
        sectionCount = [self.tableData count];
    }
    if (indexPath.section == (sectionCount - 1)) {
        if (librarySortType != kBlioLibrarySortTypePersonalized) {
            bookCount = [[self.tableData objectAtIndex:indexPath.section] count];
        }
        else {
            id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:[indexPath section]];
            bookCount = [sectionInfo numberOfObjects];
        }
		if ([indexPath row] == bookCount && showArchiveCell) {
			UITableViewCell * genericCell = nil;
			genericCell = [tableView dequeueReusableCellWithIdentifier:GenericTableCellIdentifier];
			if (genericCell == nil) {
				genericCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:GenericTableCellIdentifier] autorelease];
				genericCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				genericCell.selectionStyle = UITableViewCellSelectionStyleGray;
				genericCell.textLabel.text = NSLocalizedString(@"View Your Archive",@"Label for button in library that shows the Archive.");
			}
			return genericCell;
		}
	}
	
	BlioLibraryListCell * cell = nil;
	
	cell = (BlioLibraryListCell *)[tableView dequeueReusableCellWithIdentifier:ListCellIdentifier];
	if (cell == nil) {
		cell = [[[BlioLibraryListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ListCellIdentifier] autorelease];
		cell.delegate = self;
	} 
	
	[self configureTableCell:cell atIndexPath:indexPath];
	return cell;
	
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {

    if (showArchiveCell) {
        NSArray *sections = [self.fetchedResultsController sections];
        NSUInteger bookCount = 0;
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:[indexPath section]];
        bookCount = [sectionInfo numberOfObjects];
		if ([indexPath row] >= bookCount) return NO;
    }
	return YES;
}
- (BOOL)tableView:(UITableView *)tableview canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (librarySortType != kBlioLibrarySortTypePersonalized) return NO;
	
    NSArray *sections = [self.fetchedResultsController sections];
    NSUInteger bookCount = 0;
    if ([sections count]) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:[indexPath section]];
        bookCount = [sectionInfo numberOfObjects];
		if ([indexPath row] >= bookCount) return NO;
    }
	return YES;	
}
- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
	NSArray *sections = [self.fetchedResultsController sections];
    NSUInteger bookCount = 0;
    if ([sections count]) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:[proposedDestinationIndexPath section]];
        bookCount = [sectionInfo numberOfObjects];
		if ([proposedDestinationIndexPath row] >= bookCount) return [NSIndexPath indexPathForRow:bookCount-1 inSection:[proposedDestinationIndexPath section]];
    }
	return proposedDestinationIndexPath;		
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
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	 if (editingStyle == UITableViewCellEditingStyleDelete) {
		 // Delete the row from the data source.
		 BlioBook * bookToBeDeleted = nil;
         if (librarySortType != kBlioLibrarySortTypePersonalized) {
             bookToBeDeleted = [[self.tableData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
             [[self.tableData objectAtIndex:indexPath.section] removeObjectAtIndex:indexPath.row];
             // if we're not using core data fetched results controller as the direct data source, then manipulation of table appearance should happen at this point instead of controller:didChangeObject:
             
             NSArray * indexPaths = [self.tableView indexPathsForVisibleRows];
             [UIView beginAnimations:@"changeRowBackgroundColor" context:nil];
             NSLog(@"selected IndexPath section: %i row: %i",indexPath.section,indexPath.row);
             for (NSIndexPath * visiblePath in indexPaths) {
                 NSLog(@"visiblePath section: %i row: %i",visiblePath.section,visiblePath.row);
                 if ((visiblePath.section == indexPath.section && visiblePath.row > indexPath.row) || visiblePath.section > indexPath.section) {
                     [self tableView:self.tableView willDisplayCell:[self.tableView cellForRowAtIndexPath:visiblePath] forRowAtIndexPath:[NSIndexPath indexPathForRow:visiblePath.row-1 inSection:visiblePath.section]];
                 }
             }				
             [UIView commitAnimations];

             [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
             
             
         }
         else bookToBeDeleted = [[self.fetchedResultsController fetchedObjects] objectAtIndex:indexPath.row];		 
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
//    NSLog(@"%@ type: %i",NSStringFromSelector(_cmd),type);
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
                    if (librarySortType != kBlioLibrarySortTypePersonalized) self.tableData = [self partitionObjects:[self.fetchedResultsController fetchedObjects] collationStringSelector:collationStringSelector];
					[self.tableView reloadData];
                    // TODO: optimize performance so that only tableData is rebuilt instead of doing a new fetch in cases of (librarySortType != kBlioLibrarySortTypePersonalized)
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
                    if (librarySortType == kBlioLibrarySortTypePersonalized) {
                        NSArray * indexPaths = [self.tableView indexPathsForVisibleRows];
                        NSIndexPath * adjustedIndexPath = indexPath;
                        [UIView beginAnimations:@"changeRowBackgroundColor" context:nil];
                        for (NSIndexPath * visiblePath in indexPaths) {
                            if (visiblePath.row > adjustedIndexPath.row || visiblePath.section > adjustedIndexPath.section) {
                                [self tableView:self.tableView willDisplayCell:[self.tableView cellForRowAtIndexPath:visiblePath] forRowAtIndexPath:[NSIndexPath indexPathForRow:visiblePath.row-1 inSection:visiblePath.section]];
                            }
                        }				
                        [UIView commitAnimations];
                        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:adjustedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                    }
				}
					break;
                default:
                    break;
			}
			break;
			
		case NSFetchedResultsChangeUpdate:
				switch (self.libraryLayout) {
					case kBlioLibraryLayoutGrid:
						[self configureGridCell:(BlioLibraryGridViewCell*)[self.gridView cellAtGridIndex:indexPath.row]
										atIndex:indexPath.row];
						break;
					case kBlioLibraryLayoutList:
                        NSLog(@"indexPath: %@",indexPath);
                        NSIndexPath * adjustedIndexPath = indexPath;
                        if (librarySortType != kBlioLibrarySortTypePersonalized) {
                            adjustedIndexPath = [self adjustedIndexPathForRealIndexPath:indexPath];
                            NSLog(@"adjustedIndexPath: %@",adjustedIndexPath);
                        }
						if (adjustedIndexPath) [self configureTableCell:(BlioLibraryListCell*)[self.tableView cellForRowAtIndexPath:adjustedIndexPath]
									 atIndexPath:adjustedIndexPath];
						break;
                    default:
                        break;
				}
				
			break;
	}
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
//	[self performSelector:@selector(needsAccessibilityLayoutChanged) withObject:nil afterDelay:0.2f];
	[self needsAccessibilityLayoutChanged];
    
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
    // Avoids __CFURLCache crash in 6.1.
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    BlioStoreTabViewController *aStoreController = [[BlioStoreTabViewController alloc] initWithProcessingDelegate:self.processingDelegate managedObjectContext:self.managedObjectContext];
	if (sender == self.libraryVaultButton || [sender isKindOfClass:[UITableViewCell class]]) {
		for (id vc in aStoreController.viewControllers) {
			if ([vc isKindOfClass:[UINavigationController class]]) {
				UINavigationController * nc = (UINavigationController*)vc;
				if ([nc.viewControllers count] > 0 && [[nc.viewControllers objectAtIndex:0] isKindOfClass:[BlioStoreArchiveViewController class]]) {
					[aStoreController setSelectedViewController:nc];
					break;
				}
			}
		}
	}
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
//	[actionSheet showInView:self.view];
	[actionSheet showFromToolbar:self.navigationController.toolbar];
	[actionSheet release];	
}

- (void)showSettings:(id)sender {    
    BlioAppSettingsController *appSettingsController = [[BlioAppSettingsController alloc] init];
	[appSettingsController.tableView reloadData];
	UINavigationController *settingsController = [[UINavigationController alloc] initWithRootViewController:appSettingsController];

	[appSettingsController release];
    

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (self.settingsPopoverController && self.settingsPopoverController.popoverVisible == YES) {
			[self.settingsPopoverController dismissPopoverAnimated:YES];
			self.settingsPopoverController = nil;
		}
		else {
			self.settingsPopoverController = [[[NSClassFromString(@"UIPopoverController") alloc] initWithContentViewController:settingsController] autorelease];
			self.settingsPopoverController.popoverContentSize = CGSizeMake(320, 440);
			self.settingsPopoverController.delegate = self;
			[self.settingsPopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		}
	}
	else {
		[self presentModalViewController:settingsController animated:YES];
	}		
    settingsController.delegate = self;
    [settingsController release];    
}
#pragma mark - Social Options

- (void)showSocialOptions {    
	// show sheet interface
    UIActionSheet *actionSheet = nil;
	NSString * sheetTitle = NSLocalizedString(@"Share On:",@"\"Share On:\" action sheet title");
	NSString * social0 = NSLocalizedString(@"Facebook",@"\"Facebook\" library social option");\
    
    if([[UIDevice currentDevice] compareSystemVersion:@"5.0"] >= NSOrderedSame) {
        NSString * social1 = NSLocalizedString(@"Twitter",@"\"Twitter\" library social option");
        actionSheet = [[UIActionSheet alloc] initWithTitle:sheetTitle
                                                                 delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",@"\"Cancel\" sheet button") 
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:social0, social1, nil];
    }
    else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:sheetTitle
                                                  delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",@"\"Cancel\" sheet button") 
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:social0, nil];
    }
	actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    //	[actionSheet showInView:self.view];
	[actionSheet showFromToolbar:self.navigationController.toolbar];
	[actionSheet release];	
}


#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
//	NSLog(@"%@", NSStringFromSelector(_cmd));
	CGSize viewSize = viewController.contentSizeForViewInPopover;
	if ([viewController.view isKindOfClass:[UIScrollView class]]) {
		[((UITableViewController*)viewController).tableView reloadData];
//		NSLog(@"[(UIScrollView*)viewController.view contentSize].height: %f",[(UIScrollView*)viewController.view contentSize].height);
		viewSize.height = [(UIScrollView*)viewController.view contentSize].height;
		if (viewSize.height > 600) viewSize.height = 600;
	}
    // small hack - in order to get consistent behavior between iOS4 & 5 popover sizes for the initial display of the BlioAppSettingsController
    if ([viewController isKindOfClass:[BlioAppSettingsController class]] && !hasShownAppSettings) {
        hasShownAppSettings = YES;
        if (viewSize.height < 440) viewSize.height = 440;
    }
//    NSLog(@"setting popover to size: %f, %f",viewSize.width,viewSize.height);
	self.settingsPopoverController.popoverContentSize = viewSize;
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	// N.B. - from Apple's documentation: The popover controller does not call this method in response to programmatic calls to the dismissPopoverAnimated: method.
	self.settingsPopoverController = nil;
    hasShownAppSettings = NO;
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	//	NSLog(@"buttonIndex: %i",buttonIndex);
	if (buttonIndex == actionSheet.cancelButtonIndex) {
		NSLog(@"Social Sheet cancelled");
		return;
	}
	
    BlioLibraryGridViewCell * cell = (BlioLibraryGridViewCell*)[self.gridView cellAtGridIndex:sharedGridIndex];
    BlioBook * bookToBeShared = cell.bookView.book;
    
	if (buttonIndex == BlioSocialTypeFacebook) {
        [[BlioSocialManager sharedSocialManager] shareBook:bookToBeShared socialType:BlioSocialTypeFacebook];
    }
	else if (buttonIndex == BlioSocialTypeTwitter) {
        if ([BlioSocialManager canSendTweet]) {
            [[BlioSocialManager sharedSocialManager] shareBook:bookToBeShared socialType:BlioSocialTypeTwitter];
        }
        else {
            if([[UIDevice currentDevice] compareSystemVersion:@"5.1"] >= NSOrderedSame) {
                [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Twitter Not Setup",@"\"Twitter Not Setup\" alert message title")
                                             message:NSLocalizedStringWithDefaultValue(@"TWITTER_NOT_SETUP",nil,[NSBundle mainBundle],@"Twitter account settings were not found. Please enter your username and password in your Twitter Settings.",@"Alert message shown when no twitter account settings are found.")
                                            delegate:self 
                                   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
                                   otherButtonTitles:nil];
            }
            else {
                [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Twitter Not Setup",@"\"Twitter Not Setup\" alert message title")
                                             message:NSLocalizedStringWithDefaultValue(@"TWITTER_NOT_SETUP",nil,[NSBundle mainBundle],@"Twitter account settings were not found. Would you like to enter your username and password now?",@"Alert message shown when no twitter account settings are found, and the option to go directly to the Settings App is presented.")
                                            delegate:self 
                                   cancelButtonTitle:NSLocalizedString(@"Not Now",@"\"Not Now\" label for button used to cancel/dismiss alertview")
                                   otherButtonTitles:NSLocalizedString(@"Settings","Settings"), nil];
            }
        }
    }
    
}

#pragma mark -
#pragma mark Library Actions

-(void) reprocessCoverThumbnailsForBook:(BlioBook*)aBook {
	[self.processingDelegate reprocessCoverThumbnailsForBook:aBook];
}
-(void) pauseProcessingForBook:(BlioBook*)book {
		[self.processingDelegate pauseProcessingForBook:book];
}
-(void) enqueueBook:(BlioBook*)book {
//	if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
//		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Attention",@"\"Attention\" alert message title") 
//									 message:NSLocalizedStringWithDefaultValue(@"INTERNET_REQUIRED_TO_DOWNLOAD_BOOK",nil,[NSBundle mainBundle],@"An Internet connection was not found; Internet access is required to download this book.",@"Alert message when the user tries to download a book without an Internet connection.")
//									delegate:nil 
//						   cancelButtonTitle:@"OK"
//						   otherButtonTitles:nil];
//		return;
//	}
	[self.processingDelegate enqueueBook:book];
}

- (void)setSortOption:(id)sender {
	self.librarySortType = (BlioLibrarySortType)[sender selectedSegmentIndex];
}

- (IBAction)changeLibraryLayout:(id)sender {
    
    BlioLibraryLayout newLayout = (BlioLibraryLayout)[sender selectedSegmentIndex];
    
    if (self.libraryLayout != newLayout) {
        self.libraryLayout = newLayout;
        [[NSUserDefaults standardUserDefaults] setInteger:self.libraryLayout forKey:@"kBlioLastLibraryLayoutDefaultsKey"];
		
        switch (newLayout) {
            case kBlioLibraryLayoutGrid:
				[self.view bringSubviewToFront:self.gridView];
				if (self.librarySortType != kBlioLibrarySortTypePersonalized) [self fetchResults];
				else [self.gridView reloadData];
				self.gridView.hidden = NO;
				self.tableView.hidden = YES;
				[self setToolbarItems:[NSArray arrayWithArray:libraryItems] animated:YES];
                break;
            case kBlioLibraryLayoutList:
				[self.view bringSubviewToFront:self.tableView];
				if (self.librarySortType != kBlioLibrarySortTypePersonalized) [self fetchResults];
				else [self.tableView reloadData];
				self.gridView.hidden = YES;
				self.tableView.hidden = NO;
				[self setToolbarItems:[NSArray arrayWithArray:sortLibraryItems] animated:YES];
				[sortSegmentedControl setSelectedSegmentIndex:self.librarySortType];
                break;
            default:
                NSLog(@"Unexpected library layout %ld", (long)newLayout);
        }
		UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    }
    
}

- (void)bookSelected:(BlioLibraryBookView *)libraryBookView {
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    self.selectedLibraryBookView = libraryBookView;
    [libraryBookView setHidden:YES];
        
    BlioBookViewController *aBookViewController = [[BlioBookViewController alloc] initWithBook:[libraryBookView book] delegate:self];
    
    if (nil != aBookViewController) {
        [aBookViewController setManagedObjectContext:self.managedObjectContext];
        [aBookViewController setReturnToNavigationBarHidden:NO];
        [aBookViewController setReturnToStatusBarStyle:UIStatusBarStyleDefault];
    } else {
        [libraryBookView displayError];
        self.selectedLibraryBookView = nil;
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        return;
    }
    
    [aBookViewController release];
    
    return;    
}

- (UIView *)coverViewViewForOpening {
    return [self.selectedLibraryBookView coverView];
}

- (CGRect)coverViewRectForOpening {
    CGRect frame = [self.selectedLibraryBookView.imageView frame];
//    CGFloat xInset = frame.size.width * kBlioLibraryShadowXInset;
//    CGFloat yInset = frame.size.height * kBlioLibraryShadowYInset;
//    CGRect insetFrame = CGRectInset(frame, xInset, yInset);
    return [self.selectedLibraryBookView convertRect:frame toView:self.navigationController.view];
}

- (UIViewController *)coverViewViewControllerForOpening {
    return self;
}

- (void)coverViewDidAnimatePop {
    [self.selectedLibraryBookView setHidden:NO];
	BlioLibraryGridViewCell * cell = (BlioLibraryGridViewCell*)[self.gridView cellAtGridIndex:selectedGridIndex];
	if (cell) {
		cell.statusBadge.hidden = NO;
		if ([[self.selectedLibraryBookView.book valueForKey:@"productType"] intValue] == BlioProductTypePreview) {
			cell.previewBadge.alpha = 1;
		}
		else cell.previewBadge.alpha = 0;
		if ([[self.selectedLibraryBookView.book valueForKey:@"transactionType"] intValue] == BlioTransactionTypeLend) {
			cell.bookTypeBadge.alpha = 1;
		}
		else cell.bookTypeBadge.alpha = 0;
	}
}

- (void)coverViewDidAnimateFade {
    self.selectedLibraryBookView = nil;
    self.openBookViewController = nil;
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

@end

@implementation BlioLibraryBookView

@synthesize imageView, textureView, errorView, book, delegate,xInset,yInset;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = NO;
        self.userInteractionEnabled = NO;
        
        UIImageView *aTextureView = [[UIImageView alloc] initWithFrame:CGRectInset(self.bounds,-9,-12)];
//        aTextureView.contentMode = UIViewContentModeScaleToFill;
//        aTextureView.image = [[UIImage imageNamed:@"book-overlay.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:11];
        aTextureView.image = [UIImage imageNamed:@"book-overlay.png"];
        aTextureView.backgroundColor = [UIColor clearColor];
        aTextureView.userInteractionEnabled = NO;
        [self addSubview:aTextureView];
        self.textureView = aTextureView;
        [aTextureView release];
        
//        xInset = self.bounds.size.width * kBlioLibraryShadowXInset;
//        yInset = self.bounds.size.height * kBlioLibraryShadowYInset;
//        CGRect insetFrame = CGRectInset(self.bounds, xInset, yInset);
//        UIImageView *aImageView = [[UIImageView alloc] initWithFrame:insetFrame];
        UIImageView *aImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        aImageView.contentMode = UIViewContentModeScaleAspectFit;
        aImageView.backgroundColor = [UIColor clearColor];
        aImageView.userInteractionEnabled = NO;
        aImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [self insertSubview:aImageView belowSubview:self.textureView];
        self.imageView = aImageView;
        [aImageView release];
    }
    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    self.imageView = nil;
    self.textureView = nil;
    self.errorView = nil;
    self.book = nil;
    [super dealloc];
}

- (void)setFrame:(CGRect)newFrame {
    [super setFrame:newFrame];
    [self.textureView setFrame:CGRectInset(newFrame, -9, -12)];
//    xInset = self.textureView.bounds.size.width * kBlioLibraryShadowXInset;
//    yInset = self.textureView.bounds.size.height * kBlioLibraryShadowYInset;
//    CGRect insetFrame = CGRectInset(self.textureView.bounds, xInset, yInset);
    [self.imageView setFrame:newFrame];
    if (errorView) {
        [errorView setFrame:newFrame];
    }
}

- (UIImage *)image {
    return [self.imageView image];
}

- (void)setBook:(BlioBook *)newBook {
    [self setBook:newBook forLayout:kBlioLibraryLayoutGrid];
}

// TODO setSong which is like this except calls hasAppropriateCoverThumbForGrid/List
// and coverThumbForGrid/List with image data not gotten from manifest; use
// BlioSong:pixelSpecificCoverDataForKey
- (void)setBook:(BlioBook *)newBook forLayout:(BlioLibraryLayout)layout {
    [newBook retain];
    [book release];
    book = newBook;
    
    UIImage *newImage;
    BOOL hasAppropriateCoverThumb = NO;
	
    if (layout == kBlioLibraryLayoutList) {
//		NSLog(@"Searching for appropriate cover for list...");
        NSString * pixelSpecificKey = [newBook getPixelSpecificKeyForList];
		hasAppropriateCoverThumb = [newBook hasAppropriateCoverThumbForList:[newBook manifestDataForKey:pixelSpecificKey]];
        newImage = [newBook coverThumbForList:[newBook manifestDataForKey:pixelSpecificKey]];
    } else {
//		NSLog(@"Searching for appropriate cover for grid...");
        NSString * pixelSpecificKey = [newBook getPixelSpecificKeyForGrid];
        hasAppropriateCoverThumb = [newBook hasAppropriateCoverThumbForGrid:[newBook manifestDataForKey:pixelSpecificKey]];
        newImage = [newBook coverThumbForGrid:[newBook manifestDataForKey:pixelSpecificKey]];
    }    
    [self.imageView setImage:newImage];
    
    if (layout == kBlioLibraryLayoutList) {
        self.imageView.frame = CGRectMake(round((self.bounds.size.width - newImage.size.width)/2), round((self.bounds.size.height - newImage.size.height)/2), newImage.size.width, newImage.size.height);        
    } else {
        self.imageView.frame = CGRectMake(round((self.bounds.size.width - newImage.size.width)/2), self.bounds.size.height - newImage.size.height, newImage.size.width, newImage.size.height);
    }
//    CGFloat maxToCoverWidthRatio = self.bounds.size.width/newImage.size.width;
//    CGFloat maxToCoverHeightRatio = self.bounds.size.height/newImage.size.height;

    self.textureView.frame = CGRectInset(self.imageView.frame, -9.0f * (self.imageView.bounds.size.width/130.0f), -12.0f * (self.imageView.bounds.size.height/183.0f));
    self.textureView.center = self.imageView.center;
	if (newBook.hasCoverImage && !hasAppropriateCoverThumb && ([[newBook valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateComplete || [[newBook valueForKey:@"processingState"] intValue] == kBlioBookProcessingStatePlaceholderOnly)) {
		NSLog(@"Does not have appropriate cover thumb for book: %@, reprocessing cover thumbnails...",[newBook title]);
		[self.delegate reprocessCoverThumbnailsForBook:newBook];
	}
}

- (BlioCoverView *)coverView {
    UIImage *coverImage = [[self book] coverImage:[[self book] manifestDataForKey:BlioManifestCoverKey]];

    BlioCoverView *coverView = [[BlioCoverView alloc] initWithFrame:[self convertRect:self.imageView.frame fromView:self.imageView] coverImage:coverImage];
    return [coverView autorelease];
}

- (void)displayError {
    [self.errorView setFrame:self.imageView.frame];
    CABasicAnimation *errorAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [errorAnim setDuration:0.25f];
    [errorAnim setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [errorAnim setRepeatCount:2];
    [errorAnim setAutoreverses:YES];
    [errorAnim setFromValue:[NSNumber numberWithInt:0]];
    [errorAnim setToValue:[NSNumber numberWithInt:1]];
    [self.errorView.layer addAnimation:errorAnim forKey:@"displayErrorAnimation"];
}

- (UIView *)errorView {
    if (!errorView) {
        UIView *aErrorView = [[UIView alloc] initWithFrame:CGRectZero];
        aErrorView.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.35];
        aErrorView.layer.opacity = 0;
        [self addSubview:aErrorView];
        self.errorView = aErrorView;
        [aErrorView release];
    }
    
    return errorView;
}

@end

@implementation BlioLibraryGridViewCell

@synthesize bookView, titleLabel, authorLabel, progressSlider,progressView, progressBackgroundView,delegate,pauseButton,resumeButton,stateLabel,statusBadge,previewBadge,bookTypeBadge,numberOfDaysLeftLabel,daysLeftLabel;
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
	self.stateLabel = nil;
    self.delegate = nil;
    self.accessibilityElements = nil;
	self.statusBadge = nil;
	self.previewBadge = nil;
    self.bookTypeBadge = nil;
    self.numberOfDaysLeftLabel = nil;
    self.daysLeftLabel = nil;
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame reuseIdentifier: (NSString*) identifier{
    if ((self = [super initWithFrame:frame reuseIdentifier:identifier])) {
        self.clipsToBounds = NO;
		CGFloat bookWidth = kBlioLibraryGridBookWidthPhone;
		CGFloat bookHeight = kBlioLibraryGridBookHeightPhone;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			bookWidth = kBlioLibraryGridBookWidthPad;
			bookHeight = kBlioLibraryGridBookHeightPad;
		}

        BlioLibraryBookView* aBookView = [[BlioLibraryBookView alloc] initWithFrame:CGRectMake(0,0, bookWidth, bookHeight)];
		//        [aBookView addTarget:self.delegate action:@selector(bookTouched:)
		//            forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:aBookView];
		self.bookView = aBookView;
		
		progressBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"library-progress-background.png"]];
		progressBackgroundView.center = CGPointMake(ceilf(self.frame.size.width/2), floor(bookHeight*0.85f));
		progressBackgroundView.hidden = YES;
		[self.contentView addSubview:progressBackgroundView];
		
		stateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, -1, progressBackgroundView.bounds.size.width, progressBackgroundView.bounds.size.height)];
		stateLabel.textAlignment = UITextAlignmentCenter;
		stateLabel.backgroundColor = [UIColor clearColor];
		stateLabel.textColor = [UIColor whiteColor];
		stateLabel.hidden = YES;
		stateLabel.font = [UIFont boldSystemFontOfSize:12.0];
		[progressBackgroundView addSubview:stateLabel];
		
        CGPoint progressBackgroundCenter = progressBackgroundView.center;
		progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
		progressView.frame = CGRectMake(0, 0, kBlioLibraryGridProgressViewWidth, 10);
        if([[UIDevice currentDevice] compareSystemVersion:@"5.0"] == NSOrderedAscending) {
            // Metrics changed in iOS5!?
            progressView.center = progressBackgroundCenter;
        } else {
            progressView.center = CGPointMake(progressBackgroundCenter.x, progressBackgroundCenter.y - 0.5f);
        }
		progressView.hidden = YES;
		[self.contentView addSubview:progressView];
		
		pauseButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 33, 33)];
		[pauseButton setImage:[UIImage imageNamed:@"library-pausebutton.png"] forState:UIControlStateNormal];
		pauseButton.showsTouchWhenHighlighted = YES;
		[pauseButton addTarget:self action:@selector(onPauseButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		pauseButton.frame = CGRectMake(floor(self.frame.size.width/2 - pauseButton.frame.size.width/2), floor(self.frame.size.height/2 - pauseButton.frame.size.height/2), pauseButton.frame.size.width, pauseButton.frame.size.height);
		[pauseButton setAccessibilityLabel:NSLocalizedString(@"Pause", @"Accessibility label for Library View cell book pause button.")];
		[pauseButton setAccessibilityHint:NSLocalizedString(@"Pauses downloading and processing of book.", @"Accessibility hint for Library View cell book pause button.")];
		pauseButton.hidden = YES;
		[self.contentView addSubview:pauseButton];
		
		resumeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 33, 33)];
		[resumeButton setImage:[UIImage imageNamed:@"library-resumebutton.png"] forState:UIControlStateNormal];
		resumeButton.showsTouchWhenHighlighted = YES;
		[resumeButton addTarget:self action:@selector(onResumeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		resumeButton.frame = CGRectMake(floor(self.frame.size.width/2 - resumeButton.frame.size.width/2), floor(self.frame.size.height/2 - resumeButton.frame.size.height/2), resumeButton.frame.size.width, resumeButton.frame.size.height);
		[resumeButton setAccessibilityLabel:NSLocalizedString(@"Resume", @"Accessibility label for Library View cell book resume button.")];
		[resumeButton setAccessibilityHint:NSLocalizedString(@"Resumes downloading and processing of book.", @"Accessibility hint for Library View cell book resume button.")];
		resumeButton.hidden = YES;
		[self.contentView addSubview:resumeButton];
		
		statusBadge = [[UIImageView alloc] initWithFrame:CGRectMake(self.bounds.size.width - 25, self.bounds.size.height - 25, 20, 20)];
		statusBadge.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		[self.contentView addSubview:statusBadge];		

		previewBadge = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"badge-preview.png"]];
        
		previewBadge.frame = CGRectMake(roundf(self.bookView.xInset) - 1, roundf(self.bookView.yInset) - 1, 48, 48);
		previewBadge.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		[self.contentView addSubview:previewBadge];		

        bookTypeBadge = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"badge-daysleft.png"]];
        
		bookTypeBadge.frame = CGRectMake(roundf(self.bookView.xInset) - 1, roundf(self.bookView.yInset) - 1, 43, 43);
		bookTypeBadge.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		[self.contentView addSubview:bookTypeBadge];		

        numberOfDaysLeftLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        numberOfDaysLeftLabel.font = [UIFont systemFontOfSize:14.0f];
        numberOfDaysLeftLabel.adjustsFontSizeToFitWidth = YES;
        numberOfDaysLeftLabel.backgroundColor = [UIColor clearColor];
        numberOfDaysLeftLabel.textAlignment = UITextAlignmentCenter;
        [numberOfDaysLeftLabel setShadowColor:[UIColor whiteColor]];
        [numberOfDaysLeftLabel setShadowOffset:CGSizeMake(-0.5f, 0.5f)];
        numberOfDaysLeftLabel.transform = CGAffineTransformMakeRotation(-M_PI/4);
		[self.bookTypeBadge addSubview:numberOfDaysLeftLabel];		
        
        daysLeftLabel = [[UILabel alloc] initWithFrame:CGRectMake(-5, 12, 44, 10)];
        daysLeftLabel.font = [UIFont boldSystemFontOfSize:7.0f];
        daysLeftLabel.adjustsFontSizeToFitWidth = YES;
        daysLeftLabel.backgroundColor = [UIColor clearColor];
        daysLeftLabel.textAlignment = UITextAlignmentCenter;
        [daysLeftLabel setShadowColor:[UIColor whiteColor]];
        [daysLeftLabel setShadowOffset:CGSizeMake(-0.5f, 0.5f)];
        daysLeftLabel.transform = CGAffineTransformMakeRotation(-M_PI/4);
		[self.bookTypeBadge addSubview:daysLeftLabel];		

        
        [aBookView release];
		[self listenToProcessingNotifications];
	}
    return self;
}
-(void) prepareForReuse{
	[super prepareForReuse];
	progressBackgroundView.hidden = YES;
	progressView.hidden = YES;
	pauseButton.hidden = YES;
	resumeButton.hidden = YES;
	stateLabel.hidden = YES;
	stateLabel.font = [UIFont boldSystemFontOfSize:12.0];
	self.bookView.alpha = 1;
	self.statusBadge.image = nil;
	previewBadge.hidden = YES;
	previewBadge.alpha = 1;
	bookTypeBadge.hidden = YES;
	bookTypeBadge.alpha = 1;
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
            [deleteElement release];
        }
		
        BlioAccessibleGridBookElement *bookElement = [[BlioAccessibleGridBookElement alloc] initWithAccessibilityContainer:self];
        [bookElement setTarget:self];
        bookElement.delegate = self.delegate;
//        [bookElement setAccessibilityLabel:[NSString stringWithFormat:NSLocalizedString(@"%@ by %@, %.0f%% complete", @"Accessibility label for Library View cell book description"), 
//											[[self.bookView book] title], [[self.bookView book] author], 100 * [[[self.bookView book] progress] floatValue]]];
		NSString * previewString = @"";
		NSString * borrowString = @"";
		NSString * authorString = @"";
		NSString * audioString = @"";
		if ([[self.book valueForKey:@"productType"] intValue] == BlioProductTypePreview) {
			previewString = NSLocalizedString(@", Sample Book",@"Accessibility label add-on for sample books");
		}
        if ([[self.book valueForKey:@"transactionType"] intValue] == BlioTransactionTypeLend) {
            NSString * daysLeftMessage = nil;
            NSTimeInterval timeDifference = [[self.book valueForKey:@"expirationDate"] timeIntervalSinceDate:[NSDate date]];
            NSInteger daysLeftInteger = 0;
            if (timeDifference > 0) daysLeftInteger = ceil(timeDifference/86400);
            if (daysLeftInteger == 1) daysLeftMessage = NSLocalizedString(@"DAY LEFT", @"\"DAY LEFT\" label for borrowed books in the library interface.");
            else daysLeftMessage = NSLocalizedString(@"DAYS LEFT", @"\"DAYS LEFT\" label for borrowed books in the library interface.");
            borrowString = NSLocalizedString(@"Borrowed Book", @"Accessibility label for Borrowed Book");
            borrowString = [NSString stringWithFormat:@", %@, %i %@.",borrowString,daysLeftInteger, daysLeftMessage];
        }
		if ([self.book hasManifestValueForKey:BlioManifestAudiobookMetadataKey]) {
			audioString = NSLocalizedString(@", audiobook enabled.",@"Accessibility label add-on for library books denoting audiobook is enabled");
		}
		else if ([self.book hasTTSRights] && (self.book.hasEPub || self.book.hasTextFlow)) {
			audioString = NSLocalizedString(@", text-to-speech enabled.",@"Accessibility label add-on for library books denoting text-to-speech is enabled");
		}
		if (![[[self.bookView book] authorsWithStandardFormat] isEqualToString:@""]) authorString = [NSString stringWithFormat:@"%@%@",NSLocalizedString(@" by ",@"\"by\" separator between title and author for library book accessibility label"),[[self.bookView book] authorsWithStandardFormat]];
        [bookElement setAccessibilityLabel:[NSString stringWithFormat:NSLocalizedString(@"%@%@%@%@%@", @"Accessibility label for Library View cell book description"), 
											[[self.bookView book] title], authorString,previewString,borrowString,audioString]];
		
        [bookElement setAccessibilityTraits:UIAccessibilityTraitButton];
        [bookElement setVisibleRect:[self.delegate visibleRect]];
        if (![self.deleteButton isHidden] && [self.deleteButton alpha]) {
            [bookElement setAccessibilityHint:NSLocalizedString(@"Draggable. Double-tap and hold then move to desired location.", @"Accessibility hint for Library View cell book when editing")];
        } else {
            [bookElement setAccessibilityHint:[self stateBasedAccessibilityHint]];
        }
        [accArray addObject:bookElement];
        [bookElement release];
        
        self.accessibilityElements = accArray;
    }
    
    return [self.accessibilityElements count];
}
-(NSString*)stateBasedAccessibilityHint {
	
	if ([[[self.bookView book] valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateNotProcessed) {
		return NSLocalizedString(@"retrieving information.", @"Accessibility hint for not-processed Library View cell book description");
	}
	else if ([[[self.bookView book] valueForKey:@"processingState"] intValue] == kBlioBookProcessingStatePlaceholderOnly) {
		return NSLocalizedString(@" not yet downloaded.", @"Accessibility hint for placeholder-only Library View cell book description");
	}
	else if ([[[self.bookView book] valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateIncomplete) {
		NSString * incompleteTextLabel = NSLocalizedString(@"processing.",@"Accessibility hint for a processing Library View cell book description");
		if ([[delegate processingDelegate] incompleteDownloadOperationForSourceID:[[self.book valueForKey:@"sourceID"] intValue] sourceSpecificID:[self.book valueForKey:@"sourceSpecificID"]]) incompleteTextLabel = NSLocalizedString(@"downloading.",@"Accessibility hint for a downloading Library View cell book description");
		return incompleteTextLabel;
	}
	else if ([[[self.bookView book] valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateFailed) {
		return NSLocalizedString(@"failed to download.", @"Accessibility label for failed Library View cell book description");
	}
	else if ([[[self.bookView book] valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateNotSupported) {
		return NSLocalizedString(@"requires app update to be read.", @"Accessibility label for not supported Library View cell book description");
	}
	else if ([[[self.bookView book] valueForKey:@"processingState"] intValue] == kBlioBookProcessingStatePaused) {
		return NSLocalizedString(@"paused.", @"Accessibility label for paused Library View cell book description");
	}
	else if ([[[self.bookView book] valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateSuspended) {
		return NSLocalizedString(@"suspended.", @"Accessibility label for suspended Library View cell book description");
	}
	else return NSLocalizedString(@"Opens book. Double-tap and hold to share.", @"Accessibility hint for Library View cell book when not editing (i.e. can share)");
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
	self.bookView.delegate = self.delegate;
    [(BlioLibraryBookView *)self.bookView setBook:newBook forLayout:kBlioLibraryLayoutGrid];
    self.titleLabel.text = [newBook title];
	self.cellContentDescription = [newBook title];
    self.authorLabel.text = [[newBook author] uppercaseString];
//    if (![newBook hasTTSRights]) {
//        self.authorLabel.text = [NSString stringWithFormat:@"%@ %@", self.authorLabel.text, @"♫"];
//    }
    self.progressSlider.value = [[newBook progress] floatValue];
	
    // reposition book overlay widgets based upon size of book thumbnail
    CGPoint imageViewCenter = [self convertPoint:self.bookView.imageView.center fromView:self.bookView];
    imageViewCenter.x = ceilf(imageViewCenter.x) - 0.5;
    imageViewCenter.y = floorf(imageViewCenter.y) + 0.5;
    self.pauseButton.center = imageViewCenter;
    self.resumeButton.center = imageViewCenter;
    CGRect imageViewFrame = [self convertRect:self.bookView.imageView.frame fromView:self.bookView];
    self.deleteButton.center = CGPointMake(floorf(6 + imageViewFrame.origin.x) - 0.5f, floorf(6 + imageViewFrame.origin.y) + 0.5f);
    self.previewBadge.frame = CGRectMake(imageViewFrame.origin.x - 1, imageViewFrame.origin.y - 1, 48, 48);
    self.bookTypeBadge.frame = CGRectMake(imageViewFrame.origin.x - 1, imageViewFrame.origin.y - 1, 43, 43);

    [self setNeedsLayout];
	
	if ([[self.book valueForKey:@"productType"] intValue] == BlioProductTypePreview) {
		self.previewBadge.hidden = NO;
	}
	else self.previewBadge.hidden = YES;
    if ([[self.book valueForKey:@"transactionType"] intValue] == BlioTransactionTypeLend) {
		self.bookTypeBadge.hidden = NO;
        NSTimeInterval timeDifference = [[self.book valueForKey:@"expirationDate"] timeIntervalSinceDate:[NSDate date]];
        NSInteger daysLeftInteger = 0;
        if (timeDifference > 0) daysLeftInteger = ceil(timeDifference/86400);
        self.numberOfDaysLeftLabel.text = [NSString stringWithFormat:@"%i",daysLeftInteger];
        if (daysLeftInteger == 1) self.daysLeftLabel.text = NSLocalizedString(@"DAY LEFT", @"\"DAY LEFT\" label for borrowed books in the library interface.");
        else self.daysLeftLabel.text = NSLocalizedString(@"DAYS LEFT", @"\"DAYS LEFT\" label for borrowed books in the library interface.");
	}
	else self.bookTypeBadge.hidden = YES;
    
	
//	NSLog(@"[[self.book valueForKey:@processingState] intValue]: %i",[[self.book valueForKey:@"processingState"] intValue]);
	if ([[self.book valueForKey:@"processingState"] intValue] == kBlioBookProcessingStatePlaceholderOnly) {
		self.progressBackgroundView.hidden = YES;
		self.progressView.hidden = YES;
		self.pauseButton.hidden = YES;
		self.resumeButton.hidden = NO;
		self.stateLabel.hidden = YES;
	}	
	else if ([[self.book valueForKey:@"processingState"] intValue] != kBlioBookProcessingStateComplete) {
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
				NSLog(@"WARNING: could not find completeOp for obtaining processing progress for book: %@",[newBook title]);
				progressView.progress = 0;
			}
			self.pauseButton.hidden = NO;
			self.resumeButton.hidden = YES;
			self.stateLabel.hidden = YES;
		}
		if ([[self.book valueForKey:@"processingState"] intValue] == kBlioBookProcessingStatePaused) {
			self.resumeButton.hidden = NO;
			self.stateLabel.hidden = NO;
			self.stateLabel.text = NSLocalizedString(@"Paused...","\"Paused...\" status indicator in BlioLibraryGridViewCell");
			self.progressView.hidden = YES;
			self.pauseButton.hidden = YES;
		}
		if ([[self.book valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateFailed) {
			self.resumeButton.hidden = NO;
			self.stateLabel.hidden = NO;
			self.stateLabel.text = NSLocalizedString(@"Failed...","\"Failed...\" status indicator in BlioLibraryGridViewCell");
			self.progressView.hidden = YES;
			self.pauseButton.hidden = YES;
		}
		if ([[self.book valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateNotSupported) {
			self.resumeButton.hidden = NO;
			self.stateLabel.hidden = NO;
			stateLabel.font = [UIFont boldSystemFontOfSize:10.0];
			self.stateLabel.text = NSLocalizedString(@"Update Blio","\"Update Blio\" status indicator in BlioLibraryGridViewCell");
			self.progressView.hidden = YES;
			self.pauseButton.hidden = YES;
			self.statusBadge.image = [UIImage imageNamed:@"badge-notsupported.png"];
		}
		if ([[self.book valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateSuspended) {
			self.resumeButton.hidden = YES;
			self.stateLabel.hidden = NO;
			stateLabel.font = [UIFont boldSystemFontOfSize:10.0];
			self.stateLabel.text = NSLocalizedString(@"Suspended","\"Suspended\" status indicator in BlioLibraryGridViewCell");
			self.progressView.hidden = YES;
			self.pauseButton.hidden = YES;
			self.progressSlider.hidden = YES;
			//			self.statusBadge.image = [UIImage imageNamed:@"badge-notsupported.png"];
		}		
	}
	else {
		self.resumeButton.hidden = YES;
		self.stateLabel.hidden = YES;
		self.progressView.hidden = YES;
		self.pauseButton.hidden = YES;
		self.progressBackgroundView.hidden = YES;
		bookView.alpha = 1;
		if ([self.book hasManifestValueForKey:BlioManifestAudiobookMetadataKey]) {
			self.statusBadge.image = [UIImage imageNamed:@"badge-audiobook.png"];
		}
		else if ([self.book hasTTSRights] && (self.book.hasEPub || self.book.hasTextFlow)) {
			self.statusBadge.image = [UIImage imageNamed:@"badge-tts.png"];
		}
		
	}
}
-(void) listenToProcessingNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingProgressNotification:) name:BlioProcessingOperationProgressNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingCompleteNotification:) name:BlioProcessingOperationCompleteNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingFailedNotification:) name:BlioProcessingOperationFailedNotification object:nil];
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
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:_cmd withObject:note waitUntilDone:NO];
		return;
	}
	if ([self.book managedObjectContext] && [[note object] isKindOfClass:[BlioProcessingCompleteOperation class]] && [note userInfo] && [[note userInfo] objectForKey:@"bookID"] == [self.book objectID] && [[self.book valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateIncomplete) {
			BlioProcessingCompleteOperation * completeOp = [note object];
			progressView.progress = ((float)(completeOp.percentageComplete)/100.0f);
//            NSLog(@"BlioLibraryGridViewCell onProcessingProgressNotification entered. percentage: %u",completeOp.percentageComplete);
	}
}
- (void)onProcessingCompleteNotification:(NSNotification*)note {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:_cmd withObject:note waitUntilDone:NO];
		return;
	}
	if ([self.book managedObjectContext] && [[note object] isKindOfClass:[BlioProcessingCompleteOperation class]] && [note userInfo] && [[note userInfo] objectForKey:@"bookID"] == [self.book objectID]) {
		//	NSLog(@"BlioLibraryGridViewCell onProcessingCompleteNotification entered");
/*
		progressBackgroundView.hidden = YES;
		pauseButton.hidden = YES;	
		resumeButton.hidden = YES;	
		progressView.hidden = YES;
		bookView.alpha = 1;
		self.stateLabel.hidden = YES;
 */
	}
}
- (void)onProcessingFailedNotification:(NSNotification*)note {
	if ([self.book managedObjectContext] && [[note object] isKindOfClass:[BlioProcessingCompleteOperation class]] && [note userInfo] && self.book && [[note userInfo] objectForKey:@"bookID"] == [self.book objectID]) {
//		NSLog(@"BlioLibraryGridViewCell onProcessingFailedNotification entered");
//		self.resumeButton.hidden = NO;
//		self.stateLabel.hidden = NO;
//		self.stateLabel.text = NSLocalizedString(@"Failed...","\"Failed...\" status indicator in BlioLibraryGridViewCell");
//		self.progressView.hidden = YES;
//		self.pauseButton.hidden = YES;		
	}
}

@end

@implementation BlioLibraryListCell

@synthesize bookView, titleLabel, authorLabel, returnButton, /*progressSlider,proportionalProgressView,*/ delegate,progressView,pauseResumeButton,statusBadge,previewBadge,bookTypeBadge,numberOfDaysLeftLabel,daysLeftLabel;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.bookView = nil;
    self.titleLabel = nil;
    self.authorLabel = nil;
    //self.progressSlider = nil;
    self.progressView = nil;
	self.pauseResumeButton = nil;
	self.statusBadge = nil;
	self.previewBadge = nil;
    self.bookTypeBadge = nil;
    self.numberOfDaysLeftLabel = nil;
    self.daysLeftLabel = nil;
    self.returnButton = nil;
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.selectionStyle = UITableViewCellSelectionStyleGray;
        
		self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
				
        UIView *aBakcgroundView = [[UIView alloc] initWithFrame:self.bounds];
		self.backgroundView = aBakcgroundView;
        [aBakcgroundView release];
		self.backgroundView.autoresizesSubviews = YES;
		UIImageView * dividerView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SearchCellDivider.png"]];
		dividerView.frame = CGRectMake(0,0,self.bounds.size.width,2);
		[self.backgroundView addSubview:dividerView];
		dividerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [dividerView release];
        BlioLibraryBookView* aBookView = [[BlioLibraryBookView alloc] initWithFrame:CGRectMake(8,0, kBlioLibraryListBookWidth, kBlioLibraryListBookHeight)];
		//        [aBookView addTarget:self.delegate action:@selector(bookTouched:)
		//            forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:aBookView];
        self.bookView = aBookView;
        [aBookView release];
        
        UILabel *aTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.bookView.frame) + kBlioLibraryListBookMargin, 12, self.contentView.frame.size.width - (CGRectGetMaxX(self.bookView.frame) + kBlioLibraryListBookMargin) - kBlioLibraryListAccessoryMargin, 20)];
        aTitleLabel.font = [UIFont boldSystemFontOfSize:17.0f];
        aTitleLabel.backgroundColor = [UIColor clearColor];
		aTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:aTitleLabel];
        self.titleLabel = aTitleLabel;
        [aTitleLabel release];
        
        UILabel *aAuthorLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.bookView.frame) + kBlioLibraryListBookMargin, 28, self.contentView.frame.size.width - (CGRectGetMaxX(self.bookView.frame) + kBlioLibraryListBookMargin) - kBlioLibraryListAccessoryMargin, 20)];
        aAuthorLabel.font = [UIFont boldSystemFontOfSize:13.0f];
        aAuthorLabel.textColor = [UIColor colorWithRed:0.424f green:0.424f blue:0.443f alpha:1.0f];
        aAuthorLabel.backgroundColor = [UIColor clearColor];
		aAuthorLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:aAuthorLabel];
        self.authorLabel = aAuthorLabel;
        [aAuthorLabel release];
        
        UIButton* aReturnButton;
        if ([[UIDevice currentDevice] compareSystemVersion:@"7.0"] >= NSOrderedSame) {
            aReturnButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.bookView.frame) + kBlioLibraryListBookMargin, 52, 65, 15)];
            [aReturnButton setTitleColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
        }
        else {
            // Retain to match the +1 count from ...alloc] init...] in the other
            // branch of the if, above.
            aReturnButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
            
            [aReturnButton setFrame:CGRectMake(CGRectGetMaxX(self.bookView.frame) + kBlioLibraryListBookMargin, 52, 65, 15)];
            aReturnButton.showsTouchWhenHighlighted = YES;
        }
        [aReturnButton setAccessibilityLabel:NSLocalizedString(@"Return", @"Accessibility label for Library View cell book return button.")];
		[aReturnButton setAccessibilityHint:NSLocalizedString(@"Returns book to library.", @"Accessibility hint for Library View cell book return button.")];
        [aReturnButton setTitle:@"RETURN" forState:UIControlStateNormal];
        aReturnButton.titleLabel.font = [UIFont systemFontOfSize:12];
        aReturnButton.hidden = YES;
		[aReturnButton addTarget:self action:@selector(onReturnButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:aReturnButton];
        self.returnButton = aReturnButton;
        [aReturnButton release];
        
		/*
        BlioProgressView *aSlider = [[BlioProgressView alloc] init];
        [aSlider setIsAccessibilityElement:NO];
        aSlider.userInteractionEnabled = NO;
        aSlider.value = 0.0f;
        [aSlider setFrame:CGRectMake(CGRectGetMaxX(self.bookView.frame) + kBlioLibraryListBookMargin, 54,  self.contentView.frame.size.width - (CGRectGetMaxX(self.bookView.frame) + kBlioLibraryListBookMargin) - kBlioLibraryListAccessoryMargin, 9)];
        aSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self.contentView addSubview:aSlider];
        self.progressSlider = aSlider;
        [aSlider release];
		*/
		
		progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
		progressView.frame = CGRectMake(CGRectGetMaxX(self.bookView.frame) + kBlioLibraryListBookMargin, 52, self.contentView.frame.size.width - (CGRectGetMaxX(self.bookView.frame) + kBlioLibraryListBookMargin), 10);
		progressView.hidden = NO;
		progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self.contentView addSubview:self.progressView];

		pauseResumeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kBlioLibraryListButtonWidth, kBlioLibraryListButtonHeight)];
		[pauseResumeButton setImage:[UIImage imageNamed:@"library-resumebutton.png"] forState:UIControlStateNormal];
		pauseResumeButton.showsTouchWhenHighlighted = YES;
		[pauseResumeButton addTarget:self action:@selector(onPauseResumeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		pauseResumeButton.center = CGPointMake(self.frame.size.width/2, kBlioLibraryGridBookHeightPhone/2);
		[pauseResumeButton setAccessibilityLabel:NSLocalizedString(@"Resume", @"Accessibility label for Library View cell book resume button.")];
		[pauseResumeButton setAccessibilityHint:NSLocalizedString(@"Resumes downloading and processing of book.", @"Accessibility hint for Library View cell book resume button.")];
		
//		statusBadge = [[UIImageView alloc] initWithFrame:CGRectMake(self.contentView.bounds.size.width - 20 - kBlioLibraryListAccessoryMargin, 28, 20, 20)];
		statusBadge = [[UIImageView alloc] initWithFrame:CGRectMake(45, 52, 20, 20)];
		statusBadge.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		[self.contentView addSubview:statusBadge];
		
		previewBadge = [[UIImageView alloc] initWithFrame:CGRectMake(self.bookView.frame.origin.x + roundf(self.bookView.xInset) - 1, self.bookView.frame.origin.y + roundf(self.bookView.yInset) - 1, 36, 36)];
		previewBadge.image = [UIImage imageNamed:@"badge-preview.png"];
		previewBadge.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		[self.contentView addSubview:previewBadge];		

        bookTypeBadge = [[UIImageView alloc] initWithFrame:CGRectMake(self.bookView.frame.origin.x + roundf(self.bookView.xInset) - 1, self.bookView.frame.origin.y + roundf(self.bookView.yInset) - 1, 43, 43)];
		bookTypeBadge.image = [UIImage imageNamed:@"badge-daysleft.png"];
		bookTypeBadge.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		[self.contentView addSubview:bookTypeBadge];		

        numberOfDaysLeftLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        numberOfDaysLeftLabel.font = [UIFont systemFontOfSize:14.0f];
        numberOfDaysLeftLabel.adjustsFontSizeToFitWidth = YES;
        numberOfDaysLeftLabel.backgroundColor = [UIColor clearColor];
        numberOfDaysLeftLabel.textAlignment = UITextAlignmentCenter;
        [numberOfDaysLeftLabel setShadowColor:[UIColor whiteColor]];
        [numberOfDaysLeftLabel setShadowOffset:CGSizeMake(-0.5f, 0.5f)];
        numberOfDaysLeftLabel.transform = CGAffineTransformMakeRotation(-M_PI/4);
		[self.bookTypeBadge addSubview:numberOfDaysLeftLabel];		

        daysLeftLabel = [[UILabel alloc] initWithFrame:CGRectMake(-5, 12, 44, 10)];
        daysLeftLabel.font = [UIFont boldSystemFontOfSize:7.0f];
        daysLeftLabel.adjustsFontSizeToFitWidth = YES;
        daysLeftLabel.backgroundColor = [UIColor clearColor];
        daysLeftLabel.textAlignment = UITextAlignmentCenter;
        [daysLeftLabel setShadowColor:[UIColor whiteColor]];
        [daysLeftLabel setShadowOffset:CGSizeMake(-0.5f, 0.5f)];
        daysLeftLabel.transform = CGAffineTransformMakeRotation(-M_PI/4);
		[self.bookTypeBadge addSubview:daysLeftLabel];		

		[self listenToProcessingNotifications];
	}
    return self;
}
-(void)prepareForReuse {
	[super prepareForReuse];
	progressView.isAccessibilityElement = NO;
	progressView.progress = 0;
	progressView.hidden = YES;
	//progressSlider.hidden = YES;
	self.statusBadge.image = nil;
	self.accessoryView = nil;
	pauseResumeButton.isAccessibilityElement = NO;
	previewBadge.hidden = YES;
    bookTypeBadge.hidden = YES;
    returnButton.hidden = YES;
}

-(void)onReturnButtonPressed:(id)sender {
    [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Return Book",@"\"Return Book\" alert message title")
                                       message:NSLocalizedStringWithDefaultValue(@"RETURN_BOOK_EXPLANATION",nil,[NSBundle mainBundle],@"If you return this book to the library, it will no longer be available to download.  Would you like to proceed?",@"alert message explaining return of a book")
                                      delegate:self
                             cancelButtonTitle:NSLocalizedString(@"No",@"\"No\" label for button used to cancel/dismiss alertview")
                             otherButtonTitles: @"OK", nil];
}

-(void)onPauseResumeButtonPressed:(id)sender {
	if ([[[self.bookView book] valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateIncomplete) [delegate pauseProcessingForBook:[self book]];
	else [delegate enqueueBook:[self book]];
}
-(void)resetPauseResumeButton {
	if ([[[self.bookView book] valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateIncomplete) {
		[pauseResumeButton setImage:[UIImage imageNamed:@"library-pausebutton.png"] forState:UIControlStateNormal];
		[pauseResumeButton setAccessibilityLabel:NSLocalizedString(@"Pause", @"Accessibility label for Library View cell book pause button.")];
		[pauseResumeButton setAccessibilityHint:NSLocalizedString(@"Pauses downloading and processing of book.", @"Accessibility hint for Library View cell book pause button.")];
	}
	else if ([[[self.bookView book] valueForKey:@"processingState"] intValue] == kBlioBookProcessingStatePlaceholderOnly) {
		[pauseResumeButton setImage:[UIImage imageNamed:@"library-resumebutton.png"] forState:UIControlStateNormal];
		[pauseResumeButton setAccessibilityLabel:NSLocalizedString(@"Download", @"Accessibility label for Archive View cell book download button.")];
		[pauseResumeButton setAccessibilityHint:NSLocalizedString(@"Downloads book.", @"Accessibility hint for Library View cell book download button.")];
	}
	else {
		[pauseResumeButton setImage:[UIImage imageNamed:@"library-resumebutton.png"] forState:UIControlStateNormal];
		[pauseResumeButton setAccessibilityLabel:NSLocalizedString(@"Resume", @"Accessibility label for Library View cell book resume button.")];
		[pauseResumeButton setAccessibilityHint:NSLocalizedString(@"Resumes downloading and processing of book.", @"Accessibility hint for Library View cell book resume button.")];
	}
}
- (NSString *)accessibilityLabel {
	NSString * previewString = @"";
	NSString * borrowString = @"";
	NSString * authorString = @"";
	NSString * audioString = @"";
	
	if ([[self.book valueForKey:@"productType"] intValue] == BlioProductTypePreview) {
		previewString = NSLocalizedString(@", Sample Book",@"Accessibility label add-on for sample books");
	}
    if ([[self.book valueForKey:@"transactionType"] intValue] == BlioTransactionTypeLend) {
        NSString * daysLeftMessage = nil;
        NSTimeInterval timeDifference = [[self.book valueForKey:@"expirationDate"] timeIntervalSinceDate:[NSDate date]];
        NSInteger daysLeftInteger = 0;
        if (timeDifference > 0) daysLeftInteger = ceil(timeDifference/86400);
        if (daysLeftInteger == 1) daysLeftMessage = NSLocalizedString(@"DAY LEFT", @"\"DAY LEFT\" label for borrowed books in the library interface.");
        else daysLeftMessage = NSLocalizedString(@"DAYS LEFT", @"\"DAYS LEFT\" label for borrowed books in the library interface.");
        borrowString = NSLocalizedString(@"Borrowed Book", @"Accessibility label for Borrowed Book");
        borrowString = [NSString stringWithFormat:@", %@, %i %@.",borrowString,daysLeftInteger, daysLeftMessage];
    }
	if ([self.book hasManifestValueForKey:BlioManifestAudiobookMetadataKey]) {
		audioString = NSLocalizedString(@", audiobook enabled.",@"Accessibility label add-on for library books denoting audiobook is enabled");
	}
	else if ([self.book hasTTSRights] && (self.book.hasEPub || self.book.hasTextFlow)) {
		audioString = NSLocalizedString(@", text-to-speech enabled.",@"Accessibility label add-on for library books denoting text-to-speech is enabled");
	}
	
	if (![[[self.bookView book] authorsWithStandardFormat] isEqualToString:@""]) authorString = [NSString stringWithFormat:@"%@%@",NSLocalizedString(@" by ",@"\"by\" separator between title and author for library book accessibility label"),[[self.bookView book] authorsWithStandardFormat]];

	if ([[[self.bookView book] valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateNotProcessed) {
		return [NSString stringWithFormat:NSLocalizedString(@"%@%@%@%@%@, retrieving information.", @"Accessibility label for not-processed Library View cell book description"), 
				[[self.bookView book] title], authorString,previewString,borrowString,audioString];
	}
	else if ([[[self.bookView book] valueForKey:@"processingState"] intValue] == kBlioBookProcessingStatePlaceholderOnly) {
		return [NSString stringWithFormat:NSLocalizedString(@"%@%@%@%@%@, not yet downloaded.", @"Accessibility label for placeholder-only Library View cell book description"), 
				[[self.bookView book] title], authorString,previewString,borrowString,audioString];
	}
	else if ([[[self.bookView book] valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateIncomplete) {
//		return [NSString stringWithFormat:NSLocalizedString(@"%@%@, %.0f%% complete", @"Accessibility label for incomplete Library View cell book description"), 
//				[[self.bookView book] title], authorString, 100 * [[[self.bookView book] progress] floatValue]];
		NSString * incompleteTextLabel = NSLocalizedString(@"processing.",@"Accessibility hint for a processing Library View cell book description");
		if ([[delegate processingDelegate] incompleteDownloadOperationForSourceID:[[self.book valueForKey:@"sourceID"] intValue] sourceSpecificID:[self.book valueForKey:@"sourceSpecificID"]]) incompleteTextLabel = NSLocalizedString(@"downloading.",@"Accessibility hint for a downloading Library View cell book description");

		return [NSString stringWithFormat:NSLocalizedString(@"%@%@%@%@%@, %@.", @"Accessibility label for incomplete Library View cell book description"), 
				[[self.bookView book] title], authorString,previewString,borrowString,audioString,incompleteTextLabel];
	}
	else if ([[[self.bookView book] valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateFailed) {
		return [NSString stringWithFormat:NSLocalizedString(@"%@%@%@%@%@, failed to download.", @"Accessibility label for failed Library View cell book description"), 
				[[self.bookView book] title], authorString,previewString,borrowString,audioString];
	}
	else if ([[[self.bookView book] valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateNotSupported) {
		return [NSString stringWithFormat:NSLocalizedString(@"%@%@%@%@%@, requires app update to be read.", @"Accessibility label for not supported Library View cell book description"), 
				[[self.bookView book] title], authorString,previewString,borrowString,audioString];
	}
	else if ([[[self.bookView book] valueForKey:@"processingState"] intValue] == kBlioBookProcessingStatePaused) {
		return [NSString stringWithFormat:NSLocalizedString(@"%@%@%@%@%@, paused", @"Accessibility label for paused Library View cell book description"), 
				[[self.bookView book] title], authorString,previewString,borrowString,audioString];
	}
	else if ([[[self.bookView book] valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateSuspended) {
		return [NSString stringWithFormat:NSLocalizedString(@"%@%@%@%@%@, suspended", @"Accessibility label for suspended Library View cell book description"), 
				[[self.bookView book] title], authorString,previewString,borrowString,audioString];
	}
	else return [NSString stringWithFormat:NSLocalizedString(@"%@%@%@%@%@", @"Accessibility label for complete Library View cell book description"), 
						[[self.bookView book] title], authorString,previewString,borrowString,audioString];
}

- (NSString *)accessibilityHint {
    if ([[[self.bookView book] valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateComplete) return NSLocalizedString(@"Opens book.", @"Accessibility label for Library View cell book hint");
	return @"";
}
- (BlioBook *)book {
    return [(BlioLibraryBookView *)self.bookView book];
}

- (void)setBook:(BlioBook *)newBook {
	self.bookView.delegate = self.delegate;
    [(BlioLibraryBookView *)self.bookView setBook:newBook forLayout:kBlioLibraryLayoutList];
    self.titleLabel.text = [newBook title];
	layoutPageEquivalentCount = [self.book.layoutPageEquivalentCount unsignedIntValue];
    //self.progressSlider.value = [[newBook progress] floatValue];
	
	//[self resetProgressSlider];
	[self resetPauseResumeButton];
    
    CGRect imageViewFrame = [self.contentView convertRect:self.bookView.imageView.frame fromView:self.bookView];
    self.previewBadge.frame = CGRectMake(imageViewFrame.origin.x - 1, imageViewFrame.origin.y - 1, 36, 36);
    self.bookTypeBadge.frame = CGRectMake(imageViewFrame.origin.x - 1, imageViewFrame.origin.y - 1, 43, 43);

	if ([[self.book valueForKey:@"productType"] intValue] == BlioProductTypePreview) {
		self.previewBadge.hidden = NO;
	}
	else self.previewBadge.hidden = YES;
    if ([[self.book valueForKey:@"transactionType"] intValue] == BlioTransactionTypeLend) {
		self.bookTypeBadge.hidden = NO;
        NSTimeInterval timeDifference = [[self.book valueForKey:@"expirationDate"] timeIntervalSinceDate:[NSDate date]];
        NSInteger daysLeftInteger = 0;
        if (timeDifference > 0) {
            daysLeftInteger = ceil(timeDifference/86400);
            NSInteger processingState = [[[self.bookView book] valueForKey:@"processingState"] intValue];
            if ( (processingState != kBlioBookProcessingStatePlaceholderOnly)
                && (processingState != kBlioBookProcessingStateIncomplete) )
                self.returnButton.hidden = NO;
        }
        self.numberOfDaysLeftLabel.text = [NSString stringWithFormat:@"%i",daysLeftInteger];
        if (daysLeftInteger == 1) self.daysLeftLabel.text = NSLocalizedString(@"DAY LEFT", @"\"DAY LEFT\" label for borrowed books in the library interface.");
        else self.daysLeftLabel.text = NSLocalizedString(@"DAYS LEFT", @"\"DAYS LEFT\" label for borrowed books in the library interface.");
	}
	else self.bookTypeBadge.hidden = YES;
	
	if ([[self.book valueForKey:@"processingState"] intValue] == kBlioBookProcessingStatePlaceholderOnly) {
		progressView.isAccessibilityElement = NO;
		progressView.hidden = YES;
		self.accessoryView = pauseResumeButton;
		[self resetAuthorText];
		//self.progressSlider.hidden = YES;
	}			
	else if ([[self.book valueForKey:@"processingState"] intValue] != kBlioBookProcessingStateComplete) {
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		self.accessoryView = pauseResumeButton;
		pauseResumeButton.isAccessibilityElement = YES;
		// set appearance to reflect incomplete state
		// self.bookView.alpha = 0.35f;
		if ([[self.book valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateIncomplete) {
			progressView.frame = CGRectMake(CGRectGetMaxX(self.bookView.frame) + kBlioLibraryListBookMargin, 52, self.contentView.frame.size.width - (CGRectGetMaxX(self.bookView.frame) + kBlioLibraryListBookMargin), 10);
			progressView.hidden = NO;
			progressView.isAccessibilityElement = YES;

			//self.progressSlider.hidden = YES;
			BlioProcessingCompleteOperation * completeOp = [[delegate processingDelegate] processingCompleteOperationForSourceID:[[self.book valueForKey:@"sourceID"] intValue] sourceSpecificID:[self.book valueForKey:@"sourceSpecificID"]];
			if (completeOp) {
				[completeOp calculateProgress];
				progressView.progress = ((float)(completeOp.percentageComplete)/100.0f);
			}
			else {
				// NSLog(@"WARNING: could not find completeOp for obtaining processing progress for book: %@",[newBook title]);
				progressView.progress = 0;
			}
			if (progressView.progress == 0) NSLocalizedString(@"Calculating...","\"Calculating...\" status indicator in BlioLibraryListCell");
			if ([[delegate processingDelegate] incompleteDownloadOperationForSourceID:[[self.book valueForKey:@"sourceID"] intValue] sourceSpecificID:[self.book valueForKey:@"sourceSpecificID"]]) self.authorLabel.text = NSLocalizedString(@"Downloading...","\"Downloading...\" status indicator in BlioLibraryListCell");
			else self.authorLabel.text = NSLocalizedString(@"Processing...","\"Processing...\" status indicator in BlioLibraryListCell");

		}
		if ([[self.book valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateNotProcessed) {
			self.authorLabel.text = NSLocalizedString(@"Retrieving Information...","\"Retrieving Information...\" status indicator in BlioLibraryListCell");
			progressView.isAccessibilityElement = NO;
			progressView.hidden = YES;
			self.accessoryView = nil;
			pauseResumeButton.isAccessibilityElement = NO;
			//self.progressSlider.hidden = YES;
		}
		if ([[self.book valueForKey:@"processingState"] intValue] == kBlioBookProcessingStatePaused) {
			self.authorLabel.text = NSLocalizedString(@"Paused...","\"Paused...\" status indicator in BlioLibraryListCell");
			progressView.isAccessibilityElement = NO;
			progressView.hidden = YES;
			//self.progressSlider.hidden = YES;
		}
		if ([[self.book valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateFailed) {
			self.authorLabel.text = NSLocalizedString(@"Failed...","\"Failed...\" status indicator in BlioLibraryListCell");
			progressView.isAccessibilityElement = NO;
			progressView.hidden = YES;
			//self.progressSlider.hidden = YES;
		}
		if ([[self.book valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateNotSupported) {

			self.authorLabel.text = NSLocalizedString(@"Blio Update Required","\"Blio Update Required\" status indicator in BlioLibraryListCell");
			progressView.isAccessibilityElement = NO;
			progressView.hidden = YES;
			self.statusBadge.image = [UIImage imageNamed:@"badge-notsupported.png"];
		}
		if ([[self.book valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateSuspended) {
			self.authorLabel.text = NSLocalizedString(@"Suspended","\"Suspended\" status indicator in BlioLibraryListCell");
			progressView.isAccessibilityElement = NO;
			progressView.hidden = YES;
			//self.progressSlider.hidden = YES;
//			self.statusBadge.image = [UIImage imageNamed:@"badge-notsupported.png"];
		}
	}
	else {
		//self.progressSlider.hidden = NO;
		progressView.isAccessibilityElement = NO;
		progressView.hidden = YES;
        self.accessoryView = nil;
		pauseResumeButton.isAccessibilityElement = NO;
		[self resetAuthorText];
		self.selectionStyle = UITableViewCellSelectionStyleGray;
		if ([self.book hasManifestValueForKey:BlioManifestAudiobookMetadataKey]) {
			self.statusBadge.image = [UIImage imageNamed:@"badge-audiobook.png"];
		}
		else if ([self.book hasTTSRights] && (self.book.hasEPub || self.book.hasTextFlow)) {
			self.statusBadge.image = [UIImage imageNamed:@"badge-tts.png"];
		}
	}
    [self setNeedsLayout];
	[self layoutIfNeeded];
	UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}
-(void) listenToProcessingNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingProgressNotification:) name:BlioProcessingOperationProgressNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingCompleteNotification:) name:BlioProcessingOperationCompleteNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingFailedNotification:) name:BlioProcessingOperationFailedNotification object:nil];
}
-(void) stopListeningToProcessingNotifications {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioProcessingOperationProgressNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioProcessingOperationCompleteNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioProcessingOperationFailedNotification object:nil];
}
/*
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
			self.progressSlider.frame = CGRectMake(progressFrame.origin.x, progressFrame.origin.y, targetProgressWidth, progressFrame.size.height);	
		}
	}
//	else {		
//		// N.B. this condition is for when maxLayoutPageEquivalentCount is NOT honored and progress bars should all be a standard size.
//		// use this snippet to only show progress slider for books that have been started by the end-user.
//		if ([self.book.progress floatValue] > 0) { 
//			targetProgressWidth = self.contentView.frame.size.width - (CGRectGetMaxX(self.bookView.frame) + kBlioLibraryListBookMargin);
//			self.progressSlider.frame = CGRectMake(progressFrame.origin.x, progressFrame.origin.y, targetProgressWidth, progressFrame.size.height);	
//		}
//	}
	
}
*/
-(void) resetAuthorText {
    self.authorLabel.text = [[self.book authorsWithStandardFormat] uppercaseString];
//    if (![self.book hasTTSRights] && [self.book hasManifestValueForKey:BlioManifestAudiobookMetadataKey]) {
//        self.authorLabel.text = [NSString stringWithFormat:@"%@ %@", self.authorLabel.text, @"♫"];
//    }	
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
	// TODO: might this function be needed for anything else?
	//if (delegate == [note object]) [self resetProgressSlider];
}
- (void)onProcessingProgressNotification:(NSNotification*)note {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:_cmd withObject:note waitUntilDone:NO];
		return;
    }

		if ([self.book managedObjectContext] && [[note object] isKindOfClass:[BlioProcessingCompleteOperation class]] && [note userInfo] && [[note userInfo] objectForKey:@"bookID"] == [self.book objectID] && [[self.book valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateIncomplete) {
			BlioProcessingCompleteOperation * completeOp = [note object];
			//	NSLog(@"BlioLibraryListViewCell onProcessingProgressNotification entered. percentage: %u",completeOp.percentageComplete);
//			progressView.isAccessibilityElement = YES;
			progressView.frame = CGRectMake(CGRectGetMaxX(self.bookView.frame) + kBlioLibraryListBookMargin, 52, self.contentView.frame.size.width - (CGRectGetMaxX(self.bookView.frame) + kBlioLibraryListBookMargin), 10);
			progressView.progress = ((float)(completeOp.percentageComplete)/100.0f);


		}
}

- (void)onProcessingCompleteNotification:(NSNotification*)note {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:_cmd withObject:note waitUntilDone:NO];
		return;
	}
		if ([self.book managedObjectContext] && [[note object] isKindOfClass:[BlioProcessingDownloadOperation class]] && [note userInfo] && [[note userInfo] objectForKey:@"bookID"] == [self.book objectID] && [[self.book valueForKey:@"processingState"] intValue] == kBlioBookProcessingStateIncomplete) {
			if ([[delegate processingDelegate] incompleteDownloadOperationForSourceID:[[self.book valueForKey:@"sourceID"] intValue] sourceSpecificID:[self.book valueForKey:@"sourceSpecificID"]]) self.authorLabel.text = NSLocalizedString(@"Downloading...","\"Downloading...\" status indicator in BlioLibraryListCell");
			else self.authorLabel.text = NSLocalizedString(@"Processing...","\"Processing...\" status indicator in BlioLibraryListCell");
		}
}
- (void)onProcessingFailedNotification:(NSNotification*)note {
	if ([self.book managedObjectContext] && [[note object] isKindOfClass:[BlioProcessingCompleteOperation class]] && [note userInfo] && [[note userInfo] objectForKey:@"bookID"] == [self.book objectID]) {
//		NSLog(@"BlioLibraryListViewCell onProcessingFailedNotification entered");
//		self.accessoryView = resumeButton;
//		self.authorLabel.text = @"Failed...";
//		self.progressView.hidden = YES;
//		self.progressSlider.hidden = YES;		
	}
}

#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            break;
        case 1:
            NSLog(@"Return %@ to library.", self.book.title);
            /*
            BookVaultSoap *vaultBinding = [[BookVault BookVaultSoap] retain];
            vaultBinding.logXMLInOut = YES;
            BookVault_DeleteBook* deleteBookRequest = [[BookVault_DeleteBook new] autorelease];
            deleteBookRequest.token = [[BlioStoreManager sharedInstance] tokenForSourceID:BlioBookSourceOnlineStore];
            deleteBookRequest.productTypeId = [self.book valueForKey:@"productType"];
            deleteBookRequest.ISBN = [self.book valueForKey:@"isbn"];
            [vaultBinding DeleteBookAsyncUsingParameters:deleteBookRequest delegate:self];
            [vaultBinding release];
             */
            break;
        default:
            break;
    }
}

/*
#pragma mark BookVaultSoapResponseDelegate method

- (void) operation:(BookVaultSoapOperation *)operation completedWithResponse:(BookVaultSoapResponse *)response {
	if (!response.responseType) {
		NSLog(@"ERROR: response has no response type!");
		return;
	}
	if ([response.responseType isEqualToString:BlioBookVaultResponseTypeDeleteBook]) {
		
		NSArray *responseBodyParts = response.bodyParts;
		for(id bodyPart in responseBodyParts) {
            NSLog(@"DeleteBook response bodyPart: %@",bodyPart);
		}
        
		for(id bodyPart in responseBodyParts) {
			if ([bodyPart isKindOfClass:[SOAPFault class]]) {
				NSString* err = ((SOAPFault *)bodyPart).simpleFaultString;
				NSLog(@"SOAP error for book deletion: %@",err);
                NSString* errorMessage = @"There was an error returning this book: ";
                [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Return Book",@"\"Return Book\" alert message title")
                                                   message:[errorMessage stringByAppendingString:err]
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
                                         otherButtonTitles: nil];
				return;
			}
            else if ( [[bodyPart DeleteBookResult].ReturnCode intValue] == 0 ) {
                // Success.  Now delete the book locally, which will also update the data source.
                // TODO: deleteBook should delete license
                [[delegate processingDelegate] deleteBook:self.book attemptArchive:NO shouldSave:YES];
				return;
			}
			else {
                NSString* errorMessage = [bodyPart DeleteBookResult].Message;
				NSLog(@"Error %@ deleting book from archive: %@",[[[bodyPart DeleteBookResult] ReturnCode] stringValue], errorMessage);
                [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Return Book",@"\"Return Book"\" alert message title")
                                                   message:errorMessage
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
                                         otherButtonTitles: nil];
				return;
			}
		}
	}
}
*/

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

@implementation BlioLogoView

@synthesize numberOfBooksInLibrary, imageView;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        
        UIImageView *aImageView = [[UIImageView alloc] initWithFrame:self.frame];
        [aImageView setContentMode:UIViewContentModeScaleAspectFit];
        [aImageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [self addSubview:aImageView];
        self.imageView = aImageView;
        [aImageView release];
    }
    return self;
}

- (void)dealloc {
    self.imageView = nil;
    [super dealloc];
}

- (void)setImage:(UIImage *)newImage {
    [self.imageView setImage:newImage];
}

- (void)setFrame:(CGRect)newFrame {
    // Override frame setting because when rotating in BookViewController the libraryView titleView gets an incorrect frame set
    if (nil != self.superview) {
        newFrame.origin.y = 4;
        newFrame.size.height = self.superview.bounds.size.height - 7;
    }
    [super setFrame:newFrame];
}

- (BOOL)isAccessibilityElement {
    return YES;
}

- (NSString *)accessibilityLabel {

    if (numberOfBooksInLibrary == 0) {
        return NSLocalizedString(@"Blio Library. No books", @"Accessibility label for Library View Blio label with no books");
    } else if (numberOfBooksInLibrary == 1) {
        return [NSString stringWithFormat:NSLocalizedString(@"Blio Library. %d book", @"Accessibility label for Library View Blio label with 1 book"), numberOfBooksInLibrary];
    } else {
        return [NSString stringWithFormat:NSLocalizedString(@"Blio Library. %d books", @"Accessibility label for Library View Blio label with more than 1 book"), numberOfBooksInLibrary];
    }
}

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitStaticText | UIAccessibilityTraitSummaryElement;
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
	return accFrame;
}

@end

@implementation BlioAccessibleGridBookElement

@synthesize delegate;

- (CGRect)accessibilityFrame {
    CGRect accFrame = [self.target accessibilityFrame];
	CGRect insetFrame = CGRectInset(accFrame,10,10);
	self.accessibilityFrame = insetFrame;
	return insetFrame;
}
- (void)accessibilityElementDidBecomeFocused {
	//	NSLog(@"BlioAccessibleGridBookElement accessibilityElementDidBecomeFocused entered.");
	[[self.delegate gridView] accessibilityFocusedOnCell:self.target];
}

@end
