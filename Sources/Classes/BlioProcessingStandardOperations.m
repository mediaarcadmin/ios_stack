//
//  BlioProcessingOperations.m
//  BlioApp
//
//  Created by matt on 25/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "BlioProcessingStandardOperations.h"
#import "ZipArchive.h"
#import "BlioDrmSessionManager.h"
#import "NSString+BlioAdditions.h"
#import "BlioAlertManager.h"
#import "BlioStoreManager.h"
#import "Reachability.h"
#import "BlioImportManager.h"
#import "KNFBXMLParserLock.h"
#import "BlioLayoutPDFDataSource.h"
#import "BlioEPubMetadataReader.h"
#import "BlioSong.h"
#import "BlioVaultService.h"

@implementation BlioProcessingAggregateOperation

@synthesize alreadyCompletedOperations;

- (void)addDependency:(NSOperation *)operation {
	[super addDependency:operation];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProcessingProgressNotification:) name:BlioProcessingOperationProgressNotification object:operation];
}

- (void)removeDependency:(NSOperation *)operation {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BlioProcessingOperationProgressNotification object:operation];
	[super removeDependency:operation];
}

- (void)onProcessingProgressNotification:(NSNotification*)note {
    //NSLog(@"%@ called for %@", NSStringFromSelector(_cmd),self.sourceSpecificID);
	[self calculateProgress];
}
- (void)calculateProgress {
	//NSLog(@"alreadyCompletedOperations: %u",alreadyCompletedOperations);
	float collectiveProgress = 0.0f;
    //NSLog(@"self.dependencies: %@",self.dependencies);
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
	float newPercentageComplete = ((collectiveProgress+alreadyCompletedOperations*100)/([self.dependencies count]+alreadyCompletedOperations));
    
    //NSLog(@"%@ progress for %@: %f",[[self class] description],self.sourceSpecificID,newPercentageComplete);
	self.percentageComplete = newPercentageComplete;
}

@end

@implementation BlioProcessingCompleteOperation

@synthesize processingDelegate = _processingDelegate;


