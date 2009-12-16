//
//  EucEPubBookParagraph.m
//  libEucalyptus
//
//  Created by James Montgomerie on 26/07/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "EucEPubBookParagraph.h"
#import "EucBookTextStyle.h"

@implementation EucEPubBookParagraph

@synthesize byteOffset = _byteOffset;
@synthesize nextParagraphByteOffset = _nextParagraphByteOffset;
@synthesize words = _words;
@synthesize wordFormattingAttributes = _wordFormattingAttributes;
@synthesize globalStyle = _globalStyle;

- (id)initWithWords:(NSArray *)words 
wordFormattingAttributes:(NSArray *)wordFormattingAttributes 
         byteOffset:(size_t)byteOffset 
nextParagraphByteOffset:(size_t)nextParagraphByteOffset
        globalStyle:(EucBookTextStyle *)globalStyle
{
    if((self = [super init])) {
        _words = [words retain];
        _wordFormattingAttributes = [wordFormattingAttributes retain];
        
        _byteOffset = byteOffset;
        _nextParagraphByteOffset = nextParagraphByteOffset;
        
        _globalStyle = [globalStyle retain];
    }
    return self;
}

- (void)dealloc 
{
    [_words release];
    [_wordFormattingAttributes release];
    [_globalStyle release];
    [super dealloc];
}

@end
