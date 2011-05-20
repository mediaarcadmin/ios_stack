//
//  BlioEPubParagraphSource.m
//  BlioApp
//
//  Created by James Montgomerie on 21/04/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioEPubParagraphSource.h"
#import "BlioBookmark.h"
#import "BlioEPubBook.h"
#import "BlioBookManager.h"

#import <libEucalyptus/EucBUpeBook.h>
#import <libEucalyptus/EucBUpePageLayoutController.h>
#import <libEucalyptus/EucBookPageIndexPoint.h>
#import <libEucalyptus/EucBookNavPoint.h>
#import <libEucalyptus/EucCSSLayoutRunExtractor.h>
#import <libEucalyptus/EucCSSLayouter.h>
#import <libEucalyptus/EucCSSLayoutRun.h>
#import <libEucalyptus/EucCSSIntermediateDocumentNode.h>
#import <libEucalyptus/EucChapterNameFormatting.h>
#import <libEucalyptus/THPair.h>

@interface BlioEPubParagraphSource ()
@property (nonatomic, retain, readonly) EucBUpeBook *bUpeBook;
@end


@implementation BlioEPubParagraphSource

@synthesize bUpeBook = _bUpeBook;

- (id)initWithBookID:(NSManagedObjectID *)bookID;
{
    if((self = [super init])) {
        _bookID = [bookID retain];
        _bUpeBook = [[[BlioBookManager sharedBookManager] checkOutEucBookForBookWithID:bookID] retain];
    }
    return self;
}

- (void)dealloc
{
    if(_bUpeBook) {
        [_bUpeBook release];
        [[BlioBookManager sharedBookManager] checkInEucBookForBookWithID:_bookID];
    }
    [_bookID release];
    
    [super dealloc];
}

- (EucBookPageIndexPoint *)_indexPointFromBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    EucBookPageIndexPoint *indexPoint = [[EucBookPageIndexPoint alloc] init];
    
    indexPoint.source = bookmarkPoint.layoutPage - 1;
    indexPoint.block = bookmarkPoint.blockOffset;
    indexPoint.word = bookmarkPoint.wordOffset + 1;
    indexPoint.element = bookmarkPoint.elementOffset;
    
    return [indexPoint autorelease];
}

- (BlioBookmarkPoint *)_bookmarkPointFromIndexPoint:(EucBookPageIndexPoint *)indexPoint
{
    BlioBookmarkPoint *ret = [[BlioBookmarkPoint alloc] init];
    
    ret.layoutPage = indexPoint.source + 1;
    ret.blockOffset = indexPoint.block;
    ret.wordOffset = indexPoint.word == 0 ? 0 : indexPoint.word - 1;
    ret.elementOffset = indexPoint.element;
    
    return [ret autorelease];    
}


- (void)bookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint toParagraphID:(id *)paragraphIDOut wordOffset:(uint32_t *)wordOffsetOut
{
    EucBookPageIndexPoint *indexPoint = [self _indexPointFromBookmarkPoint:bookmarkPoint];
    
    EucCSSIntermediateDocument *intermediateDocument = [self.bUpeBook intermediateDocumentForIndexPoint:indexPoint];
    
    EucCSSLayoutRunExtractor *runExtractor = [[EucCSSLayoutRunExtractor alloc] initWithDocument:intermediateDocument];
    
    EucCSSLayoutRun *newRun = [runExtractor runForNodeWithKey:indexPoint.block];
   
    *wordOffsetOut = indexPoint.word == 0 ? 0 : indexPoint.word - 1;
    indexPoint.block = newRun.id;
    indexPoint.word = 0;
    indexPoint.element = 0;
    
    *paragraphIDOut = [THPair pairWithFirst:newRun second:indexPoint];

    [runExtractor release];    
}

