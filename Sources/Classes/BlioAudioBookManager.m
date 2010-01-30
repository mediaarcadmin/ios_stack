//
//  BlioAudioBookManager.m
//  BlioApp
//
//  Created by Arnold Chien on 1/26/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import "BlioAudioBookManager.h"


@implementation BlioAudioBookManager

@synthesize times, avPlayer, readingTimer, startedPlaying, timingFiles;

- (void)loadTimesFromFile:(NSString*)audioTimingPath {
	FILE* timingFile;
	char lineBuffer[BUFSIZ];
	timingFile = fopen([audioTimingPath cStringUsingEncoding:NSASCIIStringEncoding],"r");
	while (fgets(lineBuffer, sizeof(lineBuffer),timingFile)) {
		NSString* thisLine = [NSString stringWithUTF8String:lineBuffer];
		//NSLog(thisLine);
		NSRange initRange;
		initRange.location = 0;
		initRange.length = 2;
		if ( [[thisLine substringWithRange:initRange] compare:@"05"] != NSOrderedSame )
			continue;
		NSRange timeRange;
		timeRange.location = [thisLine rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location + 1;
		timeRange.length = [[thisLine substringFromIndex:timeRange.location]  rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location;
		NSString* thisTimeStr = [thisLine substringWithRange:timeRange];
		NSNumber* thisTime = [[NSNumber alloc] initWithInt:atoi([thisTimeStr cStringUsingEncoding:NSASCIIStringEncoding])];
		[self.times addObject:thisTime];
	}
	fclose(timingFile);
}

- (id)initWithPath:(NSString*)indexTimingPath {
	if ( (self = [super init]) ) {
		[self setAvPlayer:nil]; 
		[self setTimingFiles:[[NSMutableArray alloc] init]];
		[self retrieveTimingIndices:indexTimingPath];
		[self setStartedPlaying:NO]; 
	}
	return self;
}

- (BOOL)setAudioBook:(NSString*)audioBookPath {
	if ( self.avPlayer != nil )
		[self.avPlayer release];
	NSError* err;
	self.avPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:audioBookPath] 
													  error:&err];
	self.avPlayer.volume = 1.0;    // Will get from settings.
	BOOL prepared = [self.avPlayer prepareToPlay];
	if ( err == nil && prepared )
		return YES;
	return NO;
}

- (void)retrieveTimingIndices:(NSString*)timingIndicesFile {	
	FILE* indexFile;
	char lineBuffer[BUFSIZ];
	indexFile = fopen([timingIndicesFile cStringUsingEncoding:NSASCIIStringEncoding],"r");
	while (fgets(lineBuffer, sizeof(lineBuffer),indexFile)) {
		NSString* thisLine = [NSString stringWithUTF8String:lineBuffer];
		NSRange eolRange = [thisLine rangeOfString:@"\r\n"];
		if ( eolRange.location != NSNotFound ) 
			thisLine = [thisLine substringToIndex:eolRange.location];
		[self.timingFiles addObject:thisLine];
	}
	fclose(indexFile);
}

- (void)setAudioTiming:(NSString*)audioTimingPath {	
	if ( self.times != nil )
		[self.times release];
	[self loadTimesFromFile:audioTimingPath];
}

- (void)playAudio {
	[avPlayer play];
}

- (void)stopAudio {
	[avPlayer stop];
	[self setStartedPlaying:NO];
}

- (void)pauseAudio {
	[avPlayer pause];
}

@end
