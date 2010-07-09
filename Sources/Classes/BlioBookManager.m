//
//  BlioBookManager.m
//  BlioApp
//
//  Created by James Montgomerie on 06/07/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioBookManager.h"
#import "BlioBook.h"
#import "BlioTextFlow.h"
#import "BlioEPubBook.h"
#import "BlioParagraphSource.h"
#import "BlioTextFlowParagraphSource.h"
#import "BlioEPubParagraphSource.h"
#import "BlioXPSProvider.h"
#import <pthread.h>

@interface BlioBookManager ()

@property (nonatomic, retain) NSMutableDictionary *cachedTextFlows;
@property (nonatomic, retain) NSCountedSet *cachedTextFlowCheckoutCounts;
@property (nonatomic, retain) NSMutableDictionary *cachedEPubBooks;
@property (nonatomic, retain) NSCountedSet *cachedEPubBookCheckoutCounts;
@property (nonatomic, retain) NSMutableDictionary *cachedParagraphSources;
@property (nonatomic, retain) NSCountedSet *cachedParagraphSourceCheckoutCounts;
@property (nonatomic, retain) NSMutableDictionary *cachedXPSProviders;
@property (nonatomic, retain) NSCountedSet *cachedXPSProviderCheckoutCounts;

@end

@implementation BlioBookManager

@synthesize persistentStoreCoordinator;

@synthesize cachedTextFlows;
@synthesize cachedTextFlowCheckoutCounts;
@synthesize cachedEPubBooks;
@synthesize cachedEPubBookCheckoutCounts;
@synthesize cachedParagraphSources;
@synthesize cachedParagraphSourceCheckoutCounts;
@synthesize cachedXPSProviders;
@synthesize cachedXPSProviderCheckoutCounts;

static BlioBookManager *sSharedBookManager = nil;
static pthread_key_t sManagedObjectContextKey;

