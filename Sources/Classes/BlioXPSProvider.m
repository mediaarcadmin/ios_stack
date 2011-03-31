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
#import <libEucalyptus/THPair.h>
#import "BlioZipArchive.h"

URI_HANDLE BlioXPSProviderDRMOpen(const char * pszURI, void * data);
void BlioXPSProviderDRMRewind(URI_HANDLE h);
size_t BlioXPSProviderDRMSkip(URI_HANDLE h, size_t cb);
size_t BlioXPSProviderDRMRead(URI_HANDLE h, unsigned char * pb, size_t cb);
size_t BlioXPSProviderDRMSize(URI_HANDLE h);
void BlioXPSProviderDRMClose(URI_HANDLE h);

NSInteger numericCaseInsensitiveSort(id string1, id string2, void* context);

@interface BlioEPubInfoParserDelegate : NSObject <NSXMLParserDelegate> {
    NSMutableArray *encryptedPaths;
}

@property (nonatomic, retain) NSMutableArray *encryptedPaths;

@end

@implementation BlioEPubInfoParserDelegate

@synthesize encryptedPaths;

#pragma mark -
#pragma mark NSXMLParserDelegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    if ( [elementName isEqualToString:@"File"] ) {
		if ([[attributeDict objectForKey:@"IsEncrypted"] isEqualToString:@"true"]) {
			if (!self.encryptedPaths) self.encryptedPaths = [NSMutableArray array];
			[self.encryptedPaths addObject:[attributeDict objectForKey:@"Path"]];
		}
	}
}

#pragma mark -
#pragma mark memory management

-(void)dealloc {
	self.encryptedPaths = nil;
	[super dealloc];
}

@end


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
@property (nonatomic, retain) NSString *xpsPagesDirectory;
@property (nonatomic, retain) NSSet *enhancedContentItems; // Lazily instantiated

- (void)deleteTemporaryDirectoryAtPath:(NSString *)path;
- (NSData *)decompressWithRawDeflate:(NSData *)data;
- (NSData *)decompressWithGZipCompression:(NSData *)data;
- (NSArray *)extractHyperlinks:(NSData *)data;
- (NSData *)dataFromComponentPartsInArray:(NSArray *)partsArray;
- (NSArray *)contentsOfXPS;

@end

@implementation BlioXPSProvider

@synthesize bookID;
@synthesize tempDirectory, imageInfo, xpsData, uriMap;
@synthesize componentCache;
@synthesize drmSessionManager;
@synthesize xpsPagesDirectory;
@synthesize enhancedContentItems;

+ (void)initialize {
    if(self == [BlioXPSProvider class]) {
       [BlioXPSProtocol registerXPSProtocol];
    }
} 	

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

- (BOOL)decryptionIsAvailable {
	return self.drmSessionManager && decryptionAvailable;
}

