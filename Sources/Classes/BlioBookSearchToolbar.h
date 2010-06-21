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
    UISearchBar *searchBar;
    UIToolbar *toolbar;
    UIBarButtonItem *doneButton;
    id <BlioBookSearchToolbarDelegate> delegate;
}

@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, assign) id <BlioBookSearchToolbarDelegate> delegate;

- (void)setTintColor:(UIColor *)tintColor;

@end

@protocol BlioBookSearchToolbarDelegate <UISearchBarDelegate>

@optional
- (void)dismissSearchToolbar:(id)sender;

@end
