//
//  RootViewController.h
//  BlioApp
//
//  Created by James Montgomerie on 16/12/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//

typedef enum {
  kBlioLibraryLayoutGrid = 0,
  kBlioLibraryLayoutList = 1,
} BlioLibraryLayout;

@class BlioLibraryBookView;

@interface BlioLibraryViewController : UITableViewController {
  BlioLibraryBookView *_currentBookView;
  NSString *_currentBookPath;
  NSString *_currentPdfPath;
  NSArray *_books;
  BlioLibraryLayout _libraryLayout;
}

@property (nonatomic, retain) BlioLibraryBookView *currentBookView;
@property (nonatomic, retain) NSString *currentBookPath;
@property (nonatomic, retain) NSString *currentPdfPath;
@property (nonatomic, retain) NSArray *books;
@property (nonatomic, readonly) NSInteger columnCount;
@property (nonatomic) BlioLibraryLayout libraryLayout;

@end