- (void)dealloc {  
		
    [renderingLock lock];
    [contentsLock lock];
    XPS_Cancel(xpsHandle);
    XPS_Close(xpsHandle);
    XPS_End();
    [renderingLock unlock];
    [contentsLock unlock];
    
    [self deleteTemporaryDirectoryAtPath:self.tempDirectory];
    
    self.tempDirectory = nil;
    self.imageInfo = nil;
    self.bookID = nil;
    self.xpsData = nil;
    self.uriMap = nil;
	self.xpsPagesDirectory = nil;
	self.enhancedContentItems = nil;

    if (currentUriString) {
        [currentUriString release];
    }

	if (_encryptedEPubPaths) {
        [_encryptedEPubPaths release];
    }
	
    [renderingLock release];
    [contentsLock release];
    
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
        
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef UUIDString = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        self.tempDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:(NSString *)UUIDString];
        //NSLog(@"temp string is %@ for book with ID %@", (NSString *)UUIDString, self.bookID);
        
        NSError *error;
        NSFileManager *threadSafeManager = [[[NSFileManager alloc] init] autorelease];
        
        if (![threadSafeManager fileExistsAtPath:self.tempDirectory]) {
            if (![threadSafeManager createDirectoryAtPath:self.tempDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
                NSLog(@"Unable to create temp XPS directory at path %@ with error %@ : %@", self.tempDirectory, error, [error userInfo]);
                CFRelease(UUIDString);
                return nil;
            }
        }
        
        XPS_Start();
        NSString *xpsPath = [self.book xpsPath];
        if (![threadSafeManager fileExistsAtPath:xpsPath]) {
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
                                 atSize:(CGSize)size 
                              getBacking:(id *)context {
	

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
	if (![self bookIsEncrypted]) {
		[contentsLock lock];
	}
	
    XPS_RegisterPageCompleteCallback(xpsHandle, XPSPageCompleteCallback);
    XPS_SetUserData(xpsHandle, self);
	
    XPS_Convert(xpsHandle, NULL, 0, page - 1, 1, &format);
	
	if (![self bookIsEncrypted]) {
		[contentsLock unlock];
	}
	
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

#pragma mark -
#pragma mark EnhancedContent Parsing

static void overlayContentXMLParsingStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts)  {

	NSMutableSet *items = (NSMutableSet *)ctx;
	
    if (strcmp("EnhancedOverlayinfo", name) == 0) {
		
		NSInteger pageNumber = -1;
		NSString *navigateUri = nil;
		NSString *controlType = nil;
		NSString *visualState = nil;
		CGRect displayRegion = CGRectZero;
		CGAffineTransform contentOffset = CGAffineTransformIdentity;
		NSInteger enhancedOverlayinfoID = -1;
		
        for(int i = 0; atts[i]; i+=2) {
            if (strcmp("PageNo", atts[i]) == 0) {
				NSString *attributeString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != attributeString) {
                    pageNumber = [attributeString integerValue];
                    [attributeString release];
                }
			} else if (strcmp("DisplayRegionLeft", atts[i]) == 0) {
				NSString *attributeString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != attributeString) {
                    displayRegion.origin.x = [attributeString integerValue];
                    [attributeString release];
                }
			} else if (strcmp("DisplayRegionTop", atts[i]) == 0) {
				NSString *attributeString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != attributeString) {
                    displayRegion.origin.y = [attributeString integerValue];
                    [attributeString release];
                }
			} else if (strcmp("DisplayRegionWidth", atts[i]) == 0) {
				NSString *attributeString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != attributeString) {
                    displayRegion.size.width = [attributeString integerValue];
                    [attributeString release];
                }
			} else if (strcmp("DisplayRegionHeight", atts[i]) == 0) {
				NSString *attributeString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != attributeString) {
                    displayRegion.size.height = [attributeString integerValue];
                    [attributeString release];
                }
			} else if (strcmp("ContentScaleX", atts[i]) == 0) {
				NSString *attributeString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != attributeString) {
                    contentOffset.a = [attributeString integerValue];
                    [attributeString release];
                }
			} else if (strcmp("ContentScaleY", atts[i]) == 0) {
				NSString *attributeString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != attributeString) {
                    contentOffset.d = [attributeString integerValue];
                    [attributeString release];
                }
			} else if (strcmp("ContentOffsetX", atts[i]) == 0) {
				NSString *attributeString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != attributeString) {
                    contentOffset.tx = [attributeString integerValue];
                    [attributeString release];
                }
			} else if (strcmp("ContentOffsetY", atts[i]) == 0) {
				NSString *attributeString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != attributeString) {
                    contentOffset.ty = [attributeString integerValue];
                    [attributeString release];
                }
			} else if (strcmp("NavigateUri", atts[i]) == 0) {
                navigateUri = [[NSString alloc] initWithUTF8String:atts[i+1]];
			} else if (strcmp("ControlType", atts[i]) == 0) {
                controlType = [[NSString alloc] initWithUTF8String:atts[i+1]];
			} else if (strcmp("EnhancedOverlayinfoID", atts[i]) == 0) {
				NSString *attributeString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != attributeString) {
                    enhancedOverlayinfoID = [attributeString integerValue];
                    [attributeString release];
                }
			} else if (strcmp("VisualState", atts[i]) == 0) {
				visualState = [[NSString alloc] initWithUTF8String:atts[i+1]];
			}
        }
		NSDictionary *overlayInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:pageNumber], @"pageNumber", 
									 navigateUri, @"navigateUri",
									 controlType, @"controlType",
									 visualState, @"visualState",
									 [NSValue valueWithCGRect:displayRegion], @"displayRegion",
									 [NSValue valueWithCGAffineTransform:contentOffset], @"contentOffset",
									 [NSNumber numberWithInt:enhancedOverlayinfoID], @"enhancedOverlayinfoID",
									 nil];
		
		[navigateUri release];
		[controlType release];
		[visualState release];
		
		[items addObject:overlayInfo];				 
    }
}


