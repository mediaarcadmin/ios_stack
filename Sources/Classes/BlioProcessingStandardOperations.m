//
//  BlioProcessingOperations.m
//  BlioApp
//
//  Created by matt on 25/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioProcessingStandardOperations.h"
#import "ZipArchive.h"
//#import "BlioDrmManager.h"
#import "BlioDrmSessionManager.h"
#import "NSString+BlioAdditions.h"
#import "BlioAlertManager.h"
#import "BlioStoreManager.h"
#import "Reachability.h"

@implementation BlioProcessingCompleteOperation

@synthesize alreadyCompletedOperations;

- (id) init {
	if((self = [super init])) {
	}
	return self;
}

- (void)main {
    if ([self isCancelled]) {
		NSLog(@"BlioProcessingCompleteOperation cancelled before starting (perhaps due to pause, broken internet connection, crash, or application exit)");
		return;
	}
	NSLog(@"CompleteOperation dependencies: %@",[self dependencies]);
	NSInteger currentProcessingState = [[self getBookValueForKey:@"processingState"] intValue];
//	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
//	[userInfo setObject:self.bookID forKey:@"bookID"];
//	[userInfo setObject:[NSNumber numberWithInt:self.sourceID] forKey:@"sourceID"];
//	[userInfo setObject:self.sourceSpecificID forKey:@"sourceSpecificID"];
	for (BlioProcessingOperation * blioOp in [self dependencies]) {
		if (!blioOp.operationSuccess) {
			NSLog(@"BlioProcessingCompleteOperation: failed dependency found! Operation: %@ Sending Failed Notification...",blioOp);
			if (currentProcessingState != kBlioBookProcessingStateNotSupported && currentProcessingState != kBlioBookProcessingStatePaused && currentProcessingState != kBlioBookProcessingStateSuspended) [self setBookValue:[NSNumber numberWithInt:kBlioBookProcessingStateFailed] forKey:@"processingState"];
//			[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationFailedNotification object:self userInfo:userInfo];
			[self cancel];
			self.operationSuccess = NO;
			return;
		}
//		NSLog(@"completed operation: %@ percentageComplete: %u",blioOp,blioOp.percentageComplete);
	}	
	// delete temp download dir
	NSString * dirPath = [self.tempDirectory stringByStandardizingPath];
	NSError * downloadDirError;
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	UIApplication *application = [UIApplication sharedApplication];
	if([application respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)]) {
		self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:nil];
	}
#endif
	
    if (currentProcessingState == kBlioBookProcessingStateNotProcessed) [self setBookValue:[NSNumber numberWithInt:kBlioBookProcessingStatePlaceholderOnly] forKey:@"processingState"];
	else if (currentProcessingState != kBlioBookProcessingStateNotSupported) [self setBookValue:[NSNumber numberWithInt:kBlioBookProcessingStateComplete] forKey:@"processingState"];
	NSLog(@"Processing complete for book with sourceID:%i sourceSpecificID:%@", [self sourceID],[self sourceSpecificID]);
	
	if (![[NSFileManager defaultManager] removeItemAtPath:dirPath error:&downloadDirError]) {
		NSLog(@"Failed to delete download directory %@ with error %@ : %@", dirPath, downloadDirError, [downloadDirError userInfo]);
	}
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	if([application respondsToSelector:@selector(endBackgroundTask:)]) {
		if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) [application endBackgroundTask:backgroundTaskIdentifier];	
	}
#endif
	
//	[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationCompleteNotification object:self userInfo:userInfo];
	self.operationSuccess = YES;
}
- (void)addDependency:(NSOperation *)operation {
	[super addDependency:operation];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingProgressNotification:) name:BlioProcessingOperationProgressNotification object:operation];
}
- (void)removeDependency:(NSOperation *)operation {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioProcessingOperationProgressNotification object:operation];
	[super removeDependency:operation];
}
- (void)onProcessingProgressNotification:(NSNotification*)note {
	[self calculateProgress];
}
- (void)calculateProgress {
//	NSLog(@"alreadyCompletedOperations: %u",alreadyCompletedOperations);
	float collectiveProgress = 0.0f;
//	NSLog(@"self.dependencies: %@",self.dependencies);
	for (NSOperation* op in self.dependencies) {
		if ([op isKindOfClass:[BlioProcessingOperation class]]) {
			collectiveProgress = collectiveProgress + ((BlioProcessingOperation*)op).percentageComplete;
		}
		else {
			if (op.isFinished) collectiveProgress = collectiveProgress + 100;
			else if (op.isExecuting) collectiveProgress = collectiveProgress + 50;
			else if (op.isCancelled) NSLog(@"NSOperation of class %@ cancelled.",[[op class] description]);
		}
	}
	NSUInteger newPercentageComplete = ((collectiveProgress+alreadyCompletedOperations*100)/([self.dependencies count]+alreadyCompletedOperations));
	if (newPercentageComplete != self.percentageComplete) {
		self.percentageComplete = newPercentageComplete;
	}
}
- (void) dealloc {
//	NSLog(@"BlioProcessingCompleteOperation dealloc entered");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}
@end

@implementation BlioProcessingPreAvailabilityCompleteOperation

@synthesize filenameKey;

- (void)main {
    if ([self isCancelled]) {
		NSLog(@"BlioProcessingPreAvailabilityCompleteOperation cancelled before starting (perhaps due to pause, broken internet connection, crash, or application exit)");
		[self cancel];
		return;
	}
	for (BlioProcessingOperation * blioOp in [self dependencies]) {
		if (!blioOp.operationSuccess) {
			NSLog(@"BlioProcessingPreAvailabilityCompleteOperation: failed dependency found! Operation: %@",blioOp);
			[self cancel];
			return;
		}
	}
	BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
	self.operationSuccess = YES;
	self.percentageComplete = 100;
	
	NSDictionary *manifestEntry = [NSMutableDictionary dictionary];
	[manifestEntry setValue:[book manifestLocationForKey:self.filenameKey] forKey:BlioManifestEntryLocationKey];
	[manifestEntry setValue:[book manifestRelativePathForKey:self.filenameKey] forKey:BlioManifestEntryPathKey];
	[manifestEntry setValue:[NSNumber numberWithBool:YES] forKey:BlioManifestPreAvailabilityCompleteKey];
	 // WARNING: this may need to change if more manifest keys are added to a manifest entry!
	[self setBookManifestValue:manifestEntry forKey:self.filenameKey];
//	NSLog(@"BlioProcessingPreAvailabilityCompleteOperation complete for key: %@",self.filenameKey);
}

- (void) dealloc {
	//	NSLog(@"BlioProcessingStatusCompleteOperation dealloc entered");
	[super dealloc];
}
@end


#pragma mark -
@implementation BlioProcessingLicenseAcquisitionOperation

@synthesize attemptsMade, attemptsMaximum;

- (id)init {
    if((self = [super init])) {
        attemptsMade = 0;
		attemptsMaximum = 3;	
    }
    
    return self;
}

- (void)main {
	for (BlioProcessingOperation * blioOp in [self dependencies]) {
		if (!blioOp.operationSuccess) {
			NSLog(@"failed dependency found: %@",blioOp);
			[self cancel];
			break;
		}
	}
	
	if ([self isCancelled]) {
		NSLog(@"BlioProcessingLicenseAcquisitionOperation cancelled before starting (perhaps due to pause, broken internet connection, crash, or application exit)");
		return;
	}
	
	BOOL isEncrypted = [self bookManifestPath:BlioXPSKNFBDRMHeaderFile existsForLocation:BlioManifestEntryLocationXPS];
	if (!isEncrypted) {
        self.operationSuccess = YES;
		self.percentageComplete = 100;
		NSLog(@"book not encrypted! aborting License operation...");
		return;
	} else {
        NSMutableDictionary *manifestEntry = [NSMutableDictionary dictionary];
		[manifestEntry setValue:BlioManifestEntryLocationXPS forKey:BlioManifestEntryLocationKey];
		[manifestEntry setValue:BlioXPSKNFBDRMHeaderFile forKey:BlioManifestEntryPathKey];
		[self setBookManifestValue:manifestEntry forKey:BlioManifestDrmHeaderKey];
	}
	
	
	if ([[self getBookValueForKey:@"sourceID"] intValue] != BlioBookSourceOnlineStore) {
		NSLog(@"ERROR: Title (%@) is not an online store title!",[self getBookValueForKey:@"title"]);
		NSLog(@"xpsFilename: %@", [self getBookManifestPathForKey:BlioManifestXPSKey]);
		// TODO: remove the following two lines for final version (we're bypassing for now since Three Little Pigs doesn't need a license)
		self.operationSuccess = YES;
		self.percentageComplete = 100;
		return;
	}
    
	if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
		NSLog(@"Internet connection is dead, will prematurely abort main");
		[self cancel];
    }
	
	if ([[BlioStoreManager sharedInstance] tokenForSourceID:BlioBookSourceOnlineStore] == nil) {
		NSLog(@"ERROR: no valid token, cancelling BlioProcessingLicenseAcquisitionOperation...");
		[self cancel];
	}
    if ([self isCancelled]) {
		NSLog(@"BlioProcessingLicenseAcquisitionOperation cancelled before starting (perhaps due to pause, broken internet connection, crash, or application exit)");
		return;
	}
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	UIApplication *application = [UIApplication sharedApplication];
	if([application respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)]) {
		self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:nil];
	}
