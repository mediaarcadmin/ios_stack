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
#import "BlioBookmark.h"

@interface BlioMockBook : NSManagedObject {
    UIImage *coverThumb;
    BlioTextFlow *textFlow;
}

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *author;
@property (nonatomic, retain) NSString *coverFilename;
@property (nonatomic, retain) NSString *epubFilename;
@property (nonatomic, retain) NSString *pdfFilename;
@property (nonatomic, retain) NSNumber *progress;
@property (nonatomic, retain) NSNumber *proportionateSize;
@property (nonatomic, retain) NSNumber *position;
@property (nonatomic, retain) NSNumber *layoutPageNumber;
@property (nonatomic, retain) NSNumber *hasAudioRights;
@property (nonatomic, retain) NSString *audiobookFilename;
@property (nonatomic, retain) NSString *timingIndicesFilename;
@property (nonatomic, retain) NSString *textflowFilename;

- (UIImage *)coverImage;
- (UIImage *)coverThumbForGrid;
- (UIImage *)coverThumbForList;
- (NSString *)bookPath;
- (NSString *)pdfPath;
- (NSString *)audiobookPath;
- (NSString *)timingIndicesPath;
- (BOOL)audioRights;
- (NSString *)textflowPath;
- (BlioTextFlow *)textFlow;

- (NSArray *)sortedBookmarks;
- (NSArray *)sortedNotes;
- (NSArray *)sortedHighlights;
- (NSArray *)sortedHighlightRangesForLayoutPage:(NSInteger)layoutPage;
- (NSArray *)sortedHighlightRangesForRange:(BlioBookmarkRange *)range;

@end
