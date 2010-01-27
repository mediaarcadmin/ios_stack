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
}

@property (nonatomic, retain) NSMutableArray* times;
@property (nonatomic, retain) AVAudioPlayer* avPlayer;
@property (nonatomic, retain) NSTimer* readingTimer;

- (id)initWithAudioBook:(NSString*)audioBookPath audioTiming:(NSString*)audioTimingPath;
- (void)setAudioBook:(NSString*)audioBookPath;
- (void)setAudioTiming:(NSString*)audioTimingPath;
- (void)playAudio;
- (void)stopAudio;

@end
