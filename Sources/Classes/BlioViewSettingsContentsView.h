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
    UILabel *fontSizeLabel;
    UILabel *pageColorLabel;
	UILabel *tapZoomsToBlockLabel;
    BlioAccessibilitySegmentedControl *pageLayoutSegment;
    BlioAccessibilitySegmentedControl *fontSizeSegment;
    BlioAccessibilitySegmentedControl *pageColorSegment;
	UISwitch * tapZoomsToBlockSwitch;
    BlioAccessibilitySegmentedControl *lockButtonSegment;
    UIButton *doneButton;
    UIImage *tapTurnOnImage;
    UIImage *tapTurnOffImage;
    UIImage *lockRotationImage;
    UIImage *unlockRotationImage;   
    id<BlioViewSettingsDelegate> viewSettingsDelegate;
}

@property (nonatomic, retain) UILabel *fontSizeLabel;
@property (nonatomic, retain) UILabel *pageColorLabel;
@property (nonatomic, retain) UILabel *tapZoomsToBlockLabel;
@property (nonatomic, retain) BlioAccessibilitySegmentedControl *pageLayoutSegment;
@property (nonatomic, retain) BlioAccessibilitySegmentedControl *fontSizeSegment;
@property (nonatomic, retain) BlioAccessibilitySegmentedControl *pageColorSegment;
@property (nonatomic, retain) UISwitch * tapZoomsToBlockSwitch;
@property (nonatomic, retain) BlioAccessibilitySegmentedControl *lockButtonSegment;
@property (nonatomic, retain) UIButton *doneButton;
@property (nonatomic, assign) id<BlioViewSettingsDelegate> viewSettingsDelegate;

- (id)initWithDelegate:(id)newDelegate;
- (CGFloat)contentsHeight;

@end

