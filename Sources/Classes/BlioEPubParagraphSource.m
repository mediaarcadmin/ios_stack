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
#import <libEucalyptus/EucCSSLayoutRunExtractor.h>
#import <libEucalyptus/EucCSSLayouter.h>
#import <libEucalyptus/EucCSSLayoutDocumentRun.h>
#import <libEucalyptus/EucCSSIntermediateDocumentNode.h>
#import <libEucalyptus/THPair.h>

@interface BlioEPubParagraphSource ()
@property (nonatomic, retain, readonly) EucBUpeBook *bUpeBook;
@property (nonatomic, retain, readonly) EucBUpePageLayoutController *layoutController;
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
    [_layoutController release];
    [_bUpeBook dealloc];
    
    [super dealloc];
}

- (EucBookPageIndexPoint *)_indexPointFromBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    EucBookPageIndexPoint *indexPoint = [[EucBookPageIndexPoint alloc] init];
    
    indexPoint.source = bookmarkPoint.layoutPage;
    indexPoint.block = bookmarkPoint.blockOffset;
    indexPoint.word = bookmarkPoint.wordOffset + 1;
    indexPoint.element = bookmarkPoint.elementOffset;
    
    return [indexPoint autorelease];;
}

- (BlioBookmarkPoint *)_bookmarkPointFromIndexPoint:(EucBookPageIndexPoint *)indexPoint
{
    BlioBookmarkPoint *ret = [[BlioBookmarkPoint alloc] init];
    
    ret.layoutPage = indexPoint.source;
    ret.blockOffset = indexPoint.block;
    ret.wordOffset = indexPoint.word;
    ret.elementOffset = indexPoint.element;
    
    return [ret autorelease];    
}


- (void)bookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint toParagraphID:(id *)paragraphIDOut wordOffset:(uint32_t *)wordOffsetOut
{
    EucBookPageIndexPoint *indexPoint = [self _indexPointFromBookmarkPoint:bookmarkPoint];
    
    EucCSSIntermediateDocument *intermediateDocument = [self.bUpeBook intermediateDocumentForIndexPoint:indexPoint];
    
    EucCSSLayoutRunExtractor *runExtractor = [[EucCSSLayoutRunExtractor alloc] initWithDocument:intermediateDocument];
    
    EucCSSLayoutDocumentRun *newDocumentRun = [runExtractor documentRunForNodeWithKey:indexPoint.block];
    
    [runExtractor release];
    
    *paragraphIDOut = [THPair pairWithFirst:newDocumentRun second:indexPoint];
    *wordOffsetOut = indexPoint.word - 1;
}

- (BlioBookmarkPoint *)bookmarkPointFromParagraphID:(id)paragraphID wordOffset:(uint32_t)wordOffset
{
    BlioBookmarkPoint *ret = [self _bookmarkPointFromIndexPoint:(EucBookPageIndexPoint *)((THPair *)paragraphID).second];
    ret.wordOffset = wordOffset;
    return ret;
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

- (EucBUpePageLayoutController *)layoutController {
    if(!_layoutController) {
        _layoutController = [[EucBUpePageLayoutController alloc] initWithBook:self.bUpeBook
                                                                     pageSize:CGSizeMake(320, 480)
                                                                fontPointSize:18.0f];
    }
    return _layoutController;
}

- (NSUInteger)pageNumberForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    return [self.layoutController pageNumberForIndexPoint:[self _indexPointFromBookmarkPoint:bookmarkPoint]];
}

- (BlioBookmarkPoint *)bookmarkPointForPageNumber:(NSUInteger)pageNumber
{
    return [self _bookmarkPointFromIndexPoint:[self.layoutController indexPointForPageNumber:pageNumber]];
}

- (id<EucBookContentsTableViewControllerDataSource>)contentsDataSource
{
    return self.layoutController;
}

- (NSUInteger)pageCount
{
    return [self.layoutController globalPageCount];
}

@end
