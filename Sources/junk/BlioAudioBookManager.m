//
//  BlioAudioBookManager.m
//  BlioApp
//
//  Created by Arnold Chien on 1/26/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import "BlioAudioBookManager.h"
#import "BlioBook.h"
#import "BlioBookManager.h"
#import "BlioAlertManager.h"

@implementation BlioAudioBookManager

@synthesize avPlayer, timeIx, timeStarted, pausedAtTime, wordTimes, pageSegmentVals, pageSegments, audioFiles, timeFiles, currDictKey, highestPageIndex, pagesDict, bookID, pbwIndices;

- (id)initWithBookID:(NSManagedObjectID*)aBookID {
	if ( (self = [super init]) ) {
		[self setAvPlayer:nil]; 
		[self setWordTimes:[NSMutableArray array]];
		[self setPbwIndices:[NSMutableArray array]];
		[self setTimeFiles:[NSMutableArray array]];
		[self setAudioFiles:[NSMutableArray array]];
		[self setPagesDict:[NSMutableDictionary dictionary]];
		[self setBookID:aBookID];
		BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:aBookID];

		NSData * referencesData = [book manifestDataForKey:BlioManifestAudiobookReferencesKey];
		if (referencesData) {
			[self parseData:referencesData];
		}
		else {
			NSLog(@"WARNING: Data could not be obtained from audiobook References XML file!");
			[self disableAudio];
		}
		NSData * audiobookMetadata = [book manifestDataForKey:BlioManifestAudiobookMetadataKey];
		if (audiobookMetadata) {
			[self parseData:audiobookMetadata];
		}
		else {
			NSLog(@"WARNING: Data could not be obtained from audiobook Metadata XML file!");
			[self disableAudio];
		}
		
		[self setStartedPlaying:NO]; 
		[self setPausedAtTime:0]; 
		[self setPageChanged:YES];
	}
	return self;
}

- (void)dealloc {
	[wordTimes release];
	[pbwIndices release];
	[avPlayer release];
	[audioFiles release];
	[timeFiles release];
    [pagesDict release];
	[currDictKey release];
	[pageSegments release];
	[pageSegmentVals release];
    self.bookID = nil;
    [super dealloc];   
}

- (BOOL)initAudioWithIndex:(NSInteger)index {
	NSError* err;
	
	BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];

    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithData:[book manifestDataForKey:BlioManifestAudiobookDataFilesKey pathIndex:index]
                                                                   error:&err];
	self.avPlayer = player;
    [player release];
    
	self.avPlayer.volume = 1.0;   
	BOOL prepared = [self.avPlayer prepareToPlay];
	if ( err == nil && prepared )
		return YES;
	return NO;
}

// AC TESTING
- (NSMutableArray*)getPBWIndex:(NSString*)pbwIndexStr {
    NSUInteger firstCommaLoc = [pbwIndexStr rangeOfString:@","].location;
    if ( firstCommaLoc == NSNotFound )
        return nil;
    NSUInteger secondCommaLoc = [pbwIndexStr rangeOfString:@"," options:NSBackwardsSearch].location;
    NSRange pageIndexRange;
    pageIndexRange.location = 0;
    pageIndexRange.length = firstCommaLoc;
    NSString* pageIndexStr = [pbwIndexStr substringWithRange:pageIndexRange]; 
    NSRange blockIndexRange;
    blockIndexRange.location = pageIndexRange.location + pageIndexRange.length + 1;
    blockIndexRange.length = secondCommaLoc - blockIndexRange.location; 
    NSString* blockIndexStr = [pbwIndexStr substringWithRange:blockIndexRange]; 
    NSString* wordIndexStr = [pbwIndexStr substringFromIndex:secondCommaLoc+1];
    NSMutableArray* pbwIndex  = [[NSMutableArray alloc] init];
    [pbwIndex addObject:[NSNumber numberWithInt:[pageIndexStr intValue]]];
    [pbwIndex addObject:[NSNumber numberWithInt:[blockIndexStr intValue]]];
    [pbwIndex addObject:[NSNumber numberWithInt:[wordIndexStr intValue]]];
    return [pbwIndex autorelease];
}


