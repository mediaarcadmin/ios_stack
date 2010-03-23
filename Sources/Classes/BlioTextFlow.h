//
//  BlioTextFlow.h
//  BlioApp
//
//  Created by matt on 26/01/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <expat/expat.h>
#import "BlioBookmark.h"
#import "BlioProcessingManager.h"

@interface BlioTextFlowPositionedWord : NSObject {
    NSString *string;
    CGRect rect;
    NSIndexPath *blockID;
    NSInteger wordIndex;
    NSNumber *wordID;
}

@property (nonatomic, retain) NSString *string;
@property (nonatomic) CGRect rect;
@property (nonatomic, retain) NSIndexPath *blockID;
@property (nonatomic) NSInteger wordIndex;
@property (nonatomic, retain) NSNumber *wordID;

- (NSComparisonResult)compare:(BlioTextFlowPositionedWord *)rhs;
+ (NSInteger)wordIndexForWordID:(id)aWordID;
+ (id)wordIDForWordIndex:(NSInteger)aWordIndex;

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
    NSInteger pageIndex;
    NSString *path;
    NSMutableSet *pageMarkers;
    
    // Transient
    XML_Parser *currentParser;
    NSInteger currentPageIndex;
}

@property (nonatomic) NSInteger pageIndex;
@property (nonatomic, retain) NSString *path;
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
@property (nonatomic) BOOL folio;

- (NSString *)string;
- (NSArray *)wordStrings;
- (NSComparisonResult)compare:(BlioTextFlowBlock *)rhs;
+ (NSInteger)pageIndexForBlockID:(id)aBlockID;
+ (NSInteger)blockIndexForBlockID:(id)aBlockID;
+ (id)blockIDForPageIndex:(NSInteger)aPageIndex blockIndex:(NSInteger)aBlockIndex;

@end

@interface BlioTextFlow : NSObject <BlioProcessingManagerOperationProvider> {
    NSSet *pageRanges;
    NSInteger currentPageIndex;
    BlioTextFlowPageRange *currentPageRange;
    BlioTextFlowBlock *currentBlock;
    NSMutableArray *currentBlockArray;
    XML_Parser currentParser;
    NSInteger cachedPageIndex;
    NSArray *cachedPageBlocks;
    NSString *basePath;
}

- (id)initWithPageRanges:(NSSet *)pageRangesSet basePath:(NSString *)aBasePath;

// Convenience methods
- (NSArray *)sortedPageRanges;
- (NSArray *)blocksForPageAtIndex:(NSInteger)pageIndex;
- (NSArray *)wordStringsForPageAtIndex:(NSInteger)pageIndex;
- (NSArray *)wordsForBookmarkRange:(BlioBookmarkRange *)range;
- (NSArray *)wordStringsForBookmarkRange:(BlioBookmarkRange *)range;
- (NSString *)stringForPageAtIndex:(NSInteger)pageIndex;

@end
