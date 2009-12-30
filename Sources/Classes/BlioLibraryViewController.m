//
//  RootViewController.m
//  BlioApp
//
//  Created by James Montgomerie on 16/12/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "BlioLibraryViewController.h"
#import <libEucalyptus/EucEPubBook.h>
#import <libEucalyptus/EucBookViewController.h>
#import "BlioLayoutView.h"
#import "BlioViewSettingsSheet.h"
#import "BlioMockBook.h"

#import "BlioTestParagraphWords.h"

static const CGFloat kBlioLibraryToolbarHeight = 44;

static const CGFloat kBlioLibraryListRowHeight = 76;
static const CGFloat kBlioLibraryListBookHeight = 76;
static const CGFloat kBlioLibraryListBookWidth = 53;
static const CGFloat kBlioLibraryListContentWidth = 220;

static const CGFloat kBlioLibraryGridRowHeight = 140;
static const CGFloat kBlioLibraryGridBookHeight = 140;
static const CGFloat kBlioLibraryGridBookWidth = 102;
static const CGFloat kBlioLibraryGridBookSpacing = 0;

static const CGFloat kBlioLibraryLayoutButtonWidth = 78;
static const CGFloat kBlioLibraryShadowXInset = 0.10276f; // Nasty hack to work out proportion of texture image is shadow
static const CGFloat kBlioLibraryShadowYInset = 0.07737f;

static const CGFloat kBlioFontPointSizeArray[] = { 14.0f, 16.0f, 18.0f, 20.0f, 22.0f };

@interface BlioLibraryTableView : UITableView

@end

@interface BlioLibraryBookView : UIControl {
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

@end

@interface BlioLibraryGridCell : UITableViewCell {
  NSArray *books;
  NSMutableArray* bookViews;
  NSUInteger rowIndex;
  CGSize bookSize;
  CGPoint bookOrigin;
  NSInteger columnCount;
  id delegate;
}

@property (nonatomic) NSUInteger rowIndex;
@property (nonatomic, assign) NSArray *books;
@property (nonatomic, retain) NSMutableArray* bookViews;
@property (nonatomic) CGSize bookSize;
@property (nonatomic) CGPoint bookOrigin;
@property (nonatomic) NSInteger columnCount;
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

@implementation BlioLibraryViewController

@synthesize currentBookView = _currentBookView;
@synthesize currentBookPath = _currentBookPath;
@synthesize currentPdfPath = _currentPdfPath;
@synthesize audioPlaying = _audioPlaying;
@synthesize books = _books;
@synthesize libraryLayout = _libraryLayout;

- (void)dealloc {
  self.currentBookView = nil;
  self.currentBookPath = nil;
  self.currentPdfPath = nil;
  self.books = nil;
  self.tableView = nil;
  [super dealloc];
}

- (void)loadView {
  // UITableView subclass so that custom background is only drawn here
  BlioLibraryTableView *aTableView = [[BlioLibraryTableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
  self.tableView = aTableView;
  [aTableView release];
  
  NSMutableArray *libraryItems = [NSMutableArray array];
  UIBarButtonItem *item;
  
  item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  [libraryItems addObject:item];
  [item release];
  
  item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button-sync.png"]
                                          style:UIBarButtonItemStyleBordered
                                         target:self 
                                         action:nil];
  [libraryItems addObject:item];
  [item release];
  
  item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  [libraryItems addObject:item];
  [item release];
  
  item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button-getbooks.png"]
                                          style:UIBarButtonItemStyleBordered
                                         target:self 
                                         action:nil];
  [libraryItems addObject:item];
  [item release];
  
  item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  [libraryItems addObject:item];
  [item release];  
  
  item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button-settings.png"]
                                          style:UIBarButtonItemStyleBordered
                                         target:self 
                                         action:nil];
  [libraryItems addObject:item];
  [item release];
  
  item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  [libraryItems addObject:item];
  [item release];  
  
  [self setToolbarItems:[NSArray arrayWithArray:libraryItems] animated:YES];
  [self.navigationController setToolbarHidden:NO];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.audioPlaying = NO;
  self.libraryLayout = kBlioLibraryLayoutGrid;
  
  self.navigationItem.rightBarButtonItem = self.editButtonItem;
  
