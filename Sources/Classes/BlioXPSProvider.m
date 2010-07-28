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
#import "BlioDrmManager.h"
#import "zlib.h"

URI_HANDLE BlioXPSProviderDRMOpen(const char * pszURI, void * data);
void BlioXPSProviderDRMRewind(URI_HANDLE h);
size_t BlioXPSProviderDRMSkip(URI_HANDLE h, size_t cb);
size_t BlioXPSProviderDRMSeek(DATAOUT_HANDLE h, size_t cb, XPS_SEEK_RELATIVE rel);
size_t BlioXPSProviderDRMRead(URI_HANDLE h, unsigned char * pb, size_t cb);
size_t BlioXPSProviderDRMWrite(DATAOUT_HANDLE h, unsigned char * pb, size_t cb);
size_t BlioXPSProviderDRMSize(URI_HANDLE h);
size_t BlioXPSProviderDRMPosition(DATAOUT_HANDLE h);
void BlioXPSProviderDRMClose(URI_HANDLE h);

@interface BlioXPSProvider()

@property (nonatomic, assign, readonly) BlioBook *book;
@property (nonatomic, retain) NSString *tempDirectory;
@property (nonatomic, assign) RasterImageInfo *imageInfo;
@property (nonatomic, retain) NSMutableDictionary *xpsData;
@property (nonatomic, retain) NSMutableArray *uriMap;

- (void)deleteTemporaryDirectoryAtPath:(NSString *)path;
- (NSData *)decompressWithRawDeflate:(NSData *)data;
- (NSData *)decompressWithGZipCompression:(NSData *)data;

@end

@implementation BlioXPSProvider

@synthesize bookID;
@synthesize tempDirectory, imageInfo, xpsData, uriMap;

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
                return nil;
            }
        }
        
        XPS_Start();
        NSString *xpsPath = [self.book xpsPath];
        if (![[NSFileManager defaultManager] fileExistsAtPath:xpsPath]) {
            NSLog(@"Error creating xpsProvider. File does not exist at path: %@", xpsPath);
            return nil;
        }
        
        xpsHandle = XPS_Open([xpsPath UTF8String], [self.tempDirectory UTF8String]);
        
        if ([[self.book valueForKey:@"sourceID"] isEqual:[NSNumber numberWithInt:BlioBookSourceOnlineStore]]) {
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
            
            CFRelease(UUIDString);
        
            XPS_RegisterDrmHandler(xpsHandle, &upi);
            NSLog(@"Registered drm handler for book %@ with handle %p with userdata %p", [self.book valueForKey:@"title"], xpsHandle, self);
        }
        
        XPS_SetAntiAliasMode(xpsHandle, XPS_ANTIALIAS_ON);
        pageCount = XPS_GetNumberPages(xpsHandle, 0);
        
        self.xpsData = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)reportReading {
    [[BlioDrmManager getDrmManager] reportReadingForBookWithID:self.bookID];
}

- (void)deleteTemporaryDirectoryAtPath:(NSString *)path {
    // Should have been deleted by XPS cleanup but remove if not
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSError *error;
    NSFileManager *threadSafeManager = [[NSFileManager alloc] init];
    if ([threadSafeManager fileExistsAtPath:path]) {
        NSLog(@"Removing temp XPS directory at path %@");

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
    
    [renderingLock lock];
        memset(&properties,0,sizeof(properties));
        XPS_GetFixedPageProperties(xpsHandle, 0, page - 1, &properties);
        CGRect pageCropRect = CGRectMake(properties.contentBox.x, properties.contentBox.y, properties.contentBox.width, properties.contentBox.height);
    [renderingLock unlock];
    
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
            CGImageRef imageRef =
            CGImageCreate(width, height, 8, 24, width * 3, CGColorSpaceCreateDeviceRGB(), 
                          kCGImageAlphaNone, providerRef, NULL, true, kCGRenderingIntentDefault);
        
            CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
            CGRect imageRect = CGRectMake(0, tileRect.size.height - height, width, height);
            CGContextDrawImage(ctx, imageRect, imageRef);
            CGDataProviderRelease(providerRef);
            CGImageRelease(imageRef);        
        }
    [renderingLock unlock];
}

