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

static NSString* const BlioXPSProviderEncryptedPagesDir = @"/Documents/1/Other/KNFB/Epages/";
static NSString* const BlioXPSProviderEncryptedPagesExtension = @"bin";

static NSString * const BlioXPSProviderComponentExtensionFPage = @"fpage";
static NSString * const BlioXPSProviderComponentExtensionRels = @"rels";

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

- (void)deleteTemporaryDirectoryAtPath:(NSString *)path;
- (NSData *)decompressWithRawDeflate:(NSData *)data;
//- (NSData *)decompressWithGZipCompression:(NSData *)data;

@end

@implementation BlioXPSProvider

@synthesize bookID;
@synthesize tempDirectory, imageInfo, xpsData;

- (void)dealloc {    
    XPS_Cancel(xpsHandle);
    XPS_Close(xpsHandle);
    XPS_End();
    
    [self performSelectorOnMainThread:@selector(deleteTemporaryDirectoryAtPath:) withObject:self.tempDirectory waitUntilDone:YES];
    
    self.tempDirectory = nil;
    self.imageInfo = nil;
    self.bookID = nil;
    self.xpsData = nil;
    
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
            //NSLog(@"Registered drm handler for book %@ with handle %p with userdata %p", [self.book valueForKey:@"title"], xpsHandle, self);
        }
        
        XPS_SetAntiAliasMode(xpsHandle, XPS_ANTIALIAS_ON);
        pageCount = XPS_GetNumberPages(xpsHandle, 0);
        
        self.xpsData = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)deleteTemporaryDirectoryAtPath:(NSString *)path {
    // Should have been deleted by XPS cleanup but remove if not
    NSError *error;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"Removing temp XPS directory at path %@");

        if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
            NSLog(@"Error removing temp XPS directory at path %@ with error %@ : %@", path, error, [error userInfo]);
        }
    }
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
    format.xResolution = 96;			
    format.yResolution = 96;	
    format.colorDepth = 8;
    format.colorSpace = XPS_COLORSPACE_RGB;
    format.pagesizescale = 1;	
    format.pagesizescalewidth = pagesizescalewidth * widthScale;		
    format.pagesizescaleheight = pagesizescaleheight * heightScale;
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

// Not required as XPS document stays open during rendering
- (void)openDocumentIfRequired {}

// Not required as the XPS Provider will close on dealloc
- (void)closeDocument {}

// Not required as XPS document stays open during rendering
- (void)closeDocumentIfRequired {}

#pragma mark -
- (NSData *)dataForComponentAtPath:(NSString *)path {
    // TODO - optimise the memory footprint of component loading
    void* componentHandle =  (void*)XPS_OpenComponent(xpsHandle, 
									(char*)[path cStringUsingEncoding:NSASCIIStringEncoding], 
									0); // not writeable
    
	NSMutableData* componentData = [[NSMutableData alloc] init];
	unsigned char buffer[4096];
    int bytesRead = (NSInteger)XPS_ReadComponent(componentHandle,buffer,sizeof(buffer)); 
	while (1) {
		NSData* data = [[NSData alloc] initWithBytes:(void*)buffer length:bytesRead];
		[componentData appendData:data];
        [data release];
        
		if ( bytesRead != sizeof(buffer) )
			break;
        bytesRead = (NSInteger)XPS_ReadComponent(componentHandle,buffer,sizeof(buffer)); 
	}
	XPS_CloseComponent(componentHandle);
    
    return [componentData autorelease];
}

#pragma mark -
#pragma mark Infate

- (NSInteger)inflateInit:(void*)stream {
	return (NSInteger)XPS_inflateInit2(stream,0); // second argument = 15 (default window size) + 16 (for gzip decoding)	
}

- (int)decompress:(unsigned char*)inBuffer inBufferSz:(NSInteger)inBufSz outBuffer:(unsigned char**)outBuf outBufferSz:(NSInteger*)outBufSz {
    //- (int)decompress:(unsigned char*)inbuf inbufSz:(NSInteger)sz {
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
	    
	ret = [self inflateInit:&strm]; 
	
	if (ret != Z_OK)
		return ret;
	
	strm.avail_in = inBufSz;
	// if (strm.avail_in == 0)
	//	  break;
	strm.next_in = inBuffer;
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
				return ret;
		}
		bytesDecompressed = BUFSIZE - strm.avail_out;
		NSData* data = [[NSData alloc] initWithBytes:(const void*)outbuf length:bytesDecompressed];
		[outData appendData:data];
	}
	while (strm.avail_out == 0);
	XPS_inflateEnd(&strm);
	
	// TESTING
	NSString* testStr = [[NSString alloc] initWithData:outData encoding:NSASCIIStringEncoding];
	NSLog(@"Unencrypted buffer: %s",testStr);
	*outBuf = (unsigned char*)malloc([outData length]);  
    [outData getBytes:*outBuf length:[outData length]];
	*outBufSz = [outData length];
	
	if (ret == Z_STREAM_END)
		return Z_OK;
	return Z_DATA_ERROR;
}

