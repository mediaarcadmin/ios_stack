//
//  BlioBookManager.m
//  BlioApp
//
//  Created by James Montgomerie on 06/07/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioBookManager.h"
#import "BlioBook.h"
#import "BlioSong.h"
#import "BlioTextFlow.h"
#import "BlioEPubBook.h"
#import "BlioEPubBook.h"
#import "BlioFlowEucBook.h"
#import "BlioParagraphSource.h"
#import "BlioTextFlowParagraphSource.h"
#import "BlioEPubParagraphSource.h"
#import "BlioXPSProvider.h"
#import <pthread.h>

@interface BlioBookManager ()

@property (nonatomic, retain) NSMutableDictionary *cachedTextFlows;
@property (nonatomic, retain) NSCountedSet *cachedTextFlowCheckoutCounts;
@property (nonatomic, retain) NSMutableDictionary *cachedEucBooks;
@property (nonatomic, retain) NSCountedSet *cachedEucBookCheckoutCounts;
@property (nonatomic, retain) NSMutableDictionary *cachedParagraphSources;
@property (nonatomic, retain) NSCountedSet *cachedParagraphSourceCheckoutCounts;
@property (nonatomic, retain) NSMutableDictionary *cachedXPSProviders;
@property (nonatomic, retain) NSCountedSet *cachedXPSProviderCheckoutCounts;

@end

@implementation BlioBookManager

@synthesize persistentStoreCoordinator;

@synthesize cachedTextFlows;
@synthesize cachedTextFlowCheckoutCounts;
@synthesize cachedEucBooks;
@synthesize cachedEucBookCheckoutCounts;
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
        self.cachedEucBooks = [NSMutableDictionary dictionary];
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
        [managedObjectContextForCurrentThread release];
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
    pthread_setspecific(sManagedObjectContextKey, [managedObjectContextForCurrentThread retain]);
}

- (BOOL)save:(NSError **)error
{
    return [self.managedObjectContextForCurrentThread save:error];
}

- (BlioSong *)songWithID:(NSManagedObjectID *)aSongID
{
    // If we don't do a refresh here, we run the risk that another thread has
    // modified the object while it's been cached by this thread's managed
    // object context.
    // If I were redesigning this, I'd make only one thread allowed to modify
    // the books, and call
    // - (void)mergeChangesFromContextDidSaveNotification:(NSNotification *)notification
    // on the other threads when it saved.
    NSManagedObjectContext *context = self.managedObjectContextForCurrentThread;
    BlioSong *song = nil;
    
    if (aSongID) {
        song = (BlioSong *)[context objectWithID:aSongID];
    }
    else
        NSLog(@"WARNING: BlioBookManager songWithID: aSongID is nil!");
    if (song) {
        [context refreshObject:song mergeChanges:YES];
    }
    
    return song;
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
    BlioBook *book = nil;
    
    if (aBookID) {
        book = (BlioBook *)[context objectWithID:aBookID];
    }
    else
        NSLog(@"WARNING: BlioBookManager bookWithID: aBookID is nil!");
    if (book) {
        [context refreshObject:book mergeChanges:YES];
    }
    
    return book;
}


- (BlioTextFlow *)checkOutTextFlowForBookWithID:(NSManagedObjectID *)aBookID
{
    BlioTextFlow *ret = nil;
    
    // Always check out an XPS Provider alongside a TextFlow to guarantee that we have the 
    // same one underneath it for the duration of any decrypt operation
    [self checkOutXPSProviderForBookWithID:aBookID];
    
    [self.persistentStoreCoordinator lock];
    
    NSMutableDictionary *myCachedTextFlows = self.cachedTextFlows;
    @synchronized(myCachedTextFlows) {
        BlioTextFlow *previouslyCachedTextFlow = [myCachedTextFlows objectForKey:aBookID];
        if(previouslyCachedTextFlow) {
            //NSLog(@"Returning cached TextFlow for book with ID %@", aBookID);
            [self.cachedTextFlowCheckoutCounts addObject:aBookID];
            ret = previouslyCachedTextFlow;
        } else {
            BlioBook *book = [self bookWithID:aBookID];
            if([book hasTextFlow]) {
                BlioTextFlow *textFlow = [[BlioTextFlow alloc] initWithBookID:aBookID];
                if(textFlow) {
                    //NSLog(@"Creating and caching TextFlow for book with ID %@", aBookID);
                    NSCountedSet *myCachedTextFlowCheckoutCounts = self.cachedTextFlowCheckoutCounts;
                    if(!myCachedTextFlowCheckoutCounts) {
                        myCachedTextFlowCheckoutCounts = [NSCountedSet set];
                        self.cachedTextFlowCheckoutCounts = myCachedTextFlowCheckoutCounts;
                    }
                    [myCachedTextFlows setObject:textFlow forKey:aBookID];
                    [myCachedTextFlowCheckoutCounts addObject:aBookID];
                    [textFlow release];
                    ret = textFlow;
                }
            }
        }
    }
    
    [self.persistentStoreCoordinator unlock];

    return ret;
}

