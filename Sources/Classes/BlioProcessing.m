//
//  BlioProcessing.m
//  BlioApp
//
//  Created by matt on 25/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioProcessing.h"
#import "BlioMockBook.h"

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

- (void)setBookValue:(id)value forKey:(NSString *)key {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init]; 
    [moc setPersistentStoreCoordinator:self.storeCoordinator]; 
    NSManagedObject *book = [moc objectWithID:self.bookID];
    if (nil == book) 
        NSLog(@"Failed to retrieve book");
    else
        [book setValue:value forKey:key];
    
    NSError *anError;
    if (![moc save:&anError]) {
        NSLog(@"Save failed with error: %@, %@", anError, [anError userInfo]);
    }
    
    [moc release];
    
    [pool drain];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationProgressNotification object:self];
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
    [aRequest setEntity:[NSEntityDescription entityForName:@"BlioMockBook" inManagedObjectContext:moc]];
    [aRequest setPredicate:[NSPredicate predicateWithFormat:@"processingState == %@", [NSNumber numberWithInt:kBlioMockBookProcessingStateComplete]]];
    
    // Block whilst we calculate the position so that other threads don't perform the same
    // check at the same time
        NSError *anError;
    @synchronized (self.storeCoordinator) {
        NSUInteger count = [moc countForFetchRequest:aRequest error:&anError];
        if (count == NSNotFound) {
            NSLog(@"Failed to retrieve book count with error: %@, %@", anError, [anError userInfo]);
        } else {
            [book setValue:[NSNumber numberWithInt:count] forKey:@"libraryPosition"];
            [book setValue:[NSNumber numberWithInt:kBlioMockBookProcessingStateComplete] forKey:@"processingState"];
        }
        
        NSError *anError;
        if (![moc save:&anError]) {
            NSLog(@"Save failed with error: %@, %@", anError, [anError userInfo]);
        }
    }
    
    [aRequest release];
    [moc release];

    [pool drain];
}

@end
