//
//  EucMenuController.m
//  libEucalyptus
//
//  Created by James Montgomerie on 05/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucMenuController.h"
#import "EucMenuView.h"
#import "EucMenuItem.h"
#import "THCALayerAdditions.h"

#import <QuartzCore/QuartzCore.h>

@interface EucMenuController ()

@property (nonatomic, assign) UIView *targetView;
@property (nonatomic, assign) CGRect targetRect;
@property (nonatomic, retain) EucMenuView *menuView;

@end

@implementation EucMenuController

@synthesize menuItems = _menuItems;
@synthesize menuVisible = _menuVisible;

@synthesize targetView = _targetView;
@synthesize targetRect = _targetRect;
@synthesize menuView = _menuView;

- (void)dealloc
{
    [_menuItems release];
    [_menuView release];
    
    [super dealloc];
}

- (void)setTargetRect:(CGRect)targetRect inView:(UIView *)targetView
{
    self.targetView = targetView;
    self.targetRect = targetRect;
}

- (void)setMenuItems:(NSArray *)menuItems
{
    if(menuItems != _menuItems) {
        [_menuItems release];
        _menuItems = [menuItems retain];
        
        EucMenuView *menuView = self.menuView;
        if(menuView) {
            menuView.titles = [menuItems valueForKey:@"title"];
            menuView.colors = [menuItems valueForKey:@"color"];

            if(self.isMenuVisible) {
                if(_menuSelectStepCount != 0) {
                    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_menuSelectStep) object:nil];
                    _menuSelectStepCount = 0;
                    [[UIApplication sharedApplication] endIgnoringInteractionEvents]; 
                }
                
                menuView.selected = NO;
                [menuView positionAndResizeForAttachingToRect:self.targetRect fromView:self.targetView];
                
                CATransition *transition = [CATransition animation];
                transition.type = kCATransitionFade;
                transition.duration = 0.1f;
                [menuView.layer addAnimation:transition forKey:@"menuSwitchFade"];                
            }
        }
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if([[anim valueForKey:@"THName"] isEqualToString:@"MenuFadeOut"]) {
        UIView * menuView = self.menuView;
        if(menuView && menuView.isHidden) {
            [menuView removeFromSuperview];
            self.menuView = nil;
        }
    }
}

- (void)setMenuVisible:(BOOL)menuVisible animated:(BOOL)animated
{
    if(menuVisible != _menuVisible) {
        [CATransaction begin];
        EucMenuView *menuView = self.menuView;
        if(menuVisible) {
            if(!menuView) {
                menuView = [[EucMenuView alloc] initWithFrame:CGRectZero];
                [menuView addTarget:self 
                             action:@selector(touchUpInsideMenu:)
                   forControlEvents:UIControlEventTouchUpInside];                
                self.menuView = menuView;
                [menuView release];
            } else {
                menuView.hidden = NO;
            }
            
            NSArray *menuItems = self.menuItems;
            menuView.titles = [menuItems valueForKey:@"title"];
            menuView.colors = [menuItems valueForKey:@"color"];
            [self.targetView.window addSubview:menuView];
            [menuView positionAndResizeForAttachingToRect:self.targetRect fromView:self.targetView];
        } else {
            if(menuView) {
                menuView.hidden = YES;
                menuView.selected = NO;
            }
        }
        if(menuView && animated) {
            CATransition *transition = [CATransition animation];
            transition.type = kCATransitionFade;
            transition.duration = 0.1f;
            transition.delegate = self;
            [transition setValue:@"MenuFadeOut" forKey:@"THName"];
            [menuView.layer addAnimation:transition forKey:@"MenuFadeOut"];
        }
        [CATransaction commit];
        
        _menuVisible = menuVisible;
    }
}

- (void)setMenuVisible:(BOOL)menuVisible
{
    [self setMenuVisible:menuVisible animated:NO];
}

- (void)touchUpInsideMenu:(EucMenuView *)menuView
{
    if(menuView.isSelected) {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        menuView.selected = NO;
        [menuView setNeedsDisplay];
        _menuSelectStepCount = 1;
        [self performSelector:@selector(_menuSelectStep) withObject:nil afterDelay:0.1f];
    }
}

- (void)_menuSelectStep
{
    switch(_menuSelectStepCount) {
        case 1:
            {
                EucMenuView *menuView = self.menuView;
                menuView.selected = YES;
                [menuView setNeedsDisplay];
                ++_menuSelectStepCount;
                [self performSelector:@selector(_menuSelectStep) withObject:nil afterDelay:1.0f / 3.0f];
            } 
            break;
        case 2:
            {
                EucMenuView *menuView = self.menuView;
                menuView.selected = NO;
                [menuView setNeedsDisplay];
                ++_menuSelectStepCount;
                [self performSelector:@selector(_menuSelectStep) withObject:nil afterDelay:0.0f];
                [(EucMenuItem *)[self.menuItems objectAtIndex:self.menuView.selectedIndex] invokeAt:self.targetView];
            } 
            break;
        case 3:
            {
                [self setMenuVisible:NO animated:YES];
                _menuSelectStepCount = 0;
                [[UIApplication sharedApplication] endIgnoringInteractionEvents]; 
            }
            break;
    }
}


@end
