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

@synthesize setupData, engine, ttsLicense, currentWordOffset, currentParagraph, currentWord, currentPage, paragraphWords, textToSpeakChanged, speakingTimer;

- (void)initTTS {
	[self setSetupData:[[setupTTS alloc] initialize]]; 
	[self setTtsLicense:[[[AcapelaLicense alloc] initLicense:[[NSString alloc] initWithCString:babLicense encoding:NSASCIIStringEncoding] user:uid.userId passwd:uid.passwd] autorelease]];
    [self setEngine:[[[AcapelaSpeech alloc] initWithVoice:setupData.CurrentVoice license:ttsLicense] autorelease]];
	[self setCurrentPage:-1];
	[self setParagraphWords:nil];
	[self setTextToSpeakChanged:NO];
}

- (BOOL)startSpeaking:(NSString *)string {
	return [engine startSpeakingString:string];
}
- (void)stopSpeaking {
	[engine stopSpeaking];
}

// Shouldn't really be in the protocol because boundary is actually an Acapela enum val.
- (void)stopSpeakingAtBoundary:(NSInteger)boundary {
	[engine stopSpeakingAtBoundary:boundary];
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

- (id)objectForProperty:(NSString *)property error:(NSError **)outError {
	return [engine objectForProperty:property error:outError];
}

@end
