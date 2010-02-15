//
//  BlioStoreFeedBooksParser.m
//  BlioApp
//
//  Created by matt on 09/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioStoreFeedBooksNonGDataParser.h"

@interface BlioStoreFeedBooksNonGDataParser()
@property (nonatomic, retain) NSMutableString *currentString;
@property (nonatomic, retain) BlioStoreParsedCategory *currentCategory;
@property (nonatomic, retain) BlioStoreParsedEntity *currentEntity;
@property (nonatomic, retain) NSString *currentTitle;
@property (nonatomic, retain) NSString *currentAuthorName;
@property (nonatomic, retain) NSString *currentSummary;
@property (nonatomic, retain) NSString *currentEPubUrl;
@property (nonatomic, retain) NSString *currentPdfUrl;
@property (nonatomic, retain) NSString *currentCoverUrl;
@property (nonatomic, retain) NSString *currentThumbUrl;
@property (nonatomic, retain) NSDate *currentReleasedDate;
@property (nonatomic, retain) NSDate *currentPublishedDate;
@property (nonatomic, retain) NSURL *currentBaseURL;
@property (nonatomic, retain) NSDateFormatter *atomDateFormatter;
@property (nonatomic, retain) NSMutableData *xmlData;
@property (nonatomic, retain) NSURLConnection *feedConnection;
@property (nonatomic, assign) NSAutoreleasePool *downloadAndParsePool;
@property (nonatomic) NSUInteger countOfParsedItems;
@property (nonatomic) BOOL done;
@property (nonatomic) BOOL storingCharacters;
@property (nonatomic) BOOL parsingFeed;
@property (nonatomic) BOOL parsingEntry;
@property (nonatomic) BOOL parsingAuthor;

- (void)downloadAndParse:(NSURL *)url;
- (void)downloadStarted;
- (void)downloadEnded;
- (void)parseEnded;
- (void)parsedCategory:(BlioStoreParsedCategory *)category;
- (void)parsedEntityInCollection:(BlioStoreParsedEntity *)entity;
- (void)parsedEntity:(BlioStoreParsedEntity *)entity;
- (void)parseError:(NSError *)error;
- (void)clearElementProperties;

@end


static NSUInteger kBlioStoreFeedBooksParserCountForNotification = 10;

@implementation BlioStoreFeedBooksNonGDataParser

@synthesize currentString, currentCategory, currentEntity, currentBaseURL, atomDateFormatter, xmlData, feedConnection, downloadAndParsePool;
@synthesize done, storingCharacters, parsingFeed, parsingEntry, parsingAuthor, countOfParsedItems;
@synthesize currentTitle, currentAuthorName, currentSummary, currentEPubUrl, currentPdfUrl, currentCoverUrl, currentThumbUrl, currentReleasedDate, currentPublishedDate;

- (void)dealloc {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.delegate = nil;
    self.currentString = nil;
    self.parsedCategories = nil;
    self.parsedEntities = nil;
    self.atomDateFormatter = nil;
    self.xmlData = nil;
    self.feedConnection = nil;
    self.downloadAndParsePool = nil;
    [self clearElementProperties];
    [super dealloc];
}

- (void)clearElementProperties {
    self.currentBaseURL = nil;
    self.currentCategory = nil;
    self.currentEntity = nil;
    self.currentTitle = nil;
    self.currentAuthorName = nil;
    self.currentSummary = nil;
    self.currentEPubUrl = nil;
    self.currentPdfUrl = nil;
    self.currentCoverUrl = nil;
    self.currentThumbUrl = nil;
    self.currentReleasedDate = nil;
    self.currentPublishedDate = nil;
}

- (void)startWithURL:(NSURL *)url {
    self.parsedCategories = [NSMutableArray array];
    self.parsedEntities = [NSMutableArray array];
   
    if (nil != url)
        [NSThread detachNewThreadSelector:@selector(downloadAndParse:) toTarget:self withObject:url];
}

