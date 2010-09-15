//
//  BlioAudioSettingsController.h
//  BlioApp
//
//  Created by Arnold Chien on 2/20/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioAcapelaAudioManager.h"

@interface BlioAudioSettingsController : UITableViewController <NSFetchedResultsControllerDelegate> {
	UISegmentedControl* voiceControl;
	UISlider* speedControl;
	UISlider* volumeControl;
	UIButton* playButton;
    UILabel *voiceLabel;
    UILabel *speedLabel;
    UILabel *volumeLabel;
	NSArray * availableVoices;
	UIView * contentView;
	CGFloat footerHeight;
	NSInteger ttsBooks;
	NSInteger totalBooks;
	NSFetchedResultsController * ttsFetchedResultsController;
	NSFetchedResultsController * totalFetchedResultsController;
}
@property (nonatomic, retain) UISegmentedControl * voiceControl;
@property (nonatomic, retain) UISlider * speedControl;
@property (nonatomic, retain) UISlider * volumeControl;
@property (nonatomic, retain) UIButton * playButton;
@property (nonatomic, retain) UILabel * voiceLabel;
@property (nonatomic, retain) UILabel * speedLabel;
@property (nonatomic, retain) UILabel * volumeLabel;
@property (nonatomic, retain) NSArray * availableVoices;
@property (nonatomic, retain) UIView * contentView;
@property (nonatomic, assign) CGFloat footerHeight;
@property (nonatomic, retain) NSFetchedResultsController * ttsFetchedResultsController;
@property (nonatomic, retain) NSFetchedResultsController * totalFetchedResultsController;

@end
