//
//  BlioXPSProvider.h
//  BlioApp
//
//  Created by matt on 08/07/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BlioLayoutDataSource.h"
#import "BlioTimeOrderedCache.h"
#import "BlioDrmSessionManager.h"
#import "XpsSdk.h"

typedef enum {
    kBlioXPSProviderReportingStatusNotRequired = 0,
    kBlioXPSProviderReportingStatusRequired,
    kBlioXPSProviderReportingStatusComplete
} BlioXPSProviderReportingStatus;

@interface BlioXPSProvider : NSObject <BlioLayoutDataSource, NSXMLParserDelegate> {
    NSManagedObjectID *bookID;
	BlioDrmSessionManager* drmSessionManager;
    
    NSLock *renderingLock;
    NSLock *contentsLock;
    
    NSString *tempDirectory;
    NSInteger pageCount;
    RasterImageInfo *imageInfo;
    XPS_HANDLE xpsHandle;
    FixedPageProperties properties;
    
    NSMutableDictionary *xpsData;
    NSMutableArray *uriMap;
    NSMutableString *currentUriString;
	NSString *xpsPagesDirectory;
	NSMutableArray *_encryptedEPubPaths;

    BlioTimeOrderedCache *componentCache;
    NSNumber *bookIsEncrypted;
    BOOL decryptionAvailable;
    BlioXPSProviderReportingStatus reportingStatus;
	
	NSSet *enhancedContentItems;
}

@property (nonatomic, assign, readonly) BOOL decryptionAvailable;
@property (nonatomic, assign, readonly) BOOL bookIsEncrypted;
@property (nonatomic, retain) NSManagedObjectID *bookID;
@property (nonatomic, readonly) NSArray * encryptedEPubPaths;

- (void)bindToDRMLicense;
- (id)initWithBookID:(NSManagedObjectID *)aBookID;
- (NSData *)dataForComponentAtPath:(NSString *)path;
- (BOOL)componentExistsAtPath:(NSString *)path;
- (void)reportReadingIfRequired;

@end

@interface BlioXPSProtocol : NSURLProtocol {}

+ (NSString *)xpsProtocolScheme;
+ (void)registerXPSProtocol;
			
@end
