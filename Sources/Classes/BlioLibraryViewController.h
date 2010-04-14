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

@class BlioLibraryBookView;
@class BlioLibraryTableView;

@protocol BlioProcessingDelegate;

@interface BlioLibraryViewController : UIViewController <NSFetchedResultsControllerDelegate, UIActionSheetDelegate,UITableViewDelegate,UITableViewDataSource,MRGridViewDelegate,MRGridViewDataSource> {
    BlioLibraryBookView *_currentBookView;
    UIImageView *_currentPoppedBookCover;
    BOOL _bookCoverPopped;
    BOOL _firstPageRendered;
    
    NSArray *_books;
    BlioLibraryLayout _libraryLayout;
    
    BlioTestBlockWords *_testBlockWords;
    NSManagedObjectContext *_managedObjectContext;
    id<BlioProcessingDelegate> _processingDelegate;
    
    NSFetchedResultsController *_fetchedResultsController;
	BlioLibraryTableView * _tableView;
	MRGridView * _gridView;
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) BlioLibraryBookView *currentBookView;
@property (nonatomic, retain) UIImageView *currentPoppedBookCover;
@property (nonatomic) BOOL bookCoverPopped;
@property (nonatomic) BOOL firstPageRendered;
@property (nonatomic, retain) NSArray *books;
@property (nonatomic, retain) BlioLibraryTableView *tableView;
@property (nonatomic, retain) MRGridView *gridView;
@property (nonatomic, readonly) NSInteger columnCount;
@property (nonatomic) BlioLibraryLayout libraryLayout;
@property (nonatomic, assign) id<BlioProcessingDelegate> processingDelegate;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;

@end