- (void)checkInTextFlowForBookWithID:(NSManagedObjectID *)aBookID
{
    // Always check in an XPS Provider alongside a TextFlow to match the fact 
    // that we always check it out
    [self checkInXPSProviderForBookWithID:aBookID];
    
    NSMutableDictionary *myCachedTextFlows = self.cachedTextFlows;
    @synchronized(myCachedTextFlows) {
        NSCountedSet *myCachedTextFlowCheckoutCounts = self.cachedTextFlowCheckoutCounts;
        NSUInteger count = [myCachedTextFlowCheckoutCounts countForObject:aBookID];
        if(count == 0) {
            NSLog(@"Warning! Unexpected checkin of non-checked-out TextFlow");
        } else {
            [myCachedTextFlowCheckoutCounts removeObject:aBookID];
            if (count == 1) {
                //NSLog(@"Releasing cached TextFlow for book with ID %@", aBookID);
                [myCachedTextFlows removeObjectForKey:aBookID];
                if(myCachedTextFlowCheckoutCounts.count == 0) {
                    // May as well release the set.
                    self.cachedTextFlowCheckoutCounts = nil;
                }
            }
        }
    }
}


- (EucEPubBook *)checkOutEucBookForBookWithID:(NSManagedObjectID *)aBookID
{
    EucEPubBook *ret = nil;
    
    [self.persistentStoreCoordinator lock];
    
    NSMutableDictionary *myCachedEucBooks = self.cachedEucBooks;
    @synchronized(myCachedEucBooks) {
        EucEPubBook *previouslyCachedEucBook = [cachedEucBooks objectForKey:aBookID];
        if(previouslyCachedEucBook) {
            //NSLog(@"Returning cached EucBook for book with ID %@", aBookID);
            [self.cachedEucBookCheckoutCounts addObject:aBookID];
            ret = previouslyCachedEucBook;
        } else {
            EucEPubBook *eucBook = nil;
            BlioBook *book = [self bookWithID:aBookID];
            if([book hasEPub]) {
                eucBook = [[BlioEPubBook alloc] initWithBookID:aBookID];
            } else if([book hasTextFlow]) {
                eucBook = [[BlioFlowEucBook alloc] initWithBookID:aBookID];
            }
            if(eucBook) {
                //NSLog(@"Creating and caching EucBook for book with ID %@", aBookID);
                NSCountedSet *myCachedEucBookCheckoutCounts = self.cachedEucBookCheckoutCounts;
                if(!myCachedEucBookCheckoutCounts) {
                    myCachedEucBookCheckoutCounts = [NSCountedSet set];
                    self.cachedEucBookCheckoutCounts = myCachedEucBookCheckoutCounts;
                }
                [myCachedEucBooks setObject:eucBook forKey:aBookID];
                [myCachedEucBookCheckoutCounts addObject:aBookID];
                [eucBook release];
                ret = eucBook;
            }            
        }
    }
    
    [self.persistentStoreCoordinator unlock];
    
    return ret;
}

- (void)checkInEucBookForBookWithID:(NSManagedObjectID *)aBookID
{
    NSMutableDictionary *myCachedEucBooks = self.cachedEucBooks;
    @synchronized(myCachedEucBooks) {
        NSCountedSet *myCachedEucBookCheckoutCounts = self.cachedEucBookCheckoutCounts;
        NSUInteger count = [myCachedEucBookCheckoutCounts countForObject:aBookID];
        if(count == 0) {
            NSLog(@"Warning! Unexpected checkin of non-checked-out Euc book");
        } else {
            [myCachedEucBookCheckoutCounts removeObject:aBookID];
            if (count == 1) {
                //NSLog(@"Releasing cached Euc book for book with ID %@", aBookID);
                [myCachedEucBooks removeObjectForKey:aBookID];
                if(myCachedEucBookCheckoutCounts.count == 0) {
                    // May as well release the set.
                    self.cachedEucBookCheckoutCounts = nil;
                }
            }
        }
    }
}


