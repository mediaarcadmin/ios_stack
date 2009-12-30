//
//  BlioTestParagraphWords.m
//  BlioApp
//
//  Created by James Montgomerie on 29/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioTestParagraphWords.h"


@implementation BlioTestParagraphWords

- (void)getParagraph
{
    if(_currentParagraphId) {
        NSLog(@"%@", [_book paragraphWordsForParagraphWithId:_currentParagraphId]);
        _currentParagraphId = [_book paragraphIdForParagraphAfterParagraphWithId:_currentParagraphId];
        [self performSelector:@selector(getParagraph) withObject:nil afterDelay:0.5];
    }
}

- (void)startParagraphGettingFromBook:(EucEPubBook*)book atParagraphWithId:(uint32_t)paragraphId;
{
    _currentParagraphId = paragraphId;
    _book = [book retain]; 
    [self performSelector:@selector(getParagraph) withObject:nil afterDelay:0.5];
}

- (void)stopParagraphGetting
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [_book release];
}

@end
