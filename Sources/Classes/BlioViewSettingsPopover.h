//
//  BlioViewSettingsPopover.h
//  BlioApp
//
//  Created by matt on 31/08/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BlioViewSettingsContentsView;

@interface BlioViewSettingsPopover : UIPopoverController {
    BlioViewSettingsContentsView *contentsView;
}

- (id)initWithDelegate:(id)newDelegate;

@end