- (void)downloadAndParse:(NSURL *)url {
    self.downloadAndParsePool = [[NSAutoreleasePool alloc] init];
    self.done = NO;
    
    self.atomDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [atomDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    
    self.xmlData = [NSMutableData data];
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:url];
    self.feedConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    [self performSelectorOnMainThread:@selector(downloadStarted) withObject:nil waitUntilDone:NO];
    if (self.feedConnection != nil) {
        do {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        } while (!self.done);
    }
    
    self.feedConnection = nil;
    self.atomDateFormatter = nil;
    self.currentString = nil;
    [self clearElementProperties];
    
    [self.downloadAndParsePool drain];
    self.downloadAndParsePool = nil;
}

- (void)downloadStarted {
    NSAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)downloadEnded {
    NSAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)parseEnded {
    NSAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);

    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parser:didParseCategories:)] && [parsedCategories count] > 0) {
        [self.delegate parser:self didParseCategories:parsedCategories];
    }
    [self.parsedCategories removeAllObjects];
    
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parser:didParseEntities:)] && [parsedEntities count] > 0) {
        [self.delegate parser:self didParseEntities:parsedEntities];
    }
    [self.parsedEntities removeAllObjects];
    
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parserDidEndParsingData:)]) {
        [self.delegate parserDidEndParsingData:self];
    }
}

- (void)parseError:(NSError *)error {
    NSAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);

    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parser:didFailWithError:)]) {
        [self.delegate parser:self didFailWithError:error];
    }
}

- (void)parsedCategory:(BlioStoreParsedCategory *)category {
    NSAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
    
    [self.parsedCategories addObject:category];
    if (self.parsedCategories.count > kBlioStoreFeedBooksParserCountForNotification) {
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parser:didParseCategories:)]) {
            [self.delegate parser:self didParseCategories:self.parsedCategories];
        }
        [self.parsedCategories removeAllObjects];
    }
}

- (void)parsedEntity:(BlioStoreParsedEntity *)entity {
    NSAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
    
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parser:didParseEntity:)]) {
        [self.delegate parser:self didParseEntity:entity];
    }
}

- (void)parsedEntityInCollection:(BlioStoreParsedEntity *)entity {
    NSAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
    
    [self.parsedEntities addObject:entity];
    if (self.parsedEntities.count > kBlioStoreFeedBooksParserCountForNotification) {
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parser:didParseEntities:)]) {
            [self.delegate parser:self didParseEntities:self.parsedEntities];
        }
        [self.parsedEntities removeAllObjects];
    }
}

#pragma mark -
#pragma mark NSURLConnection Delegate methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.done = YES;
    [self performSelectorOnMainThread:@selector(parseError:) withObject:error waitUntilDone:NO];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the downloaded chunk of data.
    [self.xmlData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self performSelectorOnMainThread:@selector(downloadEnded) withObject:nil waitUntilDone:NO];
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.xmlData];
    parser.delegate = self;
    self.currentString = [NSMutableString string];
    [parser parse];
    
    [self performSelectorOnMainThread:@selector(parseEnded) withObject:nil waitUntilDone:NO];
    [parser release];
    self.currentString = nil;
    self.xmlData = nil;
    // Set the condition which ends the run loop.
    self.done = YES; 
}

#pragma mark Parsing support methods

static const NSUInteger kBlioStoreFeedbooksParserAutoreleasePoolPurgeFrequency = 20;

- (void)finishedCurrentCategory {
    // Fill with any elements polpulated during parse
    [self.currentCategory setTitle:self.currentTitle];

    [self performSelectorOnMainThread:@selector(parsedCategory:) withObject:self.currentCategory waitUntilDone:NO];
    // performSelectorOnMainThread: will retain the object until the selector has been performed
    // setting the local reference to nil ensures that the local reference will be released
    self.currentCategory = nil;
    self.countOfParsedItems++;
    // Periodically purge the autorelease pool. The frequency of this action may need to be tuned according to the 
    // size of the objects being parsed. The goal is to keep the autorelease pool from growing too large, but 
    // taking this action too frequently would be wasteful and reduce performance.
    if (self.countOfParsedItems >= kBlioStoreFeedbooksParserAutoreleasePoolPurgeFrequency) {
        [downloadAndParsePool release];
        self.downloadAndParsePool = [[NSAutoreleasePool alloc] init];
        self.countOfParsedItems = 0;
    }
}

