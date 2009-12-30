//
//  BlioTestParagraphWords.h
//  BlioApp
//
//  Created by James Montgomerie on 29/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libEucalyptus/EucEPubBook.h>

@interface BlioTestParagraphWords : NSObject {
    uint32_t _currentParagraphId;
    EucEPubBook *_book;
}

- (void)startParagraphGettingFromBook:(EucEPubBook*)book atParagraphWithId:(uint32_t)paragraphId;
- (void)stopParagraphGetting;

@end
