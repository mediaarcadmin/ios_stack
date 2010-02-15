//
//  BlioStoreFeedBooksParser.m
//  BlioApp
//
//  Created by matt on 11/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioStoreFeedBooksParser.h"


@implementation BlioStoreFeedBooksParser


- (void)volumeListFetchTicket:(GDataServiceTicket *)ticket finishedWithFeed:(GDataFeedVolume *)object error:(NSError *)error {
    
    // transfer the feed source to a property in the feed object
    if (error == nil) {
        GDataLink *selfLink = [object selfLink];
        NSURL *baseURL = selfLink ? [NSURL URLWithString:[selfLink href]] : nil;
        
        for (GDataEntryBase *entry in [object entries]) {
            GDataLink *feedLink = [GDataLink linkWithRel:nil type:@"application/atom+xml" fromLinks:[entry links]];
            GDataLink *bookLink = [GDataLink linkWithRel:nil type:@"application/atom+xml;type=entry" fromLinks:[entry links]];
            if (feedLink) {
                BlioStoreParsedCategory *aCategory = [[BlioStoreParsedCategory alloc] init];
                [aCategory setTitle:[[entry title] stringValue]];
                NSURL *absoluteURL = [NSURL URLWithString:[feedLink href] relativeToURL:baseURL];
                [aCategory setUrl:absoluteURL];
                [self performSelectorOnMainThread:@selector(parsedCategory:) withObject:aCategory waitUntilDone:NO];
                [aCategory release];
            } else if (bookLink) {
                BlioStoreParsedEntity *aEntity = [[BlioStoreParsedEntity alloc] init];
                [aEntity setTitle:[[entry title] stringValue]];
                NSURL *absoluteURL = [NSURL URLWithString:[bookLink href] relativeToURL:baseURL];
                [aEntity setUrl:absoluteURL];
                [aEntity setSummary:[[entry summary] stringValue]];
                [aEntity setAuthor:[[[entry authors] lastObject] name]];
                [aEntity setEPubUrl:[[GDataLink linkWithRel:@"http://opds-spec.org/acquisition" type:@"application/epub+zip" fromLinks:[entry links]] href]];
                [aEntity setPdfUrl:[[GDataLink linkWithRel:@"http://opds-spec.org/acquisition" type:@"application/pdf" fromLinks:[entry links]] href]];
                [aEntity setCoverUrl:[[GDataLink linkWithRel:@"http://opds-spec.org/cover" type:@"image/png" fromLinks:[entry links]] href]];
                [aEntity setThumbUrl:[[GDataLink linkWithRel:@"http://opds-spec.org/thumbnail" type:@"image/png" fromLinks:[entry links]] href]];                             
                [aEntity setPublishedDate:[[entry updatedDate] date]];
                
                // Ideally this would be handled by a GDataEntryBase subclass instead of like this
                for (GDataXMLElement *node in [entry unknownChildren]) {
                    if ([[node name] isEqualToString:@"dcterms:issued"]) {                        
                        NSString *issuedString = [node stringValue];
                        if (nil != issuedString) {
                            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                            [dateFormatter setDateFormat:@"yyyy"];
                            [aEntity setReleasedDate:[dateFormatter dateFromString:issuedString]];
                            [dateFormatter release];
                        }
                    }
                }
                [self performSelectorOnMainThread:@selector(parsedEntity:) withObject:aEntity waitUntilDone:NO];
                [aEntity release];
            }
            
        }
        [self performSelectorOnMainThread:@selector(parseEnded) withObject:nil waitUntilDone:NO];
    }
}

- (NSURL *)queryUrlForString:(NSString *)queryString {
    NSURL *queryURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.feedbooks.com/books/search.atom?query=%@", [queryString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    return queryURL;
}

@end
