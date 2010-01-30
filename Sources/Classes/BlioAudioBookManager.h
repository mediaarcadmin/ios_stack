//
//  BlioAudioBookManager.h
//  BlioApp
//
//  Created by Arnold Chien on 1/26/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

@interface BlioAudioBookManager : NSObject {
	NSMutableArray* times;
	int timeStarted;
	int timeIx;
	AVAudioPlayer* avPlayer;
	NSTimer* readingTimer;
	BOOL startedPlaying;
	NSMutableArray* timingFiles;
}

@property (nonatomic, retain) NSMutableArray* times;
@property (nonatomic, retain) NSMutableArray* timingFiles;
@property (nonatomic, retain) AVAudioPlayer* avPlayer;
@property (nonatomic, retain) NSTimer* readingTimer;
@property (nonatomic, assign) BOOL startedPlaying;

- (id)initWithAudioBook:(NSString*)audioBookPath audioTiming:(NSString*)audioTimingPath;
- (void)loadTimesFromFile:(NSString*)audioTimingPath;
- (BOOL)setAudioBook:(NSString*)audioBookPath;
- (void)retrieveTimingIndices:(NSString*)timingIndicesFile;
- (void)setAudioTiming:(NSString*)audioTimingFile;
- (void)playAudio;
- (void)stopAudio;
- (void)pauseAudio;

@end