  NSArray *segmentImages = [NSArray arrayWithObjects:
                            [UIImage imageNamed:@"button-grid.png"],
                            [UIImage imageNamed:@"button-list.png"],
                            nil];
  UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:segmentImages];
  segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
  segmentedControl.frame = CGRectMake(0,0, kBlioLibraryLayoutButtonWidth, segmentedControl.frame.size.height);
  [segmentedControl addTarget:self action:@selector(changeLibraryLayout:) forControlEvents:UIControlEventValueChanged];
  [segmentedControl setSelectedSegmentIndex:self.libraryLayout];
  
  UIBarButtonItem *libraryLayoutButton = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
  self.navigationItem.leftBarButtonItem = libraryLayoutButton;
  [libraryLayoutButton release];
  
  NSMutableArray *aArray = [NSMutableArray array];
  BlioMockBook *aBook = nil;
  
  NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
  
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"Dead Is So Last Year"];
  [aBook setAuthor:@"Marlene Perez"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"ePubs/Dead Is So Last Year.epub/OPS/cover.png"]];
  [aBook setBookPath:[[NSBundle mainBundle] pathForResource:@"Dead Is So Last Year" ofType:@"epub" inDirectory:@"ePubs"]];
  [aBook setPdfPath:[[NSBundle mainBundle] pathForResource:@"Dead Is So Last Year" ofType:@"pdf" inDirectory:@"PDFs"]];
  [aBook setProgress:0.8f];
  [aBook setProportionateSize:0.3f];
  [aArray addObject:aBook];
  [aBook release];
  
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"Exiles In The Garden"];
  [aBook setAuthor:@"Ward Just"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"ePubs/Exiles In The Garden.epub/OPS/cover.png"]];
  [aBook setBookPath:[[NSBundle mainBundle] pathForResource:@"Exiles In The Garden" ofType:@"epub" inDirectory:@"ePubs"]];
  [aBook setPdfPath:[[NSBundle mainBundle] pathForResource:@"Exiles In The Garden" ofType:@"pdf" inDirectory:@"PDFs"]];
  [aBook setProgress:0.3f];
  [aBook setProportionateSize:0.6f];
  [aArray addObject:aBook];
  [aBook release];
  
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"Essentials Of Discrete Mathematics"];
  [aBook setAuthor:@"David J. Hunter"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"MockCovers/Essentials_of_Discrete_Mathematics.png"]];
  [aBook setPdfPath:[[NSBundle mainBundle] pathForResource:@"Essentials_of_Discrete_Mathematics" ofType:@"pdf" inDirectory:@"PDFs"]];
  [aBook setProgress:0.0f];
  [aBook setProportionateSize:0.2f];
  [aArray addObject:aBook];
  [aBook release];
  
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"Three Little Pigs"];
  [aBook setAuthor:@"Stella Blackstone"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"MockCovers/Three_Little_Pigs.png"]];
  [aBook setBookPath:[[NSBundle mainBundle] pathForResource:@"Three Little Pigs" ofType:@"epub" inDirectory:@"ePubs"]];
  [aBook setPdfPath:[[NSBundle mainBundle] pathForResource:@"Three Little Pigs" ofType:@"pdf" inDirectory:@"PDFs"]];
  [aBook setProgress:1.0f];
  [aBook setProportionateSize:0.05f];
  [aArray addObject:aBook];
  [aBook release];
  
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"The Oz Principle"];
  [aBook setAuthor:@"Roger Conners"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"MockCovers/RogerConnors.png"]];
  [aBook setProgress:0.0f];
  [aBook setProportionateSize:0.7f];
  [aArray addObject:aBook];
  [aBook release];
   
   
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"How To Be A Movie Star"];
  [aBook setAuthor:@"William Mann"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"MockCovers/WilliamMann.png"]];
  [aBook setProgress:0.0f];
  [aBook setProportionateSize:0.45f];
  [aArray addObject:aBook];
  [aBook release];
  
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"Her Fearful Symmetry"];
  [aBook setAuthor:@"Audrey Niffenegger"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"MockCovers/AudreyNiffenegger.png"]];
  [aBook setProgress:0.0f];
  [aBook setProportionateSize:0.62f];
  [aArray addObject:aBook];
  [aBook release];
  
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"The Lost Symbol"];
  [aBook setAuthor:@"Dan Brown"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"MockCovers/DanBrown.png"]];
  [aBook setProgress:1.0f];
  [aBook setProportionateSize:0.53f];
  [aArray addObject:aBook];
  [aBook release];
  
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"Hostage"];
  [aBook setAuthor:@"Don Brown"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"MockCovers/DonBrown.png"]];
  [aBook setProgress:0.0f];
  [aBook setProportionateSize:0.41f];
  [aArray addObject:aBook];
  [aBook release];
  
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"I, Alex Cross"];
  [aBook setAuthor:@"James Patterson"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"MockCovers/JamesPatterson.png"]];
  [aBook setProgress:0.65f];
  [aBook setProportionateSize:0.67f];
  [aArray addObject:aBook];
  [aBook release];
  
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"Diary of a Wimpy Kid, Dog Days"];
  [aBook setAuthor:@"Jeff Kinney"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"MockCovers/JeffKinney.png"]];
  [aBook setProgress:0.0f];
  [aBook setProportionateSize:0.45f];
  [aArray addObject:aBook];
  [aBook release];
  
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"Pirate Latitudes"];
  [aBook setAuthor:@"Michael Crichton"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"MockCovers/MichaelCrichton.png"]];
  [aBook setProgress:0.0f];
  [aBook setProportionateSize:0.54f];
  [aArray addObject:aBook];
  [aBook release];
  
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"The Girl With The Dragon Tatoo"];
  [aBook setAuthor:@"Stieg Larsson"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"MockCovers/StiegLarsson.png"]];
  [aBook setProgress:1.0f];
  [aBook setProportionateSize:0.62f];
  [aArray addObject:aBook];
  [aBook release];
  
  self.books = [NSArray arrayWithArray:aArray];
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.backgroundColor = [UIColor clearColor];
  
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationItem.title = @"Bookshelf";
  self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];  
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
  self.books = nil;
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
//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
//  return YES;
//}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
  [self.tableView reloadData];
}

