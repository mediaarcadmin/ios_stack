//
//  BlioProcessingOperations.m
//  BlioApp
//
//  Created by matt on 25/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioProcessingStandardOperations.h"
#import "ZipArchive.h"
#import "BlioDrmManager.h"

static const CGFloat kBlioCoverListThumbHeight = 76;
static const CGFloat kBlioCoverListThumbWidth = 53;
static const CGFloat kBlioCoverGridThumbHeight = 140;
static const CGFloat kBlioCoverGridThumbWidth = 102;

@implementation BlioProcessingCompleteOperation

@synthesize alreadyCompletedOperations;

- (void)main {
    if ([self isCancelled]) {
		NSLog(@"BlioProcessingCompleteOperation cancelled before starting (perhaps due to pause, broken internet connection, crash, or application exit)");
		return;
	}
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	[userInfo setObject:self.bookID forKey:@"bookID"];
	for (BlioProcessingOperation * blioOp in [self dependencies]) {
		if (!blioOp.operationSuccess) {
			NSLog(@"failed dependency found! Operation: %@ Sending Failed Notification...",blioOp);
			[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationFailedNotification object:self userInfo:userInfo];
			[self cancel];
			return;
		}
//		NSLog(@"completed operation: %@ percentageComplete: %u",blioOp,blioOp.percentageComplete);
	}	
	// delete temp download dir
	NSString * dirPath = [self.tempDirectory stringByStandardizingPath];
	NSError * downloadDirError;
	if (![[NSFileManager defaultManager] removeItemAtPath:dirPath error:&downloadDirError]) {
		NSLog(@"Failed to delete download directory %@ with error %@ : %@", dirPath, downloadDirError, [downloadDirError userInfo]);
	}
	NSInteger currentProcessingState = [[self getBookValueForKey:@"processingState"] intValue];
    if (currentProcessingState == kBlioBookProcessingStateNotProcessed) [self setBookValue:[NSNumber numberWithInt:kBlioBookProcessingStatePlaceholderOnly] forKey:@"processingState"];
	else [self setBookValue:[NSNumber numberWithInt:kBlioBookProcessingStateComplete] forKey:@"processingState"];
    // The following condition is done in order to prevent a thread's first-time access to [self getBookValueForKey:@"title"] (which happens when there are no dependencies- theoretically that should never happen, but a crash would occur in artificial tests so a safeguard is warranted)... could also be avoided by simply not accessing the MOC in this method for the NSLog.
    if ([NSThread isMainThread]) NSLog(@"Processing complete for book %@", [self getBookValueForKey:@"title"]);
	else NSLog(@"Processing complete for book with sourceID:%i sourceSpecificID:%@", [self sourceID],[self sourceSpecificID]);
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationCompleteNotification object:self userInfo:userInfo];
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
	self.percentageComplete = ((collectiveProgress+alreadyCompletedOperations*100)/([self.dependencies count]+alreadyCompletedOperations));
}
- (void) dealloc {
//	NSLog(@"BlioProcessingCompleteOperation dealloc entered");
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
    if ([self isCancelled]) {
		NSLog(@"BlioProcessingLicenseAcquisitionOperation cancelled before starting (perhaps due to pause, broken internet connection, crash, or application exit)");
		return;
	}
	for (BlioProcessingOperation * blioOp in [self dependencies]) {
		if (!blioOp.operationSuccess) {
			NSLog(@"failed dependency found: %@",blioOp);
			[self cancel];
			break;
		}
	}
	if ([[self getBookValueForKey:@"sourceID"] intValue] != BlioBookSourceOnlineStore) {
		NSLog(@"ERROR: Title (%@) is not an online store title!",[self getBookValueForKey:@"title"]);
		NSLog(@"xpsFilename: %@", [self getBookManifestPathForKey:@"xpsFilename"]);
		// TODO: remove the following two lines for final version (we're bypassing for now since Three Little Pigs doesn't need a license)
		self.operationSuccess = YES;
		self.percentageComplete = 100;
		return;
	}
	@synchronized ([BlioDrmManager getDrmManager]) {
		while (attemptsMade < attemptsMaximum && self.operationSuccess == NO) {
			NSLog(@"Attempt #%u to acquire license for book title: %@",(attemptsMade+1),[self getBookValueForKey:@"title"]);
            self.operationSuccess = [[BlioDrmManager getDrmManager] getLicenseForBookWithID:self.bookID];
			attemptsMade++;
		}
	}
	if (self.operationSuccess) self.percentageComplete = 100;

}
@end


