//
//  BlioEPubParagraphSource.m
//  BlioApp
//
//  Created by James Montgomerie on 21/04/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioEPubParagraphSource.h"
#import "BlioBookmark.h"

#import <libEucalyptus/EucBUpeBook.h>
#import <libEucalyptus/EucBookPageIndexPoint.h>
#import <libEucalyptus/EucCSSLayoutRunExtractor.h>
#import <libEucalyptus/EucCSSLayouter.h>
#import <libEucalyptus/EucCSSLayoutDocumentRun.h>
#import <libEucalyptus/EucCSSIntermediateDocumentNode.h>
#import <libEucalyptus/THPair.h>

@interface BlioEPubParagraphSource ()
@property (nonatomic, retain) EucBUpeBook *bUpeBook;
@end


@implementation BlioEPubParagraphSource

@synthesize bUpeBook = _bUpeBook;

- (id)initWitBUpeBook:(EucBUpeBook *)bUpeBook
{
    if((self = [super init])) {
        _bUpeBook = [bUpeBook retain];
    }
    return self;
}

- (void)dealloc
{
    [_bUpeBook dealloc];
    
    [super dealloc];
}

- (void)bookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint toParagraphID:(id *)paragraphIDOut wordOffset:(uint32_t *)wordOffsetOut
{
    EucBookPageIndexPoint *indexPoint = [[EucBookPageIndexPoint alloc] init];
    indexPoint.source = bookmarkPoint.layoutPage;
    indexPoint.block = bookmarkPoint.blockOffset;
    indexPoint.word = bookmarkPoint.wordOffset + 1;
    indexPoint.element = bookmarkPoint.elementOffset;
    
    EucCSSIntermediateDocument *intermediateDocument = [self.bUpeBook intermediateDocumentForIndexPoint:indexPoint];
    
    EucCSSLayoutRunExtractor *runExtractor = [[EucCSSLayoutRunExtractor alloc] initWithDocument:intermediateDocument];
    
    EucCSSLayoutDocumentRun *newDocumentRun = [runExtractor documentRunForNodeWithKey:indexPoint.block];
    
    [runExtractor release];
    
    *paragraphIDOut = [THPair pairWithFirst:newDocumentRun second:indexPoint];
    *wordOffsetOut = indexPoint.word - 1;
    
    [indexPoint release];
}

- (BlioBookmarkPoint *)bookmarkPointFromParagraphID:(id)paragraphID wordOffset:(uint32_t)wordOffset
{
    BlioBookmarkPoint *ret = [[BlioBookmarkPoint alloc] init];
    EucBookPageIndexPoint *indexPoint = (EucBookPageIndexPoint *)((THPair *)paragraphID).second;

    ret.layoutPage = indexPoint.source;
    ret.blockOffset = indexPoint.block;
    ret.wordOffset = wordOffset;
    ret.elementOffset = indexPoint.element;
    
    return [ret autorelease];
}

- (NSArray *)wordsForParagraphWithID:(id)paragraphID
{
    return [(EucCSSLayoutDocumentRun *)((THPair *)paragraphID).first words];
}

- (id)nextParagraphIdForParagraphWithID:(id)paragraphID
{
    EucCSSLayoutDocumentRun *documentRun = (EucCSSLayoutDocumentRun *)((THPair *)paragraphID).first;
    EucBookPageIndexPoint *indexPoint = (EucBookPageIndexPoint *)((THPair *)paragraphID).second;

    EucCSSLayoutRunExtractor *runExtractor = [[EucCSSLayoutRunExtractor alloc] initWithDocument:documentRun.startNode.document];
    
    EucCSSLayoutDocumentRun *newDocumentRun = [runExtractor nextDocumentRunForDocumentRun:documentRun];
    
    [runExtractor release];

    THPair *ret = nil;
    if(newDocumentRun) {
        EucBookPageIndexPoint *newIndexPoint = [indexPoint copy];
        newIndexPoint.block = newDocumentRun.id;
        newIndexPoint.word = 0;
        newIndexPoint.element = 0;
        
        ret = [THPair pairWithFirst:newDocumentRun second:newIndexPoint];
        [newIndexPoint autorelease];        
    } else {
        EucBookPageIndexPoint *nextSourceIndexPoint = [[EucBookPageIndexPoint alloc] init];
        nextSourceIndexPoint.source = indexPoint.source + 1;
        EucCSSIntermediateDocument *intermediateDocument = [self.bUpeBook intermediateDocumentForIndexPoint:nextSourceIndexPoint];
        while(!ret && intermediateDocument) {
            EucCSSLayoutRunExtractor *runExtractor = [[EucCSSLayoutRunExtractor alloc] initWithDocument:intermediateDocument];
            newDocumentRun = [runExtractor documentRunForNodeWithKey:0];
            if(newDocumentRun) {
                nextSourceIndexPoint.block = newDocumentRun.id;
                ret = [THPair pairWithFirst:newDocumentRun second:nextSourceIndexPoint];
            } else {
                // Maybe this source was empty - try the next one.
                nextSourceIndexPoint.source = indexPoint.source + 1;
                intermediateDocument = [self.bUpeBook intermediateDocumentForIndexPoint:nextSourceIndexPoint];
            }
            [runExtractor release]; 
        }
        [nextSourceIndexPoint release];
    }
    
    return ret;
}

@end
