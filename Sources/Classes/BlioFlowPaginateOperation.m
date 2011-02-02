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
#import <libEucalyptus/EucBookPaginator.h>

@interface BlioFlowPaginateOperation ()

@property (nonatomic, retain) EucBookPaginator *paginator;
@property (nonatomic, copy) NSString *bookTitle;
@property (nonatomic, assign) CFAbsoluteTime startTime;
@property (nonatomic, assign) BOOL bookCheckedOut;

@end

@implementation BlioFlowPaginateOperation

@synthesize paginator;
@synthesize bookTitle;
@synthesize startTime;
@synthesize bookCheckedOut;

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isExecuting {
    return executing;
}

- (BOOL)isFinished {
    return finished;
}

- (void)finish {
    if(bookCheckedOut) {
        [[BlioBookManager sharedBookManager] checkInEucBookForBookWithID:self.bookID];
    }
    [self reportBookReadingIfRequired];

    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    executing = NO;
    finished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];    
}


- (void)start 
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    // Must be performed on main thread
    // See http://www.dribin.org/dave/blog/archives/2009/05/05/concurrent_operations/
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        [pool drain];
        return;
    }
//	NSLog(@"BlioFlowPaginateOperation start entered: %@",self); 

	for (BlioProcessingOperation * blioOp in [self dependencies]) {
		if (!blioOp.operationSuccess) {
			NSLog(@"BlioFlowPaginateOperation: failed dependency found! op: %@",blioOp);
			[self cancel];
			break;
		}
	}
    if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
		NSLog(@"BlioFlowPaginateOperation cancelled, will prematurely abort start");
        [self didChangeValueForKey:@"isFinished"];
        [pool drain];
        return;
    }
    
	if (![self hasBookManifestValueForKey:BlioManifestTextFlowKey] && ![self hasBookManifestValueForKey:BlioManifestEPubKey]) {
		// no value means this is probably a free XPS; no need to continue, but no need to send a fail signal to dependent operations either.
		self.operationSuccess = YES;
		self.percentageComplete = 100;
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
		NSLog(@"No TextFlow data available, will end PaginateOperation without cancelling dependencies...");
        [self didChangeValueForKey:@"isFinished"];
		[pool drain];
		return;
	}
	
    
    [self willChangeValueForKey:@"isExecuting"];
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
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
    
    self.startTime = CFAbsoluteTimeGetCurrent();

    EucBUpeBook *eucBook = nil;
    // Create a EucBook for the paginator.
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
        
        self.bookTitle = book.title;
        
        NSLog(@"Paginating book %@", self.bookTitle);
        
        eucBook = [[[BlioBookManager sharedBookManager] checkOutEucBookForBookWithID:self.bookID] retain];
        if(eucBook) {
            [self setBookCheckedOut:YES];
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
		}
        
        [pool drain];
    }
    
    if([eucBook paginationIsComplete] || eucBook == nil) {
        // This book is already fully paginated!
		NSLog(@"This book is already fully paginated!");
        self.operationSuccess = YES;
		self.percentageComplete = 100;
        [self finish];
    } else {
        BOOL isDirectory = YES;
        NSString *cannedPaginationPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"PageIndexes"] stringByAppendingPathComponent:[[self getBookValueForKey:@"title"] stringByAppendingPathExtension:@"libEucalyptusPageIndexes"]];    
        if([[NSFileManager defaultManager] fileExistsAtPath:cannedPaginationPath isDirectory:&isDirectory] && isDirectory) {       
            NSLog(@"Using pre-canned indexes for %@", [self getBookValueForKey:@"title"]);
            
            [[NSFileManager defaultManager] copyItemAtPath:cannedPaginationPath
                                                    toPath:paginationPath 
                                                     error:NULL];
            self.operationSuccess = YES;
			self.percentageComplete = 100;
            [self finish];
        } else {
            // Create the directory to store the pagination data if necessary.
            if(![[NSFileManager defaultManager] fileExistsAtPath:paginationPath isDirectory:&isDirectory] || !isDirectory) {
                NSError *error = nil;
                if(![[NSFileManager defaultManager] createDirectoryAtPath:paginationPath withIntermediateDirectories:YES attributes:nil error:&error]) {
                    NSLog(@"Failed to create book cache directory in processing manager with error: %@, %@", error, [error userInfo]);
                }
            }            
            
            // Actually set up the pagination!
            paginator = [[EucBookPaginator alloc] init];
            
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(paginationComplete:)
                                                         name:EucBookPaginatorCompleteNotification
                                                       object:paginator];
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(paginationProgress:)
                                                         name:EucBookBookPaginatorProgressNotification
                                                       object:paginator];
                
            
            [paginator paginateBookInBackground:eucBook saveImagesTo:nil];
        }
    }
    
    [eucBook release];
    
    
    [pool drain];
}

- (void)paginationComplete:(NSNotification *)notification
{   
    if(![[self getBookValueForKey:@"layoutPageEquivalentCount"] integerValue]) {
        // If we don't have a layout page length yet (because we have no layout document)
        // calculate smething sensible so that the bars that show comparable lengths
        // of books in the UI can look 'right'.
        
        NSDictionary *pageCounts = [[notification userInfo] objectForKey:EucBookPaginatorNotificationPageCountForPointSizeKey];
        NSInteger pageCount = [[pageCounts objectForKey:[NSNumber numberWithInteger:18]] integerValue];
        NSInteger layoutEquivalentPageCount = (NSInteger)round((double)pageCount / 0.34);
        [self setBookValue:[NSNumber numberWithInteger:layoutEquivalentPageCount]
                    forKey:@"layoutPageEquivalentCount"];
        
//        NSLog(@"Using layout equivalent page length of %ld for %@", layoutEquivalentPageCount, [self getBookValueForKey:@"title"]); 
    }
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	UIApplication *application = [UIApplication sharedApplication];
	if([application respondsToSelector:@selector(endBackgroundTask:)]) {
		if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) [application endBackgroundTask:backgroundTaskIdentifier];	
	}				
#endif
	
    self.operationSuccess = YES;
    self.percentageComplete = 100;
        
    CFAbsoluteTime elapsedTime = CFAbsoluteTimeGetCurrent() - self.startTime;
    NSLog(@"Pagination of book %@ took %ld seconds", self.bookTitle, (long)round(elapsedTime));
    
    [self finish];
}

- (void)paginationProgress:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat percentagePaginated = [[userInfo objectForKey:EucBookPaginatorNotificationPercentagePaginatedKey] floatValue];
    if (self.percentageComplete != roundf(percentagePaginated)) {
		self.percentageComplete = roundf(percentagePaginated);
//		NSLog(@"Book %@ pagination progress: %u",self.bookTitle,self.percentageComplete);
	}
}
-(void)cancel {
	[super cancel];
	NSLog(@"Cancelling pagination...");
//	[paginator stop];
	[self performSelectorInBackground:@selector(stopPaginator) withObject:nil];
	[self finish];	
}
-(void)stopPaginator {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[paginator stop];
	[pool drain];
}
-(void) dealloc {
    self.bookTitle = nil;
	self.paginator = nil;
	[super dealloc];
}

@end
