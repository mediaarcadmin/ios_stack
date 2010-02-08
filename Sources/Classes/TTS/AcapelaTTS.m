//
//  AcapelaTTS.m
//  BlioApp
//
//  Created by Arnold Chien on 12/22/09.
//  Copyright 2009 Kurzweil Technologies Inc.. All rights reserved.
//


#import "AcapelaTTS.h"
#include "Acapela/babkurz.lic.h"
#include "Acapela/babkurz.lic.01e560b3.password"

@implementation AcapelaTTS

@synthesize setupData, engine, ttsLicense;

- (void)initTTS {
	[self setSetupData:[[setupTTS alloc] initialize]]; 
	[self setTtsLicense:[[[AcapelaLicense alloc] initLicense:[[NSString alloc] initWithCString:babLicense encoding:NSASCIIStringEncoding] user:uid.userId passwd:uid.passwd] autorelease]];
    [self setEngine:[[[AcapelaSpeech alloc] initWithVoice:setupData.CurrentVoice license:ttsLicense] autorelease]];
	[self setCurrentPage:-1];
	[self setParagraphWords:nil];
	[self setTextToSpeakChanged:NO];
	[self setStartedPlaying:NO];
	[self setPageChanged:YES];
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
