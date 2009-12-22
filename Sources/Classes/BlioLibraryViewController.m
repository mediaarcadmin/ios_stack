//
//  RootViewController.m
//  BlioApp
//
//  Created by James Montgomerie on 16/12/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//

#import "BlioLibraryViewController.h"
#import <libEucalyptus/EucEPubBook.h>
#import <libEucalyptus/EucBookViewController.h>
#import "BlioLayoutView.h"
#import "BlioMockBook.h"

static const CGFloat kLibraryRowHeight = 140;
static const CGFloat kBookHeight = 140;
static const CGFloat kBookWidth = 102;
static const CGFloat kBookSpacing = 0;
static const CGFloat kBlioShadowXInset = 0.10276f; // Nasty hack to work out proportion of texture image is shadow
static const CGFloat kBlioShadowYInset = 0.07737f;

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

@interface BlioLibraryCell : UITableViewCell {
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

@implementation BlioLibraryViewController

@synthesize currentBookView = _currentBookView;
@synthesize currentBookPath = _currentBookPath;
@synthesize currentPdfPath = _currentPdfPath;
@synthesize books = _books;

- (void)dealloc {
  self.currentBookView = nil;
  self.currentBookPath = nil;
  self.currentPdfPath = nil;
  self.books = nil;
  [super dealloc];
}

- (void)loadView {
  // UITableView subclass so that custom background is only drawn here
  BlioLibraryTableView *aTableView = [[BlioLibraryTableView alloc] initWithFrame:CGRectMake(0,0,320,480-20) style:UITableViewStylePlain];
  self.tableView = aTableView;
  [aTableView release];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
  // self.navigationItem.rightBarButtonItem = self.editButtonItem;
  
  NSMutableArray *aArray = [NSMutableArray array];
  BlioMockBook *aBook = nil;
  
  NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
  
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"Dead Is So Last Year"];
  [aBook setAuthor:@"Marlene Perez"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"ePubs/Dead Is So Last Year.epub/OPS/cover.png"]];
  [aBook setBookPath:[[NSBundle mainBundle] pathForResource:@"Dead Is So Last Year" ofType:@"epub" inDirectory:@"ePubs"]];
  [aBook setPdfPath:[[NSBundle mainBundle] pathForResource:@"Dead Is So Last Year" ofType:@"pdf" inDirectory:@"PDFs"]];
  [aArray addObject:aBook];
  [aBook release];
  
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"Exiles In The Garden"];
  [aBook setAuthor:@"Ward Just"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"ePubs/Exiles In The Garden.epub/OPS/cover.png"]];
  [aBook setBookPath:[[NSBundle mainBundle] pathForResource:@"Exiles In The Garden" ofType:@"epub" inDirectory:@"ePubs"]];
  [aBook setPdfPath:[[NSBundle mainBundle] pathForResource:@"Exiles In The Garden" ofType:@"pdf" inDirectory:@"PDFs"]];
  [aArray addObject:aBook];
  [aBook release];
  
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"The Oz Principle"];
  [aBook setAuthor:@"Roger Conners"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"MockCovers/RogerConnors.png"]];
  [aArray addObject:aBook];
  [aBook release];
   
   
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"How To Be A Movie Star"];
  [aBook setAuthor:@"William Mann"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"MockCovers/WilliamMann.png"]];
  [aArray addObject:aBook];
  [aBook release];
  
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"Her Fearful Symmetry"];
  [aBook setAuthor:@"Audrey Niffenegger"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"MockCovers/AudreyNiffenegger.png"]];
  [aArray addObject:aBook];
  [aBook release];
  
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"The Lost Symbol"];
  [aBook setAuthor:@"Dan Brown"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"MockCovers/DanBrown.png"]];
  [aArray addObject:aBook];
  [aBook release];
  
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"Hostage"];
  [aBook setAuthor:@"Don Brown"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"MockCovers/DonBrown.png"]];
  [aArray addObject:aBook];
  [aBook release];
  
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"I, Alex Cross"];
  [aBook setAuthor:@"James Patterson"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"MockCovers/JamesPatterson.png"]];
  [aArray addObject:aBook];
  [aBook release];
  
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"Diary of a Wimpy Kid, Dog Days"];
  [aBook setAuthor:@"Jeff Kinney"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"MockCovers/JeffKinney.png"]];
  [aArray addObject:aBook];
  [aBook release];
  
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"Pirate Latitudes"];
  [aBook setAuthor:@"Michael Crichton"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"MockCovers/MichaelCrichton.png"]];
  [aArray addObject:aBook];
  [aBook release];
  
  aBook = [[BlioMockBook alloc] init];
  [aBook setTitle:@"The Girl With The Dragon Tatoo"];
  [aBook setAuthor:@"Stieg Larsson"];
  [aBook setCoverPath:[resourcePath stringByAppendingPathComponent:@"MockCovers/StiegLarsson.png"]];
  [aArray addObject:aBook];
  [aBook release];
  
  self.books = [NSArray arrayWithArray:aArray];
  [self.tableView setRowHeight:180];
  self.tableView.rowHeight = kLibraryRowHeight;
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
  return round((bounds.size.width - kBookSpacing*2) / (kBookWidth+kBookSpacing));
}

