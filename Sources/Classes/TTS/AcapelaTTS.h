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
#import "BlioAudioManager.h"

typedef enum {
    kAcapelaVoiceUSEnglishLaura = 0,
    kAcapelaVoiceUSEnglishRyan = 1,
} AcapelaVoice;

@interface AcapelaTTS : BlioAudioManager<TTSManager> {
	setupTTS* setupData;
	AcapelaSpeech* engine;
	AcapelaLicense* ttsLicense;
    
    CFAttributedStringRef currentStringWithWordOffsets;
}

@property (nonatomic, retain) AcapelaLicense* ttsLicense;
@property (nonatomic, retain) setupTTS* setupData;
@property (nonatomic, retain) AcapelaSpeech* engine;


// These look like they refer to properties, but no.
// They're pass-through methods to the corresponding
// AcapelaSpeech methods.
- (float)rate;
- (void)setRate:(float)rate;
- (float)volume;
- (void)setVolume:(float)volume;
- (id)delegate;
- (void)setDelegate:(id)delegate;

- (BOOL)voiceHasChanged ;
- (void)setEngineWithPreferences:(BOOL)voiceChanged;
- (BOOL)queueSpeakingString:(NSString *)string;
- (id)objectForProperty:(NSString *)property error:(NSError **)outError;


- (BOOL)startSpeakingWords:(NSArray *)words;
- (NSUInteger)wordOffsetForCharacterRange:(NSRange)characterRange;

@end
