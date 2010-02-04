//
//  BlioTextFlow.h
//  BlioApp
//
//  Created by matt on 26/01/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <libxml/xmlreader.h>
#import <libxml/parser.h>
#import "expat.h"

@interface BlioTextFlowPositionedWord : NSObject {
    NSString *string;
    CGRect rect;
    NSInteger pageIndex;
    NSInteger wordIndex;
}

@property (nonatomic, retain) NSString *string;
@property (nonatomic) CGRect rect;
@property (nonatomic) NSInteger pageIndex;
@property (nonatomic) NSInteger wordIndex;

- (NSComparisonResult)compare:(BlioTextFlowPositionedWord *)rhs;

@end

@interface BlioTextFlowPageMarker : NSObject {
    NSInteger pageIndex;
    NSInteger lineNumber;
    NSInteger byteIndex;
}

@property (nonatomic) NSInteger pageIndex;
@property (nonatomic) NSInteger lineNumber;
@property (nonatomic) NSInteger byteIndex;

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
    NSMutableArray *words;
    CGRect rect;
    BOOL folio;
}

@property (nonatomic) NSInteger pageIndex;
@property (nonatomic) NSInteger paragraphIndex;
@property (nonatomic, retain) NSMutableArray *words;
@property (nonatomic, readonly) CGRect rect;
@property (nonatomic) BOOL folio;

- (NSString *)string;
- (NSArray *)wordsArray;
- (NSComparisonResult)compare:(BlioTextFlowParagraph *)rhs;

@end

@interface BlioTextFlowSlow : NSObject {
    NSXMLParser *textFlowParser;
    NSMutableArray *sections;
    NSMutableArray *pages;
    NSMutableArray *paragraphs;
    
    BlioTextFlowSection *currentSection;
    NSMutableArray *currentPage;
    BlioTextFlowParagraph *currentParagraph;
    BlioTextFlowPositionedWord *currentWord;
    NSString *currentWordString;
    NSString *currentWordRect;
}

@property (nonatomic, retain) NSMutableArray *sections;
@property (nonatomic, retain) NSMutableArray *pages;
@property (nonatomic, retain) NSMutableArray *paragraphs;

- (id)initWithPath:(NSString *)path;

// Convenience methods
- (NSArray *)paragraphsForPageAtIndex:(NSInteger)pageIndex;
- (NSString *)stringForPageAtIndex:(NSInteger)pageIndex;

@end

@interface BlioTextFlow : NSObject {
    // Reference to the libxml parser context
    xmlParserCtxtPtr context;
    BOOL done;
    // State variable used to determine whether or not to ignore a given XML element
    BOOL parsingAnElement;
    // The following state variables deal with getting character data from XML elements. This is a potentially expensive 
    // operation. The character data in a given element may be delivered over the course of multiple callbacks, so that
    // data must be appended to a buffer. The optimal way of doing this is to use a C string buffer that grows exponentially.
    // When all the characters have been delivered, an NSString is constructed and the buffer is reset.
    BOOL storingCharacters;
    NSMutableData *characterBuffer;
    // The number of parsed songs is tracked so that the autorelease pool for the parsing thread can be periodically
    // emptied to keep the memory footprint under control. 
    NSUInteger countOfParsedElements;
    NSAutoreleasePool *parsePool;

    
    NSMutableSet *sections;
    NSMutableArray *pages;
    NSMutableArray *paragraphs;
    
    BlioTextFlowSection *currentSection;
    NSMutableArray *currentPage;
    BlioTextFlowParagraph *currentParagraph;
    BlioTextFlowPositionedWord *currentWord;
    NSString *currentWordString;
    NSString *currentWordRect;
    NSInteger currentPageIndex;
    NSMutableArray *currentParagraphArray;
    XML_Parser currentParser;
}

@property (nonatomic, retain) NSMutableSet *sections;
@property (nonatomic, retain) NSMutableArray *pages;
@property (nonatomic, retain) NSMutableArray *paragraphs;
@property BOOL storingCharacters;
@property (nonatomic, retain) NSMutableData *characterBuffer;
@property BOOL done;
@property BOOL parsingAnElement;
@property NSUInteger countOfParsedElements;
// The autorelease pool property is assign because autorelease pools cannot be retained.
@property (nonatomic, assign) NSAutoreleasePool *parsePool;
@property (nonatomic, retain) NSMutableArray *currentParagraphArray;
@property (nonatomic, readonly) XML_Parser currentParser;

- (id)initWithPath:(NSString *)path;

// Convenience methods
- (NSArray *)sortedSections;
- (NSArray *)paragraphsForPageAtIndex:(NSInteger)pageIndex;
- (NSString *)stringForPageAtIndex:(NSInteger)pageIndex;

@end
