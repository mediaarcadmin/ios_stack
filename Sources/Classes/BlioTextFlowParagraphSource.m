//
//  BlioTextFlowParagraphSource.m
//  BlioApp
//
//  Created by James Montgomerie on 14/04/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioTextFlowParagraphSource.h"

#import "BlioTextFlow.h"

#import "BlioTextFlowFlowTree.h"
#import "BlioTextFlowParagraph.h"
#import "BlioTextFlowParagraphWords.h"

#import "BlioFlowEucBook.h"
#import "BlioTextFlowXAMLTree.h"
#import "BlioTextFlowXAMLTreeNode.h"

#import <libEucalyptus/EucCSSIntermediateDocument.h>
#import <libEucalyptus/EucCSSLayoutRunExtractor.h>
#import <libEucalyptus/EucCSSLayoutDocumentRun.h>

#import "levenshtein_distance.h"

#import "BlioBookManager.h"

#define MATCHING_WINDOW_SIZE 9

@interface BlioTextFlowParagraphSource ()

@property (nonatomic, retain) BlioTextFlow *textFlow;
@property (nonatomic, assign) NSUInteger currentFlowTreeIndex;
@property (nonatomic, retain) BlioTextFlowFlowTree *currentFlowTree;

@end


@implementation BlioTextFlowParagraphSource

@synthesize textFlow;

@synthesize currentFlowTreeIndex;
@synthesize currentFlowTree;

- (id)initWithBookID:(NSManagedObjectID *)bookID
{
    if((self = [super init])) {
        textFlow = [[[BlioBookManager sharedBookManager] checkOutTextFlowForBookWithID:bookID] retain];
    }
    return self;
}

- (void)dealloc
{
    NSManagedObjectID *myBookID = [textFlow.bookID retain];
    if(textFlow) {
        [textFlow release];
        [[BlioBookManager sharedBookManager] checkInTextFlowForBookWithID:myBookID];
    }
    [myBookID release];
    [currentFlowTree release];
    
    [super dealloc];
}

- (BlioTextFlowFlowTree *)flowFlowTreeForIndex:(NSUInteger)index
{
    if(index != self.currentFlowTreeIndex || !self.currentFlowTree) {
        self.currentFlowTree = [self.textFlow flowTreeForFlowIndex:index];
        self.currentFlowTreeIndex = index;
    }    
    return self.currentFlowTree;
}

- (BlioTextFlowParagraph *)paragraphWithID:(NSIndexPath *)paragraphID
{
    BlioTextFlowParagraph *ret = nil;
    BlioTextFlowFlowTree *flowFlowTree = [self flowFlowTreeForIndex:[paragraphID indexAtPosition:0]];
    
    if(flowFlowTree) {
        uint32_t key = [paragraphID indexAtPosition:1];
        if(key) {
            ret = (BlioTextFlowParagraph *)[flowFlowTree nodeForKey:key];
        } else {
            ret = flowFlowTree.firstParagraph;
        }
    }
    return ret;
}