- (void)finishedCurrentEntity {
    // Fill with any elements polpulated during parse
    [self.currentEntity setTitle:self.currentTitle];
    [self.currentEntity setAuthor:self.currentAuthorName];
    [self.currentEntity setSummary:self.currentSummary];
    [self.currentEntity setEPubUrl:self.currentEPubUrl];
    [self.currentEntity setPdfUrl:self.currentPdfUrl];
    [self.currentEntity setCoverUrl:self.currentCoverUrl];
    [self.currentEntity setThumbUrl:self.currentThumbUrl];
    [self.currentEntity setReleasedDate:self.currentReleasedDate];
    [self.currentEntity setPublishedDate:self.currentPublishedDate];
    
    if (self.parsingFeed)
        [self performSelectorOnMainThread:@selector(parsedEntityInCollection:) withObject:self.currentEntity waitUntilDone:NO];
    else
        [self performSelectorOnMainThread:@selector(parsedEntity:) withObject:self.currentEntity waitUntilDone:NO];

    // performSelectorOnMainThread: will retain the object until the selector has been performed
    // setting the local reference to nil ensures that the local reference will be released
    self.currentEntity = nil;
    self.countOfParsedItems++;
    // Periodically purge the autorelease pool. The frequency of this action may need to be tuned according to the 
    // size of the objects being parsed. The goal is to keep the autorelease pool from growing too large, but 
    // taking this action too frequently would be wasteful and reduce performance.
    if (self.countOfParsedItems >= kBlioStoreFeedbooksParserAutoreleasePoolPurgeFrequency) {
        [downloadAndParsePool release];
        self.downloadAndParsePool = [[NSAutoreleasePool alloc] init];
        self.countOfParsedItems = 0;
    }
}

#pragma mark NSXMLParser Parsing Callbacks

