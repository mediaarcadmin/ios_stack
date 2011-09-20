//
//  BlioViewSettingsSheet.m
//  BlioApp
//
//  Created by matt on 30/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import "BlioViewSettingsSheet.h"
#import "BlioViewSettingsContentsView.h"
#import <libEucalyptus/EucMenuView.h>

@interface BlioViewSettingsSheet()

@property (nonatomic, retain) BlioViewSettingsContentsView *contentsView;
@property (nonatomic, retain) EucMenuView *menuView;
@property (nonatomic, retain) UIButton *buttonMask;

@end

@implementation BlioViewSettingsSheet

@synthesize delegate, contentsView, menuView, buttonMask;

- (void)dealloc {
    // Just in case...
    [self.menuView removeFromSuperview];
    self.menuView = nil;
    [self.buttonMask removeFromSuperview];
    self.buttonMask = nil;
    
    self.contentsView = nil;
    [super dealloc];
}

- (id)initWithDelegate:(id<BlioViewSettingsDelegate>)newDelegate {
	if ((self = [super init])) {
        self.delegate = newDelegate;
        BlioViewSettingsContentsView *aContentsView = [[BlioViewSettingsContentsView alloc] initWithDelegate:newDelegate];
        self.contentsView = aContentsView;
        [aContentsView release];
    }
	return self;
}

- (void)showFromToolbar:(UIToolbar *)toolbar
{
    UIWindow *window = toolbar.window;
    
    UIButton *invisibleDismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    invisibleDismissButton.frame = window.bounds;
    invisibleDismissButton.isAccessibilityElement = NO;
    [invisibleDismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [window addSubview:invisibleDismissButton];
    self.buttonMask = invisibleDismissButton;
    
    EucMenuView *newMenuView = [[EucMenuView alloc] init];
    [invisibleDismissButton addSubview:newMenuView];
    
    BlioViewSettingsContentsView *aContentsView = [[BlioViewSettingsContentsView alloc] initWithDelegate:self.delegate];
    aContentsView.frame = CGRectMake(0, 0, 289, aContentsView.contentsHeight);
    newMenuView.containedView = aContentsView;
    [aContentsView release];
    
    if(toolbar.bounds.size.width <= 320) {
        [newMenuView positionAndResizeForAttachingToRect:CGRectMake(279, 16, 0, 0) fromView:toolbar];
    } else {
        [newMenuView positionAndResizeForAttachingToRect:CGRectMake(408, 14, 0, 0) fromView:toolbar];
    }
    
    self.menuView = newMenuView;
    
    [newMenuView release];
}

- (void)dismissAnimated:(BOOL)animated
{
    if(animated) {
        CATransition *animation = [CATransition animation];
        [animation setType:kCATransitionFade];
        [animation setDuration:0.3f];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [[self.buttonMask.superview layer] addAnimation:animation forKey:@"ViewSettingsFade"];
    }
    
    [self.menuView removeFromSuperview];
    self.menuView = nil;
    [self.buttonMask removeFromSuperview];
    self.buttonMask = nil;
    
    [self.delegate dismissViewSettings:self];
}

- (void)dismiss
{
    [self dismissAnimated:YES];
}

@end
