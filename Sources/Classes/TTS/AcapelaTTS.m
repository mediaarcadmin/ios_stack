//
//  AcapelaTTS.m
//  BlioApp
//
//  Created by Arnold Chien on 12/22/09.
//  Copyright 2009 Kurzweil Technologies Inc.. All rights reserved.
//

#import "BlioAppSettingsConstants.h"
#import "AcapelaTTS.h"
#include "Acapela/babkurz.lic.h"
#include "Acapela/babkurz.lic.01e560b3.password"

@implementation AcapelaTTS

@synthesize setupData, engine, ttsLicense;


- (id)init {
    if ((self = [super init])) {
		[self setTtsLicense:[[[AcapelaLicense alloc] initLicense:[[NSString alloc] initWithCString:babLicense encoding:NSASCIIStringEncoding] user:uid.userId passwd:uid.passwd] autorelease]];
		[self setSetupData:[setupTTS alloc]];
		[self setEngine:[[AcapelaSpeech alloc] autorelease]];
		[self setCurrentPage:-1];
		[self setParagraphWords:nil];
		[self setTextToSpeakChanged:NO];
		[self setStartedPlaying:NO];
		[self setPageChanged:YES];
    }
    return self;
}

/*
- (void)initTTS { 
	[self setTtsLicense:[[[AcapelaLicense alloc] initLicense:[[NSString alloc] initWithCString:babLicense encoding:NSASCIIStringEncoding] user:uid.userId passwd:uid.passwd] autorelease]];
	//[self setSetupData:[[setupTTS alloc] initialize]];
	//[self setEngine:[[[AcapelaSpeech alloc] initWithVoice:setupData.CurrentVoice license:ttsLicense] autorelease]];
	[self setSetupData:[setupTTS alloc]];
	[self setEngine:[[AcapelaSpeech alloc] autorelease]];
	[self setPreferences];
	[self setCurrentPage:-1];
	[self setParagraphWords:nil];
	[self setTextToSpeakChanged:NO];
	[self setStartedPlaying:NO];
	[self setPageChanged:YES];  
}
 */

- (BOOL)voiceHasChanged {
	return ((([[self.setupData CurrentVoiceName] compare:@"Laura"]==NSOrderedSame) && 
			 [[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastVoiceDefaultsKey]!=(NSInteger)kAcapelaVoiceUSEnglishLaura) ||
			(([[self.setupData CurrentVoiceName] compare:@"Ryan"]==NSOrderedSame) && 
			 [[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastVoiceDefaultsKey]!=(NSInteger)kAcapelaVoiceUSEnglishRyan));
}

- (void)setEngineWithPreferences:(BOOL)voiceChanged {
	if (voiceChanged) {  
		[self.setupData initialize];
		[self.engine initWithVoice:setupData.CurrentVoice license:ttsLicense];
	}
	if ( [[NSUserDefaults standardUserDefaults] floatForKey:kBlioLastSpeedDefaultsKey] == 0 )
		// Preference has not been set.  Set to default.
		[[NSUserDefaults standardUserDefaults] setFloat:180.0 forKey:kBlioLastSpeedDefaultsKey];
	[self setRate:[[NSUserDefaults standardUserDefaults] floatForKey:kBlioLastSpeedDefaultsKey]];	
	if ( [[NSUserDefaults standardUserDefaults] floatForKey:kBlioLastVolumeDefaultsKey] == 0 )
		// Preference has not been set.  Set to default.
		[[NSUserDefaults standardUserDefaults] setFloat:50.0 forKey:kBlioLastVolumeDefaultsKey];
	[self setVolume:[[NSUserDefaults standardUserDefaults] floatForKey:kBlioLastVolumeDefaultsKey]];
}

- (BOOL)startSpeaking:(NSString *)string {
	return [engine startSpeakingString:string];
}
- (void)stopSpeaking {
	[self setStartedPlaying:NO];
	[engine stopSpeaking];
}

- (void)pauseSpeaking {
	[engine stopSpeaking];
}

- (BOOL)isSpeaking {
	return [engine isSpeaking];
}

- (float)rate {
	return [engine rate];
}

- (void)setRate:(float)rate; {
	[engine setRate:rate];
}

- (float)volume {
	return [engine volume];
}

- (void)setVolume:(float)volume {
	[engine setVolume:volume];
}

- (id)delegate {
	return [engine delegate];
}

- (void)setDelegate:(id)delegate {
	[engine setDelegate:delegate];
}

- (BOOL)queueSpeakingString:(NSString *)string {
	return [engine queueSpeakingString:string];
}

- (id)objectForProperty:(NSString *)property error:(NSError **)outError {
	return [engine objectForProperty:property error:outError];
}

@end
