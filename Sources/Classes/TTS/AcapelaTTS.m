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

@synthesize setupData, engine, ttsLicense, currentWordOffset, currentParagraph, currentWord, currentPage, paragraphWords;

- (void)initTTS {
	[self setTtsLicense:[[AcapelaLicense alloc] initLicense:[[NSString alloc] initWithCString:babLicense encoding:NSASCIIStringEncoding] user:uid.userId passwd:uid.passwd]];
	[self setSetupData:[[setupTTS alloc] initialize]]; 
	[self setEngine:[[AcapelaSpeech alloc] initWithVoice:setupData.CurrentVoice license:ttsLicense]];
	[self setCurrentPage:-1];
	[self setParagraphWords:nil];
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
