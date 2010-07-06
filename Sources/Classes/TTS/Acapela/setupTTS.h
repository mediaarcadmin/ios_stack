//
//  setupTTS.h
//  tts_demo
//
//  Created by Jo De Lafonteyne on 02/10/08.
//  Copyright 2008 Acapela. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface setupTTS : NSObject {
	NSArray *voices;
	NSString *currentVoice;
	BOOL autoMode;
}
@property (nonatomic, copy) NSArray *voices;
@property (nonatomic, copy) NSString *currentVoice;
@property (nonatomic, assign) BOOL autoMode;

- (void)setCurrentVoice:(NSString*)voice;

@end
