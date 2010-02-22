/*
 *  BlioBookView.h
 *  BlioApp
 *
 *  Created by James Montgomerie on 05/01/2010.
 *  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
 *
 */

#import "BlioBookmark.h"

#pragma mark -
@protocol BlioBookDelegate <NSObject>

@required
- (NSArray *)rangesToHighlightForRange:(BlioBookmarkRange *)range;
- (NSArray *)rangesToHighlightForLayoutPage:(NSInteger)pageNumber;
- (void)updateHighlightAtRange:(BlioBookmarkRange *)fromRange toRange:(BlioBookmarkRange *)toRange withColor:(UIColor *)newColor;
- (void)addHighlightWithColor:(UIColor *)color;
- (void)addHighlightNoteWithColor:(UIColor *)color;
- (void)removeHighlightAtRange:(BlioBookmarkRange *)range;
- (void)updateHighlightNoteAtRange:(BlioBookmarkRange *)highlightRange withColor:(UIColor *)newColor;

- (void)hideToolbars;
- (void)toggleToolbars;

@end

#pragma mark -
@protocol BlioTTSDataSource <NSObject>

@required
- (id)getCurrentParagraphId;
- (uint32_t)getCurrentWordOffset;
- (id)paragraphIdForParagraphAfterParagraphWithId:(id)paragraphId;
- (NSArray *)paragraphWordsForParagraphWithId:(id)paragraphId;
- (void)highlightWordAtParagraphId:(id)paragraphId wordOffset:(uint32_t)wordOffset;
@end

#pragma mark -

@protocol EucBookContentsTableViewControllerDataSource;
@class BlioBookmarkAbsolutePoint;
@class BlioBookmarkRange;
@class BlioMockBook;

@protocol BlioBookView <NSObject>

@required

@property (nonatomic, readonly) NSInteger pageCount;
@property (nonatomic, readonly) BOOL wantsTouchesSniffed;

// Page numbers start at 1.
// The EucBookContentsTableViewControllerDataSource protocol defines a way to 
// map from page numbers to 'display' page number strings.
@property (nonatomic, readonly) NSInteger pageNumber;

- (id)initWithBook:(BlioMockBook *)aBook animated:(BOOL)animated;
- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated;
- (void)goToPageNumber:(NSInteger)pageNumber animated:(BOOL)animated;

@property (nonatomic, readonly) BlioBookmarkAbsolutePoint *pageBookmarkPoint;
- (void)goToBookmarkPoint:(BlioBookmarkAbsolutePoint *)bookmarkPoint animated:(BOOL)animated;
- (NSInteger)pageNumberForBookmarkPoint:(BlioBookmarkAbsolutePoint *)bookmarkPoint;

@property (nonatomic, readonly) id<EucBookContentsTableViewControllerDataSource> contentsDataSource;

@property (nonatomic, readonly) CGRect firstPageRect;

@optional
@property (nonatomic, assign) CGFloat fontPointSize;

// Page texture-related properties are readony because
// - (void)setPageTexture:(UIImage *)pageTexture isDark:(BOOL)isDark;
// should be used to set them atomically.
@property (nonatomic, retain, readonly) UIImage *pageTexture;
@property (nonatomic, assign, readonly) BOOL pageTextureIsDark;
- (void)setPageTexture:(UIImage *)pageTexture isDark:(BOOL)isDark;

// BookMarkRange methods - some of these should be required once flow view is ready
- (BlioBookmarkRange *)selectedRange;
- (NSInteger)pageNumberForBookmarkRange:(BlioBookmarkRange *)bookmarkRange;
- (void)goToBookmarkRange:(BlioBookmarkRange *)bookmarkRange animated:(BOOL)animated;

@end