- (UIToolbar *)toolbarForReadingView {
  UIToolbar *readingToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
  readingToolbar.barStyle = UIBarStyleBlackTranslucent;
  
  NSMutableArray *readingItems = [NSMutableArray array];
  UIBarButtonItem *item;
  
  item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  [readingItems addObject:item];
  [item release];
  
  item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-contents.png"]
                                          style:UIBarButtonItemStylePlain
                                         target:self 
                                         action:nil];
  [readingItems addObject:item];
  [item release];
  
  item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  [readingItems addObject:item];
  [item release];
  
  item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-plus.png"]
                                          style:UIBarButtonItemStylePlain
                                         target:self 
                                         action:@selector(showAddMenu:)];
  [readingItems addObject:item];
  [item release];
  
  item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  [readingItems addObject:item];
  [item release];  
  
  item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-search.png"]
                                          style:UIBarButtonItemStylePlain
                                         target:self 
                                         action:nil];
  [readingItems addObject:item];
  [item release];
  
  item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  [readingItems addObject:item];
  [item release];  
  
  UIImage *audioImage = nil;
  if (self.audioPlaying)
    audioImage = [UIImage imageNamed:@"icon-pause.png"];
  else 
    audioImage = [UIImage imageNamed:@"icon-play.png"];
    
  item = [[UIBarButtonItem alloc] initWithImage:audioImage
                                          style:UIBarButtonItemStylePlain
                                         target:self 
                                         action:@selector(toggleAudio:)];
  [readingItems addObject:item];
  [item release];
  
  item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  [readingItems addObject:item];
  [item release];
  
  item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-eye.png"]
                                          style:UIBarButtonItemStylePlain
                                         target:self 
                                         action:@selector(showViewSettings:)];
  [readingItems addObject:item];
  [item release];
  
  item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  [readingItems addObject:item];
  [item release];
  
  [readingToolbar setItems:[NSArray arrayWithArray:readingItems]];
  [readingToolbar sizeToFit];
  
  return [readingToolbar autorelease];
}

