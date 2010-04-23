//
//  RootViewController.h
//  BlioApp
//
//  Created by James Montgomerie on 16/12/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "MRGridView.h"

@class BlioTestBlockWords;

typedef enum {
    kBlioLibraryLayoutGrid = 0,
    kBlioLibraryLayoutList = 1,
} BlioLibraryLayout;

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
