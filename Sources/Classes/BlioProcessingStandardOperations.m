//
//  BlioProcessingOperations.m
//  BlioApp
//
//  Created by matt on 25/02/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioProcessingStandardOperations.h"
#import "ZipArchive.h"

static const CGFloat kBlioCoverListThumbHeight = 76;
static const CGFloat kBlioCoverListThumbWidth = 53;
static const CGFloat kBlioCoverGridThumbHeight = 140;
static const CGFloat kBlioCoverGridThumbWidth = 102;

NSString * const BlioProcessingCompleteOperationFinishedNotification = @"BlioProcessingCompleteOperationFinishedNotification";


@implementation BlioProcessingCompleteOperation

- (void)main {
    if ([self isCancelled]) return;
    [self setBookValue:[NSNumber numberWithBool:YES] forKey:@"processingComplete"];
    NSLog(@"Processing complete for book %@", [self getBookValueForKey:@"title"]);
//    NSLog(@"sourceID:%@ sourceSpecificID:%@", [self getBookValueForKey:@"sourceID"],[self getBookValueForKey:@"sourceSpecificID"]);
	[[NSNotificationCenter defaultCenter] postNotificationName:BlioProcessingCompleteOperationFinishedNotification object:self];
}

@end

#pragma mark -
@implementation BlioProcessingDownloadOperation

@synthesize url, filenameKey, localFilename, tempFilename, connection, headConnection, downloadFile,resume,expectedContentLength;

- (void) dealloc {
    self.url = nil;
    self.filenameKey = nil;
    self.localFilename = nil;
    self.tempFilename = nil;
    self.connection = nil;
    self.headConnection = nil;
    self.downloadFile = nil;
    [super dealloc];
}

//- (id)initWithUrl:(NSURL *)aURL {
//    
//    if (nil == aURL) return nil;
//    
//    if((self = [super init])) {
//        self.url = aURL;
//    }
//    
//    return self;
//}

- (id)initWithUrl:(NSURL *)aURL {
    
    if (nil == aURL) return nil;
    
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
    
    if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];

	// localFilename should've been set in ProcessingManager