- (NSSet *)extractOverlayContent:(NSData *)data
{
	NSMutableSet *items = [NSMutableSet set];
	
	if(data) {
        XML_Parser overlayParser = XML_ParserCreate(NULL);
        XML_SetStartElementHandler(overlayParser, overlayContentXMLParsingStartElementHandler);
        XML_SetUserData(overlayParser, items);    
		
        if (!XML_Parse(overlayParser, [data bytes], [data length], XML_TRUE)) {
            char *anError = (char *)XML_ErrorString(XML_GetErrorCode(overlayParser));
            NSLog(@"ExtractOverlayContent parsing error: '%s'", anError);
        }
        XML_ParserFree(overlayParser);
    }
	
	return items;
			  
}

static void videoContentXMLParsingStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts)  {
	
	NSMutableSet *items = (NSMutableSet *)ctx;
	
    if (strcmp("Videoinfo", name) == 0) {
		
		NSInteger pageNumber = -1;
		NSString *navigateUri = nil;
		CGRect displayRegion = CGRectZero;
		NSInteger videoInfoID = -1;
		
        for(int i = 0; atts[i]; i+=2) {
            if (strcmp("Page", atts[i]) == 0) {
				NSString *attributeString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != attributeString) {
                    pageNumber = [attributeString integerValue];
                    [attributeString release];
                }
			} else if (strcmp("DisplayRegionLeft", atts[i]) == 0) {
				NSString *attributeString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != attributeString) {
                    displayRegion.origin.x = [attributeString integerValue];
                    [attributeString release];
                }
			} else if (strcmp("DisplayRegionTop", atts[i]) == 0) {
				NSString *attributeString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != attributeString) {
                    displayRegion.origin.y = [attributeString integerValue];
                    [attributeString release];
                }
			} else if (strcmp("DisplayRegionWidth", atts[i]) == 0) {
				NSString *attributeString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != attributeString) {
                    displayRegion.size.width = [attributeString integerValue];
                    [attributeString release];
                }
			} else if (strcmp("DisplayRegionHeight", atts[i]) == 0) {
				NSString *attributeString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != attributeString) {
                    displayRegion.size.height = [attributeString integerValue];
                    [attributeString release];
                }
			} else if (strcmp("NavigateUri", atts[i]) == 0) {
                navigateUri = [[NSString alloc] initWithUTF8String:atts[i+1]];
			} else if (strcmp("VideoinfoID", atts[i]) == 0) {
				NSString *attributeString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != attributeString) {
                    videoInfoID = [attributeString integerValue];
                    [attributeString release];
                }
			}
        }
		NSDictionary *overlayInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:pageNumber], @"pageNumber", 
									 navigateUri, @"navigateUri",
									 @"iOSCompatibleVideoContent", @"controlType",
									 [NSValue valueWithCGRect:displayRegion], @"displayRegion",
									 [NSNumber numberWithInt:videoInfoID], @"videoInfoID",
									 nil];
		
		[navigateUri release];
		
		[items addObject:overlayInfo];				 
    }
}

- (NSSet *)extractVideoContent:(NSData *)data
{
	NSMutableSet *items = [NSMutableSet set];
	
	if(data) {
        XML_Parser videoParser = XML_ParserCreate(NULL);
        XML_SetStartElementHandler(videoParser, videoContentXMLParsingStartElementHandler);
        XML_SetUserData(videoParser, items);    
		
        if (!XML_Parse(videoParser, [data bytes], [data length], XML_TRUE)) {
            char *anError = (char *)XML_ErrorString(XML_GetErrorCode(videoParser));
            NSLog(@"ExtractVideoContent parsing error: '%s'", anError);
        }
        XML_ParserFree(videoParser);
    }
	
	return items;
	
}

