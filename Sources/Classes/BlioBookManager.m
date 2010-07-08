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
@property (nonatomic, retain) NSMutableDictionary *cachedEPubBooks;
@property (nonatomic, retain) NSMutableDictionary *cachedParagraphSources;
@property (nonatomic, retain) NSMutableDictionary *cachedXpsProviders;

@end

@implementation BlioBookManager

@synthesize persistentStoreCoordinator;

@synthesize cachedTextFlows;
@synthesize cachedEPubBooks;
@synthesize cachedParagraphSources;
@synthesize cachedXpsProviders;

static BlioBookManager *sSharedBookManager = nil;
static pthread_key_t sManagedObjectContextKey;

- (id)init
{
    if((self = [super init])) {
        self.cachedTextFlows = [NSMutableDictionary dictionary];
        self.cachedEPubBooks = [NSMutableDictionary dictionary];
        self.cachedParagraphSources = [NSMutableDictionary dictionary];
        self.cachedXpsProviders = [NSMutableDictionary dictionary];
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


- (BlioTextFlow *)textFlowForBookWithID:(NSManagedObjectID *)aBookID
{
    NSValue *previouslyCachedTextFlow = [self.cachedTextFlows objectForKey:aBookID];
    if(previouslyCachedTextFlow) {
        NSLog(@"Returning cached TextFlow for book with ID %@", aBookID);
        return [[[previouslyCachedTextFlow nonretainedObjectValue] retain] autorelease];
    } else {
        BlioBook *book = [self bookWithID:aBookID];
        if(book.textFlowPath) {
            BlioTextFlow *textFlow = [[BlioTextFlow alloc] initWithBookID:aBookID];
            if(textFlow) {
                NSLog(@"Creating and caching text flow for book with ID %@", aBookID);
                [self.cachedTextFlows setObject:[NSValue valueWithNonretainedObject:textFlow]
                                         forKey:aBookID];
                return [textFlow autorelease];
            }
        }
    }
    return nil;
}

- (void)textFlowIsDeallocingForBookWithID:(NSManagedObjectID *)aBookID
{
    NSLog(@"Releasing cached text flow for book with ID %@", aBookID);
    [self.cachedTextFlows removeObjectForKey:aBookID];
}

- (BlioXPSProvider *)xpsProviderForBookWithID:(NSManagedObjectID *)aBookID
{
    NSValue *previouslyCachedXpsProvider = [self.cachedXpsProviders objectForKey:aBookID];
    if(previouslyCachedXpsProvider) {
        NSLog(@"Returning cached XpsProvider for book with ID %@", aBookID);
        return [[[previouslyCachedXpsProvider nonretainedObjectValue] retain] autorelease];
    } else {
        BlioBook *book = [self bookWithID:aBookID];
        if(book.xpsPath) {
            BlioXPSProvider *xpsProvider = [[BlioXPSProvider alloc] initWithBookID:aBookID];
            if(xpsProvider) {
                NSLog(@"Creating and caching xps provider for book with ID %@", aBookID);
                [self.cachedXpsProviders setObject:[NSValue valueWithNonretainedObject:xpsProvider]
                                         forKey:aBookID];
                return [xpsProvider autorelease];
            }
        }
    }
    return nil;
}

- (void)xpsProviderIsDeallocingForBookWithID:(NSManagedObjectID *)aBookID
{
    NSLog(@"Releasing cached xps provider for book with ID %@", aBookID);
    [self.cachedXpsProviders removeObjectForKey:aBookID];
}


- (BlioEPubBook *)ePubBookForBookWithID:(NSManagedObjectID *)aBookID
{
    NSValue *previouslyCachedEPubBook = [self.cachedEPubBooks objectForKey:aBookID];
    if(previouslyCachedEPubBook) {
        NSLog(@"Returning cached ePub book for book with ID %@", aBookID);
        return [[[previouslyCachedEPubBook nonretainedObjectValue] retain] autorelease];
    } else {
        BlioBook *book = [self bookWithID:aBookID];
        if(book.ePubPath) {
            BlioEPubBook *myEPubBook = [[BlioEPubBook alloc] initWithPath:book.ePubPath];
            if(myEPubBook) {
                NSLog(@"Creating and caching ePub book for book with ID %@", aBookID);
                myEPubBook.blioBookID = aBookID;
                myEPubBook.persistsPositionAutomatically = NO;
                myEPubBook.cacheDirectoryPath = [book.bookCacheDirectory stringByAppendingPathComponent:@"libEucalyptusCache"];
                [self.cachedEPubBooks setObject:[NSValue valueWithNonretainedObject:myEPubBook]
                                         forKey:aBookID];
                return [myEPubBook autorelease];
            }
        }
    }
    return nil;
}

- (void)ePubBookIsDeallocingForBookWithID:(NSManagedObjectID *)aBookID
{
    NSLog(@"Releasing cached ePub book for book with ID %@", aBookID);
    [self.cachedEPubBooks removeObjectForKey:aBookID];
}


- (id<BlioParagraphSource>)paragraphSourceForBookWithID:(NSManagedObjectID *)aBookID
{   
    NSValue *previouslyCachedParagraphSource = [self.cachedParagraphSources objectForKey:aBookID];
    if(previouslyCachedParagraphSource) {
        NSLog(@"Returning cached paragraph source for book with ID %@", aBookID);
        return [[[previouslyCachedParagraphSource nonretainedObjectValue] retain] autorelease];
    } else {
        BlioTextFlow *myTextFlow = [self textFlowForBookWithID:aBookID];
        id<BlioParagraphSource> myParagraphSource = nil;
        if (myTextFlow) {
            myParagraphSource = [[BlioTextFlowParagraphSource alloc] initWithTextFlow:myTextFlow];
        } else {
            BlioEPubBook *myEPubBook = [self ePubBookForBookWithID:aBookID];
            if(myEPubBook) {
                myParagraphSource = [[BlioEPubParagraphSource alloc] initWithEPubBook:myEPubBook];
            }
        }
        if(myParagraphSource) {
            NSLog(@"Creating and caching paragraph source for book with ID %@", aBookID);
            [self.cachedParagraphSources setObject:[NSValue valueWithNonretainedObject:myParagraphSource]
                                            forKey:aBookID];
            return [myParagraphSource autorelease];
        }
    }
    return nil;
}

- (void)paragraphSourceIsDeallocingForBookWithID:(NSManagedObjectID *)aBookID
{
    NSLog(@"Releasing cached paragraph source for book with ID %@", aBookID);
    [self.cachedParagraphSources removeObjectForKey:aBookID];
}

@end
