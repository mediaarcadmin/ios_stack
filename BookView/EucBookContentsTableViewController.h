//
//  BookContentsTableViewController.h
//  Eucalyptus
//
//  Created by James Montgomerie on 20/01/2009.
//  Copyright 2009 James Montgomerie. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EucBookReference;
@protocol BookContentsTableViewControllerDelegate, EucBook, EucPageLayoutController;

@interface EucBookContentsTableViewController : UITableViewController {
    EucBookReference<EucBook> *_book;
    NSArray *_namesAndUuids;
    NSString *_currentSectionUuid;
    id<BookContentsTableViewControllerDelegate> _delegate;
    UIColor *_selectedGradientColor;
    
    id<EucPageLayoutController>_pageLayoutController;
    
    NSString *_selectedUuid;

    off_t _previousLastOffset;
    BOOL _paginationIsComplete;
}

@property (nonatomic, assign) id<BookContentsTableViewControllerDelegate> delegate;
@property (nonatomic, retain) NSString *currentSectionUuid;
@property (nonatomic, readonly) NSString *selectedUuid;

- (id)initWithBook:(EucBookReference<EucBook> *)book pageLayoutController:(id<EucPageLayoutController>)pageLayoutController;

@end


@protocol BookContentsTableViewControllerDelegate

@required
- (void)bookContentsTableViewController:(EucBookContentsTableViewController *)controller 
               didSelectSectionWithUuid:(NSString *)uuid;

@end
