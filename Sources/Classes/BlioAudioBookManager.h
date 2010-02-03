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

@interface BlioAudioBookManager : BlioAudioManager {
	NSMutableArray* times;
	NSMutableArray* queuedTimes; // Not really a queue, but the term is handy.
	NSMutableArray* queuedLastTimes; 
	NSInteger timeStarted;
	NSInteger timeIx;
	NSInteger queueIx;
	NSInteger pausedAtTime;
	NSInteger lastOnPageTime;
	AVAudioPlayer* avPlayer;
	NSMutableArray* timingFiles;
}

@property (nonatomic, retain) NSMutableArray* times;
@property (nonatomic, retain) NSMutableArray* queuedTimes;
@property (nonatomic, retain) NSMutableArray* queuedLastTimes;
@property (nonatomic, retain) NSMutableArray* timingFiles;
@property (nonatomic, retain) AVAudioPlayer* avPlayer;
@property (nonatomic, assign) NSInteger timeIx;
@property (nonatomic, assign) NSInteger queueIx;
@property (nonatomic, assign) NSInteger pausedAtTime;
@property (nonatomic, assign) NSInteger lastOnPageTime;
@property (nonatomic, assign) NSInteger timeStarted;

- (id)initWithPath:(NSString*)timingIndicesPath;
- (void)loadTimesFromFile:(NSString*)audioTimingPath;
- (BOOL)initAudioWithBook:(NSString*)audioBookPath;
- (void)retrieveTimingIndices:(NSString*)timingIndicesFile;
- (void)playAudio;
- (void)stopAudio;
- (void)pauseAudio;

@end
