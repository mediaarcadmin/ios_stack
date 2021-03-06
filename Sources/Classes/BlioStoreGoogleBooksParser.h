//
//  BlioStoreGoogleBooksParser.h
//  BlioApp
//
//  Created by matt on 12/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlioStoreBooksSourceParser.h"

@interface BlioStoreGoogleBooksParser : BlioStoreBooksSourceParser {
	NSMutableArray * entryServiceTickets;
}
@property (nonatomic, retain) NSMutableArray * entryServiceTickets;

- (void)parseEntry:(GDataEntryBase *)entry withBaseURL:(NSURL *)baseURL;
@end