- (void)bookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint toParagraphID:(id *)paragraphID wordOffset:(uint32_t *)wordOffset
{
    NSUInteger flowIndex = 0;
    NSUInteger bookmarkPageIndex = bookmarkPoint.layoutPage - 1;
    NSArray *flowReferences = self.textFlow.flowReferences;
    NSUInteger nextFlowIndex = 0;
    for(BlioTextFlowFlowReference *flowReference in flowReferences) {
        if(flowReference.startPage <= bookmarkPageIndex) {
            flowIndex = nextFlowIndex;
            ++nextFlowIndex;
        } else {
            break;
        }
    }
    
    if(self.textFlow.flowTreeKind == BlioTextFlowFlowTreeKindXaml) {
        // Build an array of word hashes to search for from around the point.
        NSString *lookForStrings[MATCHING_WINDOW_SIZE];
        char lookForHashes[MATCHING_WINDOW_SIZE];

        NSArray *pageBlocks = [textFlow blocksForPageAtIndex:bookmarkPoint.layoutPage - 1 includingFolioBlocks:YES];
        NSArray *words = ((BlioTextFlowBlock *)[pageBlocks objectAtIndex:bookmarkPoint.blockOffset]).wordStrings;
        NSInteger middleWordOffset = bookmarkPoint.wordOffset;
        {
            NSInteger tryPageOffset = bookmarkPoint.layoutPage - 1;
            NSInteger tryBlockOffset = bookmarkPoint.blockOffset;
                
            while(middleWordOffset + MATCHING_WINDOW_SIZE / 2 > words.count) {
                ++tryBlockOffset;
                if(tryBlockOffset >= pageBlocks.count) {
                    tryBlockOffset = 0;
                    ++tryPageOffset;
                    if(tryPageOffset > self.textFlow.lastPageIndex) {
                        NSInteger needMore = middleWordOffset + MATCHING_WINDOW_SIZE / 2 - words.count;
                        NSMutableArray *newWords = [[NSMutableArray alloc] initWithCapacity:needMore];
                        for(NSInteger i = 0; i < needMore; ++i) {
                            [newWords addObject:@""];
                        }
                        words = [words arrayByAddingObjectsFromArray:newWords];
                        [newWords release];
                    } else {
                        pageBlocks = [textFlow blocksForPageAtIndex:tryPageOffset includingFolioBlocks:YES];
                    }
                } else {
                    BlioTextFlowBlock *block = [pageBlocks objectAtIndex:tryBlockOffset];
                    if(!block.folio) {
                        words = [words arrayByAddingObjectsFromArray:block.wordStrings];
                    }
                }
            }
        }
        
        {
            NSInteger tryPageOffset = bookmarkPoint.layoutPage - 1;
            NSInteger tryBlockOffset = bookmarkPoint.blockOffset;
            
            while(middleWordOffset - MATCHING_WINDOW_SIZE / 2 <= 0) {
                --tryBlockOffset;
                if(tryBlockOffset < 0) {
                    --tryPageOffset;
                    if(tryPageOffset < 0) {
                        NSInteger needMore = MATCHING_WINDOW_SIZE / 2 - middleWordOffset + 1;
                        NSMutableArray *newWords = [[NSMutableArray alloc] initWithCapacity:needMore];
                        for(NSInteger i = 0; i < needMore; ++i) {
                            [newWords addObject:@""];
                        }
                        words = [newWords arrayByAddingObjectsFromArray:newWords];
                        [newWords release];
                        middleWordOffset += needMore;
                    } else {
                        pageBlocks = [textFlow blocksForPageAtIndex:tryPageOffset includingFolioBlocks:YES];
                        tryBlockOffset = pageBlocks.count;
                    }
                } else {
                    BlioTextFlowBlock *block = [pageBlocks objectAtIndex:tryBlockOffset];
                    if(!block.folio) {
                        NSArray *newWords = block.wordStrings;
                        words = [newWords arrayByAddingObjectsFromArray:words];
                        middleWordOffset += newWords.count;
                    }
                }
            }
        }
        
        NSInteger i, j;
        for(i = -(MATCHING_WINDOW_SIZE / 2), j = 0 ; i <= MATCHING_WINDOW_SIZE / 2; ++i, ++j) {
            lookForHashes[j] = [[words objectAtIndex:middleWordOffset + i] hash] % 256;
            lookForStrings[j] = [words objectAtIndex:middleWordOffset + i];
        }
        
        /*
        NSLog(@"Searching for:");
        for(NSInteger i = 0; i < MATCHING_WINDOW_SIZE; ++i) {
            NSLog(@"\t%@", lookForStrings[i]);
        }
        */
        
        NSManagedObjectID *bookID = self.textFlow.bookID;
        BlioFlowEucBook *bUpeBook = (BlioFlowEucBook *)[[BlioBookManager sharedBookManager] checkOutEucBookForBookWithID:bookID];
        
        EucBookPageIndexPoint *eucIndexPoint = [[EucBookPageIndexPoint alloc] init];
        eucIndexPoint.source = flowIndex;
        EucCSSIntermediateDocument *document = [bUpeBook intermediateDocumentForIndexPoint:eucIndexPoint];
        [eucIndexPoint release];
        
        EucCSSLayoutRunExtractor *runExtractor = [[EucCSSLayoutRunExtractor alloc] initWithDocument:document];
        
        NSUInteger lookForPageIndex = bookmarkPoint.layoutPage - 1;
        
        NSUInteger lowerBoundPageIndex = 0;
        NSUInteger upperBoundPageIndex = 0;
        uint32_t lowerBoundRunKey = 0;
        uint32_t upperBoundRunKey = 0;
        BOOL upperBoundFound = NO;
        EucCSSLayoutDocumentRun *documentRun = [runExtractor documentRunForNodeWithKey:0];
        while(documentRun && !upperBoundFound) {
            upperBoundRunKey = documentRun.id;
            NSArray *thisParagraphTags = [documentRun attributeValuesForWordsForAttributeName:@"Tag"];
            for(NSString *tag in thisParagraphTags) {
                if(tag != (NSString *)[NSNull null]) {
                    if([tag hasPrefix:@"__"]) {
                        NSUInteger pageIndex = [[tag substringFromIndex:2] integerValue];
                        if(pageIndex < lookForPageIndex) {
                            lowerBoundRunKey = documentRun.id;
                            lowerBoundPageIndex = pageIndex;
                        }
                        if(pageIndex > lookForPageIndex) {
                            upperBoundFound = YES;
                            upperBoundPageIndex = pageIndex;
                            break;
                        }
                    }
                }
            }
            documentRun = [runExtractor nextDocumentRunForDocumentRun:documentRun];
        }
    
        char blockHashes[MATCHING_WINDOW_SIZE];
        NSString *blockStrings[MATCHING_WINDOW_SIZE];
        
        uint32_t runKeys[MATCHING_WINDOW_SIZE];
        uint32_t wordOffsets[MATCHING_WINDOW_SIZE];
        
        char emptyHash = [@"" hash] % 256;
        for(NSInteger i = 0; i < MATCHING_WINDOW_SIZE; ++i) {
            blockStrings[i] = @"";
            blockHashes[i] = emptyHash;
            runKeys[i] = lowerBoundRunKey;
            wordOffsets[i] = 0;
        }
        
        int bestDistance = INT_MAX;
        uint32_t bestRunKey = 0;
        uint32_t bestWordOffset = 0;
        
        uint32_t examiningRunKey = lowerBoundRunKey;
        documentRun = [runExtractor documentRunForNodeWithKey:examiningRunKey];
        while(documentRun && examiningRunKey <= upperBoundRunKey) {
            NSArray *words = documentRun.words;
            NSUInteger examiningWordOffset = 0;
            for(NSString *word in words) {
                memmove(blockHashes, blockHashes + 1, sizeof(char) * MATCHING_WINDOW_SIZE - 1);
                blockHashes[MATCHING_WINDOW_SIZE - 1] = [word hash] % 256;
                
                memmove(blockStrings, blockStrings + 1, sizeof(NSString *) * MATCHING_WINDOW_SIZE - 1);
                blockStrings[MATCHING_WINDOW_SIZE - 1] = word;
                
                memmove(runKeys, runKeys + 1, sizeof(uint32_t) * MATCHING_WINDOW_SIZE - 1);
                runKeys[MATCHING_WINDOW_SIZE - 1] = examiningRunKey;
                
                memmove(wordOffsets, wordOffsets + 1, sizeof(uint32_t) * MATCHING_WINDOW_SIZE - 1);
                wordOffsets[MATCHING_WINDOW_SIZE - 1] = examiningWordOffset;
                
                int distance = levenshtein_distance_with_bytes(lookForHashes, MATCHING_WINDOW_SIZE, blockHashes, MATCHING_WINDOW_SIZE);
                if(distance < bestDistance) {
                    /*
                     NSLog(@"Found, distance %d:", distance);
                     for(NSInteger i = 0;  i < MATCHING_WINDOW_SIZE; ++i) {
                         NSLog(@"\t%@", blockStrings[i]);
                     }
                    */
                    bestDistance = distance;
                    bestRunKey = runKeys[MATCHING_WINDOW_SIZE / 2];
                    bestWordOffset = wordOffsets[MATCHING_WINDOW_SIZE / 2];
                }
                ++examiningWordOffset;
            }
            documentRun = [runExtractor nextDocumentRunForDocumentRun:documentRun];
            examiningRunKey = documentRun.id;
        }
        
        NSUInteger indexes[2] = { flowIndex, [EucCSSIntermediateDocument documentTreeNodeKeyForKey:bestRunKey] };
        *paragraphID = [NSIndexPath indexPathWithIndexes:indexes length:2];
        *wordOffset = bestWordOffset;
        
        [runExtractor release];
        [[BlioBookManager sharedBookManager] checkInEucBookForBookWithID:bookID];
    } else {
        BlioTextFlowFlowTree *flowFlowTree = [self flowFlowTreeForIndex:flowIndex];
        BlioTextFlowParagraph *bestParagraph = flowFlowTree.firstParagraph;

        BOOL stop = NO;
        BlioTextFlowParagraph *nextParagraph;
        while(!stop && (nextParagraph = bestParagraph.nextSibling)) {
            NSArray *ranges = nextParagraph.paragraphWords.ranges;
            if(ranges.count) {
                BlioBookmarkRange *range = [nextParagraph.paragraphWords.ranges objectAtIndex:0];
                BlioBookmarkPoint *startPoint = range.startPoint;
                if([startPoint compare:bookmarkPoint] == NSOrderedDescending) {
                    break;
                }
            }
            bestParagraph = nextParagraph;
        }
        
        NSUInteger indexes[2] = { flowIndex, bestParagraph.key };
        *paragraphID = [NSIndexPath indexPathWithIndexes:indexes length:2];
        
        uint32_t bestWordOffset = 0;
        BlioBookmarkPoint *comparisonPoint = [[BlioBookmarkPoint alloc] init];
        for(BlioTextFlowPositionedWord *word in bestParagraph.paragraphWords.words) {
            comparisonPoint.layoutPage = [BlioTextFlowBlock pageIndexForBlockID:word.blockID] + 1;
            comparisonPoint.blockOffset = [BlioTextFlowBlock blockIndexForBlockID:word.blockID];
            comparisonPoint.wordOffset = word.wordIndex;
            if([comparisonPoint compare:bookmarkPoint] <= NSOrderedSame) {
                ++bestWordOffset;
            } else {
                break;
            }
        }
        if(bestWordOffset) {
            bestWordOffset--;
        }
        [comparisonPoint release];
        
        *wordOffset = bestWordOffset;
    }
}

