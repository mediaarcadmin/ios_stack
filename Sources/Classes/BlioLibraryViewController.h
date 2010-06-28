//
//  RootViewController.h
//  BlioApp
//
//  Created by James Montgomerie on 16/12/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "MRGridView.h"
#import "BlioBook.h"

@class BlioTestBlockWords;

typedef enum {
    kBlioLibraryLayoutUndefined = -1,
    kBlioLibraryLayoutGrid = 0,
    kBlioLibraryLayoutList = 1,
} BlioLibraryLayout;

typedef enum {
    kBlioLibrarySortTypePersonalized = 0,
    kBlioLibrarySortTypeTitle = 1,
    kBlioLibrarySortTypeAuthor = 2,
} BlioLibrarySortType;

static const CGFloat kBlioLibraryToolbarHeight = 44;

static const CGFloat kBlioLibraryListRowHeight = 76;
static const CGFloat kBlioLibraryListBookHeight = 76;
static const CGFloat kBlioLibraryListBookWidth = 53;
static const CGFloat kBlioLibraryListContentWidth = 220;
static const CGFloat kBlioLibraryListProgressViewWidth = 150;

static const CGFloat kBlioLibraryGridRowHeight = 140;
static const CGFloat kBlioLibraryGridBookHeight = 140;
static const CGFloat kBlioLibraryGridBookWidth = 106;
static const CGFloat kBlioLibraryGridBookHeightPad = 210;
static const CGFloat kBlioLibraryGridBookWidthPad = 140;
static const CGFloat kBlioLibraryGridProgressViewWidth = 60;
static const CGFloat kBlioLibraryGridBookSpacing = 0;
static const CGFloat kBlioLibraryGridBookSpacingPad = 40;

static const CGFloat kBlioLibraryLayoutButtonWidth = 78;
static const CGFloat kBlioLibraryShadowXInset = 0.10276f; // Nasty hack to work out proportion of texture image is shadow
static const CGFloat kBlioLibraryShadowYInset = 0.07737f;

static const CGFloat kBlioProportionalProgressBarInsetX = 3;
static const CGFloat kBlioProportionalProgressBarInsetY = 3;

@class BlioLibraryBookView;
@class BlioLibraryListCell;
@class BlioLibraryGridViewCell;

@protocol BlioProcessingDelegate;

#undef BLIO_POPOVERCONTROLLER_DELEGATE
#if TARGET_OS_IPHONE && (__IPHONE_OS_VERSION_MAX_ALLOWED >= 30200)
#define BLIO_POPOVERCONTROLLER_DELEGATE UIPopoverControllerDelegate
#else
#define BLIO_POPOVERCONTROLLER_DELEGATE
#endif

#undef POPOVERCONTROLLER_DELEGATE_DELIMITER
#if TARGET_OS_IPHONE && (__IPHONE_OS_VERSION_MAX_ALLOWED >= 30200)
#define POPOVERCONTROLLER_DELEGATE_DELIMITER ,
#else
#define POPOVERCONTROLLER_DELEGATE_DELIMITER
#endif


@interface BlioLibraryViewController : UIViewController <NSFetchedResultsControllerDelegate, UIActionSheetDelegate,UITableViewDelegate,UITableViewDataSource,MRGridViewDelegate,MRGridViewDataSource POPOVERCONTROLLER_DELEGATE_DELIMITER BLIO_POPOVERCONTROLLER_DELEGATE> {
    BlioLibraryBookView *_currentBookView;
    UIImageView *_currentPoppedBookCover;
    BOOL _bookCoverPopped;
    BOOL _firstPageRendered;
    BOOL _didEdit;
    BlioLibraryLayout _libraryLayout;
    
    BlioTestBlockWords *_testBlockWords;
    NSManagedObjectContext *_managedObjectContext;
    id<BlioProcessingDelegate> _processingDelegate;
    
