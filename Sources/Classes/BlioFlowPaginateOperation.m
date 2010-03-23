//
//  BlioEPubPaginateOperation.m
//  BlioApp
//
//  Created by James Montgomerie on 17/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioFlowPaginateOperation.h"
#import "BlioProcessing.h"

#import "BlioMockBook.h"
#import "BlioFlowEucBook.h"

#import <libEucalyptus/EucBUpeBook.h>
#import <libEucalyptus/EucBookPaginator.h>

@implementation BlioFlowPaginateOperation

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
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    // Must be performed on main thread
    // See http://www.dribin.org/dave/blog/archives/2009/05/05/concurrent_operations/
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
    
    if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        [pool drain];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    NSString *epubPath = [self.cacheDirectory stringByAppendingPathComponent:[self getBookValueForKey:@"epubFilename"]];
    NSString *textflowPath = [self.cacheDirectory stringByAppendingPathComponent:[self getBookValueForKey:@"textFlowFilename"]];
   
    NSString *paginationPath = [self.cacheDirectory stringByAppendingPathComponent:@"libEucalyptusPageIndexes"];
    
    NSString *cannedPaginationPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"PageIndexes"] stringByAppendingPathComponent:[[self getBookValueForKey:@"title"] stringByAppendingPathExtension:@"libEucalyptusPageIndexes"]];
    
    BOOL isDirectory = YES;

    if([[NSFileManager defaultManager] fileExistsAtPath:cannedPaginationPath isDirectory:&isDirectory] && isDirectory) {       
        NSLog(@"Using pre-canned indexes for %@", [self getBookValueForKey:@"title"]);

        [[NSFileManager defaultManager] copyItemAtPath:cannedPaginationPath
                                                toPath:paginationPath 
                                                 error:NULL];
        
        [self finish];
    } else {
        if(self.forceReprocess) {
            // Best effort - ignore errors.
            [[NSFileManager defaultManager] removeItemAtPath:paginationPath error:NULL];
        }
        
        if(![[NSFileManager defaultManager] fileExistsAtPath:paginationPath isDirectory:&isDirectory] || !isDirectory) {
            NSError *error = nil;
            if(![[NSFileManager defaultManager] createDirectoryAtPath:paginationPath withIntermediateDirectories:YES attributes:nil error:&error]) {
                NSLog(@"Failed to create book cache directory in processing manager with error: %@, %@", error, [error userInfo]);
            }
        }
        
        
        EucBUpeLocalBookReference<EucBook> *eucBook = nil;
        if(textflowPath) {
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

            NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init]; 
            [moc setPersistentStoreCoordinator:self.storeCoordinator]; 
            
            eucBook = [[BlioFlowEucBook alloc] initWithBlioBook:(BlioMockBook *)[moc objectWithID:self.bookID]];
            [moc release];
            
            [pool drain];
        } else if(epubPath) {
            eucBook = [[EucBUpeBook alloc] initWithPath:epubPath];
        }
        
        eucBook.cacheDirectoryPath = paginationPath;

        paginator = [[EucBookPaginator alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(paginationComplete:)
                                                     name:EucBookPaginatorCompleteNotification
                                                   object:paginator];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(paginationProgress:)
                                                     name:EucBookBookPaginatorProgressNotification
                                                   object:paginator];
            
        
        NSLog(@"Begining pagination for %@", eucBook.title);
        [paginator paginateBookInBackground:eucBook saveImagesTo:nil];
        
        [eucBook release];
    }
    
    [pool drain];
}

- (void)paginationComplete:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat percentagePaginated = [[userInfo objectForKey:EucBookPaginatorNotificationPercentagePaginatedKey] floatValue];
    EucBUpeBook *book = [userInfo objectForKey:EucBookPaginatorNotificationBookKey];
    
    NSLog(@"Pagination compete (%@, %f%%)!", book.title, (double)percentagePaginated);
    self.percentageComplete = 100;
    
    [self finish];
}

- (void)paginationProgress:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat percentagePaginated = [[userInfo objectForKey:EucBookPaginatorNotificationPercentagePaginatedKey] floatValue];
    EucBUpeBook *book = [userInfo objectForKey:EucBookPaginatorNotificationBookKey];
    
    NSLog(@"Pagination progress (%@, %f%%)!", book.title, (double)percentagePaginated);
    
    self.percentageComplete = roundf(percentagePaginated);
}

@end
