//
//  BlioAudioManager.h
//  BlioApp
//
//  Created by Arnold Chien on 1/30/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BlioAudioManager : NSObject {
	id currentParagraph;
	uint32_t currentWordOffset;
	uint32_t adjustedWordOffset;
	uint32_t currentPage;
	NSArray* paragraphWords;
	NSTimer* speakingTimer;
	BOOL startedPlaying;
	// TTS
	BOOL textToSpeakChanged; 
	NSString* currentWord;
}

@property (nonatomic, retain) NSArray* paragraphWords;
@property (nonatomic, retain) NSString* currentWord;
@property (nonatomic, retain) NSTimer* speakingTimer;
@property (nonatomic, retain) id currentParagraph;
@property (nonatomic) uint32_t currentWordOffset;
@property (nonatomic) uint32_t adjustedWordOffset;
@property (nonatomic) uint32_t currentPage; 
@property (nonatomic, assign) BOOL startedPlaying;
@property (nonatomic) BOOL textToSpeakChanged; 

- (void)adjustParagraphWords;

@end
