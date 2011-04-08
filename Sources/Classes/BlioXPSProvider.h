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
#import "KNFBTimeOrderedCache.h"
#import "BlioDrmSessionManager.h"
#import "XpsSdk.h"

static NSString * const BlioXPSEncryptedUriMap = KNFBXPSEncryptedUriMap;
static NSString * const BlioXPSEncryptedPagesDir = KNFBXPSEncryptedPagesDir;
static NSString * const BlioXPSEncryptedImagesDir = KNFBXPSEncryptedImagesDir;
static NSString * const BlioXPSEncryptedTextFlowDir = KNFBXPSEncryptedTextFlowDir;
static NSString * const BlioXPSMetaDataDir = KNFBXPSMetaDataDir;
static NSString * const BlioXPSCoverImage = KNFBXPSCoverImage;
static NSString * const BlioXPSFixedDocumentSequenceFile = KNFBXPSFixedDocumentSequenceFile;
static NSString * const BlioXPSFixedDocumentSequenceExtension = KNFBXPSFixedDocumentSequenceExtension;
static NSString * const BlioXPSTextFlowSectionsFile = KNFBXPSTextFlowSectionsFile;
static NSString * const BlioXPSKNFBMetadataFile = KNFBXPSKNFBMetadataFile;
static NSString * const BlioXPSKNFBRightsFile = KNFBXPSKNFBRightsFile;
static NSString * const BlioXPSAudiobookDirectory = KNFBXPSAudiobookDirectory;
static NSString * const BlioXPSAudiobookMetadataFile = KNFBXPSAudiobookMetadataFile;
static NSString * const BlioXPSAudiobookReferencesFile = KNFBXPSAudiobookReferencesFile;
static NSString * const BlioXPSKNFBDRMHeaderFile = KNFBXPSKNFBDRMHeaderFile;
static NSString * const BlioXPSComponentExtensionFPage = KNFBXPSComponentExtensionFPage;
static NSString * const BlioXPSComponentExtensionRels = KNFBXPSComponentExtensionRels;
static NSString * const BlioXPSComponentExtensionEncrypted = KNFBXPSComponentExtensionEncrypted;

static NSString * const BlioXPSKNFBEPubInfoFile = KNFBXPSKNFBEPubInfoFile;
static NSString * const BlioXPSEPubMetaInfContainerFile = KNFBXPSEPubMetaInfContainerFile;

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

    KNFBTimeOrderedCache *componentCache;
    NSNumber *bookIsEncrypted;
    BOOL decryptionAvailable;
    BlioXPSProviderReportingStatus reportingStatus;
	NSSet *enhancedContentItems;
}

@property (nonatomic, retain) NSManagedObjectID *bookID;
@property (nonatomic, readonly) NSArray * encryptedEPubPaths;

- (id)initWithBookID:(NSManagedObjectID *)aBookID;
- (NSData *)dataForComponentAtPath:(NSString *)path;
- (BOOL)componentExistsAtPath:(NSString *)path;
- (void)reportReadingIfRequired;
- (BOOL)decryptionIsAvailable;

@end
