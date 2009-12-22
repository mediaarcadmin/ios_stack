//
//  RootViewController.h
//  BlioApp
//
//  Created by James Montgomerie on 16/12/2009.
//  Copyright Things Made Out Of Other Things 2009. All rights reserved.
//

@class BlioLibraryBookView;

@interface BlioLibraryViewController : UITableViewController {
    BlioLibraryBookView *_currentBookView;
    NSString *_currentBookPath;
    NSString *_currentPdfPath;
    NSArray *_books;
}

@property (nonatomic, retain) BlioLibraryBookView *currentBookView;
@property (nonatomic, retain) NSString *currentBookPath;
@property (nonatomic, retain) NSString *currentPdfPath;
@property (nonatomic, retain) NSArray *books;
@property (nonatomic, readonly) NSInteger columnCount;

@end
