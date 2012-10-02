//
//  BlioViewSettingsSheet.m
//  BlioApp
//
//  Created by matt on 30/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import "BlioViewSettingsSheet.h"
#import "BlioViewSettingsInterface.h"
#import "BlioViewSettingsGeneralContentsView.h"
#import "BlioViewSettingsFontAndSizeContentsView.h"
#import "BlioUIImageAdditions.h"

#import <libEucalyptus/EucMenuView.h>
#import <libEucalyptus/THNavigationButton.h>

@interface BlioViewSettingsSheetMask : UIControl {}

@property (nonatomic, assign) BlioViewSettingsSheet *settingsSheet;

@end

@implementation BlioViewSettingsSheetMask

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

@interface BlioViewSettingsSheet ()

@property (nonatomic, retain) UIControl *screenMask;
@property (nonatomic, retain) EucMenuView *menuView;

- (void)dismiss;


/*
@property (nonatomic, retain) UIView *containerView;
@property (nonatomic, retain) BlioViewSettingsGeneralContentsView *settingsContentsView;

- (void)dismiss;
*/
@end

@implementation BlioViewSettingsSheet

- (void)presentFromBarButtonItem:(UIBarButtonItem *)item
                       inToolbar:(UIToolbar *)toolbar
                        forEvent:(UIEvent *)event
{
    UIWindow *window = toolbar.window;
    BlioViewSettingsContentsView *contentsView = self.contentsView;
    
    BlioViewSettingsSheetMask *screenMask = [[BlioViewSettingsSheetMask alloc] init];
    screenMask.settingsSheet = self;
    screenMask.frame = window.bounds;
    [screenMask addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [window addSubview:screenMask];
    self.screenMask = screenMask;
    [screenMask release];
    
    EucMenuView *menuView = [[EucMenuView alloc] init];
    [screenMask addSubview:menuView];

    UIView *containerContainerView = [[UIView alloc] initWithFrame:CGRectZero];
    containerContainerView.layer.cornerRadius = 6.0f;
    containerContainerView.layer.masksToBounds = YES;
    menuView.containedView = containerContainerView;
    [containerContainerView release];
    
    CGRect preferredContentsFrame = (CGRect){ CGPointZero, contentsView.preferredSize };

    containerContainerView.frame = preferredContentsFrame;
    contentsView.frame = preferredContentsFrame;

    [containerContainerView addSubview:contentsView];
    
    CGRect presentationRect = [toolbar frame];
    for(UITouch* touch in [event allTouches]) {
        if(touch.phase == UITouchPhaseEnded) {
            presentationRect = [toolbar convertRect:touch.view.bounds fromView:touch.view];
            break;
        }
    }
    presentationRect = CGRectIntegral(CGRectInset(presentationRect, presentationRect.size.width * 0.33f, presentationRect.size.height * 0.33f));
    [menuView positionAndResizeForAttachingToRect:presentationRect fromView:toolbar];
    
    self.menuView = menuView;
    [menuView release];
    
    [contentsView performSelector:@selector(flashScrollIndicators) withObject:nil afterDelay:0.0];
    
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)dismissAnimated:(BOOL)animated
{
    UIView *transitionView = [self.screenMask.superview retain];
    
    void(^removalBlock)(void) = ^{
        [self.menuView removeFromSuperview];
        self.menuView = nil;
        [self.screenMask removeFromSuperview];
        self.screenMask = nil;
    };
    
    void(^completionBlock)(BOOL) = ^(BOOL finished){
        [self.delegate viewSettingsInterfaceDidDismiss:self];
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
        [transitionView release];
    };
    
    if(animated) {
        [UIView transitionWithView:self.screenMask.superview
                          duration:1.0f / 3.0f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:removalBlock
                        completion:completionBlock];
    } else {
        removalBlock();
        completionBlock(YES);
    }
}

- (void)dismiss
{
    [self dismissAnimated:YES];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Would be nice to re-place ourselved after a rotation, like a UIPopover,
    // but I can't see a non-sketchy way to find the rect of the toolbar item
    // after the rotation.
    [self dismissAnimated:NO];
}

@end
