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

@interface BlioViewSettingsSheetMask : UIControl {}

@property (nonatomic, assign) BlioViewSettingsSheet *settingsSheet;

@end

@implementation BlioViewSettingsSheetMask

@synthesize settingsSheet;

- (id)init
{
    if((self = [super init])) {
        self.isAccessibilityElement = NO;
    }
    return self;
}

- (BOOL)accessibilityPerformEscape
{
    // New API in iOS 5, this never seems to be called.  Not sure why.
    [self.settingsSheet dismissAnimated:YES];
    return YES;
}

- (BOOL)accessibilityViewIsModal
{
    return YES;
}

@end

@interface BlioViewSettingsSheet()

@property (nonatomic, retain) BlioViewSettingsContentsView *contentsView;
@property (nonatomic, retain) EucMenuView *menuView;
@property (nonatomic, retain) UIControl *screenMask;

- (void)dismiss;

@end

@implementation BlioViewSettingsSheet

@synthesize delegate, contentsView, menuView, screenMask;

- (void)dealloc {
    // Just in case...
    [self.menuView removeFromSuperview];
    self.menuView = nil;
    [self.screenMask removeFromSuperview];
    self.screenMask = nil;
    
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
    
    BlioViewSettingsSheetMask *invisibleDismissButton = [[BlioViewSettingsSheetMask alloc] init];
    invisibleDismissButton.frame = window.bounds;
    [invisibleDismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [window addSubview:invisibleDismissButton];
    self.screenMask = invisibleDismissButton;
    [invisibleDismissButton release];
        
    EucMenuView *newMenuView = [[EucMenuView alloc] init];
    [invisibleDismissButton addSubview:newMenuView];
    
    BlioViewSettingsContentsView *aContentsView = [[BlioViewSettingsContentsView alloc] initWithDelegate:self.delegate];
    newMenuView.containedView = aContentsView;
    [aContentsView release];
    
    CGFloat desiredContentsHeight = aContentsView.contentsHeight;
    if(toolbar.bounds.size.width <= 320) {
        aContentsView.frame = CGRectMake(0, 0, 289, desiredContentsHeight);
        [newMenuView positionAndResizeForAttachingToRect:CGRectMake(279, 15, 1, 1) fromView:toolbar];
    } else {
        if(aContentsView.hasScreenBrightnessSlider) {
            aContentsView.frame = CGRectMake(0, 0, 319, desiredContentsHeight);
        } else {
            aContentsView.frame = CGRectMake(0, 0, 289, desiredContentsHeight);
        }
        [newMenuView positionAndResizeForAttachingToRect:CGRectMake(408, 13, 1, 1) fromView:toolbar];
    }
    
    self.menuView = newMenuView;
    
    [newMenuView release];
    
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)dismissAnimated:(BOOL)animated
{
    if(animated) {
        CATransition *animation = [CATransition animation];
        [animation setType:kCATransitionFade];
        [animation setDuration:0.3f];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [[self.screenMask.superview layer] addAnimation:animation forKey:@"ViewSettingsFade"];
    }
    
    [self.menuView removeFromSuperview];
    self.menuView = nil;
    [self.screenMask removeFromSuperview];
    self.screenMask = nil;
    
    [self.delegate viewSettingsDidDismiss:self];
    
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)dismiss
{
    [self dismissAnimated:YES];
}

@end
