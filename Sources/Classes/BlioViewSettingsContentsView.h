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

    UILabel *fontAndSizeLabel;
    UILabel *pageColorLabel;
	UILabel *tapZoomsLabel;
	UILabel *twoUpLandscapeLabel;
    
    BlioAccessibilitySegmentedControl *pageLayoutSegment;
    BlioAccessibilitySegmentedControl *fontAndSizeSegment;
    BlioAccessibilitySegmentedControl *pageColorSegment;
    BlioAccessibilitySegmentedControl *tapZoomsSegment;
    BlioAccessibilitySegmentedControl *twoUpLandscapeSegment;
    BlioAccessibilitySegmentedControl *lockButtonSegment;
    
    UISlider *screenBrightnessSlider;
    
    UIButton *doneButton;
    
    UIImage *lockRotationImage;
    UIImage *unlockRotationImage;   
}

@property (nonatomic, assign) id<BlioViewSettingsDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL hasScreenBrightnessSlider;

- (id)initWithDelegate:(id<BlioViewSettingsDelegate>)newDelegate;
- (CGFloat)contentsHeight;

- (void)refreshSettings;

@end

