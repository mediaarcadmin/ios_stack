//
//  BlioAudioBookManager.m
//  BlioApp
//
//  Created by Arnold Chien on 1/26/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import "BlioAudioBookManager.h"


@implementation BlioAudioBookManager

@synthesize avPlayer, timeIx, timeStarted, pausedAtTime, wordTimes, pageSegmentVals, pageSegments, audioFiles, timeFiles, currDictKey, pagesDict;

- (BOOL)loadWordTimesFromFile:(NSString*)audioTimingPath {
	FILE* timingFile = NULL;
	char lineBuffer[BUFSIZ];
	timingFile = fopen([audioTimingPath cStringUsingEncoding:NSASCIIStringEncoding],"r");
	if ( !timingFile ) {
		NSLog(@"Timing file could not be opened.");
		return NO;
	}
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
		return NO;
	}
	self.wordTimes = fileTimes;
	fclose(timingFile);
	return YES;
}

- (void)parseData:(NSString*)path  {
	// Prepare to parse the xml file.
	NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
	xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:url];
	[xmlParser setDelegate:self];
	[url release];	
	// Start the parse.
	BOOL parsedReferences = [xmlParser parse];
	[xmlParser release]; 
	if ( !parsedReferences ) {
		NSLog(@"Failed to parse audio data file: %s\n",path);
		return;
	}
}

- (id)initWithPath:(NSString*)referencesPath metadataPath:(NSString*)metadataPath{
	if ( (self = [super init]) ) {
		[self setAvPlayer:nil]; 
		[self setWordTimes:[[NSMutableArray alloc] init]];
		[self setTimeFiles:[[NSMutableArray alloc] init]];
		[self setAudioFiles:[[NSMutableArray alloc] init]];
		[self setPagesDict:[[NSMutableDictionary alloc] init]];
		[self parseData:referencesPath];
		[self parseData:metadataPath];
		[self setStartedPlaying:NO]; 
		[self setPausedAtTime:0]; 
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
	self.avPlayer.volume = 1.0;   
	BOOL prepared = [self.avPlayer prepareToPlay];
	if ( err == nil && prepared )
		return YES;
	return NO;
}

/*
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
 */

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
	/*int i;
	// The timer doesn't stop as quickly as the audio stops, so timeIx 
	// gets a little bit ahead.  Use currentTime to reset it.
	for ( i=0;i<[times count];++i) {
		if ( [[self.wordTimes objectAtIndex:i] intValue] + self.lastOnPageTime > [avPlayer currentTime]*1000 )
			break;
	}
	self.timeIx = i-1;
	*/
	self.pausedAtTime = [[self.wordTimes objectAtIndex:self.timeIx] intValue];// + self.lastOnPageTime;
	NSLog(@"Pausing audio, timeIx is %d, pausedAtTime is %d",self.timeIx,self.pausedAtTime);
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	NSString* audioPath;
	if ( [elementName isEqualToString:@"Audio"] ) {
		// Kluge, change this - just add filename here, make into a path in bookview ctlr.
		//[book.bookCacheDirectory stringByAppendingPathComponent:filename];
		audioPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/AudioBooks/Graveyard Book/"] stringByAppendingString:[attributeDict objectForKey:@"src"]];
		[self.audioFiles addObject:audioPath];
	}
	else if ( [elementName isEqualToString:@"Timing"] ) {
		// Kluge, change this
		audioPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/AudioBooks/Graveyard Book/"] stringByAppendingString:[attributeDict objectForKey:@"src"]];
		[self.timeFiles addObject:audioPath];
	}
	else if ( [elementName isEqualToString:@"Page"] ) {
		pageSegments = [[NSMutableArray alloc] init];
		[self setCurrDictKey:[attributeDict objectForKey:@"PageIndex"]];
	}
	else if ( [elementName isEqualToString:@"AudioSegment"] ) {
		pageSegmentVals = [[NSMutableArray alloc] initWithCapacity:3];
		[pageSegmentVals addObject:[attributeDict objectForKey:@"TimeIndex"]];
		[pageSegmentVals addObject:[attributeDict objectForKey:@"TimeOffset"]];
	}
	else if ( [elementName isEqualToString:@"AudioRef"] ) {
		[pageSegmentVals addObject:[attributeDict objectForKey:@"AudioRefIndex"]];
		[pageSegments addObject:pageSegmentVals];
		[pageSegmentVals release];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	if ( [elementName isEqualToString:@"AudioReferences"]  ) {
		if ( [self.timeFiles count] != [self.audioFiles count] ) {
			NSLog(@"Missing audio or timing file.");
			// TODO: Disable audiobook playback.
		}
	}
	else if ( [elementName isEqualToString:@"Page"] ) {
		[self.pagesDict setObject:pageSegments forKey:self.currDictKey];
		[pageSegments release];
	}
}

@end
