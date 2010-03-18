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

@implementation BlioProcessingCompleteOperation

- (void)main {
    if ([self isCancelled]) return;
    [self setBookValue:[NSNumber numberWithBool:YES] forKey:@"processingComplete"];
}

@end

#pragma mark -
@implementation BlioProcessingDownloadOperation

@synthesize url, localFilename, tempFilename, connection, downloadFile;

- (void) dealloc {
    self.url = nil;
    self.localFilename = nil;
    self.tempFilename = nil;
    self.connection = nil;
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
        // Generate a random filename
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef uniqueString = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        self.tempFilename = [NSString stringWithString:(NSString *)uniqueString];
        CFRelease(uniqueString);
        
        executing = NO;
        finished = NO;
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
    
    if (nil == self.localFilename) {
        // Generate a random filename
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef uniqueString = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        self.localFilename = [NSString stringWithString:(NSString *)uniqueString];
        CFRelease(uniqueString);
    }
    
    NSString *cachedPath = [self.cacheDirectory stringByAppendingPathComponent:self.localFilename];

    if([self.url isFileURL]) {
        // Just symlink it to save time.
        
        NSString *fromPath = [[[self.url absoluteURL] path] stringByStandardizingPath];
        NSString *toPath = [cachedPath stringByStandardizingPath];
        
        NSArray *fromComponents = [fromPath pathComponents];
        NSArray *toComponents = [toPath pathComponents];
        
        NSUInteger i = 0;
        for(; 
            i < fromComponents.count && i < toComponents.count &&
            [[fromComponents objectAtIndex:i] isEqualToString:[toComponents objectAtIndex:i]];
            ++i) {
        }
        NSMutableArray *relativeComponents = [NSMutableArray array];
        for(NSUInteger j = i; j < (toComponents.count - 1); ++j) {
            [relativeComponents addObject:@".."];
        }
        [relativeComponents addObjectsFromArray:[fromComponents subarrayWithRange:NSMakeRange(i, fromComponents.count - i)]];
            
        NSString *relativePath = [relativeComponents componentsJoinedByString:@"/"];
        symlink([relativePath fileSystemRepresentation], [toPath fileSystemRepresentation]);
        
        NSLog(@"Symlinking from \"%@\" to \"%@\" as \"%@\" instead of downloading", fromPath, toPath, relativePath); 
        
        [self downloadDidFinishSuccessfully:YES];
        [self finish];
    } else {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if(![fileManager createFileAtPath:cachedPath contents:nil attributes:nil]) {
            NSLog(@"Could not create file to hold download");
        } else {
            self.downloadFile = [NSFileHandle fileHandleForWritingAtPath:cachedPath];
        }

        NSURLRequest *aRequest = [[NSURLRequest alloc] initWithURL:self.url];
        NSURLConnection *aConnection = [[NSURLConnection alloc] initWithRequest:aRequest delegate:self];
        [aRequest release];
        
        if (nil == aConnection) {
            [self finish];
        } else {
            self.connection = aConnection;
            [aConnection release];
        }
    }
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data {
     [self.downloadFile writeData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
    [self downloadDidFinishSuccessfully:YES];
    [self finish];
}

- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
    [self downloadDidFinishSuccessfully:NO];
    [self finish];
}

- (void)downloadDidFinishSuccessfully:(BOOL)success {
    if (!success) NSLog(@"Download did not finish successfully");
}

@end

#pragma mark -
@implementation BlioProcessingDownloadAndUnzipOperation

- (void)downloadDidFinishSuccessfully:(BOOL)success {
    if ([self isCancelled]) return;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if (!success) {
        NSLog(@"Download did not finish successfully");
        [pool drain];
        return;
    }
    
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
    if (!success) NSLog(@"Unzip did not finish successfully");
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

- (void)downloadDidFinishSuccessfully:(BOOL)success {
    if (success) [self setBookValue:self.localFilename forKey:@"coverFilename"];    
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
    [gridThumb release];
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

- (void)unzipDidFinishSuccessfully:(BOOL)success {
    if (success) [self setBookValue:self.localFilename forKey:@"epubFilename"];
}

@end

#pragma mark -
@implementation BlioProcessingDownloadPdfOperation

- (void)downloadDidFinishSuccessfully:(BOOL)success {
    if (success) [self setBookValue:self.localFilename forKey:@"pdfFilename"];    
}

@end

#pragma mark -
@implementation BlioProcessingDownloadTextFlowOperation

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
            [self setBookValue:rootFile forKey:@"textFlowFilename"];
        else
            NSLog(@"Could not find root file in Textflow directory %@", cachedFilename);
    }
}

@end

#pragma mark -
@implementation BlioProcessingDownloadAudiobookOperation

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
            [self setBookValue:audioMetadataFilename forKey:@"audiobookFilename"];
            [self setBookValue:audioReferencesFilename forKey:@"timingIndicesFilename"];
            [self setBookValue:[NSNumber numberWithBool:YES] forKey:@"hasAudioRights"]; 
        } else {
            NSLog(@"Could not find required audiobook files in AudioBook directory %@", cachedFilename);
        }        
    }
}

@end