- (BlioBookmarkPoint *)bookmarkPointFromParagraphID:(id)paragraphID wordOffset:(uint32_t)wordOffset
{
    BlioBookmarkPoint *ret = [self _bookmarkPointFromIndexPoint:(EucBookPageIndexPoint *)((THPair *)paragraphID).second];
    ret.wordOffset = wordOffset;
    return ret;
}

- (NSArray *)wordsForParagraphWithID:(id)paragraphID
{
    return paragraphID ? [(EucCSSLayoutRun *)((THPair *)paragraphID).first words] : nil;
}

- (id)nextParagraphIdForParagraphWithID:(id)paragraphID
{
    EucCSSLayoutRun *run = (EucCSSLayoutRun *)((THPair *)paragraphID).first;
    EucBookPageIndexPoint *indexPoint = (EucBookPageIndexPoint *)((THPair *)paragraphID).second;

    EucCSSLayoutRunExtractor *runExtractor = [[EucCSSLayoutRunExtractor alloc] initWithDocument:run.startNode.document];
    
    EucCSSLayoutRun *newRun = [runExtractor nextRunForRun:run];
    
    [runExtractor release];

    THPair *ret = nil;
    if(newRun) {
        EucBookPageIndexPoint *newIndexPoint = [indexPoint copy];
        newIndexPoint.block = newRun.id;
        newIndexPoint.word = 0;
        newIndexPoint.element = 0;
        
        ret = [THPair pairWithFirst:newRun second:newIndexPoint];
        [newIndexPoint autorelease];        
    } else {
        EucBookPageIndexPoint *nextSourceIndexPoint = [[EucBookPageIndexPoint alloc] init];
        nextSourceIndexPoint.source = indexPoint.source + 1;
        EucCSSIntermediateDocument *intermediateDocument = [self.bUpeBook intermediateDocumentForIndexPoint:nextSourceIndexPoint];
        while(!ret && intermediateDocument) {
            EucCSSLayoutRunExtractor *runExtractor = [[EucCSSLayoutRunExtractor alloc] initWithDocument:intermediateDocument];
            newRun = [runExtractor runForNodeWithKey:0];
            if(newRun) {
                nextSourceIndexPoint.block = newRun.id;
                ret = [THPair pairWithFirst:newRun second:nextSourceIndexPoint];
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

- (NSArray *)sectionUuids
{
    return [self.bUpeBook.navPoints valueForKey:@"uuid"];
}

- (NSUInteger)levelForSectionUuid:(NSString *)sectionUuid
{
    return [self.bUpeBook navPointWithUuid:sectionUuid].level;
}

- (THPair *)presentationNameAndSubTitleForSectionUuid:(NSString *)sectionUuid
{
    return [[self.bUpeBook navPointWithUuid:sectionUuid].text splitAndFormattedChapterName];
}

- (BlioBookmarkPoint *)bookmarkPointForSectionUuid:(NSString *)uuid
{
    return [self _bookmarkPointFromIndexPoint:[self.bUpeBook indexPointForUuid:uuid]];
}

- (NSString *)sectionUuidForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    EucBookPageIndexPoint *indexPoint = [self _indexPointFromBookmarkPoint:bookmarkPoint];
    NSString *bestUuid = nil;
    {
        for(EucBookNavPoint *navPoint in self.bUpeBook.navPoints) {
            EucBookPageIndexPoint *thisIndexPoint = [self.bUpeBook indexPointForUuid:navPoint.uuid];
            if([thisIndexPoint compare:indexPoint] != NSOrderedDescending) {
                bestUuid = navPoint.uuid;
            }
        }
    }
    return bestUuid;
}

- (BlioBookmarkPoint *)estimatedBookmarkPointForPercentage:(float)percentage
{
    return [self _bookmarkPointFromIndexPoint:[self.bUpeBook estimatedIndexPointForPercentage:percentage]];
}

- (float)estimatedPercentageForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    return [self.bUpeBook estimatedPercentageForIndexPoint:[self _indexPointFromBookmarkPoint:bookmarkPoint]];
}

@end
