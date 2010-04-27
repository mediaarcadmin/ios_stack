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

static const NSInteger kBlioMockBookProcessingStateNotProcessed = 0;
static const NSInteger kBlioMockBookProcessingStatePlaceholderOnly = 1;
static const NSInteger kBlioMockBookProcessingStateIncomplete = 2;
static const NSInteger kBlioMockBookProcessingStatePaused = 3;
static const NSInteger kBlioMockBookProcessingStateComplete = 4;

@protocol BlioBookText
- (NSArray *)wordStringsForBookmarkRange:(BlioBookmarkRange *)range;
@end


@interface BlioMockBook : NSManagedObject <BlioBookText> {
    UIImage *coverThumb;
    BlioTextFlow *textFlow;
    EucBUpeBook *ePubBook;
    id<BlioParagraphSource> paragraphSource;
}

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *author;
@property (nonatomic, retain) NSString *coverFilename;
@property (nonatomic, retain) NSString *epubFilename;
@property (nonatomic, retain) NSString *pdfFilename;
@property (nonatomic, retain) NSNumber *progress;
@property (nonatomic, retain) NSNumber *processingComplete;
@property (nonatomic, retain) NSNumber *proportionateSize;
@property (nonatomic, retain) NSNumber *position;
@property (nonatomic, retain) NSNumber *hasAudioRights;
@property (nonatomic, retain) NSString *audiobookFilename;
@property (nonatomic, retain) NSString *timingIndicesFilename;
@property (nonatomic, retain) NSString *textFlowFilename;
@property (nonatomic, retain) NSString *sourceID;
@property (nonatomic, retain) NSString *sourceSpecificID;
@property (nonatomic, retain) NSManagedObject *placeInBook;

// Convenience accessor.
@property (nonatomic, retain) BlioBookmarkPoint *implicitBookmarkPoint;
@property (nonatomic, retain, readonly) BlioTextFlow *textFlow;
@property (nonatomic, retain, readonly) EucBUpeBook *ePubBook;
@property (nonatomic, retain, readonly) id<BlioParagraphSource> paragraphSource;

// Call to release all derived (i.e. not stored in CoreData) attributes 
// (textflow, ePub book etc.)
- (void)flushCaches;


- (NSString *)bookCacheDirectory;
- (NSString *)bookTempDirectory;
- (UIImage *)coverImage;
- (UIImage *)coverThumbForGrid;
- (UIImage *)coverThumbForList;
- (NSString *)ePubPath;
- (NSString *)pdfPath;
- (NSString *)audiobookPath;
- (NSString *)timingIndicesPath;
- (BOOL)audioRights;
- (NSString *)textFlowPath;


- (NSArray *)sortedBookmarks;
- (NSArray *)sortedNotes;
- (NSArray *)sortedHighlights;
- (NSArray *)sortedHighlightRangesForLayoutPage:(NSInteger)layoutPage;
- (NSArray *)sortedHighlightRangesForRange:(BlioBookmarkRange *)range;
- (NSManagedObject *)fetchHighlightWithBookmarkRange:(BlioBookmarkRange *)range;


@end
