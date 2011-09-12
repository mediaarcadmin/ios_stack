//
//  BlioTextFlowPreParseOperation.m
//  Scholastic
//
//  Created by Gordon Christie on 29/03/2011.
//  Copyright 2011 BitWink. All rights reserved.
//

#import "BlioTextFlowPreParseOperation.h"
#import "BlioTextFlowPageRange.h"
#import "BlioTextFlowPageMarker.h"
#import "BlioBook.h"
#import <expat/expat.h>

#pragma mark -
@implementation BlioTextFlowPreParseOperation

static void pageRangeFileXMLParsingStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts)  {
    
    NSMutableArray *pageRangesArray = (NSMutableArray *)ctx;
    
    if(strcmp("PageRange", name) == 0) {
        BlioTextFlowPageRange *aPageRange = [[BlioTextFlowPageRange alloc] init];
        
        for(int i = 0; atts[i]; i+=2) {
            if (strcmp("Start", atts[i]) == 0) {
                [aPageRange setStartPageIndex:atoi(atts[i+1])];
            } else if (strcmp("End", atts[i]) == 0) {
                [aPageRange setEndPageIndex:atoi(atts[i+1])];
            } else if (strcmp("Source", atts[i]) == 0) {
                NSString *sourceString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != sourceString) {
                    // Write the filename directly but set up the manifest entries once we have completed parsing
                    [aPageRange setFileName:sourceString];
                    [sourceString release];
                }
            }
        }
        
        if (nil != aPageRange) {
            [pageRangesArray addObject:aPageRange];
            [aPageRange release];
        }
    }
    
}

static void pageFileXMLParsingStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts)  {
    
    BlioTextFlowPageRange *pageRange = (BlioTextFlowPageRange *)ctx;
    NSInteger newPageIndex = -1;
    
    if(strcmp("Page", name) == 0) {
        
        NSUInteger currentByteIndex = (NSUInteger)(XML_GetCurrentByteIndex(*[pageRange currentParser]));
        
        for(int i = 0; atts[i]; i+=2) {
            if (strcmp("PageIndex", atts[i]) == 0) {
                NSString *pageIndexString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != pageIndexString) {
                    newPageIndex = [pageIndexString integerValue];
                    [pageIndexString release];
                }
            } 
        }
        
        if ((newPageIndex >= 0) && (newPageIndex != [pageRange currentPageIndex])) {
            BlioTextFlowPageMarker *newPageMarker = [[BlioTextFlowPageMarker alloc] init];
            [newPageMarker setPageIndex:newPageIndex];
            [newPageMarker setByteIndex:currentByteIndex];
            [pageRange.pageMarkers addObject:newPageMarker];
            [newPageMarker release];
            [pageRange setCurrentPageIndex:newPageIndex];
        }
    }
    
}

- (void)main {
    // NSLog(@"BlioTextFlowPreParseOperation main entered");
	for (BlioProcessingOperation * blioOp in [self dependencies]) {
		if (!blioOp.operationSuccess) {
			NSLog(@"BlioTextFlowPreParseOperation: failed dependency found! op: %@",blioOp);
			[self cancel];
			break;
		}
	}	
    if ([self isCancelled]) {
		NSLog(@"BlioTextFlowPreParseOperation cancelled, will prematurely abort start");	
		return;
	}
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	if (![self hasBookManifestValueForKey:BlioManifestTextFlowKey]) {
		// no value means this is probably a free XPS; no need to continue, but no need to send a fail signal to dependent operations either.
		self.operationSuccess = YES;
		self.percentageComplete = 100;
        [self reportBookReadingIfRequired];
		[pool drain];
		return;
	}
	
    NSData *data = [self getBookManifestDataForKey:BlioManifestTextFlowKey];
    
    if (nil == data) {
        //NSLog(@"Could not create TextFlow data file.");
        NSLog(@"Could not pre-parse TextFlow because TextFlow file did not exist at path: %@.", [self getBookManifestPathForKey:BlioManifestTextFlowKey]);
		self.operationSuccess = NO;
        [self reportBookReadingIfRequired];
        [pool drain];
        return;
    }
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	UIApplication *application = [UIApplication sharedApplication];
	if([application respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)]) {
		self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:nil];
	}		
#endif
	
    NSMutableSet *pageRangesSet = [NSMutableSet set];
    
    // Parse pageRange file
    XML_Parser pageRangeFileParser = XML_ParserCreate(NULL);
    
    XML_SetStartElementHandler(pageRangeFileParser, pageRangeFileXMLParsingStartElementHandler);
    
    XML_SetUserData(pageRangeFileParser, (void *)pageRangesSet);    
    if (!XML_Parse(pageRangeFileParser, [data bytes], [data length], XML_TRUE)) {
        char *anError = (char *)XML_ErrorString(XML_GetErrorCode(pageRangeFileParser));
        NSLog(@"TextFlow parsing error: '%s' in file: '%@'", anError, [self getBookManifestPathForKey:BlioManifestTextFlowKey]);
    }
    XML_ParserFree(pageRangeFileParser);
    //[data release];
    //    [pool drain];
    //    pool = [[NSAutoreleasePool alloc] init];
    
    for (BlioTextFlowPageRange *pageRange in pageRangesSet) {
        //        NSDictionary *manifestEntry = [NSMutableDictionary dictionary];
        //        [manifestEntry setValue:@"textflow" forKey:BlioManifestEntryLocationKey];
        //        [manifestEntry setValue:[pageRange fileName] forKey:BlioManifestEntryPathKey];
        //        [self setBookManifestValue:manifestEntry forKey:[pageRange fileName]];
        
        NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
        //NSData *data = [self getBookManifestDataForKey:[pageRange fileName]];
        NSData *data = [self getBookTextFlowDataWithPath:[pageRange fileName]];
        
        if (!data) {
            NSLog(@"Could not pre-parse TextFlow because TextFlow file did not exist with name: %@.", [pageRange fileName]);
			self.operationSuccess = NO;
            [self reportBookReadingIfRequired];
            [pool drain];
            return;
        }
        
        XML_Parser flowParser = XML_ParserCreate(NULL);
        XML_SetStartElementHandler(flowParser, pageFileXMLParsingStartElementHandler);
        
        pageRange.currentPageIndex = -1;
        pageRange.currentParser = &flowParser;
        XML_SetUserData(flowParser, (void *)pageRange);    
        if (!XML_Parse(flowParser, [data bytes], [data length], XML_TRUE)) {
            char *anError = (char *)XML_ErrorString(XML_GetErrorCode(flowParser));
            NSLog(@"TextFlow parsing error: '%s' in file: '%@'", anError, [pageRange fileName]);
        }
        XML_ParserFree(flowParser);   
        
        [innerPool drain];
    }
    
    [self setBookValue:[NSSet setWithSet:pageRangesSet] forKey:@"textFlowPageRanges"];
    
    NSSortDescriptor *sortPageDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"startPageIndex" ascending:YES] autorelease];
    NSArray *sortedRanges = [[pageRangesSet allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortPageDescriptor]];
    [self setBookValue:[NSNumber numberWithInteger:[[sortedRanges lastObject] endPageIndex]]
                forKey:@"layoutPageEquivalentCount"];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	if([application respondsToSelector:@selector(endBackgroundTask:)]) {
        //		NSLog(@"ending background task...");
		if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) [application endBackgroundTask:backgroundTaskIdentifier];	
	}		
#endif	
    self.operationSuccess = YES;
	self.percentageComplete = 100;
    
    [self reportBookReadingIfRequired];
    [pool drain];
}


@end
