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

@implementation BlioFlowPaginateOperation

@synthesize paginator;

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
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    executing = NO;
    finished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}


- (void)start 
{
//	NSLog(@"BlioFlowPaginateOperation start entered"); 

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    // Must be performed on main thread
    // See http://www.dribin.org/dave/blog/archives/2009/05/05/concurrent_operations/
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        [pool drain];
        return;
    }
	for (BlioProcessingOperation * blioOp in [self dependencies]) {
		if (!blioOp.operationSuccess) {
			NSLog(@"failed dependency found!");
			[self cancel];
			break;
		}
	}
    if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
		NSLog(@"Operation cancelled, will prematurely abort start");
        [self didChangeValueForKey:@"isFinished"];
        [pool drain];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
        	
    NSString *paginationPath = [self.cacheDirectory stringByAppendingPathComponent:@"libEucalyptusCache"];

    if(self.forceReprocess) {
        // Best effort - ignore errors.
        [[NSFileManager defaultManager] removeItemAtPath:paginationPath error:NULL];
    }
    
    
    EucBUpeBook *eucBook = nil;
    
    // Create a EucBook for the paginator.
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
        
        NSLog(@"Paginating book %@", book.title);
        
        eucBook = [[[BlioBookManager sharedBookManager] checkOutEucBookForBookWithID:self.bookID] retain];
        
        [pool drain];
    }
    
    if([eucBook paginationIsComplete] || eucBook == nil) {
        // This book is already fully paginated!
        self.operationSuccess = YES;
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
                
            
            //NSLog(@"Begining pagination for %@", eucBook.title);
            [paginator paginateBookInBackground:eucBook saveImagesTo:nil];
        }
    }
    
    [eucBook release];
    [[BlioBookManager sharedBookManager] checkInEucBookForBookWithID:self.bookID];
    
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
        
        NSLog(@"Using layout equivalent page length of %ld for %@", layoutEquivalentPageCount, [self getBookValueForKey:@"title"]); 
    }
    
    self.percentageComplete = 100;
    self.operationSuccess = YES;
    
    [self finish];
}

- (void)paginationProgress:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat percentagePaginated = [[userInfo objectForKey:EucBookPaginatorNotificationPercentagePaginatedKey] floatValue];
    self.percentageComplete = roundf(percentagePaginated);
}
-(void) dealloc {
	self.paginator = nil;
	[super dealloc];
}
@end
