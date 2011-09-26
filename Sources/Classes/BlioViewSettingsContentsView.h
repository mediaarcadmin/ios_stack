//
//  BlioViewSettingsContentsView.h
//  BlioApp
//
//  Created by matt on 31/08/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioAccessibilitySegmentedControl.h"
#import "BlioBookViewController.h"

@protocol BlioViewSettingsDelegate;

@interface BlioViewSettingsContentsView : UIView {
    id<BlioViewSettingsDelegate> delegate;
    
    BOOL refreshingSettings;

    UILabel *fontSizeLabel;
    UILabel *justificationLabel;
    UILabel *pageColorLabel;
	UILabel *tapZoomsToBlockLabel;
	UILabel *landscapePageLabel;
    
    BlioAccessibilitySegmentedControl *pageLayoutSegment;
    BlioAccessibilitySegmentedControl *fontSizeSegment;
    BlioAccessibilitySegmentedControl *justificationSegment;
    BlioAccessibilitySegmentedControl *pageColorSegment;
    BlioAccessibilitySegmentedControl *tapZoomsToBlockSegment;
    BlioAccessibilitySegmentedControl *landscapePageSegment;
    BlioAccessibilitySegmentedControl *lockButtonSegment;
    
    UISlider *screenBrightnessSlider;
    
    UIButton *doneButton;
    
    UIImage *lockRotationImage;
    UIImage *unlockRotationImage;   
}

@property (nonatomic, assign) id<BlioViewSettingsDelegate> delegate;

@property (nonatomic, retain) UILabel *fontSizeLabel;
@property (nonatomic, retain) UILabel *justificationLabel;
@property (nonatomic, retain) UILabel *pageColorLabel;
@property (nonatomic, retain) UILabel *tapZoomsToBlockLabel;
@property (nonatomic, retain) UILabel *landscapePageLabel;

@property (nonatomic, retain) BlioAccessibilitySegmentedControl *pageLayoutSegment;
@property (nonatomic, retain) BlioAccessibilitySegmentedControl *fontSizeSegment;
@property (nonatomic, retain) BlioAccessibilitySegmentedControl *justificationSegment;
@property (nonatomic, retain) BlioAccessibilitySegmentedControl *pageColorSegment;
@property (nonatomic, retain) BlioAccessibilitySegmentedControl *tapZoomsToBlockSegment;
@property (nonatomic, retain) BlioAccessibilitySegmentedControl *landscapePageSegment;
@property (nonatomic, retain) BlioAccessibilitySegmentedControl *lockButtonSegment;

@property (nonatomic, retain) UIButton *doneButton;
@property (nonatomic, retain) UISlider *screenBrightnessSlider;

- (id)initWithDelegate:(id<BlioViewSettingsDelegate>)newDelegate;
- (CGFloat)contentsHeight;

- (void)refreshSettings;

@end

