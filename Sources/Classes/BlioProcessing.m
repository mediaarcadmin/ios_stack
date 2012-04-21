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
#import <sys/xattr.h>
#import <libEucalyptus/THUIDeviceAdditions.h>

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
    pthread_mutex_lock(&sBookMutationMutex);
    {
        ++mutationCount;
        if(mutationCount != 1) {
            NSLog(@"rrewrewrewrew");
        }
		if (!self.bookID) NSLog(@"WARNING: self.bookID for %@ is nil, flushBookCache will fail!",[self description]);
        BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
        if (nil == book) {
            NSLog(@"Failed to retrieve book in BlioProcessing flushBookCache");
        } else {
            [book flushCaches];
        }
        --mutationCount;
    }
    pthread_mutex_unlock(&sBookMutationMutex);
    
    [pool drain];
}

- (void)reportBookReadingIfRequired {
//	NSLog(@"reportBookReadingIfRequired");
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    pthread_mutex_lock(&sBookMutationMutex);
    {
        ++mutationCount;
        if(mutationCount != 1) {
            NSLog(@"rrewrewrewrew");
        }
        BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
        if (nil == book) {
            NSLog(@"Failed to retrieve book in BlioProcessing reportBookReadingIfRequired");
        } else {
            [book reportReadingIfRequired];
        }
        --mutationCount;
    }
    pthread_mutex_unlock(&sBookMutationMutex);
    
    [pool drain];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	if (self.bookID) [self flushBookCache];
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
            NSLog(@"Failed to retrieve book in BlioProcessing setBookManifestValue:forKey:");
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
            NSLog(@"Failed to retrieve book in BlioProcessing setBookValue:forKey:");
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
        NSLog(@"Failed to retrieve book in BlioProcessing getBookManifestPathForKey:");
        return nil;
    } else {
        return [book manifestPathForKey:key];
    }
}

- (BOOL)hasBookManifestValueForKey:(NSString *)key {
    BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
    if (nil == book) {
        NSLog(@"Failed to retrieve book in BlioProcessing hasBookManifestValueForKey:");
        return NO;
    } else {
        return [book hasManifestValueForKey:key];
    }
}

- (NSData *)getBookManifestDataForKey:(NSString *)key {
    BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
    if (nil == book) {
        NSLog(@"Failed to retrieve book in BlioProcessing getBookManifestDataForKey:");
        return nil;
    } else {
        return [book manifestDataForKey:key];
    }
}

- (NSData *)getBookTextFlowDataWithPath:(NSString *)path {
    BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
    if (nil == book) {
        NSLog(@"Failed to retrieve book in BlioProcessing getBookTextFlowDataWithPath:");
        return nil;
    } else {
        return [book textFlowDataWithPath:path];
    }
}

- (NSData *)getBookXPSDataWithPath:(NSString *)path {
    BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
    if (nil == book) {
        NSLog(@"Failed to retrieve book in BlioProcessing getBookTextFlowDataWithPath:");
        return nil;
    } else {
        return [book XPSDataWithPath:path];
    }
}

- (BOOL)bookHasXPSDataWithPath:(NSString *)path {
    BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
    if (nil == book) {
        NSLog(@"Failed to retrieve book in BlioProcessing bookHasXPSDataWithPath:");
        return NO;
    } else {
        return [book XPSComponentExistsWithPath:path];
    }
}

- (BOOL)bookManifestPath:(NSString *)path existsForLocation:(NSString *)location {
    BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
    if (nil == book) {
        NSLog(@"Failed to retrieve book in BlioProcessing bookManifestPath:existsForLocation:");
        return NO;
    } else {
        return [book manifestPath:path existsForLocation:location];
    }
}

- (id)getBookValueForKey:(NSString *)key {
    BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
    if (nil == book) {
        NSLog(@"Failed to retrieve book in BlioProcessing getBookValueForKey:");
        return nil;
    } else {
        return [book valueForKey:key];
    }
}

-(void) setOperationSuccess:(BOOL)operationOutcome {
	operationSuccess = operationOutcome;
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
	[userInfo setObject:self.bookID forKey:@"bookID"];
	[userInfo setObject:[NSNumber numberWithInt:self.sourceID] forKey:@"sourceID"];
	[userInfo setObject:self.sourceSpecificID forKey:@"sourceSpecificID"];	
	if (operationOutcome) [[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationCompleteNotification object:self userInfo:userInfo];
	else [[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationFailedNotification object:self userInfo:userInfo];
}

-(BOOL) operationSuccess {
	return operationSuccess;
}

-(void) setPercentageComplete:(CGFloat)percentage {
	CGFloat flooredPercentage = floorf(percentage*10)/10;
	if (percentageComplete != flooredPercentage) {
		percentageComplete = flooredPercentage;
		if (![self isCancelled]) {
			NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
			[userInfo setObject:self.bookID forKey:@"bookID"];
			[userInfo setObject:[NSNumber numberWithInt:self.sourceID] forKey:@"sourceID"];
			[userInfo setObject:self.sourceSpecificID forKey:@"sourceSpecificID"];	
			[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationProgressNotification object:self userInfo:userInfo];
		}
	}
}

-(CGFloat) percentageComplete {
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
+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    // for iOS 5.1 and above
    if([[UIDevice currentDevice] compareSystemVersion:@"5.1"] >= NSOrderedSame) {
        NSError * setKeyError = nil;
        [URL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&setKeyError];
        if (setKeyError) {
            NSLog(@"ERROR (addSkipBackupAttributeToItemAtURL 5.1 and above): %@",[setKeyError localizedDescription]);
            return NO;
        }
        return YES;
    }
    // for iOS 5.0.1
    const char* filePath = [[URL path] fileSystemRepresentation];
    
    const char* attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    
    int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
    return result == 0;
}

@end
