//
//  BlioTextFlow.m
//  BlioApp
//
//  Created by matt on 26/01/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioTextFlow.h"
#import "BlioBook.h"
#import "BlioBookManager.h"

@interface BlioTextFlow()

- (BlioBook *)book;

@end

@implementation BlioTextFlow

#pragma mark -
#pragma mark Wrapper Methods

- (BlioTextFlowFlowTree *)flowTreeForFlowIndex:(NSUInteger)sectionIndex 
{
    return (BlioTextFlowFlowTree *)[super flowTreeForFlowIndex:sectionIndex];
}

- (BlioTextFlowXAMLTree *)xamlTreeForFlowIndex:(NSUInteger)sectionIndex 
{
    return (BlioTextFlowXAMLTree *)[super xamlTreeForFlowIndex:sectionIndex];
}

- (BlioTextFlowReference *)referenceForReferenceId:(NSString *)referenceId
{
    return (BlioTextFlowReference *)[super referenceForReferenceId:referenceId];
}

- (BlioTextFlowBlock *)nextBlockForBlock:(BlioTextFlowBlock *)block includingFolioBlocks:(BOOL)includingFolioBlocks onSamePage:(BOOL)onSamePage
{
    return (BlioTextFlowBlock *)[super nextBlockForBlock:block includingFolioBlocks:includingFolioBlocks onSamePage:onSamePage];
}

- (BlioTextFlowBlock *)previousBlockForBlock:(BlioTextFlowBlock *)block includingFolioBlocks:(BOOL)includingFolioBlocks onSamePage:(BOOL)onSamePage
{
    return (BlioTextFlowBlock *)[super previousBlockForBlock:block includingFolioBlocks:includingFolioBlocks onSamePage:onSamePage];
}

- (NSArray *)wordsForBookmarkRange:(BlioBookmarkRange *)range {
    return [self wordsForRange:range];
}

- (NSArray *)wordStringsForBookmarkRange:(BlioBookmarkRange *)range {
    return [self wordStringsForRange:range];
}

#pragma mark -
#pragma mark Overriden methods

- (NSArray *)wordsForRange:(id)aRange
{
    BlioBookmarkRange *range = (BlioBookmarkRange *)aRange;
    
    NSMutableArray *allWords = [NSMutableArray array];
    
    for (NSInteger pageNumber = range.startPoint.layoutPage; pageNumber <= range.endPoint.layoutPage; pageNumber++) {
        NSInteger pageIndex = pageNumber - 1;
        
        for (BlioTextFlowBlock *block in [self blocksForPageAtIndex:pageIndex includingFolioBlocks:YES]) {
            if (![block isFolio]) {
                for (BlioTextFlowPositionedWord *word in [block words]) {
                    if ((range.startPoint.layoutPage < pageNumber) &&
                        (block.blockIndex <= range.endPoint.blockOffset) &&
                        (word.wordIndex <= range.endPoint.wordOffset)) {
                        
                        [allWords addObject:word];
                        
                    } else if ((range.endPoint.layoutPage > pageNumber) &&
                               (block.blockIndex >= range.startPoint.blockOffset) &&
                               (word.wordIndex >= range.startPoint.wordOffset)) {
                        
                        [allWords addObject:word];
                        
                    } else if ((range.startPoint.layoutPage == pageNumber) &&
                               (block.blockIndex == range.startPoint.blockOffset) &&
                               (word.wordIndex >= range.startPoint.wordOffset)) {
                        
                        if ((block.blockIndex == range.endPoint.blockOffset) &&
                            (word.wordIndex <= range.endPoint.wordOffset)) {
                            [allWords addObject:word];
                        } else if (block.blockIndex < range.endPoint.blockOffset) {
                            [allWords addObject:word];
                        }
                        
                    } else if ((range.startPoint.layoutPage == pageNumber) &&
                               (block.blockIndex > range.startPoint.blockOffset)) {
                        
                        if ((block.blockIndex == range.endPoint.blockOffset) &&
                            (word.wordIndex <= range.endPoint.wordOffset)) {
                            [allWords addObject:word];
                        } else if (block.blockIndex < range.endPoint.blockOffset) {
                            [allWords addObject:word];
                        }
                        
                    }
                }
            }
        }
    }
    
    return allWords;
}

- (NSArray *)wordStringsForRange:(id)aRange {
    BlioBookmarkRange *range = (BlioBookmarkRange *)aRange;
    return [[self wordsForBookmarkRange:range] valueForKey:@"string"];
}

- (id)rangeWithStartPage:(NSUInteger)startPage 
              startBlock:(NSUInteger)startBlock
               startWord:(NSUInteger)startWord
                 endPage:(NSUInteger)endPage
                endBlock:(NSUInteger)endBlock
                 endWord:(NSUInteger)endWord
{
    BlioBookmarkPoint *startPoint = [[BlioBookmarkPoint alloc] init];
    startPoint.layoutPage = startPage;
    startPoint.blockOffset = startBlock;
    startPoint.wordOffset = startWord;
    
    BlioBookmarkPoint *endPoint = [[BlioBookmarkPoint alloc] init];
    endPoint.layoutPage = endPage;
    endPoint.blockOffset = endBlock;
    endPoint.wordOffset = endWord;
    
    BlioBookmarkRange *range = [[BlioBookmarkRange alloc] init];
    range.startPoint = startPoint;
    range.endPoint = endPoint;
    
    [startPoint release];
    [endPoint release];
    
    return [range autorelease];
}

- (NSSet *)persistedTextFlowPageRanges
{
    return [self.book valueForKey:@"textFlowPageRanges"];
}

- (NSData *)textFlowDataWithPath:(NSString *)path
{
    return [self.book textFlowDataWithPath:path];
}

- (NSData *)textFlowRootFileData
{
    return [self.book manifestDataForKey:BlioManifestTextFlowKey];
}

#pragma mark -
#pragma mark Blio specific methods

- (BlioBook *)book {
    return [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
}

+ (NSArray *)preAvailabilityOperations {
    BlioTextFlowPreParseOperation *preParseOp = [[BlioTextFlowPreParseOperation alloc] init];
    NSArray *operations = [NSArray arrayWithObject:preParseOp];
    [preParseOp release];
    return operations;
}

@end