#pragma mark -
#pragma mark DRM Handler

- (NSDictionary *)openDRMRenderingComponentAtPath:(NSString *)path {
    NSLog(@"Open %@", path);
    
    NSString *extension = [path pathExtension];
    NSString *componentPath = path;
    
    
    if ([extension isEqualToString:@"ODTTF"]) {    
        
        XPS_FILE_PACKAGE_INFO packageInfo;
        int ret = XPS_GetComponentInfo(xpsHandle, (char *)[componentPath UTF8String], &packageInfo);
        if (!ret) {
            NSLog(@"Error opening component at path %@ for book with ID %@", path, self.bookID);
            return nil;
        }
        NSData *unencryptedData = [NSMutableData dataWithBytes:packageInfo.pComponentData length:packageInfo.length];
        //NSData *componentData = [self decompressWithRawDeflate:unencryptedData];
        
        //NSData *componentData = [self dataForComponentAtPath:path];
        NSMutableDictionary *xpsDataDict = [NSMutableDictionary dictionaryWithCapacity:3];
        [xpsDataDict setValue:[NSValue valueWithNonretainedObject:self] forKey:@"xpsProvider"];
        [xpsDataDict setObject:path forKey:@"xpsPath"];
        [xpsDataDict setValue:[NSNumber numberWithInt:0] forKey:@"xpsByteOffset"];
        [xpsDataDict setValue:unencryptedData forKey:@"xpsData"];    
        [self.xpsData setObject:xpsDataDict forKey:path];
    
        return xpsDataDict;
    }
    
    BOOL encrypted = NO;
    //BOOL deflated = NO;
    BOOL gzipped = NO;
    
    if ([extension isEqualToString:BlioXPSProviderComponentExtensionFPage]) {
        encrypted = YES;
        gzipped = YES;
        componentPath = [[BlioXPSProviderEncryptedPagesDir stringByAppendingPathComponent:[path lastPathComponent]] stringByAppendingPathExtension:BlioXPSProviderEncryptedPagesExtension];
    } else if ([extension isEqualToString:@"jpg"]) { 
        encrypted = YES;
        componentPath = [path stringByAppendingPathExtension:BlioXPSProviderEncryptedPagesExtension];
    }
    
    NSData *componentData;
    
    if (encrypted) {
        componentData = [[BlioDrmManager getDrmManager] decryptComponent:componentPath forBookWithID:self.bookID];
    } else {
        XPS_FILE_PACKAGE_INFO packageInfo;
        int ret = XPS_GetComponentInfo(xpsHandle, (char *)[componentPath UTF8String], &packageInfo);
        if (!ret) {
            NSLog(@"Error opening component at path %@ for book with ID %@", path, self.bookID);
            return nil;
        }
        NSData *unencryptedData = [NSMutableData dataWithBytes:packageInfo.pComponentData length:packageInfo.length];
        componentData = [self decompressWithRawDeflate:unencryptedData];
    }

    NSMutableDictionary *xpsDataDict = [NSMutableDictionary dictionaryWithCapacity:3];
    [xpsDataDict setValue:[NSValue valueWithNonretainedObject:self] forKey:@"xpsProvider"];
    [xpsDataDict setObject:path forKey:@"xpsPath"];
    [xpsDataDict setValue:[NSNumber numberWithInt:0] forKey:@"xpsByteOffset"];
    [xpsDataDict setValue:componentData forKey:@"xpsData"];
    [self.xpsData setObject:xpsDataDict forKey:path];

    
    NSLog(@"openedComponent at path %@ from request for %@", componentPath, path);
    
    return xpsDataDict;
    
    if (0) {
    int compressionType = 0;
    NSMutableData *componentData = nil;
    XPS_FILE_PACKAGE_INFO packageInfo;
    int ret = XPS_GetComponentInfo(xpsHandle, (char *)[componentPath UTF8String], &packageInfo);
    
    if (!ret) {
        NSLog(@"Error opening component at path %@ for book with ID %@", path, self.bookID);
        return nil;
    }
    componentData = [NSMutableData dataWithBytes:packageInfo.pComponentData length:packageInfo.length];
    compressionType = packageInfo.compression_type;
    
    
    
    
    NSMutableDictionary *xpsDataDict = [NSMutableDictionary dictionaryWithCapacity:3];
    [xpsDataDict setValue:[NSValue valueWithNonretainedObject:self] forKey:@"xpsProvider"];
    [xpsDataDict setObject:path forKey:@"xpsPath"];
    
    switch (compressionType) {
        case 0:
            [xpsDataDict setValue:componentData forKey:@"xpsData"];
            break;
        case 8: {
            //unsigned char* decryptedBuff;	
//            NSInteger decryptedBuffSz;
//            [self decompress:(unsigned char *)[componentData bytes] inBufferSz:[componentData length] outBuffer:&decryptedBuff outBufferSz:&decryptedBuffSz];
//            NSData *inflatedData = [NSData dataWithBytesNoCopy:decryptedBuff length:decryptedBuffSz freeWhenDone:NO];
//            [xpsDataDict setValue:inflatedData forKey:@"xpsData"];
            
            unsigned char *buffer = (unsigned char*)[componentData bytes];
            
            // This XOR step is to undo an additional encryption step that was needed for .NET environment.
            for (int i=0;i<[componentData length];++i)
                buffer[i] ^= 0xA0;
            
            // The buffer is fully decrypted now, but gzip compressed; so must decompress.
            NSData *inflatedData = [self decompressWithGZipCompression:componentData];
            [xpsDataDict setValue:inflatedData forKey:@"xpsData"];
            
        }   break;
        default:
            NSLog(@"Unrecognise compression type %d encountered at path %@", compressionType, path);
            [xpsDataDict setValue:componentData forKey:@"xpsData"];
            break;
    }
    
    // Add to dictionary to retain object until BlioXPSProviderDRMClose
    // The xpsProvider and xpsPath are used to identify and remove the object on DRMClose
    [self.xpsData setObject:xpsDataDict forKey:path];
    
    return xpsDataDict;
    }
}