//    NSLog(@"self.url: %@",[self.url absoluteString]);
 //   NSLog(@"self.localFilename: %@",self.localFilename);
	if (self.localFilename == nil || [self.localFilename isEqualToString:@""]) {
        // Processing manager did not set localFilename from context. Therefore generate a random filename
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef uniqueString = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        self.localFilename = [NSString stringWithString:(NSString *)uniqueString];
        CFRelease(uniqueString);
		[self setBookValue:self.localFilename forKey:self.filenameKey];
    }
	else resume = YES;
    
    NSString *cachedPath = [self.cacheDirectory stringByAppendingPathComponent:self.localFilename];

    if([self.url isFileURL]) {
        // Just copy the local files to save time
        NSError *error;
        NSString *fromPath = [[[self.url absoluteURL] path] stringByStandardizingPath];
        NSString *toPath = [cachedPath stringByStandardizingPath];
        
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
- (void)startDownload {
    NSString *cachedPath = [self.cacheDirectory stringByAppendingPathComponent:self.localFilename];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (resume == NO) {
		// if not resuming, delete whatever is in place
		if ([NSFileHandle fileHandleForWritingAtPath:cachedPath] != nil) [fileManager removeItemAtPath:cachedPath error:NULL];
	}
	// ensure there is a file in place
	if ([NSFileHandle fileHandleForWritingAtPath:cachedPath] == nil) {
		if (![fileManager createFileAtPath:cachedPath contents:nil attributes:nil]) {
			NSLog(@"Could not create file to hold download");
			[self downloadDidFinishSuccessfully:NO];
			[self finish];
		}
	}
	self.downloadFile = [NSFileHandle fileHandleForWritingAtPath:cachedPath];
	NSMutableURLRequest *aRequest = [[NSMutableURLRequest alloc] initWithURL:self.url];
//	NSLog(@"about to start connection to URL: %@",[self.url absoluteString]);
	if (resume) {
		// add range header
		NSError * error = nil;
		NSDictionary * fileAttributes = [fileManager attributesOfItemAtPath:cachedPath error:&error];
		if (error != nil) {
            NSLog(@"Failed to retrieve file attributes from path:%@ with error %@ : %@", cachedPath, error, [error userInfo]);
		}
		NSNumber * bytesAlreadyDownloaded = [fileAttributes valueForKey:NSFileSize];
//		NSLog(@"bytesAlreadyDownloaded: %@",[bytesAlreadyDownloaded stringValue]);
		// TODO: add support for etag in header. See http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.27
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
		if (httpResponse.statusCode != 206 && resume == YES) {
			// we are not getting partial content; try again from scratch.
			// TODO: just erase previous progress and keep using this connection instead of starting from scratch
			resume = NO;
			[theConnection cancel];
			[self startDownload];
		}		
	}
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data {
    if (self.connection == aConnection) {
//		NSLog(@"connection didReceiveData");
		[self.downloadFile writeData:data];
	}
	else {
		
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
	if (!success) {
		NSLog(@"Download did not finish successfully");
		NSLog(@"for url: %@",[self.url absoluteString]);
	}
	// NOTE: setting localFilename of book is now done immediately upon generating new uuid, so as to accommodate resuming downloads.
}

@end

#pragma mark -
@implementation BlioProcessingDownloadAndUnzipOperation

- (void)downloadDidFinishSuccessfully:(BOOL)success {
    if ([self isCancelled]) return;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if (!success) {
        NSLog(@"Download did not finish successfully");
		NSLog(@"for url: %@",[self.url absoluteString]);
        [pool drain];
        return;
    }
//	NSLog(@"Download finished successfully"); 
//	NSLog(@"for url: %@",[self.url absoluteString]);
    
    NSString *unzippedFilename = [self.localFilename stringByDeletingPathExtension];
    if ([unzippedFilename isEqualToString:self.localFilename]) {
        // Generate a random filename
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef uniqueString = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        unzippedFilename = [NSString stringWithString:(NSString *)uniqueString];
        CFRelease(uniqueString);
    }
        
    BOOL unzipSuccess = NO;
    ZipArchive* aZipArchive = [[ZipArchive alloc] init];
	if([aZipArchive UnzipOpenFile:[self.cacheDirectory stringByAppendingPathComponent:self.localFilename]] ) {
		if (![aZipArchive UnzipFileTo:[self.cacheDirectory stringByAppendingPathComponent:unzippedFilename] overWrite:YES]) {
            NSLog(@"Failed to unzip file from %@ to %@", self.localFilename, unzippedFilename);
        } else {
            unzipSuccess = YES;
        }

		[aZipArchive UnzipCloseFile];
	} else {
        NSLog(@"Failed to open zipfile at path: %@", [self.cacheDirectory stringByAppendingPathComponent:self.localFilename]);
    }
    
	[aZipArchive release];

    NSError *anError;
    if (![[NSFileManager defaultManager] removeItemAtPath:[self.cacheDirectory stringByAppendingPathComponent:self.localFilename] error:&anError])
        NSLog(@"Failed to delete zip file at path %@ with error: %@, %@", [self.cacheDirectory stringByAppendingPathComponent:self.localFilename], anError, [anError userInfo]);

    self.localFilename = unzippedFilename;
    
    [self unzipDidFinishSuccessfully:unzipSuccess];    
    
    [pool drain];
}

- (void)unzipDidFinishSuccessfully:(BOOL)success {
    if (success) [self setBookValue:self.localFilename forKey:self.filenameKey];
    else NSLog(@"Unzip did not finish successfully");
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
    if ([self isCancelled]) return;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSString *coverFile = [self getBookValueForKey:@"coverFilename"]; 
    NSString *coverPath = [self.cacheDirectory stringByAppendingPathComponent:coverFile];
    if (![[NSFileManager defaultManager] fileExistsAtPath:coverPath]) {
        NSLog(@"Could not create thumbs because cover file did not exist at path: %@.", coverPath);
        [pool drain];
        return;
    }
    
    NSData *imageData = [NSData dataWithContentsOfMappedFile:coverPath];
    UIImage *cover = [UIImage imageWithData:imageData];
    
    if (nil == cover) {
        NSLog(@"Could not create thumbs because cover image at path %@ was not an image.", coverPath);
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
    [self setBookValue:@"gridThumb.png" forKey:@"gridThumbFilename"];
    
    if ([self isCancelled]) {
        [pool drain];
        return;
    }
    
    UIImage *listThumb = [self createThumbFromImage:cover forSize:CGSizeMake(kBlioCoverListThumbWidth, kBlioCoverListThumbHeight)];
    NSData *listData = UIImagePNGRepresentation(listThumb);
    NSString *listThumbPath = [self.cacheDirectory stringByAppendingPathComponent:@"listThumb.png"];
    [listData writeToFile:listThumbPath atomically:YES];
    [listThumb release];
    [self setBookValue:@"listThumb.png" forKey:@"listThumbFilename"];
    
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
        NSString *cachedFilename = [self.cacheDirectory stringByAppendingPathComponent:self.localFilename];
        NSString *targetFilename = [self.cacheDirectory stringByAppendingPathComponent:@"TextFlow"];
        
        if (![[NSFileManager defaultManager] moveItemAtPath:cachedFilename toPath:targetFilename error:&anError]) {
            NSLog(@"Error whilst attempting to move file %@ to %@", cachedFilename, targetFilename);
            return;
        }
        
        // Identify textFlow root file
        NSArray *textFlowFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:targetFilename error:&anError];
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
        
        if (nil != rootFile)
            [self setBookValue:rootFile forKey:self.filenameKey];
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
        NSString *cachedFilename = [self.cacheDirectory stringByAppendingPathComponent:self.localFilename];
        NSString *targetFilename = [self.cacheDirectory stringByAppendingPathComponent:@"Audiobook"];
        
        if (![[NSFileManager defaultManager] moveItemAtPath:cachedFilename toPath:targetFilename error:&anError]) {
            NSLog(@"Error whilst attempting to move file %@ to %@", cachedFilename, targetFilename);
            return;
        }
        
        // Identify Audiobook root files        
        // TODO These checks (especially for the root rtx file) are not robust
        NSArray *audioFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:targetFilename error:&anError];
        if (nil == audioFiles)
            NSLog(@"Error whilst enumerating Audiobook directory %@: %@, %@", targetFilename, anError, [anError userInfo]);
        
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
		// For now keep the old key names.
        if (audioMetadataFilename && audioReferencesFilename) {
            [self setBookValue:audioMetadataFilename forKey:self.filenameKey];
            [self setBookValue:audioReferencesFilename forKey:@"timingIndicesFilename"];
            [self setBookValue:[NSNumber numberWithBool:YES] forKey:@"hasAudioRights"]; 
        } else {
            NSLog(@"Could not find required audiobook files in AudioBook directory %@", cachedFilename);
        }        
    }
}

@end

