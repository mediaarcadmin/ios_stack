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
#import "BlioCoverView.h"
#import "BlioAccessibilitySegmentedControl.h"
#import "BlioAutorotatingViewController.h"

@class BlioTestBlockWords;
@class BlioBookViewController;

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
static const CGFloat kBlioLibraryListBookWidth = 53;
static const CGFloat kBlioLibraryListBookHeight = 76;
static const CGFloat kBlioLibraryListBookMargin = 6;
static const CGFloat kBlioLibraryListAccessoryMargin = 20;
static const CGFloat kBlioLibraryListContentWidth = 220;
static const CGFloat kBlioLibraryListButtonWidth = 33;
static const CGFloat kBlioLibraryListButtonHeight = 33;

static const CGFloat kBlioLibraryGridRowHeight = 140;
static const CGFloat kBlioLibraryGridBookWidthPhone = 84;
static const CGFloat kBlioLibraryGridBookHeightPhone = 118;
static const CGFloat kBlioLibraryGridBookWidthPad = 140;
static const CGFloat kBlioLibraryGridBookHeightPad = 210;
static const CGFloat kBlioLibraryGridProgressViewWidth = 60;
static const CGFloat kBlioLibraryGridBookSpacing = 11;
static const CGFloat kBlioLibraryGridBookSpacingPad = 40;

static const CGFloat kBlioLibraryLayoutButtonWidth = 78;
static const CGFloat kBlioLibrarySortButtonWidth = 117;

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

@interface BlioLogoView : UIView {
    NSUInteger numberOfBooksInLibrary;
    UIImageView *imageView;
}

@property (nonatomic, assign) NSUInteger numberOfBooksInLibrary;
@property (nonatomic, retain) UIImageView *imageView;

- (void)setImage:(UIImage *)newImage;

@end

@interface BlioLibraryViewController : BlioAutorotatingViewController <NSFetchedResultsControllerDelegate, UINavigationControllerDelegate, BlioCoverViewDelegate, UIActionSheetDelegate,UITableViewDelegate,UITableViewDataSource,MRGridViewDelegate,MRGridViewDataSource POPOVERCONTROLLER_DELEGATE_DELIMITER BLIO_POPOVERCONTROLLER_DELEGATE> {
    BlioLibraryBookView *_currentBookView;
    BOOL _didEdit;
    BlioLibraryLayout _libraryLayout;
    BlioLogoView *logoView;
    
    BlioTestBlockWords *_testBlockWords;
    NSManagedObjectContext *_managedObjectContext;
    id<BlioProcessingDelegate> _processingDelegate;
    
    NSFetchedResultsController *_fetchedResultsController;
	UITableView * _tableView;
	MRGridView * _gridView;
	NSUInteger maxLayoutPageEquivalentCount;
	NSInteger _keyValueOfCellToBeDeleted;
	BlioLibrarySortType librarySortType;
    BlioLibraryBookView *selectedLibraryBookView;
    BlioBookViewController *openBookViewController;
	UIButton * libraryVaultButton;
	BOOL showArchiveCell;
	NSInteger selectedGridIndex;
	NSInteger sharedGridIndex;
	BlioAccessibilitySegmentedControl * sortSegmentedControl;
	NSMutableArray * libraryItems;
	NSMutableArray * sortLibraryItems;
	UIColor * tintColor;
	UIPopoverController * settingsPopoverController;
	NSArray * tableData;
    SEL collationStringSelector;
    BOOL hasShownAppSettings;
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) BlioLibraryBookView *currentBookView;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) MRGridView *gridView;
@property (nonatomic, readonly) NSInteger columnCount;
@property (nonatomic) BlioLibraryLayout libraryLayout;
@property (nonatomic, assign) id<BlioProcessingDelegate> processingDelegate;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, assign) NSUInteger maxLayoutPageEquivalentCount;
@property (nonatomic, assign) BlioLibrarySortType librarySortType;
@property (nonatomic, retain) UIButton * libraryVaultButton;
@property (nonatomic, assign) BOOL showArchiveCell;
@property (nonatomic, retain) UIColor * tintColor;
@property (nonatomic, retain) UIPopoverController * settingsPopoverController;

-(void)configureTableCell:(BlioLibraryListCell*)cell atIndexPath:(NSIndexPath*)indexPath;
-(void)configureGridCell:(BlioLibraryGridViewCell*)cell atIndex:(NSInteger)index;
-(void)calculateMaxLayoutPageEquivalentCount;
-(void)fetchResults;
- (CGRect)visibleRect;
- (void)showStore:(id)sender;
-(void)showSocialOptions;

