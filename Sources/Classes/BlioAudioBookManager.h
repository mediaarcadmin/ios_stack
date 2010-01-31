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
	NSInteger timeStarted;
	NSInteger timeIx;
	NSInteger lastTime;
	AVAudioPlayer* avPlayer;
	NSMutableArray* timingFiles;
}

@property (nonatomic, retain) NSMutableArray* times;
@property (nonatomic, retain) NSMutableArray* timingFiles;
@property (nonatomic, retain) AVAudioPlayer* avPlayer;
@property (nonatomic, assign) NSInteger timeIx;
@property (nonatomic, assign) NSInteger lastTime;
@property (nonatomic, assign) NSInteger timeStarted;

- (id)initWithPath:(NSString*)indexTimingPath;
- (void)loadTimesFromFile:(NSString*)audioTimingPath;
- (BOOL)setAudioBook:(NSString*)audioBookPath;
- (void)retrieveTimingIndices:(NSString*)timingIndicesFile;
- (void)setAudioTiming:(NSString*)audioTimingFile;
- (void)playAudio;
- (void)stopAudio;
- (void)pauseAudio;

@end
