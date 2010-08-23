//
//  BlioStoreGoogleBooksParser.m
//  BlioApp
//
//  Created by matt on 12/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioStoreGoogleBooksParser.h"
#import "BlioBook.h"
#import "BlioAlertManager.h"

@implementation BlioStoreGoogleBooksParser

@synthesize entryServiceTickets;

- (void)startWithURL:(NSURL *)url {
    if (nil == url) return;
    isParsing = YES;
    self.parsedCategories = [NSMutableArray array];
    self.parsedEntities = [NSMutableArray array];
    
    GDataQueryBooks *query = [GDataQueryBooks booksQueryWithFeedURL:url];
    if ([[url absoluteString] rangeOfString:@"min-viewability=full"].location == NSNotFound) [query setMinimumViewability:kGDataGoogleBooksMinViewabilityFull];
    
    self.serviceTicket = [self.service fetchFeedWithQuery:query
                            delegate:self
                   didFinishSelector:@selector(volumeListFetchTicket:finishedWithFeed:error:)];
    

}
-(void) dealloc {
	[self cancel];
	self.entryServiceTickets = nil;
	[super dealloc];
}
- (void)volumeListFetchTicket:(GDataServiceTicket *)ticket finishedWithFeed:(GDataFeedVolume *)object error:(NSError *)error {
//    NSLog(@"BlioStoreGoogleBooksParser volumeFetchTicket:finishedWithFeed: entered");
    if (error == nil) {
        self.entryServiceTickets = [NSMutableArray array];
		[self.delegate parser:self didParseTotalResults:[object totalResults]]; // pass over the total results number to the BlioStoreCategoriesController, so that it can assign the number to the respective feed.
		// if nextLink is not nil, then send it back to the delegate in NSURL form
		if ([object nextLink] != nil) [self.delegate parser:self didParseNextLink:[[object nextLink] URL]];
		if ([object identifier] != nil) [self.delegate parser:self didParseIdentifier:[object identifier]];
	
		for (GDataEntryBase *entry in [object entries]) {
            NSURL *idUrl = [NSURL URLWithString:[entry identifier]];
            if (nil != idUrl) {
                GDataQueryBooks *query = [GDataQueryBooks booksQueryWithFeedURL:idUrl];            
                [entryServiceTickets addObject:[self.service fetchFeedWithQuery:query
                                        delegate:self
                               didFinishSelector:@selector(volumeFetchTicket:finishedWithVolume:error:)]];
            }
        }
    }
	else {
		NSLog(@"ERROR: BlioStoreGoogleBooksParser (feed): %@, %@",error,[error userInfo]);
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"We're Sorry...",@"\"We're Sorry...\" alert message title") 
									 message:[[error userInfo] objectForKey:NSLocalizedDescriptionKey]
									delegate:self 
						   cancelButtonTitle:@"OK"
						   otherButtonTitles:nil];		
		[self performSelectorOnMainThread:@selector(parseEnded) withObject:nil waitUntilDone:NO];
	}

}

- (void)volumeFetchTicket:(GDataServiceTicket *)ticket finishedWithVolume:(GDataEntryVolume *)object error:(NSError *)error {
//    NSLog(@"BlioStoreGoogleBooksParser volumeFetchTicket:%@ finishedWithVolume:%@ error:%@ entered",ticket,object,error);
    // transfer the feed source to a property in the feed object
	if ([entryServiceTickets containsObject:ticket]) {
		[entryServiceTickets removeObject:ticket];
	}
	else {
		NSLog(@"ERROR: finished entry service ticket that is not our our entryServiceTicket array!");
	}
    if (error == nil) {
        GDataLink *selfLink = [object selfLink];
        NSURL *baseURL = selfLink ? [NSURL URLWithString:[selfLink href]] : nil;
        
        [self parseEntry:object withBaseURL:baseURL];
    }
	else NSLog(@"ERROR: BlioStoreGoogleBooksParser (entry): %@, %@",error,[error userInfo]);

//	NSLog(@"[entryServiceTickets count]: %i",[entryServiceTickets count]);
	if ([entryServiceTickets count] == 0) [self performSelectorOnMainThread:@selector(parseEnded) withObject:nil waitUntilDone:NO];
}

