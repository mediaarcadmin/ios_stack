//
//  BlioXPSProvider.m
//  BlioApp
//
//  Created by matt on 08/07/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioXPSProvider.h"
#import "BlioBook.h"
#import "BlioXPSProvider.h"
#import "BlioBookManager.h"
#import "BlioDrmSessionManager.h"
#import "BlioLayoutHyperlink.h"
#import "zlib.h"
#import <objc/runtime.h>

URI_HANDLE BlioXPSProviderDRMOpen(const char * pszURI, void * data);
void BlioXPSProviderDRMRewind(URI_HANDLE h);
size_t BlioXPSProviderDRMSkip(URI_HANDLE h, size_t cb);
size_t BlioXPSProviderDRMRead(URI_HANDLE h, unsigned char * pb, size_t cb);
size_t BlioXPSProviderDRMSize(URI_HANDLE h);
void BlioXPSProviderDRMClose(URI_HANDLE h);

@interface BlioXPSBitmapReleaseCallback : NSObject {
    void *data;
}

@property (nonatomic, assign) void *data;

@end

@interface BlioXPSProvider()

@property (nonatomic, assign, readonly) BlioBook *book;
@property (nonatomic, retain) NSString *tempDirectory;
@property (nonatomic, assign) RasterImageInfo *imageInfo;
@property (nonatomic, retain) NSMutableDictionary *xpsData;
@property (nonatomic, retain) NSMutableArray *uriMap;
@property (nonatomic, retain) BlioTimeOrderedCache *componentCache;
@property (nonatomic, assign, readonly) BOOL bookIsEncrypted;
@property (nonatomic, retain) BlioDrmSessionManager* drmSessionManager;

- (void)deleteTemporaryDirectoryAtPath:(NSString *)path;
- (NSData *)decompressWithRawDeflate:(NSData *)data;
- (NSData *)decompressWithGZipCompression:(NSData *)data;
- (NSArray *)extractHyperlinks:(NSData *)data;

@end

@implementation BlioXPSProvider

@synthesize bookID;
@synthesize tempDirectory, imageInfo, xpsData, uriMap;
@synthesize componentCache;
@synthesize drmSessionManager;

- (BlioDrmSessionManager*)drmSessionManager {
	if ( !drmSessionManager ) {
		[self setDrmSessionManager:[[BlioDrmSessionManager alloc] initWithBookID:self.bookID]];
        if ([drmSessionManager bindToLicense]) {
            decryptionAvailable = YES;
            if (reportingStatus != kBlioXPSProviderReportingStatusComplete) {
                reportingStatus = kBlioXPSProviderReportingStatusRequired;
            }
        }
    }
	return drmSessionManager;
}

- (void)dealloc {   
    [renderingLock lock];
    [contentsLock lock];
    [inflateLock lock];
    XPS_Cancel(xpsHandle);
    XPS_Close(xpsHandle);
    XPS_End();
    [renderingLock unlock];
    [contentsLock unlock];
    [inflateLock unlock];
    
    [self deleteTemporaryDirectoryAtPath:self.tempDirectory];
    
    self.tempDirectory = nil;
    self.imageInfo = nil;
    self.bookID = nil;
    self.xpsData = nil;
    self.uriMap = nil;
    
    if (currentUriString) {
        [currentUriString release];
    }
    
    [renderingLock release];
    [contentsLock release];
    [inflateLock release];
    
    self.componentCache = nil;
    
    if (drmSessionManager) {
		[drmSessionManager release];
    }
	
    [super dealloc];
}