- (id<BlioParagraphSource>)checkOutParagraphSourceForBookWithID:(NSManagedObjectID *)aBookID
{   
    id<BlioParagraphSource> ret = nil;

    [self.persistentStoreCoordinator lock];
    
    NSMutableDictionary *myCachedParagraphSources = self.cachedParagraphSources;
    @synchronized(myCachedParagraphSources) {
        id<BlioParagraphSource> previouslyCachedParagraphSource = [myCachedParagraphSources objectForKey:aBookID];
        if(previouslyCachedParagraphSource) {
            //NSLog(@"Returning cached ParagraphSource for book with ID %@", aBookID);
            [self.cachedParagraphSourceCheckoutCounts addObject:aBookID];
            ret= previouslyCachedParagraphSource;
        } else {
            id<BlioParagraphSource> paragraphSource = nil;
            BlioBook *book = [self bookWithID:aBookID];
            if([book hasTextFlow]) {
                paragraphSource = [[BlioTextFlowParagraphSource alloc] initWithBookID:aBookID];
            } else if([book hasEPub]) {
                paragraphSource = [[BlioEPubParagraphSource alloc] initWithBookID:aBookID];
            }
            
            if(paragraphSource) {
                //NSLog(@"Creating and caching ParagraphSource for book with ID %@", aBookID);
                NSCountedSet *myCachedParagraphSourceCheckoutCounts = self.cachedParagraphSourceCheckoutCounts;
                if(!myCachedParagraphSourceCheckoutCounts) {
                    myCachedParagraphSourceCheckoutCounts = [NSCountedSet set];
                    self.cachedParagraphSourceCheckoutCounts = myCachedParagraphSourceCheckoutCounts;
                }
                [myCachedParagraphSources setObject:paragraphSource forKey:aBookID];
                [myCachedParagraphSourceCheckoutCounts addObject:aBookID];
                [paragraphSource release];
                ret = paragraphSource;
            }
        }
    }
    
    [self.persistentStoreCoordinator unlock];
    
    return ret;
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
                //NSLog(@"Releasing cached paragraph source for book with ID %@", aBookID);
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
    BlioXPSProvider *ret = nil;

    [self.persistentStoreCoordinator lock];
    
    NSMutableDictionary *myCachedXPSProviders = self.cachedXPSProviders;
    @synchronized(myCachedXPSProviders) {
        BlioXPSProvider *previouslyCachedXPSProvider = [myCachedXPSProviders objectForKey:aBookID];
        if(previouslyCachedXPSProvider) {
            //NSLog(@"Returning cached XPSProvider for book with ID %@", aBookID);
            [self.cachedXPSProviderCheckoutCounts addObject:aBookID];
            ret = previouslyCachedXPSProvider;
        } else {
            BlioBook *book = [self bookWithID:aBookID];
            if(book.xpsPath) {
                BlioXPSProvider *xpsProvider = [[BlioXPSProvider alloc] initWithBookID:aBookID];
                if(xpsProvider) {
                    //NSLog(@"Creating and caching XPSProvider for book with title %@ and ID %@", [book title], aBookID);
                    NSCountedSet *myCachedXPSProviderCheckoutCounts = self.cachedXPSProviderCheckoutCounts;
                    if(!myCachedXPSProviderCheckoutCounts) {
                        myCachedXPSProviderCheckoutCounts = [NSCountedSet set];
                        self.cachedXPSProviderCheckoutCounts = myCachedXPSProviderCheckoutCounts;
                    }
                    [myCachedXPSProviders setObject:xpsProvider forKey:aBookID];
                    [myCachedXPSProviderCheckoutCounts addObject:aBookID];
                    [xpsProvider release];
                    ret = xpsProvider;
                }
            }
        }
    }
    
    //NSLog(@"[%d] checkOutXPSProviderForBookWithID %@", [self.cachedXPSProviderCheckoutCounts countForObject:aBookID], aBookID);

    
    [self.persistentStoreCoordinator unlock];
    
    return ret;
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
                //NSLog(@"Releasing cached XPSProvider for book with ID %@", aBookID);
                [myCachedXPSProviders removeObjectForKey:aBookID];
                if(myCachedXPSProviderCheckoutCounts.count == 0) {
                    // May as well release the set.
                    self.cachedXPSProviderCheckoutCounts = nil;
                }
            }
        }
        //NSLog(@"[%d] checkInXPSProviderForBookWithID %@", [self.cachedXPSProviderCheckoutCounts countForObject:aBookID], aBookID);

    }
}

@end
