//
//  AcapelaTTS.h
//  TTSDemo
//
//  Created by Arnold Chien on 12/22/09.
//  Copyright 2009 Kurzweil Technologies Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTSManager.h"
#import "setupTTS.h"

@interface AcapelaTTS : NSObject<TTSManager> {
	setupTTS* setupData;
	AcapelaSpeech* engine;
	AcapelaLicense* ttsLicense;
	uint32_t currentParagraph;
	uint32_t currentWordOffset;
	uint32_t currentPage;
	NSString* currentWord;
	NSArray* paragraphWords;
	NSTimer* speakingTimer;
	BOOL textToSpeakChanged;
}

@property (nonatomic, retain) AcapelaLicense* ttsLicense;
@property (nonatomic, retain) setupTTS* setupData;
@property (nonatomic, retain) AcapelaSpeech* engine;
@property (nonatomic, retain) NSArray* paragraphWords;
@property (nonatomic, retain) NSString* currentWord;
@property (nonatomic, retain) NSTimer* speakingTimer;
@property (nonatomic) uint32_t currentParagraph;
@property (nonatomic) uint32_t currentWordOffset;
@property (nonatomic) uint32_t currentPage;
@property (nonatomic) BOOL textToSpeakChanged;

// These look like they refer to properties, but no.
// They're pass-through methods to the corresponding
// AcapelaSpeech methods.
- (float)rate;
- (void)setRate:(float)rate;
- (float)volume;
- (void)setVolume:(float)volume;
- (id)delegate;
- (void)setDelegate:(id)delegate;
- (BOOL)queueSpeakingString:(NSString *)string;
- (void)adjustParagraphWords;
- (id)objectForProperty:(NSString *)property error:(NSError **)outError;

@end