#pragma mark Table View Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  switch (self.libraryLayout) {
    case kBlioLibraryLayoutGrid: {
      NSInteger bookCount = [self.books count];
      NSInteger columnCount = self.columnCount;
      NSInteger rowCount = bookCount / columnCount;
      if (bookCount % columnCount) rowCount++;
      return rowCount;
    } break;
    default:
      return [self.books count];
      break;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  switch (self.libraryLayout) {
    case kBlioLibraryLayoutGrid:
        return kBlioLibraryGridRowHeight;
      break;
    default:
      return kBlioLibraryListRowHeight;
      break;
  }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  switch (self.libraryLayout) {
    case kBlioLibraryLayoutGrid: {
      static NSString *GridCellIdentifier = @"BlioLibraryGridCell";
      
      BlioLibraryGridCell *cell = (BlioLibraryGridCell *)[tableView dequeueReusableCellWithIdentifier:GridCellIdentifier];
      if (cell == nil) {
        cell = [[[BlioLibraryGridCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:GridCellIdentifier] autorelease];
      }  
      
      cell.books = self.books;
      cell.rowIndex = [indexPath row]; // N.B. currently these need to be set before the column count
      cell.delegate = self; // N.B. currently these need to be set before the column count
      cell.columnCount = self.columnCount;
      
      return cell;
    } break;
    default: {
      static NSString *ListCellOddIdentifier = @"BlioLibraryListCellOdd";
      static NSString *ListCellEvenIdentifier = @"BlioLibraryListCellEven";
      BlioLibraryListCell *cell;
      
      if ([indexPath row] % 2) {
        cell = (BlioLibraryListCell *)[tableView dequeueReusableCellWithIdentifier:ListCellEvenIdentifier];
        if (cell == nil) {
          cell = [[[BlioLibraryListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ListCellEvenIdentifier] autorelease];
        } 
        cell.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"row-light.png"]] autorelease];
      } else {   
        cell = (BlioLibraryListCell *)[tableView dequeueReusableCellWithIdentifier:ListCellOddIdentifier];
        if (cell == nil) {
          cell = [[[BlioLibraryListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ListCellOddIdentifier] autorelease];
        } 
        cell.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"row-dark.png"]] autorelease];
      }
      
      cell.book = [self.books objectAtIndex:[indexPath row]];
      cell.delegate = self;
      
      if ([indexPath row] % 2)
        cell.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"row-light.png"]] autorelease];
      else                         
        cell.backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"row-dark.png"]] autorelease];
                               
      return cell;
    } break;
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {    
  BlioMockBook *selectedBook = [self.books objectAtIndex:[indexPath row]];
  self.currentBookPath = [selectedBook bookPath];
  self.currentPdfPath = [selectedBook pdfPath];
  
  if (nil != self.currentBookPath) {
    EucEPubBook *book = [[EucEPubBook alloc] initWithPath:self.currentBookPath];
    EucBookViewController *bookViewController = [[EucBookViewController alloc] initWithBook:book];
    [(EucBookView *)bookViewController.bookView setAppearAtCoverThenOpen:YES];
    
    bookViewController.overriddenToolbar = [self toolbarForReadingView];
    
    bookViewController.toolbarsVisibleAfterAppearance = YES;
    [book release];
    [self.navigationController pushViewController:bookViewController animated:YES];
    [bookViewController release];
  } else if (nil != self.currentPdfPath) {
    BlioLayoutView *layoutView = [[BlioLayoutView alloc] initWithPath:self.currentPdfPath];    
    EucBookViewController *bookViewController = [[EucBookViewController alloc] initWithBookView:layoutView];
    [layoutView release];
    
    bookViewController.overriddenToolbar = [self toolbarForReadingView];    
    bookViewController.toolbarsVisibleAfterAppearance = YES;
    [self.navigationController pushViewController:bookViewController animated:YES];
    [bookViewController release];
  }
  
  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  if (self.libraryLayout == kBlioLibraryLayoutList)
    return YES;
  else
    return NO;
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
 // Delete the row from the data source.
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
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
#pragma mark BookController State Methods

- (BlioPageLayout)currentPageLayout {
  EucBookViewController *bookViewController = (EucBookViewController *)self.navigationController.topViewController;
  if([bookViewController.bookView isKindOfClass:[BlioLayoutView class]])
    return kBlioPageLayoutPageLayout;
  else
    return kBlioPageLayoutPlainText;
}

- (void)changePageLayout:(id)sender {
  
  BlioLibraryLayout newLayout = (BlioLibraryLayout)[sender selectedSegmentIndex];
  
  if([self currentPageLayout] != newLayout) {
    EucBookViewController *bookViewController = (EucBookViewController *)self.navigationController.topViewController;
    
    if (newLayout == kBlioPageLayoutPlainText && self.currentBookPath) {
      EucEPubBook *book = [[EucEPubBook alloc] initWithPath:self.currentBookPath];
      EucBookView *bookView = [[EucBookView alloc] initWithFrame:[[UIScreen mainScreen] bounds] 
                                                            book:book];
      bookViewController.bookView = bookView;
      [bookView release];
      [book release];
    } else if (newLayout == kBlioPageLayoutPageLayout && self.currentPdfPath) {
      BlioLayoutView *layoutView = [[BlioLayoutView alloc] initWithPath:self.currentPdfPath];
      bookViewController.bookView = layoutView;
      [layoutView release];
    }
  }
  
}

- (BOOL)shouldShowPageAttributeSettings {
  if ([self currentPageLayout] == kBlioPageLayoutPageLayout)
    return NO;
  else
    return YES;
}

- (BlioFontSize)currentFontSize {
  BlioFontSize fontSize = kBlioFontSizeMedium;
  if ([self currentPageLayout] == kBlioPageLayoutPlainText) {
    EucBookViewController *bookViewController = (EucBookViewController *)self.navigationController.topViewController;
    EucBookView *bookView = (EucBookView *)bookViewController.bookView;
    
    CGFloat actualFontSize = bookView.fontPointSize;
    CGFloat bestDifference = CGFLOAT_MAX;
    BlioFontSize bestFontSize = kBlioFontSizeMedium;
    for(BlioFontSize i = kBlioFontSizeVerySmall; i <= kBlioFontSizeVeryLarge; ++i) {
      CGFloat thisDifference = fabsf(kBlioFontPointSizeArray[i] - actualFontSize);
      if(thisDifference < bestDifference) {
        bestDifference = thisDifference;
        bestFontSize = i;
      }
    }
    fontSize = bestFontSize;
  } 
  return fontSize;
}

- (void)changeFontSize:(id)sender {
  BlioFontSize newSize = (BlioFontSize)[sender selectedSegmentIndex];
  if([self currentFontSize] != newSize) {
    if ([self currentPageLayout] == kBlioPageLayoutPlainText) {
      EucBookViewController *bookViewController = (EucBookViewController *)self.navigationController.topViewController;
      EucBookView *bookView = (EucBookView *)bookViewController.bookView;
      bookView.fontPointSize = kBlioFontPointSizeArray[newSize];
    }
    NSLog(@"Attempting to change to BlioFontSize: %d", newSize);
  }
}

- (BlioPageColor)currentPageColor {
  return kBlioPageColorWhite;
}

- (void)changePageColor:(id)sender {
  BlioPageColor newColor = (BlioPageColor)[sender selectedSegmentIndex];
  if([self currentPageColor] != newColor) {
    NSLog(@"Attempting to change to BlioPageColor: %d", newColor);
  }
}

- (BlioRotationLock)currentLockRotation {
  return kBlioRotationLockOff;
}

- (void)changeLockRotation:(id)sender {
  // This is just a placeholder check. Obviously we shouldn't be checking against the string.
  BlioRotationLock newLock = (BlioRotationLock)[[sender titleForSegmentAtIndex:[sender selectedSegmentIndex]] isEqualToString:@"Unlock Rotation"];
  if([self currentLockRotation] != newLock) {
    NSLog(@"Attempting to change to BlioRotationLock: %d", newLock);
  }
}

- (BlioTapTurn)currentTapTurn {
  return kBlioTapTurnOff;
}

- (void)changeTapTurn:(id)sender {
  // This is just a placeholder check. Obviously we shouldn't be checking against the string.
  BlioTapTurn newTapTurn = (BlioTapTurn)[[sender titleForSegmentAtIndex:[sender selectedSegmentIndex]] isEqualToString:@"Disable Tap Turn"];
  if([self currentTapTurn] != newTapTurn) {
    NSLog(@"Attempting to change to BlioTapTurn: %d", newTapTurn);
  }
}


#pragma mark -
#pragma mark Action Callback Methods

- (void)showAddMenu:(id)sender {
  UIActionSheet *aActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Add Bookmark", @"Add Notes", nil];
  aActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
  aActionSheet.delegate = self;
  UIToolbar *toolbar = (UIToolbar *)[(EucBookViewController *)self.navigationController.visibleViewController overriddenToolbar];
  [aActionSheet showFromToolbar:toolbar];
  [aActionSheet release];
}

- (void)showViewSettings:(id)sender {
  BlioViewSettingsSheet *aSettingsSheet = [[BlioViewSettingsSheet alloc] initWithDelegate:self];
  UIToolbar *toolbar = (UIToolbar *)[(EucBookViewController *)self.navigationController.visibleViewController overriddenToolbar];
  [aSettingsSheet showFromToolbar:toolbar];
  [aSettingsSheet release];
}

- (void)dismissViewSettings:(id)sender {
  [self dismissModalViewControllerAnimated:YES];
}

- (void)toggleAudio:(id)sender {
  if ([self currentPageLayout] == kBlioPageLayoutPlainText) {
    EucBookViewController *bookViewController = (EucBookViewController *)self.navigationController.topViewController;
    EucBookView *bookView = (EucBookView *)bookViewController.bookView;
    
    UIBarButtonItem *item = (UIBarButtonItem *)sender;
    
    UIImage *audioImage = nil;
    if (self.audioPlaying) {
      [_testParagraphWords stopParagraphGetting];
      [_testParagraphWords release];
      _testParagraphWords = nil;
      
      [_acapelaTTS stopSpeaking];
      audioImage = [UIImage imageNamed:@"icon-play.png"];
    } else { 
      EucEPubBook *book = (EucEPubBook*)bookView.book;
      uint32_t paragraphId, wordOffset;
      [book getCurrentParagraphId:&paragraphId wordOffset:&wordOffset];
      _testParagraphWords = [[BlioTestParagraphWords alloc] init];
      [_testParagraphWords startParagraphGettingFromBook:book atParagraphWithId:paragraphId];
      
      if (_acapelaTTS == nil) {
        _acapelaTTS = [[AcapelaTTS alloc] init];
        [_acapelaTTS initTTS];
      }
      [_acapelaTTS setRate:180];  // Will get from settings.
      [_acapelaTTS setVolume:70];  // Likewise.
      [_acapelaTTS startSpeaking:@"Hello my name is Laura.  I hope you like my voice because you're stuck with it."];
      audioImage = [UIImage imageNamed:@"icon-pause.png"];
    }
    self.audioPlaying = !self.audioPlaying;
    [item setImage:audioImage];
  }
}

- (void)changeLibraryLayout:(id)sender {
  
  BlioLibraryLayout newLayout = (BlioLibraryLayout)[sender selectedSegmentIndex];
  
  if (self.libraryLayout != newLayout) {
    self.libraryLayout = newLayout;
    
    switch (newLayout) {
      case kBlioLibraryLayoutGrid:
        [self.tableView setBackgroundColor:[UIColor clearColor]];
        break;
      default:
        if ([self.books count] % 2)
          [self.tableView setBackgroundColor:[UIColor whiteColor]];
        else
          [self.tableView setBackgroundColor:[UIColor colorWithRed:0.882f green:0.882f blue:0.906f alpha:1.0f]];
        break;
    }
    
    [self.tableView reloadData];
  }

}

- (void)bookTouched:(BlioLibraryBookView *)bookView {
  bookView.alpha = 0.0f;
  UIView *targetView = self.navigationController.view;
  
  UIView *poppedImageView = [[UIView alloc] initWithFrame:[[bookView superview] convertRect:[bookView frame] toView:targetView]];
  poppedImageView.backgroundColor = [UIColor clearColor];
  UIImage *bookImage = [[bookView book] coverImage];
  
  CGFloat xInset = poppedImageView.bounds.size.width * kBlioLibraryShadowXInset;
  CGFloat yInset = poppedImageView.bounds.size.height * kBlioLibraryShadowYInset;
  CGRect insetFrame = CGRectInset(poppedImageView.bounds, xInset, yInset);
  UIImageView *aImageView = [[UIImageView alloc] initWithFrame:insetFrame];
  aImageView.contentMode = UIViewContentModeScaleToFill;
  aImageView.image = bookImage;
  aImageView.backgroundColor = [UIColor clearColor];
  aImageView.autoresizesSubviews = YES;
  aImageView.autoresizingMask = 
    UIViewAutoresizingFlexibleLeftMargin  |
    UIViewAutoresizingFlexibleWidth       |
    UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleTopMargin   |
    UIViewAutoresizingFlexibleHeight      |
    UIViewAutoresizingFlexibleBottomMargin;
  
  [poppedImageView addSubview:aImageView];
  
  UIImageView *aTextureView = [[UIImageView alloc] initWithFrame:poppedImageView.bounds];
  aTextureView.contentMode = UIViewContentModeScaleToFill;
  aTextureView.image = [UIImage imageNamed:@"booktextureandshadow.png"];
  aTextureView.backgroundColor = [UIColor clearColor];
  aTextureView.autoresizesSubviews = YES;
  aTextureView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [poppedImageView addSubview:aTextureView];
  
  [targetView addSubview:poppedImageView];
  
  [UIView beginAnimations:@"popBook" context:poppedImageView];
  [aImageView release];
  [UIView setAnimationDuration:0.65f];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(popBookDidStop:finished:context:)];
  [UIView setAnimationWillStartSelector:@selector(popBookWillStart:context:)];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
  
  CGFloat widthRatio = (targetView.frame.size.width)/aImageView.frame.size.width;
  CGFloat heightRatio = (targetView.frame.size.height)/aImageView.frame.size.height;
  
  CGSize poppedSize = CGSizeMake(poppedImageView.frame.size.width * widthRatio, poppedImageView.frame.size.height * heightRatio);
  CGRect poppedRect = CGRectIntegral(CGRectMake((targetView.frame.size.width-poppedSize.width)/2.0f, (targetView.frame.size.height-poppedSize.height)/2.0f, poppedSize.width, poppedSize.height));
  [poppedImageView setFrame:poppedRect];
  [self.tableView setAlpha:0.0f];
  [aTextureView setAlpha:0.0f];
 
  [UIView commitAnimations];
  
  [aTextureView release];
  [poppedImageView release];
  
  self.currentBookView = bookView;
}

