//
//  NSAcapelaSpeech.h
//
//  Copyright 2010 Acapela. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AcapelaLicense.h"


enum {
	AcapelaSpeechImmediateBoundary =  0,
	AcapelaSpeechWordBoundary,
	AcapelaSpeechSentenceBoundary
};
typedef NSUInteger AcapelaSpeechBoundary;
typedef unsigned int BB_U32;

@interface AcapelaSpeech : NSObject {
}

    - (id)initWithVoice:(NSString *)voice license:(AcapelaLicense*)aca_lic;
	
	- (BOOL)startSpeakingString:(NSString *)string;
	- (BOOL)startSpeakingString:(NSString *)string toURL:(NSURL *)url;
    - (BOOL)startSpeakingStringSync:(NSString *)string toURL:(NSURL *)url;


	- (BOOL)queueSpeakingString:(NSString *)string;
	- (BOOL)queueSpeakingString:(NSString *)string textIndex:(int*)index;

	- (void)stopSpeaking;
	- (void)stopSpeakingAtBoundary:(AcapelaSpeechBoundary)boundary;

	- (void)pauseSpeakingAtBoundary:(AcapelaSpeechBoundary)boundary;
	- (void)continueSpeaking;

	- (void)skipToNextText;

	- (BOOL)isSpeaking;
	- (BOOL)isPaused;

	- (id)delegate;		
	- (void)setDelegate:(id)anObject;
	- (NSString *)voice;
	- (BOOL)setVoice:(NSString *)voice;
	- (float)rate;
	- (void)setRate:(float)rate;
	- (float)volume;
	- (void)setVolume:(float)volume;
	- (int)selbreak;
	- (void)setSelbreak:(int)selbreak;
	- (int)voiceShaping;
	- (void)setVoiceShaping:(int)voiceShaping;

 	- (BOOL)setActive:(BOOL)state;


	- (id)objectForProperty:(NSString *)property error:(NSError **)outError;

	+ (void)setVoicesDirectoryArray:(NSArray*)anArray;
	+ (void)refreshVoiceList;

	+ (BOOL)isAnyApplicationSpeaking;
	+ (NSArray *)availableVoices;
	+ (NSDictionary *)attributesForVoice:(NSString*)voice;
	- (NSDictionary*)attributesForCurrentVoice;

	- (NSArray *)getUserDicosTitles;

	- (BOOL)addUserDico:(NSString *)userDicoTitle relativePath:(NSString *)path;
	- (BOOL)removeUserDico:(NSString *)userDicoTitle;

	- (BOOL)setUserDicoEntry:(NSString *)userDicoTitle word:(NSString *)word nature:(NSString *)nature transcription:(NSString *)transcription;
	- (BOOL)removeUserDicoEntry:(NSString *)userDicoTitle word:(NSString *)word;

	- (NSString *)getUserDicoPath:(NSString *)userDicoTitle;
	- (NSArray *)checkUserDicoContent:(NSString *)userDicoTitle;
	- (NSDictionary *)listUserDicoContent:(NSString *)userDicoTitle;

	- (NSArray *)getPhonemsList;
	- (NSArray *)isPhoneticEntryValid:(NSString *)phoneticEntry;

    - (Float32) audioPeakLevel;
    - (Float32) audioAverageLevel;

	
@end

@interface NSObject (AcapelaSpeechDelegate)

- (void)speechSynthesizer:(AcapelaSpeech *)sender didFinishSpeaking:(BOOL)finishedSpeaking;
- (void)speechSynthesizer:(AcapelaSpeech *)sender didFinishSpeaking:(BOOL)finishedSpeaking textIndex:(int)index;
- (void)speechSynthesizer:(AcapelaSpeech *)sender willSpeakWord:(NSRange)characterRange ofString:(NSString *)string;
- (void)speechSynthesizer:(AcapelaSpeech *)sender willSpeakPhoneme:(short)phonemeOpcode;
- (void)speechSynthesizer:(AcapelaSpeech *)sender didEncounterSyncMessage:(NSString *)errorMessage;
@end

extern NSString *const AcapelaVoiceName;
extern NSString *const AcapelaVoiceIdentifier;
extern NSString *const AcapelaVoiceAge;
extern NSString *const AcapelaVoiceGender;
extern NSString *const AcapelaVoiceDemoText;
extern NSString *const AcapelaVoiceLanguage;
extern NSString *const AcapelaVoiceLocaleIdentifier;
extern NSString *const AcapelaVoiceSupportedCharacters;
extern NSString *const AcapelaVoiceIndividuallySpokenCharacters;
extern NSString *const AcapelaVoiceStringEncoding;
extern NSString *const AcapelaVoiceDataVersion;
extern NSString *const AcapelaVoiceGlobalPath;
extern NSString *const AcapelaVoiceRelativePathToApp;
extern NSString *const AcapelaVoiceFrequency;
extern NSString *const AcapelaVoiceQuality;


// Values for AcapelaVoiceGender voice attribute
extern NSString *const AcapelaVoiceGenderNeuter;
extern NSString *const AcapelaVoiceGenderMale;
extern NSString *const AcapelaVoiceGenderFemale;

