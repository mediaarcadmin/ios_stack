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
		[self setSetupData:[[setupTTS alloc] init]];
		[self setEngine:[[[AcapelaSpeech alloc] init]autorelease]];
		[self setCurrentPage:-1];
		[self setBlockWords:nil];
		[self setTextToSpeakChanged:NO];
		[self setStartedPlaying:NO];
		[self setPageChanged:YES];
    }
    return self;
}

- (void)dealloc
{
    if(currentStringWithWordOffsets) {
        CFRelease(currentStringWithWordOffsets);
    }
    [engine release];
    [setupData release];
    [ttsLicense release];
    
    [super dealloc];
}

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

- (BOOL)startSpeakingWords:(NSArray *)words {
    if(currentStringWithWordOffsets) {
        CFRelease(currentStringWithWordOffsets);
    }
    
    // Create an attributed string so that we can look up word offsets for 
    // any location in it later (in -wordOffsetForCharacterRange:)
    CFMutableAttributedStringRef stringWithWordOffsets = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
    CFAttributedStringBeginEditing(stringWithWordOffsets);
    
    NSUInteger offset = 0;
    for(NSString *word in words) {
        NSUInteger wordLength = [word length];
        CFIndex oldLength = CFAttributedStringGetLength(stringWithWordOffsets);
        
        CFAttributedStringReplaceString(stringWithWordOffsets, CFRangeMake(oldLength, 0), (CFStringRef)word);
        CFAttributedStringReplaceString(stringWithWordOffsets, CFRangeMake(oldLength + wordLength, 0), CFSTR(" "));
        CFAttributedStringSetAttribute(stringWithWordOffsets, CFRangeMake(oldLength, wordLength + 1),
                                       CFSTR("wordOffset"), (CFTypeRef)[NSNumber numberWithUnsignedInteger:offset]);
        ++offset;
    }
    
    // Remove the trailing space we just added in the last iteration of the loop.
    CFIndex stringLength = CFAttributedStringGetLength(stringWithWordOffsets);
    if(stringLength) {
        CFAttributedStringReplaceString(stringWithWordOffsets, CFRangeMake(stringLength - 2, 1), CFSTR(""));
    }
    
    CFAttributedStringEndEditing(stringWithWordOffsets);
    
    currentStringWithWordOffsets = stringWithWordOffsets;
    
    NSString *stringToSpeak = (NSString *)CFAttributedStringGetString(currentStringWithWordOffsets);
    return [engine startSpeakingString:stringToSpeak];
}

- (BOOL)startSpeaking:(NSString *)string {
	return [self startSpeakingWords:[NSArray arrayWithObject:string]];
}

- (NSUInteger)wordOffsetForCharacterRange:(NSRange)characterRange
{
    NSNumber *wordOffsetNumber = (NSNumber *)CFAttributedStringGetAttribute(currentStringWithWordOffsets, 
                                                                            characterRange.location + characterRange.length,
                                                                            CFSTR("wordOffset"), NULL);
    return [wordOffsetNumber unsignedIntegerValue];
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
