//
//  BlioViewSettingsSheet.h
//  BlioApp
//
//  Created by matt on 30/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BlioViewSettingsSheet : UIActionSheet {
    UILabel *fontSizeLabel;
    UILabel *pageColorLabel;
    UISegmentedControl *pageLayoutSegment;
    UISegmentedControl *fontSizeSegment;
    UISegmentedControl *pageColorSegment;
    UISegmentedControl *lockButtonSegment;
    UISegmentedControl *tapTurnButtonSegment;
    UIButton *doneButton;
}

@property (nonatomic, retain) UILabel *fontSizeLabel;
@property (nonatomic, retain) UILabel *pageColorLabel;
@property (nonatomic, retain) UISegmentedControl *pageLayoutSegment;
@property (nonatomic, retain) UISegmentedControl *fontSizeSegment;
@property (nonatomic, retain) UISegmentedControl *pageColorSegment;
@property (nonatomic, retain) UISegmentedControl *lockButtonSegment;
@property (nonatomic, retain) UISegmentedControl *tapTurnButtonSegment;
@property (nonatomic, retain) UIButton *doneButton;

- (id)initWithDelegate:(id)newDelegate;

@end
