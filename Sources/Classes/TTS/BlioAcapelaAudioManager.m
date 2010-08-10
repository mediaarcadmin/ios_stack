//
//  BlioAcapelaAudioManager.m
//  BlioApp
//
//  Created by Arnold Chien on 12/22/09.
//  Copyright 2009 Kurzweil Technologies Inc.. All rights reserved.
//


#import "BlioAppSettingsConstants.h"
#import "BlioAcapelaAudioManager.h"
#import "BlioProcessingStandardOperations.h"
#import "BlioAlertManager.h"

#include "Acapela/babkurz.lic.h"
#include "Acapela/babkurz.lic.01e560b3.password"

static NSString * BlioVoiceDataVoiceNameKey = @"voiceName";
static NSString * BlioVoiceDataSampleFilenameKey = @"sampleFilename";
static NSString * BlioVoiceDataURLKey = @"url";

NSString * const BlioVoiceListRefreshedNotification = @"BlioVoiceListRefreshedNotification";

@implementation BlioAcapelaAudioManager

@synthesize setupData, downloadQueue,voiceData,sampleAudioPlayer;
@synthesize engine, ttsLicense;

+(BlioAcapelaAudioManager*)sharedAcapelaAudioManager
{
	static BlioAcapelaAudioManager * sharedAcapelaAudioManager = nil;
	if (sharedAcapelaAudioManager == nil) {
		sharedAcapelaAudioManager = [[BlioAcapelaAudioManager alloc] init];
	}
	
	return sharedAcapelaAudioManager;
}

- (id)init {
    if ((self = [super init])) {
		NSString* licenseStr = [[NSString alloc] initWithCString:babLicense encoding:NSASCIIStringEncoding];
		[self setTtsLicense:[[[AcapelaLicense alloc] initLicense:licenseStr user:uid.userId passwd:uid.passwd] autorelease]];
		[licenseStr release];
		[self setSetupData:[[[setupTTS alloc] init] autorelease]];
		[self setEngine:[[[AcapelaSpeech alloc] init]autorelease]];
		[self setCurrentPage:-1];
		[self setBlockWords:nil];
		[self setTextToSpeakChanged:NO];
		[self setStartedPlaying:NO];
		[self setPageChanged:YES];
		self.downloadQueue = [[[NSOperationQueue alloc] init] autorelease];
		[self.downloadQueue setMaxConcurrentOperationCount:3];
		self.voiceData = [NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"BlioVoiceData.plist"]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingFailedNotification:) name:BlioProcessingOperationFailedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingCompleteNotification:) name:BlioProcessingOperationCompleteNotification object:nil];
		if (![[NSUserDefaults standardUserDefaults] objectForKey:kBlioLastVoiceDefaultsKey] && [[AcapelaSpeech availableVoices] count] > 0) {
			[[NSUserDefaults standardUserDefaults] setObject:[[AcapelaSpeech availableVoices] objectAtIndex:0] forKey:kBlioLastVoiceDefaultsKey];
		}

    }
    return self;
}

- (void)dealloc
{
    if(currentStringWithWordOffsets) {
        CFRelease(currentStringWithWordOffsets);
    }
	if (self.downloadQueue) [self.downloadQueue cancelAllOperations];
	self.downloadQueue = nil;
	self.voiceData = nil;
	self.sampleAudioPlayer = nil;
    [engine release];
    [ttsLicense release];
    [setupData release];
    
    [super dealloc];
}

+(NSString*)voiceNameForVoice:(NSString*)voice {
	if ([[BlioAcapelaAudioManager sharedAcapelaAudioManager].voiceData objectForKey:voice]) {
		NSDictionary * voiceFields = [[BlioAcapelaAudioManager sharedAcapelaAudioManager].voiceData objectForKey:voice];
		return [voiceFields objectForKey:BlioVoiceDataVoiceNameKey];
	}
//	N.B.: relying upon [AcapelaSpeech attributesForVoice:(NSString*)aVoice] is not preferred for now; the method doesn't work for Laura and Ryan, and if a non-existent voice is sent to this method, the app will crash (not robust). We're using voiceNames in our voiceData plist instead.
//	if ([voice isEqualToString:@"enu_laura_22k_ns.cvcu.411"]) {
//		return @"Laura";
//	}
//	else if ([voice isEqualToString:@"enu_ryan_22k_ns.cvcu.411"]) {
//		return @"Ryan";
//	}
//	else {
//		NSDictionary * voiceAtrributes = [AcapelaSpeech attributesForVoice:voice];
//		if (voiceAtrributes && [voiceAtrributes objectForKey:AcapelaVoiceName]) {
//			return [voiceAtrributes objectForKey:AcapelaVoiceName];
//		}
//	}
	return nil;
}

