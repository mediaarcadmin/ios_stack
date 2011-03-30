//
//  BlioTextFlow.m
//  BlioApp
//
//  Created by matt on 26/01/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioTextFlow.h"

@implementation BlioTextFlow

- (id)initWithBookID:(NSManagedObjectID *)aBookID
{
    return [super initWithBookID:aBookID];
}

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

#pragma mark -
#pragma mark Blio Methods

- (NSArray *)wordsForBookmarkRange:(BlioBookmarkRange *)range
{
    return nil;
}

- (NSArray *)wordStringsForBookmarkRange:(BlioBookmarkRange *)range
{
    return nil;
}

+ (NSArray *)preAvailabilityOperations {
    BlioTextFlowPreParseOperation *preParseOp = [[BlioTextFlowPreParseOperation alloc] init];
    NSArray *operations = [NSArray arrayWithObject:preParseOp];
    [preParseOp release];
    return operations;
}

@end
