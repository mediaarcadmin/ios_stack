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

@synthesize downloadQueue,voiceData,sampleAudioPlayer;
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
        
		if (![[NSUserDefaults standardUserDefaults] objectForKey:kBlioLastVoiceDefaultsKey] && [[AcapelaSpeech availableVoices] count] > 0) {
			NSLog(@"No voice default set; however, a voice has been found, so the default will be set to that voice...");
			[[NSUserDefaults standardUserDefaults] setObject:[[AcapelaSpeech availableVoices] objectAtIndex:0] forKey:kBlioLastVoiceDefaultsKey];
		}
		
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
}
-(NSArray*)availableVoiceNamesForUse {
	NSArray * availableVoices = [AcapelaSpeech availableVoices];
	NSMutableArray * availableVoiceNames = [NSMutableArray arrayWithCapacity:[availableVoices count]];
	for (NSString * voice in availableVoices) {
		[availableVoiceNames addObject:[BlioAcapelaAudioManager voiceNameForVoice:voice]];
	}
	return availableVoiceNames;
}
-(NSArray*)availableVoicesForDownload {
	NSMutableArray * voices = [NSMutableArray array];
	NSArray * availableVoicesForUse = [AcapelaSpeech availableVoices];
	for (NSString * key in self.voiceData) {
		if (![availableVoicesForUse containsObject:key]) [voices addObject:key];
	}
	if ([voices count] > 0) return voices;
	return nil;
}
- (BOOL)voiceHasChanged {
	return !self.engine || ![self.engine.voice isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:kBlioLastVoiceDefaultsKey]];
}

- (void)setEngineWithPreferences {
	if ([self voiceHasChanged]) {  
        self.engine = nil; // Nil it out before re-setting just to save some RAM.
		self.engine = [[[AcapelaSpeech alloc] initWithVoice:[[NSUserDefaults standardUserDefaults] objectForKey:kBlioLastVoiceDefaultsKey] license:ttsLicense] autorelease];
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
    // Remove the trailing space we just added in the last iteration of the loop,
    // Unless the stirng would be, by doing so, completly empty.
    if(stringLength > 1) {
        CFAttributedStringReplaceString(stringWithWordOffsets, CFRangeMake(stringLength - 1, 1), CFSTR(""));
    }

    CFAttributedStringEndEditing(stringWithWordOffsets);

    currentStringWithWordOffsets = stringWithWordOffsets;
    
    NSString *stringToSpeak = (NSString *)CFAttributedStringGetString(currentStringWithWordOffsets);
    return [engine startSpeakingString:stringToSpeak];
	
	// TESTING
	//return [engine startSpeakingString:@"In the bosom of one of those spacious coves which indent"];
    //[engine queueSpeakingString:@"the eastern shore of the Hudson"];
	
	//return NO;
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
-(void)playSampleForVoiceName:(NSString *)aVoiceName {
	if (self.sampleAudioPlayer && self.sampleAudioPlayer.playing == YES) [self.sampleAudioPlayer stop];
	NSDictionary * voiceDictionary = nil;
	for (id key in self.voiceData) {
		if ([[[self.voiceData objectForKey:key] objectForKey:BlioVoiceDataVoiceNameKey] isEqualToString:aVoiceName]) {
			voiceDictionary = [self.voiceData objectForKey:key];
			break;
		}
	}
	if (voiceDictionary) {
		NSString * sampleFilename = nil;
		sampleFilename = [voiceDictionary objectForKey:BlioVoiceDataSampleFilenameKey];
		if (sampleFilename) {
			NSError * sampleError = nil;
			self.sampleAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"voiceSamples"] stringByAppendingPathComponent:sampleFilename]] error:&sampleError];
			if (sampleError) {
				NSLog(@"ERROR: AVAudioPlayer sample audio could not be initialized for voiceName: %@. Error: %@,%@",aVoiceName,sampleError,[sampleError userInfo]); 
			}
			else {						  
				[self.sampleAudioPlayer play];
			}
		}
	}
	else {
		NSLog(@"WARNING: Could not find appropriate voice dictionary for voice: %@",aVoiceName);
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
			NSArray *paths2 = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
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
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Download Error",@"\"Download Error\" alert message title")
									 message:NSLocalizedStringWithDefaultValue(@"ERROR_WHILE_DOWNLOADING_VOICE",nil,[NSBundle mainBundle],@"The voice failed to download. Please try again later.",@"Alert message shown to end-user when the BlioProcessingDownloadAndUnzipVoiceOperation fails.")
									delegate:nil 
						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
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
