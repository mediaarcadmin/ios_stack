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
#import "BlioParagraphSource.h"
#import "BlioBookmark.h"

@class BlioXPSProvider;

static const CGFloat kBlioCoverListThumbHeight = 76;
static const CGFloat kBlioCoverListThumbWidth = 53;
static const CGFloat kBlioCoverGridThumbWidthPhone = 106;
static const CGFloat kBlioCoverGridThumbHeightPhone = 140;
static const CGFloat kBlioCoverGridThumbWidthPad = 140;
static const CGFloat kBlioCoverGridThumbHeightPad = 210;

static const NSInteger kBlioBookProcessingStateNotProcessed = 0;
static const NSInteger kBlioBookProcessingStatePlaceholderOnly = 1;
static const NSInteger kBlioBookProcessingStateIncomplete = 2;
static const NSInteger kBlioBookProcessingStateFailed = 3;
static const NSInteger kBlioBookProcessingStateNotSupported = 4;
static const NSInteger kBlioBookProcessingStatePaused = 5;
static const NSInteger kBlioBookProcessingStateSuspended = 6;
static const NSInteger kBlioBookProcessingStateComplete = 7;

static NSString * const BlioManifestEntryLocationFileSystem = @"fileSystem";
static NSString * const BlioManifestEntryLocationXPS = @"xps";
static NSString * const BlioManifestEntryLocationTextflow = @"textflow";
static NSString * const BlioManifestEntryLocationWeb = @"web";
static NSString * const BlioManifestEntryLocationBundle = @"bundle";
static NSString * const BlioManifestEntryLocationDocumentsDirectory = @"DocumentsDirectory";

static NSString * const BlioXPSEncryptedUriMap = @"/Documents/1/Other/KNFB/UriMap.xml";
static NSString * const BlioXPSEncryptedPagesDir = @"/Documents/1/Other/KNFB/Epages";
static NSString * const BlioXPSEncryptedImagesDir = @"/Resources";
static NSString * const BlioXPSEncryptedTextFlowDir = @"/Documents/1/Other/KNFB/Flow";
static NSString * const BlioXPSMetaDataDir = @"/Documents/1/Metadata";
static NSString * const BlioXPSPagesDir = @"/Documents/1/Pages";
static NSString * const BlioXPSCoverImage = @"/Documents/1/Other/KNFB/CoverArt.jpg";
static NSString * const BlioXPSTextFlowSectionsFile = @"/Documents/1/Other/KNFB/Flow/Sections.xml";
static NSString * const BlioXPSKNFBMetadataFile = @"/Documents/1/Other/KNFB/Metadata.xml";
static NSString * const BlioXPSKNFBRightsFile = @"/Documents/1/Other/KNFB/Rights.xml";
static NSString * const BlioXPSAudiobookDirectory = @"/Documents/1/Other/KNFB/Audio/";
static NSString * const BlioXPSAudiobookMetadataFile = @"/Documents/1/Other/KNFB/Audio/Audio.xml";
static NSString * const BlioXPSAudiobookReferencesFile = @"/Documents/1/Other/KNFB/Audio/References.xml";
static NSString * const BlioXPSKNFBDRMHeaderFile = @"/Documents/1/Other/KNFB/DrmpHeader.bin";

static NSString * const BlioXPSComponentExtensionFPage = @"fpage";
static NSString * const BlioXPSComponentExtensionRels = @"rels";
static NSString * const BlioXPSComponentExtensionEncrypted = @"bin";

static NSString * const BlioManifestAudiobookKey = @"audiobookFilename";
static NSString * const BlioManifestEPubKey = @"epubFilename";
static NSString * const BlioManifestPDFKey = @"pdfFilename";
static NSString * const BlioManifestTextFlowKey = @"textFlowFilename";
static NSString * const BlioManifestXPSKey = @"xpsFilename";
static NSString * const BlioManifestCoverKey = @"coverFilename";
static NSString * const BlioManifestThumbnailDirectoryKey = @"thumbnailDirectory";
static NSString * const BlioManifestRightsKey = @"rightsFilename";
static NSString * const BlioManifestAudiobookDataFilesKey = @"audiobookDataFiles";
static NSString * const BlioManifestAudiobookTimingFilesKey = @"audiobookTimingFiles";
static NSString * const BlioManifestKNFBMetadataKey = @"KNFBMetadataFilename";
static NSString * const BlioManifestPreAvailabilityCompleteKey = @"preAvailabilityComplete";
static NSString * const BlioManifestDrmHeaderKey = @"drmHeaderFilename";
static NSString * const BlioManifestFirstLayoutPageOnLeftKey = @"firstLayoutPageOnLeft";

static NSString * const BlioManifestEntryLocationKey = @"location";
static NSString * const BlioManifestEntryPathKey = @"path";

@protocol BlioBookText
- (NSArray *)wordStringsForBookmarkRange:(BlioBookmarkRange *)range;
@end

@class BlioTextFlow, BlioParagraphSource;

@interface BlioBook : NSManagedObject <BlioBookText> {
    BlioTextFlow *textFlow;
    BlioXPSProvider *xpsProvider;
    id<BlioParagraphSource> paragraphSource;
}

// Core data attribute-backed dynamic properties
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *author;
@property (nonatomic, retain) NSNumber *progress;
@property (nonatomic, retain) NSNumber *processingState;
@property (nonatomic, retain) NSNumber *sourceID;
@property (nonatomic, retain) NSString *sourceSpecificID;
@property (nonatomic, retain) NSNumber *layoutPageEquivalentCount;
@property (nonatomic, retain) NSNumber *libraryPosition;
@property (nonatomic, retain) NSNumber *reflowRight;

// the following two attributes are used to quickly calculate the number of TTS-compatible books
@property (nonatomic, retain) NSNumber *hasAudiobook;
@property (nonatomic, retain) NSNumber *hasAudiobookRights;

// Legacy core data attribute-backed dynamic properties TODO: remove these
@property (nonatomic, retain) NSString *audiobookFilename;
@property (nonatomic, retain) NSString *timingIndicesFilename;

@property (nonatomic, assign, readonly) BOOL audioRights;
@property (nonatomic, assign, readonly) BOOL reflowEnabled;
@property (nonatomic, assign, readonly) BOOL fixedViewEnabled;

// Lazily convenience accessors
@property (nonatomic, retain) BlioBookmarkPoint *implicitBookmarkPoint;
// These convenience acessors are not guranteed to exists after a memory warning
// If you need to retain the result in your object use the checkout methods in BlioBookManager
@property (nonatomic, retain, readonly) BlioTextFlow *textFlow;
@property (nonatomic, retain, readonly) id<BlioParagraphSource> paragraphSource;

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
@property (nonatomic, assign, readonly) BOOL hasPdf;
@property (nonatomic, assign, readonly) BOOL hasXps;
@property (nonatomic, assign, readonly) BOOL hasCoverImage;
@property (nonatomic, assign, readonly) BOOL hasTextFlow;
@property (nonatomic, assign, readonly) BOOL isEncrypted;
@property (nonatomic, assign, readonly) BOOL hasAppropriateCoverThumbForList;
@property (nonatomic, assign, readonly) BOOL hasAppropriateCoverThumbForGrid;
@property (nonatomic, assign, readonly) BOOL firstLayoutPageOnLeft;


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
+(NSString*)standardNameFromCanonicalName:(NSString*)aName;
+(NSString*)canonicalNameFromStandardName:(NSString*)aName;

@end