- (UIImage *)thumbnailForPage:(NSInteger)pageNumber {
    UIImage *thumbnail = nil;
    NSString *thumbnailsLocation = [self.book manifestLocationForKey:@"thumbnailDirectory"];
    if ([thumbnailsLocation isEqualToString:BlioManifestEntryLocationXPS]) {
        NSString *thumbPath = [BlioXPSMetaDataDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.jpg", pageNumber]];
        NSData *thumbData = [self dataForComponentAtPath:thumbPath];
        if (thumbData) {
            thumbnail = [UIImage imageWithData:thumbData];
        }
    }
    return thumbnail;
}

// Not required as XPS document stays open during rendering
- (void)openDocumentIfRequired {}

// Not required as the XPS Provider will close on dealloc
- (void)closeDocument {}

// Not required as XPS document stays open during rendering
- (void)closeDocumentIfRequired {}

#pragma mark -
#pragma mark XPS Component Data

- (NSData *)replaceMappedResources:(NSData *)data {
    NSString *inputString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:[inputString length]];
        
    NSString *GRIDROW = @"Grid.Row=\"";
    NSString *CLOSINGQUOTE = @"\"";
    
    NSScanner *aScanner = [NSScanner scannerWithString:inputString];
    
    while ([aScanner isAtEnd] == NO)
    {
        NSString *prefix;
        [aScanner scanUpToString:GRIDROW intoString:&prefix];
        [outputString appendString:prefix];
        
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
    int ret = XPS_GetComponentInfo(xpsHandle, (char *)[path UTF8String], &packageInfo);
    if (!ret) {
        NSLog(@"Error opening component at path %@ for book with ID %@", path, self.bookID);
        return nil;
    } else {
        rawData = [NSMutableData dataWithBytes:packageInfo.pComponentData length:packageInfo.length];
        //NSLog(@"Raw data length %d (%d) with compression %d", [rawData length], packageInfo.length, packageInfo.compression_type);
        if (packageInfo.compression_type == 8) {
            rawData = [self decompressWithRawDeflate:rawData];
        }
    }
    
    return rawData;
}

- (NSData *)dataForComponentAtPath:(NSString *)path {
    NSString *componentPath = path;
    NSString *directory = [path stringByDeletingLastPathComponent];
    NSString *filename  = [path lastPathComponent];
    NSString *extension = [[path pathExtension] uppercaseString];

    BOOL encrypted = NO;
    BOOL gzipped = NO;
    BOOL mapped = NO;
    
    // TODO Make sure these checks are ordered from most common to least common for efficiency
    if ([filename isEqualToString:@"Rights.xml"]) {
        encrypted = YES;
    } else if ([extension isEqualToString:[BlioXPSComponentExtensionFPage uppercaseString]]) {
        encrypted = YES;
        gzipped = YES;
        mapped = YES;
        componentPath = [[BlioXPSEncryptedPagesDir stringByAppendingPathComponent:[path lastPathComponent]] stringByAppendingPathExtension:BlioXPSComponentExtensionEncrypted];
    } else if ([directory isEqualToString:BlioXPSEncryptedImagesDir] && ([extension isEqualToString:@"JPG"] || [extension isEqualToString:@"PNG"])) { 
        encrypted = YES;
        componentPath = [path stringByAppendingPathExtension:BlioXPSComponentExtensionEncrypted];
    } else if ([directory isEqualToString:BlioXPSEncryptedTextFlowDir]) {  
        if (![path isEqualToString:@"/Documents/1/Other/KNFB/Flow/Sections.xml"]) {
            encrypted = YES;
            gzipped = YES;
        }
    } else if ([directory isEqualToString:BlioXPSEncryptedPagesDir]) {
        encrypted = YES;
        gzipped = YES;
    } else if ([path isEqualToString:BlioXPSEncryptedUriMap]) {
        encrypted = YES;
        gzipped = YES;
    }
    
    NSData *componentData = [self rawDataForComponentAtPath:componentPath];
             
    if (encrypted) {
        if (![[BlioDrmManager getDrmManager] decryptData:componentData forBookWithID:self.bookID]) {
            NSLog(@"Error whilst decrypting data at path %@", componentPath);
            return nil;
        }
    }
    
    if (gzipped) {
        componentData = [self decompressWithGZipCompression:componentData];
    }
    
    if (mapped) {
        componentData = [self replaceMappedResources:componentData];
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

size_t BlioXPSProviderDRMSeek(DATAOUT_HANDLE h, size_t cb, XPS_SEEK_RELATIVE rel) {
    //NSLog(@"BlioXPSProviderDRMSeek");
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

size_t BlioXPSProviderDRMWrite(DATAOUT_HANDLE h, unsigned char * pb, size_t cb) {
    //NSLog(@"BlioXPSProviderDRMWrite");
	return 0;
}

size_t BlioXPSProviderDRMSize(URI_HANDLE h){
    
    NSDictionary *xpsDataDict = (NSDictionary *)h;
    NSData *xpsFileData = [xpsDataDict valueForKey:@"xpsData"];

    if (nil != xpsFileData) {
        //NSLog(@"BlioXPSProviderDRMSize %d", [xpsFileData length]);
        return [xpsFileData length];
    }
    NSLog(@"BlioXPSProviderDRMSize failed");
    return 0;
}

size_t BlioXPSProviderDRMPosition(DATAOUT_HANDLE h) {
    NSLog(@"BlioXPSProviderDRMPosition");
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
    
    //ret = XPS_inflateInit2(&strm,31); // second argument = 15 (default window size) + 16 (for gzip decoding)	
	ret = XPS_inflateInit2(&strm, windowBits);
    //ret = [self inflateInit:&strm]; 
	
	if (ret != Z_OK) {
        [inflateLock unlock];
		return nil;
    }
	
	strm.avail_in = [data length];
	// if (strm.avail_in == 0)
	//	  break;
	strm.next_in = (Bytef *)[data bytes];
	// Inflate until the output buffer isn't full
	do {
		strm.avail_out = BUFSIZE;
		strm.next_out = outbuf;
		ret = XPS_inflate(&strm,Z_NO_FLUSH); 
		// ret should be Z_STREAM_END
		switch (ret) {
			case Z_NEED_DICT:
				ret = Z_DATA_ERROR;
			case Z_DATA_ERROR:
			case Z_MEM_ERROR:
				XPS_inflateEnd(&strm);
                [inflateLock unlock];
				return nil;
		}
		bytesDecompressed = BUFSIZE - strm.avail_out;
		NSData* data = [[NSData alloc] initWithBytes:(const void*)outbuf length:bytesDecompressed];
		[outData appendData:data];
	}
	while (strm.avail_out == 0);
	XPS_inflateEnd(&strm);
	
    [inflateLock unlock];
    
	// TESTING
	//NSString* testStr = [[NSString alloc] initWithData:outData encoding:NSASCIIStringEncoding];
	//NSLog(@"Unencrypted buffer: %s",testStr);
	
	if (ret == Z_STREAM_END)
		return [outData autorelease];
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
