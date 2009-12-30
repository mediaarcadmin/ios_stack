//
//  setupTTS.h
//  tts_demo
//
//  Created by Jo De Lafonteyne on 02/10/08.
//  Copyright 2008 Acapela. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AcapelaSpeech.h"

@interface setupTTS : NSObject {
	NSMutableArray *Voices;
	NSString *CurrentVoice;
	NSString *CurrentVoiceName;
	BOOL AutoMode;
}
@property (nonatomic, retain) NSMutableArray *Voices;
@property (nonatomic, retain) NSString *CurrentVoice;
@property (nonatomic, retain) NSString *CurrentVoiceName;
@property (nonatomic) BOOL AutoMode;

- (id)initialize;
- (NSString*)SetCurrentVoice:(NSInteger)row;

@end