    NSFetchedResultsController *_fetchedResultsController;
	UITableView * _tableView;
	MRGridView * _gridView;
	NSUInteger maxLayoutPageEquivalentCount;
	NSInteger _keyValueOfCellToBeDeleted;
	BlioLibrarySortType librarySortType;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	UIPopoverController * settingsPopoverController;
#endif
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) BlioLibraryBookView *currentBookView;
@property (nonatomic, retain) UIImageView *currentPoppedBookCover;
@property (nonatomic) BOOL bookCoverPopped;
@property (nonatomic) BOOL firstPageRendered;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) MRGridView *gridView;
@property (nonatomic, readonly) NSInteger columnCount;
@property (nonatomic) BlioLibraryLayout libraryLayout;
@property (nonatomic, assign) id<BlioProcessingDelegate> processingDelegate;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, assign) NSUInteger maxLayoutPageEquivalentCount;
@property (nonatomic, assign) BlioLibrarySortType librarySortType;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
@property (nonatomic, retain) UIPopoverController * settingsPopoverController;
#endif

-(void)configureTableCell:(BlioLibraryListCell*)cell atIndexPath:(NSIndexPath*)indexPath;
-(void)configureGridCell:(BlioLibraryGridViewCell*)cell atIndex:(NSInteger)index;
-(void)calculateMaxLayoutPageEquivalentCount;
-(void)fetchResults;
- (CGRect)visibleRect;

@end

@interface BlioLibraryBookView : UIView {
    UIImageView *imageView;
    UIImageView *textureView;
    UIView *highlightView;
    BlioBook *book;
}

@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UIImageView *textureView;
@property (nonatomic, retain) UIView *highlightView;
@property (nonatomic, retain) BlioBook *book;
@property (nonatomic, readonly) UIImage *image;

- (void)setBook:(BlioBook *)newBook forLayout:(BlioLibraryLayout)layout;

@end

@interface BlioProportionalProgressView : UIView {
	UIImageView * proportionalBackground;
	UIView * progressBar;
	float progress;
}
@property (nonatomic,assign) float progress;
@property (nonatomic, retain) UIImageView *proportionalBackground;
@property (nonatomic, retain) UIView *progressBar;

@end

@interface BlioLibraryGridViewCell : MRGridViewCell {
    BlioLibraryBookView *bookView;
    UILabel *titleLabel;
    UILabel *authorLabel;
    UISlider *progressSlider;
    UIImageView *progressBackgroundView;
    UIProgressView *progressView;
    UIButton * pauseButton;
    UIButton * resumeButton;
    UILabel * pausedLabel;
    id delegate;
    NSArray *accessibilityElements;
	NSString * librarySortKey;
}

@property (nonatomic, retain) BlioLibraryBookView *bookView;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *authorLabel;
@property (nonatomic, retain) UISlider *progressSlider;
@property (nonatomic, retain) UIImageView *progressBackgroundView;
@property (nonatomic, retain) UIProgressView *progressView;
@property (nonatomic, retain) UIButton *pauseButton;
@property (nonatomic, retain) UIButton *resumeButton;
@property (nonatomic, assign) BlioBook *book;
@property (nonatomic, assign) UILabel *pausedLabel;
@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) NSArray *accessibilityElements;

-(void)listenToProcessingNotifications;
-(void)stopListeningToProcessingNotifications;

@end

@interface BlioLibraryListCell : UITableViewCell {
    BlioLibraryBookView *bookView;
    UILabel *titleLabel;
    UILabel *authorLabel;
	UISlider *progressSlider;
	BlioProportionalProgressView *proportionalProgressView;
    UIProgressView *progressView;
    UIButton * pauseButton;
    UIButton * resumeButton;
    id delegate;
	NSUInteger layoutPageEquivalentCount;
}

@property (nonatomic, retain) BlioLibraryBookView *bookView;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *authorLabel;
@property (nonatomic, retain) UISlider *progressSlider;
@property (nonatomic, retain) BlioProportionalProgressView *proportionalProgressView;
@property (nonatomic, retain) UIProgressView *progressView;
@property (nonatomic, retain) UIButton *pauseButton;
@property (nonatomic, retain) UIButton *resumeButton;
@property (nonatomic, assign) BlioBook *book;
@property (nonatomic, assign) id delegate;

-(void)resetAuthorText;
-(void)resetProgressSlider;
-(void)listenToProcessingNotifications;
-(void)stopListeningToProcessingNotifications;

@end

