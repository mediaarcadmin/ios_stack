//
//  BlioAudioSettingsController.h
//  BlioApp
//
//  Created by Arnold Chien on 2/20/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AcapelaTTS.h"

@interface BlioAudioSettingsController : UIViewController {
	UISegmentedControl* voiceControl;
	UISlider* speedControl;
	UISlider* volumeControl;
	UIButton* playButton;
    UILabel *voiceLabel;
    UILabel *speedLabel;
    UILabel *volumeLabel;
}

@end