-(NSArray*)availableVoicesForUse {
	return [AcapelaSpeech availableVoices];
	return nil;
}
-(NSArray*)availableVoicesForDownload {
	NSMutableArray * voices = [NSMutableArray array];
	NSArray * availableVoicesForUse = [self availableVoicesForUse];
	for (NSString * key in self.voiceData) {
		if (![availableVoicesForUse containsObject:key]) [voices addObject:key];
	}
	if ([voices count] > 0) return voices;
	return nil;
}
- (BOOL)voiceHasChanged {
	return [self.setupData.currentVoice isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:kBlioLastVoiceDefaultsKey]];
//	return ((([[self.setupData CurrentVoiceName] compare:@"Laura"]==NSOrderedSame) && 
//			 [[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastVoiceDefaultsKey]!=(NSInteger)kAcapelaVoiceUSEnglishLaura) ||
//			(([[self.setupData CurrentVoiceName] compare:@"Ryan"]==NSOrderedSame) && 
//			 [[NSUserDefaults standardUserDefaults] integerForKey:kBlioLastVoiceDefaultsKey]!=(NSInteger)kAcapelaVoiceUSEnglishRyan));
}

- (void)setEngineWithPreferences:(BOOL)voiceChanged {
	if (voiceChanged) {  
		[self.setupData init];
		[self.engine initWithVoice:setupData.currentVoice license:ttsLicense];
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
        
    NSUInteger offset = self.currentWordOffset;
    NSArray *wordsToSpeak = words;
    if(offset) {
        wordsToSpeak = [wordsToSpeak subarrayWithRange:NSMakeRange(offset, wordsToSpeak.count - offset)];
    } 
    for(NSString *word in wordsToSpeak) {
        NSUInteger wordLength = [word length];
        CFIndex oldLength = CFAttributedStringGetLength(stringWithWordOffsets);
        CFAttributedStringReplaceString(stringWithWordOffsets, CFRangeMake(oldLength, 0), (CFStringRef)word);
        CFAttributedStringReplaceString(stringWithWordOffsets, CFRangeMake(oldLength + wordLength, 0), CFSTR(" "));
        CFAttributedStringSetAttribute(stringWithWordOffsets, CFRangeMake(oldLength, wordLength + 1),
                                       CFSTR("wordOffset"), (CFTypeRef)[NSNumber numberWithUnsignedInteger:offset]);
        ++offset;
    }

    CFIndex stringLength = CFAttributedStringGetLength(stringWithWordOffsets);
    // Remove the trailing space we just added in the last iteration of the loop.
    if(stringLength) {
        CFAttributedStringReplaceString(stringWithWordOffsets, CFRangeMake(stringLength - 1, 1), CFSTR(""));
    }

    CFAttributedStringEndEditing(stringWithWordOffsets);

    currentStringWithWordOffsets = stringWithWordOffsets;
    
    NSString *stringToSpeak = (NSString *)CFAttributedStringGetString(currentStringWithWordOffsets);
    return [engine startSpeakingString:stringToSpeak];
	return NO;
}

- (BOOL)startSpeaking:(NSString *)string {
	return [self startSpeakingWords:[NSArray arrayWithObject:string]];
}

- (NSUInteger)wordOffsetForCharacterRange:(NSRange)characterRange
{
    // Get the word offset for at the end of the range.
    CFIndex location = characterRange.location + (characterRange.length ? (characterRange.length - 1) : 0);
    NSNumber *wordOffsetNumber = (NSNumber *)CFAttributedStringGetAttribute(currentStringWithWordOffsets, 
                                                                            location,
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
	return NO;
}

- (float)rate {
	return [engine rate];
	return 0;
}

- (void)setRate:(float)rate; {
	[engine setRate:rate];
}

- (float)volume {
	return [engine volume];
	return 0;
}

- (void)setVolume:(float)volume {
	NSLog(@"setVolume: %f",volume);
	NSLog(@"is speaking: %i",[engine isSpeaking]);
	NSLog(@"engine: %@",[engine description]);
	[engine setVolume:volume];
}

- (id)delegate {
	return [engine delegate];
	return nil;
}

- (void)setDelegate:(id)delegate {
	[engine setDelegate:delegate];
}

- (BOOL)queueSpeakingString:(NSString *)string {
	return [engine queueSpeakingString:string];
	return NO;
}

- (id)objectForProperty:(NSString *)property error:(NSError **)outError {
	return [engine objectForProperty:property error:outError];
	return nil;
}
-(void)playSampleForVoice:(NSString *)aVoice {
	if (self.sampleAudioPlayer && self.sampleAudioPlayer.playing == YES) [self.sampleAudioPlayer stop];
	if ([self.voiceData objectForKey:aVoice]) {
		NSString * sampleFilename = nil;
		sampleFilename = [[self.voiceData objectForKey:aVoice] objectForKey:BlioVoiceDataSampleFilenameKey];
		if (sampleFilename) {
			NSError * sampleError = nil;
			self.sampleAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"voiceSamples"] stringByAppendingPathComponent:sampleFilename]] error:&sampleError];
			if (sampleError) {
				NSLog(@"ERROR: AVAudioPlayer sample audio could not be initialized for voice: %@. Error: %@,%@",aVoice,sampleError,[sampleError userInfo]); 
			}
			else {						  
				[self.sampleAudioPlayer play];
			}
		}
	}
}
-(void)downloadVoice:(NSString*)aVoice {
	if ([self.voiceData objectForKey:aVoice]) {
		
		NSString * urlString = [[self.voiceData objectForKey:aVoice] objectForKey:BlioVoiceDataURLKey];
		if (urlString) {
			BlioProcessingDownloadAndUnzipVoiceOperation * voiceOperation = [[BlioProcessingDownloadAndUnzipVoiceOperation alloc] initWithUrl:[NSURL URLWithString:urlString]];
			NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
			NSString *docsPath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
			voiceOperation.tempDirectory = docsPath;
			NSArray *paths2 = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
			NSString *docsPath2 = ([paths2 count] > 0) ? [paths2 objectAtIndex:0] : nil;
			voiceOperation.cacheDirectory = docsPath2;
			voiceOperation.filenameKey = [urlString lastPathComponent];
			voiceOperation.voice = aVoice;
			NSLog(@"adding BlioProcessingDownloadAndUnzipVoiceOperation to queue...");
			[self.downloadQueue addOperation:voiceOperation];
			[voiceOperation release];
		}
	}
}

