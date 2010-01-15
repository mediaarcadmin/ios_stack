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

@interface BlioContentsTabViewController : UIViewController {
    UIToolbar *toolbar;
    UINavigationController *contentsController;
    UINavigationController *bookmarksController;
    UINavigationController *notesController;
    UIView<BlioBookView> *bookView;
    id<EucBookContentsTableViewControllerDelegate> delegate;
}

@property (nonatomic, retain) UIToolbar *toolbar;
@property (nonatomic, retain) UINavigationController *contentsController;
@property (nonatomic, retain) UINavigationController *bookmarksController;
@property (nonatomic, retain) UINavigationController *notesController;
@property (nonatomic, retain) UIView<BlioBookView> *bookView;
@property (nonatomic, assign) id<EucBookContentsTableViewControllerDelegate> delegate;

- (id)initWithBookView:(UIView<BlioBookView> *)aBookView;

@end