#endif
	
/* 
	@synchronized ([BlioDrmManager getDrmManager]) {
		
		NSInteger cooldownTime = [[BlioDrmManager getDrmManager] licenseCooldownTime];
		if (cooldownTime > 0) {
			NSLog(@"BlioDrmManager still cooling down (%i seconds to go), cancelling BlioProcessingLicenseAcquisitionOperation in the meantime...",cooldownTime);
			[self cancel];		
			return;
		}
		
		while (attemptsMade < attemptsMaximum && self.operationSuccess == NO) {
			NSLog(@"Attempt #%u to acquire license for book title: %@",(attemptsMade+1),[self getBookValueForKey:@"title"]);
            self.operationSuccess = [[BlioDrmManager getDrmManager] getLicenseForBookWithID:self.bookID sessionToken:[[BlioStoreManager sharedInstance] tokenForSourceID:BlioBookSourceOnlineStore]];
			attemptsMade++;
		}

		if (!self.operationSuccess) {
			[[BlioDrmManager getDrmManager] resetLicenseCooldownTimer];
		}
	}
*/
	NSLog(@"sourceSpecificID: %@ licenseOp: %@ getting DRMSessionManager",self.sourceSpecificID,self);
	BlioDrmSessionManager* drmSessionManager = [[BlioDrmSessionManager alloc] initWithBookID:self.bookID]; 
	//NSInteger cooldownTime = [drmSessionManager licenseCooldownTime];
	//if (cooldownTime > 0) {
	//	NSLog(@"BlioDrmManager still cooling down (%i seconds to go), cancelling BlioProcessingLicenseAcquisitionOperation in the meantime...",cooldownTime);
	//	[self cancel];		
	//	return;
	//}
	BOOL acquisitionSuccess = NO;
	while (attemptsMade < attemptsMaximum && acquisitionSuccess == NO) {
		NSLog(@"Attempt #%u to acquire license for book title: %@",(attemptsMade+1),[self getBookValueForKey:@"title"]);
		acquisitionSuccess = [drmSessionManager getLicense:[[BlioStoreManager sharedInstance] tokenForSourceID:BlioBookSourceOnlineStore]];
		attemptsMade++;
	}
	[drmSessionManager release];
	//if (!self.operationSuccess) {
	//	[drmSessionManager resetLicenseCooldownTimer];
	//} 
	self.operationSuccess = acquisitionSuccess;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	if([application respondsToSelector:@selector(endBackgroundTask:)]) {
		if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) [application endBackgroundTask:backgroundTaskIdentifier];	
	}	
#endif
	
	if (self.operationSuccess) self.percentageComplete = 100;
	NSLog(@"sourceSpecificID: %@ licenseOp: %@ reached end of main...",self.sourceSpecificID,self);
/* RESTORE FOR OLD DRM INTERFACE
	else {
		[[BlioDrmManager getDrmManager] startLicenseCooldownTimer];				
	}
*/
}
@end


#pragma mark -

@interface BlioProcessingDownloadOperation (PRIVATE)

-(void)finish;

@end

@implementation BlioProcessingDownloadOperation

@synthesize url, filenameKey, localFilename, tempFilename, connection, headConnection, downloadFile,resume,expectedContentLength;

- (void) dealloc {
//	NSLog(@"BlioProcessingDownloadOperation %@ dealloc entered.",self);
    self.url = nil;
    self.filenameKey = nil;
    self.localFilename = nil;
    self.tempFilename = nil;
	if (self.connection) {
		[self.connection cancel];
	}
	if (self.headConnection) [self.headConnection cancel];
    self.connection = nil;
    self.headConnection = nil;
    self.downloadFile = nil;
    [super dealloc];
}

- (id)initWithUrl:(NSURL *)aURL {
    
//    if (nil == aURL) return nil; // starting with paid books, URLs may be dynamically generated from server.
    
    if((self = [super init])) {
        self.url = aURL;
		self.connection = nil;
		self.headConnection = nil;
		expectedContentLength = NSURLResponseUnknownLength;
        executing = NO;
        finished = NO;
		resume = YES;
    }
    
    return self;
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isExecuting {
    return executing;
}

- (BOOL)isFinished {
    return finished;
}
-(void)cancel {
	[super cancel];
	NSLog(@"Cancelling download...");
	if (self.connection) {
		[self.connection cancel];
	}	
	[self finish];
}

- (void)finish {
    self.connection = nil;
    
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    executing = NO;
    finished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)start {
    
    // Must be performed on main thread
    // See http://www.dribin.org/dave/blog/archives/2009/05/05/concurrent_operations/
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
	for (BlioProcessingOperation * blioOp in [self dependencies]) {
		if (!blioOp.operationSuccess) {
			NSLog(@"failed dependency found: %@",blioOp);
			[self cancel];
			break;
		}
	}
	
    if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
		NSLog(@"Operation cancelled, will prematurely abort start");
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }

	if (self.url == nil) {
        [self willChangeValueForKey:@"isFinished"];
		NSLog(@"URL is nil, will prematurely abort start");
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }

	if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
        [self willChangeValueForKey:@"isFinished"];
		NSLog(@"Internet connection is dead, will prematurely abort start");
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
	
    [self willChangeValueForKey:@"isExecuting"];
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	UIApplication *application = [UIApplication sharedApplication];
	if([application respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)]) {
		self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:nil];
	}
