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

@class EucBUpeBook;

static const NSInteger kBlioBookProcessingStateNotProcessed = 0;
static const NSInteger kBlioBookProcessingStatePlaceholderOnly = 1;
static const NSInteger kBlioBookProcessingStateIncomplete = 2;
static const NSInteger kBlioBookProcessingStatePaused = 3;
static const NSInteger kBlioBookProcessingStateComplete = 4;

@protocol BlioBookText
- (NSArray *)wordStringsForBookmarkRange:(BlioBookmarkRange *)range;
@end

@interface BlioBook : NSManagedObject <BlioBookText> {
    BlioTextFlow *textFlow;
    EucBUpeBook *ePubBook;
    id<BlioParagraphSource> paragraphSource;
}

// Core data attribute-backed dynamic properties
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *author;
@property (nonatomic, retain) NSNumber *progress;
@property (nonatomic, retain) NSNumber *processingState;
@property (nonatomic, retain) NSNumber *sourceID;
@property (nonatomic, retain) NSString *sourceSpecificID;

// Legacy core data attribute-backed dynamic properties TODO: remove these
@property (nonatomic, retain) NSString *coverFilename;
@property (nonatomic, retain) NSString *epubFilename;
@property (nonatomic, retain) NSString *pdfFilename;
@property (nonatomic, retain) NSString *xpsFilename;
@property (nonatomic, retain) NSNumber *layoutPageEquivalentCount;
@property (nonatomic, retain) NSNumber *libraryPosition;
@property (nonatomic, retain) NSNumber *hasAudioRights;
@property (nonatomic, retain) NSString *audiobookFilename;
@property (nonatomic, retain) NSString *timingIndicesFilename;
@property (nonatomic, retain) NSString *textFlowFilename;

// Legacy core data attribute-backed convenience accessors TODO: remove these
@property (nonatomic, assign, readonly) UIImage *coverImage;
@property (nonatomic, assign, readonly) UIImage *coverThumbForGrid;
@property (nonatomic, assign, readonly) UIImage *coverThumbForList;
@property (nonatomic, assign, readonly) NSString *ePubPath;
@property (nonatomic, assign, readonly) NSString *pdfPath;
@property (nonatomic, assign, readonly) NSString *xpsPath;
@property (nonatomic, assign, readonly) NSString *audiobookPath;
@property (nonatomic, assign, readonly) NSString *timingIndicesPath;
@property (nonatomic, assign, readonly) NSString *textFlowPath;
@property (nonatomic, assign, readonly) BOOL audioRights;

// Lazily instantiated convenience accessors
@property (nonatomic, retain) BlioBookmarkPoint *implicitBookmarkPoint;
@property (nonatomic, retain, readonly) BlioTextFlow *textFlow;
@property (nonatomic, retain, readonly) EucBUpeBook *ePubBook;
@property (nonatomic, retain, readonly) id<BlioParagraphSource> paragraphSource;

// Core data attribute-backed convenience accessors
@property (nonatomic, assign, readonly) NSString* bookCacheDirectory;
@property (nonatomic, assign, readonly) NSString* bookTempDirectory;

// Book manifest-backed convenience accessors

// Call to release all derived (i.e. not stored in CoreData) attributes 
// (textflow, ePub book etc.)
- (void)flushCaches;

- (NSArray *)sortedBookmarks;
- (NSArray *)sortedNotes;
- (NSArray *)sortedHighlights;
- (NSArray *)sortedHighlightRangesForLayoutPage:(NSInteger)layoutPage;
- (NSArray *)sortedHighlightRangesForRange:(BlioBookmarkRange *)range;
- (NSManagedObject *)fetchHighlightWithBookmarkRange:(BlioBookmarkRange *)range;


@end
