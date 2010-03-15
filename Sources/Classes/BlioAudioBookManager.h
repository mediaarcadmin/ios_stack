//
//  BlioAudioBookManager.h
//  BlioApp
//
//  Created by Arnold Chien on 1/26/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import "BlioAudioManager.h"

#define PAGE_TIMING_DELTA 250

typedef enum {
    kTimeIndex = 0,
    kTimeOffset = 1,
    kAudioRefIndex = 2,
} AudioSegmentInfo;

@interface BlioAudioBookManager : BlioAudioManager {
	NSMutableArray* wordTimes;
	NSInteger timeStarted;
	NSInteger timeIx;
	NSInteger pausedAtTime;
	AVAudioPlayer* avPlayer;
	NSMutableArray* audioFiles;
	NSMutableArray* timeFiles;
	NSXMLParser* xmlParser;
	NSMutableDictionary* pagesDict;
	NSString* currDictKey;
	NSMutableArray* pageSegments;
	NSMutableArray* pageSegmentVals;
	
	// obsolete
	NSMutableArray* times;
	NSMutableArray* timingFiles;
	NSInteger lastOnPageTime;
	NSInteger queueIx;
	NSMutableArray* queuedTimes; // Not really a queue, but the term is handy.
	NSMutableArray* queuedEndTimes; 
}

@property (nonatomic, retain) NSMutableArray* times;
@property (nonatomic, retain) NSMutableArray* wordTimes;
@property (nonatomic, retain) NSMutableArray* queuedTimes;
@property (nonatomic, retain) NSMutableArray* queuedEndTimes;
@property (nonatomic, retain) NSMutableArray* timingFiles;
@property (nonatomic, retain) NSMutableArray* audioFiles;
@property (nonatomic, retain) NSMutableArray* timeFiles;
@property (nonatomic, retain) NSMutableArray* pageSegments;
@property (nonatomic, retain) NSMutableArray* pageSegmentVals;
@property (nonatomic, retain) NSMutableDictionary* pagesDict;
@property (nonatomic, retain) AVAudioPlayer* avPlayer;
@property (nonatomic, retain) NSString* currDictKey;
@property (nonatomic, assign) NSInteger timeIx;
@property (nonatomic, assign) NSInteger queueIx;
@property (nonatomic, assign) NSInteger pausedAtTime;
@property (nonatomic, assign) NSInteger lastOnPageTime;
@property (nonatomic, assign) NSInteger timeStarted;

- (id)initWithPath:(NSString*)referencesPath metadataPath:(NSString*)metadataPath;
// - (void)loadTimesFromFile:(NSString*)audioTimingPath;
- (BOOL)loadWordTimesFromFile:(NSString*)audioTimingPath;
- (BOOL)initAudioWithBook:(NSString*)audioBookPath;
- (void)retrieveTimingIndices:(NSString*)timingIndicesFile;
- (void)playAudio;
- (void)stopAudio;
- (void)pauseAudio;

@end
