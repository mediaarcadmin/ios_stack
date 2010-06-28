//
//  BlioViewSettingsSheet.h
//  BlioApp
//
//  Created by matt on 30/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioAccessibilitySegmentedControl.h"
#import "BlioBookViewController.h"

@protocol BlioViewSettingsDelegate;

@interface BlioViewSettingsSheet : UIActionSheet {
    UILabel *fontSizeLabel;
    UILabel *pageColorLabel;
    BlioAccessibilitySegmentedControl *pageLayoutSegment;
    BlioAccessibilitySegmentedControl *fontSizeSegment;
    BlioAccessibilitySegmentedControl *pageColorSegment;
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
@property (nonatomic, retain) UISegmentedControl *pageLayoutSegment;
@property (nonatomic, retain) UISegmentedControl *fontSizeSegment;
@property (nonatomic, retain) UISegmentedControl *pageColorSegment;
@property (nonatomic, retain) UISegmentedControl *lockButtonSegment;
@property (nonatomic, retain) UIButton *doneButton;
@property (nonatomic, assign) id<BlioViewSettingsDelegate> viewSettingsDelegate;

- (id)initWithDelegate:(id)newDelegate;

@end