- (void)popBookWillStart:(NSString *)animationID context:(void *)context {
  [[UIApplication sharedApplication] setStatusBarHidden:YES animated:YES];
  [self.tableView setUserInteractionEnabled:NO];
}

- (void)popBookDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
  if (finished) {
    [UIView beginAnimations:@"fadeBook" context:context];
    [UIView setAnimationDuration:0.5f];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(fadeBookDidStop:finished:context:)];
    [(UIView *)context setAlpha:0.0f];
    [UIView commitAnimations];
    
    [self.currentBookView setAlpha:1.0f];
    [self.tableView setUserInteractionEnabled:YES];
    [self.tableView setAlpha:1.0f];
    [[UIApplication sharedApplication] setStatusBarHidden:NO animated:YES];

    BlioMockBook *currentBook = [self.currentBookView book];
    self.currentBookPath = [currentBook bookPath];
    self.currentPdfPath = [currentBook pdfPath];
    
    if (nil != self.currentBookPath) {
      [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
      
      EucEPubBook *book = [[EucEPubBook alloc] initWithPath:self.currentBookPath];
      EucBookViewController *bookViewController = [[EucBookViewController alloc] initWithBook:book];
      [(EucBookView *)bookViewController.bookView setAppearAtCoverThenOpen:YES];
      
      bookViewController.overriddenToolbar = [self toolbarForReadingView];
      bookViewController.toolbarsVisibleAfterAppearance = YES;
      [book release];
      [self.navigationController pushViewController:bookViewController animated:NO];
      [bookViewController release];
    }

  }
}

