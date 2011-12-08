//
//  BlioViewSettingsSheet.m
//  BlioApp
//
//  Created by matt on 30/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import "BlioViewSettingsSheet.h"
#import "BlioViewSettings.h"
#import "BlioViewSettingsContentsView.h"
#import "BlioViewSettingsFontAndSizeContentsView.h"
#import "BlioUIImageAdditions.h"

#import <libEucalyptus/EucMenuView.h>
#import <libEucalyptus/THNavigationButton.h>

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

@property (nonatomic, retain) EucMenuView *menuView;
@property (nonatomic, retain) UIView *containerView;
@property (nonatomic, retain) BlioViewSettingsContentsView *settingsContentsView;
@property (nonatomic, retain) UIControl *screenMask;

- (void)dismiss;

@end

@implementation BlioViewSettingsSheet

@synthesize delegate, settingsContentsView, menuView, containerView, screenMask;

- (void)dealloc {
    // Just in case...
    [self.menuView removeFromSuperview];
    self.menuView = nil;
    [self.screenMask removeFromSuperview];
    self.screenMask = nil;
    
    self.settingsContentsView = nil;
    [super dealloc];
}

- (id)initWithDelegate:(id<BlioViewSettingsDelegate>)newDelegate {
	if ((self = [super init])) {
        self.delegate = newDelegate;
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
    
    EucMenuView *newMenuView = [[EucMenuView alloc] init];
    [invisibleDismissButton addSubview:newMenuView];
    
    UIView *aContainerContainerView = [[UIView alloc] initWithFrame:CGRectZero];
    aContainerContainerView.layer.cornerRadius = 6.0f;
    aContainerContainerView.layer.masksToBounds = YES;
    newMenuView.containedView = aContainerContainerView;
    
    UIView *aContainerView = [[UIView alloc] initWithFrame:CGRectZero];
    aContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [aContainerContainerView addSubview:aContainerView];
    
    BlioViewSettingsContentsView *aContentsView = [[BlioViewSettingsContentsView alloc] initWithDelegate:self.delegate];
    aContentsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [aContainerView addSubview:aContentsView];
    
    CGFloat desiredContentsHeight = aContentsView.contentsHeight;
    if(toolbar.bounds.size.width <= 320) {
        aContainerContainerView.frame = CGRectMake(0, 0, 289, desiredContentsHeight);
        [newMenuView positionAndResizeForAttachingToRect:CGRectMake(279, 15, 1, 1) fromView:toolbar];
    } else {
        if(aContentsView.hasScreenBrightnessSlider && [self.delegate shouldPresentBrightnessSliderVerticallyInPageSettings]) {
            aContainerContainerView.frame = CGRectMake(0, 0, 319, desiredContentsHeight);
        } else {
            aContainerContainerView.frame = CGRectMake(0, 0, 289, desiredContentsHeight);
        }
        [newMenuView positionAndResizeForAttachingToRect:CGRectMake(408, 13, 1, 1) fromView:toolbar];
    }
    
    self.containerView = aContainerView;
    self.settingsContentsView = aContentsView;
    self.menuView = newMenuView;
    self.screenMask = invisibleDismissButton;

    [newMenuView release];
    [aContainerContainerView release];
    [aContainerView release];
    [aContentsView release];
    [invisibleDismissButton release];

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
    
    self.settingsContentsView.delegate = nil;
    self.settingsContentsView  = nil;
    
    [self.delegate viewSettingsDidDismiss:self];
    
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)dismiss
{
    [self dismissAnimated:YES];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)popFontSettings
{
    while(self.containerView.subviews.count) {
        [[self.containerView.subviews lastObject] removeFromSuperview];
    }
    
    [self.settingsContentsView refreshSettings];
    
    [self.containerView addSubview:self.settingsContentsView];
    
    CATransition *transition = [[CATransition alloc] init];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromLeft;
    transition.delegate = self;
    [self.containerView.layer addAnimation:transition forKey:@"pushFontsOut"];
    [transition release];
}

- (void)pushFontSettings
{
    while(self.containerView.subviews.count) {
        [[self.containerView.subviews lastObject] removeFromSuperview];
    }
    
    BlioViewSettingsFontAndSizeContentsView *aFontSettingsView = [[BlioViewSettingsFontAndSizeContentsView alloc] initWithDelegate:self.delegate];
    
    CGFloat rowHeight = aFontSettingsView.rowHeight;
    CGRect availableFrame = self.settingsContentsView.frame;
    
    UIImage *arrowImage = [[UIImage imageNamed:@"rightButtonBlackOpaque.png"] blioImageByFlippingHorizontally];
    CGSize arrowImageSize = arrowImage.size;
    arrowImage = [arrowImage stretchableImageWithLeftCapWidth:arrowImageSize.width * 0.5f topCapHeight:arrowImageSize.height * 0.5f];
   
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundImage:arrowImage forState:UIControlStateNormal];
    button.titleEdgeInsets = UIEdgeInsetsMake(0, 14, 0, 8);
    
    [button setTitle:NSLocalizedString(@"Settings", "Title for button in Font & Size settings popover to return to the main settings screen (iPhone)")
            forState:UIControlStateNormal];
    
    button.titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]];
    button.titleLabel.textColor = [UIColor whiteColor];
    button.titleLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    button.titleLabel.shadowOffset = CGSizeMake(0, -1);
    button.titleLabel.textAlignment = UITextAlignmentCenter;
    
    button.accessibilityHint = NSLocalizedString(@"Back to Reading Settings.", "Accessibility hint for button on font and size settings popover (iPhone only)");
    
    [button sizeToFit];
    button.frame = CGRectMake(kBlioViewSettingsXInsetIPhone, kBlioViewSettingsYInsetIPhone,
                              button.frame.size.width + 22, rowHeight);
    [button addTarget:self action:@selector(popFontSettings) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:button];    

    
    CGRect labelFrame = availableFrame;
    labelFrame.origin.y += kBlioViewSettingsXInsetIPhone;
    labelFrame.size.height = rowHeight - 6;
    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    label.font = [UIFont boldSystemFontOfSize: 18.0f];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    label.textAlignment = UITextAlignmentCenter;
    
    label.text = NSLocalizedString(@"Font & Size", "Title for Font & Size Settings Popover");
    [label sizeToFit];
    labelFrame.size.width = label.frame.size.width;
    labelFrame.origin.x = ceilf((availableFrame.size.width - labelFrame.size.width) * 0.5f);
    label.frame = labelFrame;
    
    [self.containerView addSubview:label];    
    [label release];
    
    CGRect fontSettingsFrame = availableFrame;
    fontSettingsFrame.origin.y += rowHeight + kBlioViewSettingsRowSpacingIPhone;
    fontSettingsFrame.size.height -= rowHeight + kBlioViewSettingsRowSpacingIPhone;
    aFontSettingsView.frame = fontSettingsFrame;
    aFontSettingsView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    [self.settingsContentsView removeFromSuperview];
    [self.containerView addSubview:aFontSettingsView];
    
    [aFontSettingsView release];
    
    CATransition *transition = [[CATransition alloc] init];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromRight;
    transition.delegate = self;
    [self.containerView.layer addAnimation:transition forKey:@"pushFontsIn"];
    [transition release];
}

@end
