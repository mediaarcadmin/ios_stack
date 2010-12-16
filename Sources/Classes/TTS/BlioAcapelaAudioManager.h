//
//  BlioAcapelaAudioManager.h
//  TTSDemo
//
//  Created by Arnold Chien on 12/22/09.
//  Copyright 2009 Kurzweil Technologies Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "TTSManager.h"
#import "setupTTS.h"
#import "BlioAudioManager.h"
#import "BlioProcessingStandardOperations.h"
#import "AcapelaSpeech.h"

extern NSString * const BlioVoiceListRefreshedNotification;

@interface BlioAcapelaAudioManager : BlioAudioManager<TTSManager> {
	setupTTS* setupData;
	AcapelaSpeech* engine;
	AcapelaLicense* ttsLicense;
    NSOperationQueue *downloadQueue;
	NSDictionary * voiceData;
    CFAttributedStringRef currentStringWithWordOffsets;
	AVAudioPlayer * sampleAudioPlayer;
}

@property (nonatomic, retain) setupTTS* setupData;
@property (nonatomic, retain) AcapelaSpeech* engine;
@property (nonatomic, retain) AcapelaLicense* ttsLicense;
@property (nonatomic, retain) NSOperationQueue *downloadQueue;
@property (nonatomic, retain) NSDictionary *voiceData;
@property (nonatomic, retain) AVAudioPlayer *sampleAudioPlayer;


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
+(NSString*)voiceNameForVoice:(NSString*)voice;

- (BOOL)startSpeakingWords:(NSArray *)words;
- (NSUInteger)wordOffsetForCharacterRange:(NSRange)characterRange;

-(NSArray*)availableVoicesForUse;
-(NSArray*)availableVoiceNamesForUse;
-(NSArray*)availableVoicesForDownload;

-(void)playSampleForVoice:(NSString *)aVoice;
-(void)playSampleForVoiceName:(NSString *)aVoiceName;
-(void)downloadVoice:(NSString *)aVoice;

-(BlioProcessingDownloadAndUnzipVoiceOperation*)downloadVoiceOperationByVoice:(NSString*)aVoice;

+(BlioAcapelaAudioManager*)sharedAcapelaAudioManager;

@end
