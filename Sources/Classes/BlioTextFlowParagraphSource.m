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

#import "BlioBookManager.h"

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
        
        NSArray *thisParagraphTags = [wordContainingDocumentRun attributeValuesForWordsForAttributeName:@"Tag"];
        if(thisParagraphTags.count > wordOffset) {
            NSUInteger afterWordCount = 0;
            NSString *thisPageTag = [thisParagraphTags objectAtIndex:wordOffset];
            if(thisPageTag != (NSString *)[NSNull null] &&
               [thisPageTag hasPrefix:@"__"]) {
                NSArray *afterAttributes = [thisParagraphTags subarrayWithRange:NSMakeRange(wordOffset, thisParagraphTags.count - wordOffset)];
                
                
                EucCSSLayoutDocumentRun *documentRun = wordContainingDocumentRun;
                BOOL seenNextPage = NO;
                do {
                    NSLog(@"afterAttributes: %@", afterAttributes);
                    NSUInteger count = 0;
                    NSUInteger lastThisPage = 0;
                    for(NSString *attribute in afterAttributes) {
                        if([attribute hasPrefix:@"__"]) {
                            if([attribute isEqualToString:thisPageTag]) {
                                lastThisPage = count;
                            } else {
                                seenNextPage = YES; 
                                break;
                            }
                        } else {
                            lastThisPage = count;
                        }
                        ++count;
                    }
                    afterWordCount += lastThisPage;
                    if(!seenNextPage) {
                        documentRun = [runExtractor nextDocumentRunForDocumentRun:documentRun];
                        afterAttributes = [documentRun attributeValuesForWordsForAttributeName:@"Tag"];
                    }
                } while(documentRun && !seenNextPage);
                
                NSLog(@"afterWordCount: %ld", (long)afterWordCount);

                
                NSUInteger pageIndex = [[thisPageTag substringFromIndex:2] integerValue];
                NSUInteger afterBlockCount = 0;
                NSArray *pageBlocks = [textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:YES];
                BlioTextFlowBlock *wordContainingBlock = nil;
                for(BlioTextFlowBlock *block in [pageBlocks reverseObjectEnumerator]) {
                    if(!block.folio) {
                        NSUInteger blockWordCount = [[block words] count];
                        if(blockWordCount < afterWordCount) {
                            afterWordCount -= blockWordCount;
                        } else {
                            wordContainingBlock = block;
                            break;
                        }
                    }
                    afterBlockCount++;
                }
                if(wordContainingBlock) {
                    NSUInteger blockIndex = pageBlocks.count - afterBlockCount;
                    NSUInteger blockWordIndex = wordContainingBlock.words.count - afterWordCount;
                    
                    NSArray *xamlWordStrings = wordContainingDocumentRun.words;
                    NSLog(@"XAML: %@", [xamlWordStrings subarrayWithRange:NSMakeRange(wordOffset, xamlWordStrings.count - wordOffset)]);
                    NSArray *blockWordStrings = wordContainingBlock.wordStrings;
                    NSLog(@"Block: %@", [blockWordStrings subarrayWithRange:NSMakeRange(blockWordIndex, blockWordStrings.count - blockWordIndex)]);
                    NSLog(@"{%ld, %ld, %ld}", (long)pageIndex, (long)blockIndex, (long)blockWordIndex);
                }                
            }
        }        
        
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
    BlioTextFlowParagraph *paragraph = [self paragraphWithID:(NSIndexPath *)paragraphID];
    return paragraph.paragraphWords.wordStrings;
}

- (id)nextParagraphIdForParagraphWithID:(id)paragraphID
{
    NSIndexPath *ret = nil;
    
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
