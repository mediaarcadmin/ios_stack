//
//  RootViewController.m
//  BlioApp
//
//  Created by James Montgomerie on 16/12/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "BlioLibraryViewController.h"
#import "BlioBookViewController.h"
#import "BlioEPubView.h"
#import "BlioLayoutView.h"
#import "BlioMockBook.h"
#import "BlioUIImageAdditions.h"
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

- (void)setBook:(BlioMockBook *)newBook forLayout:(BlioLibraryLayout)layout;

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
@synthesize currentPoppedBookCover = _currentPoppedBookCover;
@synthesize books = _books;
@synthesize libraryLayout = _libraryLayout;
@synthesize bookCoverPopped = _bookCoverPopped;
@synthesize firstPageRendered = _firstPageRendered;

- (void)dealloc {
    self.currentBookView = nil;
    self.books = nil;
    self.tableView = nil;
    self.currentPoppedBookCover = nil;
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
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.libraryLayout = kBlioLibraryLayoutGrid;
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    UIEdgeInsets inset = UIEdgeInsetsMake(3, 0, 0, 0);
    
    NSArray *segmentImages = [NSArray arrayWithObjects:
                              [UIImage imageWithShadow:[UIImage imageNamed:@"button-grid.png"] inset:inset],
                              [UIImage imageWithShadow:[UIImage imageNamed:@"button-list.png"] inset:inset],
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
    [aBook setBookPath:[[NSBundle mainBundle] pathForResource:@"Essentials_of_Discrete_Mathematics" ofType:@"epub" inDirectory:@"ePubs"]];
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
    
    UIImage *logoImage = [UIImage appleLikeBeveledImage:[UIImage imageNamed:@"logo-white.png"]];
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:logoImage];
    self.navigationItem.titleView = logoImageView;
    [logoImageView release];
    
    [self.navigationController setToolbarHidden:NO];
    UIColor *tintColor = [UIColor colorWithRed:160.0f / 256.0f green:190.0f / 256.0f  blue:190.0f / 256.0f  alpha:1.0f];
    self.navigationController.toolbar.tintColor = tintColor;
    self.navigationController.navigationBar.tintColor = tintColor;
}

/*
- (void)viewDidAppear:(BOOL)animated {
    UIToolbar *toolbar = self.navigationController.toolbar;
    toolbar.barStyle = UIBarStyleDefault;
    toolbar.tintColor = [UIColor colorWithRed:160.0f / 256.0f green:190.0f / 256.0f  blue:190.0f / 256.0f  alpha:1.0f];
}
*/

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
 /*   BlioMockBook *selectedBook = [self.books objectAtIndex:[indexPath row]];
    self.currentBookPath = [selectedBook bookPath];
    self.currentPdfPath = [selectedBook pdfPath];
    
    if (nil != self.currentBookPath) {
        EucEPubBook *book = [[EucEPubBook alloc] initWithPath:self.currentBookPath];
        BlioBookViewController *bookViewController = [[BlioBookViewController alloc] initWithBook:book];
        [(BlioEPubView *)bookViewController.bookView setAppearAtCoverThenOpen:YES];
        
        bookViewController.overriddenToolbar = [self toolbarForReadingView];
        
        bookViewController.toolbarsVisibleAfterAppearance = YES;
        [book release];
        [self.navigationController pushViewController:bookViewController animated:YES];
        [bookViewController release];
    } else if (nil != self.currentPdfPath) {
        BlioLayoutView *layoutView = [[BlioLayoutView alloc] initWithPath:self.currentPdfPath];    
        BlioBookViewController *bookViewController = [[BlioBookViewController alloc] initWithBookView:layoutView];
        [layoutView release];
        
        bookViewController.overriddenToolbar = [self toolbarForReadingView];    
        bookViewController.toolbarsVisibleAfterAppearance = YES;
        [self.navigationController pushViewController:bookViewController animated:YES];
        [bookViewController release];
    }
    */
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
#pragma mark Library Actions

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
    
    CGFloat widthRatio = (targetView.frame.size.width)/aCoverImageView.frame.size.width;
    CGFloat heightRatio = (targetView.frame.size.height)/aCoverImageView.frame.size.height;
    
    CGSize poppedSize = CGSizeMake(poppedImageView.frame.size.width * widthRatio, poppedImageView.frame.size.height * heightRatio);
    CGRect poppedRect = CGRectIntegral(CGRectMake((targetView.frame.size.width-poppedSize.width)/2.0f, (targetView.frame.size.height-poppedSize.height)/2.0f, poppedSize.width, poppedSize.height));
    
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
        
        CGRect coverRect = [[UIScreen mainScreen] bounds];
        BOOL shrinkCover = NO;
        
        if (nil != bookViewController) {
            self.navigationController.navigationBarHidden = YES; // We already animated the cover over it.
            coverRect = [[bookViewController bookView] firstPageRect];
            if (!CGRectEqualToRect([[UIScreen mainScreen] bounds], coverRect)) shrinkCover = YES;
            
            bookViewController.toolbarsVisibleAfterAppearance = !shrinkCover;
            bookViewController.returnToNavigationBarHidden = NO;
            bookViewController.returnToStatusBarStyle = UIStatusBarStyleDefault;
            [self.navigationController pushViewController:bookViewController animated:NO];
            
            [bookViewController release];
        }
        
        if (!shrinkCover) {
            self.bookCoverPopped = YES;
            self.firstPageRendered = YES;
            [(UIView *)context removeFromSuperview];
        } else {            
            [UIView beginAnimations:@"shrinkBook" context:context];
            [UIView setAnimationDuration:0.35f];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(shrinkBookDidStop:finished:context:)];
            [self.currentPoppedBookCover setBounds:CGRectMake(0,0, coverRect.size.width, coverRect.size.height)];
            [UIView commitAnimations];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blioCoverPageDidFinishRender:) name:@"blioCoverPageDidFinishRender" object:nil];
        }            
            
    }
}

- (void)blioCoverPageDidFinishRender:(NSNotification *)notification {
    self.firstPageRendered = YES;
    
    if (self.bookCoverPopped) {
        [self performSelectorOnMainThread:@selector(removeShrinkBookAnimation:) withObject:[self.currentPoppedBookCover superview] waitUntilDone:YES];
    
        self.currentPoppedBookCover = nil;
    }
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

- (void)fadeBookDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    if ([(UIView *)context superview])
        [(UIView *)context removeFromSuperview];
}

- (void)shrinkBookDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    self.bookCoverPopped = YES;
    
    if (self.firstPageRendered) {
        [self performSelector:@selector(removeShrinkBookAnimation:) withObject:(UIView *)context afterDelay:0.5f];
        self.currentPoppedBookCover = nil;
    }
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
        aTextureView.image = [UIImage imageNamed:@"booktextureandshadowsubtle.png"];
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
        [bookView setBook:book forLayout:kBlioLibraryLayoutGrid];
    } else {
        [bookView setBook:nil forLayout:kBlioLibraryLayoutGrid];
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

- (BlioMockBook *)book {
    return [(BlioLibraryBookView *)self.bookView book];
}

- (void)setBook:(BlioMockBook *)newBook {
    [(BlioLibraryBookView *)self.bookView setBook:newBook forLayout:kBlioLibraryLayoutList];
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


