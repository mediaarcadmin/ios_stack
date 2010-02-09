//
//  BlioAudioBookManager.m
//  BlioApp
//
//  Created by Arnold Chien on 1/26/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import "BlioAudioBookManager.h"


@implementation BlioAudioBookManager

@synthesize times, queuedTimes, queuedEndTimes, avPlayer, timingFiles, timeIx, queueIx, timeStarted, pausedAtTime, lastOnPageTime;

- (void)loadTimesFromFile:(NSString*)audioTimingPath {
	FILE* timingFile;
	char lineBuffer[BUFSIZ];
	timingFile = fopen([audioTimingPath cStringUsingEncoding:NSASCIIStringEncoding],"r");
	NSMutableArray* fileTimes = [[NSMutableArray alloc] init];
	NSString* thisTimeStr = nil;
	int lastTime;
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
		thisTimeStr = [thisLine substringWithRange:timeRange];
		lastTime = atoi([thisTimeStr cStringUsingEncoding:NSASCIIStringEncoding]);
		[fileTimes addObject:[[NSNumber alloc] initWithInt:lastTime]];
	}
	if ( thisTimeStr == nil ) {
		NSLog(@"Empty timing file, %s", [audioTimingPath cStringUsingEncoding:NSASCIIStringEncoding]);
		return;
	}
	[self.queuedTimes addObject:fileTimes];
	// Get duration of last word in this file
	NSRange endTimeRange;
	endTimeRange.location = [thisTimeStr rangeOfString:@","].location + 1;
	endTimeRange.length = [[thisTimeStr substringFromIndex:endTimeRange.location]  rangeOfString:@","].location;
	NSString* endTimeStr = [thisTimeStr substringWithRange:endTimeRange];
	[self.queuedEndTimes addObject:[[NSNumber alloc] initWithInt:atoi([endTimeStr cStringUsingEncoding:NSASCIIStringEncoding])]];
	NSLog(@"Adding end time: %d",[[[NSNumber alloc] initWithInt:atoi([endTimeStr cStringUsingEncoding:NSASCIIStringEncoding])] intValue]);
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
		[self setQueuedEndTimes:[[NSMutableArray alloc] init]];
		[self retrieveTimingIndices:timingIndicesPath];
		[self fillTimingQueue:timingIndicesPath];
		[self setStartedPlaying:NO]; 
		[self setPausedAtTime:0]; 
		[self setLastOnPageTime:0];
		[self setPageChanged:YES];
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
		if ( [[self.times objectAtIndex:i] intValue] + self.lastOnPageTime > [avPlayer currentTime]*1000 )
			break;
	}
	self.timeIx = i-1;
	self.pausedAtTime = [[self.times objectAtIndex:self.timeIx] intValue] + self.lastOnPageTime;
	NSLog(@"Pausing audio, timeIx is %d, pausedAtTime is %d",self.timeIx,self.pausedAtTime);
}

@end
