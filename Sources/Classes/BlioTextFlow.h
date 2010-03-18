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
    NSIndexPath *paragraphID;
    NSInteger wordIndex;
    NSNumber *wordID;
}

@property (nonatomic, retain) NSString *string;
@property (nonatomic) CGRect rect;
@property (nonatomic, retain) NSIndexPath *paragraphID;
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

@interface BlioTextFlowSection : NSObject <NSCoding> {
    // NSCoding compliant
    NSInteger pageIndex;
    NSString *name;
    NSString *path;
    NSString *anchor;
    NSMutableSet *pageMarkers;
    
    // Transient
    XML_Parser *currentParser;
    NSInteger currentPageIndex;
}

@property (nonatomic) NSInteger pageIndex;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain) NSString *anchor;
@property (nonatomic, retain) NSMutableSet *pageMarkers;

- (NSArray *)sortedPageMarkers;

@end

@interface BlioTextFlowParagraph : NSObject {
    NSInteger pageIndex;
    NSInteger paragraphIndex;
    NSIndexPath *paragraphID;
    NSMutableArray *words;
    CGRect rect;
    BOOL folio;
}

@property (nonatomic) NSInteger pageIndex;
@property (nonatomic) NSInteger paragraphIndex;
@property (nonatomic, retain) NSIndexPath *paragraphID;
@property (nonatomic, retain) NSMutableArray *words;
@property (nonatomic, readonly) CGRect rect;
@property (nonatomic) BOOL folio;

- (NSString *)string;
- (NSArray *)wordsArray;
- (NSComparisonResult)compare:(BlioTextFlowParagraph *)rhs;
+ (NSInteger)pageIndexForParagraphID:(id)aParagraphID;
+ (NSInteger)paragraphIndexForParagraphID:(id)aParagraphID;
+ (id)paragraphIDForPageIndex:(NSInteger)aPageIndex paragraphIndex:(NSInteger)aParagraphIndex;

@end

@interface BlioTextFlow : NSObject <BlioProcessingManagerOperationProvider> {
    NSSet *sections;
    NSInteger currentPageIndex;
    BlioTextFlowSection *currentSection;
    BlioTextFlowParagraph *currentParagraph;
    NSMutableArray *currentParagraphArray;
    XML_Parser currentParser;
    NSInteger cachedPageIndex;
    NSArray *cachedPageParagraphs;
    NSString *basePath;
}

- (id)initWithSections:(NSSet *)sectionsSet basePath:(NSString *)aBasePath;

// Convenience methods
- (NSArray *)sortedSections;
- (NSArray *)paragraphsForPageAtIndex:(NSInteger)pageIndex;
- (NSArray *)wordsForPageAtIndex:(NSInteger)pageIndex;
- (NSArray *)wordStringsForBookmarkRange:(BlioBookmarkRange *)range;
- (NSString *)stringForPageAtIndex:(NSInteger)pageIndex;

@end