// Constants for the XML element names that will be considered during the parse. 
static NSString *kBlioStoreFeedBooksParserName_Feed = @"feed";
static NSString *kBlioStoreFeedBooksParserName_Entry = @"entry";
static NSString *kBlioStoreFeedBooksParserName_Link = @"link";
static NSString *kBlioStoreFeedBooksParserName_Title = @"title";
static NSString *kBlioStoreFeedBooksParserName_Author = @"author";
static NSString *kBlioStoreFeedBooksParserName_Name = @"name";
static NSString *kBlioStoreFeedBooksParserName_PublishedDate = @"updated";
static NSString *kBlioStoreFeedBooksParserName_ReleasedDate = @"dcterms:issued";
static NSString *kBlioStoreFeedBooksParserName_Summary = @"summary";

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:kBlioStoreFeedBooksParserName_Feed]) {
        parsingFeed = YES;
    } else if ([elementName isEqualToString:kBlioStoreFeedBooksParserName_Entry]) {
        self.currentCategory = nil;
        parsingEntry = YES;
        if (!parsingFeed) {
            self.currentEntity = [[[BlioStoreParsedEntity alloc] init] autorelease];
        }
    } else if ([elementName isEqualToString:kBlioStoreFeedBooksParserName_Link] && !parsingEntry) {
        NSString *type = [attributeDict valueForKey:@"type"];
        NSString *rel = [attributeDict valueForKey:@"rel"];
        NSString *href = [attributeDict valueForKey:@"href"];
        if ([rel isEqualToString:@"self"] && [type isEqualToString:@"application/atom+xml"] && nil != href) {
            NSURL *feedURL = [NSURL URLWithString:href];
            NSString *basePath = [NSString stringWithFormat:@"%@://%@", [feedURL scheme], [feedURL host]];
            self.currentBaseURL = [NSURL URLWithString:basePath];
        }
    } else if ([elementName isEqualToString:kBlioStoreFeedBooksParserName_Link] && parsingEntry) {
        NSString *type = [attributeDict valueForKey:@"type"];
        NSString *rel = [attributeDict valueForKey:@"rel"];
        NSString *href = [attributeDict valueForKey:@"href"];
        if ([type isEqualToString:@"application/atom+xml"]) {
            if (nil != href) {
                self.currentCategory = [[[BlioStoreParsedCategory alloc] init] autorelease];
                NSURL *absoluteURL = [NSURL URLWithString:href relativeToURL:self.currentBaseURL];
                [self.currentCategory setUrl:absoluteURL];
            }
        } else if ([type isEqualToString:@"application/atom+xml;type=entry"]) {
            if (nil != href) {
                self.currentEntity = [[[BlioStoreParsedEntity alloc] init] autorelease];
                NSURL *absoluteURL = [NSURL URLWithString:href relativeToURL:self.currentBaseURL];
                [self.currentEntity setUrl:absoluteURL];
            }
        } else if ([rel isEqualToString:@"http://opds-spec.org/acquisition"] && parsingEntry && !parsingFeed && (nil != href)) {
            NSURL *absoluteURL = [NSURL URLWithString:href relativeToURL:self.currentBaseURL];
            if ([type isEqualToString:@"application/epub+zip"]) {
                self.currentEPubUrl = [absoluteURL absoluteString];
            } else if ([type isEqualToString:@"application/pdf"]) {
                self.currentPdfUrl = [absoluteURL absoluteString];
            }
        } else if ([type isEqualToString:@"image/png"] && parsingEntry && !parsingFeed && (nil != href)) {
            NSURL *absoluteURL = [NSURL URLWithString:href relativeToURL:self.currentBaseURL];
            if ([rel isEqualToString:@"http://opds-spec.org/cover"]) {
                self.currentCoverUrl = [absoluteURL absoluteString];
            } else if ([rel isEqualToString:@"http://opds-spec.org/thumbnail"]) {
                self.currentThumbUrl = [absoluteURL absoluteString];
            }
        }
    } else if ([elementName isEqualToString:kBlioStoreFeedBooksParserName_Author]) {
        parsingAuthor = YES;
    } else if (([elementName isEqualToString:kBlioStoreFeedBooksParserName_Title] && parsingEntry) ||
               ([elementName isEqualToString:kBlioStoreFeedBooksParserName_Name] && parsingAuthor) ||
               ([elementName isEqualToString:kBlioStoreFeedBooksParserName_PublishedDate] && !parsingFeed) ||
               ([elementName isEqualToString:kBlioStoreFeedBooksParserName_ReleasedDate] && !parsingFeed) ||
               ([elementName isEqualToString:kBlioStoreFeedBooksParserName_Summary] && !parsingFeed)) {
        
        storingCharacters = YES;
    }
    [self.currentString setString:@""];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:kBlioStoreFeedBooksParserName_Feed]) {
        parsingFeed = NO;
    } else if ([elementName isEqualToString:kBlioStoreFeedBooksParserName_Entry]) {
        if (nil != self.currentCategory) [self finishedCurrentCategory];
        if (nil != self.currentEntity) [self finishedCurrentEntity];
        parsingEntry = NO;
        [self clearElementProperties];
    } else if ([elementName isEqualToString:kBlioStoreFeedBooksParserName_Author]) {
        parsingAuthor = NO;
    } else if ([elementName isEqualToString:kBlioStoreFeedBooksParserName_Title]) {
        self.currentTitle = [NSString stringWithString:self.currentString];
    } else if ([elementName isEqualToString:kBlioStoreFeedBooksParserName_Name]) {
        self.currentAuthorName = [NSString stringWithString:self.currentString];
    } else if ([elementName isEqualToString:kBlioStoreFeedBooksParserName_Summary]) {
        self.currentSummary = [NSString stringWithString:self.currentString];
    } else if ([elementName isEqualToString:kBlioStoreFeedBooksParserName_ReleasedDate]) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy"];
        self.currentReleasedDate = [dateFormatter dateFromString:self.currentString];
        [dateFormatter release];
    } else if ([elementName isEqualToString:kBlioStoreFeedBooksParserName_PublishedDate]) {
        self.currentPublishedDate = [self.atomDateFormatter dateFromString:self.currentString];
    }
    storingCharacters = NO;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (storingCharacters) [self.currentString appendString:string];
}

/*
 A production application should include robust error handling as part of its parsing implementation.
 The specifics of how errors are handled depends on the application.
 */
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    // Handle errors as appropriate for your application.
}

@end
