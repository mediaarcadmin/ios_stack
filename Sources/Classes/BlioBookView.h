/*
 *  BlioBookView.h
 *  BlioApp
 *
 *  Created by James Montgomerie on 05/01/2010.
 *  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
 *
 */

#import "BlioBookmark.h"
#import "BlioWebToolsViewController.h"

#pragma mark -
@protocol BlioBookViewDelegate <NSObject>

@required
- (NSArray *)rangesToHighlightForRange:(BlioBookmarkRange *)range;
- (NSArray *)rangesToHighlightForLayoutPage:(NSInteger)pageNumber;
- (void)updateHighlightAtRange:(BlioBookmarkRange *)fromRange toRange:(BlioBookmarkRange *)toRange withColor:(UIColor *)newColor;
- (void)addHighlightWithColor:(UIColor *)color;
- (void)addHighlightNoteWithColor:(UIColor *)color;
- (void)removeHighlightAtRange:(BlioBookmarkRange *)range;
- (void)updateHighlightNoteAtRange:(BlioBookmarkRange *)highlightRange withColor:(UIColor *)newColor;

- (void)copyWithRange:(BlioBookmarkRange *)range;

- (void)openWebToolWithRange:(BlioBookmarkRange *)range toolType:(BlioWebToolsType)type;

- (void)showToolbars;
- (void)hideToolbars;
- (void)hideToolbarsAndStatusBar:(BOOL)hidesStatusBar;
- (void)toggleToolbars;
- (void)togglePauseButton;
- (BOOL)toolbarsVisible;
- (BOOL)audioPlaying;

@property (nonatomic, readonly) BOOL audioPlaying;

- (CGRect)nonToolbarRect;
@end

#pragma mark -

@protocol EucBookContentsTableViewControllerDataSource;
@class BlioBookmarkPoint;
@class BlioBookmarkRange;

@protocol BlioBookView <NSObject>

@required

@property (nonatomic, readonly) NSInteger pageCount;
@property (nonatomic, readonly) BOOL wantsTouchesSniffed;

// Page numbers start at 1.
// The EucBookContentsTableViewControllerDataSource protocol defines a way to 
// map from page numbers to 'display' page number strings.
@property (nonatomic, readonly) NSInteger pageNumber;

- (NSString *)pageLabelForPageNumber:(NSInteger)pageNumber;

- (id)initWithFrame:(CGRect)frame
             bookID:(NSManagedObjectID *)bookID 
           animated:(BOOL)animated;

- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated;
- (void)goToPageNumber:(NSInteger)pageNumber animated:(BOOL)animated;

@property (nonatomic, readonly) BlioBookmarkPoint *currentBookmarkPoint;
- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated;
- (NSInteger)pageNumberForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;

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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;

- (void)highlightWordAtBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;

- (BOOL)toolbarShowShouldBeSuppressed;

@end