//
//  BlioBookSearchToolbar.h
//  BlioApp
//
//  Created by matt on 15/06/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BlioBookSearchToolbarDelegate;

@interface BlioBookSearchToolbar : UIView {
    id <BlioBookSearchToolbarDelegate> delegate;
    UISearchBar *searchBar;
    UINavigationBar *doneNavBar;
    UIBarButtonItem *doneButton;
    UINavigationBar *inlineNavBar;
    UISegmentedControl *inlineSegmentedControl;
    UIView *toolbarDecoration;
    BOOL inlineMode;
}

@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, assign) id <BlioBookSearchToolbarDelegate> delegate;
@property (nonatomic, assign) BOOL inlineMode;

- (void)setTintColor:(UIColor *)tintColor;
- (void)setBarStyle:(UIBarStyle)barStyle;

@end

@protocol BlioBookSearchToolbarDelegate <UISearchBarDelegate>

@optional
- (void)dismissSearchToolbar:(id)sender;
- (void)nextResult;
- (void)previousResult;

@end
