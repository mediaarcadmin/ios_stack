//
//  RootViewController.h
//  BlioApp
//
//  Created by James Montgomerie on 16/12/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "MRGridView.h"
#import "BlioMockBook.h"

@class BlioTestBlockWords;

typedef enum {
    kBlioLibraryLayoutGrid = 0,
    kBlioLibraryLayoutList = 1,
} BlioLibraryLayout;

static const CGFloat kBlioLibraryToolbarHeight = 44;

static const CGFloat kBlioLibraryListRowHeight = 76;
static const CGFloat kBlioLibraryListBookHeight = 76;
static const CGFloat kBlioLibraryListBookWidth = 53;
static const CGFloat kBlioLibraryListContentWidth = 220;
static const CGFloat kBlioLibraryListProgressViewWidth = 150;

static const CGFloat kBlioLibraryGridRowHeight = 140;
static const CGFloat kBlioLibraryGridBookHeight = 140;
static const CGFloat kBlioLibraryGridBookWidth = 106;
static const CGFloat kBlioLibraryGridProgressViewWidth = 60;
static const CGFloat kBlioLibraryGridBookSpacing = 0;

static const CGFloat kBlioLibraryLayoutButtonWidth = 78;
static const CGFloat kBlioLibraryShadowXInset = 0.10276f; // Nasty hack to work out proportion of texture image is shadow
static const CGFloat kBlioLibraryShadowYInset = 0.07737f;


@class BlioBookVaultManager;
@class BlioLibraryBookView;
@class BlioLibraryListCell;
@class BlioLibraryGridViewCell;

@protocol BlioProcessingDelegate;

@interface BlioLibraryViewController : UIViewController <NSFetchedResultsControllerDelegate, UIActionSheetDelegate,UITableViewDelegate,UITableViewDataSource,MRGridViewDelegate,MRGridViewDataSource> {
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
	
	BlioBookVaultManager* _vaultManager;
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
@property (nonatomic, retain) BlioBookVaultManager* vaultManager;


-(void)configureTableCell:(BlioLibraryListCell*)cell atIndexPath:(NSIndexPath*)indexPath;
-(void)configureGridCell:(BlioLibraryGridViewCell*)cell atIndex:(NSInteger)index;
	
@end

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
    UIImageView *progressBackgroundView;
    UIProgressView *progressView;
    UIButton * pauseButton;
    UIButton * resumeButton;
    UILabel * pausedLabel;
    id delegate;
}

@property (nonatomic, retain) BlioLibraryBookView *bookView;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *authorLabel;
@property (nonatomic, retain) UISlider *progressSlider;
@property (nonatomic, retain) UIImageView *progressBackgroundView;
@property (nonatomic, retain) UIProgressView *progressView;
@property (nonatomic, retain) UIButton *pauseButton;
@property (nonatomic, retain) UIButton *resumeButton;
@property (nonatomic, assign) BlioMockBook *book;
@property (nonatomic, assign) UILabel *pausedLabel;
@property (nonatomic, assign) id delegate;

@end

@interface BlioLibraryListCell : UITableViewCell {
    BlioLibraryBookView *bookView;
    UILabel *titleLabel;
    UILabel *authorLabel;
    UISlider *progressSlider;
    UIProgressView *progressView;
    UIButton * pauseButton;
    UIButton * resumeButton;
    id delegate;
}

@property (nonatomic, retain) BlioLibraryBookView *bookView;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *authorLabel;
@property (nonatomic, retain) UISlider *progressSlider;
@property (nonatomic, retain) UIProgressView *progressView;
@property (nonatomic, retain) UIButton *pauseButton;
@property (nonatomic, retain) UIButton *resumeButton;
@property (nonatomic, assign) BlioMockBook *book;
@property (nonatomic, assign) id delegate;

-(void) resetAuthorText;
@end
