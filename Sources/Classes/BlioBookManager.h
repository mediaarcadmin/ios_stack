//
//  BlioBookManager.h
//  BlioApp
//
//  Created by James Montgomerie on 06/07/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BlioBook, BlioTextFlow, BlioEPubBook, BlioXPSProvider;
@protocol BlioParagraphSource;

@interface BlioBookManager : NSObject {
}

+ (BlioBookManager *)sharedBookManager;

// Setup:

// Should be set once, before any other methods are called.
@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;

// Semi-public.  Safe to call, but generally not required:
// Can be set, but will br created automatically if none is set.
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContextForCurrentThread;

// Saves the current thread's managed object context.
- (BOOL)save:(NSError **)error;


// Public methods:
// Returns an object that should be used only on the thread the call is made from.
// Remember to lock before this call, and only unlock after calling save if 
// you're planning to modify the book and other threads might be modifying 
// it simultaneously!
- (BlioBook *)bookWithID:(NSManagedObjectID *)aBookID;


// Public methods - however, generally, using the accessors in BlioBook for 
// these if you already have a BlioBook instance is preferrable:

// Returns a thread-safe object; May be passed between threads.
- (BlioTextFlow *)textFlowForBookWithID:(NSManagedObjectID *)aBookID;

// Returns a thread-safe object; May be passed between threads.
- (BlioEPubBook *)ePubBookForBookWithID:(NSManagedObjectID *)aBookID;

// Returns a thread-safe object; May be passed between threads.
- (id <BlioParagraphSource>)paragraphSourceForBookWithID:(NSManagedObjectID *)aBookID;

// Returns a thread-safe object; May be passed between threads.
- (BlioXPSProvider *)xpsProviderForBookWithID:(NSManagedObjectID *)aBookID;


- (void)textFlowIsDeallocingForBookWithID:(NSManagedObjectID *)aBookID;
- (void)ePubBookIsDeallocingForBookWithID:(NSManagedObjectID *)aBookID;
- (void)paragraphSourceIsDeallocingForBookWithID:(NSManagedObjectID *)aBookID;
- (void)xpsProviderIsDeallocingForBookWithID:(NSManagedObjectID *)aBookID;

@end
