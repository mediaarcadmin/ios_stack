//
//  BlioBook.h
//  LibraryView
//
//  Created by matt on 15/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//
#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BlioTextFlow.h"
#import "BlioBookmark.h"
#import "BlioXPSProvider.h"
#import "KNFBXPSConstants.h"

static const CGFloat kBlioCoverListThumbWidth = 42;
static const CGFloat kBlioCoverListThumbHeight = 64;
static const CGFloat kBlioCoverGridThumbWidthPhone = 84;
static const CGFloat kBlioCoverGridThumbHeightPhone = 118;
static const CGFloat kBlioCoverGridThumbWidthPad = 140;
static const CGFloat kBlioCoverGridThumbHeightPad = 210;

static const NSInteger kBlioBookProcessingStateToBeDeleted = -1;
static const NSInteger kBlioBookProcessingStateNotProcessed = 0;
static const NSInteger kBlioBookProcessingStatePlaceholderOnly = 1;
static const NSInteger kBlioBookProcessingStateIncomplete = 2;
static const NSInteger kBlioBookProcessingStateFailed = 3;
static const NSInteger kBlioBookProcessingStateNotSupported = 4;
static const NSInteger kBlioBookProcessingStatePaused = 5;
static const NSInteger kBlioBookProcessingStateSuspended = 6;
static const NSInteger kBlioBookProcessingStateComplete = 7;

static NSString * const BlioManifestEntryLocationFileSystem = @"BlioManifestEntryLocationFileSystem";
static NSString * const BlioManifestEntryLocationXPS = @"BlioManifestEntryLocationXPS";
static NSString * const BlioManifestEntryLocationTextflow = @"BlioManifestEntryLocationTextflow";
static NSString * const BlioManifestEntryLocationWeb = @"BlioManifestEntryLocationWeb";
static NSString * const BlioManifestEntryLocationBundle = @"BlioManifestEntryLocationBundle";
static NSString * const BlioManifestEntryLocationDocumentsDirectory = @"BlioManifestEntryLocationDocumentsDirectory";
static NSString * const BlioManifestEntryLocationFileSystemOther = @"BlioManifestEntryLocationFileSystemOther";

static NSString * const BlioManifestAudiobookKey = @"BlioManifestAudiobookKey";
static NSString * const BlioManifestEPubKey = @"BlioManifestEPubKey";
static NSString * const BlioManifestEPubInfoFileKey = @"BlioManifestEPubInfoFileKey";
static NSString * const BlioManifestPDFKey = @"BlioManifestPDFKey";
static NSString * const BlioManifestTextFlowKey = @"BlioManifestTextFlowKey";
static NSString * const BlioManifestXPSKey = @"BlioManifestXPSKey";
static NSString * const BlioManifestLicenseAcquisitionCompleteKey = @"BlioManifestLicenseAcquisitionCompleteKey";
static NSString * const BlioManifestCoverKey = @"CoverImage";
static NSString * const BlioManifestThumbnailDirectoryKey = @"BlioManifestThumbnailDirectoryKey";
static NSString * const BlioManifestRightsKey = @"BlioManifestRightsKey";
static NSString * const BlioManifestAudiobookMetadataKey = @"BlioManifestAudiobookMetadataKey";
static NSString * const BlioManifestAudiobookDataFilesKey = @"BlioManifestAudiobookDataFilesKey";
static NSString * const BlioManifestAudiobookReferencesKey = @"BlioManifestAudiobookReferencesKey";
static NSString * const BlioManifestAudiobookTimingFilesKey = @"BlioManifestAudiobookTimingFilesKey";
static NSString * const BlioManifestKNFBMetadataKey = @"BlioManifestKNFBMetadataKey";
static NSString * const BlioManifestPreAvailabilityCompleteKey = @"BlioManifestPreAvailabilityCompleteKey";
static NSString * const BlioManifestDrmHeaderKey = @"BlioManifestDrmHeaderKey";
static NSString * const BlioManifestFirstLayoutPageOnLeftKey = @"BlioManifestFirstLayoutPageOnLeftKey";

