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

static const NSInteger kBlioMockBookProcessingStateIncomplete = 0;
static const NSInteger kBlioMockBookProcessingStatePaused = 1;
static const NSInteger kBlioMockBookProcessingStateComplete = 2;

@protocol BlioBookText
- (NSArray *)wordStringsForBookmarkRange:(BlioBookmarkRange *)range;
@end


@interface BlioMockBook : NSManagedObject <BlioBookText> {
    UIImage *coverThumb;
    BlioTextFlow *textFlow;
    id<BlioParagraphSource> paragraphSource;
}

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *author;
@property (nonatomic, retain) NSString *coverFilename;
@property (nonatomic, retain) NSString *epubFilename;
@property (nonatomic, retain) NSString *pdfFilename;
@property (nonatomic, retain) NSNumber *progress;
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

- (BlioTextFlow *)textFlow;
- (id<BlioParagraphSource>)paragraphSource;

- (NSArray *)sortedBookmarks;
- (NSArray *)sortedNotes;
- (NSArray *)sortedHighlights;
- (NSArray *)sortedHighlightRangesForLayoutPage:(NSInteger)layoutPage;
- (NSArray *)sortedHighlightRangesForRange:(BlioBookmarkRange *)range;
- (NSManagedObject *)fetchHighlightWithBookmarkRange:(BlioBookmarkRange *)range;


@end