- (NSSet *)enhancedContentItems 
{
	if (!enhancedContentItems) {
		NSMutableSet *items = [NSMutableSet set];
		
		if ([self componentExistsAtPath:[BlioXPSEnhancedContentDir stringByAppendingPathComponent:@"OverlayContent.xml"]]) {
			NSData *overlayContentData = [self dataForComponentAtPath:[BlioXPSEnhancedContentDir stringByAppendingPathComponent:@"OverlayContent.xml"]];
			[items unionSet:[self extractOverlayContent:overlayContentData]];
		}
		
		if ([self componentExistsAtPath:[BlioXPSEnhancedContentDir stringByAppendingPathComponent:@"VideoContent.xml"]]) {
			NSData *videoContentData = [self dataForComponentAtPath:[BlioXPSEnhancedContentDir stringByAppendingPathComponent:@"VideoContent.xml"]];
			[items unionSet:[self extractVideoContent:videoContentData]];
		}
		
		enhancedContentItems = [items retain];
	}
	
	return enhancedContentItems;
}

- (BOOL)hasEnhancedContent {
    BOOL hasEnhancedContent = ([self componentExistsAtPath:[BlioXPSEnhancedContentDir stringByAppendingPathComponent:@"OverlayContent.xml"]] ||
                               [self componentExistsAtPath:[BlioXPSEnhancedContentDir stringByAppendingPathComponent:@"VideoContent.xml"]]);
    
    return hasEnhancedContent;
}

- (NSArray *)enhancedContentForPage:(NSInteger)page {
		
	NSMutableArray *array = [NSMutableArray array];
	
	for (NSDictionary *item in self.enhancedContentItems) {
		if ([[item valueForKey:@"pageNumber"] intValue] == page - 1) {
			[array addObject:item];
		}
	}
	
	return array;
}

- (NSData *)enhancedContentDataAtPath:(NSString *)path {
	return [self dataForComponentAtPath:path];
}

- (NSURL *)temporaryURLForEnhancedContentVideoAtPath:(NSString *)path {
    return nil;
#if 0
    void *directoryPtr;
    [contentsLock lock];
    NSUInteger entries = XPS_GetPackageDir(xpsHandle, &directoryPtr);
    [contentsLock unlock];
        //        NSURL 
        //    NSFileHandle *fileHandle =  
        return [BlioZipArchive contentsOfCentralDirectory:directoryPtr numberOfEntries:entries];
    
    
    //
	NSData *videoData = [self dataForComponentAtPath:path];
	
	NSString *tempPath = [self.tempDirectory stringByAppendingPathComponent:[path lastPathComponent]];
	[videoData writeToFile:tempPath atomically:NO];
	NSURL *tempURL = [NSURL fileURLWithPath:tempPath];

	return tempURL;
#endif
}

- (NSString *)enhancedContentRootPath {
	return BlioXPSEnhancedContentDir;
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

- (NSData *)mappedDataForComponentAtPath:(NSString *)path {
	XPS_FILE_PACKAGE_INFO packageInfo;
    [contentsLock lock];
    int ret = XPS_GetComponentInfo(xpsHandle, (char *)[path UTF8String], &packageInfo);
    [contentsLock unlock];
		
	if (!ret) {
        NSLog(@"Error opening component at path %@ for book with ID %@", path, self.bookID);
        return nil;
    } else if (packageInfo.compression_type == 8) {
		NSLog(@"Error opening mappedFile at path %@ for book with ID %@ - data is deflated - cannot be directly mapped", path, self.bookID);
        return nil;
	} else {
        return [[[NSData alloc] initWithBytesNoCopy:packageInfo.pComponentData length:packageInfo.length freeWhenDone:NO] autorelease];
	}
	
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
        NSData *packageData = [[NSData alloc] initWithBytesNoCopy:packageInfo.pComponentData length:packageInfo.length freeWhenDone:NO];
        //NSLog(@"Raw data length %d (%d) with compression %d", [rawData length], packageInfo.length, packageInfo.compression_type);
        if (packageInfo.compression_type == 8) {
            rawData = [self decompressWithRawDeflate:packageData];
            [packageData release];
            if ([rawData length] == 0) {
                NSLog(@"Error decompressing component at path %@ for book with ID %@", path, self.bookID);
            }
        } else {
            rawData = [packageData autorelease];
        }
    }
    
    if ([rawData length] == 0) {
        NSLog(@"Error opening component at path %@ for book with ID %@", path, self.bookID);
        return nil;
    }
    
    return rawData;
}

