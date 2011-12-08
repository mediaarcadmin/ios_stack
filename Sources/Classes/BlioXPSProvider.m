//
//  BlioXPSProvider.m
//  BlioApp
//
//  Created by matt on 08/07/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioXPSProvider.h"
#import "BlioXPSProtocol.h"
#import "BlioBook.h"
#import "BlioBookManager.h"
#import "BlioDrmSessionManager.h"
#import "BlioXPSConstants.h"
#import <expat/expat.h>

@interface BlioXPSProvider()

@property (nonatomic, retain) NSManagedObjectID *bookID;
@property (nonatomic, retain) NSSet *enhancedContentItems;

- (BlioDrmSessionManager *)drmSessionManager;
- (NSSet *)extractOverlayContent:(NSData *)data;
- (NSSet *)extractVideoContent:(NSData *)data;

@end

@implementation BlioXPSProvider

@synthesize bookID;
@synthesize enhancedContentItems;

+ (void)initialize {
    if(self == [BlioXPSProvider class]) {
       [BlioXPSProtocol registerXPSProtocol];
    }
} 	

- (void)dealloc {  
    
    [bookID release], bookID = nil;
    [drmSessionManager release], drmSessionManager = nil;
    [enhancedContentItems release], enhancedContentItems = nil;
	
    [super dealloc];
}

- (id)initWithBookID:(NSManagedObjectID *)aBookID {
    
    BlioBookManager *bookManager = [BlioBookManager sharedBookManager];
    BlioBook *blioBook = [bookManager bookWithID:aBookID];
    NSString *aXpsPath = [blioBook xpsPath];
    
    if (aXpsPath && (self = [super initWithPath:aXpsPath])) {
        bookID = [aBookID retain];
    }
    
    return self;
}

- (BlioDrmSessionManager*)drmSessionManager {
	if ( !drmSessionManager ) {
		drmSessionManager = [[BlioDrmSessionManager alloc] initWithBookID:self.bookID]; 
		if ([drmSessionManager bindToLicense]) { 
			decryptionAvailable = YES; 
			if (reportingStatus != kKNFBDrmBookReportingStatusComplete) { 
				reportingStatus = kKNFBDrmBookReportingStatusRequired; 
			} 
		} 
	} 
	return drmSessionManager;
}

- (NSSet *)enhancedContentItems {
	if (!enhancedContentItems) {
		NSMutableSet *items = [NSMutableSet set];
		
		if ([self componentExistsAtPath:[BlioXPSKNFBEnhancedContentDir stringByAppendingPathComponent:@"OverlayContent.xml"]]) {
			NSData *overlayContentData = [self dataForComponentAtPath:[BlioXPSKNFBEnhancedContentDir stringByAppendingPathComponent:@"OverlayContent.xml"]];
			[items unionSet:[self extractOverlayContent:overlayContentData]];
		}
		
		if ([self componentExistsAtPath:[BlioXPSKNFBEnhancedContentDir stringByAppendingPathComponent:@"VideoContent.xml"]]) {
			NSData *videoContentData = [self dataForComponentAtPath:[BlioXPSKNFBEnhancedContentDir stringByAppendingPathComponent:@"VideoContent.xml"]];
			[items unionSet:[self extractVideoContent:videoContentData]];
		}
		
		enhancedContentItems = [items retain];
	}
	
	return enhancedContentItems;
}

#pragma mark - Subclassed methods

- (NSString *)bookThumbnailsDirectory {
    NSString *thumbnailsDirectory = nil;
    
    BlioBookManager *bookManager = [BlioBookManager sharedBookManager];
    BlioBook *blioBook = [bookManager bookWithID:self.bookID];
    
    NSString *thumbnailsLocation = [blioBook manifestLocationForKey:BlioManifestThumbnailDirectoryKey];
    if ([thumbnailsLocation isEqualToString:BlioManifestEntryLocationXPS]) {
        thumbnailsDirectory = BlioXPSMetaDataDir;
    }
    
    return thumbnailsDirectory;
}

- (id<KNFBDrmBookDecrypter>)drmBookDecrypter {
    return [self drmSessionManager];
}

#pragma mark - BlioLayoutDataSource Methods

- (BOOL)hasEnhancedContent {
    BOOL hasEnhancedContent = ([self componentExistsAtPath:[BlioXPSKNFBEnhancedContentDir stringByAppendingPathComponent:@"OverlayContent.xml"]] ||
                               [self componentExistsAtPath:[BlioXPSKNFBEnhancedContentDir stringByAppendingPathComponent:@"VideoContent.xml"]]);
    
    return hasEnhancedContent;
}

- (NSString *)enhancedContentRootPath {
	return BlioXPSKNFBEnhancedContentDir;
}

- (NSData *)enhancedContentDataAtPath:(NSString *)path {
	return [self dataForComponentAtPath:path];
}

- (NSURL *)temporaryURLForEnhancedContentVideoAtPath:(NSString *)path {
    return [self temporaryURLForComponentAtPath:path];
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

#pragma mark - Private Methods


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
                navigateUri = [[[NSString alloc] initWithUTF8String:atts[i+1]] autorelease];
			} else if (strcmp("ControlType", atts[i]) == 0) {
                controlType = [[[NSString alloc] initWithUTF8String:atts[i+1]] autorelease];
			} else if (strcmp("EnhancedOverlayinfoID", atts[i]) == 0) {
				NSString *attributeString = [[NSString alloc] initWithUTF8String:atts[i+1]];
                if (nil != attributeString) {
                    enhancedOverlayinfoID = [attributeString integerValue];
                    [attributeString release];
                }
			} else if (strcmp("VisualState", atts[i]) == 0) {
				visualState = [[[NSString alloc] initWithUTF8String:atts[i+1]] autorelease];
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
            NSLog(@"ExtractOverlayContent parsing error: '%s'", (char *)XML_ErrorString(XML_GetErrorCode(overlayParser)));
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
                navigateUri = [[[NSString alloc] initWithUTF8String:atts[i+1]] autorelease];
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
            NSLog(@"ExtractVideoContent parsing error: '%s'", (char *)XML_ErrorString(XML_GetErrorCode(videoParser)));
        }
        XML_ParserFree(videoParser);
    }
	
	return items;
	
}

@end
