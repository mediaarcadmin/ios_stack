//
//  BlioStoreGoogleBooksParser.m
//  BlioApp
//
//  Created by matt on 11/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioStoreBooksSourceParser.h"

// tags for viewability pop-up
const int kAnyViewability = 0;     // any amount or none is viewable
const int kPartialViewability = 1; // some is viewable
const int kFullViewability = 2;    // entire book must be viewable

static NSUInteger kBlioStoreParserCountForNotification = 0;

@implementation BlioStoreBooksSourceParser

@synthesize delegate;
@synthesize service;
@synthesize serviceTicket;
@synthesize parsedCategories, parsedEntities;

- (void)dealloc {
	[self cancel];
    self.delegate = nil;
    [self.service clearLastModifiedDates];
    self.service = nil;  
    self.serviceTicket = nil;  
    self.parsedCategories = nil;
    self.parsedEntities = nil;
    [super dealloc];
}

- (id)init {
    if ((self = [super init])) {
        
        GDataServiceGoogleBooks *aService = [[GDataServiceGoogleBooks alloc] init];
        
        [aService setUserAgent:@"NOTYETDISCLOSED-NOTYETDISCLOSED-1.0"]; // set this to yourName-appName-appVersion
        [aService setShouldCacheDatedData:YES];
        [aService setServiceShouldFollowNextLinks:NO];
        //[aService setShouldServiceFeedsIgnoreUnknowns:YES]; // cannot use ths because we have unknown elements
        self.service = aService;
        [aService release];
        isParsing = NO;
    }
    return self;
}

- (void)startWithURL:(NSURL *)url {
    if (nil == url) return;
//    NSLog(@"BlioStoreBooksSourceParser startWithURL: %@", [url absoluteString]);
	isParsing = YES;
	self.parsedCategories = [NSMutableArray array];
    self.parsedEntities = [NSMutableArray array];
    
    self.serviceTicket = [self.service fetchFeedWithURL:url
                          delegate:self
                 didFinishSelector:@selector(volumeListFetchTicket:finishedWithFeed:error:)];
}

- (void)parsedCategory:(BlioStoreParsedCategory *)category {
    NSAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
    
    [self.parsedCategories addObject:category];
    if (self.parsedCategories.count > kBlioStoreParserCountForNotification) {
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parser:didParseCategories:)]) {
            [self.delegate parser:self didParseCategories:self.parsedCategories];
        }
        [self.parsedCategories removeAllObjects];
    }
}

- (void)parsedEntity:(BlioStoreParsedEntity *)entity {
    NSAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
	if (![entity ePubUrl] && ![entity pdfUrl]) {
		NSLog(@"Encountered entry with neither ePubUrl nor pdfUrl; ignoring...");
	}
	else {
		[self.parsedEntities addObject:entity];
		if (self.parsedEntities.count > kBlioStoreParserCountForNotification) {
			if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parser:didParseEntities:)]) {
				[self.delegate parser:self didParseEntities:self.parsedEntities];
			}
			[self.parsedEntities removeAllObjects];
		}
	}
}

- (void)parseEnded {
    NSAssert2([NSThread isMainThread], @"%s at line %d called on secondary thread", __FUNCTION__, __LINE__);
	isParsing = NO;
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parser:didParseCategories:)] && [parsedCategories count] > 0) {
        [self.delegate parser:self didParseCategories:parsedCategories];
    }
    [self.parsedCategories removeAllObjects];
    
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parser:didParseEntities:)] && [parsedEntities count] > 0) {
        [self.delegate parser:self didParseEntities:parsedEntities];
    }
    [self.parsedEntities removeAllObjects];
    
	// TODO: initiate another connection if valid results are not enough.

    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parserDidEndParsingData:)]) {
        [self.delegate parserDidEndParsingData:self];
    }
}

- (void)volumeListFetchTicket:(GDataServiceTicket *)ticket finishedWithFeed:(GDataFeedVolume *)object error:(NSError *)error {
    NSAssert([self isMemberOfClass:[BlioStoreBooksSourceParser class]] == NO, @"Object is of abstract base class BlioStoreBooksSourceParser");
}

- (NSURL *)queryUrlForString:(NSString *)queryString {
    return nil;
}
-(BOOL)isParsing {
	return isParsing;
}
-(void)cancel {
	if (self.serviceTicket) [self.serviceTicket cancelTicket];
}
@end

@implementation BlioStoreParsedCategory

@synthesize title, url, type;

- (void)dealloc {
    self.title = nil;
    self.url = nil;
    self.type = nil;
    [super dealloc];
}

- (Class)classForType {
    Class klass = nil;
    if (nil != self.type) klass = NSClassFromString(self.type);
    return klass;
}

@end

@implementation BlioStoreParsedEntity

@synthesize title, authors, url, summary, ePubUrl, pdfUrl, coverUrl, thumbUrl, releasedDate, publishedDate, publisher, pageCount,id;

- (void)dealloc {
    self.title = nil;
    self.id = nil;
    self.authors = nil;
    self.url = nil;
    self.summary = nil;
    self.ePubUrl = nil;
    self.pdfUrl = nil;
    self.coverUrl = nil;
    self.thumbUrl = nil;
    self.releasedDate = nil;
    self.publishedDate = nil;
    self.publisher = nil;
    self.pageCount = nil;
    [super dealloc];
}

@end
