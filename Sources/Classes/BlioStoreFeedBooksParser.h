//
//  BlioStoreFeedBooksParser.h
//  BlioApp
//
//  Created by matt on 09/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlioStoreParsedCategory : NSObject {
    NSString *title;
    NSString *url;
}

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *url;

@end

@interface BlioStoreParsedEntity : NSObject {
    NSString *title;
    NSString *author;
    NSString *url;
    NSString *summary;
    NSString *ePubUrl;
    NSString *pdfUrl;
    NSString *coverUrl;
    NSString *thumbUrl;
    NSString *releasedYear;
    NSDate *publishedDate;
}

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *author;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *summary;
@property (nonatomic, retain) NSString *ePubUrl;
@property (nonatomic, retain) NSString *pdfUrl;
@property (nonatomic, retain) NSString *coverUrl;
@property (nonatomic, retain) NSString *thumbUrl;
@property (nonatomic, retain) NSString *releasedYear;
@property (nonatomic, retain) NSDate *publishedDate;

@end

@class BlioStoreFeedBooksParser;

// Protocol for the parser to communicate with its delegate.
@protocol BlioStoreFeedBooksParserDelegate <NSObject>

@optional
- (void)parserDidEndParsingData:(BlioStoreFeedBooksParser *)parser;
- (void)parser:(BlioStoreFeedBooksParser *)parser didFailWithError:(NSError *)error;
- (void)parser:(BlioStoreFeedBooksParser *)parser didParseCategories:(NSArray *)parsedCategories;
- (void)parser:(BlioStoreFeedBooksParser *)parser didParseEntities:(NSArray *)parsedEntities;
- (void)parser:(BlioStoreFeedBooksParser *)parser didParseEntity:(BlioStoreParsedEntity *)parsedEntity;

@end


@interface BlioStoreFeedBooksParser : NSObject {
    id <BlioStoreFeedBooksParserDelegate> delegate;
    NSMutableArray *parsedCategories;
    NSMutableArray *parsedEntities;
    NSMutableString *currentString;
    BlioStoreParsedCategory *currentCategory;
    BlioStoreParsedEntity *currentEntity;
    NSString *currentTitle;
    NSString *currentAuthorName;
    NSString *currentSummary;
    NSString *currentEPubUrl;
    NSString *currentPdfUrl;
    NSString *currentCoverUrl;
    NSString *currentThumbUrl;
    NSString *currentReleasedYear;
    NSDate *currentPublishedDate;
    NSURL *currentBaseURL;
    NSDateFormatter *atomDateFormatter;
    NSMutableData *xmlData;
    NSURLConnection *feedConnection;
    NSAutoreleasePool *downloadAndParsePool;
    
    NSUInteger countOfParsedItems;
    BOOL done;
    BOOL storingCharacters;
    BOOL parsingFeed;
    BOOL parsingEntry;
    BOOL parsingAuthor;
}

@property (nonatomic, assign) id <BlioStoreFeedBooksParserDelegate> delegate;

- (void)startWithURL:(NSURL *)url;

@end