#pragma mark -
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
    
    if (nil == aURL) return nil;
    
    if((self = [super init])) {
        self.url = aURL;
		self.connection = nil;
		self.headConnection = nil;
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
    
    [self willChangeValueForKey:@"isExecuting"];
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];

    // create temp download dir
	NSString * dirPath = [self.tempDirectory stringByStandardizingPath];
	NSError * downloadDirError;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
		if (![[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&downloadDirError]) {
			NSLog(@"Failed to create download directory %@ with error %@ : %@", dirPath, downloadDirError, [downloadDirError userInfo]);
		}
	}
    if([self.url isFileURL]) {
		
		NSString *cachedPath = [self.tempDirectory stringByAppendingPathComponent:self.filenameKey];
        
		// Just copy the local files to save time
        NSError *error;
        NSString *fromPath = [[[self.url absoluteURL] path] stringByStandardizingPath];
//        if ([[NSFileManager defaultManager] fileExistsAtPath:fromPath]) NSLog(@"file exists at fromPath: %@",fromPath);
		NSString *toPath = [cachedPath stringByStandardizingPath];
//        if ([[NSFileManager defaultManager] fileExistsAtPath:toPath]) NSLog(@"file exists at toPath: %@",toPath);
        
        if (![[NSFileManager defaultManager] copyItemAtPath:fromPath toPath:toPath error:&error]) {
            NSLog(@"Failed to copy file from %@ to %@ with error %@ : %@", fromPath, toPath, error, [error userInfo]);
        }


        [self downloadDidFinishSuccessfully:YES];
        [self finish];
    } else {
		// net URL
		
		if (resume) {
			// downloadHead first
			[self headDownload];			
		}
		else {
			[self startDownload];
		}
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
			NSLog(@"rangeString: %@",rangeString);
			[aRequest addValue:rangeString forHTTPHeaderField:@"Range"];
		}
		else resume = NO;
	}
	NSURLConnection *aConnection = [[NSURLConnection alloc] initWithRequest:aRequest delegate:self];
	[aRequest release];
	
	if (nil == aConnection) {
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
//	NSLog(@"connection didReceiveResponse: %@",[[response URL] absoluteString]);
	self.expectedContentLength = [response expectedContentLength];
	NSHTTPURLResponse * httpResponse;
	
	httpResponse = (NSHTTPURLResponse *) response;
	assert( [httpResponse isKindOfClass:[NSHTTPURLResponse class]] );
//	NSLog(@"response connection httpResponse.statusCode:%i",httpResponse.statusCode);
	
	if (theConnection == headConnection) {		
		if (httpResponse.statusCode/100 != 2) {
			// we are not getting valid response; try again from scratch.
			resume = NO;
			[theConnection cancel];
			[self startDownload];
		}
		else {
			NSString * acceptRanges = [httpResponse.allHeaderFields objectForKey:@"Accept-Ranges"];
			if (acceptRanges == nil) {
//				NSLog(@"No Accept-Ranges available.");
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
		if (httpResponse.statusCode != 206 && resume == YES && forceReprocess == NO) {
			// we are not getting partial content; try again from scratch.
			// TODO: just erase previous progress and keep using this connection instead of starting from scratch
			resume = NO;
			[theConnection cancel];
			[self startDownload];
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
//			NSLog(@"Download operation percentageComplete for asset %@: %u",self.localFilename,self.percentageComplete);
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
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	[userInfo setObject:self.bookID forKey:@"bookID"];
	if (!success) {
		NSLog(@"BlioProcessingDownloadOperation: Download did not finish successfully");
		NSLog(@"for url: %@",[self.url absoluteString]);
		[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationFailedNotification object:self userInfo:userInfo];		
	}
	else {
		// generate new filename
		CFUUIDRef theUUID = CFUUIDCreate(NULL);
		CFStringRef uniqueString = CFUUIDCreateString(NULL, theUUID);
		CFRelease(theUUID);

		NSString *temporaryPath = [self temporaryPath];
		NSString *cachedPath = [self.cacheDirectory stringByAppendingPathComponent:[NSString stringWithString:(NSString *)uniqueString]];
		// copy file to final location (cachedPath)
		NSError * error;
		if (![[NSFileManager defaultManager] moveItemAtPath:temporaryPath toPath:cachedPath error:&error]) {
            NSLog(@"Failed to move file from download cache %@ to final location %@ with error %@ : %@", temporaryPath, cachedPath, error, [error userInfo]);

        }
		else {
			//[self setBookValue:[NSString stringWithString:(NSString *)uniqueString] forKey:self.filenameKey];
            NSDictionary *manifestEntry = [NSMutableDictionary dictionary];
            [manifestEntry setValue:BlioManifestEntryLocationFileSystem forKey:@"location"];
            [manifestEntry setValue:(NSString *)uniqueString forKey:@"path"];
            
            [self setBookValue:[NSString stringWithString:(NSString *)uniqueString] forKey:self.filenameKey];
            [self setBookManifestValue:manifestEntry forKey:self.filenameKey];
			self.operationSuccess = YES;
			self.percentageComplete = 100;
			[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationCompleteNotification object:self userInfo:userInfo];			
		}
		CFRelease(uniqueString);

	}
}

@end

#pragma mark -
@implementation BlioProcessingDownloadPaidBookOperation
- (id)initWithUrl:(NSURL *)aURL {
    if ((self = [super initWithUrl:aURL])) {
		self.filenameKey = @"xpsFilename";
    }
    return self;
}

- (void)downloadDidFinishSuccessfully:(BOOL)success {
    if (success) {
        NSDictionary *manifestEntry = [NSMutableDictionary dictionary];
        [manifestEntry setValue:BlioManifestEntryLocationXPS forKey:@"location"];
        [manifestEntry setValue:BlioXPSTextFlowSectionsFile forKey:@"path"];
        [self setBookManifestValue:manifestEntry forKey:@"textFlowFilename"];
        
        manifestEntry = [NSMutableDictionary dictionary];
        [manifestEntry setValue:BlioManifestEntryLocationXPS forKey:@"location"];
        [manifestEntry setValue:BlioXPSCoverImage forKey:@"path"];
        [self setBookManifestValue:manifestEntry forKey:@"coverFilename"];
    }

    [super downloadDidFinishSuccessfully:success];
}

@end

#pragma mark -
@implementation BlioProcessingDownloadAndUnzipOperation

- (void)downloadDidFinishSuccessfully:(BOOL)success {
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	[userInfo setObject:self.bookID forKey:@"bookID"];
    if ([self isCancelled]) return;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if (!success) {
        NSLog(@"BlioProcessingDownloadAndUnzipOperation: Download did not finish successfully for url: %@",[self.url absoluteString]);
        [pool drain];
        return;
    }

	// Generate a random filename
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	CFStringRef uniqueString = CFUUIDCreateString(NULL, theUUID);
	CFRelease(theUUID);
	NSString *unzippedFilename = [NSString stringWithString:(NSString *)uniqueString];
	CFRelease(uniqueString);
	
	
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
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	[userInfo setObject:self.bookID forKey:@"bookID"];
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
            [manifestEntry setValue:BlioManifestEntryLocationFileSystem forKey:@"location"];
            [manifestEntry setValue:self.localFilename forKey:@"path"];
            
            [self setBookManifestValue:manifestEntry forKey:self.filenameKey];
            
            //[self setBookValue:self.localFilename forKey:self.filenameKey];
			self.operationSuccess = YES;
			[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationCompleteNotification object:self userInfo:userInfo];			
		}
	} else {
		NSLog(@"Unzip did not finish successfully");
		[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingOperationFailedNotification object:self userInfo:userInfo];			
	}
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
		self.filenameKey = @"coverFilename";
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

- (UIImage *)createThumbFromImage:(UIImage *)image forSize:(CGSize)size {
    
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
	for (BlioProcessingOperation * blioOp in [self dependencies]) {
		if (!blioOp.operationSuccess) {
			NSLog(@"failed dependency found!");
			[self cancel];
			break;
		}
	}	
    if ([self isCancelled]) {
		NSLog(@"Operation cancelled, will prematurely abort start");
		return;
    }
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSData *imageData = [self getBookManifestDataForKey:@"coverFilename"];    
    UIImage *cover = [UIImage imageWithData:imageData];
    
    if (nil == cover) {
        NSLog(@"Failed to create generate cover thumbs because cover image was not an image.");
        [pool drain];
        return;
    }
    
    if ([self isCancelled]) {
        [pool drain];
        return;
    }
    
    UIImage *gridThumb = [self createThumbFromImage:cover forSize:CGSizeMake(kBlioCoverGridThumbWidth, kBlioCoverGridThumbHeight)];
    NSData *gridData = UIImagePNGRepresentation(gridThumb);
    NSString *gridThumbPath = [self.cacheDirectory stringByAppendingPathComponent:@"gridThumb.png"];
    [gridData writeToFile:gridThumbPath atomically:YES];
    [gridThumb release]; // this is giving an ERROR (TODO)
    
    NSDictionary *gridThumbManifestEntry = [NSMutableDictionary dictionary];
    [gridThumbManifestEntry setValue:BlioManifestEntryLocationFileSystem forKey:@"location"];
    [gridThumbManifestEntry setValue:@"gridThumb.png" forKey:@"path"];
    [self setBookManifestValue:gridThumbManifestEntry forKey:@"gridThumbFilename"];

    if ([self isCancelled]) {
        [pool drain];
        return;
    }
    
    UIImage *listThumb = [self createThumbFromImage:cover forSize:CGSizeMake(kBlioCoverListThumbWidth, kBlioCoverListThumbHeight)];
    NSData *listData = UIImagePNGRepresentation(listThumb);
    NSString *listThumbPath = [self.cacheDirectory stringByAppendingPathComponent:@"listThumb.png"];
    [listData writeToFile:listThumbPath atomically:YES];
    [listThumb release];
    
    NSDictionary *listThumbManifestEntry = [NSMutableDictionary dictionary];
    [listThumbManifestEntry setValue:BlioManifestEntryLocationFileSystem forKey:@"location"];
    [listThumbManifestEntry setValue:@"listThumb.png" forKey:@"path"];
    [self setBookManifestValue:listThumbManifestEntry forKey:@"listThumbFilename"];
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
		self.filenameKey = @"epubFilename";
    }
    return self;
}

@end

#pragma mark -
@implementation BlioProcessingDownloadPdfOperation

- (id)initWithUrl:(NSURL *)aURL {
    if ((self = [super initWithUrl:aURL])) {
		self.filenameKey = @"pdfFilename";
    }
    return self;
}

@end

#pragma mark -
@implementation BlioProcessingDownloadXPSOperation

- (id)initWithUrl:(NSURL *)aURL {
    if ((self = [super initWithUrl:aURL])) {
		self.filenameKey = @"xpsFilename";
    }
    return self;
}

@end

#pragma mark -
@implementation BlioProcessingDownloadTextFlowOperation
- (id)initWithUrl:(NSURL *)aURL {
    if ((self = [super initWithUrl:aURL])) {
		self.filenameKey = @"textFlowFilename";
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
                [manifestEntry setValue:BlioManifestEntryLocationTextflow forKey:@"location"];
                [manifestEntry setValue:rootFile forKey:@"path"];
				[self setBookManifestValue:manifestEntry forKey:self.filenameKey];
				self.operationSuccess = YES;
				self.percentageComplete = 100;
			}
		}
        else
            NSLog(@"Could not find root file in Textflow directory %@", cachedFilename);
    }
}

@end

#pragma mark -
@implementation BlioProcessingDownloadAudiobookOperation
- (id)initWithUrl:(NSURL *)aURL {
    if ((self = [super initWithUrl:aURL])) {
		self.filenameKey = @"audiobookFilename";
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
				[self setBookValue:[NSNumber numberWithBool:YES] forKey:@"hasAudioRights"]; 
				self.operationSuccess = YES;
				self.percentageComplete = 100;
			}
        } else {
            NSLog(@"Could not find required audiobook files in AudioBook directory %@", temporaryPath);
        }        
    }
}

@end