#endif
	
    // create temp download dir
	NSString * dirPath = [self.tempDirectory stringByStandardizingPath];
	NSError * downloadDirError;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
		if (![[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&downloadDirError]) {
			NSLog(@"Failed to create download directory %@ with error %@ : %@", dirPath, downloadDirError, [downloadDirError userInfo]);
		}
	}
    
    if (resume && ![self.url isFileURL]) {
        // downloadHead first
        [self headDownload];			
    }
    else {
        [self startDownload];
    }
}
-(NSString*)temporaryPath {
	return [[self.tempDirectory stringByAppendingPathComponent:self.filenameKey] stringByStandardizingPath];
}
- (void)startDownload {
	
    NSString *temporaryPath = [self temporaryPath];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	/*
    NSString *cachedPath = [[self.cacheDirectory stringByAppendingPathComponent:self.localFilename] stringByStandardizingPath];
	// see if there is no need to downlaod (asset is already present at cachedPath
	if ([fileManager fileExistsAtPath:cachedPath]) {
		[self downloadDidFinishSuccessfully:NO];
		[self finish];
		return;
	}
	*/
	
	if (resume == NO || forceReprocess == YES) {
		// if not resuming, delete whatever is in place
		if ([NSFileHandle fileHandleForWritingAtPath:temporaryPath] != nil) [fileManager removeItemAtPath:temporaryPath error:NULL];
	}
	// ensure there is a file in place
	if ([NSFileHandle fileHandleForWritingAtPath:temporaryPath] == nil) {
		if (![fileManager createFileAtPath:temporaryPath contents:nil attributes:nil]) {
			NSLog(@"Could not create file to hold download at location: %@",temporaryPath);
			[self downloadDidFinishSuccessfully:NO];
			[self finish];
		}
	}
	self.downloadFile = [NSFileHandle fileHandleForWritingAtPath:temporaryPath];
	NSMutableURLRequest *aRequest = [[NSMutableURLRequest alloc] initWithURL:self.url];
//	NSLog(@"about to start connection to URL: %@",[self.url absoluteString]);
	if (resume && forceReprocess == NO) {
		// add range header
		NSError * error = nil;
		NSDictionary * fileAttributes = [fileManager attributesOfItemAtPath:temporaryPath error:&error];
		if (error != nil) {
            NSLog(@"Failed to retrieve file attributes from path:%@ with error %@ : %@", temporaryPath, error, [error userInfo]);
		}
		NSNumber * bytesAlreadyDownloaded = [fileAttributes valueForKey:NSFileSize];
//		NSLog(@"bytesAlreadyDownloaded: %@",[bytesAlreadyDownloaded stringValue]);
		// TODO: add support for etag in header (not a priority now since Feedbooks doesn't seem to support 206 partial content responses, but may be relevant when paid books are downloaded). See http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.27
		if ([bytesAlreadyDownloaded longValue] != 0)
		{
			NSString * rangeString = [NSString stringWithFormat:@"bytes=%@-",[bytesAlreadyDownloaded stringValue]];
			NSLog(@"will use rangeString: %@",rangeString);
			[aRequest addValue:rangeString forHTTPHeaderField:@"Range"];
		}
		else resume = NO;
	}
	NSURLConnection *aConnection = [[NSURLConnection alloc] initWithRequest:aRequest delegate:self];
	[aRequest release];
	
	if (nil == aConnection) {
		[self downloadDidFinishSuccessfully:NO];
		[self finish];
	} else {
		self.connection = aConnection;
		[aConnection release];
	}	
}
- (void)headDownload {	
	// make HEAD HTTP method call to see if server supports Accept-Ranges header
	NSMutableURLRequest *headRequest = [[NSMutableURLRequest alloc] initWithURL:self.url];
	[headRequest setHTTPMethod:@"HEAD"];
	NSURLConnection *hConnection = [[NSURLConnection alloc] initWithRequest:headRequest delegate:self];
	[headRequest release];
	if (nil == hConnection) {
		[self finish];
	} else {
		self.headConnection = hConnection;
		[hConnection release];
	}	
}
- (void)connection:(NSURLConnection *)theConnection didReceiveResponse:(NSURLResponse *)response {
	NSLog(@"connection didReceiveResponse: %@",[[response URL] absoluteString]);
	self.expectedContentLength = [response expectedContentLength];

	NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *) response;
	
	if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]] && theConnection == headConnection) {		
		NSLog(@"httpResponse.statusCode: %i",httpResponse.statusCode);
		if (httpResponse.statusCode/100 != 2) {
			// we are not getting valid response; try again from scratch.
			resume = NO;
			[theConnection cancel];
			[self startDownload];
		}
		else {
			
//			NSLog(@"inspecting header fields...");
			NSString * acceptRanges = nil;
			for (id key in httpResponse.allHeaderFields)
			{
				NSString * keyString = (NSString*)key;
//				NSLog(@"keyString: %@",keyString);
				if ([[keyString lowercaseString] isEqualToString:[@"Accept-Ranges" lowercaseString]]) {
					acceptRanges = [httpResponse.allHeaderFields objectForKey:keyString];
					break;
				}
			}			
			NSLog(@"Accept-Ranges: %@",acceptRanges);
			if (acceptRanges == nil) {
				//  most servers accept byte ranges without explicitly saying so- will try partial download.
				resume = YES;
				[theConnection cancel];
				[self startDownload];
			}
			else if ([acceptRanges isEqualToString:@"none"]) {
				// server definitely does not support accept ranges
				resume = NO;
				[theConnection cancel];
				[self startDownload];
			}
			else if ([acceptRanges isEqualToString:@"bytes"]) {
				// explicitly supports byte ranges
				resume = YES;
				[theConnection cancel];
				[self startDownload];
			} else { // alternative unit
				// if Accept-Ranges is present but not "none", it will most likely accept byte ranges without explicitly saying so- will try partial download.
				resume = YES;
				[theConnection cancel];
				[self startDownload];
			}
		}
	}
	else if (theConnection == connection) {
		if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {  // i.e. we're not a file:// download
			NSLog(@"downloadConnection httpResponse.statusCode: %i",httpResponse.statusCode);
			if (httpResponse.statusCode != 206 && resume == YES && forceReprocess == NO) {
				// we are not getting partial content; try again from scratch.
				// TODO: just erase previous progress and keep using this connection instead of starting from scratch
				resume = NO;
				[theConnection cancel];
				[self startDownload];
			}
		}		
	}
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data {
	if ([self isCancelled]) {
		if (self.headConnection) {
			[self.headConnection cancel];
			self.headConnection = nil;
		}
		if (self.connection) {
			[self.connection cancel];
			self.connection = nil;
		}
		[self willChangeValueForKey:@"isFinished"];
        finished = YES;
		NSLog(@"DownloadOperation cancelled, will prematurely abort NSURLConnection");
        [self didChangeValueForKey:@"isFinished"];
        return;
    }	
    if (self.connection == aConnection) {
//		NSLog(@"connection didReceiveData");
		[self.downloadFile writeData:data];
		if (expectedContentLength != 0 && expectedContentLength != NSURLResponseUnknownLength) {
//			NSLog(@"[self.downloadFile seekToEndOfFile]: %llu",[self.downloadFile seekToEndOfFile]);
//			NSLog(@"expectedContentLength: %lld",expectedContentLength);
			self.percentageComplete = [self.downloadFile seekToEndOfFile]*100/expectedContentLength;
//			NSLog(@"Download operation percentageComplete for asset %@: %u",self.sourceSpecificID,self.percentageComplete);
		}
		else self.percentageComplete = 50;
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
    if (self.connection == aConnection) {
//		NSLog(@"Finished downloading URL: %@",[self.url absoluteString]);
		[self downloadDidFinishSuccessfully:YES];
		[self finish];		
	}
}
- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
	NSLog(@"BlioProcessingDownloadOperation connection:%@ didFailWithError: %@, %@",aConnection,error,[error userInfo]);
    if (self.connection == aConnection) {
		[self downloadDidFinishSuccessfully:NO];
		[self finish];
	}
	else {
		self.resume = NO;
		[self startDownload];
	}
}

- (void)downloadDidFinishSuccessfully:(BOOL)success {
//	if (success) NSLog(@"Download finished successfully"); 
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
	[userInfo setObject:self.bookID forKey:@"bookID"];
	[userInfo setObject:[NSNumber numberWithInt:self.sourceID] forKey:@"sourceID"];
	[userInfo setObject:self.sourceSpecificID forKey:@"sourceSpecificID"];
	if (!success) {
		NSLog(@"BlioProcessingDownloadOperation: Download did not finish successfully");
		NSLog(@"for url: %@",[self.url absoluteString]);
		[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationFailedNotification object:self userInfo:userInfo];		
	}
	else {
		// generate new filename
		NSString *uniqueString = [NSString uniqueStringWithBaseString:[self getBookValueForKey:@"title"]];
		NSString *temporaryPath = [self temporaryPath];
		NSString *cachedPath = [self.cacheDirectory stringByAppendingPathComponent:uniqueString];
		// copy file to final location (cachedPath)
		NSError * error;
		if (![[NSFileManager defaultManager] moveItemAtPath:temporaryPath toPath:cachedPath error:&error]) {
            NSLog(@"Failed to move file from download cache %@ to final location %@ with error %@ : %@", temporaryPath, cachedPath, error, [error userInfo]);

        }
		else {
			//[self setBookValue:[NSString stringWithString:(NSString *)uniqueString] forKey:self.filenameKey];
            NSDictionary *manifestEntry = [NSMutableDictionary dictionary];
            [manifestEntry setValue:BlioManifestEntryLocationFileSystem forKey:BlioManifestEntryLocationKey];
            [manifestEntry setValue:(NSString *)uniqueString forKey:BlioManifestEntryPathKey];
            
            [self setBookValue:[NSString stringWithString:(NSString *)uniqueString] forKey:self.filenameKey];
            [self setBookManifestValue:manifestEntry forKey:self.filenameKey];
			self.operationSuccess = YES;
			self.percentageComplete = 100;
			[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationCompleteNotification object:self userInfo:userInfo];			
		}
	}
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	UIApplication *application = [UIApplication sharedApplication];
	if([application respondsToSelector:@selector(endBackgroundTask:)]) {
		if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) [application endBackgroundTask:backgroundTaskIdentifier];	
	}	
