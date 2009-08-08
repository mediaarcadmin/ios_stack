//
//  EucEPubBookReader.h
//  Eucalyptus
//
//  Created by James Montgomerie on 26/07/2009.
//  Copyright 2009 James Montgomerie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucBookReader.h"
#import "expat.h"

@class EucEPubStyleStore, EucEPubBookParagraph, EucEPubBook, EucBookPageIndexPoint;

@interface EucEPubBookReader : NSObject <EucBookReader> {
    EucEPubBook *_book;

    size_t *_fileStartOffsetMap;
    NSUInteger _fileStartOffsetMapCount;
    NSUInteger _currentFileIndex;
    NSURL *_baseURL;
    NSString *_packageRelativePath;
    
    EucEPubStyleStore *_styleStore;
    NSData *_xhtmlData;
    XML_Parser _parser;
    
    size_t _paragraphBuildingStartOffset;
    NSMutableArray *_paragraphBuildingStyleStack;
    NSMutableArray *_paragraphBuildingWords;
    NSMutableArray *_paragraphBuildingAttributes;
    BOOL _paragraphBuildingCharactersEndedInWhitespace;
    
    NSCharacterSet *_whitespaceAndNewlineCharacterSet;
    
    int32_t _startOffset;
    
    NSMutableDictionary *_anchorIDStore;
}

@property (nonatomic, assign) BOOL shouldCollectPaginationData;

- (EucEPubBookParagraph *)paragraphAtOffset:(size_t)offset maxOffset:(size_t)maxOffset;

@end
