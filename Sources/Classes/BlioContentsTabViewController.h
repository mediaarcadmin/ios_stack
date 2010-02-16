//
//  BlioContentsTabViewController.h
//  BlioApp
//
//  Created by matt on 15/01/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <libEucalyptus/EucBookContentsTableViewController.h>
#import "BlioBookView.h"
#import "BlioMockBook.h"
#import "BlioBookmark.h"

@protocol BlioContentsTabViewControllerDelegate <NSObject>

@optional

- (void)dismissContentsTabView:(id)sender;

- (void)displayNote:(NSManagedObject *)note animated:(BOOL)animated;
- (void)goToContentsBookmarkRange:bookmarkRange animated:(BOOL)animated;
- (void)goToContentsUuid:(NSString *)sectionUuid animated:(BOOL)animated;
- (void)deleteBookmark:(NSManagedObject *)bookmark;
- (void)deleteNote:(NSManagedObject *)note;

@end

@class BlioContentsTabBookmarksViewController, BlioContentsTabNotesViewController;

@interface BlioContentsTabViewController : UINavigationController {
    EucBookContentsTableViewController *contentsController;
    BlioContentsTabBookmarksViewController *bookmarksController;
    BlioContentsTabNotesViewController *notesController;
    UIView<BlioBookView> *bookView;
    id<EucBookContentsTableViewControllerDelegate, BlioContentsTabViewControllerDelegate> delegate;
    UIBarButtonItem *doneButton;
    BlioMockBook *book;
    UISegmentedControl *tabSegment;
}

@property (nonatomic, retain) EucBookContentsTableViewController *contentsController;
@property (nonatomic, retain) BlioContentsTabBookmarksViewController *bookmarksController;
@property (nonatomic, retain) BlioContentsTabNotesViewController *notesController;
@property (nonatomic, retain) UIView<BlioBookView> *bookView;
@property (nonatomic, assign) id<EucBookContentsTableViewControllerDelegate, BlioContentsTabViewControllerDelegate> delegate;
@property (nonatomic, retain) UIBarButtonItem *doneButton;
@property (nonatomic, retain) BlioMockBook *book;
@property (nonatomic, retain) UISegmentedControl *tabSegment;

- (id)initWithBookView:(UIView<BlioBookView> *)aBookView book:(BlioMockBook *)aBook;

@end