#endif
	
}

@end

#pragma mark -
@implementation BlioProcessingDownloadPaidBookOperation

- (id)initWithUrl:(NSURL *)aURL {
    if ((self = [super initWithUrl:aURL])) {
		self.filenameKey = BlioManifestXPSKey;
    }
    return self;
}
- (void)start {
	for (BlioProcessingOperation * blioOp in [self dependencies]) {
		if (!blioOp.operationSuccess) {
			NSLog(@"failed dependency found: %@",blioOp);
			[self cancel];
			break;
		}
	}	
	if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
		NSLog(@"Operation cancelled, will prematurely abort start");
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
	
	if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
        [self willChangeValueForKey:@"isFinished"];
		NSLog(@"Internet connection is dead, will prematurely abort start");
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
	
	if (self.url == nil) {
		if ([[BlioStoreManager sharedInstance] tokenForSourceID:self.sourceID]) {
			// app will contact Store for a new limited-lifetime URL.
			NSURL * newXPSURL = [[BlioStoreManager sharedInstance] URLForBookWithSourceID:sourceID sourceSpecificID:sourceSpecificID];
			if (newXPSURL) {
				NSLog(@"new XPS URL: %@",[newXPSURL absoluteString]);
				self.url = newXPSURL;
				
//				// set manifest location for record-keeping purposes (though the app will likely request a new URL at a later time should this one fail now.)
//				NSDictionary *manifestEntry = [NSMutableDictionary dictionary];
//				[manifestEntry setValue:BlioManifestEntryLocationWeb forKey:BlioManifestEntryLocationKey];
//				[manifestEntry setValue:[newXPSURL absoluteString] forKey:BlioManifestEntryPathKey];
//				[self setBookManifestValue:manifestEntry forKey:BlioManifestXPSKey];		
			}
			else {
				NSLog(@"new XPS URL was not able to be obtained from server! Cancelling BlioProcessingDownloadPaidBookOperation...");
				[self cancel];
				return;
			}
		}
		else {
			NSLog(@"App does not have valid token! Cancelling BlioProcessingDownloadPaidBookOperation...");
			[self cancel];
			return;
		}
	}
	[super start];
}
@end

#pragma mark -
@implementation BlioProcessingXPSManifestOperation

@synthesize audiobookReferencesParser, rightsParser, metadataParser, featureCompatibilityDictionary, audioFiles, timingFiles;

- (id)init {
    if ((self = [super init])) {
		self.audioFiles = [NSMutableArray array];
		self.timingFiles = [NSMutableArray array];
    }
    return self;
}
- (void)dealloc {
	self.audiobookReferencesParser = nil;
	self.rightsParser = nil;
	self.metadataParser = nil;
	self.audioFiles = nil;
	self.timingFiles = nil;
	self.featureCompatibilityDictionary = nil;
	[super dealloc];
}

-(void)main {
	for (BlioProcessingOperation * blioOp in [self dependencies]) {
		if (!blioOp.operationSuccess) {
			NSLog(@"BlioProcessingXPSManifestOperation: %@ failed dependency found: %@",self,blioOp);
			[self cancel];
			break;
		}
	}	
	if ([self isCancelled]) {
		NSLog(@"BlioProcessingXPSManifestOperation cancelled before starting (perhaps due to pause, broken internet connection, crash, or application exit)");
		return;
	}
	
	NSDictionary *manifestEntry;
		
	BOOL hasTextflowData = [self bookManifestPath:BlioXPSTextFlowSectionsFile existsForLocation:BlioManifestEntryLocationXPS];
	if (hasTextflowData) {
		manifestEntry = [NSMutableDictionary dictionary];
		[manifestEntry setValue:BlioManifestEntryLocationXPS forKey:BlioManifestEntryLocationKey];
		[manifestEntry setValue:BlioXPSTextFlowSectionsFile forKey:BlioManifestEntryPathKey];
		[self setBookManifestValue:manifestEntry forKey:BlioManifestTextFlowKey];
	}
	
	BOOL hasCoverData = [self bookManifestPath:BlioXPSCoverImage existsForLocation:BlioManifestEntryLocationXPS];
	if (hasCoverData) {
		manifestEntry = [NSMutableDictionary dictionary];
		[manifestEntry setValue:BlioManifestEntryLocationXPS forKey:BlioManifestEntryLocationKey];
		[manifestEntry setValue:BlioXPSCoverImage forKey:BlioManifestEntryPathKey];
		[self setBookManifestValue:manifestEntry forKey:BlioManifestCoverKey];
	}
	
	BOOL hasThumbnailData = [self bookManifestPath:BlioXPSMetaDataDir existsForLocation:BlioManifestEntryLocationXPS];
	if (hasThumbnailData) {
		manifestEntry = [NSMutableDictionary dictionary];
		[manifestEntry setValue:BlioManifestEntryLocationXPS forKey:BlioManifestEntryLocationKey];
		[manifestEntry setValue:BlioXPSMetaDataDir forKey:BlioManifestEntryPathKey];
		[self setBookManifestValue:manifestEntry forKey:BlioManifestThumbnailDirectoryKey];
	}
	
	BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
//	NSLog(@"[book isEncrypted]: %i",[book isEncrypted]);
	if ([book isEncrypted]) {
		BOOL hasRightsData = [self bookManifestPath:BlioXPSKNFBRightsFile existsForLocation:BlioManifestEntryLocationXPS];
		if (hasRightsData) {
			manifestEntry = [NSMutableDictionary dictionary];
			[manifestEntry setValue:BlioManifestEntryLocationXPS forKey:BlioManifestEntryLocationKey];
			[manifestEntry setValue:BlioXPSKNFBRightsFile forKey:BlioManifestEntryPathKey];
			[self setBookManifestValue:manifestEntry forKey:BlioManifestRightsKey];
			
			// Parse Rights file and modify book attributes accordingly
			NSData * data = [self getBookManifestDataForKey:BlioManifestRightsKey];
			if (data) {
				// test to see if valid XML found
//				NSString * stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//				NSLog(@"stringData: %@",stringData);
//				[stringData release];
				self.rightsParser = [[[NSXMLParser alloc] initWithData:data] autorelease];
				[rightsParser setDelegate:self];
				[rightsParser parse];
			}
		}
	}
	else {
		[self setBookValue:[NSNumber numberWithBool:NO] forKey:@"hasAudiobookRights"]; 
		[self setBookValue:[NSNumber numberWithBool:YES] forKey:@"reflowRight"]; 
	}
	
	BOOL hasAudiobook = [self bookManifestPath:BlioXPSAudiobookMetadataFile existsForLocation:BlioManifestEntryLocationXPS];
	NSLog(@"self.cacheDirectory %@ hasAudiobook: %i,",self.cacheDirectory, hasAudiobook);
	if (hasAudiobook) {
		NSLog(@"setting Audiobook values in manifest...");
		
		// TODO: the following line is temporary! we're setting hasAudiobookRights to true unconditionally when an audiobook is found so that the audiobook in "There Was An Old Lady" can be used (the book is currently not encrypted).
		// [self setBookValue:[NSNumber numberWithBool:YES] forKey:@"hasAudiobookRights"]; 
		
		manifestEntry = [NSMutableDictionary dictionary];
		[manifestEntry setValue:BlioManifestEntryLocationXPS forKey:BlioManifestEntryLocationKey];
		[manifestEntry setValue:BlioXPSAudiobookDirectory forKey:BlioManifestEntryPathKey];
		[self setBookManifestValue:manifestEntry forKey:BlioManifestAudiobookKey];
		
		manifestEntry = [NSMutableDictionary dictionary];
		[manifestEntry setValue:BlioManifestEntryLocationXPS forKey:BlioManifestEntryLocationKey];
		[manifestEntry setValue:BlioXPSAudiobookMetadataFile forKey:BlioManifestEntryPathKey];
		[self setBookManifestValue:manifestEntry forKey:@"audiobookMetadataFilename"];
		
		manifestEntry = [NSMutableDictionary dictionary];
		[manifestEntry setValue:BlioManifestEntryLocationXPS forKey:BlioManifestEntryLocationKey];
		[manifestEntry setValue:BlioXPSAudiobookReferencesFile forKey:BlioManifestEntryPathKey];
		[self setBookManifestValue:manifestEntry forKey:@"audiobookReferencesFilename"];
		
		NSData * data = [self getBookManifestDataForKey:@"audiobookReferencesFilename"];
		if (data) {
			// test to see if valid XML found
//			NSString * stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//			NSLog(@"stringData: %@",stringData);
//			[stringData release];
			self.audiobookReferencesParser = [[[NSXMLParser alloc] initWithData:data] autorelease];
			[audiobookReferencesParser setDelegate:self];
			[audiobookReferencesParser parse];
		}
		//			NSLog(@"[book audioRights]: %i",[book audioRights]);
		//			NSLog(@"[book hasManifestValueForKey:@audiobookMetadataFilename]: %i",[book hasManifestValueForKey:@"audiobookMetadataFilename"]);
	}
	
	BOOL hasKNFBMetadata = [self bookManifestPath:BlioXPSKNFBMetadataFile existsForLocation:BlioManifestEntryLocationXPS];
	if (hasKNFBMetadata) {
		NSLog(@"Metadata file is present. parsing XML...");
		manifestEntry = [NSMutableDictionary dictionary];
		[manifestEntry setValue:BlioManifestEntryLocationXPS forKey:BlioManifestEntryLocationKey];
		[manifestEntry setValue:BlioXPSKNFBMetadataFile forKey:BlioManifestEntryPathKey];
		[self setBookManifestValue:manifestEntry forKey:BlioManifestKNFBMetadataKey];
		
		// Parse Metadata file and modify book attributes accordingly
		NSData * data = [self getBookManifestDataForKey:BlioManifestKNFBMetadataKey];
		if (data) {
			// test to see if valid XML found
//			NSString * stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//			NSLog(@"stringData: %@",stringData);
//			[stringData release];
			self.metadataParser = [[[NSXMLParser alloc] initWithData:data] autorelease];
			[metadataParser setDelegate:self];
			[metadataParser parse];
		}
	}
	
	if ([self isCancelled]) {
		NSLog(@"BlioProcessingXPSManifestOperation cancelled at end - likely due to incompatible features encountered in the book Metadata.xml.");
		self.operationSuccess = NO;
		return;
	}
	self.operationSuccess = YES;
	self.percentageComplete = 100;	
}

