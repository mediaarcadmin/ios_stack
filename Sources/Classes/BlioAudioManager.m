//
//  BlioAudioManager.m
//  BlioApp
//
//  Created by Arnold Chien on 1/30/10.
//  Copyright 2010 Kurzweil Technologies Inc.. All rights reserved.
//

#import "BlioAudioManager.h"


@implementation BlioAudioManager

@synthesize currentWordOffset, currentBlock, currentPage, startedPlaying, pageChanged, textToSpeakChanged, blockWords, speakingTimer;

- (void)dealloc {
    [speakingTimer release];
    [blockWords release];
    [currentBlock release];
    
    [super dealloc];
}

@end
