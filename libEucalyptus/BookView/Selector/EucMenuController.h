//
//  EucMenuController.h
//  libEucalyptus
//
//  Created by James Montgomerie on 05/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EucMenuView;

@interface EucMenuController : NSObject {
    NSArray *_menuItems;
    BOOL _menuVisible;

    UIView *_targetView;
    CGRect _targetRect;
    
    EucMenuView *_menuView;
    
    NSUInteger _menuSelectStepCount;
}

@property(nonatomic, retain) NSArray *menuItems;

- (void)setTargetRect:(CGRect)targetRect inView:(UIView *)targetView;

@property(nonatomic,getter=isMenuVisible) BOOL menuVisible;
- (void)setMenuVisible:(BOOL)menuVisible animated:(BOOL)animated;

@end