- (id)initWithBookID:(NSManagedObjectID *)aBookID {
    if ((self = [super init])) {
        self.bookID = aBookID;
		
        renderingLock = [[NSLock alloc] init];
        contentsLock = [[NSLock alloc] init];
        inflateLock = [[NSLock alloc] init];
        
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef UUIDString = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        self.tempDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:(NSString *)UUIDString];
        //NSLog(@"temp string is %@ for book with ID %@", (NSString *)UUIDString, self.bookID);
        
        NSError *error;
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.tempDirectory]) {
            if (![[NSFileManager defaultManager] createDirectoryAtPath:self.tempDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
                NSLog(@"Unable to create temp XPS directory at path %@ with error %@ : %@", self.tempDirectory, error, [error userInfo]);
                CFRelease(UUIDString);
                return nil;
            }
        }
        
        XPS_Start();
        NSString *xpsPath = [self.book xpsPath];
        if (![[NSFileManager defaultManager] fileExistsAtPath:xpsPath]) {
            NSLog(@"Error creating xpsProvider. File does not exist at path: %@", xpsPath);
            CFRelease(UUIDString);
            return nil;
        }
        
        xpsHandle = XPS_Open([xpsPath UTF8String], [self.tempDirectory UTF8String]);
        
        decryptionAvailable = NO;
        
        if ([self bookIsEncrypted]) {
            XPS_URI_PLUGIN_INFO	upi = {
                XPS_URI_SOURCE_PLUGIN,
                sizeof(XPS_URI_PLUGIN_INFO),
                "",
                self,
                BlioXPSProviderDRMOpen,
                NULL,
                BlioXPSProviderDRMRewind,
                BlioXPSProviderDRMSkip,
                BlioXPSProviderDRMRead,
                BlioXPSProviderDRMSize,
                BlioXPSProviderDRMClose
            };
            
            strncpy(upi.guid, [(NSString *)UUIDString UTF8String], [(NSString *)UUIDString length]);
        
            XPS_RegisterDrmHandler(xpsHandle, &upi);
            //NSLog(@"Registered drm handler for book %@ with handle %p with userdata %p", [self.book valueForKey:@"title"], xpsHandle, self);
        }
        CFRelease(UUIDString);
        
        XPS_SetAntiAliasMode(xpsHandle, XPS_ANTIALIAS_ON);
        pageCount = XPS_GetNumberPages(xpsHandle, 0);
        
        self.xpsData = [NSMutableDictionary dictionary];
        
        BlioTimeOrderedCache *aCache = [[BlioTimeOrderedCache alloc] init];
        aCache.countLimit = 30; // Arbitrary 30 object limit
        aCache.totalCostLimit = 1024*1024; // Arbitrary 1MB limit. This may need wteaked or set on a per-device basis
        self.componentCache = aCache;
        [aCache release];
		
		drmSessionManager = nil;
    }
    return self;
}

- (void)reportReadingIfRequired {
    if (reportingStatus == kBlioXPSProviderReportingStatusRequired) {
        if ([drmSessionManager reportReading]) {
            reportingStatus = kBlioXPSProviderReportingStatusComplete;
        }
    }
}

- (void)deleteTemporaryDirectoryAtPath:(NSString *)path {
    // Should have been deleted by XPS cleanup but remove if not
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSError *error;
    NSFileManager *threadSafeManager = [[NSFileManager alloc] init];
    if ([threadSafeManager fileExistsAtPath:path]) {
        //NSLog(@"Removing temp XPS directory at path %@", path);

        if (![threadSafeManager removeItemAtPath:path error:&error]) {
            NSLog(@"Error removing temp XPS directory at path %@ with error %@ : %@", path, error, [error userInfo]);
        }
    }
    [threadSafeManager release];
    [pool drain];
}

