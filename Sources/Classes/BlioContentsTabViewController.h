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

@interface BlioContentsTabViewController : UINavigationController {
    EucBookContentsTableViewController *contentsController;
    UITableViewController *bookmarksController;
    UITableViewController *notesController;
    UIView<BlioBookView> *bookView;
    id<EucBookContentsTableViewControllerDelegate> delegate;
    UIBarButtonItem *doneButton;
}

@property (nonatomic, retain) EucBookContentsTableViewController *contentsController;
@property (nonatomic, retain) UITableViewController *bookmarksController;
@property (nonatomic, retain) UITableViewController *notesController;
@property (nonatomic, retain) UIView<BlioBookView> *bookView;
@property (nonatomic, assign) id<EucBookContentsTableViewControllerDelegate> delegate;
@property (nonatomic, retain) UIBarButtonItem *doneButton;

- (id)initWithBookView:(UIView<BlioBookView> *)aBookView;

@end
