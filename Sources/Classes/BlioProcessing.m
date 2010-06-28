//
//  BlioProcessing.m
//  BlioApp
//
//  Created by matt on 25/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioProcessing.h"
#import "BlioBook.h"

NSString * const BlioProcessingOperationStartNotification = @"BlioProcessingOperationStartNotification";
NSString * const BlioProcessingOperationProgressNotification = @"BlioProcessingOperationProgressNotification";
NSString * const BlioProcessingOperationCompleteNotification = @"BlioProcessingOperationCompleteNotification";
NSString * const BlioProcessingOperationFailedNotification = @"BlioProcessingOperationFailedNotification";

@implementation BlioProcessingOperation

@synthesize bookID, sourceID, sourceSpecificID, storeCoordinator, forceReprocess, cacheDirectory,tempDirectory;
- (id) init {
	if((self = [super init])) {
		operationSuccess = NO;
		forceReprocess = NO;
	}
	return self;
}
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    self.bookID = nil;
	self.sourceSpecificID = nil;
    self.storeCoordinator = nil;
    self.cacheDirectory = nil;
    self.tempDirectory = nil;
    [super dealloc];
}

- (void)setBookManifestValue:(id)value forKey:(NSString *)key {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init]; 
    [moc setPersistentStoreCoordinator:self.storeCoordinator]; 
    @synchronized (self.storeCoordinator) {
        BlioBook *book = (BlioBook *)[moc objectWithID:self.bookID];
        if (nil == book) {
            NSLog(@"Failed to retrieve book");
        } else {
            [book setManifestValue:value forKey:key];
        }
        
        //NSError *anError;
//        if (![moc save:&anError]) {
//            NSLog(@"[BlioProcessingOperation setManifestValue:%@ forKey:%@] Save failed with error: %@, %@", value, key, anError, [anError userInfo]);
//        }
    }
    [moc release];
    
    [pool drain];
}

- (void)setBookValue:(id)value forKey:(NSString *)key {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init]; 
    [moc setPersistentStoreCoordinator:self.storeCoordinator]; 
    @synchronized (self.storeCoordinator) {
    NSManagedObject *book = [moc objectWithID:self.bookID];
    if (nil == book) 
        NSLog(@"Failed to retrieve book");
    else
        [book setValue:value forKey:key];
    
    NSError *anError;
    if (![moc save:&anError]) {
        NSLog(@"[BlioProcessingOperation setBookValue:%@ forKey:%@] Save failed with error: %@, %@", value, key, anError, [anError userInfo]);
    }
    }
    [moc release];
    
    [pool drain];
}

- (NSString *)getBookManifestPathForKey:(NSString *)key {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init]; 
    [moc setPersistentStoreCoordinator:self.storeCoordinator]; 
    BlioBook *book = (BlioBook *)[moc objectWithID:self.bookID];
    
    if (nil == book) {
        NSLog(@"Failed to retrieve book");
        [moc release];
        [pool drain];
        return nil;
    } 
    
    NSString *path = [[book manifestPathForKey:key] retain];
    [moc release];
    [pool drain];
    return [path autorelease];
}

- (NSData *)getBookManifestDataForKey:(NSString *)key {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init]; 
    [moc setPersistentStoreCoordinator:self.storeCoordinator]; 
    BlioBook *book = (BlioBook *)[moc objectWithID:self.bookID];
    
    if (nil == book) {
        NSLog(@"Failed to retrieve book");
        [moc release];
        [pool drain];
        return nil;
    } 
    
    NSData *data = [[book manifestDataForKey:key] retain];
    [moc release];
    [pool drain];
    return [data autorelease];
}

- (id)getBookValueForKey:(NSString *)key {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init]; 
    [moc setPersistentStoreCoordinator:self.storeCoordinator]; 
    NSManagedObject *book = [moc objectWithID:self.bookID];
    
    if (nil == book) {
        NSLog(@"Failed to retrieve book");
        [moc release];
        [pool drain];
        return nil;
    } 
    
    id value = [[book valueForKey:key] retain];
    [moc release];
    [pool drain];
	[value autorelease];
    return value;
}

-(void) setOperationSuccess:(BOOL)operationOutcome {
	operationSuccess = operationOutcome;
	if (operationOutcome) [[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationCompleteNotification object:self];
	else [[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationFailedNotification object:self];
}
-(BOOL) operationSuccess {
	return operationSuccess;
}
-(void) setPercentageComplete:(NSUInteger)percentage {
	percentageComplete = percentage;
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	[userInfo setObject:self.bookID forKey:@"bookID"];
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationProgressNotification object:self userInfo:userInfo];
}
-(NSUInteger) percentageComplete {
	return percentageComplete;
}
- (void)setBookProcessingComplete {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init]; 
    [moc setPersistentStoreCoordinator:self.storeCoordinator];
    NSManagedObject *book = [moc objectWithID:self.bookID];
    
    if (nil == book) {
        [moc release];
        NSLog(@"Failed to retrieve book");
        return;
    }
    
    NSFetchRequest *aRequest = [[NSFetchRequest alloc] init];
    [aRequest setEntity:[NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:moc]];
    [aRequest setPredicate:[NSPredicate predicateWithFormat:@"processingState == %@", [NSNumber numberWithInt:kBlioBookProcessingStateComplete]]];
    
    // Block whilst we calculate the position so that other threads don't perform the same
    // check at the same time
        NSError *anError;
    @synchronized (self.storeCoordinator) {
        NSUInteger count = [moc countForFetchRequest:aRequest error:&anError];
        if (count == NSNotFound) {
            NSLog(@"Failed to retrieve book count with error: %@, %@", anError, [anError userInfo]);
        } else {
            [book setValue:[NSNumber numberWithInt:count] forKey:@"libraryPosition"];
            [book setValue:[NSNumber numberWithInt:kBlioBookProcessingStateComplete] forKey:@"processingState"];
        }
        
        NSError *anError;
        if (![moc save:&anError]) {
            NSLog(@"[BlioProcessingOperation setBookProcessingComplete] Save failed with error: %@, %@", anError, [anError userInfo]);
        }
    }
    
    [aRequest release];
    [moc release];

    [pool drain];
}

@end
