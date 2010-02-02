//
//  BlioAudioBookManager.m
//  BlioApp
//
//  Created by Arnold Chien on 1/26/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import "BlioAudioBookManager.h"


@implementation BlioAudioBookManager

@synthesize times, queuedTimes, avPlayer, timingFiles, timeIx, queueIx, timeStarted, pausedAtTime, lastOnPageTime;

- (void)loadTimesFromFile:(NSString*)audioTimingPath {
	FILE* timingFile;
	char lineBuffer[BUFSIZ];
	timingFile = fopen([audioTimingPath cStringUsingEncoding:NSASCIIStringEncoding],"r");
	NSMutableArray* fileTimes = [[NSMutableArray alloc] init];
	while (fgets(lineBuffer, sizeof(lineBuffer),timingFile)) {
		NSString* thisLine = [NSString stringWithUTF8String:lineBuffer];
		NSRange initRange;
		initRange.location = 0;
		initRange.length = 2;
		if ( [[thisLine substringWithRange:initRange] compare:@"05"] != NSOrderedSame )
			continue;
		NSRange timeRange;
		timeRange.location = [thisLine rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location + 1;
		timeRange.length = [[thisLine substringFromIndex:timeRange.location]  rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location;
		NSString* thisTimeStr = [thisLine substringWithRange:timeRange];
		//NSNumber* thisTime = [[NSNumber alloc] initWithInt:atoi([thisTimeStr cStringUsingEncoding:NSASCIIStringEncoding])];
		//[fileTimes addObject:thisTime];
		[fileTimes addObject:[[NSNumber alloc] initWithInt:atoi([thisTimeStr cStringUsingEncoding:NSASCIIStringEncoding])]];
	}
	[self.queuedTimes addObject:fileTimes];
	fclose(timingFile);
}

- (void)fillTimingQueue:(NSString*)indexTimingPath {
	NSString* fileSuffix;
	for ( int i=0; i<[self.timingFiles count] ; ++i ) {
		fileSuffix = (NSString*)[self.timingFiles objectAtIndex:i];
		NSRange numRange;
		numRange.location = 1;
		numRange.length = [fileSuffix length] -1;
		NSRange extRange = [indexTimingPath rangeOfString:@".rtx"];
		NSString* timingPath = [[indexTimingPath substringToIndex:extRange.location] stringByAppendingString:[[@" " stringByAppendingString:fileSuffix] stringByAppendingString:@".rtx"]];
		[self loadTimesFromFile:timingPath];
	}
}

- (id)initWithPath:(NSString*)timingIndicesPath {
	if ( (self = [super init]) ) {
		[self setAvPlayer:nil]; 
		[self setTimingFiles:[[NSMutableArray alloc] init]];
		[self setTimes:[[NSMutableArray alloc] init]];
		[self setQueuedTimes:[[NSMutableArray alloc] init]];
		[self retrieveTimingIndices:timingIndicesPath];
		[self fillTimingQueue:timingIndicesPath];
		[self setStartedPlaying:NO]; 
		[self setPausedAtTime:0]; 
		[self setLastOnPageTime:0];
	}
	return self;
}

- (BOOL)initAudioWithBook:(NSString*)audioBookPath {
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

- (void)playAudio {
	[self setTimeStarted:[avPlayer currentTime]];
	//[self setTimeStarted:[[NSDate date] timeIntervalSince1970]];
	[avPlayer play];
}

- (void)stopAudio {
	[self.speakingTimer invalidate];
	[self setStartedPlaying:NO];
	[avPlayer stop];
}

- (void)pauseAudio {
	[avPlayer pause];
	[self.speakingTimer invalidate];
	int i;
	// The timer doesn't stop as quickly as the audio stops, so timeIx 
	// gets a little bit ahead.  Use currentTime to reset it.
	for ( i=0;i<[times count];++i) {
		if ( [[self.times objectAtIndex:i] intValue] > [avPlayer currentTime]*1000 )
			break;
	}
	self.timeIx = i;
	self.pausedAtTime = [[self.times objectAtIndex:self.timeIx] intValue];
	//NSLog(@"Pausing audio, timeIx is %d, lastTime is %d",self.timeIx,self.pausedAtTime);
}

@end
