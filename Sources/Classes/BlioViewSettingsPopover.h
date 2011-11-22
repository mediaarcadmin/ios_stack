//
//  BlioViewSettingsPopover.h
//  BlioApp
//
//  Created by matt on 31/08/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioModalPopoverController.h"

@class BlioViewSettingsContentsView;
@protocol BlioViewSettingsDelegate;

@interface BlioViewSettingsPopover : BlioModalPopoverController <UIPopoverControllerDelegate, UINavigationControllerDelegate> {
    BlioViewSettingsContentsView *contentsView;
    id<BlioViewSettingsDelegate> viewSettingsDelegate;
}

- (id)initWithDelegate:(id)newDelegate;

- (void)pushFontSettings;

@end