-(NSArray*)encryptedEPubPaths {
	if (!_encryptedEPubPaths) {
		NSData * epubInfoData = nil;
		if ([self componentExistsAtPath:BlioXPSKNFBEPubInfoFile]) epubInfoData = [self rawDataForComponentAtPath:BlioXPSKNFBEPubInfoFile];
		if (epubInfoData) {
			NSXMLParser * epubInfoParser = [[NSXMLParser alloc] initWithData:epubInfoData];
			BlioEPubInfoParserDelegate * epubInfoParserDelegate = [[BlioEPubInfoParserDelegate alloc] init];
			[epubInfoParser setDelegate:epubInfoParserDelegate];
			[epubInfoParser parse];
			if (epubInfoParserDelegate.encryptedPaths) {
				_encryptedEPubPaths = [epubInfoParserDelegate.encryptedPaths retain];
			}
			else _encryptedEPubPaths = [[NSMutableArray alloc] initWithCapacity:0];
			[epubInfoParserDelegate release];
			[epubInfoParser release];
		}
	}
	return _encryptedEPubPaths;
}

- (NSArray *)contentsOfXPS {
	void *directoryPtr;
	[contentsLock lock];
	NSUInteger entries = XPS_GetPackageDir(xpsHandle, &directoryPtr);
    [contentsLock unlock];
	
	return [BlioZipArchive contentsOfCentralDirectory:directoryPtr numberOfEntries:entries];
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

- (NSString *)extractFixedDocumentPath:(NSData *)data {
	NSString *docRefString = nil;
	
	if (data) {
		NSString *inputString = [[NSString alloc] initWithBytesNoCopy:(void *)[data bytes] length:[data length] encoding:NSUTF8StringEncoding freeWhenDone:NO];
		
		NSString *DOCREF = @"<DocumentReference";
		NSString *QUOTE = @"\"";
		
		NSScanner *aScanner = [NSScanner scannerWithString:inputString];
		
		while ([aScanner isAtEnd] == NO)
		{
			
			[aScanner scanUpToString:DOCREF intoString:NULL];
			[aScanner scanString:DOCREF intoString:NULL];
			[aScanner scanUpToString:QUOTE intoString:NULL];
			[aScanner scanString:QUOTE intoString:NULL];
			[aScanner scanUpToString:QUOTE intoString:&docRefString];
			break;
		}
		[inputString release];
	}
	
	if (docRefString && ![[docRefString substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"/"]) {
		docRefString = [NSString stringWithFormat:@"/%@", docRefString];
	}
	
	return docRefString;
}

- (NSString *)extractFixedPagesPath:(NSData *)data {
	NSString *pageContentString = nil;
	NSString *fixedPagesString = nil;
	
	if (data) {
		NSString *inputString = [[NSString alloc] initWithBytesNoCopy:(void *)[data bytes] length:[data length] encoding:NSUTF8StringEncoding freeWhenDone:NO];
		
		NSString *PAGECONTENT = @"<PageContent";
		NSString *QUOTE = @"\"";
		
		NSScanner *aScanner = [NSScanner scannerWithString:inputString];
		
		while ([aScanner isAtEnd] == NO)
		{
			
			[aScanner scanUpToString:PAGECONTENT intoString:NULL];
			[aScanner scanString:PAGECONTENT intoString:NULL];
			[aScanner scanUpToString:QUOTE intoString:NULL];
			[aScanner scanString:QUOTE intoString:NULL];
			[aScanner scanUpToString:QUOTE intoString:&pageContentString];
			
			if (pageContentString) {
				fixedPagesString = [NSString stringWithString:[pageContentString stringByDeletingLastPathComponent]];
				break;
			}
			
		}
		[inputString release];
	}
	
	return fixedPagesString;
}

- (NSArray *)stringsInArray:(NSArray *)stringArray matchingRegularExpression:(NSString *)expression {
	NSMutableArray *matches = [NSMutableArray array];
	
	for (NSString *string in stringArray) {
		if ([string rangeOfString:expression options:(NSRegularExpressionSearch | NSCaseInsensitiveSearch)].location != NSNotFound) {
			[matches addObject:string];
		}
	}
	
	return matches;
}

NSInteger numericCaseInsensitiveSort(id string1, id string2, void* context) {
    return [string1 compare:string2 options:(NSCaseInsensitiveSearch | NSNumericSearch)];
}

- (NSData *)dataFromComponentPartsInArray:(NSArray *)partsArray {
	// Reorder parts
	NSArray *sortedParts = [partsArray sortedArrayUsingFunction:numericCaseInsensitiveSort context:NULL];
	
	NSMutableData *partsData = [NSMutableData data];
		
	for (NSString *part in sortedParts) {
		[partsData appendData:[self dataForComponentAtPath:part]];
	}
	
	return partsData;
}


- (NSString *)xpsPagesDirectory {
	if (!xpsPagesDirectory) {
				
		NSArray *contents = [self contentsOfXPS];
		
		NSArray *fixedDocumentSequenceParts = [self stringsInArray:contents matchingRegularExpression:[NSString stringWithFormat:@"^/[^/]*\\.%@.*", BlioXPSFixedDocumentSequenceExtension]];
		NSData *sequenceData = [self dataFromComponentPartsInArray:fixedDocumentSequenceParts];
		
		NSString *fixedDocumentPath = [self extractFixedDocumentPath:sequenceData];
		
		if (fixedDocumentPath) {
			NSArray *fixedDocumentParts = [self stringsInArray:contents matchingRegularExpression:[NSString stringWithFormat:@"^%@.*", fixedDocumentPath]];
			NSData *fixedDocumentData = [self dataFromComponentPartsInArray:fixedDocumentParts];

			NSString *pagesPath = [self extractFixedPagesPath:fixedDocumentData];
			if ([[pagesPath substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"/"]) {
				xpsPagesDirectory = pagesPath;
			} else {
				xpsPagesDirectory = [[fixedDocumentPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:pagesPath];
			}
			[xpsPagesDirectory retain];
		}
										 
	}
	
	return xpsPagesDirectory ? : @"";
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
	} 
//	else if ([filename isEqualToString:@"container.xml.bin"]) {
//			if (self.bookIsEncrypted) {
//				encrypted = YES;
//				gzipped = YES;
//			}
//	} 
	else if ([extension isEqualToString:[BlioXPSComponentExtensionFPage uppercaseString]]) {
        if (self.bookIsEncrypted) {
            encrypted = YES;
            gzipped = YES;
            componentPath = [[BlioXPSEncryptedPagesDir stringByAppendingPathComponent:[path lastPathComponent]] stringByAppendingPathExtension:BlioXPSComponentExtensionEncrypted];
        } else {
            componentPath = [[self xpsPagesDirectory] stringByAppendingPathComponent:path];
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
    } else if (([directory rangeOfString:BlioXPSEncryptedTextFlowDir].location != NSNotFound) && ([extension isEqualToString:@"JPG"] || [extension isEqualToString:@"PNG"])) { 
        if (self.bookIsEncrypted) {
            encrypted = YES;
        }
        cached = YES;
    }
	else if (self.encryptedEPubPaths) {
		if ([self.encryptedEPubPaths containsObject:path]) {
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
			NSLog(@"Error whilst decrypting data at path %@ for bookID: %@", componentPath,self.bookID);
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
    
    return bytesToSkip;
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

#define CHUNK 16384

- (NSData *)decompress:(NSData *)data windowBits:(NSInteger)windowBits {
	
	int ret;
	unsigned bytesDecompressed;
	z_stream strm;
	const int BUFSIZE=16384;
	unsigned char outbuf[BUFSIZE];
	NSMutableData* outData = [[NSMutableData alloc] init];
	
	// Allocate inflate state.
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	strm.opaque = Z_NULL;
	strm.avail_in = 0;
	strm.next_in = Z_NULL;
	    
	ret = inflateInit2(&strm, windowBits);
	
	if (ret != Z_OK) {
        [outData release];
		return nil;
    }
	
	strm.avail_in = [data length];
	strm.next_in = (Bytef *)[data bytes];
	// Inflate until the output buffer isn't full
	do {
		strm.avail_out = BUFSIZE;
		strm.next_out = outbuf;
		ret = inflate(&strm,Z_NO_FLUSH); 
		// ret should be Z_STREAM_END
		switch (ret) {
			case Z_NEED_DICT:
				//ret = Z_DATA_ERROR;
			case Z_DATA_ERROR:
			case Z_MEM_ERROR:
				inflateEnd(&strm);
                [outData release];
				return nil;
		}
		bytesDecompressed = BUFSIZE - strm.avail_out;
		[outData appendBytes:outbuf length:bytesDecompressed];
	}
	while (strm.avail_out == 0);
	inflateEnd(&strm);
		
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

@implementation BlioXPSProtocol

+ (void)registerXPSProtocol {
	static BOOL inited = NO;
	if ( ! inited ) {
		[NSURLProtocol registerClass:[BlioXPSProtocol class]];
		inited = YES;
	}
}

/* our own class method.  Here we return the NSString used to mark
 urls handled by our special protocol. */
+ (NSString *)xpsProtocolScheme {
	return @"blioxpsprotocol";
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
	NSString *theScheme = [[request URL] scheme];
	return ([theScheme caseInsensitiveCompare: [BlioXPSProtocol xpsProtocolScheme]] == NSOrderedSame);
}

/* if canInitWithRequest returns true, then webKit will call your
 canonicalRequestForRequest method so you have an opportunity to modify
 the NSURLRequest before processing the request */
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
	
	
	/* retrieve the current request. */
    NSURLRequest *request = [self request];
	NSString *encodedBookID = [[request URL] host];
	
	NSManagedObjectID *bookID = nil;
	
	if (encodedBookID && ![encodedBookID isEqualToString:@"undefined"]) {
		CFStringRef bookURIStringRef = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (CFStringRef)encodedBookID, CFSTR(""), kCFStringEncodingUTF8);		
		NSURL *bookURI = [NSURL URLWithString:(NSString *)bookURIStringRef];
		CFRelease(bookURIStringRef);

		bookID = [[[BlioBookManager sharedBookManager] persistentStoreCoordinator] managedObjectIDForURIRepresentation:bookURI];
		
	}
	
	if (!bookID) {
		return;
	}
	
	BlioXPSProvider *xpsProvider = [[BlioBookManager sharedBookManager] checkOutXPSProviderForBookWithID:bookID];
	
	NSString *path = [[request URL] path];
	NSData *data = [xpsProvider dataForComponentAtPath:path];
	
	NSURLResponse *response = 
	[[NSURLResponse alloc] initWithURL:[request URL] 
							  MIMEType:nil 
				 expectedContentLength:-1 
					  textEncodingName:@"utf-8"];
	
	/* get a reference to the client so we can hand off the data */
    id<NSURLProtocolClient> client = [self client];
	
	/* turn off caching for this response data */ 
	[client URLProtocol:self didReceiveResponse:response
	 cacheStoragePolicy:NSURLCacheStorageNotAllowed];
	
	/* set the data in the response to our data */ 
	[client URLProtocol:self didLoadData:data];
	
	/* notify that we completed loading */
	[client URLProtocolDidFinishLoading:self];
	
	/* we can release our copy */
	[response release];
	
	[[BlioBookManager sharedBookManager] checkInXPSProviderForBookWithID:bookID];
	
}

- (void)stopLoading {
	// Do nothing
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