- (void)parseEntry:(GDataEntryVolume *)entry withBaseURL:(NSURL *)baseURL {
    GDataLink *bookLink = [GDataLink linkWithRel:nil type:@"application/atom+xml" fromLinks:[entry links]];

    if (bookLink) {
        BlioStoreParsedEntity *aEntity = [[BlioStoreParsedEntity alloc] init];
        [aEntity setTitle:[[entry title] stringValue]];
        NSURL *absoluteURL = [NSURL URLWithString:[bookLink href] relativeToURL:baseURL];
        [aEntity setUrl:absoluteURL];
        NSMutableString* descriptions = nil;
        for (GDataDCFormat *desc in [entry volumeDescriptions]) {
            if (nil == descriptions) {
                descriptions = [NSMutableString stringWithString:[desc stringValue]];
            } else {
                [descriptions appendString:[NSString stringWithFormat:@"\n\n%@", [desc stringValue]]];
            }
        }
		aEntity.id = [entry identifier];
		[aEntity setSummary:descriptions];
		NSMutableArray * authorsArray = [NSMutableArray arrayWithCapacity:[[entry creators] count]];
		for (GDataDCCreator * creator in [entry creators]) {
			[authorsArray addObject:[BlioBook canonicalNameFromStandardName:[creator stringValue]]];
		}
		
        [aEntity setAuthors:authorsArray];
        [aEntity setEPubUrl:[[entry EPubDownloadLink] href]];
		
		NSString * modifiedCoverUrl = [[entry thumbnailLink] href];
		modifiedCoverUrl = [modifiedCoverUrl stringByReplacingOccurrencesOfString:@"zoom=" withString:@"zoom=9"];
		modifiedCoverUrl = [modifiedCoverUrl stringByReplacingOccurrencesOfString:@"edge=curl" withString:@"edge=plain"];
		
        [aEntity setCoverUrl:modifiedCoverUrl];
		
		NSString * modifiedThumbUrl = [[entry thumbnailLink] href];
		modifiedThumbUrl = [modifiedCoverUrl stringByReplacingOccurrencesOfString:@"edge=curl" withString:@"edge=plain"];
		
        [aEntity setThumbUrl:modifiedThumbUrl];                             
        [aEntity setPublishedDate:[[entry updatedDate] date]];
        [aEntity setReleasedDate:[[[[entry dates] lastObject] dateTimeValue] date]];
        [aEntity setPublisher:[[[entry publishers] lastObject] stringValue]];
        NSString *pageCount = nil;
        for (GDataDCFormat *format in [entry formats]) {
            NSString *formatString = [format stringValue];
            NSScanner *pageScanner = [NSScanner scannerWithString:formatString];
            NSInteger anInteger = -1;
            [pageScanner scanInteger:&anInteger];
            if (anInteger > 0) pageCount = [[NSNumber numberWithInteger:anInteger] stringValue];
        }
        [aEntity setPageCount:pageCount];
        [self performSelectorOnMainThread:@selector(parsedEntity:) withObject:aEntity waitUntilDone:NO];
        [aEntity release];
    }    
}

- (NSURL *)queryUrlForString:(NSString *)queryString {
    NSURL *feedURL = [NSURL URLWithString:kGDataGoogleBooksVolumeFeed];
    GDataQueryBooks *booksQuery = [GDataQueryBooks booksQueryWithFeedURL:feedURL];
    [booksQuery setFullTextQueryString:queryString];
    return [booksQuery URL];
}
-(void)cancel {
	if (self.entryServiceTickets) {
		for (GDataServiceTicket * ticket in self.entryServiceTickets) {
			[ticket cancelTicket];
		}
	}
	if (self.serviceTicket) [self.serviceTicket cancelTicket];
}

@end