static NSString * const BlioManifestEntryLocationKey = @"BlioManifestEntryLocationKey";
static NSString * const BlioManifestEntryPathKey = @"BlioManifestEntryPathKey";

static NSString * const BlioBookEucalyptusCacheDir = @"libEucalyptusCache";
static NSString * const BlioBookThumbnailsDir = @"thumbnails";
static NSString * const BlioBookThumbnailPrefix = @"thumbnail";

#define BlioXPSEncryptedUriMap KNFBXPSEncryptedUriMap
#define BlioXPSEncryptedPagesDir KNFBXPSEncryptedPagesDir
#define BlioXPSEncryptedImagesDir KNFBXPSEncryptedImagesDir
#define BlioXPSEncryptedTextFlowDir KNFBXPSEncryptedTextFlowDir
#define BlioXPSMetaDataDir KNFBXPSMetaDataDir
#define BlioXPSCoverImage KNFBXPSCoverImage
#define BlioXPSFixedDocumentSequenceFile KNFBXPSFixedDocumentSequenceFile
#define BlioXPSFixedDocumentSequenceExtension KNFBXPSFixedDocumentSequenceExtension
#define BlioXPSTextFlowSectionsFile KNFBXPSTextFlowSectionsFile
#define BlioXPSKNFBMetadataFile KNFBXPSKNFBMetadataFile
#define BlioXPSKNFBRightsFile KNFBXPSKNFBRightsFile
#define BlioXPSAudiobookDirectory KNFBXPSAudiobookDirectory
#define BlioXPSAudiobookMetadataFile KNFBXPSAudiobookMetadataFile
#define BlioXPSAudiobookReferencesFile KNFBXPSAudiobookReferencesFile
#define BlioXPSKNFBDRMHeaderFile KNFBXPSKNFBDRMHeaderFile
#define BlioXPSComponentExtensionFPage KNFBXPSComponentExtensionFPage
#define BlioXPSComponentExtensionRels KNFBXPSComponentExtensionRels
#define BlioXPSComponentExtensionEncrypted KNFBXPSComponentExtensionEncrypted

#define BlioXPSKNFBEPubInfoFile KNFBXPSKNFBEPubInfoFile
#define BlioXPSEPubMetaInfContainerFile KNFBXPSEPubMetaInfContainerFile

@protocol BlioBookText
- (NSArray *)wordStringsForBookmarkRange:(BlioBookmarkRange *)range;
@end

@class BlioTextFlow;
@class BlioXPSProvider;

@interface BlioBook : NSManagedObject <BlioBookText> {
    BlioTextFlow *textFlow;
    BlioXPSProvider *xpsProvider;
}

// Core data attribute-backed dynamic properties
@property (nonatomic, retain) NSString *author;
@property (nonatomic, retain) NSDate *expirationDate;
@property (nonatomic, retain) NSNumber *layoutPageEquivalentCount;
@property (nonatomic, retain) NSNumber *libraryPosition;
@property (nonatomic, retain) NSNumber *progress;
@property (nonatomic, retain) NSNumber *processingState;
@property (nonatomic, retain) NSNumber *reflowRight;
@property (nonatomic, retain) NSNumber *sourceID;
@property (nonatomic, retain) NSString *sourceSpecificID;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *titleSortable;
@property (nonatomic, retain) NSNumber *transactionType;

// the following two attributes are used to quickly calculate the number of TTS-compatible books
@property (nonatomic, retain) NSNumber *audiobook;
@property (nonatomic, retain) NSNumber *ttsRight;
@property (nonatomic, retain) NSNumber *ttsCapable;


@property (nonatomic, assign, readonly) BOOL hasAudiobook;
@property (nonatomic, assign, readonly) BOOL isTTSCapable;
@property (nonatomic, assign, readonly) BOOL hasTTSRights;
@property (nonatomic, assign, readonly) BOOL reflowEnabled;
@property (nonatomic, assign, readonly) BOOL fixedViewEnabled;

