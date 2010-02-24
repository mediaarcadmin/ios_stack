//
//  BlioProcessingManager.m
//  BlioApp
//
//  Created by matt on 24/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioProcessingManager.h"
#import "BlioMockBook.h"

@interface BlioProcessingDownloadOperation : BlioProcessingBookOperation {
    NSURL *url;
    NSString *cacheDirectory;
}

@property (nonatomic, retain) NSURL* url;
@property (nonatomic, retain) NSString* cacheDirectory;

- (id)initWithUrl:(NSURL *)aURL cacheDirectory:(NSString *)aCacheDir;

@end

@interface BlioProcessingDownloadPDFOperation : BlioProcessingDownloadOperation
@end

@interface BlioProcessingDownloadCoverOperation : BlioProcessingDownloadOperation
@end

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

- (void)enqueueBookWithTitle:(NSString *)title authors:(NSArray *)authors coverURL:(NSURL *)coverURL ePubURL:(NSURL *)ePubURL pdfURL:(NSURL *)pdfURL {
    NSLog(@"book enqueued with title: %@, authors: %@, coverURL: %@, ePurlURL: %@, pdfURL: %@", title, authors, coverURL, ePubURL, pdfURL);
    
    NSManagedObjectContext *moc = self.managedObjectContext;
    if (nil != moc) {
        BlioMockBook *aBook = [NSEntityDescription insertNewObjectForEntityForName:@"BlioMockBook" inManagedObjectContext:moc];
        [aBook setValue:title forKey:@"title"];
        [aBook setValue:[authors lastObject] forKey:@"author"];
        [aBook setValue:[NSNumber numberWithBool:NO] forKey:@"processingComplete"];
        
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef uniqueString = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        [aBook setValue:(NSString *)uniqueString forKey:@"uuid"];
        CFRelease(uniqueString);
        
        NSError *error;
        if (![moc save:&error]) {
            NSLog(@"Save failed in processing manager with error: %@, %@", error, [error userInfo]);
        } else {
            NSManagedObjectID *bookID = [aBook objectID];
            NSString *cacheDir = [aBook bookCacheDirectory];
            
            if (![[NSFileManager defaultManager] createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:&error])
                NSLog(@"Failed to create book cache directory in processing manager with error: %@, %@", error, [error userInfo]);

            if (nil != coverURL) {
                BlioProcessingDownloadCoverOperation *downloadOp = [[BlioProcessingDownloadCoverOperation alloc] initWithUrl:coverURL cacheDirectory:cacheDir];
                downloadOp.bookID = bookID;
                downloadOp.storeCoordinator = [moc persistentStoreCoordinator];
                [self.preAvailabilityQueue addOperation:downloadOp];
            }
        }
    }
}

@end

@implementation BlioProcessingBookOperation

@synthesize bookID, storeCoordinator, forceReprocess, percentageComplete;

- (void)dealloc {
    self.bookID = nil;
    self.storeCoordinator = nil;
    [super dealloc];
}

- (void)setBookValue:(id)value forKey:(NSString *)key {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init]; 
    [moc setPersistentStoreCoordinator:self.storeCoordinator]; 
    NSManagedObject *book = [moc objectWithID:self.bookID];
    if (nil == book) 
        NSLog(@"Failed to retrieve book");
    else
        [book setValue:value forKey:key];
    
    NSError *error;
    if (![moc save:&error]) {
        NSLog(@"Save failed with error: %@, %@", error, [error userInfo]);
    }
    
    [moc release];
    
    [pool drain];
}

@end

@implementation BlioProcessingDownloadOperation

@synthesize url, cacheDirectory;

- (void) dealloc {
    self.url = nil;
    self.cacheDirectory = nil;
    [super dealloc];
}

- (id)initWithUrl:(NSURL *)aURL cacheDirectory:(NSString *)aCacheDir {
    
    if (nil == aURL) return nil;
    
    if((self = [super init])) {
        self.url = aURL;
        self.cacheDirectory = aCacheDir;
    }

    return self;
}

@end

@implementation BlioProcessingDownloadPDFOperation

- (void)main {
    if ([self isCancelled]) return;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [pool drain];
}


@end

@implementation BlioProcessingDownloadCoverOperation

- (void)main {
    if ([self isCancelled]) return;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSError *error;
    NSURLResponse *response;
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:self.url];
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [request release];
    
    if (error) {
        NSLog(@"Failed to download from URL with error: %@, %@", error, [error userInfo]);
        [pool drain];
        return;
    }
    
    NSLog(@"downloaded data of size: %d", [data length]);
    
    if ([self isCancelled]) {
        [pool drain];
        return;
    }
    
    NSString *extension = [[response suggestedFilename] pathExtension];
    if (nil == extension) extension = @"png";
    
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef uniqueString = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    NSString *filename = [(NSString *)uniqueString stringByAppendingPathExtension:extension];
    CFRelease(uniqueString);
    
    NSString *cachedFilename = [self.cacheDirectory stringByAppendingPathComponent:filename];
    [data writeToFile:cachedFilename atomically:YES];
    
    NSLog(@"Saving cover with filename %@", filename);
    [self setBookValue:filename forKey:@"coverFilename"];
    [self setBookValue:[NSNumber numberWithBool:YES] forKey:@"processingComplete"];
    
    [pool drain];
}


@end