- (BlioBookmarkPoint *)bookmarkPointFromParagraphID:(id)paragraphID wordOffset:(uint32_t)wordOffset
{
    BlioBookmarkPoint *ret = nil;

    if(self.textFlow.flowTreeKind == BlioTextFlowFlowTreeKindXaml) {
        NSManagedObjectID *bookID = self.textFlow.bookID;
        BlioFlowEucBook *bUpeBook = (BlioFlowEucBook *)[[BlioBookManager sharedBookManager] checkOutEucBookForBookWithID:bookID];
        
        EucBookPageIndexPoint *eucIndexPoint = [[EucBookPageIndexPoint alloc] init];
        eucIndexPoint.source = [paragraphID indexAtPosition:0];
        EucCSSIntermediateDocument *document = [bUpeBook intermediateDocumentForIndexPoint:eucIndexPoint];
        [eucIndexPoint release];
        
        EucCSSLayoutRunExtractor *runExtractor = [[EucCSSLayoutRunExtractor alloc] initWithDocument:document];
        
        uint32_t xamlFlowTreeKey = [paragraphID indexAtPosition:1];
        uint32_t documentKey = [EucCSSIntermediateDocument keyForDocumentTreeNodeKey:xamlFlowTreeKey];
        EucCSSLayoutDocumentRun *wordContainingDocumentRun = [runExtractor documentRunForNodeWithKey:documentKey];
        
        NSUInteger startPageNumber = 0;
        NSUInteger endPageNumber = 0;
        
        
        {
            EucCSSLayoutDocumentRun *testDocumentRun = wordContainingDocumentRun;
            NSArray *thisParagraphTags = [testDocumentRun attributeValuesForWordsForAttributeName:@"Tag"];
            NSInteger testOffset = wordOffset + (MATCHING_WINDOW_SIZE / 2);
            NSString *thisPageTag = nil;
            do {
                if(thisParagraphTags.count <= testOffset) {
                    testOffset -= thisParagraphTags.count;
                    do {
                        testDocumentRun = [runExtractor nextDocumentRunForDocumentRun:testDocumentRun];
                        thisParagraphTags = [testDocumentRun attributeValuesForWordsForAttributeName:@"Tag"];
                    } while(testDocumentRun && thisParagraphTags.count == 0);
                } else {
                    thisPageTag = [thisParagraphTags objectAtIndex:testOffset++];
                }
            } while(testDocumentRun && (thisPageTag == (NSString *)[NSNull null] || ![thisPageTag hasPrefix:@"__"]));
            --testOffset;
            if(testDocumentRun) {
                endPageNumber = [[thisPageTag substringFromIndex:2] integerValue];
            }
        }
        
        {
            EucCSSLayoutDocumentRun *testDocumentRun = wordContainingDocumentRun;
            NSArray *thisParagraphTags = [testDocumentRun attributeValuesForWordsForAttributeName:@"Tag"];
            NSInteger testOffset = wordOffset - 1 - (MATCHING_WINDOW_SIZE / 2);
            NSString *thisPageTag = nil;
            do {
                if(testOffset < 0) {
                    do {
                        testDocumentRun = [runExtractor previousDocumentRunForDocumentRun:testDocumentRun];
                        thisParagraphTags = [testDocumentRun attributeValuesForWordsForAttributeName:@"Tag"];
                    } while(testDocumentRun && thisParagraphTags.count == 0);
                    testOffset = thisParagraphTags.count + testOffset;
                } else {
                    thisPageTag = [thisParagraphTags objectAtIndex:testOffset--];
                }
            } while(testDocumentRun && (thisPageTag == (NSString *)[NSNull null] || ![thisPageTag hasPrefix:@"__"]));
            ++testOffset;
            if(testDocumentRun) {
                startPageNumber = [[thisPageTag substringFromIndex:2] integerValue];
            }
        }
        if(endPageNumber < startPageNumber) {
            endPageNumber = (startPageNumber == 0 ? 0 : startPageNumber - 1);
        }
        
        NSString *lookForStrings[MATCHING_WINDOW_SIZE];
        char lookForHashes[MATCHING_WINDOW_SIZE];
        {
            EucCSSLayoutDocumentRun *testDocumentRun = wordContainingDocumentRun;
            NSInteger middleWordOffset = wordOffset;
            NSArray *runWords = testDocumentRun.words;
            if(middleWordOffset < MATCHING_WINDOW_SIZE / 2) {
                EucCSSLayoutDocumentRun *previousDocumentRun = testDocumentRun;
                while(middleWordOffset < MATCHING_WINDOW_SIZE / 2) {
                    previousDocumentRun = [runExtractor previousDocumentRunForDocumentRun:previousDocumentRun];
                    if(previousDocumentRun) {
                        NSArray *previousWords = previousDocumentRun.words;
                        runWords = [previousWords arrayByAddingObjectsFromArray:runWords];
                        middleWordOffset += previousWords.count;
                    } else {
                        NSString *extraWords[MATCHING_WINDOW_SIZE / 2];
                        for(NSInteger i = 0; i < MATCHING_WINDOW_SIZE / 2; ++i) {
                            extraWords[i] = @"";
                        }
                        runWords = [[NSArray arrayWithObjects:extraWords count:MATCHING_WINDOW_SIZE / 2] arrayByAddingObjectsFromArray:runWords];
                        middleWordOffset += MATCHING_WINDOW_SIZE / 2;
                    }
                }
            }
            if(runWords.count - middleWordOffset < MATCHING_WINDOW_SIZE / 2 + 1) {
                EucCSSLayoutDocumentRun *nextDocumentRun = testDocumentRun;
                while(runWords.count - middleWordOffset < MATCHING_WINDOW_SIZE / 2 + 1) {
                    nextDocumentRun = [runExtractor nextDocumentRunForDocumentRun:nextDocumentRun];
                    if(nextDocumentRun) {
                        NSArray *nextWords = nextDocumentRun.words;
                        runWords = [runWords arrayByAddingObjectsFromArray:nextWords];
                    } else {
                        NSString *extraWords[MATCHING_WINDOW_SIZE / 2];
                        for(NSInteger i = 0; i < MATCHING_WINDOW_SIZE / 2; ++i) {
                            extraWords[i] = @"";
                        }
                        runWords = [runWords arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:extraWords count:MATCHING_WINDOW_SIZE / 2] ];
                    }
                }
            }
            
            NSInteger i, j;
            for(i = -(MATCHING_WINDOW_SIZE / 2), j = 0 ; i <= MATCHING_WINDOW_SIZE / 2; ++i, ++j) {
                lookForHashes[j] = [[runWords objectAtIndex:middleWordOffset + i] hash] % 256;
                lookForStrings[j] = [runWords objectAtIndex:middleWordOffset + i];
            }
        }
        
        /*
        NSLog(@"Searching for:");
        for(NSInteger i = 0; i < MATCHING_WINDOW_SIZE; ++i) {
            NSLog(@"\t%@", lookForStrings[i]);
        }
        */
        
        char blockHashes[MATCHING_WINDOW_SIZE];
        NSString *blockStrings[MATCHING_WINDOW_SIZE];
        
        NSUInteger pageIndexes[MATCHING_WINDOW_SIZE];
        NSUInteger blockOffsets[MATCHING_WINDOW_SIZE];
        NSUInteger wordOffsets[MATCHING_WINDOW_SIZE];
        
        char emptyHash = [@"" hash] % 256;
        for(NSInteger i = 0; i < MATCHING_WINDOW_SIZE; ++i) {
            blockStrings[i] = @"";
            blockHashes[i] = emptyHash;
            pageIndexes[i] = startPageNumber;
            blockOffsets[i] = 0;
            wordOffsets[i] = 0;
        }
        
        int bestDistance = INT_MAX;
        NSUInteger bestPageIndex = startPageNumber;
        NSUInteger bestBlockOffset = 0;
        NSUInteger bestWordOffset = 0;
        
        for(NSInteger examiningPage = startPageNumber; examiningPage <= endPageNumber; ++examiningPage) {
            NSUInteger examiningBlockOffset = 0;
            for(BlioTextFlowBlock *block in [textFlow blocksForPageAtIndex:examiningPage includingFolioBlocks:YES]) {
                if(!block.folio) {
                    NSUInteger examiningWordOffset = 0;
                    for(NSString *word in block.wordStrings) {
                        memmove(blockHashes, blockHashes + 1, sizeof(char) * MATCHING_WINDOW_SIZE - 1);
                        blockHashes[MATCHING_WINDOW_SIZE - 1] = [word hash] % 256;

                        memmove(blockStrings, blockStrings + 1, sizeof(NSString *) * MATCHING_WINDOW_SIZE - 1);
                        blockStrings[MATCHING_WINDOW_SIZE - 1] = word;

                        memmove(pageIndexes, pageIndexes + 1, sizeof(NSUInteger) * MATCHING_WINDOW_SIZE - 1);
                        pageIndexes[MATCHING_WINDOW_SIZE - 1] = examiningPage;
                        
                        memmove(blockOffsets, blockOffsets + 1, sizeof(NSUInteger) * MATCHING_WINDOW_SIZE - 1);
                        blockOffsets[MATCHING_WINDOW_SIZE - 1] = examiningBlockOffset;

                        memmove(wordOffsets, wordOffsets + 1, sizeof(NSUInteger) * MATCHING_WINDOW_SIZE - 1);
                        wordOffsets[MATCHING_WINDOW_SIZE - 1] = examiningWordOffset;
                        
                        int distance = levenshtein_distance_with_bytes(lookForHashes, MATCHING_WINDOW_SIZE, blockHashes, MATCHING_WINDOW_SIZE);
                        if(distance < bestDistance) {
                            /*
                            NSLog(@"Found, distance %d:", distance);
                            for(NSInteger i = 0;  i < MATCHING_WINDOW_SIZE; ++i) {
                                NSLog(@"\t%@", blockStrings[i]);
                            }
                            */
                            bestDistance = distance;
                            bestPageIndex = pageIndexes[MATCHING_WINDOW_SIZE / 2];
                            bestBlockOffset = blockOffsets[MATCHING_WINDOW_SIZE / 2];
                            bestWordOffset = wordOffsets[MATCHING_WINDOW_SIZE / 2];
                        }
                        ++examiningWordOffset;
                    }
                    ++examiningBlockOffset;
                }
            }
        }
        
        ret = [[BlioBookmarkPoint alloc] init];
        ret.layoutPage = bestPageIndex + 1;
        ret.blockOffset = bestBlockOffset;
        ret.wordOffset = bestWordOffset;
        
        [ret autorelease];
        
        [runExtractor release];
        [[BlioBookManager sharedBookManager] checkInEucBookForBookWithID:bookID];
    } else {
        BlioTextFlowParagraph *paragraph = [self paragraphWithID:(NSIndexPath *)paragraphID];
        if(paragraph) {
            BlioTextFlowParagraphWords *paragraphWords = paragraph.paragraphWords;
            NSArray *words = paragraphWords.words;

            if(wordOffset >= words.count) {
                ret = [self bookmarkPointFromParagraphID:[self nextParagraphIdForParagraphWithID:paragraphID]
                                              wordOffset:0];
            } else {
                BlioTextFlowPositionedWord *word = [words objectAtIndex:wordOffset];
                ret = [[BlioBookmarkPoint alloc] init];

                ret.layoutPage = [BlioTextFlowBlock pageIndexForBlockID:word.blockID] + 1;
                ret.blockOffset = [BlioTextFlowBlock blockIndexForBlockID:word.blockID];
                ret.wordOffset = word.wordIndex;

                [ret autorelease];
            }
        }
    }
    return ret;
}

