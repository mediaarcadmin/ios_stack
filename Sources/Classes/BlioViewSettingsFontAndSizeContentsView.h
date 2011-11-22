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

@protocol BlioViewSettingsDelegate;

@interface BlioViewSettingsFontAndSizeContentsView : UIView <UITableViewDelegate, UITableViewDataSource> {
    id<BlioViewSettingsDelegate> delegate;
    
    BOOL refreshingSettings;

    UILabel *fontSizeLabel;
    UILabel *justificationLabel;

    BlioAccessibilitySegmentedControl *fontSizeSegment;
    BlioAccessibilitySegmentedControl *justificationSegment;
    
    UIView *fontTableViewShadow;
    UITableView *fontTableView;
}

@property (nonatomic, assign, readonly) id<BlioViewSettingsDelegate> delegate;
@property (nonatomic, assign, readonly) CGFloat rowHeight;

- (id)initWithDelegate:(id<BlioViewSettingsDelegate>)newDelegate;
- (void)refreshSettings;
- (void)flashScrollIndicators;

@end
