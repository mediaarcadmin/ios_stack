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

@interface BlioEPubParagraphID : NSObject {
    EucCSSLayoutRun *_run;
    EucBookPageIndexPoint *_indexPoint;
    EucCSSLayoutRunExtractor *_runExtractor;
}

@property (nonatomic, retain, readonly) EucCSSLayoutRun *run;
@property (nonatomic, retain, readonly) EucBookPageIndexPoint *indexPoint;
@property (nonatomic, retain, readonly) EucCSSLayoutRunExtractor *runExtractor;

@end

@implementation BlioEPubParagraphID 

@synthesize run = _run;
@synthesize indexPoint = _indexPoint;
@synthesize runExtractor = _runExtractor;

- (id)initWithRun:(EucCSSLayoutRun *)run
       indexPoint:(EucBookPageIndexPoint *)indexPoint
     runExtractor:(EucCSSLayoutRunExtractor *)runExtractor
{
    if((self = [super init])) {
        _run = [run retain];
        _indexPoint = [indexPoint retain];
        _runExtractor = [runExtractor retain];
    }
    
    return self;
}

- (void)dealloc
{
    [_run release];
    [_indexPoint release];
    [_runExtractor release];

    [super dealloc];
}

- (BOOL)isEqual:(id)rhs
{
    if([rhs isKindOfClass:[BlioEPubParagraphID class]]) {
        return [self.indexPoint isEqual:((BlioEPubParagraphID *)rhs).indexPoint];
    } else {
        return NO;
    }
}

@end



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
    
    NSInteger layoutPage = bookmarkPoint.layoutPage;
    indexPoint.source = MAX(1, layoutPage) - 1;
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
    
    *paragraphIDOut = [[[BlioEPubParagraphID alloc] initWithRun:newRun indexPoint:indexPoint runExtractor:runExtractor] autorelease];

    [runExtractor release];    
}

- (BlioBookmarkPoint *)bookmarkPointFromParagraphID:(id)paragraphID wordOffset:(uint32_t)wordOffset
{
    BlioBookmarkPoint *ret = [self _bookmarkPointFromIndexPoint:((BlioEPubParagraphID *)paragraphID).indexPoint];
    ret.wordOffset = wordOffset;
    return ret;
}

- (NSArray *)wordsForParagraphWithID:(id)paragraphID
{
    return paragraphID ? [((BlioEPubParagraphID *)paragraphID).run words] : nil;
}

- (id)nextParagraphIdForParagraphWithID:(id)paragraphID
{
    EucCSSLayoutRun *run = ((BlioEPubParagraphID *)paragraphID).run;
    EucBookPageIndexPoint *indexPoint = ((BlioEPubParagraphID *)paragraphID).indexPoint;
    EucCSSLayoutRunExtractor *runExtractor = ((BlioEPubParagraphID *)paragraphID).runExtractor;
    
    EucCSSLayoutRun *newRun = [runExtractor nextRunForRun:run];
    
    BlioEPubParagraphID *ret = nil;
    if(newRun) {
        EucBookPageIndexPoint *newIndexPoint = [indexPoint copy];
        newIndexPoint.block = newRun.id;
        newIndexPoint.word = 0;
        newIndexPoint.element = 0;
        
        ret = [[[BlioEPubParagraphID alloc] initWithRun:newRun indexPoint:newIndexPoint runExtractor:runExtractor] autorelease];
        [newIndexPoint release];        
    } else {
        EucBookPageIndexPoint *nextSourceIndexPoint = [[EucBookPageIndexPoint alloc] init];
        nextSourceIndexPoint.source = indexPoint.source + 1;
        EucCSSIntermediateDocument *intermediateDocument = [self.bUpeBook intermediateDocumentForIndexPoint:nextSourceIndexPoint];
        while(!ret && intermediateDocument) {
            EucCSSLayoutRunExtractor *runExtractor = [[EucCSSLayoutRunExtractor alloc] initWithDocument:intermediateDocument];
            newRun = [runExtractor runForNodeWithKey:0];
            if(newRun) {
                nextSourceIndexPoint.block = newRun.id;
                ret = [[[BlioEPubParagraphID alloc] initWithRun:newRun indexPoint:nextSourceIndexPoint runExtractor:runExtractor] autorelease];
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
        EucBookNavPoint *bestNavPoint = nil;
        
        EucBookPageIndexPoint *currentIndexPoint = indexPoint;
        EucBookPageIndexPoint *newIndexPoint = nil;
        
        EucBUpeBook *book = self.bUpeBook;
        
        for(EucBookNavPoint *navPoint in book.navPoints) {
            EucBookPageIndexPoint *prospectiveNewIndexPoint = [book indexPointForUuid:navPoint.uuid];
            if([currentIndexPoint compare:prospectiveNewIndexPoint] == NSOrderedDescending) {
                if(!newIndexPoint || [prospectiveNewIndexPoint compare:newIndexPoint] == NSOrderedDescending) {
                    newIndexPoint = prospectiveNewIndexPoint;
                    bestNavPoint = navPoint;
                }
            }
        }
        
        bestUuid = bestNavPoint.uuid;
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
