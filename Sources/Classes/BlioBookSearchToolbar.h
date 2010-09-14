//
//  BlioBookSearchToolbar.h
//  BlioApp
//
//  Created by matt on 15/06/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BlioBookSearchBar

- (void)setBarStyle:(UIBarStyle)barStyle;
- (void)setTintColor:(UIColor *)tintColor;
- (void)setDelegate:(id)delegate;
- (void)setPlaceholder:(NSString *)placeholder;
- (void)setShowsCancelButton:(BOOL)showCancel;

@end


@protocol BlioBookSearchToolbarDelegate;

@interface BlioBookSearchToolbar : UIView {
    id <BlioBookSearchToolbarDelegate> delegate;
    UIView<BlioBookSearchBar> *searchBar;
    UINavigationBar *doneNavBar;
    UIBarButtonItem *doneButton;
    UINavigationBar *inlineNavBar;
    UISegmentedControl *inlineSegmentedControl;
    UIView *toolbarDecoration;
    BOOL inlineMode;
}

@property (nonatomic, assign) id <BlioBookSearchToolbarDelegate> delegate;
@property (nonatomic, assign) BOOL inlineMode;
@property (nonatomic, retain) UIView<BlioBookSearchBar> *searchBar;

- (void)setTintColor:(UIColor *)tintColor;
- (void)setBarStyle:(UIBarStyle)barStyle;

@end

@protocol BlioBookSearchToolbarDelegate <UISearchBarDelegate>

@optional
- (void)dismissSearchToolbar:(id)sender;
- (void)nextResult;
- (void)previousResult;

@end