// Lazily convenience accessors
@property (nonatomic, retain) BlioBookmarkPoint *implicitBookmarkPoint;
// Objects returned by this convenience acessors is not guranteed to exist after a memory warning
// If you need to retain the result in your object use the checkout methods in BlioBookManager
@property (nonatomic, retain, readonly) BlioTextFlow *textFlow;

// Core data attribute-backed convenience accessors
@property (nonatomic, assign, readonly) NSString* bookCacheDirectory;
@property (nonatomic, assign, readonly) NSString* bookTempDirectory;

// Book manifest-backed convenience accessors
@property (nonatomic, assign, readonly) UIImage *coverImage;
@property (nonatomic, assign, readonly) UIImage *coverThumbForGrid;
@property (nonatomic, assign, readonly) UIImage *coverThumbForList;
@property (nonatomic, assign, readonly) NSString *ePubPath;
@property (nonatomic, assign, readonly) NSString *pdfPath;
@property (nonatomic, assign, readonly) NSString *xpsPath;
@property (nonatomic, assign, readonly) BOOL hasEPub;
@property (nonatomic, assign, readonly) BOOL hasEmbeddedEPub;
@property (nonatomic, assign, readonly) BOOL hasPdf;
@property (nonatomic, assign, readonly) BOOL hasXps;
@property (nonatomic, assign, readonly) BOOL hasCoverImage;
@property (nonatomic, assign, readonly) BOOL hasTextFlow;
@property (nonatomic, assign, readonly) BOOL isEncrypted;
@property (nonatomic, assign, readonly) BOOL decryptionIsAvailable;
@property (nonatomic, assign, readonly) BOOL hasAppropriateCoverThumbForList;
@property (nonatomic, assign, readonly) BOOL hasAppropriateCoverThumbForGrid;
@property (nonatomic, assign, readonly) BOOL firstLayoutPageOnLeft;
@property (nonatomic, assign, readonly) BOOL hasSearch;
@property (nonatomic, assign, readonly) BOOL hasTOC;


// Call to release all derived (i.e. not stored in CoreData) attributes 
// (textflow etc.)
- (void)flushCaches;
- (void)reportReadingIfRequired;

- (NSArray *)sortedBookmarks;
- (NSArray *)sortedNotes;
- (NSArray *)sortedHighlights;
- (NSArray *)sortedHighlightRangesForLayoutPage:(NSInteger)layoutPage;
- (NSArray *)sortedHighlightRangesForRange:(BlioBookmarkRange *)range;
- (NSManagedObject *)fetchHighlightWithBookmarkRange:(BlioBookmarkRange *)range;

- (NSData *)textFlowDataWithPath:(NSString *)path;

- (void)setManifestValue:(id)value forKey:(NSString *)key;
- (BOOL)hasManifestValueForKey:(NSString *)key;
- (NSData *)manifestDataForKey:(NSString *)key;
- (BOOL)manifestPath:(NSString *)path existsForLocation:(NSString *)location;
- (NSString *)manifestPathForKey:(NSString *)key;
- (NSString *)manifestRelativePathForKey:(NSString *)key;
- (NSData *)manifestDataForKey:(NSString *)key pathIndex:(NSInteger)index;
- (NSString *)manifestLocationForKey:(NSString *)key;
- (BOOL)manifestPreAvailabilityCompleteForKey:(NSString *)key;
- (NSString *)authorsWithStandardFormat;

+(NSString*)standardNamesFromCanonicalNameArray:(NSArray*)aNameArray;
+(NSArray*) suffixes;
+(NSArray*) suffixesWithoutCommas;
+(NSArray*) prefixes;
+(NSArray*) specialSuffixes;
+(NSString*)standardNameFromCanonicalName:(NSString*)aName;
+(NSString*)canonicalNameFromStandardName:(NSString*)aName;

@end
