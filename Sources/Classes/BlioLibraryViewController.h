//
//  RootViewController.h
//  BlioApp
//
//  Created by James Montgomerie on 16/12/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//

@class BlioTestParagraphWords;

typedef enum {
    kBlioLibraryLayoutGrid = 0,
    kBlioLibraryLayoutList = 1,
} BlioLibraryLayout;

@class BlioLibraryBookView;

@interface BlioLibraryViewController : UITableViewController <UIActionSheetDelegate> {
    BlioLibraryBookView *_currentBookView;
    UIImageView *_currentPoppedBookCover;
    BOOL _bookCoverPopped;
    BOOL _firstPageRendered;
    
    NSArray *_books;
    BlioLibraryLayout _libraryLayout;
    
    BlioTestParagraphWords *_testParagraphWords;
}

@property (nonatomic, retain) BlioLibraryBookView *currentBookView;
@property (nonatomic, retain) UIImageView *currentPoppedBookCover;
@property (nonatomic) BOOL bookCoverPopped;
@property (nonatomic) BOOL firstPageRendered;
@property (nonatomic, retain) NSArray *books;
@property (nonatomic, readonly) NSInteger columnCount;
@property (nonatomic) BlioLibraryLayout libraryLayout;

@end