#pragma mark -
#pragma mark NSXMLParserDelegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	//	NSLog(@"didStartElement: %@",elementName);
	if (parser == self.audiobookReferencesParser) {
		if ( [elementName isEqualToString:@"Audio"] ) {
			NSString * audioFile = [attributeDict objectForKey:@"src"];
			
			if (audioFile) {
				audioFile = [BlioXPSAudiobookDirectory stringByAppendingPathComponent:audioFile];
				[self.audioFiles addObject:audioFile];
			}
		}
		else if ( [elementName isEqualToString:@"Timing"] ) {		
			NSString * timingFile = [attributeDict objectForKey:@"src"];
			
			if (timingFile) {
				timingFile = [BlioXPSAudiobookDirectory stringByAppendingPathComponent:timingFile];
				[self.timingFiles addObject:timingFile];
			}
		}
	}	
	else if (parser == self.rightsParser) {
		if ( [elementName isEqualToString:@"Audio"] ) {
			NSString * attributeStringValue = [attributeDict objectForKey:@"TTSRead"];
			if (attributeStringValue && [attributeStringValue isEqualToString:@"True"]) {
				[self setBookValue:[NSNumber numberWithBool:NO] forKey:@"hasAudiobookRights"]; 
			}
			else {
				[self setBookValue:[NSNumber numberWithBool:YES] forKey:@"hasAudiobookRights"]; 
			}
		}
		else if ( [elementName isEqualToString:@"Reflow"] ) {
			NSString * attributeStringValue = [attributeDict objectForKey:@"Enabled"];
			if (attributeStringValue && [attributeStringValue isEqualToString:@"True"]) {
				[self setBookValue:[NSNumber numberWithBool:YES] forKey:@"reflowRight"]; 
			}
			else {
				[self setBookValue:[NSNumber numberWithBool:NO] forKey:@"reflowRight"]; 
			}
		}
	}
	else if (parser == self.metadataParser) {
		if ( [elementName isEqualToString:@"Feature"] ) {
			if (!self.featureCompatibilityDictionary) self.featureCompatibilityDictionary = [NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"BlioFeatureCompatibility.plist"]];
			
			NSString * featureName = [attributeDict objectForKey:@"Name"];
			NSString * featureVersion = [attributeDict objectForKey:@"Version"];
			NSString * isRequired = [attributeDict objectForKey:@"IsRequired"];
			if (featureName && featureVersion && isRequired) {
				if ([isRequired isEqualToString:@"true"]) {
					NSNumber * featureCompatibilityVersion = [self.featureCompatibilityDictionary objectForKey:featureName];
					if (featureCompatibilityVersion) NSLog(@"Required feature: %@ found. App compatibility version: %f, book version required: %f",featureName,[featureCompatibilityVersion floatValue],[featureVersion floatValue]);
					else NSLog(@"Required feature: %@ found. App is not compatible with this feature, book version required: %f",featureName,[featureVersion floatValue]);
					if (!featureCompatibilityVersion || [featureCompatibilityVersion floatValue] < [featureVersion floatValue]) {
						// the parsed feature is not listed in the app's compatibility dictionary or the book requires a higher version than our compatibility version

						BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
						[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"For Your Information...",@"\"For Your Information...\" Alert message title")
													 message:[NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"INCOMPATIBLE_FEATURE",nil,[NSBundle mainBundle],@"The book, \"%@\" contains features that cannot be taken advantage of by this version of the Blio app. In order to enjoy this book, please check the iTunes App Store for an update to this App.",@"Alert message informing the end-user that an incompatible feature was found during the processing of a book, and prompting the end-user to visit the iTunes App Store."),book.title]
													delegate:nil
										   cancelButtonTitle:@"OK"
										   otherButtonTitles:nil];
						[self setBookValue:[NSNumber numberWithInt:kBlioBookProcessingStateNotSupported] forKey:@"processingState"];
						[self cancel];
						[parser abortParsing];
					}
					else {
						// the app is compatible with the required version of this feature (no action required)
					}
				}
				else {
					// feature is optional
				}
			}
        } else if ( [elementName isEqualToString:@"PageLayout"] ) {
            NSString * firstPageSide = [attributeDict objectForKey:@"FirstPageSide"];
            if(firstPageSide && [firstPageSide isEqualToString:@"Left"]) {
                [self setBookManifestValue:[NSNumber numberWithBool:YES] forKey:BlioManifestFirstLayoutPageOnLeftKey];
            }
        }
    }
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	//	NSLog(@"found characters: %@",string);
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {    
	//	NSLog(@"didEndElement: %@",elementName);
	if (parser == self.audiobookReferencesParser) {	
		if ( [elementName isEqualToString:@"AudioReferences"]  ) {
			if ( [self.timingFiles count] != [self.audioFiles count] ) {
				NSLog(@"WARNING: Missing audio or timing file.");
				// TODO: Disable audiobook playback.
			}
			else {
				NSMutableDictionary * manifestEntry = nil;
				manifestEntry = [NSMutableDictionary dictionary];
				[manifestEntry setValue:BlioManifestEntryLocationXPS forKey:BlioManifestEntryLocationKey];
				[manifestEntry setValue:self.audioFiles forKey:BlioManifestEntryPathKey];
				[self setBookManifestValue:manifestEntry forKey:BlioManifestAudiobookDataFilesKey];	
				
				manifestEntry = [NSMutableDictionary dictionary];
				[manifestEntry setValue:BlioManifestEntryLocationXPS forKey:BlioManifestEntryLocationKey];
				[manifestEntry setValue:self.timingFiles forKey:BlioManifestEntryPathKey];
				[self setBookManifestValue:manifestEntry forKey:BlioManifestAudiobookTimingFilesKey];			
			}
		}
	}
	else if (parser == self.metadataParser) {
		if ( [elementName isEqualToString:@"Features"] ) {
			self.featureCompatibilityDictionary = nil;
		}		
	}
}

