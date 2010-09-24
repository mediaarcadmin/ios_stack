//
//  BlioProcessing.m
//  BlioApp
//
//  Created by matt on 25/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioProcessing.h"
#import "BlioBookManager.h"
#import "BlioBook.h"

#import <pthread.h>

@implementation BlioProcessingOperation

static pthread_mutex_t sBookMutationMutex = PTHREAD_MUTEX_INITIALIZER;

static int mutationCount = 0;

@synthesize bookID, sourceID, sourceSpecificID, forceReprocess, cacheDirectory,tempDirectory;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
@synthesize backgroundTaskIdentifier;
#endif

- (id) init {
	if((self = [super init])) {
		operationSuccess = NO;
		forceReprocess = NO;
	}
	return self;
}

- (void)flushBookCache {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSLog(@"Flushing cache from %@", self);
    pthread_mutex_lock(&sBookMutationMutex);
    {
        ++mutationCount;
        if(mutationCount != 1) {
            NSLog(@"rrewrewrewrew");
        }
        BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
        if (nil == book) {
            NSLog(@"Failed to retrieve book");
        } else {
            [book flushCaches];
        }
        --mutationCount;
    }
    pthread_mutex_unlock(&sBookMutationMutex);
    
    [pool drain];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [self flushBookCache];
    
    self.bookID = nil;
	self.sourceSpecificID = nil;
    self.cacheDirectory = nil;
    self.tempDirectory = nil;
    
    [super dealloc];
}

- (void)setBookManifestValue:(id)value forKey:(NSString *)key {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    pthread_mutex_lock(&sBookMutationMutex);
    {
        ++mutationCount;
        if(mutationCount != 1) {
            NSLog(@"rrewrewrewrew");
        }
        BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
        if (nil == book) {
            NSLog(@"Failed to retrieve book");
        } else {
            [book setManifestValue:value forKey:key];
        }
        --mutationCount;
    }
    pthread_mutex_unlock(&sBookMutationMutex);

    [pool drain];
}

- (void)setBookValue:(id)value forKey:(NSString *)key {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    pthread_mutex_lock(&sBookMutationMutex);
    {
        ++mutationCount;
        if(mutationCount != 1) {
            NSLog(@"rrewrewrewrew");
        }        
        BlioBookManager *bookManager = [BlioBookManager sharedBookManager];
        BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
        if (nil == book) {
            NSLog(@"Failed to retrieve book");
        } else {
            [book setValue:value forKey:key];
        }
        NSError *anError;
        if (![bookManager save:&anError]) {
            NSLog(@"[BlioProcessingOperation setBookValue:%@ forKey:%@] Save failed with error: %@, %@", value, key, anError, [anError userInfo]);
        }
        --mutationCount;
    }
    pthread_mutex_unlock(&sBookMutationMutex);
    
    [pool drain];
}

- (NSString *)getBookManifestPathForKey:(NSString *)key {
    BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
    if (nil == book) {
        NSLog(@"Failed to retrieve book");
        return nil;
    } else {
        return [book manifestPathForKey:key];
    }
}

- (BOOL)hasBookManifestValueForKey:(NSString *)key {
    BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
    if (nil == book) {
        NSLog(@"Failed to retrieve book");
        return NO;
    } else {
        return [book hasManifestValueForKey:key];
    }
}

- (NSData *)getBookManifestDataForKey:(NSString *)key {
    BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
    if (nil == book) {
        NSLog(@"Failed to retrieve book");
        return nil;
    } else {
        return [book manifestDataForKey:key];
    }
}

- (NSData *)getBookTextFlowDataWithPath:(NSString *)path {
    BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
    if (nil == book) {
        NSLog(@"Failed to retrieve book");
        return nil;
    } else {
        return [book textFlowDataWithPath:path];
    }
}

- (BOOL)bookManifestPath:(NSString *)path existsForLocation:(NSString *)location {
    BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
    if (nil == book) {
        NSLog(@"Failed to retrieve book");
        return NO;
    } else {
        return [book manifestPath:path existsForLocation:location];
    }
}

- (id)getBookValueForKey:(NSString *)key {
    BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
    if (nil == book) {
        NSLog(@"Failed to retrieve book");
        return nil;
    } else {
        return [book valueForKey:key];
    }
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
    
    NSManagedObject *book = [[BlioBookManager sharedBookManager] bookWithID:bookID];
    
    if (nil == book) {
        NSLog(@"Failed to retrieve book");
        return;
    }
    
    NSManagedObjectContext *moc = [[BlioBookManager sharedBookManager] managedObjectContextForCurrentThread];
    NSFetchRequest *aRequest = [[NSFetchRequest alloc] init];
    [aRequest setEntity:[NSEntityDescription entityForName:@"BlioBook" inManagedObjectContext:moc]];
    [aRequest setPredicate:[NSPredicate predicateWithFormat:@"processingState == %@", [NSNumber numberWithInt:kBlioBookProcessingStateComplete]]];
    
    // Block whilst we calculate the position so that other threads don't perform the same
    // check at the same time
    pthread_mutex_lock(&sBookMutationMutex);
    {
        ++mutationCount;
        if(mutationCount != 1) {
            NSLog(@"rrewrewrewrew");
        }
        
        NSError *anError = nil;
        NSUInteger count = [moc countForFetchRequest:aRequest error:&anError];
        if (count == NSNotFound) {
            NSLog(@"Failed to retrieve book count with error: %@, %@", anError, [anError userInfo]);
        } else {
            [book setValue:[NSNumber numberWithInt:count] forKey:@"libraryPosition"];
            [book setValue:[NSNumber numberWithInt:kBlioBookProcessingStateComplete] forKey:@"processingState"];
        }
        
        if (![moc save:&anError]) {
            NSLog(@"[BlioProcessingOperation setBookProcessingComplete] Save failed with error: %@, %@", anError, [anError userInfo]);
        }
        
        --mutationCount;
    }
    pthread_mutex_unlock(&sBookMutationMutex);
    
    [aRequest release];

    [pool drain];
}

@end
