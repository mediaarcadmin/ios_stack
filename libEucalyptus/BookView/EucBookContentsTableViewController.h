//
//  BookContentsTableViewController.h
//  libEucalyptus
//
//  Created by James Montgomerie on 20/01/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class THPair;
@protocol EucBookContentsTableViewControllerDelegate, EucBookContentsTableViewControllerDataSource;

@interface EucBookContentsTableViewController : UITableViewController {
    id<EucBookContentsTableViewControllerDelegate> _delegate;
    id<EucBookContentsTableViewControllerDataSource> _dataSource;
    
    NSArray *_uuids;
    NSString *_currentSectionUuid;
    UIColor *_selectedGradientColor;
        
    NSString *_selectedUuid;

    off_t _previousLastOffset;
    BOOL _paginationIsComplete;
}

@property (nonatomic, assign) id<EucBookContentsTableViewControllerDelegate> delegate;
@property (nonatomic, assign) id<EucBookContentsTableViewControllerDataSource> dataSource;
@property (nonatomic, retain) NSString *currentSectionUuid;
@property (nonatomic, readonly) NSString *selectedUuid;

// init is the designated initialiser.
- (id)init;

@end

@protocol EucBookContentsTableViewControllerDelegate

@required
- (void)bookContentsTableViewController:(EucBookContentsTableViewController *)controller 
               didSelectSectionWithUuid:(NSString *)uuid;

@end

@protocol EucBookContentsTableViewControllerDataSource <NSObject>

@required
- (NSArray *)sectionUuids;
- (NSString *)sectionUuidForPageNumber:(NSUInteger)pageNumber;
- (THPair *)presentationNameAndSubTitleForSectionUuid:(NSString *)sectionUuid;
- (NSUInteger)pageNumberForSectionUuid:(NSString *)sectionUuid;


// A "display number" i.e. cover -> nil, 2 -> @"1" etc;
// Could also do things like convert to roman numerals when appropriate.
- (NSString *)displayPageNumberForPageNumber:(NSUInteger)pageNumber;

@end