@end

#pragma mark -
@implementation BlioProcessingDownloadAndUnzipOperation

- (void)downloadDidFinishSuccessfully:(BOOL)success {
    if ([self isCancelled]) return;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if (!success) {
        NSLog(@"BlioProcessingDownloadAndUnzipOperation: Download did not finish successfully for url: %@",[self.url absoluteString]);
        [pool drain];
        return;
    }

	// Generate a random filename
	NSString *unzippedFilename = [NSString uniqueStringWithBaseString:[self getBookValueForKey:@"title"]];
    
    NSString *temporaryPath = [[self.tempDirectory stringByAppendingPathComponent:self.filenameKey] stringByStandardizingPath];
    NSString *temporaryPath2 = [[self.tempDirectory stringByAppendingPathComponent:unzippedFilename] stringByStandardizingPath];

    BOOL unzipSuccess = NO;
    ZipArchive* aZipArchive = [[ZipArchive alloc] init];
	if([aZipArchive UnzipOpenFile:temporaryPath] ) {
		if (![aZipArchive UnzipFileTo:temporaryPath2 overWrite:YES]) {
            NSLog(@"Failed to unzip file from %@ to %@", temporaryPath, temporaryPath2);
        } else {
//			NSLog(@"Successfully unzipped file from %@ to %@",temporaryPath,temporaryPath2);
//			if ([[NSFileManager defaultManager] fileExistsAtPath:temporaryPath2]) NSLog(@"file exists at temporaryPath2: %@",temporaryPath2);
			unzipSuccess = YES;
        }

		[aZipArchive UnzipCloseFile];
	} else {
        NSLog(@"Failed to open zipfile at path: %@", temporaryPath);
    }
    
	[aZipArchive release];

    NSError *anError;
    if (![[NSFileManager defaultManager] removeItemAtPath:temporaryPath error:&anError])
        NSLog(@"Failed to delete zip file at path %@ with error: %@, %@", temporaryPath, anError, [anError userInfo]);

    self.localFilename = unzippedFilename;
     
    [self unzipDidFinishSuccessfully:unzipSuccess];    
    
    [pool drain];
}

- (void)unzipDidFinishSuccessfully:(BOOL)success {
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
	[userInfo setObject:self.bookID forKey:@"bookID"];
	[userInfo setObject:[NSNumber numberWithInt:self.sourceID] forKey:@"sourceID"];
	[userInfo setObject:self.sourceSpecificID forKey:@"sourceSpecificID"];
    if (success) {
		NSString *temporaryPath = [[self.tempDirectory stringByAppendingPathComponent:self.localFilename] stringByStandardizingPath];
		NSString *targetFilename = [[self.cacheDirectory stringByAppendingPathComponent:self.localFilename] stringByStandardizingPath];
		NSError *anError;
//		if ([[NSFileManager defaultManager] fileExistsAtPath:temporaryPath]) NSLog(@"file exists at temporaryPath: %@",temporaryPath);
//		else NSLog(@"ERROR: file does NOT exist at temporaryPath: %@",temporaryPath);
        if ([[NSFileManager defaultManager] fileExistsAtPath:targetFilename]) {
			NSLog(@"WARNING: file already exists at targetFilename: %@, writing over file...",targetFilename);
			if (![[NSFileManager defaultManager] removeItemAtPath:targetFilename error:&anError])
				NSLog(@"ERROR: Failed to delete targetFilename %@ with error: %@, %@", targetFilename, anError, [anError userInfo]);
		}
//		else NSLog(@"file does NOT exist at targetFilename: %@",targetFilename);
		
        if (![[NSFileManager defaultManager] moveItemAtPath:temporaryPath toPath:targetFilename error:&anError]) {
            NSLog(@"BlioProcessingDownloadAndUnzipOperation: Error whilst attempting to move file %@ to %@: %@, %@", temporaryPath, targetFilename,anError,[anError userInfo]);
			[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationFailedNotification object:self userInfo:userInfo];			
            return;
        }
		else {
            NSDictionary *manifestEntry = [NSMutableDictionary dictionary];
            [manifestEntry setValue:BlioManifestEntryLocationFileSystem forKey:BlioManifestEntryLocationKey];
            [manifestEntry setValue:self.localFilename forKey:BlioManifestEntryPathKey];
            
            [self setBookManifestValue:manifestEntry forKey:self.filenameKey];
            
            //[self setBookValue:self.localFilename forKey:self.filenameKey];
			self.operationSuccess = YES;
			[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationCompleteNotification object:self userInfo:userInfo];			
		}
	} else {
		NSLog(@"Unzip did not finish successfully");
		[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationFailedNotification object:self userInfo:userInfo];			
	}
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	UIApplication *application = [UIApplication sharedApplication];
	if([application respondsToSelector:@selector(endBackgroundTask:)]) {
//		NSLog(@"ending background task...");
		if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) [application endBackgroundTask:backgroundTaskIdentifier];	
	}	
#endif
	
}

@end

#pragma mark -
@implementation BlioProcessingDownloadAndUnzipVoiceOperation

@synthesize voice;

-(void) dealloc {
	self.voice = nil;
	[super dealloc];
}

- (void)downloadDidFinishSuccessfully:(BOOL)success {
    if ([self isCancelled]) return;

	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	[userInfo setObject:self.voice forKey:@"voice"];
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if (!success) {
        NSLog(@"BlioDownloadAndUnzipVoiceOperation: Download did not finish successfully for url: %@",[self.url absoluteString]);
		[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationFailedNotification object:self userInfo:userInfo];			
        [pool drain];
        return;
    }
	//	NSLog(@"Download finished successfully"); 
	//	NSLog(@"for url: %@",[self.url absoluteString]);
	

	
    NSString *temporaryPath = [[self.tempDirectory stringByAppendingPathComponent:self.filenameKey] stringByStandardizingPath];
    NSString *temporaryPath2 = [[self.cacheDirectory stringByAppendingPathComponent:@"TTS"] stringByStandardizingPath];
	
    BOOL unzipSuccess = NO;
    ZipArchive* aZipArchive = [[ZipArchive alloc] init];
	if([aZipArchive UnzipOpenFile:temporaryPath] ) {
		if (![aZipArchive UnzipFileTo:temporaryPath2 overWrite:YES]) {
            NSLog(@"Failed to unzip file from %@ to %@", temporaryPath, temporaryPath2);
        } else {
            unzipSuccess = YES;
        }
		
		[aZipArchive UnzipCloseFile];
	} else {
        NSLog(@"Failed to open zipfile at path: %@", temporaryPath);
    }
    
	[aZipArchive release];
	
    NSError *anError;
    if (![[NSFileManager defaultManager] removeItemAtPath:temporaryPath error:&anError])
        NSLog(@"Failed to delete zip file at path %@ with error: %@, %@", temporaryPath, anError, [anError userInfo]);
	
    self.localFilename = temporaryPath2;
	
    [self unzipDidFinishSuccessfully:unzipSuccess];    
    
    [pool drain];
}

