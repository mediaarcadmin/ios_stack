//
//  MockBook.h
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

@class BlioEPubBook, BlioXPSProvider;

static const NSInteger kBlioBookProcessingStateNotProcessed = 0;
static const NSInteger kBlioBookProcessingStatePlaceholderOnly = 1;
static const NSInteger kBlioBookProcessingStateIncomplete = 2;
static const NSInteger kBlioBookProcessingStatePaused = 3;
static const NSInteger kBlioBookProcessingStateComplete = 4;

static NSString * const BlioManifestEntryLocationFileSystem = @"fileSystem";
static NSString * const BlioManifestEntryLocationXPS = @"xps";
static NSString * const BlioManifestEntryLocationTextflow = @"textflow";
static NSString * const BlioManifestEntryLocationWeb = @"web";
static NSString * const BlioManifestEntryLocationBundle = @"bundle";



@protocol BlioBookText
- (NSArray *)wordStringsForBookmarkRange:(BlioBookmarkRange *)range;
@end

@class BlioTextFlow, BlioEPubBook, BlioParagraphSource;

@interface BlioBook : NSManagedObject <BlioBookText> {
    BlioTextFlow *textFlow;
    BlioEPubBook *ePubBook;
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

// Legacy core data attribute-backed dynamic properties TODO: remove these
@property (nonatomic, retain) NSNumber *hasAudioRights;
@property (nonatomic, retain) NSString *audiobookFilename;
@property (nonatomic, retain) NSString *timingIndicesFilename;

// Legacy core data attribute-backed convenience accessors TODO: remove these
@property (nonatomic, assign, readonly) NSString *audiobookPath;
@property (nonatomic, assign, readonly) NSString *timingIndicesPath;
@property (nonatomic, assign, readonly) BOOL audioRights;

// Lazily convenience accessors
@property (nonatomic, retain) BlioBookmarkPoint *implicitBookmarkPoint;
// These convenience acessors are not guranteed to exists after a memory warning
// If you need to retain the result in your object use the checkout methods in BlioBookManager
@property (nonatomic, retain, readonly) BlioTextFlow *textFlow;
@property (nonatomic, retain, readonly) BlioEPubBook *ePubBook;
@property (nonatomic, retain, readonly) BlioXPSProvider *xpsProvider;
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
@property (nonatomic, assign, readonly) NSString *textFlowPath;

// Call to release all derived (i.e. not stored in CoreData) attributes 
// (textflow, ePub book etc.)
- (void)flushCaches;

- (NSArray *)sortedBookmarks;
- (NSArray *)sortedNotes;
- (NSArray *)sortedHighlights;
- (NSArray *)sortedHighlightRangesForLayoutPage:(NSInteger)layoutPage;
- (NSArray *)sortedHighlightRangesForRange:(BlioBookmarkRange *)range;
- (NSManagedObject *)fetchHighlightWithBookmarkRange:(BlioBookmarkRange *)range;

- (void)setManifestValue:(id)value forKey:(NSString *)key;
- (BOOL)hasManifestValueForKey:(NSString *)key;
- (NSData *)manifestDataForKey:(NSString *)key;
- (NSString *)manifestPathForKey:(NSString *)key;

@end
