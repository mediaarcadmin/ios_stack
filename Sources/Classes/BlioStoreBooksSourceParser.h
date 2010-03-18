//
//  BlioStoreGoogleBooksParser.h
//  BlioApp
//
//  Created by matt on 11/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GDataBooks.h>

@interface BlioStoreParsedCategory : NSObject {
    NSString *title;
    NSURL *url;
    NSString *type;
}

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) NSString *type;

- (Class)classForType;

@end

@interface BlioStoreParsedEntity : NSObject {
    NSString *title;
    NSString *author;
    NSURL *url;
    NSString *summary;
    NSString *ePubUrl;
    NSString *pdfUrl;
    NSString *coverUrl;
    NSString *thumbUrl;
    NSDate *releasedDate;
    NSDate *publishedDate;
    NSString *publisher;
    NSString *pageCount;
}

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *author;
@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) NSString *summary;
@property (nonatomic, retain) NSString *ePubUrl;
@property (nonatomic, retain) NSString *pdfUrl;
@property (nonatomic, retain) NSString *coverUrl;
@property (nonatomic, retain) NSString *thumbUrl;
@property (nonatomic, retain) NSDate *releasedDate;
@property (nonatomic, retain) NSDate *publishedDate;
@property (nonatomic, retain) NSString *publisher;
@property (nonatomic, retain) NSString *pageCount;

@end

@class BlioStoreBooksSourceParser;

// Protocol for the parser to communicate with its delegate.
@protocol BlioStoreBooksSourceParserDelegate <NSObject>

@optional
- (void)parserDidEndParsingData:(BlioStoreBooksSourceParser *)parser;
- (void)parser:(BlioStoreBooksSourceParser *)parser didFailWithError:(NSError *)error;
- (void)parser:(BlioStoreBooksSourceParser *)parser didParseTotalResults:(NSNumber *)volumeTotalResults;
- (void)parser:(BlioStoreBooksSourceParser *)parser didParseNextLink:(NSURL *)nextLink;
- (void)parser:(BlioStoreBooksSourceParser *)parser didParseCategories:(NSArray *)parsedCategories;
- (void)parser:(BlioStoreBooksSourceParser *)parser didParseEntities:(NSArray *)parsedEntities;
- (void)parser:(BlioStoreBooksSourceParser *)parser didParseEntity:(BlioStoreParsedEntity *)parsedEntity;
@end

@interface BlioStoreBooksSourceParser : NSObject {
    id <BlioStoreBooksSourceParserDelegate> delegate;
    GDataServiceGoogleBooks *service;
    
    NSMutableArray *parsedCategories;
    NSMutableArray *parsedEntities;
}

@property (nonatomic, assign) id <BlioStoreBooksSourceParserDelegate> delegate;
@property (nonatomic, retain) NSMutableArray *parsedCategories;
@property (nonatomic, retain) NSMutableArray *parsedEntities;
@property (nonatomic, retain) GDataServiceGoogleBooks *service;

- (void)startWithURL:(NSURL *)url;

// Subclasses can override these methods
- (NSURL *)queryUrlForString:(NSString *)queryString;

// Subclasses must override these methods
- (void)volumeListFetchTicket:(GDataServiceTicket *)ticket finishedWithFeed:(GDataFeedVolume *)object error:(NSError *)error;

@end
