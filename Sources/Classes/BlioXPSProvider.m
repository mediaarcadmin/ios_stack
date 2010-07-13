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

- (void)deleteTemporaryDirectoryAtPath:(NSString *)path;

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
        
        NSError *error;
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.tempDirectory]) {
            if (![[NSFileManager defaultManager] createDirectoryAtPath:self.tempDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
                NSLog(@"Unable to create temp XPS directory at path %@ with error %@ : %@", self.tempDirectory, error, [error userInfo]);
            }
        }
        
        XPS_Start();
        xpsHandle = XPS_Open([[self.book xpsPath] UTF8String], [self.tempDirectory UTF8String]);
        
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

- (NSData *)decompress:(NSData *)data {

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

    ret = XPS_inflateInit2(&strm,31); // second argument = 15 (default window size) + 16 (for gzip decoding)	
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


#pragma mark -
#pragma mark DRM Handler

- (NSDictionary *)openDRMRenderingComponentAtPath:(NSString *)path {
    XPS_FILE_PACKAGE_INFO packageInfo;
    int ret = XPS_GetComponentInfo(xpsHandle, (char *)[path UTF8String], &packageInfo);
    NSLog(@"open %@ returned %d, compression %d, length %d", path, ret, packageInfo.compression_type, packageInfo.length);
    
    //NSMutableData *componentData = [NSMutableData dataWithBytesNoCopy:packageInfo.pComponentData length:packageInfo.length freeWhenDone:NO];
    NSMutableData *componentData = [NSMutableData dataWithBytes:packageInfo.pComponentData length:packageInfo.length];

    NSMutableDictionary *xpsDataDict = [NSMutableDictionary dictionaryWithCapacity:3];
    [xpsDataDict setValue:[NSValue valueWithNonretainedObject:self] forKey:@"xpsProvider"];
    [xpsDataDict setObject:path forKey:@"xpsPath"];
    
    switch (packageInfo.compression_type) {
        case 0:
            [xpsDataDict setValue:componentData forKey:@"xpsData"];
            break;
        case 8: {
            //unsigned char* decryptedBuff;	
//            NSInteger decryptedBuffSz;
//            [self decompress:(unsigned char *)[componentData bytes] inBufferSz:[componentData length] outBuffer:&decryptedBuff outBufferSz:&decryptedBuffSz];
//            NSData *inflatedData = [NSData dataWithBytesNoCopy:decryptedBuff length:decryptedBuffSz freeWhenDone:NO];
//            [xpsDataDict setValue:inflatedData forKey:@"xpsData"];
            
            unsigned char* decrBuff;	
            NSInteger decrBuffSz;
            unsigned char *buffer = (unsigned char*)[componentData bytes];
            
            // This XOR step is to undo an additional encryption step that was needed for .NET environment.
            for (int i=0;i<[componentData length];++i)
                buffer[i] ^= 0xA0;
            
            // The buffer is fully decrypted now, but gzip compressed; so must decompress.
            [self decompress:buffer inBufferSz:[componentData length] outBuffer:&decrBuff outBufferSz:&decrBuffSz];
            
            NSLog(@"Inflated data is length %d", decrBuffSz);
            NSData *inflatedData = [NSData dataWithBytesNoCopy:decrBuff length:decrBuffSz freeWhenDone:NO];
            [xpsDataDict setValue:inflatedData forKey:@"xpsData"];
            
        }   break;
        default:
            NSLog(@"Unrecognise compression type %d encountered at path %@", packageInfo.compression_type, path);
            [xpsDataDict setValue:componentData forKey:@"xpsData"];
            break;
    }
    
    // Add to dictionary to retain object until BlioXPSProviderDRMClose
    // The xpsProvider and xpsPath are used to identify and remove the object on DRMClose
    [self.xpsData setObject:xpsDataDict forKey:path];
    
    return xpsDataDict;
}

- (void)closeDRMRenderingComponentAtPath:(NSString *)path {
    NSLog(@"Close %@", path);
    [self.xpsData removeObjectForKey:path];
} 

URI_HANDLE BlioXPSProviderDRMOpen(const char * pszURI, void * data) {
    BlioXPSProvider *provider = (BlioXPSProvider *)data;
    NSString *path = [NSString stringWithCString:pszURI encoding:NSUTF8StringEncoding];
    NSDictionary *xpsDataDict = [provider openDRMRenderingComponentAtPath:path];
    
    return xpsDataDict;
}

void BlioXPSProviderDRMRewind(URI_HANDLE h) {
    
}

size_t BlioXPSProviderDRMSkip(URI_HANDLE h, size_t cb) {
    return 0;
}

size_t BlioXPSProviderDRMSeek(DATAOUT_HANDLE h, size_t cb, XPS_SEEK_RELATIVE rel) {
    return 0;
}

size_t BlioXPSProviderDRMRead(URI_HANDLE h, unsigned char * pb, size_t cb) {
    NSDictionary *xpsDataDict = (NSDictionary *)h;
    NSData *xpsFileData = [xpsDataDict valueForKey:@"xpsData"];
    
    if (nil != xpsFileData) {
        [xpsFileData getBytes:(void *)pb length:cb];
        return 1;
    }
    return 0;
}

size_t BlioXPSProviderDRMWrite(DATAOUT_HANDLE h, unsigned char * pb, size_t cb) {
	return 0;
}

size_t BlioXPSProviderDRMSize(URI_HANDLE h){
    NSDictionary *xpsDataDict = (NSDictionary *)h;
    NSData *xpsFileData = [xpsDataDict valueForKey:@"xpsData"];

    if (nil != xpsFileData) {
        return [xpsFileData length];
    }
    return 0;
}

size_t BlioXPSProviderDRMPosition(DATAOUT_HANDLE h) {
	return 0;
}

void BlioXPSProviderDRMClose(URI_HANDLE h) {
    NSDictionary *xpsDataDict = (NSDictionary *)h;
    BlioXPSProvider *xpsProvider = [[xpsDataDict valueForKey:@"xpsProvider"] nonretainedObjectValue];
    NSString *path = [xpsDataDict valueForKey:@"xpsPath"];
    
    [xpsProvider closeDRMRenderingComponentAtPath:path];
}

@end
