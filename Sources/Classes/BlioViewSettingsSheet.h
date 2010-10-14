//
//  BlioViewSettingsSheet.h
//  BlioApp
//
//  Created by matt on 30/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BlioViewSettingsContentsView;

@interface BlioViewSettingsSheet : UIActionSheet {
    BlioViewSettingsContentsView *contentsView;
}

- (id)initWithDelegate:(id)newDelegate;

@end