// Synthesizer Properties (including object type)
extern NSString *const AcapelaSpeechStatusProperty;  // NSDictionary, see keys below
extern NSString *const AcapelaSpeechErrorsProperty ;  // NSDictionary, see keys below
NSString *const AcapelaSpeechInputModeProperty ;  // NSString: AcapelaSpeechModeTextProperty or AcapelaSpeechModePhonemeProperty
NSString *const AcapelaSpeechCharacterModeProperty ; // NSString: AcapelaSpeechModeNormalProperty or AcapelaSpeechModeLiteralProperty
NSString *const AcapelaSpeechNumberModeProperty ; // NSString: AcapelaSpeechModeNormalProperty or AcapelaSpeechModeLiteralProperty
NSString *const AcapelaSpeechRateProperty ;  // NSNumber
NSString *const AcapelaSpeechPitchBaseProperty ;  // NSNumber
NSString *const AcapelaSpeechPitchModProperty ;  // NSNumber
NSString *const AcapelaSpeechVolumeProperty ;  // NSNumber
extern NSString *const AcapelaSpeechSynthesizerInfoProperty ;  // NSDictionary, see keys below
NSString *const AcapelaSpeechRecentSyncProperty ;  // NSString
NSString *const AcapelaSpeechPhonemeSymbolsProperty ;  // NSDictionary, see keys below
NSString *const AcapelaSpeechCurrentVoiceProperty ;  // NSString
extern NSString *const AcapelaSpeechCommandDelimiterProperty ;  // NSDictionary, see keys below
NSString *const AcapelaSpeechResetProperty ;
NSString *const AcapelaSpeechOutputToFileURLProperty ;  // NSURL

// Speaking Modes for AcapelaSpeechInputModeProperty
NSString *const AcapelaSpeechModeText ;
NSString *const AcapelaSpeechModePhoneme ;

// Speaking Modes for AcapelaSpeechInputModeProperty and AcapelaSpeechNumberModeProperty
NSString *const AcapelaSpeechModeNormal ;
NSString *const AcapelaSpeechModeLiteral ;

// Dictionary keys returned by AcapelaSpeechStatusProperty
NSString *const AcapelaSpeechStatusOutputBusy ;  // NSNumber
NSString *const AcapelaSpeechStatusOutputPaused ;  // NSNumber
NSString *const AcapelaSpeechStatusNumberOfCharactersLeft ;  // NSNumber
NSString *const AcapelaSpeechStatusPhonemeCode ;  // NSNumber

// Dictionary keys returned by AcapelaSpeechErrorProperty
extern NSString *const AcapelaSpeechErrorCount ;  // NSNumber
extern NSString *const AcapelaSpeechErrorOldestCode ;  // NSNumber
extern NSString *const AcapelaSpeechErrorOldestCharacterOffset ;  // NSNumber
extern NSString *const AcapelaSpeechErrorNewestCode ;  // NSNumber
extern NSString *const AcapelaSpeechErrorNewestCharacterOffset ;  // NSNumber
extern NSString *const AcapelaSpeechErrorOldestNLPcode ;
extern NSString *const AcapelaSpeechErrorOldestSYNTHcode ;
extern NSString *const AcapelaSpeechErrorNewestNLPcode ;  // NSNumber
extern NSString *const AcapelaSpeechErrorNewestSYNTHcode ;  // NSNumber

// Dictionary keys returned by AcapelaSpeechSynthesizerInfoProperty
extern NSString *const AcapelaSpeechSynthesizerInfoIdentifier ;  // NSString
extern NSString *const AcapelaSpeechSynthesizerInfoVersion ;  // NSString

// Dictionary keys returned by AcapelaSpeechPhonemeSymbolsProperty
NSString *const AcapelaSpeechPhonemeInfoOpcode ;  // NSNumber
NSString *const AcapelaSpeechPhonemeInfoSymbol ;  // NSString
NSString *const AcapelaSpeechPhonemeInfoExample ;  // NSString
NSString *const AcapelaSpeechPhonemeInfoHiliteStart ;  // NSNumber
NSString *const AcapelaSpeechPhonemeInfoHiliteEnd ;  // NSNumber

// Dictionary keys returned by AcapelaSpeechCommandDelimiterProperty
extern NSString *const AcapelaSpeechCommandPrefix ;  // NSString
extern NSString *const AcapelaSpeechCommandSuffix ;  // NSString

// Use with addSpeechDictionary:
NSString *const AcapelaSpeechDictionaryLocaleIdentifier ;  // NSString
NSString *const AcapelaSpeechDictionaryModificationDate ;  // NSString
NSString *const AcapelaSpeechDictionaryPronunciations ;  // NSArray
NSString *const AcapelaSpeechDictionaryAbbreviations ;  // NSArray
NSString *const AcapelaSpeechDictionaryEntrySpelling ;  // NSString
NSString *const AcapelaSpeechDictionaryEntryPhonemes ;  // NSString
