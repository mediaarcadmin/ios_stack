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
    NSLock *inflateLock;
    
    NSString *tempDirectory;
    NSInteger pageCount;
    RasterImageInfo *imageInfo;
    XPS_HANDLE xpsHandle;
    FixedPageProperties properties;
    
    NSMutableDictionary *xpsData;
    NSMutableArray *uriMap;
    NSMutableString *currentUriString;
	NSString *xpsPagesDirectory;
    
    BlioTimeOrderedCache *componentCache;
    NSNumber *bookIsEncrypted;
    BOOL decryptionAvailable;
    BlioXPSProviderReportingStatus reportingStatus;
}

@property (nonatomic, retain) NSManagedObjectID *bookID;

- (id)initWithBookID:(NSManagedObjectID *)aBookID;
- (NSData *)dataForComponentAtPath:(NSString *)path;
- (BOOL)componentExistsAtPath:(NSString *)path;
- (void)reportReadingIfRequired;

@end