- (void)unzipDidFinishSuccessfully:(BOOL)success {
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	UIApplication *application = [UIApplication sharedApplication];
	if([application respondsToSelector:@selector(endBackgroundTask:)]) {
//		NSLog(@"ending background task...");
		if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) [application endBackgroundTask:backgroundTaskIdentifier];	
	}
#endif
	
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	[userInfo setObject:self.voice forKey:@"voice"];
    if (success) {
		[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationCompleteNotification object:self userInfo:userInfo];			
	} 
	else {
		NSLog(@"Unzip did not finish successfully");
		[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationFailedNotification object:self userInfo:userInfo];			
	}
}
-(void) setPercentageComplete:(NSUInteger)percentage {
	percentageComplete = percentage;
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	[userInfo setObject:self.voice forKey:@"voice"];
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationProgressNotification object:self userInfo:userInfo];
}

@end


#pragma mark -
@implementation BlioProcessingDownloadCoverOperation

- (id)initWithUrl:(NSURL *)aURL {
    if ((self = [super initWithUrl:aURL])) {
        self.localFilename = @"cover";
		self.filenameKey = BlioManifestCoverKey;
    }
    return self;
}

@end

#pragma mark -
@implementation BlioProcessingGenerateCoverThumbsOperation

- (CGAffineTransform)transformForOrientation:(CGSize)newSize orientation:(UIImageOrientation)orientation {
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (orientation) {
        case UIImageOrientationDown:           // EXIF = 3
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newSize.width, newSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:           // EXIF = 6
        case UIImageOrientationLeftMirrored:   // EXIF = 5
            transform = CGAffineTransformTranslate(transform, newSize.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:          // EXIF = 8
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, 0, newSize.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (orientation) {
        case UIImageOrientationUpMirrored:     // EXIF = 2
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newSize.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:   // EXIF = 5
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, newSize.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    return transform;
}

- (UIImage *)newThumbFromImage:(UIImage *)image forSize:(CGSize)size {
    
    CGAffineTransform transform = [self transformForOrientation:size orientation:image.imageOrientation];
    
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, size.width, size.height));
    CGImageRef imageRef = image.CGImage;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                newRect.size.width,
                                                newRect.size.height,
                                                8,
                                                0,
                                                colorSpace,
                                                kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    // Rotate and/or flip the image if required by its orientation
    CGContextConcatCTM(bitmap, transform);
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(bitmap, kCGInterpolationHigh);
    
    // Draw into the context; this scales the image
    CGContextDrawImage(bitmap, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newThumb = [[UIImage alloc] initWithCGImage:newImageRef];
    
    // Clean up
    CGImageRelease(newImageRef);
    CGContextRelease(bitmap);
    CGColorSpaceRelease(colorSpace);
    
    return newThumb;
}

- (void)main {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    for (BlioProcessingOperation * blioOp in [self dependencies]) {
		if (!blioOp.operationSuccess) {
			NSLog(@"BlioProcessingGenerateCoverThumbsOperation: failed dependency found! op: %@",blioOp);
			[self cancel];
			break;
		}
	}	
    if ([self isCancelled]) {
		NSLog(@"Operation cancelled, will prematurely abort start");
        [pool drain];
		return;
    }
    
    NSData *imageData = nil;
    BOOL hasCover = [self hasBookManifestValueForKey:BlioManifestCoverKey];
    
    if (hasCover) {
        imageData = [self getBookManifestDataForKey:BlioManifestCoverKey];
    }
    
    if (nil == imageData) {
        if (!hasCover) {
            NSLog(@"Failed to create generate cover thumbs because cover image from manifest value is nil.");
        }
        [pool drain];
		// not having a valid cover image should not trigger a book processing failure.
		self.operationSuccess = YES;
		self.percentageComplete = 100;
        return;
    }
    UIImage *cover = [UIImage imageWithData:imageData];
    
    if (nil == cover) {
        NSLog(@"Failed to create generate cover thumbs because cover image was not an image.");
        [pool drain];
		// not having a valid cover image should not trigger a book processing failure.
		self.operationSuccess = YES;
		self.percentageComplete = 100;
        return;
    }
    
    if ([self isCancelled]) {
        [pool drain];
        return;
    }
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	UIApplication *application = [UIApplication sharedApplication];
	if([application respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)]) {
		self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:nil];
	}	
#endif
	
	NSString * pixelSpecificKey = nil;
	NSString * pixelSpecificFilename = nil;
	CGFloat targetThumbWidth = 0;
	CGFloat targetThumbHeight = 0;
	NSInteger scaledTargetThumbWidth = 0;
	NSInteger scaledTargetThumbHeight = 0;

	targetThumbWidth = kBlioCoverGridThumbWidthPhone;
	targetThumbHeight = kBlioCoverGridThumbHeightPhone;

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		targetThumbWidth = kBlioCoverGridThumbWidthPad;
		targetThumbHeight = kBlioCoverGridThumbHeightPad;
	}
    
    CGFloat scaleFactor = 1;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        scaleFactor = [[UIScreen mainScreen] scale];
    }	
	scaledTargetThumbWidth = round(targetThumbWidth * scaleFactor);
	scaledTargetThumbHeight = round(targetThumbHeight * scaleFactor);
	
	
	pixelSpecificKey = [NSString stringWithFormat:@"thumbFilename%ix%i",scaledTargetThumbWidth,scaledTargetThumbHeight];
	pixelSpecificFilename = [NSString stringWithFormat:@"%@.png",pixelSpecificKey];
	
    UIImage *gridThumb = [self newThumbFromImage:cover forSize:CGSizeMake(scaledTargetThumbWidth, scaledTargetThumbHeight)];
    NSData *gridData = UIImagePNGRepresentation(gridThumb);
    NSString *gridThumbPath = [self.cacheDirectory stringByAppendingPathComponent:pixelSpecificFilename];
    [gridData writeToFile:gridThumbPath atomically:YES];
    [gridThumb release];
    
    NSDictionary *gridThumbManifestEntry = [NSMutableDictionary dictionary];
    [gridThumbManifestEntry setValue:BlioManifestEntryLocationFileSystem forKey:BlioManifestEntryLocationKey];
    [gridThumbManifestEntry setValue:pixelSpecificFilename forKey:BlioManifestEntryPathKey];
    [self setBookManifestValue:gridThumbManifestEntry forKey:pixelSpecificKey];

    if ([self isCancelled]) {
        [pool drain];
        return;
    }
    

	targetThumbWidth = kBlioCoverListThumbWidth;
	targetThumbHeight = kBlioCoverListThumbHeight;

	scaledTargetThumbWidth = round(targetThumbWidth * scaleFactor);
	scaledTargetThumbHeight = round(targetThumbHeight * scaleFactor);
	
	pixelSpecificKey = [NSString stringWithFormat:@"thumbFilename%ix%i",scaledTargetThumbWidth,scaledTargetThumbHeight];
	pixelSpecificFilename = [NSString stringWithFormat:@"%@.png",pixelSpecificKey];
	
    UIImage *listThumb = [self newThumbFromImage:cover forSize:CGSizeMake(scaledTargetThumbWidth, scaledTargetThumbHeight)];
    NSData *listData = UIImagePNGRepresentation(listThumb);
    NSString *listThumbPath = [self.cacheDirectory stringByAppendingPathComponent:pixelSpecificFilename];
    [listData writeToFile:listThumbPath atomically:YES];
    [listThumb release];
    	
    NSDictionary *listThumbManifestEntry = [NSMutableDictionary dictionary];
    [listThumbManifestEntry setValue:BlioManifestEntryLocationFileSystem forKey:BlioManifestEntryLocationKey];
    [listThumbManifestEntry setValue:pixelSpecificFilename forKey:BlioManifestEntryPathKey];
    [self setBookManifestValue:listThumbManifestEntry forKey:pixelSpecificKey];

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	if([application respondsToSelector:@selector(endBackgroundTask:)]) {
		if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) [application endBackgroundTask:backgroundTaskIdentifier];	
	}			
