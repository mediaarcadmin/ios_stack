//
//  BlioTextFlow.h
//  BlioApp
//
//  Created by matt on 26/01/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "KNFBTextFlow.h"
#import "BlioBookmark.h"
#import "BlioProcessingManager.h"
#import "BlioTextFlowReference.h"

@class BlioTextFlowFlowTree, BlioTextFlowXAMLTree;

typedef enum BlioTextFlowFlowTreeKind
{
    BlioTextFlowFlowTreeKindUnknown = 0,
    BlioTextFlowFlowTreeKindFlow,
    BlioTextFlowFlowTreeKindXaml,
} BlioTextFlowFlowTreeKind;

@interface BlioTextFlow : KNFBTextFlow <BlioProcessingManagerOperationProvider> {}

- (id)initWithBookID:(NSManagedObjectID *)aBookID;

// Wrapper methods
- (BlioTextFlowFlowTree *)flowTreeForFlowIndex:(NSUInteger)sectionIndex;
- (BlioTextFlowXAMLTree *)xamlTreeForFlowIndex:(NSUInteger)sectionIndex;
- (BlioTextFlowReference *)referenceForReferenceId:(NSString *)referenceId;

- (BlioTextFlowBlock *)nextBlockForBlock:(BlioTextFlowBlock *)block includingFolioBlocks:(BOOL)includingFolioBlocks onSamePage:(BOOL)onSamePage;
- (BlioTextFlowBlock *)nextBlockForBlock:(BlioTextFlowBlock *)block includingFolioBlocks:(BOOL)includingFolioBlocks onSamePage:(BOOL)onSamePage;
- (BlioTextFlowBlock *)previousBlockForBlock:(BlioTextFlowBlock *)block includingFolioBlocks:(BOOL)includingFolioBlocks onSamePage:(BOOL)onSamePage;

// Blio methods
- (NSArray *)wordsForBookmarkRange:(BlioBookmarkRange *)range;
- (NSArray *)wordStringsForBookmarkRange:(BlioBookmarkRange *)range;

@end
