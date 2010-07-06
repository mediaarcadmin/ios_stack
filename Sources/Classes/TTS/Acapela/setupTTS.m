//
//  etup.m
//  tts_demo
//
//  Created by Jo De Lafonteyne on 02/10/08.
//  Copyright 2008 Acapela. All rights reserved.
//

#import "setupTTS.h"
#import "BlioAcapelaAudioManager.h"
#import "BlioAppSettingsConstants.h"

@implementation setupTTS

@synthesize voices;
@synthesize currentVoice;
@synthesize autoMode;

-(id)init {
	autoMode = FALSE;
//	self.voices = [AcapelaSpeech availableVoices];
	self.voices = [NSArray array];
	if (voices.count > 0) {
		[self setCurrentVoice:[[NSUserDefaults standardUserDefaults] stringForKey:kBlioLastVoiceDefaultsKey]];
	}
	else
		[self setCurrentVoice:nil];
	
	return self;
}

- (void)setCurrentVoice:(NSString*)voice {
	if (currentVoice) [currentVoice release];
	if (voice != nil) {
		currentVoice = [[NSString stringWithString:voice] retain];
	}
	else {
		currentVoice = nil;
	}
}
- (NSString*)currentVoiceName {
	if (currentVoice != nil) return [BlioAcapelaAudioManager voiceNameForVoice:currentVoice];
	return nil;
}
@end