#endif
	
	self.operationSuccess = YES;
	self.percentageComplete = 100;
    
    // The above operations will erroneously report a malloc error in the 3.0 Simulator
    // This appears to be a simulator-only bug in Apple's framework as described here:
    // http://stackoverflow.com/questions/1424210/iphone-development-pointer-being-freed-was-not-allocated
    [pool drain];
	
}
                           
@end

#pragma mark -
@implementation BlioProcessingDownloadEPubOperation
- (id)initWithUrl:(NSURL *)aURL {
    if ((self = [super initWithUrl:aURL])) {
		self.filenameKey = BlioManifestEPubKey;
    }
    return self;
}

@end

#pragma mark -
@implementation BlioProcessingDownloadPdfOperation

- (id)initWithUrl:(NSURL *)aURL {
    if ((self = [super initWithUrl:aURL])) {
		self.filenameKey = BlioManifestPDFKey;
    }
    return self;
}

@end

#pragma mark -
@implementation BlioProcessingDownloadXPSOperation

- (id)initWithUrl:(NSURL *)aURL {
    if ((self = [super initWithUrl:aURL])) {
		self.filenameKey = BlioManifestXPSKey;
    }
    return self;
}

@end

#pragma mark -
@implementation BlioProcessingDownloadTextFlowOperation
- (id)initWithUrl:(NSURL *)aURL {
    if ((self = [super initWithUrl:aURL])) {
		self.filenameKey = BlioManifestTextFlowKey;
    }
    return self;
}
- (void)unzipDidFinishSuccessfully:(BOOL)success {
    if (success) {
        NSError *anError;
        
        // Rename the unzipped folder to be TextFlow
        NSString *cachedFilename = [self.tempDirectory stringByAppendingPathComponent:self.localFilename];
        NSString *targetFilename = [self.cacheDirectory stringByAppendingPathComponent:@"TextFlow"];
        
        // Identify textFlow root file
        NSArray *textFlowFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cachedFilename error:&anError];
        if (nil == textFlowFiles)
            NSLog(@"Error whilst enumerating Textflow directory %@: %@, %@", targetFilename, anError, [anError userInfo]);
        
        NSString *rootFile = nil;
        for (NSString *textFlowFile in textFlowFiles) {
            if ([textFlowFile isEqualToString:@"Sections.xml"]) {
                rootFile = textFlowFile;
                break;
            } else {
                // TODO - remove this when it is no longer needed
                NSRange rootIDRange = [textFlowFile rangeOfString:@"_split.xml"];
                if (rootIDRange.location != NSNotFound) {
                    rootFile = textFlowFile;
                    break;
                }
            }
        }
        
        if (nil != rootFile) {

			if (![[NSFileManager defaultManager] fileExistsAtPath:cachedFilename]) NSLog(@"ERROR: file does NOT exist at cachedFilename: %@",cachedFilename);
//			else NSLog(@"file exists at cachedFilename: %@",cachedFilename);			
			if ([[NSFileManager defaultManager] fileExistsAtPath:targetFilename]) {
				NSLog(@"WARNING: file already exists at targetFilename: %@, writing over file...",targetFilename);
				if (![[NSFileManager defaultManager] removeItemAtPath:targetFilename error:&anError])
					NSLog(@"ERROR: Failed to delete targetFilename %@ with error: %@, %@", targetFilename, anError, [anError userInfo]);
			}
//			else NSLog(@"file does not exist at targetFilename: %@",targetFilename);

			
			if (![[NSFileManager defaultManager] moveItemAtPath:cachedFilename toPath:targetFilename error:&anError]) {
				NSLog(@"BlioProcessingDownloadTextFlowOperation: Error whilst attempting to move file %@ to %@: %@, %@", cachedFilename, targetFilename,anError,[anError userInfo]);
				return;
			}			
            else {
                NSDictionary *manifestEntry = [NSMutableDictionary dictionary];
                [manifestEntry setValue:BlioManifestEntryLocationTextflow forKey:BlioManifestEntryLocationKey];
                [manifestEntry setValue:rootFile forKey:BlioManifestEntryPathKey];
				[self setBookManifestValue:manifestEntry forKey:self.filenameKey];
				self.operationSuccess = YES;
				self.percentageComplete = 100;
			}
		}
        else
            NSLog(@"Could not find root file in Textflow directory %@", cachedFilename);
    }
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	UIApplication * application = [UIApplication sharedApplication];
	if([application respondsToSelector:@selector(endBackgroundTask:)]) {
		if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) [application endBackgroundTask:backgroundTaskIdentifier];	
	}				
#endif
}

@end

#pragma mark -
@implementation BlioProcessingDownloadAudiobookOperation
- (id)initWithUrl:(NSURL *)aURL {
    if ((self = [super initWithUrl:aURL])) {
		self.filenameKey = BlioManifestAudiobookKey;
    }
    return self;
}
- (void)unzipDidFinishSuccessfully:(BOOL)success {
    if (success) {
        NSError *anError;
        
        // Rename the unzipped folder to be Audiobook
        NSString *temporaryPath = [[self.tempDirectory stringByAppendingPathComponent:self.localFilename] stringByStandardizingPath];
        NSString *targetFilename = [[self.cacheDirectory stringByAppendingPathComponent:@"Audiobook"] stringByStandardizingPath];
                
        // Identify Audiobook root files        
        // TODO These checks (especially for the root rtx file) are not robust
        NSArray *audioFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:temporaryPath error:&anError];
        if (nil == audioFiles)
            NSLog(@"Error whilst enumerating Audiobook directory %@: %@, %@", temporaryPath, anError, [anError userInfo]);
        
		// There can be multiple mp3 files as well as multiple rtx files.  
		// The metadata xml file has metadata that maps mp3-rtx pairs to fixed pages.
		// The references xml file has the pairs.  We don't know till we parse it 
		// if we have the required mp3 and rtx files.
        NSString *audioMetadataFilename = nil;
        NSString *audioReferencesFilename = nil;
        for (NSString *audioFile in audioFiles) {
			NSRange audioXmlRange = [audioFile rangeOfString:@"Audio.xml"];
            if (audioXmlRange.location != NSNotFound) {
				audioMetadataFilename = audioFile;
            }
			NSRange refsXmlRange = [audioFile rangeOfString:@"References.xml"];
            if (refsXmlRange.location != NSNotFound) {
				audioReferencesFilename = audioFile;
            }
        }
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:temporaryPath]) NSLog(@"ERROR: file does NOT exist at temporaryPath: %@",temporaryPath);
//        else NSLog(@"file exists at temporaryPath: %@",temporaryPath);		
		if ([[NSFileManager defaultManager] fileExistsAtPath:targetFilename]) {
			NSLog(@"WARNING: file already exists at targetFilename: %@, writing over file...",targetFilename);
			if (![[NSFileManager defaultManager] removeItemAtPath:targetFilename error:&anError])
				NSLog(@"ERROR: Failed to delete targetFilename %@ with error: %@, %@", targetFilename, anError, [anError userInfo]);
		}
//		else NSLog(@"file does not exist at targetFilename: %@",targetFilename);
		
		// For now keep the old key names.
        if (audioMetadataFilename && audioReferencesFilename) {
			if (![[NSFileManager defaultManager] moveItemAtPath:temporaryPath toPath:targetFilename error:&anError]) {
				NSLog(@"BlioProcessingDownloadAudiobookOperation: Error whilst attempting to move file %@ to %@: %@, %@", temporaryPath, targetFilename,anError,[anError userInfo]);
				return;
			}
			else {
				[self setBookValue:audioMetadataFilename forKey:self.filenameKey];
				[self setBookValue:audioReferencesFilename forKey:@"timingIndicesFilename"];
				[self setBookValue:[NSNumber numberWithBool:YES] forKey:@"hasAudiobookRights"]; 
				self.operationSuccess = YES;
				self.percentageComplete = 100;
			}
        } else {
            NSLog(@"Could not find required audiobook files in AudioBook directory %@", temporaryPath);
        }        
    }
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	UIApplication * application = [UIApplication sharedApplication];
	if([application respondsToSelector:@selector(endBackgroundTask:)]) {
		if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) [application endBackgroundTask:backgroundTaskIdentifier];	
	}					
#endif
}

@end

