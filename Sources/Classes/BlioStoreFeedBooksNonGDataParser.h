//
//  BlioStoreFeedBooksParser.h
//  BlioApp
//
//  Created by matt on 09/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioStoreBooksSourceParser.h"
#import "BlioAppAppDelegate.h"

@interface BlioStoreFeedBooksNonGDataParser : BlioStoreBooksSourceParser BLIO_NSXMLPARSER_DELEGATE {
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
    NSDate *currentReleasedDate;
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

- (void)startWithURL:(NSURL *)url;

@end
