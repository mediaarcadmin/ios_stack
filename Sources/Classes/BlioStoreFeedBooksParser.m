//
//  BlioStoreFeedBooksParser.m
//  BlioApp
//
//  Created by matt on 11/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioStoreFeedBooksParser.h"
#import "BlioBook.h"
#import "BlioAlertManager.h"

@implementation BlioStoreFeedBooksParser


- (void)volumeListFetchTicket:(GDataServiceTicket *)ticket finishedWithFeed:(GDataFeedVolume *)object error:(NSError *)error {
    
    // transfer the feed source to a property in the feed object
    if (error == nil) {
		[self.delegate parser:self didParseTotalResults:[object totalResults]]; // pass over the total results number to the BlioStoreCategoriesController, so that it can assign the number to the respective feed.
		// if nextLink is not nil, then send it back to the delegate in NSURL form
		if ([object nextLink] != nil) [self.delegate parser:self didParseNextLink:[[object nextLink] URL]];
		if ([object identifier] != nil) [self.delegate parser:self didParseIdentifier:[object identifier]];

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
                aEntity.id = [entry identifier];
                [aEntity setSummary:[[entry summary] stringValue]];
				NSMutableArray * authorsArray = [NSMutableArray arrayWithCapacity:[[entry authors] count]];
				for (GDataPerson * person in [entry authors]) {
					[authorsArray addObject:[BlioBook canonicalNameFromStandardName:[person name]]];
				}
                [aEntity setAuthors:authorsArray];
                [aEntity setEPubUrl:[[GDataLink linkWithRel:@"http://opds-spec.org/acquisition" type:@"application/epub+zip" fromLinks:[entry links]] href]];
                [aEntity setPdfUrl:[[GDataLink linkWithRel:@"http://opds-spec.org/acquisition" type:@"application/pdf" fromLinks:[entry links]] href]];
                [aEntity setCoverUrl:[[GDataLink linkWithRel:@"http://opds-spec.org/cover" type:@"image/png" fromLinks:[entry links]] href]];
				if (aEntity.coverUrl == nil) [aEntity setCoverUrl:[[GDataLink linkWithRel:@"http://opds-spec.org/cover" type:nil fromLinks:[entry links]] href]];
                [aEntity setThumbUrl:[[GDataLink linkWithRel:@"http://opds-spec.org/thumbnail" type:@"image/png" fromLinks:[entry links]] href]];                             
				if (aEntity.thumbUrl == nil) [aEntity setThumbUrl:[[GDataLink linkWithRel:@"http://opds-spec.org/thumbnail" type:nil fromLinks:[entry links]] href]];
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
	else {
		NSLog(@"ERROR: BlioStoreFeedBooksParser: %@, %@",error,[error userInfo]);
		[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"We're Sorry...",@"\"We're Sorry...\" alert message title") 
									 message:[[error userInfo] objectForKey:NSLocalizedDescriptionKey] ? [[error userInfo] objectForKey:NSLocalizedDescriptionKey] : NSLocalizedStringWithDefaultValue(@"ERROR_WHILE_PARSING_FEED",nil,[NSBundle mainBundle],@"An error occurred while reading this feed. Please try again later.",@"Alert message shown to end-user when parsing of a Get Books feed fails.")
									delegate:self 
						   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
						   otherButtonTitles:nil];				
		[self performSelectorOnMainThread:@selector(parseEnded) withObject:nil waitUntilDone:NO];
	}
}

- (NSURL *)queryUrlForString:(NSString *)queryString {
    NSURL *queryURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.feedbooks.com/books/search.atom?query=%@", [queryString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    return queryURL;
}

@end
