/*
 *  EucBookParagraph.h
 *  Eucalyptus
 *
 *  Created by James Montgomerie on 26/07/2009.
 *  Copyright 2009 James Montgomerie. All rights reserved.
 *
 */

@protocol EucBookParagraph <NSObject>

@property (nonatomic, readonly) size_t byteOffset;
@property (nonatomic, readonly) size_t nextParagraphByteOffset;

@property (nonatomic, readonly) NSArray *words;
@property (nonatomic, readonly) NSArray *wordFormattingAttributes;

@end
