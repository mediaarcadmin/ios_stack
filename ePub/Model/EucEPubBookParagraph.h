//
//  EucEPubBookParagraph.h
//  Eucalyptus
//
//  Created by James Montgomerie on 26/07/2009.
//  Copyright 2009 James Montgomerie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucBookParagraph.h"

@class EucBookTextStyle;

@interface EucEPubBookParagraph : NSObject <EucBookParagraph> {
    size_t _byteOffset;
    size_t _nextParagraphByteOffset;
    
    NSArray *_words;
    NSArray *_wordFormattingAttributes;
    
    EucBookTextStyle *_globalStyle;
}

@property (nonatomic, readonly) EucBookTextStyle *globalStyle;

- (id)initWithWords:(NSArray *)words 
wordFormattingAttributes:(NSArray *)wordFormattingAttributes 
         byteOffset:(size_t)byteOffset 
nextParagraphByteOffset:(size_t)nextParagraphByteOffset
        globalStyle:(EucBookTextStyle *)globalStyle;

@end
