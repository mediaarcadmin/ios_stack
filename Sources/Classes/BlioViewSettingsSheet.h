//
//  BlioViewSettingsSheet.h
//  BlioApp
//
//  Created by matt on 30/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BlioViewSettingsDelegate;
@class BlioViewSettingsContentsView, EucMenuView;

@interface BlioViewSettingsSheet : NSObject {
    id<BlioViewSettingsDelegate> delegate;
    UIControl *screenMask;
    
    EucMenuView *menuView;
    UIView *containerView;
    BlioViewSettingsContentsView *settingsContentsView;
}

@property (nonatomic, assign) id<BlioViewSettingsDelegate> delegate;

- (id)initWithDelegate:(id<BlioViewSettingsDelegate>)delegate;
- (void)showFromToolbar:(UIToolbar *)toolbar;
- (void)dismiss;
- (void)dismissAnimated:(BOOL)animated;

- (void)pushFontSettings;

@end
