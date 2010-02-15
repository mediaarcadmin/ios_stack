//
//  BlioStoreLocalParser.m
//  BlioApp
//
//  Created by matt on 12/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioStoreLocalParser.h"


@implementation BlioStoreLocalParser

- (void)volumeListFetchTicket:(GDataServiceTicket *)ticket finishedWithFeed:(GDataFeedVolume *)object error:(NSError *)error {
    // transfer the feed source to a property in the feed object
    if (error == nil) {
        NSURL *baseURL = [[[ticket objectFetcher] request] URL];
        // Workaround because stringByDeletingLastPathComponent turns file:// into file:/
        NSString *basePath = [[baseURL path] stringByDeletingLastPathComponent];
        
        for (GDataEntryBase *entry in [object entries]) {
            GDataLink *feedLink = [GDataLink linkWithRel:nil type:@"application/atom+xml" fromLinks:[entry links]];
            if (feedLink) {
                BlioStoreParsedCategory *aCategory = [[BlioStoreParsedCategory alloc] init];
                [aCategory setTitle:[[entry title] stringValue]];
                [aCategory setType:[entry identifier]];
                if ([[feedLink rel] isEqualToString:@"local"]) {
                    [aCategory setUrl:[NSURL fileURLWithPath:[basePath stringByAppendingPathComponent:[feedLink href]]]];
                } else {
                    NSURL *absoluteURL = [NSURL URLWithString:[feedLink href] relativeToURL:baseURL];
                    [aCategory setUrl:absoluteURL];
                }
                [self performSelectorOnMainThread:@selector(parsedCategory:) withObject:aCategory waitUntilDone:NO];
                [aCategory release];
            }
        }
        [self performSelectorOnMainThread:@selector(parseEnded) withObject:nil waitUntilDone:NO];
    }
}

@end
