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

@synthesize url, localFilename;

- (void) dealloc {
    self.url = nil;
    self.localFilename = nil;
    [super dealloc];
}

- (id)initWithUrl:(NSURL *)aURL {
    
    if (nil == aURL) return nil;
    
    if((self = [super init])) {
        self.url = aURL;
    }
    
    return self;
}

- (void)main {
    if ([self isCancelled]) return;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSError *error;
    NSURLResponse *response;
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:self.url];
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [request release];
    
    if (error) {
        NSLog(@"Failed to download from URL %@ with error: %@, %@", self.url, error, [error userInfo]);
        [pool drain];
        return;
    }
    
    if ([self isCancelled]) {
        [pool drain];
        return;
    }
    
    if (nil == self.localFilename) {
        // Generate a random filename
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef uniqueString = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        self.localFilename = [NSString stringWithString:(NSString *)uniqueString];
        CFRelease(uniqueString);
    }
    
    NSString *extension = [[response suggestedFilename] pathExtension];
    if (extension)
        self.localFilename = [[self.localFilename stringByDeletingPathExtension] stringByAppendingPathExtension:extension];

    
    NSString *cachedFilename = [self.cacheDirectory stringByAppendingPathComponent:self.localFilename];
    BOOL success = [data writeToFile:cachedFilename atomically:YES];
    
    [self downloadDidFinishSuccessfully:success];
    
    [pool drain];
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

    NSError *error;
    if (![[NSFileManager defaultManager] removeItemAtPath:[self.cacheDirectory stringByAppendingPathComponent:self.localFilename] error:&error])
        NSLog(@"Failed to delete zip file at path %@ with error: %@, %@", [self.cacheDirectory stringByAppendingPathComponent:self.localFilename], error, [error userInfo]);

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
        NSLog(@"Could not create thumbs because cover image was corrupt.");
        [pool drain];
        return;
    }
    
    if ([self isCancelled]) {
        [pool drain];
        return;
    }
    
    NSString *gridThumbFilename = @"gridThumb.png";
    UIImage *gridThumb = [self createThumbFromImage:cover forSize:CGSizeMake(kBlioCoverGridThumbWidth, kBlioCoverGridThumbHeight)];
    NSData *gridData = UIImagePNGRepresentation(gridThumb);
    NSString *gridThumbPath = [self.cacheDirectory stringByAppendingPathComponent:gridThumbFilename];
    [gridData writeToFile:gridThumbPath atomically:YES];
    [gridThumb release];
    [self setBookValue:gridThumbFilename forKey:@"gridThumbFilename"];
    
    if ([self isCancelled]) {
        [pool drain];
        return;
    }
    
    NSString *listThumbFilename = @"listThumb.png";
    UIImage *listThumb = [self createThumbFromImage:cover forSize:CGSizeMake(kBlioCoverListThumbWidth, kBlioCoverListThumbHeight)];
    NSData *listData = UIImagePNGRepresentation(listThumb);
    NSString *listThumbPath = [self.cacheDirectory stringByAppendingPathComponent:@"listThumb.png"];
    [listData writeToFile:listThumbPath atomically:YES];
    [listThumb release];
    [self setBookValue:listThumbFilename forKey:@"listThumbFilename"];
    
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
        NSError *error;
        
        // Rename the unzipped folder to be TextFlow
        NSString *cachedFilename = [self.cacheDirectory stringByAppendingPathComponent:self.localFilename];
        NSString *targetFilename = [self.cacheDirectory stringByAppendingPathComponent:@"TextFlow"];
        
        if (![[NSFileManager defaultManager] moveItemAtPath:cachedFilename toPath:targetFilename error:&error]) {
            NSLog(@"Error whilst attempting to move file %@ to %@", cachedFilename, targetFilename);
            return;
        }
        
        // Identify textFlow root file
        NSArray *textFlowFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:targetFilename error:&error];
        if (nil == textFlowFiles)
            NSLog(@"Error whilst enumerating Textflow directory %@: %@, %@", targetFilename, error, [error userInfo]);
        
        NSString *rootFile = nil;
        for (NSString *textFlowFile in textFlowFiles) {
            NSRange rootIDRange = [textFlowFile rangeOfString:@"_split.xml"];
            if (rootIDRange.location != NSNotFound) {
                rootFile = textFlowFile;
                break;
            }
        }
        
        if (nil != rootFile)
            [self setBookValue:rootFile forKey:@"textflowFilename"];
        else
            NSLog(@"Could not find root file in Textflow directory %@", cachedFilename);
    }
}

@end

#pragma mark -
@implementation BlioProcessingDownloadAudiobookOperation

- (void)unzipDidFinishSuccessfully:(BOOL)success {
    if (success) {
        NSError *error;
        
        // Rename the unzipped folder to be Audiobook
        NSString *cachedFilename = [self.cacheDirectory stringByAppendingPathComponent:self.localFilename];
        NSString *targetFilename = [self.cacheDirectory stringByAppendingPathComponent:@"Audiobook"];
        
        if (![[NSFileManager defaultManager] moveItemAtPath:cachedFilename toPath:targetFilename error:&error]) {
            NSLog(@"Error whilst attempting to move file %@ to %@", cachedFilename, targetFilename);
            return;
        }
        
        // Identify Audiobook root files        
        // TODO These checks (especially for the root rtx file) are not robust
        NSArray *audioFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:targetFilename error:&error];
        if (nil == audioFiles)
            NSLog(@"Error whilst enumerating Audiobook directory %@: %@, %@", targetFilename, error, [error userInfo]);
        
        NSString *audiobookFilename = nil;
        NSString *timingIndicesFilename = nil;
        NSUInteger rtxFilenameLength = 100000;
        for (NSString *audioFile in audioFiles) {
            NSRange mp3Range = [audioFile rangeOfString:@".mp3"];
            if (mp3Range.location != NSNotFound) {
                audiobookFilename = audioFile;
            }
            NSRange rtxRange = [audioFile rangeOfString:@".rtx"];
            if (rtxRange.location != NSNotFound) {
                NSUInteger filenameLength = [audioFile length];
                if (filenameLength < rtxFilenameLength) {
                    timingIndicesFilename = audioFile;
                    rtxFilenameLength = filenameLength;
                }
            }
        }
        
        if (audiobookFilename && timingIndicesFilename) {
            [self setBookValue:audiobookFilename forKey:@"audiobookFilename"];
            [self setBookValue:timingIndicesFilename forKey:@"timingIndicesFilename"];
            [self setBookValue:[NSNumber numberWithBool:YES] forKey:@"hasAudioRights"];
        } else {
            NSLog(@"Could not find required audiobook files in AudioBook directory %@", cachedFilename);
        }        
    }
}

@end