- (void)fadeBookDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
  [(UIView *)context removeFromSuperview];
}

@end

@implementation BlioLibraryTableView

- (void)drawRect:(CGRect)rect {
  if ([self.backgroundColor isEqual:[UIColor clearColor]]) {
    UIImage *image = [UIImage imageNamed: @"librarybackground.png"];
	  [image drawInRect:rect];
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
    aTextureView.image = [UIImage imageNamed:@"booktextureandshadow.png"];
    aTextureView.backgroundColor = [UIColor clearColor];
    aTextureView.alpha = 0.0f;
    aTextureView.userInteractionEnabled = NO;
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
    [self insertSubview:aImageView belowSubview:self.textureView];
    self.imageView = aImageView;
    [aImageView release];
    
    UIView *aHighlightView = [[UIView alloc] initWithFrame:insetFrame];
    aHighlightView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
    aHighlightView.alpha = 0.0f;
    aHighlightView.userInteractionEnabled = NO;
    [self insertSubview:aHighlightView aboveSubview:self.imageView];
    self.highlightView = aHighlightView;
    [aHighlightView release];
    
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
  [newBook retain];
  [book release];
  book = newBook;
  
  UIImage *newImage = [newBook coverThumb];
  [[self imageView] setImage:newImage];
  
  if (nil != newImage) 
    self.textureView.alpha = 1.0f;
  else
    self.textureView.alpha = 0.0f;
  
  [[self imageView] setNeedsDisplay];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
  self.highlightView.alpha = 1.0f;
  return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
  self.highlightView.alpha = 0.0f;
}

@end

@implementation BlioLibraryGridCell

@synthesize rowIndex;
@synthesize books;
@synthesize bookViews;
@synthesize bookSize;
@synthesize bookOrigin;
@synthesize columnCount;
@synthesize delegate;

- (void)dealloc {
  self.books = nil;
  self.bookViews = nil;
  self.delegate = nil;
  [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
    // Initialization code
    self.bookViews = [NSMutableArray array];
    self.bookSize = CGSizeMake(kBlioLibraryGridBookWidth, kBlioLibraryGridBookHeight);
    self.bookOrigin = CGPointMake(kBlioLibraryGridBookSpacing, kBlioLibraryGridBookSpacing);
    self.columnCount = 0;
    self.rowIndex = 0;
    self.delegate = nil;
    self.opaque = NO;
    self.accessoryType = UITableViewCellAccessoryNone;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  return self;
}

- (void)layoutBookViews {
  CGRect bookFrame = CGRectMake(self.bookOrigin.x, self.bookOrigin.y,
                                self.bookSize.width, self.bookSize.height);
  
  for (UIView* bookView in self.bookViews) {
    bookView.frame = bookFrame;
    bookFrame.origin.x += kBlioLibraryGridBookSpacing + self.bookSize.width;
    [bookView setNeedsDisplay];
  }
}

- (void)assignBookAtIndex:(NSUInteger)index toView:(BlioLibraryBookView *)bookView {
  if (index < [self.books count]) {
    BlioMockBook *book = [self.books objectAtIndex:index];
    [bookView setBook:book];
  } else {
    [bookView setBook:nil];
  }
}

- (void)layoutSubviews {
  [super layoutSubviews];
  [self layoutBookViews];
}

- (void)setBookSize:(CGSize)newBookSize {
  bookSize = newBookSize;
  [self setNeedsLayout];
}

- (void)setBookOrigin:(CGPoint)newBookOrigin {
  bookOrigin = newBookOrigin;
  [self setNeedsLayout];  
}

- (void)setColumnCount:(NSInteger)newColumnCount {
  if (columnCount != newColumnCount) {
    for (UIView* bookView in self.bookViews) {
      [bookView removeFromSuperview];
    }
    [self.bookViews removeAllObjects];
    
    columnCount = newColumnCount;
    
    for (NSInteger i = [self.bookViews count]; i < columnCount; ++i) {
      BlioLibraryBookView* bookView = [[[BlioLibraryBookView alloc] init] autorelease];
      [bookView addTarget:self.delegate action:@selector(bookTouched:)
         forControlEvents:UIControlEventTouchUpInside];
      [self.contentView addSubview:bookView];
      [self assignBookAtIndex:(self.rowIndex*columnCount)+i toView:bookView];
      [self.bookViews addObject:bookView];
    }
  } else {
    for (NSInteger i = 0; i < [self.bookViews count]; ++i) {
      BlioLibraryBookView* bookView = [self.bookViews objectAtIndex:i];
      [self assignBookAtIndex:(self.rowIndex*columnCount)+i toView:bookView];
    }
  }
  
  CGFloat xOrigin = (self.bounds.size.width - (columnCount * (kBlioLibraryGridBookSpacing + self.bookSize.width)))/2.0f;
  
  if (xOrigin < 0) {
    CGFloat maxWidth = (self.bounds.size.width - (columnCount * kBlioLibraryGridBookSpacing))/columnCount;
    CGFloat ratio = maxWidth / self.bookSize.width;
    self.bookSize = CGSizeMake(self.bookSize.width * ratio, self.bookSize.height * ratio);
    xOrigin = (self.bounds.size.width - (columnCount * (kBlioLibraryGridBookSpacing + self.bookSize.width)))/2.0f;
  }
  
  CGFloat yOrigin = kBlioLibraryGridBookSpacing;
  self.bookOrigin = CGPointMake(xOrigin, yOrigin);
  [self setNeedsLayout];  
}

@end

@implementation BlioLibraryListCell

@synthesize bookView, titleLabel, authorLabel, progressSlider, delegate;

- (void)dealloc {
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
    [aBookView addTarget:self.delegate action:@selector(bookTouched:)
       forControlEvents:UIControlEventTouchUpInside];
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
    UIImage *minImage = [[UIImage imageNamed:@"minimum-progress.png"] stretchableImageWithLeftCapWidth:2 topCapHeight:0];
//    UIImage *maxImage = [[UIImage imageNamed:@"maximum-progress.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
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

- (BlioMockBook *)book {
  return [(BlioLibraryBookView *)self.bookView book];
}

- (void)setBook:(BlioMockBook *)newBook {
  [(BlioLibraryBookView *)self.bookView setBook:newBook];
  self.titleLabel.text = [newBook title];
  self.authorLabel.text = [[newBook author] uppercaseString];
  self.progressSlider.value = [newBook progress];
  CGRect progressFrame = self.progressSlider.frame;
  self.progressSlider.frame = CGRectMake(progressFrame.origin.x, progressFrame.origin.y, [newBook proportionateSize] * kBlioLibraryListContentWidth, progressFrame.size.height);
  [self setNeedsLayout];
}

- (void)setDelegate:(id)newDelegate {
  [self.bookView removeTarget:delegate action:@selector(bookTouched:)
      forControlEvents:UIControlEventTouchUpInside];
  
  delegate = newDelegate;
  [self.bookView addTarget:delegate action:@selector(bookTouched:)
      forControlEvents:UIControlEventTouchUpInside];
}

@end


