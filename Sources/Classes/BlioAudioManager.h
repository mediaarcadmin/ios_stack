//
//  BlioAudioManager.h
//  BlioApp
//
//  Created by Arnold Chien on 1/30/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BlioAudioManager : NSObject {
	id currentBlock;
	uint32_t currentWordOffset;
	uint32_t adjustedWordOffset;
	uint32_t currentPage;
	NSArray* blockWords;
	NSTimer* speakingTimer;
	BOOL startedPlaying;
	BOOL pageChanged;  // This means page has changed since the stop button was last pressed.
	// TTS
	BOOL textToSpeakChanged; 
	NSString* currentWord;
}

@property (nonatomic, retain) NSArray* blockWords;
@property (nonatomic, retain) NSString* currentWord;
@property (nonatomic, retain) NSTimer* speakingTimer;
@property (nonatomic, retain) id currentBlock;
@property (nonatomic) uint32_t currentWordOffset;
@property (nonatomic) uint32_t adjustedWordOffset;
@property (nonatomic) uint32_t currentPage; 
@property (nonatomic, assign) BOOL startedPlaying;
@property (nonatomic, assign) BOOL pageChanged;
@property (nonatomic) BOOL textToSpeakChanged; 

- (void)adjustBlockWords;

@end
