//
//  BlioAudioManager.m
//  BlioApp
//
//  Created by Arnold Chien on 1/30/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import "BlioAudioManager.h"


@implementation BlioAudioManager

@synthesize currentWordOffset, adjustedWordOffset, currentBlock, currentWord, currentPage, startedPlaying, pageChanged, textToSpeakChanged, blockWords, speakingTimer;

- (void)dealloc {
    self.currentBlock = nil;
    [super dealloc];
}

- (void)adjustBlockWords {
	NSRange pageRange;
	pageRange.location = self.currentWordOffset - self.adjustedWordOffset;
	pageRange.length = [self.blockWords count] - (self.currentWordOffset- self.adjustedWordOffset);
	NSArray* subBlock = [self.blockWords subarrayWithRange:pageRange];
	[self setBlockWords:subBlock];
	[self setAdjustedWordOffset:self.currentWordOffset];
}

@end
