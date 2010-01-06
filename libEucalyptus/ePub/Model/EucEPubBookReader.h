//
//  EucEPubBookReader.h
//  libEucalyptus
//
//  Created by James Montgomerie on 26/07/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucBookReader.h"
#import "expat.h"

@class EucEPubStyleStore, EucEPubBookParagraph, EucEPubBook, EucBookPageIndexPoint;

@interface EucEPubBookReader : NSObject <EucBookReader> {
    EucEPubBook *_book; // Nonretained.

    size_t *_fileStartOffsetMap;
    NSUInteger _fileStartOffsetMapCount;
    
    NSMutableDictionary *_anchorIDStore;

    NSUInteger _currentFileIndex;
    NSData *_xhtmlData;
    NSURL *_baseURL;
    NSString *_packageRelativePath;
    int32_t _startOffset;
    EucEPubStyleStore *_styleStore;
    
    XML_Parser _parser;
    
    size_t _paragraphBuildingStartOffset;
    NSMutableArray *_paragraphBuildingWords;
    NSMutableArray *_paragraphBuildingAttributes;
    NSMutableArray *_paragraphBuildingStyleStack;
    BOOL _paragraphBuildingCharactersEndedInWhitespace;
    
    NSCharacterSet *_whitespaceAndNewlineCharacterSet;
    
    NSMutableArray *_xHTMLfileCache;
}

@property (nonatomic, assign) BOOL shouldCollectPaginationData;

- (EucEPubBookParagraph *)paragraphAtOffset:(size_t)offset maxOffset:(size_t)maxOffset;

@end