-(void)openBook:(BlioBook *)selectedBook;

@end

@interface BlioLibraryBookView : UIView {
    UIImageView *imageView;
    UIImageView *textureView;
    UIView *errorView;
    BlioBook *book;
	id delegate;
	CGFloat xInset;
	CGFloat yInset;
}

@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UIImageView *textureView;
@property (nonatomic, retain) UIView *errorView;
@property (nonatomic, retain) BlioBook *book;
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, assign) id delegate;
@property (nonatomic, readonly) CGFloat xInset;
@property (nonatomic, readonly) CGFloat yInset;

- (void)setBook:(BlioBook *)newBook forLayout:(BlioLibraryLayout)layout;
- (BlioCoverView *)coverView;
- (void)displayError;

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

@interface BlioProgressView : UIView {
    CGFloat value;
}

@property (nonatomic, assign) CGFloat value;

@end

@interface BlioLibraryGridViewCell : MRGridViewCell {
    BlioLibraryBookView *bookView;
    UILabel *titleLabel;
    UILabel *authorLabel;
    BlioProgressView *progressSlider;
    UIImageView *progressBackgroundView;
    UIProgressView *progressView;
    UIButton * pauseButton;
    UIButton * resumeButton;
    UILabel * stateLabel;
    id delegate;
    NSArray *accessibilityElements;
	NSString * librarySortKey;
	UIImageView * statusBadge;
	UIImageView * previewBadge;
	UIImageView * bookTypeBadge;
    UILabel *numberOfDaysLeftLabel;
    UILabel *daysLeftLabel;
}

@property (nonatomic, retain) BlioLibraryBookView *bookView;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *authorLabel;
@property (nonatomic, retain) BlioProgressView *progressSlider;
@property (nonatomic, retain) UIImageView *progressBackgroundView;
@property (nonatomic, retain) UIProgressView *progressView;
@property (nonatomic, retain) UIButton *pauseButton;
@property (nonatomic, retain) UIButton *resumeButton;
@property (nonatomic, assign) BlioBook *book;
@property (nonatomic, assign) UILabel *stateLabel;
@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) NSArray *accessibilityElements;
@property (nonatomic, retain) UIImageView *statusBadge;
@property (nonatomic, retain) UIImageView *previewBadge;
@property (nonatomic, retain) UIImageView *bookTypeBadge;
@property (nonatomic, retain) UILabel *numberOfDaysLeftLabel;
@property (nonatomic, retain) UILabel *daysLeftLabel;

-(void)listenToProcessingNotifications;
-(void)stopListeningToProcessingNotifications;
-(NSString*)stateBasedAccessibilityHint;
@end

@interface BlioLibraryListCell : UITableViewCell/*<BookVaultSoapResponseDelegate>*/ {
    BlioLibraryBookView *bookView;
    UILabel *titleLabel;
    UILabel *authorLabel;
    UIButton *returnButton;
	//BlioProgressView *progressSlider;
	//BlioProportionalProgressView *proportionalProgressView;
    UIProgressView *progressView;
	UIButton * pauseResumeButton;
    id delegate;
	NSUInteger layoutPageEquivalentCount;
	UIImageView * statusBadge;
	UIImageView * previewBadge;
    UIImageView * bookTypeBadge;
    UILabel *numberOfDaysLeftLabel;
    UILabel *daysLeftLabel;
}

@property (nonatomic, retain) BlioLibraryBookView *bookView;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *authorLabel;
@property (nonatomic, retain) UIButton *returnButton;
//@property (nonatomic, retain) BlioProgressView *progressSlider;
//@property (nonatomic, retain) BlioProportionalProgressView *proportionalProgressView;
@property (nonatomic, retain) UIProgressView *progressView;
@property (nonatomic, retain) UIButton *pauseResumeButton;
@property (nonatomic, assign) BlioBook *book;
@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) UIImageView *statusBadge;
@property (nonatomic, retain) UIImageView *previewBadge;
@property (nonatomic, retain) UIImageView *bookTypeBadge;
@property (nonatomic, retain) UILabel *numberOfDaysLeftLabel;
@property (nonatomic, retain) UILabel *daysLeftLabel;

-(void)resetAuthorText;
//-(void)resetProgressSlider;
-(void)listenToProcessingNotifications;
-(void)stopListeningToProcessingNotifications;

@end

