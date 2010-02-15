//
//  BlioStoreGoogleBooksParser.m
//  BlioApp
//
//  Created by matt on 12/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioStoreGoogleBooksParser.h"

@implementation BlioStoreGoogleBooksParser

- (void)startWithURL:(NSURL *)url {
    if (nil == url) return;
    
    self.parsedCategories = [NSMutableArray array];
    self.parsedEntities = [NSMutableArray array];
    
    GDataQueryBooks *query = [GDataQueryBooks booksQueryWithFeedURL:url];
    [query setMinimumViewability:kGDataGoogleBooksMinViewabilityFull];
    
    [self.service fetchFeedWithQuery:query
                            delegate:self
                   didFinishSelector:@selector(volumeListFetchTicket:finishedWithFeed:error:)];
    

}

- (void)volumeListFetchTicket:(GDataServiceTicket *)ticket finishedWithFeed:(GDataFeedVolume *)object error:(NSError *)error {
    
    if (error == nil) {        
        for (GDataEntryBase *entry in [object entries]) {
            NSURL *idUrl = [NSURL URLWithString:[entry identifier]];
            if (nil != idUrl) {
                GDataQueryBooks *query = [GDataQueryBooks booksQueryWithFeedURL:idUrl];            
                [self.service fetchFeedWithQuery:query
                                        delegate:self
                               didFinishSelector:@selector(volumeFetchTicket:finishedWithVolume:error:)];
            }
        }
    }
}

- (void)volumeFetchTicket:(GDataServiceTicket *)ticket finishedWithVolume:(GDataEntryVolume *)object error:(NSError *)error {
    
    // transfer the feed source to a property in the feed object
    if (error == nil) {
        GDataLink *selfLink = [object selfLink];
        NSURL *baseURL = selfLink ? [NSURL URLWithString:[selfLink href]] : nil;
        
        [self parseEntry:object withBaseURL:baseURL];   
        [self performSelectorOnMainThread:@selector(parseEnded) withObject:nil waitUntilDone:NO];
    }
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
        [aEntity setSummary:descriptions];
        [aEntity setAuthor:[[[entry creators] lastObject] stringValue]];
        [aEntity setEPubUrl:[[entry EPubDownloadLink] href]];
        [aEntity setCoverUrl:[[entry thumbnailLink] href]];
        [aEntity setThumbUrl:[[entry thumbnailLink] href]];                             
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

@end