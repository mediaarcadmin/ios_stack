//
//  BlioEPubPaginateOperation.m
//  BlioApp
//
//  Created by James Montgomerie on 17/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioFlowPaginateOperation.h"
#import "BlioProcessing.h"

#import "BlioBook.h"
#import "BlioBookManager.h"
#import "BlioFlowEucBook.h"
#import "BlioEPubBook.h"

#import <libEucalyptus/EucBUpeBook.h>


@implementation BlioFlowPaginateOperation

- (void)main
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	for (BlioProcessingOperation * blioOp in [self dependencies]) {
		if (!blioOp.operationSuccess) {
			NSLog(@"BlioFlowPaginateOperation: failed dependency found! op: %@",blioOp);
			[self cancel];
			break;
		}
	}
    
	if (![self hasBookManifestValueForKey:BlioManifestTextFlowKey] && ![self hasBookManifestValueForKey:BlioManifestEPubKey]) {
		// no value means this is probably a free XPS; no need to continue, but no need to send a fail signal to dependent operations either.
		self.operationSuccess = YES;
		self.percentageComplete = 100;
		NSLog(@"No TextFlow data available, will end PaginateOperation without cancelling dependencies...");
		[pool drain];
		return;
	}
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	UIApplication *application = [UIApplication sharedApplication];
	if([application respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)]) {
		self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:nil];
	}		
#endif
	
    NSString *paginationPath = [self.cacheDirectory stringByAppendingPathComponent:BlioBookEucalyptusCacheDir];

    if(self.forceReprocess) {
        // Best effort - ignore errors.
        [[NSFileManager defaultManager] removeItemAtPath:paginationPath error:NULL];
    }
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
        
    BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
    
    NSString *bookTitle = book.title;
    
    NSLog(@"Analysing book %@", bookTitle);
    
    EucBUpeBook *eucBook = nil;
    if([book hasEPub]) {
        eucBook = [[BlioEPubBook alloc] initWithBookID:self.bookID];
    } else if([book hasTextFlow]) {
        eucBook = [[BlioFlowEucBook alloc] initWithBookID:self.bookID];
    }
    if(eucBook) {
        if (![self hasBookManifestValueForKey:BlioManifestCoverKey]) {
            NSURL *coverURL = eucBook.coverURL;
            if(coverURL) {
                NSLog(@"eucBook.coverURL: %@",coverURL);
                NSData *coverData = [eucBook dataForURL:coverURL];
                if(coverData) {
                    [coverData writeToFile:[self.cacheDirectory stringByAppendingPathComponent:BlioManifestCoverKey] atomically:NO];
                
                    NSDictionary *manifestEntry = [NSMutableDictionary dictionary];
                    [manifestEntry setValue:BlioManifestEntryLocationFileSystem forKey:BlioManifestEntryLocationKey];
                    [manifestEntry setValue:BlioManifestCoverKey forKey:BlioManifestEntryPathKey];
                    [self setBookManifestValue:manifestEntry forKey:BlioManifestCoverKey];
                    NSMutableDictionary * noteInfo = [NSMutableDictionary dictionaryWithCapacity:1];
                    [noteInfo setObject:self.bookID forKey:@"bookID"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingReprocessCoverThumbnailNotification object:self userInfo:noteInfo];
                } else {
                    NSLog(@"Couldn't get data for cover in book.");
                }
            }
        }
        
        [eucBook release];
    }
    
    NSLog(@"Analysing book %@, took %f seconds", bookTitle, CFAbsoluteTimeGetCurrent() - startTime);

	self.percentageComplete = 100;    
	self.operationSuccess = YES;    
    
    [pool drain];
}

@end
