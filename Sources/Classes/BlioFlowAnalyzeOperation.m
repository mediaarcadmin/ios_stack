//
//  BlioEPubAnalyzeOperation.m
//  BlioApp
//
//  Created by James Montgomerie on 17/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioFlowAnalyzeOperation.h"
#import "BlioProcessing.h"

#import "BlioBook.h"
#import "BlioBookManager.h"
#import "BlioFlowEucBook.h"
#import "BlioEPubBook.h"

#import <libEucalyptus/EucBUpeBook.h>


@implementation BlioFlowAnalyzeOperation

- (void)main
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	for (BlioProcessingOperation * blioOp in [self dependencies]) {
		if (!blioOp.operationSuccess) {
			NSLog(@"BlioFlowAnalyzeOperation: failed dependency found! op: %@",blioOp);
			[self cancel];
			break;
		}
	}
    
	if (![self hasBookManifestValueForKey:BlioManifestTextFlowKey] && ![self hasBookManifestValueForKey:BlioManifestEPubKey]) {
		// no value means this is probably a free XPS; no need to continue, but no need to send a fail signal to dependent operations either.
		self.operationSuccess = YES;
		self.percentageComplete = 100;
		NSLog(@"No TextFlow or ePub available, will end BlioFlowAnalyzeOperation without cancelling dependencies...");
		[pool drain];
		return;
	}
	
	UIApplication *application = [UIApplication sharedApplication];
	if([application respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)]) {
		self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:nil];
	}		
	
    NSString *cachePath = [self.cacheDirectory stringByAppendingPathComponent:BlioBookEucalyptusCacheDir];

    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if(self.forceReprocess) {
        NSError *error = nil;
        [fileManager removeItemAtPath:cachePath error:&error];
        if(error) {
            NSLog(@"Warning: Could not remove old book metadata at %@ - error %@", cachePath, error);
        }
    }
    
    NSError *error = nil;
    if(![fileManager createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:&error]) {
        self.percentageComplete = 100;
        self.operationSuccess = NO;
        NSLog(@"Warning: Could not create book cache directory at %@ - error %@ - abandoning.", cachePath, error);
    } else {        
        CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
            
        BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
        
        NSLog(@"Analysing book %@", book.title);
        
        EucBUpeBook *eucBook = [[BlioBookManager sharedBookManager] checkOutEucBookForBookWithID:self.bookID];
        if(eucBook) {
            [eucBook generateAndCacheUncachedRecachableData];
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
            
            [[BlioBookManager sharedBookManager] checkInEucBookForBookWithID:self.bookID];
        }
        
        NSLog(@"Analysing book %@, took %f seconds", book.title, CFAbsoluteTimeGetCurrent() - startTime);

        self.percentageComplete = 100;    
        self.operationSuccess = YES;    
    }
    
    [fileManager release];
    
    if([application respondsToSelector:@selector(endBackgroundTask:)]) {
		if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) [application endBackgroundTask:backgroundTaskIdentifier];	
	}			
    
    [pool drain];
}

@end
