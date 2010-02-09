//
//  BlioAudioManager.m
//  BlioApp
//
//  Created by Arnold Chien on 1/30/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import "BlioAudioManager.h"


@implementation BlioAudioManager

@synthesize currentWordOffset, adjustedWordOffset, currentParagraph, currentWord, currentPage, startedPlaying, pageChanged, textToSpeakChanged, paragraphWords, speakingTimer;

- (void)dealloc {
    self.currentParagraph = nil;
    [super dealloc];
}

- (void)adjustParagraphWords {
	NSRange pageRange;
	pageRange.location = self.currentWordOffset - self.adjustedWordOffset;
	pageRange.length = [self.paragraphWords count] - (self.currentWordOffset- self.adjustedWordOffset);
	NSArray* subParagraph = [self.paragraphWords subarrayWithRange:pageRange];
	[self setParagraphWords:subParagraph];
	[self setAdjustedWordOffset:self.currentWordOffset];
}

@end