- (NSArray *)wordsForParagraphWithID:(id)paragraphID
{
    NSArray *ret = nil;
    if(self.textFlow.flowTreeKind == BlioTextFlowFlowTreeKindXaml) {
        NSManagedObjectID *bookID = self.textFlow.bookID;
        BlioFlowEucBook *bUpeBook = (BlioFlowEucBook *)[[BlioBookManager sharedBookManager] checkOutEucBookForBookWithID:bookID];
        
        EucBookPageIndexPoint *eucIndexPoint = [[EucBookPageIndexPoint alloc] init];
        eucIndexPoint.source = [paragraphID indexAtPosition:0];
        EucCSSIntermediateDocument *document = [bUpeBook intermediateDocumentForIndexPoint:eucIndexPoint];
        [eucIndexPoint release];
        
        EucCSSLayoutRunExtractor *runExtractor = [[EucCSSLayoutRunExtractor alloc] initWithDocument:document];
        
        uint32_t xamlFlowTreeKey = [paragraphID indexAtPosition:1];
        uint32_t documentKey = [EucCSSIntermediateDocument keyForDocumentTreeNodeKey:xamlFlowTreeKey];
        EucCSSLayoutDocumentRun *wordsContainingDocumentRun = [runExtractor documentRunForNodeWithKey:documentKey];
        
        ret = [wordsContainingDocumentRun words];
        
        [runExtractor release];
        [[BlioBookManager sharedBookManager] checkInEucBookForBookWithID:bookID];
    } else {        
        BlioTextFlowParagraph *paragraph = [self paragraphWithID:(NSIndexPath *)paragraphID];
        ret =  paragraph.paragraphWords.wordStrings;
    }
    return ret;
}

