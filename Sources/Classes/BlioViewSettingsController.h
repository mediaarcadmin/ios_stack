//
//  BlioViewSettingsController.h
//  BlioApp
//
//  Created by matt on 22/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BlioViewSettingsController : UIViewController {
  id delegate;
  UILabel *fontSizeLabel;
  UILabel *pageColorLabel;
  UISegmentedControl *fontSizeSegment;
  UISegmentedControl *pageColorSegment;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) UILabel *fontSizeLabel;
@property (nonatomic, retain) UILabel *pageColorLabel;
@property (nonatomic, retain) UISegmentedControl *fontSizeSegment;
@property (nonatomic, retain) UISegmentedControl *pageColorSegment;

@end
