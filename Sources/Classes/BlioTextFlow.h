//
//  BlioTextFlow.h
//  BlioApp
//
//  Created by matt on 26/01/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <expat/expat.h>

@interface BlioTextFlowPositionedWord : NSObject {
    NSString *string;
    CGRect rect;
    NSInteger pageIndex;
    NSInteger wordIndex;
    NSNumber *wordID;
}

@property (nonatomic, retain) NSString *string;
@property (nonatomic) CGRect rect;
@property (nonatomic) NSInteger pageIndex;
@property (nonatomic) NSInteger wordIndex;
@property (nonatomic, retain) NSNumber *wordID;

- (NSComparisonResult)compare:(BlioTextFlowPositionedWord *)rhs;
+ (NSInteger)wordIndexForWordID:(id)aWordID;

@end

@interface BlioTextFlowPageMarker : NSObject {
    NSUInteger pageIndex;
    NSUInteger byteIndex;
}

@property (nonatomic) NSUInteger pageIndex;
@property (nonatomic) NSUInteger byteIndex;

@end

@interface BlioTextFlowSection : NSObject {
    NSInteger pageIndex;
    NSString *name;
    NSString *path;
    NSString *anchor;
    NSMutableSet *pageMarkers;
}

@property (nonatomic) NSInteger pageIndex;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain) NSString *anchor;
@property (nonatomic, retain) NSMutableSet *pageMarkers;

- (void)addPageMarker:(BlioTextFlowPageMarker *)aPageMarker;
- (NSArray *)sortedPageMarkers;

@end

@interface BlioTextFlowParagraph : NSObject {
    NSInteger pageIndex;
    NSInteger paragraphIndex;
    NSString *paragraphID;
    NSMutableArray *words;
    CGRect rect;
    BOOL folio;
}

@property (nonatomic) NSInteger pageIndex;
@property (nonatomic) NSInteger paragraphIndex;
@property (nonatomic, retain) NSString *paragraphID;
@property (nonatomic, retain) NSMutableArray *words;
@property (nonatomic, readonly) CGRect rect;
@property (nonatomic) BOOL folio;

- (NSString *)string;
- (NSArray *)wordsArray;
- (NSComparisonResult)compare:(BlioTextFlowParagraph *)rhs;
+ (NSInteger)pageIndexForParagraphID:(id)aParagraphID;
+ (NSInteger)paragraphIndexForParagraphID:(id)aParagraphID;

@end

@interface BlioTextFlow : NSObject {
    NSMutableSet *sections;
    NSInteger currentPageIndex;
    BlioTextFlowSection *currentSection;
    BlioTextFlowParagraph *currentParagraph;
    NSMutableArray *currentParagraphArray;
    XML_Parser currentParser;
    NSInteger cachedPageIndex;
    NSArray *cachedPageParagraphs;
}

@property (nonatomic, retain) NSMutableSet *sections;

- (id)initWithPath:(NSString *)path;

// Convenience methods
- (NSArray *)sortedSections;
- (NSArray *)paragraphsForPageAtIndex:(NSInteger)pageIndex;
- (NSString *)stringForPageAtIndex:(NSInteger)pageIndex;

@end
