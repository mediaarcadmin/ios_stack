//
//  BlioTextFlow.h
//  BlioApp
//
//  Created by matt on 26/01/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <expat/expat.h>
#import "BlioBook.h"
#import "BlioBookmark.h"
#import "BlioProcessingManager.h"
#import <libEucalyptus/EucBookContentsTableViewController.h>
#import "BlioTOCEntry.h"

@class BlioTextFlowFlowTree, BlioTextFlowXAMLTree;

@interface BlioTextFlowPositionedWord : NSObject {
    NSString *string;
    CGRect rect;
    NSIndexPath *blockID;
    NSUInteger wordIndex;
    NSNumber *wordID;
}

@property (nonatomic, retain) NSString *string;
@property (nonatomic) CGRect rect;
@property (nonatomic, retain) NSIndexPath *blockID;
@property (nonatomic) NSUInteger wordIndex;
@property (nonatomic, retain) NSNumber *wordID;

- (NSComparisonResult)compare:(BlioTextFlowPositionedWord *)rhs;
+ (NSUInteger)wordIndexForWordID:(id)aWordID;
+ (id)wordIDForWordIndex:(NSUInteger)aWordIndex;

@end

@interface BlioTextFlowPageMarker : NSObject {
    // NSCoding compliant
    NSUInteger pageIndex;
    NSUInteger byteIndex;
}

@property (nonatomic) NSUInteger pageIndex;
@property (nonatomic) NSUInteger byteIndex;

@end

@interface BlioTextFlowPageRange : NSObject <NSCoding> {
    // NSCoding compliant
    NSInteger startPageIndex;
    NSInteger endPageIndex;
    NSString *fileName;
    NSMutableSet *pageMarkers;
    
    // Transient
    XML_Parser *currentParser;
    NSInteger currentPageIndex;
}

@property (nonatomic) NSInteger startPageIndex;
@property (nonatomic) NSInteger endPageIndex;
@property (nonatomic, retain) NSString *fileName;
@property (nonatomic, retain) NSMutableSet *pageMarkers;

- (NSArray *)sortedPageMarkers;

@end

@interface BlioTextFlowBlock : NSObject {
    NSInteger pageIndex;
    NSInteger blockIndex;
    NSIndexPath *blockID;
    NSMutableArray *words;
    CGRect rect;
    BOOL folio;
}

@property (nonatomic) NSInteger pageIndex;
@property (nonatomic) NSInteger blockIndex;
@property (nonatomic, retain) NSIndexPath *blockID;
@property (nonatomic, retain) NSMutableArray *words;
@property (nonatomic, readonly) CGRect rect;
@property (nonatomic, getter=isFolio) BOOL folio;

- (NSString *)string;
- (NSArray *)wordStrings;
- (NSComparisonResult)compare:(BlioTextFlowBlock *)rhs;
+ (NSInteger)pageIndexForBlockID:(id)aBlockID;
+ (NSInteger)blockIndexForBlockID:(id)aBlockID;
+ (id)blockIDForPageIndex:(NSInteger)aPageIndex blockIndex:(NSInteger)aBlockIndex;

@end

@interface BlioTextFlowFlowReference : NSObject {
    NSUInteger startPage;
    NSString *flowSourceFileName;
}

@property (nonatomic, assign, readonly) NSUInteger startPage;
@property (nonatomic, retain, readonly) NSString *flowSourceFileName;

@end

@interface BlioTextFlowReference : NSObject {
    NSInteger pageIndex;
    NSString *referenceId;
}

@property (nonatomic, assign, readonly) NSInteger pageIndex;
@property (nonatomic, retain, readonly) NSString *referenceId;

@end

#define kTextFlowPageBlocksCacheCapacity 5

typedef enum BlioTextFlowFlowTreeKind
{
    BlioTextFlowFlowTreeKindUnknown = 0,
    BlioTextFlowFlowTreeKindFlow,
    BlioTextFlowFlowTreeKindXaml,
} BlioTextFlowFlowTreeKind;

@interface BlioTextFlow : NSObject <BlioProcessingManagerOperationProvider, EucBookContentsTableViewControllerDataSource> {
    NSSet *pageRanges;
    
    NSArray *flowReferences;
    NSArray *tableOfContents;
    
    NSManagedObjectID *bookID;
    
    NSInteger pageIndexCache[kTextFlowPageBlocksCacheCapacity];
    NSArray *pageBlocksCache[kTextFlowPageBlocksCacheCapacity];
    NSLock *pageBlocksCacheLock;
    
    BlioTextFlowFlowTreeKind flowTreeKind;
}

@property (nonatomic, retain, readonly) NSArray *flowReferences;
@property (nonatomic, retain, readonly) NSArray *tableOfContents;
@property (nonatomic, retain) NSManagedObjectID *bookID;
@property (nonatomic, assign, readonly) BlioTextFlowFlowTreeKind flowTreeKind;

- (id)initWithBookID:(NSManagedObjectID *)aBookID;

- (BlioTextFlowFlowTree *)flowTreeForFlowIndex:(NSUInteger)sectionIndex;
- (BlioTextFlowXAMLTree *)xamlTreeForFlowIndex:(NSUInteger)sectionIndex;
- (BlioTextFlowReference *)referenceForReferenceId:(NSString *)referenceId;

// Convenience methods
- (NSArray *)sortedPageRanges;
- (BlioTextFlowBlock *)nextBlockForBlock:(BlioTextFlowBlock *)block includingFolioBlocks:(BOOL)includingFolioBlocks onSamePage:(BOOL)onSamePage;
- (BlioTextFlowBlock *)nextBlockForBlock:(BlioTextFlowBlock *)block includingFolioBlocks:(BOOL)includingFolioBlocks onSamePage:(BOOL)onSamePage;
- (BlioTextFlowBlock *)previousBlockForBlock:(BlioTextFlowBlock *)block includingFolioBlocks:(BOOL)includingFolioBlocks onSamePage:(BOOL)onSamePage;
- (NSArray *)blocksForPageAtIndex:(NSInteger)pageIndex includingFolioBlocks:(BOOL)wantFolioBlocks;
- (NSArray *)wordStringsForPageAtIndex:(NSInteger)pageIndex;
- (NSArray *)wordsForBookmarkRange:(BlioBookmarkRange *)range;
- (NSArray *)wordStringsForBookmarkRange:(BlioBookmarkRange *)range;
- (NSString *)stringForPageAtIndex:(NSInteger)pageIndex;
- (NSUInteger)lastPageIndex; 

@end