- (void)closeDRMRenderingComponentAtPath:(NSString *)path {
    NSLog(@"Close %@", path);
    [self.xpsData removeObjectForKey:path];
} 

URI_HANDLE BlioXPSProviderDRMOpen(const char * pszURI, void * data) {
    NSString *path = [NSString stringWithCString:pszURI encoding:NSUTF8StringEncoding];
    BlioXPSProvider *provider = (BlioXPSProvider *)data;
    NSLog(@"BlioXPSProviderDRMOpen %@ with userdata %p", path, provider);
    
    
    if ([[path pathExtension] isEqualToString:BlioXPSProviderComponentExtensionRels]) {
        // This is a bug in the XPS library, we shouldn't be asked for this but it happens
        // On XPS_Open when a DRM Handler was previously registered for another handle, even
        // if that handle is no longer valid
        return NULL;
    }
    
    NSDictionary *xpsDataDict = [provider openDRMRenderingComponentAtPath:path];
    
    return xpsDataDict;
}

void BlioXPSProviderDRMRewind(URI_HANDLE h) {
    NSLog(@"BlioXPSProviderDRMRewind");
    NSDictionary *xpsDataDict = (NSDictionary *)h;
    [xpsDataDict setValue:[NSNumber numberWithInt:0] forKey:@"xpsByteOffset"];
}

size_t BlioXPSProviderDRMSkip(URI_HANDLE h, size_t cb) {
    NSLog(@"BlioXPSProviderDRMSkip");
    NSDictionary *xpsDataDict = (NSDictionary *)h;
    NSData *xpsFileData = [xpsDataDict valueForKey:@"xpsData"];
    NSUInteger byteOffset = [[xpsDataDict valueForKey:@"xpsByteOffset"] integerValue];
    NSUInteger bytesRemaining = [xpsFileData length] - byteOffset;
    NSUInteger bytesToSkip = MIN(cb, bytesRemaining);
    
    [xpsDataDict setValue:[NSNumber numberWithInt:byteOffset+bytesToSkip] forKey:@"xpsByteOffset"];
    
    return 0;
}

size_t BlioXPSProviderDRMSeek(DATAOUT_HANDLE h, size_t cb, XPS_SEEK_RELATIVE rel) {
    NSLog(@"BlioXPSProviderDRMSeek");
    return 0;
}

size_t BlioXPSProviderDRMRead(URI_HANDLE h, unsigned char * pb, size_t cb) {

    NSDictionary *xpsDataDict = (NSDictionary *)h;
    NSData *xpsFileData = [xpsDataDict valueForKey:@"xpsData"];
    NSUInteger byteOffset = [[xpsDataDict valueForKey:@"xpsByteOffset"] integerValue];
    
    NSLog(@"BlioXPSProviderDRMRead %d bytes from %d", cb, byteOffset);
    if (byteOffset == 1337) {
        NSLog(@"About to fail");
    }
    
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
    NSLog(@"BlioXPSProviderDRMWrite");
	return 0;
}

size_t BlioXPSProviderDRMSize(URI_HANDLE h){
    
    NSDictionary *xpsDataDict = (NSDictionary *)h;
    NSData *xpsFileData = [xpsDataDict valueForKey:@"xpsData"];

    if (nil != xpsFileData) {
        NSLog(@"BlioXPSProviderDRMSize %d", [xpsFileData length]);
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
    NSLog(@"BlioXPSProviderDRMClose");
    NSDictionary *xpsDataDict = (NSDictionary *)h;
    BlioXPSProvider *xpsProvider = [[xpsDataDict valueForKey:@"xpsProvider"] nonretainedObjectValue];
    NSString *path = [xpsDataDict valueForKey:@"xpsPath"];
    
    NSLog(@"BlioXPSProviderDRMClose path %@", path);
    
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

@end
