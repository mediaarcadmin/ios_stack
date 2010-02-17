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

#import <QuartzCore/QuartzCore.h>

@interface EucMenuController ()

@property (nonatomic, assign) UIView *targetView;
@property (nonatomic, assign) UIWindow *targetWindow;
@property (nonatomic, assign) CGRect windowTargetRect;
@property (nonatomic, retain) EucMenuView *menuView;

@end

@implementation EucMenuController

@synthesize menuItems = _menuItems;
@synthesize menuVisible = _menuVisible;

@synthesize targetWindow = _targetWindow;
@synthesize targetView = _targetView;
@synthesize windowTargetRect = _windowTargetRect;
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
    UIWindow *targetWindow = targetView.window;
    self.targetWindow = targetWindow;
    self.windowTargetRect = [targetView convertRect:targetRect toView:targetWindow];
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
            menuView.titles = [self.menuItems valueForKey:@"title"];
            [self.targetWindow addSubview:menuView];
            [menuView positionAndResizeForAttachingToRect:self.windowTargetRect];
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
            [menuView.layer addAnimation:transition forKey:@"fadeTransition"];
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
        [self performSelector:@selector(_flashStepTwo) withObject:nil afterDelay:0.1f];
    }
}

- (void)_flashStepTwo
{
    EucMenuView *menuView = self.menuView;
    menuView.selected = YES;
    [menuView setNeedsDisplay];
    [self performSelector:@selector(_flashStepThree) withObject:nil afterDelay:1.0f / 3.0f];
}

- (void)_flashStepThree
{
    EucMenuView *menuView = self.menuView;
    menuView.selected = NO;
    [menuView setNeedsDisplay];
    [self performSelector:@selector(_flashStepFour) withObject:nil afterDelay:0.0f];
}

- (void)_flashStepFour
{
    [self setMenuVisible:NO animated:YES];
    [[UIApplication sharedApplication] endIgnoringInteractionEvents]; 
    [self performSelector:@selector(_flashStepFive) withObject:nil afterDelay:0.0f];
}

- (void)_flashStepFive
{
    [(EucMenuItem *)[self.menuItems objectAtIndex:self.menuView.selectedIndex] invokeAt:self.targetView];
}

@end