- (BOOL)loadWordTimesWithIndex:(NSInteger)index {

	NSString* thisTimeStr = nil;
	int lastTime;

	BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
	NSMutableArray* fileTimes = [[NSMutableArray alloc] init];
	NSData * timingData = [book manifestDataForKey:BlioManifestAudiobookTimingFilesKey pathIndex:index];
	NSString * timingDataString = [[NSString alloc] initWithData:timingData encoding:NSASCIIStringEncoding];
//	NSLog(@"timingDataString: %@",timingDataString);
	NSArray * timingLines = [timingDataString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
//	NSLog(@"[timingLines count]: %i",[timingLines count]);
    
    BOOL pbwColumn = YES;
	for (NSString * thisLine in timingLines) {
		if ([thisLine length] > 0) {
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
			[fileTimes addObject:[NSNumber numberWithInt:lastTime]];
            
            // AC TESTING
            if ( pbwColumn ) {
                NSRange pbwIndexRange;
                pbwIndexRange.location = [thisLine rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet] options:NSBackwardsSearch].location + 1;
                pbwIndexRange.length = [thisLine length] - pbwIndexRange.location;
                NSString* pbwIndexStr = [thisLine substringWithRange:pbwIndexRange];
                NSMutableArray* pbwIndex = [self getPBWIndex:pbwIndexStr];
                if (pbwIndex) {
                    // TODO? set member boolean that this rtx file has pbw indices
                    [self.pbwIndices addObject:pbwIndex];
                }
                else
                    pbwColumn = NO;
            }
		}
	}
    

// OPENING FILE DIRECTLY
//
//	while (fgets(lineBuffer, sizeof(lineBuffer),timingFile)) {
//		NSString* thisLine = [NSString stringWithUTF8String:lineBuffer];
//		NSRange initRange;
//		initRange.location = 0;
//		initRange.length = 2;
//		if ( [[thisLine substringWithRange:initRange] compare:@"05"] != NSOrderedSame )
//			continue;
//		NSRange timeRange;
//		timeRange.location = [thisLine rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location + 1;
//		timeRange.length = [[thisLine substringFromIndex:timeRange.location]  rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location;
//		thisTimeStr = [thisLine substringWithRange:timeRange];
//		lastTime = atoi([thisTimeStr cStringUsingEncoding:NSASCIIStringEncoding]);
//		[fileTimes addObject:[NSNumber numberWithInt:lastTime]];
//	}
	
	if ( thisTimeStr == nil ) {
//		NSLog(@"Empty timing file, %s", [audioTimingPath cStringUsingEncoding:NSASCIIStringEncoding]);
		NSLog(@"Empty timing data, %@", timingDataString);
        [fileTimes release];
        [timingDataString release];
		return NO;
	}
	self.wordTimes = fileTimes;
    [fileTimes release];
	[timingDataString release];
//	fclose(timingFile);
	return YES;
}

- (void)parseData:(NSData*)data  {
	// Prepare to parse the xml file.
//	NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
	NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:data];
	[xmlParser setDelegate:self];
//	[url release];	
	// Start the parse.
	BOOL parsedReferences = [xmlParser parse];
	[xmlParser release]; 
	if ( !parsedReferences ) {
//		NSLog(@"Failed to parse audio data file: %s\n",path);
		NSLog(@"Failed to parse audio data: %@",data);
		return;
	}
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

- (void)disableAudio {
	[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Audiobook Error",@"\"Audiobook Error\" alert message title")
								 message:NSLocalizedStringWithDefaultValue(@"AUDIOBOOK_CANNOT_BE_READ",nil,[NSBundle mainBundle],@"The audiobook cannot be read. Please contact Blio technical support.",@"Alert message when audiobook cannot be read.")
								delegate:nil 
					   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
					   otherButtonTitles: nil];
	// This will cause audio to go over to TTS.
	// Would it be better to just disable audio??
//	[[BlioBookManager sharedBookManager] bookWithID:self.bookID].audiobook = NO;
	
}

- (void)playAudio {
	[self setTimeStarted:[avPlayer currentTime]];
	[avPlayer play];
}

- (void)stopAudio {
	[self.speakingTimer invalidate];
	[self setStartedPlaying:NO];
	[avPlayer stop];
}

- (void)pauseAudio {
	[self.speakingTimer invalidate];
	//[self setStartedPlaying:NO];
	[avPlayer pause];
	/*int i;
	// The timer doesn't stop as quickly as the audio stops, so timeIx 
	// gets a little bit ahead.  Use currentTime to reset it.
	for ( i=0;i<[times count];++i) {
		if ( [[self.wordTimes objectAtIndex:i] intValue] + self.lastOnPageTime > [avPlayer currentTime]*1000 )
			break;
	}
	self.timeIx = i-1;
	*/
	//self.pausedAtTime = [[self.wordTimes objectAtIndex:self.timeIx] intValue];
	//NSLog(@"Pausing audio, timeIx is %d, pausedAtTime is %d",self.timeIx,self.pausedAtTime);
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	NSString* audioPath;
	if ( [elementName isEqualToString:@"Audio"] ) {
		audioPath = [attributeDict objectForKey:@"src"];
		[self.audioFiles addObject:audioPath];
	}
	else if ( [elementName isEqualToString:@"Timing"] ) {
		audioPath = [attributeDict objectForKey:@"src"];
		[self.timeFiles addObject:audioPath];
	}
	else if ( [elementName isEqualToString:@"Page"] ) {
		self.pageSegments = [NSMutableArray array];
		[self setCurrDictKey:[NSNumber numberWithInteger:[[attributeDict objectForKey:@"PageIndex"] integerValue]]];
	}
	else if ( [elementName isEqualToString:@"AudioSegment"] ) {
		self.pageSegmentVals = [NSMutableArray arrayWithCapacity:3];
		[pageSegmentVals addObject:[attributeDict objectForKey:@"TimeIndex"]];
		[pageSegmentVals addObject:[attributeDict objectForKey:@"TimeOffset"]];
	}
	else if ( [elementName isEqualToString:@"AudioRef"] ) {
		[pageSegmentVals addObject:[attributeDict objectForKey:@"AudioRefIndex"]];
		[pageSegments addObject:pageSegmentVals];
		self.pageSegmentVals  = nil;
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	if ( [elementName isEqualToString:@"AudioReferences"]  ) {
		if ( [self.timeFiles count] != [self.audioFiles count] ) {
			[self disableAudio];
		}
	}
	else if ( [elementName isEqualToString:@"Page"] ) {
		[self.pagesDict setObject:pageSegments forKey:self.currDictKey];
		self.pageSegments = nil;
        if([self.currDictKey integerValue] > self.highestPageIndex) {
            self.highestPageIndex = [self.currDictKey integerValue];
        }
	}
}

@end