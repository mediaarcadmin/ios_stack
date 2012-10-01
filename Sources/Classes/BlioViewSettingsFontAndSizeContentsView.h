//
//  BlioViewSettingsFontAndSizeContentsView.h
//  BlioApp
//
//  Created by James Montgomerie on 21/11/2011.
//  Copyright (c) 2011 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioAccessibilitySegmentedControl.h"
#import "BlioBookViewController.h"

@protocol BlioViewSettingsContentsViewDelegate;

@interface BlioViewSettingsFontAndSizeContentsView : BlioViewSettingsContentsView <UITableViewDelegate, UITableViewDataSource> {
    BOOL refreshingSettings;

    UILabel *fontSizeLabel;
    UILabel *justificationLabel;

    BlioAccessibilitySegmentedControl *fontSizeSegment;
    BlioAccessibilitySegmentedControl *justificationSegment;
    
    UIView *fontTableViewShadow;
    UITableView *fontTableView;
}

- (void)flashScrollIndicators;

@end