// Override to allow orientations other than the default portrait orientation.
//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
//  return YES;
//}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
  [self.tableView reloadData];
}

#pragma mark -
#pragma mark Action Callbacks

- (void)toggleBookView
{
  EucBookViewController *bookViewController = (EucBookViewController *)self.navigationController.topViewController;
  if([bookViewController.bookView isKindOfClass:[BlioLayoutView class]]) {
    EucEPubBook *book = [[EucEPubBook alloc] initWithPath:self.currentBookPath];
    EucBookView *bookView = [[EucBookView alloc] initWithFrame:[[UIScreen mainScreen] bounds] 
                                                          book:book];
    bookViewController.bookView = bookView;
    [bookView release];
    [book release];
  } else {
    BlioLayoutView *layoutView = [[BlioLayoutView alloc] initWithPath:self.currentPdfPath];
    bookViewController.bookView = layoutView;
    [layoutView release];
  }
}

- (void)bookTouched:(BlioLibraryBookView *)bookView {
  bookView.alpha = 0.0f;
  UIView *targetView = self.navigationController.view;
  
  UIView *poppedImageView = [[UIView alloc] initWithFrame:[[bookView superview] convertRect:[bookView frame] toView:targetView]];
  poppedImageView.backgroundColor = [UIColor clearColor];
  UIImage *bookImage = [bookView image];
  
  CGFloat xInset = poppedImageView.bounds.size.width * kBlioShadowXInset;
  CGFloat yInset = poppedImageView.bounds.size.height * kBlioShadowYInset;
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
      UIToolbar *emptyToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
      emptyToolbar.barStyle = UIBarStyleBlack;
      emptyToolbar.translucent = YES;
      UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                            target:self 
                                                                            action:@selector(toggleBookView)];
      emptyToolbar.items = [NSArray arrayWithObject:item];
      [item release];
      [emptyToolbar sizeToFit];
      bookViewController.overriddenToolbar = emptyToolbar;
      [emptyToolbar release];      
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

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSInteger bookCount = [self.books count];
  NSInteger columnCount = self.columnCount;
  NSInteger rowCount = bookCount / columnCount;
  if (bookCount % columnCount) rowCount++;
  return rowCount;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  static NSString *CellIdentifier = @"BlioLibraryCell";
  
  BlioLibraryCell *cell = (BlioLibraryCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[BlioLibraryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}  
  
  cell.books = self.books;
  cell.rowIndex = [indexPath row]; // N.B. currently these need to be set before the column count
  cell.delegate = self; // N.B. currently these need to be set before the column count
  cell.columnCount = self.columnCount;

  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {    
    switch (indexPath.row) {
        case 0:
        case 2:
            self.currentBookPath = [[NSBundle mainBundle] pathForResource:@"Dead Is So Last Year" ofType:@"epub" inDirectory:@"ePubs"];
            self.currentPdfPath = [[NSBundle mainBundle] pathForResource:@"Dead Is So Last Year" ofType:@"pdf" inDirectory:@"PDFs"];
            break;
        case 1:
        case 3:
            self.currentBookPath = [[NSBundle mainBundle] pathForResource:@"Exiles In The Garden" ofType:@"epub" inDirectory:@"ePubs"];
            self.currentPdfPath = [[NSBundle mainBundle] pathForResource:@"Exiles In The Garden" ofType:@"pdf" inDirectory:@"PDFs"];
            break;
        default:
            break;
    }
    
    if(indexPath.row < 2) {
        EucEPubBook *book = [[EucEPubBook alloc] initWithPath:self.currentBookPath];
        EucBookViewController *bookViewController = [[EucBookViewController alloc] initWithBook:book];
        bookViewController.toolbarsVisibleAfterAppearance = YES;
        [book release];
        [self.navigationController pushViewController:bookViewController animated:YES];
        [bookViewController release];
    } else {
//        BlioLayoutView *layoutView = [[BlioLayoutView alloc] initWithPath:self.currentPdfPath];
//        UIViewController *vC = [[UIViewController alloc] init];
//        vC.view = layoutView;
//        [layoutView release];
//        [self.navigationController pushViewController:vC animated:YES];
//        [vC release];
      
      BlioLayoutView *layoutView = [[BlioLayoutView alloc] initWithPath:self.currentPdfPath];
      layoutView.navigationController = self.navigationController;
      [[self.navigationController navigationBar] setBarStyle:UIBarStyleBlackTranslucent];
      [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:NO];
      UIViewController *viewController = [[UIViewController alloc] init];
      viewController.view = layoutView;
      viewController.wantsFullScreenLayout = YES;
      [layoutView release];
      [self.navigationController pushViewController:viewController animated:YES];
      [viewController release];
      
      /*
        EucBookViewController *bookViewController = [[EucBookViewController alloc] initWithBookView:layoutView];

        UIToolbar *emptyToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
        emptyToolbar.barStyle = UIBarStyleBlack;
        emptyToolbar.translucent = YES;
        
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                              target:self 
                                                                              action:@selector(toggleBookView)];
        emptyToolbar.items = [NSArray arrayWithObject:item];
        [item release];
        [emptyToolbar sizeToFit];
        
        bookViewController.overriddenToolbar = emptyToolbar;
        [emptyToolbar release];
        bookViewController.toolbarsVisibleAfterAppearance = YES;
        [layoutView release];
        [self.navigationController pushViewController:bookViewController animated:YES];
        [bookViewController release];
       */
    }
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


@end

@implementation BlioLibraryTableView

- (void)drawRect:(CGRect)rect {
  UIImage *image = [UIImage imageNamed: @"librarybackground.png"];
	[image drawInRect:rect];
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
    
    CGFloat xInset = self.bounds.size.width * kBlioShadowXInset;
    CGFloat yInset = self.bounds.size.height * kBlioShadowYInset;
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
  CGFloat xInset = self.textureView.bounds.size.width * kBlioShadowXInset;
  CGFloat yInset = self.textureView.bounds.size.height * kBlioShadowYInset;
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
  
  UIImage *newImage = [newBook coverImage];
  [[self imageView] setImage:newImage];
  
  if (nil != newImage) 
    self.textureView.alpha = 1.0f;
  else
    self.textureView.alpha = 0.0f;
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
  self.highlightView.alpha = 1.0f;
  return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
  self.highlightView.alpha = 0.0f;
}

@end

@implementation BlioLibraryCell

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
    self.bookSize = CGSizeMake(kBookWidth, kBookHeight);
    self.bookOrigin = CGPointMake(kBookSpacing, kBookSpacing);
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
    bookFrame.origin.x += kBookSpacing + self.bookSize.width;
  }
}

- (void)assignBookAtIndex:(NSUInteger)index toView:(BlioLibraryBookView *)bookView {
  if (index < [self.books count]) {
    BlioMockBook *book = [self.books objectAtIndex:index];
    [bookView setBook:book];
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
  }
  
  CGFloat xOrigin = (self.bounds.size.width - (columnCount * (kBookSpacing + self.bookSize.width)))/2.0f;
  
  if (xOrigin < 0) {
    CGFloat maxWidth = (self.bounds.size.width - (columnCount * kBookSpacing))/columnCount;
    CGFloat ratio = maxWidth / self.bookSize.width;
    self.bookSize = CGSizeMake(self.bookSize.width * ratio, self.bookSize.height * ratio);
    xOrigin = (self.bounds.size.width - (columnCount * (kBookSpacing + self.bookSize.width)))/2.0f;
  }
  
  CGFloat yOrigin = kBookSpacing;
  self.bookOrigin = CGPointMake(xOrigin, yOrigin);
  [self setNeedsLayout];  
}

@end