- (void)main {
    //NSLog(@"bookID: %@",bookID);
    if ([self isCancelled]) {
		NSLog(@"BlioProcessingCompleteOperation cancelled before starting (perhaps due to pause, broken internet connection, crash, or application exit)");
		NSLog(@"CompleteOperation dependencies: %@",[self dependencies]);
		return;
	}
    NSInteger currentProcessingState;
    if (self.bookID)
        currentProcessingState = [[self getBookValueForKey:@"processingState"] intValue];
    else if (self.songID)
        currentProcessingState = [[self getSongValueForKey:@"processingState"] intValue];
//	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
//	[userInfo setObject:self.bookID forKey:@"bookID"];
//	[userInfo setObject:[NSNumber numberWithInt:self.sourceID] forKey:@"sourceID"];
//	[userInfo setObject:self.sourceSpecificID forKey:@"sourceSpecificID"];
	for (BlioProcessingOperation * blioOp in [self dependencies]) {
		if (!blioOp.operationSuccess) {
			NSLog(@"BlioProcessingCompleteOperation: failed dependency found! Operation: %@ Sending Failed Notification...",blioOp);
			NSLog(@"CompleteOperation dependencies: %@",[self dependencies]);
			if (currentProcessingState != kBlioBookProcessingStateNotSupported && currentProcessingState != kBlioBookProcessingStatePaused && currentProcessingState != kBlioBookProcessingStateSuspended) [self setBookValue:[NSNumber numberWithInt:kBlioBookProcessingStateFailed] forKey:@"processingState"];
//			[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationFailedNotification object:self userInfo:userInfo];
			[self cancel];
			self.operationSuccess = NO;
			return;
		}
//		NSLog(@"completed operation: %@ percentageComplete: %f",blioOp,blioOp.percentageComplete);
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
	
    if (currentProcessingState == kBlioBookProcessingStateNotProcessed) {
        if (self.bookID)
            [self setBookValue:[NSNumber numberWithInt:kBlioBookProcessingStatePlaceholderOnly] forKey:@"processingState"];
        else if (self.songID)
            [self setSongValue:[NSNumber numberWithInt:kBlioBookProcessingStatePlaceholderOnly] forKey:@"processingState"];
    }
    else if (currentProcessingState != kBlioBookProcessingStateNotSupported) {
        if (self.bookID)
            [self setBookValue:[NSNumber numberWithInt:kBlioBookProcessingStateComplete] forKey:@"processingState"];
        else if (self.songID)
            [self setSongValue:[NSNumber numberWithInt:kBlioBookProcessingStateComplete] forKey:@"processingState"];
    }
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
- (void) dealloc {
//	NSLog(@"BlioProcessingCompleteOperation dealloc entered");
    [self.processingDelegate completeOperationFinished];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}
@end

@implementation BlioProcessingDeleteBookOperation
@synthesize processingDelegate = _processingDelegate;
@synthesize attemptArchive,shouldSave;

- (void)main {
    NSMutableDictionary * settings = [NSMutableDictionary dictionaryWithCapacity:4];
    [settings setObject:self.bookID forKey:@"bookID"];
    [settings setObject:[NSNumber numberWithBool:self.attemptArchive] forKey:@"attemptArchive"];
    [settings setObject:[NSNumber numberWithBool:self.shouldSave] forKey:@"shouldSave"];
    [self.processingDelegate safeDeleteBookWithSettings:settings];
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
		attemptsMaximum = 1;	
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
	
    // For PlayReady only:
	//BOOL isEncrypted = [self bookManifestPath:BlioXPSKNFBDRMHeaderFile existsForLocation:BlioManifestEntryLocationXPS];
    // For PlayReady or KDRM:
	BOOL isEncrypted = [self bookManifestPath:KNFBXPSEncryptedPagesDir existsForLocation:BlioManifestEntryLocationXPS];
	if (!isEncrypted) {
        self.operationSuccess = YES;
		self.percentageComplete = 100;
		NSLog(@"book not encrypted! aborting License operation...");
		return;
	} else {
        NSMutableDictionary *manifestEntry = [NSMutableDictionary dictionary];
		[manifestEntry setValue:BlioManifestEntryLocationXPS forKey:BlioManifestEntryLocationKey];
        // For PlayReady only:
		//[manifestEntry setValue:BlioXPSKNFBDRMHeaderFile forKey:BlioManifestEntryPathKey];
		//[self setBookManifestValue:manifestEntry forKey:BlioManifestDrmHeaderKey];
        // For PlayReady or KDRM:
		[manifestEntry setValue:KNFBXPSEncryptedPagesDir forKey:BlioManifestEntryPathKey];
		[self setBookManifestValue:manifestEntry forKey:BlioManifestDrmPagesKey];
	}
	BOOL isValidSource = NO;
#ifdef TEST_MODE
    isValidSource = ([[self getBookValueForKey:@"sourceID"] intValue] == BlioBookSourceOnlineStore || [[self getBookValueForKey:@"sourceID"] intValue] == BlioBookSourceLocalBundleDRM || [[self getBookValueForKey:@"sourceID"] intValue] == BlioBookSourceFileSharing);
#else
    isValidSource = ([[self getBookValueForKey:@"sourceID"] intValue] == BlioBookSourceOnlineStore || [[self getBookValueForKey:@"sourceID"] intValue] == BlioBookSourceLocalBundleDRM);
#endif
	if (!isValidSource) {
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
	NSLog(@"License Acquisition will use token: %@",[[BlioStoreManager sharedInstance] tokenForSourceID:BlioBookSourceOnlineStore]);
	if ([[BlioStoreManager sharedInstance] tokenForSourceID:BlioBookSourceOnlineStore] == nil) {
		NSLog(@"ERROR: no valid token, cancelling BlioProcessingLicenseAcquisitionOperation...");
		NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:self.bookID forKey:@"bookID"];
		[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingLicenseAcquisitionTokenRequiredNotification object:self userInfo:userInfo];
		[self cancel];
	}

	if ([[self getBookValueForKey:@"userNum"] intValue] != [[BlioStoreManager sharedInstance] currentUserNum] && [[self getBookValueForKey:@"sourceID"] intValue] != BlioBookSourceLocalBundleDRM && [[self getBookValueForKey:@"sourceID"] intValue] != BlioBookSourceFileSharing) {  
		NSLog(@"Book userNum and currentUserNum do not match! Cancelling BlioProcessingLicenseAcquisitionOperation...");
		NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:self.bookID forKey:@"bookID"];
		[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingLicenseAcquisitionNonMatchingUserNotification object:self userInfo:userInfo];
		[self cancel];
		return;						
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
	self.operationSuccess = acquisitionSuccess;
	
	if (self.operationSuccess) {
		NSDictionary *manifestEntry = [NSMutableDictionary dictionary];
		[self setBookManifestValue:manifestEntry forKey:BlioManifestLicenseAcquisitionCompleteKey];		
	} 

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

- (void)prepareForStartOnBackgroundThread;
- (void)cancelActiveConnections;
- (void)finish;

@end

@implementation BlioProcessingDownloadOperation

@synthesize url, filenameKey, localFilename, tempFilename, connection, headConnection, downloadFile,resume,expectedContentLength,requestHTTPBody,serverMimetype,serverFilename, statusCode, mustReport;

- (void) dealloc {
//	NSLog(@"BlioProcessingDownloadOperation %@ dealloc entered.",self);
    self.url = nil;
    self.filenameKey = nil;
    self.localFilename = nil;
    self.tempFilename = nil;
	if (self.connection) {
		[self.connection cancel];
        self.connection = nil;
	}
	if (self.headConnection) {
        [self.headConnection cancel];
        self.headConnection = nil;
    }
    self.downloadFile = nil;
	self.requestHTTPBody = nil;
    [super dealloc];
}

- (id)initWithUrl:(NSURL *)aURL {
    if((self = [super init])) {
        self.url = aURL;
		expectedContentLength = NSURLResponseUnknownLength;
        executing = NO;
        finished = NO;
		resume = NO;
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

- (void)cancel {
	[super cancel];
	NSLog(@"Cancelling download...");
    if([NSThread isMainThread]) {
        [self performSelector:@selector(cancelActiveConnections) withObject:nil afterDelay:0.0];
    } else {
        [self performSelectorOnMainThread:@selector(cancelActiveConnections) withObject:nil waitUntilDone:NO];
    }
}

- (void)cancelActiveConnections
{
    if (self.headConnection || self.connection) {
        [self.headConnection cancel];
        self.headConnection = nil;
        
        [self.connection cancel];
        self.connection = nil;

        // We'd usually be relying on the callbacks from these connections
        // to finish the operation, so we need to do it manually because there
        // will be no further callbacks.
        [self finish];
    }
}

- (void)finish {
    if(!finished) {
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
    }
    if(executing) {
        [self willChangeValueForKey:@"isExecuting"];
        executing = NO;
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (void)start
{
    [self willChangeValueForKey:@"isExecuting"];
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
	for (BlioProcessingOperation * blioOp in [self dependencies]) {
		if (!blioOp.operationSuccess) {
			NSLog(@"failed dependency found: %@",blioOp);
			[self cancel];
			break;
		}
	}    
    
    if ([self isCancelled]) {
        NSLog(@"BlioProcessingDownloadOperation cancelled, will prematurely abort start");
        [self finish];
        return;
    }

    [self prepareForStartOnBackgroundThread];
    
    if ([self isCancelled]) {
        NSLog(@"BlioProcessingDownloadOperation cancelled, will prematurely abort start");
        [self finish];
        return;
    }
    
    [self performSelectorOnMainThread:@selector(startOnMainThread) withObject:nil waitUntilDone:NO];
}

- (void)prepareForStartOnBackgroundThread {
    // Do nothing - subclasses can implement to do anything they need to do in the background
    // before we start our download on the main thread. (e.g. prepare the URL).
}

- (void)startOnMainThread {
    NSParameterAssert([NSThread isMainThread]);

    if ([self isCancelled]) {
        NSLog(@"BlioProcessingDownloadOperation cancelled, will prematurely abort start");
        [self finish];
        return;
    }

    NSURL *myURL = self.url;
	if (myURL == nil) {
		NSLog(@"URL is nil, will prematurely abort start");
        [self finish];
        return;
    }
    
	if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable && ![myURL isFileURL]) {
		NSLog(@"Internet connection is dead, will prematurely abort start");
        [self finish];
        return;
    }

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
    
    if (resume && ![myURL isFileURL]) {
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
    [BlioProcessingOperation addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:temporaryPath]];
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
	if (requestHTTPBody) {
		NSLog(@"requestHTTPBody found! including it via POST...");
		[aRequest setHTTPMethod:@"POST"];
		[aRequest setHTTPBody:requestHTTPBody];
		[aRequest setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
		NSLog(@"data length: %u",[requestHTTPBody length]);
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
- (NSString *)filenameFromContentDisposition:(NSString *)dispositionString {
    // Not exactly a great parser, but it doesn't really matter if
    // we get this wrong sometimes - the user never sees the filenames.
    NSString *filename = nil;
    NSRange filenameStart = [dispositionString rangeOfString:@"filename=" options:NSCaseInsensitiveSearch];
    if(filenameStart.location != NSNotFound) {
        filename = [dispositionString substringFromIndex:filenameStart.location + filenameStart.length];
        if(filename.length) {
            if([filename characterAtIndex:0] == '"') {
                filename = [filename substringFromIndex:1];
            }
            if(filename.length) {
                NSRange endQuote = [filename rangeOfString:@"\""];
                if(endQuote.location != NSNotFound) {
                    filename = [filename substringToIndex:endQuote.location];
                } else {
                    NSRange endSpace = [filename rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if(endSpace.location != NSNotFound) {
                        filename = [filename substringToIndex:endSpace.location];
                    }
                }
            }
        }
    }
    return filename.length ? filename : nil;
}
- (void)connection:(NSURLConnection *)theConnection didReceiveResponse:(NSURLResponse *)response {
//	NSLog(@"connection didReceiveResponse: %@",[[response URL] absoluteString]);
	self.expectedContentLength = [response expectedContentLength];

	NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *) response;
    self.statusCode = httpResponse.statusCode;

	if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]] && theConnection == headConnection) {		
//		NSLog(@"headConnection httpResponse.statusCode: %i",httpResponse.statusCode);
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
				//NSLog(@"keyString: \"%@\" = \"%@\"",keyString,[httpResponse.allHeaderFields objectForKey:keyString]);
				if ([[keyString lowercaseString] isEqualToString:[@"Accept-Ranges" lowercaseString]]) {
					acceptRanges = [httpResponse.allHeaderFields objectForKey:keyString];
					break;
				}
			}			
//			NSLog(@"Accept-Ranges: %@",acceptRanges);
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
			else {
//				NSLog(@"inspecting header fields for download connection...");
				for (id key in httpResponse.allHeaderFields)
				{
                    NSString * keyString = (NSString*)key;
                    if ([[keyString lowercaseString] isEqualToString:[@"Content-Disposition" lowercaseString]]) {
                        NSString *filename = [self filenameFromContentDisposition:[httpResponse.allHeaderFields objectForKey:keyString]];
                        if(filename) {
                            self.serverFilename = filename;
                        }
                    }             
                    if ([[keyString lowercaseString] isEqualToString:[@"Content-Type" lowercaseString]]) {
                        self.serverMimetype = [httpResponse.allHeaderFields objectForKey:keyString];
                    }
					//NSString * keyString = (NSString*)key;
					//NSLog(@"keyString: %@ value: %@",keyString, [httpResponse.allHeaderFields valueForKey:key]);
				}							
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
		NSLog(@"DownloadOperation cancelled, will prematurely abort NSURLConnection");
        [self finish];
        return;
    }	
    if (self.connection == aConnection) {
//		NSLog(@"connection didReceiveData");
		[self.downloadFile writeData:data];
		if (expectedContentLength != 0 && expectedContentLength != NSURLResponseUnknownLength) {
//			NSLog(@"[self.downloadFile seekToEndOfFile]: %llu",[self.downloadFile seekToEndOfFile]);
//			NSLog(@"expectedContentLength: %lld",expectedContentLength);
			self.percentageComplete = [self.downloadFile seekToEndOfFile]*100/expectedContentLength;
//			NSLog(@"Download operation percentageComplete for asset %@: %f",self.sourceSpecificID,self.percentageComplete);
		}
		else
            self.percentageComplete = 50;
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
    if (self.connection == aConnection) {
//		NSLog(@"Finished downloading URL: %@",[self.url absoluteString]);
        if (self.statusCode == 500) {
            NSData * serverErrorData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:self.temporaryPath]];
            NSString *responseString = [[NSString alloc] initWithData:serverErrorData encoding: NSUTF8StringEncoding];
            NSLog(@"500 responseString: %@",responseString);
            [responseString release];
        }
        else {
            [self downloadDidFinishSuccessfully:YES];
            [self finish];
        }
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

-(void)setMediaID:(NSMutableDictionary*)dict {
    if (self.bookID)
        [dict setObject:self.bookID forKey:@"bookID"];
    else if (self.songID)
        [dict setObject:self.songID forKey:@"songID"];
}

- (void)downloadDidFinishSuccessfully:(BOOL)success {
//	if (success) NSLog(@"Download finished successfully"); 
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
    [self setMediaID:userInfo];
	[userInfo setObject:[NSNumber numberWithInt:self.sourceID] forKey:@"sourceID"];
	[userInfo setObject:self.sourceSpecificID forKey:@"sourceSpecificID"];
	if (!success) {
		NSLog(@"BlioProcessingDownloadOperation: Download did not finish successfully");
		NSLog(@"for url: %@",[self.url absoluteString]);
		[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationFailedNotification object:self userInfo:userInfo];		
	}
	else {
		// Generate new filename, based on the server's filename if possible.
		NSString *uniqueString = nil;
        NSString *originalFilename = [self serverFilename];
        if(!originalFilename) {
            NSString *urlPath = [self.url path];
            if(urlPath) {
                originalFilename = [urlPath lastPathComponent];
            }
        }
        if(originalFilename.length) {
            uniqueString = [NSString uniquePathWithBasePath:originalFilename];
        }
        if(!uniqueString) {
            uniqueString = [NSString uniqueStringWithBaseString:[self getBookValueForKey:@"title"]];
        }
        
        if(self.serverMimetype) {
            // Put the right file extension on the file, if we can.
            CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (CFStringRef)self.serverMimetype, NULL);
            if(uti) {
                CFStringRef extension = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension);
                if(extension) {
                    uniqueString = [[uniqueString stringByDeletingPathExtension] stringByAppendingPathExtension:(NSString *)extension];
                    CFRelease(extension);
                }
                CFRelease(uti);
            }
        }        
        
        NSString *temporaryPath = [self temporaryPath];
		NSString *cachedPath = [self.cacheDirectory stringByAppendingPathComponent:uniqueString];
		// copy file to final location (cachedPath)
		NSError * error;
		if (![[NSFileManager defaultManager] moveItemAtPath:temporaryPath toPath:cachedPath error:&error]) {
            NSLog(@"Failed to move file from download cache %@ to final location %@ with error %@ : %@", temporaryPath, cachedPath, error, [error userInfo]);

        }
		else {
            
            if (![self shouldBackupDownload])
                [BlioProcessingOperation addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:cachedPath]];

			//[self setBookValue:[NSString stringWithString:(NSString *)uniqueString] forKey:self.filenameKey];
            
            if (self.bookID) {
                NSDictionary *manifestEntry = [NSMutableDictionary dictionary];
                [manifestEntry setValue:BlioManifestEntryLocationFileSystem forKey:BlioManifestEntryLocationKey];
                [manifestEntry setValue:(NSString *)uniqueString forKey:BlioManifestEntryPathKey];
            
                //          [self setBookValue:[NSString stringWithString:(NSString *)uniqueString] forKey:self.filenameKey];
                [self setBookManifestValue:manifestEntry forKey:self.filenameKey];
            }
            else if (self.songID) {
                [self setSongValue:uniqueString forKey:filenameKey];
                // Inform server that download was successful.
                // Once this happens, download will no longer be available.  So uncomment only when done testing.
                // if (self.mustReport)
                //[BlioVaultService reportDownloadCompleted:self.sourceSpecificID];
            }
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
-(BOOL)shouldBackupDownload {
    if (self.sourceID == BlioBookSourceLocalBundle || self.sourceID == BlioBookSourceLocalBundleDRM) return NO;
    return YES;
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

- (void)prepareForStartOnBackgroundThread {
    if(!self.url)  {
        if ([[BlioStoreManager sharedInstance] tokenForSourceID:self.sourceID]) {
            if ([[self getBookValueForKey:@"userNum"] intValue] == [[BlioStoreManager sharedInstance] currentUserNum]) {
                // app will contact Store for a new limited-lifetime URL.
                NSURL * newXPSURL = [[BlioStoreManager sharedInstance] URLForProductWithSourceID:sourceID sourceSpecificID:sourceSpecificID];
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
                }
            }
            else {
                NSLog(@"Book userNum and currentUserNum do not match! Cancelling BlioProcessingDownloadPaidBookOperation...");
                NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
                [userInfo setObject:self.bookID forKey:@"bookID"];
                [[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingDownloadPaidBookNonMatchingUserNotification object:self userInfo:userInfo];
            }
        }
        else {
            NSLog(@"App does not have valid token! Cancelling BlioProcessingDownloadPaidBookOperation...");
            NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
            [userInfo setObject:self.bookID forKey:@"bookID"];
            [[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingDownloadPaidBookTokenRequiredNotification object:self userInfo:userInfo];
        }
    }
    
    [super prepareForStartOnBackgroundThread];
}
-(BOOL)shouldBackupDownload {
    return NO;
}

@end

#pragma mark -
@implementation BlioProcessingDownloadPaidSongOperation

- (id)initWithUrl:(NSURL *)aURL {
    if ((self = [super initWithUrl:aURL])) {
        self.filenameKey = BlioSongKey;
        self.mustReport = YES;
    }
    return self;
}

- (void)prepareForStartOnBackgroundThread {
    if (!self.url)  {
        if ([[BlioStoreManager sharedInstance] tokenForSourceID:self.sourceID]) {
            if ([[self getSongValueForKey:@"userNum"] intValue] == [[BlioStoreManager sharedInstance] currentUserNum]) {
                NSURL * newSongURL = [[BlioStoreManager sharedInstance] URLForProductWithSourceID:sourceID sourceSpecificID:sourceSpecificID];
                if (newSongURL) {
                    NSLog(@"new Song URL: %@",[newSongURL absoluteString]);
                    self.url = newSongURL;
                }
                else {
                    NSLog(@"new Song URL was not able to be obtained from server! Cancelling BlioProcessingDownloadPaidSongOperation...");
                }
            }
            else {
                NSLog(@"Song userNum and currentUserNum do not match! Cancelling BlioProcessingDownloadPaidSongOperation...");
                NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
                [userInfo setObject:self.songID forKey:@"songID"];
                // TODO does notification handler(s) need songID?
                [[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingDownloadPaidBookNonMatchingUserNotification object:self userInfo:userInfo];
            }
        }
        else {
            NSLog(@"App does not have valid token! Cancelling BlioProcessingDownloadPaidSongOperation...");
            NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
            [userInfo setObject:self.songID forKey:@"songID"];
            // TODO does notification handler(s) need songID?
            [[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingDownloadPaidBookTokenRequiredNotification object:self userInfo:userInfo];
        }
    }
    
    [super prepareForStartOnBackgroundThread];
}
-(BOOL)shouldBackupDownload {
    return NO;
}

@end

#pragma mark -

@interface BlioProcessingXPSManifestOperation () <BlioEPubMetadataReaderDataProvider>
@end

@implementation BlioProcessingXPSManifestOperation 

@synthesize featureCompatibilityDictionary, audioFiles, timingFiles;

- (id)init {
    if ((self = [super init])) {
		self.audioFiles = [NSMutableArray array];
		self.timingFiles = [NSMutableArray array];
    }
    return self;
}
- (void)dealloc {
	self.audioFiles = nil;
	self.timingFiles = nil;
	self.featureCompatibilityDictionary = nil;
	[super dealloc];
}

- (NSData *)blioEPubMetadataReader:(BlioEPubMetadataReader *)reader copyDataForComponentAtPath:(NSString *)path
{
    return [[self getBookXPSDataWithPath:path] retain];
}

- (BOOL)blioEPubMetadataReader:(BlioEPubMetadataReader *)reader componentExistsAtPath:(NSString *)path
{
    return [self bookHasXPSDataWithPath:path];
}
    
- (void)main {
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
	
	NSDictionary *manifestEntry = nil;
	
    BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];

	BOOL hasEmbeddedEPub = [self bookManifestPath:BlioXPSEPubMetaInfContainerFile existsForLocation:BlioManifestEntryLocationXPS];
	if (hasEmbeddedEPub) {
		manifestEntry = [NSMutableDictionary dictionary];
		[manifestEntry setValue:BlioManifestEntryLocationXPS forKey:BlioManifestEntryLocationKey];
		[manifestEntry setValue:@"" forKey:BlioManifestEntryPathKey];
		[self setBookManifestValue:manifestEntry forKey:BlioManifestEPubKey];
        
        BlioEPubMetadataReader *ePubMetadata = [[BlioEPubMetadataReader alloc] initWithDataProvider:self];
        if(ePubMetadata && 
           [[NSDecimalNumber decimalNumberWithMantissa:3 exponent:0 isNegative:NO] compare:ePubMetadata.packageVersion] != NSOrderedDescending) {
            @autoreleasepool {
                [BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Advanced Book Features",@"\"Advanced Book Features\" Alert message title")
                                             message:[NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"EPUB_3_UNSUPPORTED_ALERT",nil,[NSBundle mainBundle],@"The book \"%@\" may not display fully because it may contain elements that are not supported in this version of Blio.",@"Alert message informing the end-user that an an EPUB book might contain features that this version of Blio does not support."),book.title]
                                            delegate:nil
                                   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
                                   otherButtonTitles:nil];
            }
        }
        [ePubMetadata release];
	}
	
	BOOL hasTextflowData = [self bookManifestPath:BlioXPSTextFlowSectionsFile existsForLocation:BlioManifestEntryLocationXPS];
	if (hasTextflowData) {
		manifestEntry = [NSMutableDictionary dictionary];
		[manifestEntry setValue:BlioManifestEntryLocationXPS forKey:BlioManifestEntryLocationKey];
		[manifestEntry setValue:BlioXPSTextFlowSectionsFile forKey:BlioManifestEntryPathKey];
		[self setBookManifestValue:manifestEntry forKey:BlioManifestTextFlowKey];
		NSLog(@"Textflow sections file is present. parsing XML...");
		NSData * data = [self getBookManifestDataForKey:BlioManifestTextFlowKey];
		if (data) {
            @synchronized([KNFBXMLParserLock sharedLock]) {
                textflowParser = [[NSXMLParser alloc] initWithData:data];
                [textflowParser setDelegate:self];
                [textflowParser parse];
                [textflowParser release];
                textflowParser = nil;
            }
		}
	}
	
	BOOL hasCoverData = [self bookManifestPath:BlioXPSCoverImage existsForLocation:BlioManifestEntryLocationXPS];
	if (hasCoverData) {
        // move file cover to CoverImage within cache directory
        if ([[book manifestLocationForKey:BlioManifestCoverKey] isEqualToString:BlioManifestEntryLocationFileSystem]) {
            NSString * currentCoverPath = [book manifestPathForKey:BlioManifestCoverKey];
            if (![[NSFileManager defaultManager] fileExistsAtPath:[[book cacheDirectory] stringByAppendingPathComponent:BlioManifestCoverKey]]) {
                NSError * moveOldCoverError = nil;
                [[NSFileManager defaultManager] moveItemAtPath:currentCoverPath toPath:[[book cacheDirectory] stringByAppendingPathComponent:BlioManifestCoverKey] error:&moveOldCoverError];
                if (moveOldCoverError) NSLog(@"ERROR: moving old book cover in preparation for XPS cover use: %@",[moveOldCoverError localizedDescription]);
            }
        }
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
                @synchronized([KNFBXMLParserLock sharedLock]) {
                    rightsParser = [[NSXMLParser alloc] initWithData:data];
                    [rightsParser setDelegate:self];
                    [rightsParser parse];
                    [rightsParser release];
                    rightsParser = nil;
                }
			}
		}
	}
	else {
		[self setBookValue:[NSNumber numberWithBool:YES] forKey:@"ttsRight"];
		[self setBookValue:[NSNumber numberWithBool:YES] forKey:@"reflowRight"]; 
	}
	
	hasAudiobook = [self bookManifestPath:BlioXPSAudiobookMetadataFile existsForLocation:BlioManifestEntryLocationXPS];
	NSLog(@"self.cacheDirectory %@ hasAudiobook: %i,",self.cacheDirectory, hasAudiobook);
	if (hasAudiobook) {
		NSLog(@"setting Audiobook values in manifest...");
				
		manifestEntry = [NSMutableDictionary dictionary];
		[manifestEntry setValue:BlioManifestEntryLocationXPS forKey:BlioManifestEntryLocationKey];
		[manifestEntry setValue:BlioXPSAudiobookDirectory forKey:BlioManifestEntryPathKey];
		[self setBookManifestValue:manifestEntry forKey:BlioManifestAudiobookKey];
		
		manifestEntry = [NSMutableDictionary dictionary];
		[manifestEntry setValue:BlioManifestEntryLocationXPS forKey:BlioManifestEntryLocationKey];
		[manifestEntry setValue:BlioXPSAudiobookMetadataFile forKey:BlioManifestEntryPathKey];
		[self setBookManifestValue:manifestEntry forKey:BlioManifestAudiobookMetadataKey];
		
		manifestEntry = [NSMutableDictionary dictionary];
		[manifestEntry setValue:BlioManifestEntryLocationXPS forKey:BlioManifestEntryLocationKey];
		[manifestEntry setValue:BlioXPSAudiobookReferencesFile forKey:BlioManifestEntryPathKey];
		[self setBookManifestValue:manifestEntry forKey:BlioManifestAudiobookReferencesKey];
		
		NSData * data = [self getBookManifestDataForKey:BlioManifestAudiobookReferencesKey];
		if (data) {
			// test to see if valid XML found
//			NSString * stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//			NSLog(@"stringData: %@",stringData);
//			[stringData release];
            @synchronized([KNFBXMLParserLock sharedLock]) {
                audiobookReferencesParser = [[NSXMLParser alloc] initWithData:data];
                [audiobookReferencesParser setDelegate:self];
                [audiobookReferencesParser parse];
                [audiobookReferencesParser release];
                audiobookReferencesParser = nil;
            }
		}
		else {
			hasAudiobook = NO;
		}
		//			NSLog(@"[book hasTTSRights]: %i",[book hasTTSRights]);
		//			NSLog(@"[book hasManifestValueForKey:BlioManifestAudiobookMetadataKey]: %i",[book hasManifestValueForKey:BlioManifestAudiobookMetadataKey]);
	}
	[self setBookValue:[NSNumber numberWithBool:hasAudiobook] forKey:@"audiobook"]; 

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
            @synchronized([KNFBXMLParserLock sharedLock]) {
                metadataParser = [[NSXMLParser alloc] initWithData:data];
                [metadataParser setDelegate:self];
                [metadataParser parse];
                [metadataParser release];
                metadataParser = nil;
            }
		}
	}
	
	if (!hasAudiobook && hasTextflowData && [book hasTTSRights]) {
		[self setBookValue:[NSNumber numberWithBool:YES] forKey:@"ttsCapable"]; 
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
	if (parser == audiobookReferencesParser) {
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
	else if (parser == textflowParser) {
		if ( [elementName isEqualToString:@"BookContents"] ) {
			NSString * attributeStringValue = [attributeDict objectForKey:@"NoTextFlowView"];
			if (attributeStringValue && [attributeStringValue isEqualToString:@"True"]) {
				hasReflowRightOverride = YES;
			}
			else {
				hasReflowRightOverride = NO; 
			}
		}
	}	
	else if (parser == rightsParser) {
		if ( [elementName isEqualToString:@"Audio"] ) {
			NSString * attributeStringValue = [attributeDict objectForKey:@"TTSRead"];
			if (attributeStringValue && [attributeStringValue isEqualToString:@"True"]) {
				[self setBookValue:[NSNumber numberWithBool:YES] forKey:@"ttsRight"]; 
			}
			else {
				[self setBookValue:[NSNumber numberWithBool:NO] forKey:@"ttsRight"]; 
			}
		}
		else if ( [elementName isEqualToString:@"Reflow"] ) {
			NSString * attributeEnabledStringValue = [attributeDict objectForKey:@"Enabled"];
			[self setBookValue:[NSNumber numberWithBool:NO] forKey:@"reflowRight"]; 
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
				NSString * attributeSmallScreenStringValue = [attributeDict objectForKey:@"SmallScreen"];
				if (attributeSmallScreenStringValue) {
					if ([attributeSmallScreenStringValue isEqualToString:@"True"]) 
						[self setBookValue:[NSNumber numberWithBool:YES] forKey:@"reflowRight"];
				}
				else if (attributeEnabledStringValue 
						 && [attributeEnabledStringValue isEqualToString:@"True"]
						 && !hasReflowRightOverride)
					[self setBookValue:[NSNumber numberWithBool:YES] forKey:@"reflowRight"]; 
			}
			else if (attributeEnabledStringValue 
					&& [attributeEnabledStringValue isEqualToString:@"True"]
					&& !hasReflowRightOverride)  {
					[self setBookValue:[NSNumber numberWithBool:YES] forKey:@"reflowRight"]; 
			}
		}
	}
	else if (parser == metadataParser) {
		if ( [elementName isEqualToString:@"Feature"] ) {
			if (!self.featureCompatibilityDictionary) self.featureCompatibilityDictionary = [NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"BlioFeatureCompatibility.plist"]];
			
			NSString * featureName = [attributeDict objectForKey:@"Name"];
			NSString * featureVersion = [attributeDict objectForKey:@"Version"];
			NSString * isRequired = [attributeDict objectForKey:@"IsRequired"];
			if (featureName && featureVersion && isRequired) {
                if ([featureName isEqualToString:@"TwoPageSpread"] && [[isRequired lowercaseString] isEqualToString:@"true"]) {
                    // The feature tag here is being used to state that this book requires a two-up view, not that the app requires a 2-up feature...
					[self setBookValue:[NSNumber numberWithBool:YES] forKey:@"twoPageSpread"]; 
                } else if ([[isRequired lowercaseString] isEqualToString:@"true"]) {
					NSNumber * featureCompatibilityVersion = [self.featureCompatibilityDictionary objectForKey:featureName];
//					if (featureCompatibilityVersion) NSLog(@"Required feature: %@ found. App compatibility version: %f, book version required: %f",featureName,[featureCompatibilityVersion floatValue],[featureVersion floatValue]);
//					else NSLog(@"Required feature: %@ found. App is not compatible with this feature, book version required: %f",featureName,[featureVersion floatValue]);
					if (!featureCompatibilityVersion || [featureCompatibilityVersion floatValue] < [featureVersion floatValue]) {
						// the parsed feature is not listed in the app's compatibility dictionary or the book requires a higher version than our compatibility version

						BlioBook *book = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
						[BlioAlertManager showAlertWithTitle:NSLocalizedString(@"Advanced Book Features",@"\"Advanced Book Features\" Alert message title")
													 message:[NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"INCOMPATIBLE_FEATURE",nil,[NSBundle mainBundle],@"The book \"%@\" cannot be read in this version of Blio. Please check the App Store for a Blio update.",@"Alert message informing the end-user that an incompatible feature was found during the processing of a book, and prompting the end-user to visit the iTunes App Store."),book.title]
													delegate:nil
										   cancelButtonTitle:NSLocalizedString(@"OK",@"\"OK\" label for button used to cancel/dismiss alertview")
										   otherButtonTitles:nil];
						[self setBookValue:[NSNumber numberWithInt:kBlioBookProcessingStateNotSupported] forKey:@"processingState"];
						[self cancel];
						[parser abortParsing];
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
	if (parser == audiobookReferencesParser) {	
		if ( [elementName isEqualToString:@"AudioReferences"]  ) {
			if ( [self.timingFiles count] != [self.audioFiles count] ) {
				NSLog(@"WARNING: Missing audio or timing file.");
				hasAudiobook = NO;
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
	else if (parser == metadataParser) {
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

    // Generate new filename, based on the server's filename if possible.
    NSString *uniqueString = nil;
    NSString *originalFilename = [self serverFilename];
    if(!originalFilename.length) {
        NSString *urlPath = [self.url path];
        if(urlPath) {
            originalFilename = [urlPath lastPathComponent];
        }
    }
    if(originalFilename.length) {
        uniqueString = [NSString uniquePathWithBasePath:originalFilename];
        NSString *pathExtension = [uniqueString pathExtension];
        if(pathExtension && [pathExtension caseInsensitiveCompare:@"zip"] == NSOrderedSame) {
            uniqueString = [uniqueString stringByDeletingPathExtension];
        } else {
            uniqueString = [uniqueString stringByAppendingPathExtension:@"unzipped"];
        }
    }
    if(!uniqueString) {
        uniqueString = [NSString uniqueStringWithBaseString:[self getBookValueForKey:@"title"]];
    }
    
    NSString *unzippedFilename = uniqueString;

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
//		if ([[NSFileManager defaultManager] fileExistsAtPath:temporaryPath]) {
//			NSLog(@"File does exist, moving to Documents directory for debugging...");
//			NSError * moveError;
//			NSString *debugPath = [[[BlioImportManager fileSharingDirectory] stringByAppendingPathComponent:self.filenameKey] stringByStandardizingPath];
//			NSLog(@"debugPath: %@",debugPath);
//			if (![[NSFileManager defaultManager] copyItemAtPath:temporaryPath toPath:debugPath error:&moveError]) {
//				NSLog(@"ERROR: could not move unzippable downloaded voice to Documents directory for debugging! %@,%@",[moveError localizedDescription],[moveError userInfo]);
//			}
//		}
//		else NSLog(@"because file does not exist!");
		if (expectedContentLength != NSURLResponseUnknownLength) NSLog(@"expectedContentLength: %lld",expectedContentLength);

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
-(void) setPercentageComplete:(CGFloat)percentage {
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
    }
    return self;
}

@end

#pragma mark -
@interface BlioProcessingGenerateCoverThumbsOperation()

- (NSData *)generatePDFCoverImageOfSize:(CGSize)size maintainAspectRatio:(BOOL)maintainAspectRatio;

@end

@implementation BlioProcessingGenerateCoverThumbsOperation

@synthesize maintainAspectRatio;

- (id)init {
    if ((self = [super init])) {
        maintainAspectRatio = YES;
    }
    return self;
}

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
		NSLog(@"BlioProcessingGenerateCoverThumbsOperation cancelled, will prematurely abort start");
        [pool drain];
		return;
    }
    
    NSData *imageData = nil;
    BOOL hasCover;
    if (self.bookID) {
        hasCover = [self hasBookManifestValueForKey:BlioManifestCoverKey];
        if (hasCover) {
            imageData = [self getBookManifestDataForKey:BlioManifestCoverKey];
        }
        if (!imageData) {
            BOOL isPDF = [self hasBookManifestValueForKey:BlioManifestPDFKey];
            if (isPDF) {
                CGSize screenSize = [[UIScreen mainScreen] bounds].size;
                imageData = [self generatePDFCoverImageOfSize:screenSize maintainAspectRatio:YES];
            }
        }
    }
    else if (self.songID) {
        BlioSong *song = [[BlioBookManager sharedBookManager] songWithID:self.songID];
        if (song) {
            imageData = [song coverData]; 
        }
        else
            NSLog(@"Failed to retrieve song in BlioProcessingGenerateCoverThumbsOperation main.");
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
	CGFloat maxThumbWidth = 0;
	CGFloat maxThumbHeight = 0;
	NSInteger scaledMaxThumbWidth = 0;
	NSInteger scaledMaxThumbHeight = 0;
	CGFloat targetThumbWidth = 0;
	CGFloat targetThumbHeight = 0;
	NSInteger scaledTargetThumbWidth = 0;
	NSInteger scaledTargetThumbHeight = 0;

	maxThumbWidth = kBlioCoverGridThumbWidthPhone;
	maxThumbHeight = kBlioCoverGridThumbHeightPhone;

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		maxThumbWidth = kBlioCoverGridThumbWidthPad;
		maxThumbHeight = kBlioCoverGridThumbHeightPad;
	}
    
    CGFloat scaleFactor = 1;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        scaleFactor = [[UIScreen mainScreen] scale];
    }	
	
    scaledMaxThumbWidth = round(maxThumbWidth * scaleFactor);
	scaledMaxThumbHeight = round(maxThumbHeight * scaleFactor);
	
	pixelSpecificKey = [NSString stringWithFormat:@"%@%ix%i",BlioBookThumbnailPrefix,scaledMaxThumbWidth,scaledMaxThumbHeight];
	pixelSpecificFilename = [NSString stringWithFormat:@"%@.png",pixelSpecificKey];

	targetThumbWidth = maxThumbWidth;
	targetThumbHeight = maxThumbHeight;
    
    if (maintainAspectRatio) {
        CGFloat maxToCoverWidthRatio = maxThumbWidth/cover.size.width;
        if ((cover.size.height * maxToCoverWidthRatio) < maxThumbHeight) {
            targetThumbHeight = cover.size.height * maxToCoverWidthRatio;
        }
        else {
            CGFloat maxToCoverHeightRatio = maxThumbHeight/cover.size.height;
            targetThumbWidth = cover.size.width * maxToCoverHeightRatio;
        }
    }
    
    scaledTargetThumbWidth = round(targetThumbWidth * scaleFactor);
	scaledTargetThumbHeight = round(targetThumbHeight * scaleFactor);
    
    UIImage *gridThumb = [self newThumbFromImage:cover forSize:CGSizeMake(scaledTargetThumbWidth, scaledTargetThumbHeight)];
    NSData *gridData = UIImagePNGRepresentation(gridThumb);
    NSString *gridThumbDir = [self.cacheDirectory stringByAppendingPathComponent:BlioBookThumbnailsDir];
	if (![[NSFileManager defaultManager] fileExistsAtPath:gridThumbDir]) {
		NSError * createDirectoryError;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:gridThumbDir withIntermediateDirectories:YES attributes:nil error:&createDirectoryError])
			NSLog(@"Failed to create book cache directory in processing manager with error: %@, %@", createDirectoryError, [createDirectoryError userInfo]);
	}
    NSString *gridThumbPath = [gridThumbDir stringByAppendingPathComponent:pixelSpecificFilename];
    [gridData writeToFile:gridThumbPath atomically:YES];
    [gridThumb release];
    
    NSMutableDictionary * resizedCovers = [NSMutableDictionary dictionaryWithCapacity:4];
    if (self.bookID) {
        NSDictionary *gridThumbManifestEntry = [NSMutableDictionary dictionary];
        [gridThumbManifestEntry setValue:BlioManifestEntryLocationFileSystem forKey:BlioManifestEntryLocationKey];
        [gridThumbManifestEntry setValue:[BlioBookThumbnailsDir stringByAppendingPathComponent:pixelSpecificFilename] forKey:BlioManifestEntryPathKey];
        [self setBookManifestValue:gridThumbManifestEntry forKey:pixelSpecificKey];
    }
    else if (self.songID) {
        [resizedCovers setValue:[BlioBookThumbnailsDir stringByAppendingPathComponent:pixelSpecificFilename] forKey:pixelSpecificKey];
    }
    
    if ([self isCancelled]) {
        [pool drain];
        return;
    }
    

	maxThumbWidth = kBlioCoverListThumbWidth;
	maxThumbHeight = kBlioCoverListThumbHeight;

	scaledMaxThumbWidth = round(maxThumbWidth * scaleFactor);
	scaledMaxThumbHeight = round(maxThumbHeight * scaleFactor);
	
	pixelSpecificKey = [NSString stringWithFormat:@"%@%ix%i",BlioBookThumbnailPrefix,scaledMaxThumbWidth,scaledMaxThumbHeight];
	pixelSpecificFilename = [NSString stringWithFormat:@"%@.png",pixelSpecificKey];
	
    targetThumbWidth = maxThumbWidth;
	targetThumbHeight = maxThumbHeight;
    
    if (maintainAspectRatio) {
        CGFloat maxToCoverWidthRatio = maxThumbWidth/cover.size.width;
        if ((cover.size.height * maxToCoverWidthRatio) < maxThumbHeight) {
            targetThumbHeight = cover.size.height * maxToCoverWidthRatio;
        }
        else {
            CGFloat maxToCoverHeightRatio = maxThumbHeight/cover.size.height;
            targetThumbWidth = cover.size.width * maxToCoverHeightRatio;
        }
    }
    
    scaledTargetThumbWidth = round(targetThumbWidth * scaleFactor);
	scaledTargetThumbHeight = round(targetThumbHeight * scaleFactor);

    UIImage *listThumb = [self newThumbFromImage:cover forSize:CGSizeMake(scaledTargetThumbWidth, scaledTargetThumbHeight)];
    NSData *listData = UIImagePNGRepresentation(listThumb);
	NSString *listThumbDir = [self.cacheDirectory stringByAppendingPathComponent:BlioBookThumbnailsDir];
	if (![[NSFileManager defaultManager] fileExistsAtPath:listThumbDir]) {
		NSError * createDirectoryError;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:gridThumbDir withIntermediateDirectories:YES attributes:nil error:&createDirectoryError])
			NSLog(@"Failed to create book cache directory in processing manager with error: %@, %@", createDirectoryError, [createDirectoryError userInfo]);
	}
    NSString *listThumbPath = [listThumbDir stringByAppendingPathComponent:pixelSpecificFilename];
    [listData writeToFile:listThumbPath atomically:YES];
    [listThumb release];
    
    if (self.bookID) {
        NSDictionary *listThumbManifestEntry = [NSMutableDictionary dictionary];
        [listThumbManifestEntry setValue:BlioManifestEntryLocationFileSystem forKey:BlioManifestEntryLocationKey];
        [listThumbManifestEntry setValue:[BlioBookThumbnailsDir stringByAppendingPathComponent:pixelSpecificFilename] forKey:BlioManifestEntryPathKey];
        [self setBookManifestValue:listThumbManifestEntry forKey:pixelSpecificKey];
    }
    else if (self.songID) {
        [resizedCovers setValue:[BlioBookThumbnailsDir stringByAppendingPathComponent:pixelSpecificFilename] forKey:pixelSpecificKey];
        [self setSongValue:resizedCovers forKey:BlioSongCoversDictionaryKey];
    }

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

- (NSData *)generatePDFCoverImageOfSize:(CGSize)size maintainAspectRatio:(BOOL)maintainRatio {
    
    UIImage *pdfCover = nil;
    NSData *coverData = nil;
    
    NSString *pdfPath = [self getBookValueForKey:@"pdfPath"];
               
    if (pdfPath) {
        BlioLayoutPDFDataSource *aPDFDatasource = [[BlioLayoutPDFDataSource alloc] initWithPath:pdfPath];
        CGRect cropRect = [aPDFDatasource cropRectForPage:1];        
        CGSize thumbSize = size;
        
        if (maintainRatio) {
            CGFloat maxToCoverWidthRatio = size.width/cropRect.size.width;
            if ((cropRect.size.height * maxToCoverWidthRatio) < thumbSize.height) {
                thumbSize.height = cropRect.size.height * maxToCoverWidthRatio;
            } else {
                CGFloat maxToCoverHeightRatio = size.height/cropRect.size.height;
                thumbSize.width = cropRect.size.width * maxToCoverHeightRatio;
            }
        }
        
        id backing = nil;
        CGContextRef bitmapContext = [aPDFDatasource RGBABitmapContextForPage:1 fromRect:cropRect atSize:thumbSize getBacking:&backing];
        CGImageRef pdfImage = CGBitmapContextCreateImage(bitmapContext);
        pdfCover = [UIImage imageWithCGImage:pdfImage];
        CGImageRelease(pdfImage);
        [aPDFDatasource release];
    }
    
    if (pdfCover) {
        NSString *filename = @"Cover.jpg";
        NSString *thumbDir = [[self cacheDirectory] stringByAppendingPathComponent:BlioBookThumbnailsDir];
        coverData = UIImageJPEGRepresentation(pdfCover, 0.8f);
        NSFileManager *threadsafeManager = [[[NSFileManager alloc] init] autorelease];
        
        if (![threadsafeManager fileExistsAtPath:thumbDir]) {
            NSError * createDirectoryError;
            if (![threadsafeManager createDirectoryAtPath:thumbDir withIntermediateDirectories:YES attributes:nil error:&createDirectoryError]) {
                NSLog(@"Failed to create book cache directory whilst generating PDF cover with error: %@, %@", createDirectoryError, [createDirectoryError userInfo]);
            }
        }
        
        NSString *coverPath = [thumbDir stringByAppendingPathComponent:filename];
        [coverData writeToFile:coverPath atomically:YES];
        
        NSDictionary *coverManifestEntry = [NSMutableDictionary dictionary];
        [coverManifestEntry setValue:BlioManifestEntryLocationFileSystem forKey:BlioManifestEntryLocationKey];
        [coverManifestEntry setValue:[BlioBookThumbnailsDir stringByAppendingPathComponent:filename] forKey:BlioManifestEntryPathKey];
        [self setBookManifestValue:coverManifestEntry forKey:BlioManifestCoverKey];
    }
    
    return coverData;
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
				// timing indices and audiobook metadata locations is now stored in manifest by BlioProcessingXPSManifestOperation... this operation would need significant refactoring if we were to re-support audiobooks outside of XPS in the future.
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

