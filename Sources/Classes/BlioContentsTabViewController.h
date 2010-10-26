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
#import "BlioBook.h"
#import "BlioBookmark.h"

@protocol BlioContentsTabViewControllerDelegate <NSObject>

@optional

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;
- (void)dismissContentsTabView:(id)sender;

- (void)displayNote:(NSManagedObject *)note atRange:(BlioBookmarkRange *)range animated:(BOOL)animated;
- (void)goToContentsBookmarkRange:bookmarkRange animated:(BOOL)animated;
- (void)goToContentsUuid:(NSString *)sectionUuid animated:(BOOL)animated;
- (void)deleteBookmark:(NSManagedObject *)bookmark;
- (void)deleteNote:(NSManagedObject *)note;
- (BOOL)isRotationLocked;

@end

@class BlioContentsTabContentsViewController, BlioContentsTabBookmarksViewController, BlioContentsTabNotesViewController;

@interface BlioContentsTabViewController : UINavigationController <EucBookContentsTableViewControllerDelegate, UIPopoverControllerDelegate> {
    BlioContentsTabContentsViewController *contentsController;
    BlioContentsTabBookmarksViewController *bookmarksController;
    BlioContentsTabNotesViewController *notesController;
    UIView<BlioBookView> *bookView;
    id <BlioContentsTabViewControllerDelegate> delegate;
    UIBarButtonItem *doneButton;
    BlioBook *book;
    UISegmentedControl *tabSegment;
    UIPopoverController *popoverController;
	BOOL isTOCActive;
}

@property (nonatomic, retain) BlioContentsTabContentsViewController *contentsController;
@property (nonatomic, retain) BlioContentsTabBookmarksViewController *bookmarksController;
@property (nonatomic, retain) BlioContentsTabNotesViewController *notesController;
@property (nonatomic, retain) UIView<BlioBookView> *bookView;
@property (nonatomic, assign) id <BlioContentsTabViewControllerDelegate> delegate;
@property (nonatomic, retain) UIBarButtonItem *doneButton;
@property (nonatomic, retain) BlioBook *book;
@property (nonatomic, retain) UISegmentedControl *tabSegment;
@property (nonatomic, assign) UIPopoverController *popoverController;

- (id)initWithBookView:(UIView<BlioBookView> *)aBookView book:(BlioBook *)aBook;

@end
