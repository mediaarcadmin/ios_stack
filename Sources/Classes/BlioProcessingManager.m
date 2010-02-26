//
//  BlioProcessingManager.m
//  BlioApp
//
//  Created by matt on 24/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioProcessingManager.h"
#import "BlioProcessingStandardOperations.h"
#import "BlioMockBook.h"

@interface BlioProcessingManager()
@property (nonatomic, retain) NSOperationQueue *preAvailabilityQueue;
@property (nonatomic, retain) NSOperationQueue *postAvailabilityQueue;
@end

@implementation BlioProcessingManager

@synthesize managedObjectContext, preAvailabilityQueue, postAvailabilityQueue;

- (void)dealloc {
    [self.preAvailabilityQueue cancelAllOperations];
    [self.postAvailabilityQueue cancelAllOperations];
    self.preAvailabilityQueue = nil;
    self.postAvailabilityQueue = nil;
    self.managedObjectContext = nil;
    [super dealloc];
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aManagedObjectContext {
    if ((self = [super init])) {
        self.managedObjectContext = aManagedObjectContext;
        
        NSOperationQueue *aPreAvailabilityQueue = [[NSOperationQueue alloc] init];
        self.preAvailabilityQueue = aPreAvailabilityQueue;
        [aPreAvailabilityQueue release];
        
        NSOperationQueue *aPostAvailabilityQueue = [[NSOperationQueue alloc] init];
        self.postAvailabilityQueue = aPostAvailabilityQueue;
        [aPostAvailabilityQueue release];
    }
    return self;
}

#pragma mark -
#pragma mark BlioProcessingDelegate

- (void)enqueueBookWithTitle:(NSString *)title authors:(NSArray *)authors coverURL:(NSURL *)coverURL 
                     ePubURL:(NSURL *)ePubURL pdfURL:(NSURL *)pdfURL textFlowURL:(NSURL *)textFlowURL 
                audiobookURL:(NSURL *)audiobookURL {    
    NSManagedObjectContext *moc = self.managedObjectContext;
    if (nil != moc) {
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:[NSEntityDescription entityForName:@"BlioMockBook" inManagedObjectContext:moc]];        
        
        NSError *error;
        BlioMockBook *aBook;
        
        NSUInteger count = [moc countForFetchRequest:request error:&error];
        [request release];
        if (count == NSNotFound) {
            NSLog(@"Failed to retrieve book count with error: %@, %@", error, [error userInfo]);
            return;
        } else {
            aBook = [NSEntityDescription insertNewObjectForEntityForName:@"BlioMockBook" inManagedObjectContext:moc];
        }
        
        [aBook setValue:title forKey:@"title"];
        [aBook setValue:[authors lastObject] forKey:@"author"];
        [aBook setValue:[NSNumber numberWithInt:count] forKey:@"position"];        
        [aBook setValue:[NSNumber numberWithBool:NO] forKey:@"processingComplete"];
        
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef uniqueString = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        [aBook setValue:(NSString *)uniqueString forKey:@"uuid"];
        CFRelease(uniqueString);
        
        if (![moc save:&error]) {
            NSLog(@"Save failed in processing manager with error: %@, %@", error, [error userInfo]);
        } else {
            NSManagedObjectID *bookID = [aBook objectID];
            NSString *cacheDir = [aBook bookCacheDirectory];
            
            if (![[NSFileManager defaultManager] createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:&error])
                NSLog(@"Failed to create book cache directory in processing manager with error: %@, %@", error, [error userInfo]);
            
            NSMutableArray *bookOps = [NSMutableArray array];
            
            if (nil != coverURL) {
                BlioProcessingDownloadCoverOperation *coverOp = [[BlioProcessingDownloadCoverOperation alloc] initWithUrl:coverURL];
                coverOp.bookID = bookID;
                coverOp.storeCoordinator = [moc persistentStoreCoordinator];
                coverOp.cacheDirectory = cacheDir;
                [self.preAvailabilityQueue addOperation:coverOp];
                [bookOps addObject:coverOp];
                
                BlioProcessingGenerateCoverThumbsOperation *thumbsOp = [[BlioProcessingGenerateCoverThumbsOperation alloc] init];
                thumbsOp.bookID = bookID;
                thumbsOp.storeCoordinator = [moc persistentStoreCoordinator];
                thumbsOp.cacheDirectory = cacheDir;
                [thumbsOp addDependency:coverOp];
                [self.preAvailabilityQueue addOperation:thumbsOp];
                [bookOps addObject:thumbsOp];
                
                [coverOp release];
                [thumbsOp release];
            }
            
            if (nil != ePubURL) {
                BlioProcessingDownloadEPubOperation *ePubOp = [[BlioProcessingDownloadEPubOperation alloc] initWithUrl:ePubURL];
                ePubOp.bookID = bookID;
                ePubOp.storeCoordinator = [moc persistentStoreCoordinator];
                ePubOp.cacheDirectory = cacheDir;
                [self.preAvailabilityQueue addOperation:ePubOp];
                [bookOps addObject:ePubOp];
                [ePubOp release];
            }
            
            if (nil != pdfURL) {
                BlioProcessingDownloadPdfOperation *pdfOp = [[BlioProcessingDownloadPdfOperation alloc] initWithUrl:pdfURL];
                pdfOp.bookID = bookID;
                pdfOp.storeCoordinator = [moc persistentStoreCoordinator];
                pdfOp.cacheDirectory = cacheDir;
                [self.preAvailabilityQueue addOperation:pdfOp];
                [bookOps addObject:pdfOp];
                [pdfOp release];
            }
            
            if (nil != textFlowURL) {
                BlioProcessingDownloadTextFlowOperation *textFlowOp = [[BlioProcessingDownloadTextFlowOperation alloc] initWithUrl:textFlowURL];
                textFlowOp.bookID = bookID;
                textFlowOp.storeCoordinator = [moc persistentStoreCoordinator];
                textFlowOp.cacheDirectory = cacheDir;
                [self.preAvailabilityQueue addOperation:textFlowOp];
                [bookOps addObject:textFlowOp];
                [textFlowOp release];
            }
            
            if (nil != audiobookURL) {
                BlioProcessingDownloadAudiobookOperation *audiobookOp = [[BlioProcessingDownloadAudiobookOperation alloc] initWithUrl:audiobookURL];
                audiobookOp.bookID = bookID;
                audiobookOp.storeCoordinator = [moc persistentStoreCoordinator];
                audiobookOp.cacheDirectory = cacheDir;
                [self.preAvailabilityQueue addOperation:audiobookOp];
                [bookOps addObject:audiobookOp];
                [audiobookOp release];
            }
            
            BlioProcessingCompleteOperation *completeOp = [[BlioProcessingCompleteOperation alloc] init];
            completeOp.bookID = bookID;
            completeOp.storeCoordinator = [moc persistentStoreCoordinator];
            
            for (NSOperation *op in bookOps) {
                [completeOp addDependency:op];
            }
            
            [self.preAvailabilityQueue addOperation:completeOp];
            [completeOp release];
        }
    }
}

@end