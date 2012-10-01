//
//  BlioViewSettingsSheet.h
//  BlioApp
//
//  Created by matt on 30/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioViewSettingsInterface.h"

@protocol BlioViewSettingsContentsViewDelegate;
@class BlioViewSettingsGeneralContentsView, EucMenuView;

@interface BlioViewSettingsSheet : BlioViewSettingsInterface/* {
    id<BlioViewSettingsContentsViewDelegate> delegate;
    UIControl *screenMask;
    
    EucMenuView *menuView;
    UIView *containerView;
    BlioViewSettingsGeneralContentsView *settingsContentsView;
}

@property (nonatomic, assign) id<BlioViewSettingsContentsViewDelegate> delegate;

- (id)initWithDelegate:(id<BlioViewSettingsContentsViewDelegate>)delegate;
- (void)showFromToolbar:(UIToolbar *)toolbar;
- (void)dismiss;
- (void)dismissAnimated:(BOOL)animated;

- (void)pushFontSettings;
*/
@end