- (BlioBook *)book {
    return [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
}

- (BOOL)bookIsEncrypted {
    if (nil == bookIsEncrypted) {
        bookIsEncrypted = [NSNumber numberWithBool:[self.book isEncrypted]];
    }
    
    return [bookIsEncrypted boolValue];
}

#pragma mark -
#pragma mark BlioLayoutDataSource

- (NSInteger)pageCount {
    return pageCount;
}

- (CGRect)cropRectForPage:(NSInteger)page {
    [renderingLock lock];
        memset(&properties,0,sizeof(properties));
        XPS_GetFixedPageProperties(xpsHandle, 0, page - 1, &properties);
        CGRect cropRect = CGRectMake(properties.contentBox.x, properties.contentBox.y, properties.contentBox.width, properties.contentBox.height);
    [renderingLock unlock];
    
    return cropRect;
}

- (CGRect)mediaRectForPage:(NSInteger)page {
    [renderingLock lock];
        memset(&properties,0,sizeof(properties));
        XPS_GetFixedPageProperties(xpsHandle, 0, page - 1, &properties);
        CGRect mediaRect = CGRectMake(0, 0, properties.width, properties.height);
    [renderingLock unlock];
    
    return mediaRect;
}

- (CGFloat)dpiRatio {
    return 1;
}

void XPSPageCompleteCallback(void *userdata, RasterImageInfo *data) {
	BlioXPSProvider *provider = (BlioXPSProvider *)userdata;	
	provider.imageInfo = data;
}

static void XPSDataReleaseCallback(void *info, const void *data, size_t size) {
	XPS_ReleaseImageMemory((void *)data);
}

- (void)drawPage:(NSInteger)page inBounds:(CGRect)bounds withInset:(CGFloat)inset inContext:(CGContextRef)ctx inRect:(CGRect)rect withTransform:(CGAffineTransform)transform observeAspect:(BOOL)aspect {
    
    CGAffineTransform ctm = CGContextGetCTM(ctx);
    CGRect insetBounds = CGRectInset(bounds, inset, inset);
    
	CGRect pageCropRect = [self cropRectForPage:page];
    
    CGFloat widthScale = (CGRectGetWidth(insetBounds) / CGRectGetWidth(pageCropRect)) * ctm.a;
    CGFloat heightScale = (CGRectGetHeight(insetBounds) / CGRectGetHeight(pageCropRect)) * ctm.d;
    CGFloat pageScale = MIN(widthScale, heightScale);
    if (aspect) widthScale = heightScale = pageScale;
    
    CGRect scaledPage = CGRectMake(pageCropRect.origin.x, pageCropRect.origin.y, pageCropRect.size.width * widthScale, pageCropRect.size.height * heightScale);
    CGRect truncatedPage = CGRectMake(scaledPage.origin.x, scaledPage.origin.y, floorf(scaledPage.size.width), floorf(scaledPage.size.height));
    CGFloat horizontalPageOffset = (CGRectGetWidth(bounds) * ctm.a - CGRectGetWidth(truncatedPage))/2.0f; 
    CGFloat verticalPageOffset = (CGRectGetHeight(bounds) * ctm.d  - CGRectGetHeight(truncatedPage))/2.0f; 
    
    CGRect clipRect = CGContextGetClipBoundingBox(ctx);
    CGRect tileRect = CGRectApplyAffineTransform(clipRect, ctm); 
    tileRect.origin = CGPointMake(clipRect.origin.x * ctm.a, clipRect.origin.y * ctm.d);

    CGFloat pagesizescalewidth = (CGRectGetWidth(tileRect))/ CGRectGetWidth(truncatedPage);
    CGFloat pagesizescaleheight = (CGRectGetHeight(tileRect))/ CGRectGetHeight(truncatedPage);
    
    CGContextConcatCTM(ctx, CGAffineTransformInvert(ctm));
    CGRect maskRect = CGRectMake(ctm.tx + horizontalPageOffset, ctm.ty + verticalPageOffset, truncatedPage.size.width, truncatedPage.size.height);
    CGContextClipToRect(ctx, maskRect);    
    
    OutputFormat format;
    memset(&format,0,sizeof(format));
    
    CGPoint topLeftOfTileOffsetFromBottomLeft = CGPointMake(tileRect.origin.x, CGRectGetHeight(bounds)*ctm.d - CGRectGetMaxY(tileRect));
    XPS_ctm render_ctm = { widthScale, 0, 0, heightScale, -topLeftOfTileOffsetFromBottomLeft.x + horizontalPageOffset, -topLeftOfTileOffsetFromBottomLeft.y + verticalPageOffset };
    //NSLog(@"render_ctm = { %f, %f, %f, %f, %f, %f }", render_ctm.a, render_ctm.b, render_ctm.c, render_ctm.d, render_ctm.tx, render_ctm.ty);
    format.xResolution = 96;			
    format.yResolution = 96;	
    format.colorDepth = 8;
    format.colorSpace = XPS_COLORSPACE_RGB;
    format.pagesizescale = 1;	
    format.pagesizescalewidth = pagesizescalewidth * widthScale;		
    format.pagesizescaleheight = pagesizescaleheight * heightScale;
    //NSLog(@"pagesScaleWidth %f, pagesScaleHeight %f", format.pagesizescalewidth, format.pagesizescaleheight);
    format.ctm = &render_ctm;				
    format.formatType = OutputFormat_RAW;
    imageInfo = NULL;
    
    [renderingLock lock];
        XPS_RegisterPageCompleteCallback(xpsHandle, XPSPageCompleteCallback);
        XPS_SetUserData(xpsHandle, self);
        XPS_Convert(xpsHandle, NULL, 0, page - 1, 1, &format);

        if (imageInfo) {
            size_t width  = imageInfo->widthInPixels;
            size_t height = imageInfo->height;
            size_t dataLength = width * height * 3;
        
            CGDataProviderRef providerRef = CGDataProviderCreateWithData(self, imageInfo->pBits, dataLength, XPSDataReleaseCallback);
            CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
            CGImageRef imageRef =
            CGImageCreate(width, height, 8, 24, width * 3, rgbColorSpace, 
                          kCGImageAlphaNone, providerRef, NULL, true, kCGRenderingIntentDefault);
            CGColorSpaceRelease(rgbColorSpace);
            CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
            CGRect imageRect = CGRectMake(0, tileRect.size.height - height, width, height);
            CGContextDrawImage(ctx, imageRect, imageRef);
            CGDataProviderRelease(providerRef);
            CGImageRelease(imageRef);        
        }
    [renderingLock unlock];
}

- (CGContextRef)RGBABitmapContextForPage:(NSUInteger)page
                                fromRect:(CGRect)rect
                                 minSize:(CGSize)size 
                              getContext:(id *)context {
	
	CGRect pageCropRect = [self cropRectForPage:page];
    
    OutputFormat format;
    memset(&format,0,sizeof(format));
    
    CGFloat pageSizeScaleWidth  = size.width / pageCropRect.size.width;
    CGFloat pageSizeScaleHeight = size.height / pageCropRect.size.height;
    
    CGFloat pageZoomScaleWidth  = size.width / CGRectGetWidth(rect);
    CGFloat pageZoomScaleHeight = size.height / CGRectGetHeight(rect);
    
    XPS_ctm render_ctm = { pageZoomScaleWidth, 0, 0, pageZoomScaleHeight, -rect.origin.x * pageZoomScaleWidth, -rect.origin.y * pageZoomScaleHeight};
    format.xResolution = 96;			
    format.yResolution = 96;	
    format.colorDepth = 8;
    format.colorSpace = XPS_COLORSPACE_RGBA;
    format.pagesizescale = 1;	
    format.pagesizescalewidth = pageSizeScaleWidth;		
    format.pagesizescaleheight = pageSizeScaleHeight;
    format.ctm = &render_ctm;				
    format.formatType = OutputFormat_RAW;
    imageInfo = NULL;
    
    [renderingLock lock];
    XPS_RegisterPageCompleteCallback(xpsHandle, XPSPageCompleteCallback);
    XPS_SetUserData(xpsHandle, self);
    XPS_Convert(xpsHandle, NULL, 0, page - 1, 1, &format);
    
    CGContextRef bitmapContext = nil;
    
    if (imageInfo) {
        size_t width  = imageInfo->widthInPixels;
        size_t height = imageInfo->height;
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

        bitmapContext = CGBitmapContextCreate(imageInfo->pBits, width, height, 8, imageInfo->rowStride, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
        BlioXPSBitmapReleaseCallback *releaseCallback = [[BlioXPSBitmapReleaseCallback alloc] init];
        releaseCallback.data = imageInfo->pBits;
        
        *context = [releaseCallback autorelease];
                        
        CGColorSpaceRelease(colorSpace);
    }
    [renderingLock unlock];
    
    return (CGContextRef)[(id)bitmapContext autorelease];
}

- (UIImage *)thumbnailForPage:(NSInteger)pageNumber {
    UIImage *thumbnail = nil;
    NSString *thumbnailsLocation = [self.book manifestLocationForKey:BlioManifestThumbnailDirectoryKey];
    if ([thumbnailsLocation isEqualToString:BlioManifestEntryLocationXPS]) {
        NSString *thumbPath = [BlioXPSMetaDataDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.jpg", pageNumber]];
        NSData *thumbData = [self dataForComponentAtPath:thumbPath];
        if (thumbData) {
            thumbnail = [UIImage imageWithData:thumbData];
        }
    }
    return thumbnail;
}

- (NSArray *)hyperlinksForPage:(NSInteger)page {
    NSData *fpage = [self dataForComponentAtPath:[NSString stringWithFormat:@"%d.fpage", page]];
    NSArray *hyperlinks = [self extractHyperlinks:fpage];

    return hyperlinks;
}

// Not required as XPS document stays open during rendering
- (void)openDocumentIfRequired {}

// Not required as the XPS Provider will close on dealloc
- (void)closeDocument {}

// Not required as XPS document stays open during rendering
- (void)closeDocumentIfRequired {}

#pragma mark -
#pragma mark XPS Component Data

- (CGRect)xpsRectFromString:(NSString *)pathString {
    CGMutablePathRef mutablePath = CGPathCreateMutable();
    NSScanner *pathScanner = [NSScanner scannerWithString:pathString];
    [pathScanner setCharactersToBeSkipped:nil]; 
    
    NSCharacterSet *XPSCOMMANDS = [NSCharacterSet characterSetWithCharactersInString:@"FMmLlZz "];
    NSString *COMMA = @",";
    NSString *lastCommand = nil;
    
    while ([pathScanner isAtEnd] == NO)
    {
        NSString *command = nil;
        CGFloat a = 0, b = 0;
        
        [pathScanner scanUpToCharactersFromSet:XPSCOMMANDS intoString:NULL];
        [pathScanner scanCharactersFromSet:XPSCOMMANDS intoString:&command];
        
        if ([command isEqualToString:@" "]) {
            command = [NSString stringWithString:lastCommand];
        } else {
            lastCommand = command;
        }
        
        if ([[command uppercaseString] isEqualToString:@"M"]) {
            [pathScanner scanFloat:&a];
            [pathScanner scanString:COMMA intoString:NULL];
            [pathScanner scanFloat:&b];
            CGPathMoveToPoint(mutablePath, NULL, a, b);
        } else if ([[command uppercaseString] isEqualToString:@"L"]) {
            [pathScanner scanFloat:&a];
            [pathScanner scanString:COMMA intoString:NULL];
            [pathScanner scanFloat:&b];
            CGPathAddLineToPoint(mutablePath, NULL, a, b);
        } else if ([[command uppercaseString] isEqualToString:@"Z"]) {
            CGPathCloseSubpath(mutablePath);
        }
    }
    
    CGRect boundingRect = CGPathGetBoundingBox(mutablePath);
    CGPathRelease(mutablePath);
    
    return boundingRect;                
}

- (NSArray *)extractHyperlinks:(NSData *)data {
    NSMutableArray *hyperlinks = [NSMutableArray array];
    
    NSString *inputString = [[NSString alloc] initWithBytesNoCopy:(void *)[data bytes] length:[data length] encoding:NSUTF8StringEncoding freeWhenDone:NO];
    
    NSString *HYPERLINK = @"<Path FixedPage.NavigateUri";
    NSString *DATA = @"Data";
    NSString *QUOTE = @"\"";
    NSString *CLOSINGBRACKET = @"/>";
    
    NSScanner *aScanner = [NSScanner scannerWithString:inputString];
    
    while ([aScanner isAtEnd] == NO)
    {
        NSString *hyperlinkString = nil;
        [aScanner scanUpToString:HYPERLINK intoString:NULL];
        [aScanner scanString:HYPERLINK intoString:NULL];
        [aScanner scanUpToString:QUOTE intoString:NULL];
        [aScanner scanString:QUOTE intoString:NULL];
        [aScanner scanUpToString:CLOSINGBRACKET intoString:&hyperlinkString];
        [aScanner scanString:CLOSINGBRACKET intoString:NULL];
        if (hyperlinkString != nil) {
            NSScanner *hyperlinkScanner = [NSScanner scannerWithString:hyperlinkString];
            while ([hyperlinkScanner isAtEnd] == NO)
            {
                NSString *link = nil, *pathData = nil;
                [hyperlinkScanner scanUpToString:QUOTE intoString:&link];
                [hyperlinkScanner scanString:QUOTE intoString:NULL];
                [hyperlinkScanner scanUpToString:DATA intoString:NULL];
                [hyperlinkScanner scanString:DATA intoString:NULL];
                [hyperlinkScanner scanUpToString:QUOTE intoString:NULL];
                [hyperlinkScanner scanString:QUOTE intoString:NULL];
                [hyperlinkScanner scanUpToString:QUOTE intoString:&pathData];
                [hyperlinkScanner scanString:QUOTE intoString:NULL];
                CGRect hyperlinkRect = [self xpsRectFromString:pathData];
                BlioLayoutHyperlink *blioHyperlink = [[BlioLayoutHyperlink alloc] initWithLink:link rect:hyperlinkRect];
                [hyperlinks addObject:blioHyperlink];
                [blioHyperlink release];
            }
        }
    }
    [inputString release];
    
    return hyperlinks;
}


- (NSData *)replaceMappedResources:(NSData *)data {
    NSString *inputString = [[NSString alloc] initWithBytesNoCopy:(void *)[data bytes] length:[data length] encoding:NSUTF8StringEncoding freeWhenDone:NO];
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:[inputString length]];

    NSString *GRIDROW = @"Grid.Row=\"";
    NSString *CLOSINGQUOTE = @"\"";
    
    NSScanner *aScanner = [NSScanner scannerWithString:inputString];
    
    while ([aScanner isAtEnd] == NO)
    {
        NSUInteger startPos = [aScanner scanLocation];
        [aScanner scanUpToString:GRIDROW intoString:NULL];
        NSUInteger endPos = [aScanner scanLocation];
        NSRange prefixRange = NSMakeRange(startPos, endPos - startPos);
        [outputString appendString:[inputString substringWithRange:prefixRange]];
        
        if ([aScanner isAtEnd] == NO) {
            // Skip the gridrow entry
            [aScanner scanString:GRIDROW intoString:NULL];
            
            // Read the row digit, insert the lookup and advance passed the closing quote
            NSInteger anInteger;
            if ([aScanner scanInteger:&anInteger]) {
                if (anInteger < [self.uriMap count]) {
                    [outputString appendString:[NSString stringWithFormat:@"ImageSource=\"%@\" ", [self.uriMap objectAtIndex:anInteger]]];
                } else {
                    NSLog(@"Warning: could not find mapped resource for Grid.Row %d. Mapping count is %d", anInteger, [self.uriMap count]);
                }
            }
            // Skip the closing quote
            [aScanner scanString:CLOSINGQUOTE intoString:NULL];
        }
    }
    [inputString release];
    
    if ([outputString length]) {
        data = [outputString dataUsingEncoding:NSUTF8StringEncoding];
    }
    [outputString release];
    
    return data;
}

- (NSData *)rawDataForComponentAtPath:(NSString *)path {
    NSData *rawData = nil;
    
    XPS_FILE_PACKAGE_INFO packageInfo;
    [contentsLock lock];
    int ret = XPS_GetComponentInfo(xpsHandle, (char *)[path UTF8String], &packageInfo);
    [contentsLock unlock];
    if (!ret) {
        NSLog(@"Error opening component at path %@ for book with ID %@", path, self.bookID);
        return nil;
    } else {
        NSData *packageData = [NSMutableData dataWithBytes:packageInfo.pComponentData length:packageInfo.length];
        //NSLog(@"Raw data length %d (%d) with compression %d", [rawData length], packageInfo.length, packageInfo.compression_type);
        if (packageInfo.compression_type == 8) {
            rawData = [self decompressWithRawDeflate:packageData];
            if ([rawData length] == 0) {
                NSLog(@"Error decompressing component at path %@ for book with ID %@", path, self.bookID);
            }
        } else {
            rawData = packageData;
        }
    }
    
    if ([rawData length] == 0) {
        NSLog(@"Error opening component at path %@ for book with ID %@", path, self.bookID);
        return nil;
    }
    
    return rawData;
}

- (BOOL)componentExistsAtPath:(NSString *)path {
    XPS_FILE_PACKAGE_INFO packageInfo;
    [contentsLock lock];
    int ret = XPS_GetComponentInfo(xpsHandle, (char *)[path UTF8String], &packageInfo);
    [contentsLock unlock];
    if (ret && (packageInfo.length > 0)) {
        return YES;
    }
    return NO;
}

- (NSData *)dataForComponentAtPath:(NSString *)path {
    NSString *componentPath = path;
    NSString *directory = [path stringByDeletingLastPathComponent];
    NSString *filename  = [path lastPathComponent];
    NSString *extension = [[path pathExtension] uppercaseString];

    BOOL encrypted = NO;
    BOOL gzipped = NO;
    BOOL mapped = NO;
    BOOL cached = NO;
    
    // TODO: Make sure these checks are ordered from most common to least common for efficiency
    if ([filename isEqualToString:@"Rights.xml"]) {
        if (self.bookIsEncrypted) {
            encrypted = YES;
            gzipped = YES;
        }
    } else if ([extension isEqualToString:[BlioXPSComponentExtensionFPage uppercaseString]]) {
        if (self.bookIsEncrypted) {
            encrypted = YES;
            gzipped = YES;
            componentPath = [[BlioXPSEncryptedPagesDir stringByAppendingPathComponent:[path lastPathComponent]] stringByAppendingPathExtension:BlioXPSComponentExtensionEncrypted];
        } else {
            componentPath = [BlioXPSPagesDir stringByAppendingPathComponent:path];
        }
        mapped = YES;
        cached = YES;
    } else if ([directory isEqualToString:BlioXPSEncryptedImagesDir] && ([extension isEqualToString:@"JPG"] || [extension isEqualToString:@"PNG"])) { 
        if (self.bookIsEncrypted) {
            encrypted = YES;
            componentPath = [path stringByAppendingPathExtension:BlioXPSComponentExtensionEncrypted];
        }
        cached = YES;
    } else if ([directory isEqualToString:BlioXPSEncryptedTextFlowDir]) {  
        if (![path isEqualToString:@"/Documents/1/Other/KNFB/Flow/Sections.xml"]) {
            if (self.bookIsEncrypted) {
                encrypted = YES;
                gzipped = YES;
            }
            cached = YES;
        }
    } else if ([directory isEqualToString:BlioXPSEncryptedPagesDir]) {
        if (self.bookIsEncrypted) {
            encrypted = YES;
            gzipped = YES;
        }
        cached = YES;
    } else if ([path isEqualToString:BlioXPSEncryptedUriMap]) {
        if (self.bookIsEncrypted) {
            encrypted = YES;
            gzipped = YES;
        }
    }
        
    if (cached) {
        NSData *cacheData = [self.componentCache objectForKey:componentPath];
        if ([cacheData length]) {
            return cacheData;
        }
    }
    
    NSData *componentData = [self rawDataForComponentAtPath:componentPath];
             
    if (encrypted) {
        BOOL decrypted = NO;
        if (!decryptionAvailable) {
            // Check if this is first run
            if (self.drmSessionManager && decryptionAvailable) {
                if ([self.drmSessionManager decryptData:componentData]) {
                    decrypted = YES;
                }
            }
        } else {
            if ([self.drmSessionManager decryptData:componentData]) {
                decrypted = YES;
            }
        }
        
        if (!decrypted) {
			NSLog(@"Error whilst decrypting data at path %@ for bookID: %i", componentPath,self.bookID);
            return nil;
        }
    }
    
    if (gzipped) {
        componentData = [self decompressWithGZipCompression:componentData];
    }
    
    if (mapped) {
        componentData = [self replaceMappedResources:componentData];
    }
    
    if (cached && [componentData length]) {
        [self.componentCache setObject:componentData forKey:componentPath cost:[componentData length]];
    }
    
    if (![componentData length]) {
        NSLog(@"Zero length data returned in dataForComponentAtPath: %@", path);
    }
    
    return componentData;
    
}

#pragma mark -
#pragma mark DRM Handler

- (NSDictionary *)openDRMRenderingComponentAtPath:(NSString *)path {
    //NSLog(@"openDRMRenderingComponentAtPath: %@", path);
    
    NSData *componentData = [self dataForComponentAtPath:path];
    
    NSMutableDictionary *xpsDataDict = [NSMutableDictionary dictionaryWithCapacity:3];
    [xpsDataDict setValue:[NSValue valueWithNonretainedObject:self] forKey:@"xpsProvider"];
    [xpsDataDict setObject:path forKey:@"xpsPath"];
    [xpsDataDict setValue:[NSNumber numberWithInt:0] forKey:@"xpsByteOffset"];
    [xpsDataDict setValue:componentData forKey:@"xpsData"];    
    [self.xpsData setObject:xpsDataDict forKey:path];
    
    return xpsDataDict;
}

- (void)closeDRMRenderingComponentAtPath:(NSString *)path {
    [self.xpsData removeObjectForKey:path];
} 

URI_HANDLE BlioXPSProviderDRMOpen(const char * pszURI, void * data) {
    NSString *path = [NSString stringWithCString:pszURI encoding:NSUTF8StringEncoding];
    BlioXPSProvider *provider = (BlioXPSProvider *)data;
    //NSLog(@"BlioXPSProviderDRMOpen %@ with userdata %p", path, provider);
    
    NSDictionary *xpsDataDict = [provider openDRMRenderingComponentAtPath:path];
    
    return xpsDataDict;
}

void BlioXPSProviderDRMRewind(URI_HANDLE h) {
    //NSLog(@"BlioXPSProviderDRMRewind");
    NSDictionary *xpsDataDict = (NSDictionary *)h;
    [xpsDataDict setValue:[NSNumber numberWithInt:0] forKey:@"xpsByteOffset"];
}

size_t BlioXPSProviderDRMSkip(URI_HANDLE h, size_t cb) {
    //NSLog(@"BlioXPSProviderDRMSkip");
    NSDictionary *xpsDataDict = (NSDictionary *)h;
    NSData *xpsFileData = [xpsDataDict valueForKey:@"xpsData"];
    NSUInteger byteOffset = [[xpsDataDict valueForKey:@"xpsByteOffset"] integerValue];
    NSUInteger bytesRemaining = [xpsFileData length] - byteOffset;
    NSUInteger bytesToSkip = MIN(cb, bytesRemaining);
    
    [xpsDataDict setValue:[NSNumber numberWithInt:byteOffset+bytesToSkip] forKey:@"xpsByteOffset"];
    
    return 0;
}

size_t BlioXPSProviderDRMRead(URI_HANDLE h, unsigned char * pb, size_t cb) {

    NSDictionary *xpsDataDict = (NSDictionary *)h;
    NSData *xpsFileData = [xpsDataDict valueForKey:@"xpsData"];
    NSUInteger byteOffset = [[xpsDataDict valueForKey:@"xpsByteOffset"] integerValue];
    
   // NSLog(@"BlioXPSProviderDRMRead %d bytes from %d", cb, byteOffset);
    
    if (nil != xpsFileData) {
        NSUInteger bytesRemaining = [xpsFileData length] - byteOffset;
        NSUInteger bytesToRead = MIN(cb, bytesRemaining);
        
        //[xpsFileData getBytes:(void *)pb length:bytesToRead];
        [xpsFileData getBytes:(void *)pb range:NSMakeRange(byteOffset, bytesToRead)];
        [xpsDataDict setValue:[NSNumber numberWithInt:byteOffset+bytesToRead] forKey:@"xpsByteOffset"];
        return bytesToRead;
    }
    return 0;
}

size_t BlioXPSProviderDRMSize(URI_HANDLE h){
    
    NSDictionary *xpsDataDict = (NSDictionary *)h;
    NSData *xpsFileData = [xpsDataDict valueForKey:@"xpsData"];

    if (nil != xpsFileData) {
        //NSLog(@"BlioXPSProviderDRMSize %d", [xpsFileData length]);
        return [xpsFileData length];
    }
  
    return 0;
}

void BlioXPSProviderDRMClose(URI_HANDLE h) {
    //NSLog(@"BlioXPSProviderDRMClose");
    NSDictionary *xpsDataDict = (NSDictionary *)h;
    BlioXPSProvider *xpsProvider = [[xpsDataDict valueForKey:@"xpsProvider"] nonretainedObjectValue];
    NSString *path = [xpsDataDict valueForKey:@"xpsPath"];
    
    //NSLog(@"BlioXPSProviderDRMClose path %@", path);
    
    [xpsProvider closeDRMRenderingComponentAtPath:path];
}

#pragma mark -
#pragma mark Decompress methods

- (NSData *)decompress:(NSData *)data windowBits:(NSInteger)windowBits {
    
	int ret;
	unsigned bytesDecompressed;
	z_stream strm;
	const int BUFSIZE=16384;
	unsigned char outbuf[BUFSIZE];
	NSMutableData* outData = [[NSMutableData alloc] init];
	
	// Read the gzip header.
	// TESTING
	//unsigned char ID1 = inBuffer[0];  // should be x1f
	//unsigned char ID2 = inBuffer[1];  // should be x8b
	//unsigned char CM = inBuffer[2];   // should be 8
	
	// Allocate inflate state.
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	strm.opaque = Z_NULL;
	strm.avail_in = 0;
	strm.next_in = Z_NULL;
	
    [inflateLock lock];
    
	ret = XPS_inflateInit2(&strm, windowBits);
	
	if (ret != Z_OK) {
        [inflateLock unlock];
        [outData release];
		return nil;
    }
	
	strm.avail_in = [data length];
	strm.next_in = (Bytef *)[data bytes];
	// Inflate until the output buffer isn't full
	do {
		strm.avail_out = BUFSIZE;
		strm.next_out = outbuf;
		ret = XPS_inflate(&strm,Z_NO_FLUSH); 
		// ret should be Z_STREAM_END
		switch (ret) {
			case Z_NEED_DICT:
				//ret = Z_DATA_ERROR;
			case Z_DATA_ERROR:
			case Z_MEM_ERROR:
				XPS_inflateEnd(&strm);
                [inflateLock unlock];
                [outData release];
				return nil;
		}
		bytesDecompressed = BUFSIZE - strm.avail_out;
		NSData* data = [[NSData alloc] initWithBytesNoCopy:outbuf length:bytesDecompressed freeWhenDone:NO];
		[outData appendData:data];
        [data release];
	}
	while (strm.avail_out == 0);
	XPS_inflateEnd(&strm);
	
    [inflateLock unlock];
	
	if (ret == Z_STREAM_END || ret == Z_OK)
		return [outData autorelease];
    
    [outData release];
	return nil;
}

- (NSData *)decompressWithRawDeflate:(NSData *)data {
    return [self decompress:data windowBits:-15];
}

- (NSData *)decompressWithGZipCompression:(NSData *)data {
    return [self decompress:data windowBits:31];
}

#pragma mark -
#pragma mark UriMap.xml Parsing

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    if (currentUriString) {
        [currentUriString release];
        currentUriString = nil;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (!currentUriString) {
        currentUriString = [[NSMutableString alloc] initWithCapacity:50];
    }
    [currentUriString appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {    
    if ( [elementName isEqualToString:@"string"] ) {
        [self.uriMap addObject:currentUriString];
    }
    
    if (currentUriString) {
        [currentUriString release];
        currentUriString = nil;
    }
}

- (NSMutableArray *)uriMap {
    if (nil == uriMap) {
        NSData *uriMapData = [self dataForComponentAtPath:BlioXPSEncryptedUriMap];
        if (uriMapData) {
            self.uriMap = [NSMutableArray arrayWithCapacity:51];
            NSXMLParser *uriMapParser = [[NSXMLParser alloc] initWithData:uriMapData];
            [uriMapParser setDelegate:self];
            [uriMapParser setShouldResolveExternalEntities:NO];
            BOOL success = [uriMapParser parse];
            if (!success) {
                self.uriMap = nil;
            }
        }
    }
    return uriMap;
}

@end

@implementation BlioXPSBitmapReleaseCallback

@synthesize data;

- (void)dealloc {
    if (self.data) {
        //NSLog(@"Release: %p", self.data);
        XPS_ReleaseImageMemory(self.data);
    }
    [super dealloc];
}

@end
