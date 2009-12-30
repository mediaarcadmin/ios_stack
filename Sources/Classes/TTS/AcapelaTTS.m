//
//  AcapelaTTS.m
//  BlioApp
//
//  Created by Arnold Chien on 12/22/09.
//  Copyright 2009 Kurzweil Technologies Inc.. All rights reserved.
//

#import "AcapelaTTS.h"
#include "Acapela/babdevlopper.lic.h"
#include "Acapela/babdevlopper.pw.h"

@implementation AcapelaTTS

@synthesize setupData, engine, ttsLicense;

- (void)initTTS {
	[self setTtsLicense:[[AcapelaLicense alloc] initLicense:[[NSString alloc] initWithCString:babLicense encoding:NSASCIIStringEncoding] user:uid.userId passwd:uid.passwd]];
	[self setSetupData:[[setupTTS alloc] initialize]]; 
	[self setEngine:[[AcapelaSpeech alloc] initWithVoice:setupData.CurrentVoice license:ttsLicense]];
	[engine setDelegate:self];
}

- (BOOL)startSpeaking:(NSString *)string {
	return [engine startSpeakingString:string];
}
- (void)stopSpeaking {
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

- (id)objectForProperty:(NSString *)property error:(NSError **)outError {
	return [engine objectForProperty:property error:outError];
}

- (void)speechSynthesizer:(AcapelaSpeech*)synth didFinishSpeaking:(BOOL)finishedSpeaking
{
	NSLog(@"Stopped speaking.");
}

- (void)speechSynthesizer:(AcapelaSpeech*)sender willSpeakWord:(NSRange)characterRange 
				 ofString:(NSString*)string 
{
	NSLog(@"About to speak a word.");
}


@end