- (id)init
{
    if((self = [super init])) {
        self.cachedTextFlows = [NSMutableDictionary dictionary];
        self.cachedEPubBooks = [NSMutableDictionary dictionary];
        self.cachedParagraphSources = [NSMutableDictionary dictionary];
        self.cachedXPSProviders = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (BlioBookManager *)sharedBookManager
{
    // We don't need to bother being thread-safe in the initialisation here,
    // because the object can't be used until the NSPersistentStoreCoordinator 
    // is set, so that has to be all done on the main thread before other calls
    // are made anyway.
    if(!sSharedBookManager) {
        sSharedBookManager = [[self alloc] init];
        // By setting this, if we associate an object with sManagedObjectContextKey
        // using pthread_setspecific, CFRelease will be called on it before
        // the thread terminates.
        pthread_key_create(&sManagedObjectContextKey, (void (*)(void *))CFRelease);
    }
    return sSharedBookManager;
}

- (NSManagedObjectContext *)managedObjectContextForCurrentThread
{
    NSManagedObjectContext *managedObjectContextForCurrentThread = (NSManagedObjectContext *)pthread_getspecific(sManagedObjectContextKey);
    if(!managedObjectContextForCurrentThread) {
        managedObjectContextForCurrentThread = [[NSManagedObjectContext alloc] init]; 
        managedObjectContextForCurrentThread.persistentStoreCoordinator = self.persistentStoreCoordinator; 
        self.managedObjectContextForCurrentThread = managedObjectContextForCurrentThread;
    }
    return managedObjectContextForCurrentThread;
}

- (void)setManagedObjectContextForCurrentThread:(NSManagedObjectContext *)managedObjectContextForCurrentThread
{
    NSManagedObjectContext *oldManagedObjectContextForCurrentThread = (NSManagedObjectContext *)pthread_getspecific(sManagedObjectContextKey);
    if(oldManagedObjectContextForCurrentThread) {
        NSLog(@"Unexpectedly setting thread's managed object context on thread %@, which already has one set", [NSThread currentThread]);
        [oldManagedObjectContextForCurrentThread release];
    }
    
    // CFRelease will be called on the object before the thread terminates
    // (see comments in +sharedBookManager).
    pthread_setspecific(sManagedObjectContextKey, managedObjectContextForCurrentThread);
}

- (BOOL)save:(NSError **)error
{
    return [self.managedObjectContextForCurrentThread save:error];
}

- (BlioBook *)bookWithID:(NSManagedObjectID *)aBookID
{
    // If we don't do a refresh here, we run the risk that another thread has
    // modified the object while it's been cached by this thread's managed
    // object context.  
    // If I were redesigning this, I'd make only one thread allowed to modify
    // the books, and call 
    // - (void)mergeChangesFromContextDidSaveNotification:(NSNotification *)notification
    // on the other threads when it saved.
    NSManagedObjectContext *context = self.managedObjectContextForCurrentThread;
    BlioBook *book = (BlioBook *)[context objectWithID:aBookID];
    [context refreshObject:book mergeChanges:YES];
    return book;
}


- (BlioTextFlow *)checkOutTextFlowForBookWithID:(NSManagedObjectID *)aBookID
{
    NSMutableDictionary *myCachedTextFlows = self.cachedTextFlows;
    @synchronized(myCachedTextFlows) {
        BlioTextFlow *previouslyCachedTextFlow = [myCachedTextFlows objectForKey:aBookID];
        if(previouslyCachedTextFlow) {
            NSLog(@"Returning cached TextFlow for book with ID %@", aBookID);
            [self.cachedTextFlowCheckoutCounts addObject:aBookID];
            return previouslyCachedTextFlow;
        } else {
            BlioBook *book = [self bookWithID:aBookID];
            if(book.textFlowPath) {
                BlioTextFlow *textFlow = [[BlioTextFlow alloc] initWithBookID:aBookID];
                if(textFlow) {
                    NSLog(@"Creating and caching TextFlow for book with ID %@", aBookID);
                    NSCountedSet *myCachedTextFlowCheckoutCounts = self.cachedTextFlowCheckoutCounts;
                    if(!myCachedTextFlowCheckoutCounts) {
                        myCachedTextFlowCheckoutCounts = [NSCountedSet set];
                        self.cachedTextFlowCheckoutCounts = myCachedTextFlowCheckoutCounts;
                    }
                    [myCachedTextFlows setObject:textFlow forKey:aBookID];
                    [myCachedTextFlowCheckoutCounts addObject:aBookID];
                    [textFlow release];
                    return textFlow;
                }
            }
        }
    }
    return nil;
}

- (void)checkInTextFlowForBookWithID:(NSManagedObjectID *)aBookID
{
    NSMutableDictionary *myCachedTextFlows = self.cachedTextFlows;
    @synchronized(myCachedTextFlows) {
        NSCountedSet *myCachedTextFlowCheckoutCounts = self.cachedTextFlowCheckoutCounts;
        NSUInteger count = [myCachedTextFlowCheckoutCounts countForObject:aBookID];
        if(count == 0) {
            NSLog(@"Warning! Unexpected checkin of non-checked-out TextFlow");
        } else {
            [myCachedTextFlowCheckoutCounts removeObject:aBookID];
            if (count == 1) {
                NSLog(@"Releasing cached TextFlow for book with ID %@", aBookID);
                [myCachedTextFlows removeObjectForKey:aBookID];
                if(myCachedTextFlowCheckoutCounts.count == 0) {
                    // May as well release the set.
                    self.cachedTextFlowCheckoutCounts = nil;
                }
            }
        }
    }
}


- (BlioEPubBook *)checkOutEPubBookForBookWithID:(NSManagedObjectID *)aBookID
{
    NSMutableDictionary *myCachedEPubBooks = self.cachedEPubBooks;
    @synchronized(myCachedEPubBooks) {
        BlioEPubBook *previouslyCachedEPubBook = [cachedEPubBooks objectForKey:aBookID];
        if(previouslyCachedEPubBook) {
            NSLog(@"Returning cached EPubBook for book with ID %@", aBookID);
            [self.cachedEPubBookCheckoutCounts addObject:aBookID];
            return previouslyCachedEPubBook;
        } else {
            BlioBook *book = [self bookWithID:aBookID];
            if(book.textFlowPath) {
                BlioEPubBook *ePubBook = [[BlioEPubBook alloc] initWithPath:book.ePubPath];
                if(ePubBook) {
                    ePubBook.blioBookID = aBookID;
                    ePubBook.persistsPositionAutomatically = NO;
                    ePubBook.cacheDirectoryPath = [book.bookCacheDirectory stringByAppendingPathComponent:@"libEucalyptusCache"];
                    
                    NSLog(@"Creating and caching EPubBook for book with ID %@", aBookID);
                    NSCountedSet *myCachedEPubBookCheckoutCounts = self.cachedEPubBookCheckoutCounts;
                    if(!myCachedEPubBookCheckoutCounts) {
                        myCachedEPubBookCheckoutCounts = [NSCountedSet set];
                        cachedEPubBookCheckoutCounts = myCachedEPubBookCheckoutCounts;
                    }
                    [myCachedEPubBooks setObject:ePubBook forKey:aBookID];
                    [myCachedEPubBookCheckoutCounts addObject:aBookID];
                    [ePubBook release];
                    return ePubBook;
                }
            }
        }
    }
    return nil;
}

- (void)checkInEPubBookForBookWithID:(NSManagedObjectID *)aBookID
{
    NSMutableDictionary *myCachedEPubBooks = self.cachedEPubBooks;
    @synchronized(myCachedEPubBooks) {
        NSCountedSet *myCachedEPubBookCheckoutCounts = self.cachedEPubBookCheckoutCounts;
        NSUInteger count = [myCachedEPubBookCheckoutCounts countForObject:aBookID];
        if(count == 0) {
            NSLog(@"Warning! Unexpected checkin of non-checked-out ePub book");
        } else {
            [myCachedEPubBookCheckoutCounts removeObject:aBookID];
            if (count == 1) {
                NSLog(@"Releasing cached ePub book for book with ID %@", aBookID);
                [myCachedEPubBooks removeObjectForKey:aBookID];
                if(myCachedEPubBookCheckoutCounts.count == 0) {
                    // May as well release the set.
                    self.cachedEPubBookCheckoutCounts = nil;
                }
            }
        }
    }
}


- (id<BlioParagraphSource>)checkOutParagraphSourceForBookWithID:(NSManagedObjectID *)aBookID
{   
    NSMutableDictionary *myCachedParagraphSources = self.cachedParagraphSources;
    @synchronized(myCachedParagraphSources) {
        id<BlioParagraphSource> previouslyCachedParagraphSource = [myCachedParagraphSources objectForKey:aBookID];
        if(previouslyCachedParagraphSource) {
            NSLog(@"Returning cached ParagraphSource for book with ID %@", aBookID);
            [self.cachedParagraphSourceCheckoutCounts addObject:aBookID];
            return previouslyCachedParagraphSource;
        } else {
            BlioBook *book = [self bookWithID:aBookID];
            if(book.textFlowPath) {
                BlioTextFlow *textFlow = [self checkOutTextFlowForBookWithID:aBookID];
                id<BlioParagraphSource> paragraphSource = nil;
                if(textFlow) {
                    paragraphSource = [[BlioTextFlowParagraphSource alloc] initWithBookID:aBookID];
                    [self checkInTextFlowForBookWithID:aBookID];
                } else {
                    BlioEPubBook *myEPubBook = [self checkOutEPubBookForBookWithID:aBookID];
                    if(myEPubBook) {
                        paragraphSource = [[BlioEPubParagraphSource alloc] initWithBookID:aBookID];
                        [self checkInEPubBookForBookWithID:aBookID];
                    }
                }
                if(paragraphSource) {
                    NSLog(@"Creating and caching ParagraphSource for book with ID %@", aBookID);
                    NSCountedSet *myCachedParagraphSourceCheckoutCounts = self.cachedParagraphSourceCheckoutCounts;
                    if(!myCachedParagraphSourceCheckoutCounts) {
                        myCachedParagraphSourceCheckoutCounts = [NSCountedSet set];
                        self.cachedParagraphSourceCheckoutCounts = myCachedParagraphSourceCheckoutCounts;
                    }
                    [myCachedParagraphSources setObject:paragraphSource forKey:aBookID];
                    [myCachedParagraphSourceCheckoutCounts addObject:aBookID];
                    [paragraphSource release];
                    return paragraphSource;
                }
            }
        }
    }
    return nil;
}

- (void)checkInParagraphSourceForBookWithID:(NSManagedObjectID *)aBookID
{
    NSMutableDictionary *myCachedParagraphSources = self.cachedParagraphSources;
    @synchronized(myCachedParagraphSources) {
        NSCountedSet *myCachedParagraphSourceCheckoutCounts = self.cachedParagraphSourceCheckoutCounts;
        NSUInteger count = [myCachedParagraphSourceCheckoutCounts countForObject:aBookID];
        if(count == 0) {
            NSLog(@"Warning! Unexpected checkin of non-checked-out paragraph source");
        } else {
            [myCachedParagraphSourceCheckoutCounts removeObject:aBookID];
            if (count == 1) {
                NSLog(@"Releasing cached paragraph source for book with ID %@", aBookID);
                [myCachedParagraphSources removeObjectForKey:aBookID];
                if(myCachedParagraphSourceCheckoutCounts.count == 0) {
                    // May as well release the set.
                    self.cachedParagraphSourceCheckoutCounts = nil;
                }
            }
        }
    }
}


- (BlioXPSProvider *)checkOutXPSProviderForBookWithID:(NSManagedObjectID *)aBookID
{
    NSMutableDictionary *myCachedXPSProviders = self.cachedXPSProviders;
    @synchronized(myCachedXPSProviders) {
        BlioXPSProvider *previouslyCachedXPSProvider = [myCachedXPSProviders objectForKey:aBookID];
        if(previouslyCachedXPSProvider) {
            NSLog(@"Returning cached XPSProvider for book with ID %@", aBookID);
            [self.cachedXPSProviderCheckoutCounts addObject:aBookID];
            return previouslyCachedXPSProvider;
        } else {
            BlioBook *book = [self bookWithID:aBookID];
            if(book.xpsPath) {
                BlioXPSProvider *xpsProvider = [[BlioXPSProvider alloc] initWithBookID:aBookID];
                if(xpsProvider) {
                    NSLog(@"Creating and caching XPSProvider for book with ID %@", aBookID);
                    NSCountedSet *myCachedXPSProviderCheckoutCounts = self.cachedXPSProviderCheckoutCounts;
                    if(!myCachedXPSProviderCheckoutCounts) {
                        myCachedXPSProviderCheckoutCounts = [NSCountedSet set];
                        self.cachedXPSProviderCheckoutCounts = myCachedXPSProviderCheckoutCounts;
                    }
                    [myCachedXPSProviders setObject:xpsProvider forKey:aBookID];
                    [myCachedXPSProviderCheckoutCounts addObject:aBookID];
                    [xpsProvider release];
                    return xpsProvider;
                }
            }
        }
    }
    return nil;
}

- (void)checkInXPSProviderForBookWithID:(NSManagedObjectID *)aBookID
{
    NSMutableDictionary *myCachedXPSProviders = self.cachedXPSProviders;
    @synchronized(myCachedXPSProviders) {
        NSCountedSet *myCachedXPSProviderCheckoutCounts = self.cachedXPSProviderCheckoutCounts;
        NSUInteger count = [myCachedXPSProviderCheckoutCounts countForObject:aBookID];
        if(count == 0) {
            NSLog(@"Warning! Unexpected checkin of non-checked-out XPSProvider");
        } else {
            [myCachedXPSProviderCheckoutCounts removeObject:aBookID];
            if (count == 1) {
                NSLog(@"Releasing cached XPSProvider for book with ID %@", aBookID);
                [myCachedXPSProviders removeObjectForKey:aBookID];
                if(myCachedXPSProviderCheckoutCounts.count == 0) {
                    // May as well release the set.
                    self.cachedXPSProviderCheckoutCounts = nil;
                }
            }
        }
    }
}

@end