- (id)nextParagraphIdForParagraphWithID:(id)paragraphID
{
    NSIndexPath *ret = nil;
    
    if(self.textFlow.flowTreeKind == BlioTextFlowFlowTreeKindXaml) {
        NSManagedObjectID *bookID = self.textFlow.bookID;
        BlioFlowEucBook *bUpeBook = (BlioFlowEucBook *)[[BlioBookManager sharedBookManager] checkOutEucBookForBookWithID:bookID];
        
        EucBookPageIndexPoint *eucIndexPoint = [[EucBookPageIndexPoint alloc] init];
        eucIndexPoint.source = [paragraphID indexAtPosition:0];
        EucCSSIntermediateDocument *document = [bUpeBook intermediateDocumentForIndexPoint:eucIndexPoint];
        [eucIndexPoint release];
        
        EucCSSLayoutRunExtractor *runExtractor = [[EucCSSLayoutRunExtractor alloc] initWithDocument:document];
        
        uint32_t xamlFlowTreeKey = [paragraphID indexAtPosition:1];
        uint32_t documentKey = [EucCSSIntermediateDocument keyForDocumentTreeNodeKey:xamlFlowTreeKey];
        EucCSSLayoutDocumentRun *thisParagraphRun = [runExtractor documentRunForNodeWithKey:documentKey];
        EucCSSLayoutDocumentRun *nextParagraphRun = [runExtractor nextDocumentRunForDocumentRun:thisParagraphRun];
        
        if(nextParagraphRun) {
            NSUInteger indexes[2] = { [paragraphID indexAtPosition:0], nextParagraphRun.id };
            ret = [NSIndexPath indexPathWithIndexes:indexes length:2];
        } else {
            NSUInteger newSection = [paragraphID indexAtPosition:0] + 1;
            if(newSection < self.textFlow.flowReferences.count) {
                NSUInteger indexes[2] = { newSection, 0 };
                ret = [NSIndexPath indexPathWithIndexes:indexes length:2];
            }
        }

        [runExtractor release];
        [[BlioBookManager sharedBookManager] checkInEucBookForBookWithID:bookID];
    } else {
        BlioTextFlowParagraph *paragraph = [self paragraphWithID:(NSIndexPath *)paragraphID];
        paragraph = paragraph.nextSibling;
        
        if(paragraph) {
            NSUInteger indexes[2] = { [paragraphID indexAtPosition:0], (NSUInteger)paragraph.key };
            ret = [NSIndexPath indexPathWithIndexes:indexes length:2];
        } else {
            NSUInteger indexes[2] = { [paragraphID indexAtPosition:0] + 1, 0 };
            NSIndexPath *newID = [[NSIndexPath alloc] initWithIndexes:indexes length:2];
            paragraph = [self paragraphWithID:newID];
            if(paragraph) {
                ret = [newID autorelease];
            } else {
                [newID release];
            }
        }
    }
    //NSLog(@"Returning Paragraph %ld, %ld", (long)[ret indexAtPosition:0], (long)[ret indexAtPosition:1]);
    
    return ret;
}

- (id<EucBookContentsTableViewControllerDataSource>)contentsDataSource
{
    return self.textFlow;
}
 
- (NSUInteger)pageNumberForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    return bookmarkPoint.layoutPage;
}

- (BlioBookmarkPoint *)bookmarkPointForPageNumber:(NSUInteger)pageNumber
{
    BlioBookmarkPoint *point = [[BlioBookmarkPoint alloc] init];
    point.layoutPage = pageNumber;
    return [point autorelease];
}

- (NSUInteger)pageCount
{
    return self.textFlow.lastPageIndex + 1;
}

@end