- (void)onProcessingCompleteNotification:(NSNotification*)note {
	if ([[note object] isKindOfClass:[BlioProcessingDownloadAndUnzipVoiceOperation class]]) {
		NSLog(@"BlioAcapelaManager onProcessingCompleteNotification entered");
		[AcapelaSpeech refreshVoiceList];
		if ([[AcapelaSpeech availableVoices] count] == 1) {
			[[NSUserDefaults standardUserDefaults] setObject:[[AcapelaSpeech availableVoices] objectAtIndex:0] forKey:kBlioLastVoiceDefaultsKey];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:BlioVoiceListRefreshedNotification object:self];
	}
}
- (void)onProcessingFailedNotification:(NSNotification*)note {
	if ([[note object] isKindOfClass:[BlioProcessingDownloadAndUnzipVoiceOperation class]]) {
		NSLog(@"BlioAcapelaManager onProcessingFailedNotification entered");
		[AcapelaSpeech refreshVoiceList];
		[[NSNotificationCenter defaultCenter] postNotificationName:BlioVoiceListRefreshedNotification object:self];
		
		// show alert box
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"We're Sorry...",@"\"We're Sorry...\" alert message title")
									 message:NSLocalizedStringWithDefaultValue(@"ERROR_WHILE_DOWNLOADING_VOICE",nil,[NSBundle mainBundle],@"An error occurred while downloading this voice. Please try again later.",@"Alert message shown to end-user when the BlioProcessingDownloadAndUnzipVoiceOperation fails.")
									delegate:nil 
						   cancelButtonTitle:@"OK"
						   otherButtonTitles: nil];
		
	}
}
-(BlioProcessingDownloadAndUnzipVoiceOperation*)downloadVoiceOperationByVoice:(NSString*)aVoice {
	NSArray * operations = [self.downloadQueue operations];
	for (BlioProcessingDownloadAndUnzipVoiceOperation * op in operations) {
		if ([op isKindOfClass:[BlioProcessingDownloadAndUnzipVoiceOperation class]] && [op.voice isEqualToString:aVoice]) {
			return op;
		}
	}
	return nil;	
}
@end
