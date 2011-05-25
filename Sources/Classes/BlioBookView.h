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
- (void)refreshHighlights;
- (void)updateHighlightNoteAtRange:(BlioBookmarkRange *)highlightRange toRange:(BlioBookmarkRange *)toRange withColor:(UIColor *)newColor;
- (BOOL)hasNoteOverlappingSelectedRange;

- (void)copyWithRange:(BlioBookmarkRange *)range;

- (void)openWebToolWithRange:(BlioBookmarkRange *)range toolType:(BlioWebToolsType)type;

- (void)showToolbars;
- (void)hideToolbars;
- (void)hideToolbarsAndStatusBar:(BOOL)hidesStatusBar;
- (void)toggleToolbars;
- (BOOL)toolbarsVisible;
- (BOOL)audioPlaying;
- (void)cancelPendingToolbarShow;

@property (nonatomic, readonly) BOOL audioPlaying;

- (CGRect)nonToolbarRect;
- (void)firstPageDidRender;

- (void)pushBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;

@end

#pragma mark -

@protocol EucBookContentsTableViewControllerDataSource;
@class BlioBookmarkPoint;
@class BlioBookmarkRange;

@protocol BlioBookView <NSObject>

@required

@property (nonatomic, assign) id<BlioBookViewDelegate> delegate;

@property (nonatomic, readonly) BOOL wantsTouchesSniffed;

- (id)initWithFrame:(CGRect)frame
             bookID:(NSManagedObjectID *)bookID 
           animated:(BOOL)animated;

- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated;
@property (nonatomic, retain, readonly) NSString *currentUuid;

@property (nonatomic, retain, readonly) BlioBookmarkPoint *currentBookmarkPoint;
- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated;
- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated saveToHistory:(BOOL)save;
- (void)pushCurrentBookmarkPoint;

- (BlioBookmarkPoint *)bookmarkPointForPercentage:(float)percentage;
- (float)percentageForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;

- (NSString *)displayPageNumberForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;
- (NSString *)pageLabelForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;

- (BOOL)currentPageContainsBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;

@property (nonatomic, readonly) id<EucBookContentsTableViewControllerDataSource> contentsDataSource;

@property (nonatomic, readonly) CGRect firstPageRect;

@optional
@property (nonatomic, assign) CGFloat fontPointSize;
@property (nonatomic, readonly) UIImage *dimPageImage;

// Page texture-related properties are readony because
// - (void)setPageTexture:(UIImage *)pageTexture isDark:(BOOL)isDark;
// should be used to set them atomically.
@property (nonatomic, retain, readonly) UIImage *pageTexture;
@property (nonatomic, assign, readonly) BOOL pageTextureIsDark;
- (void)setPageTexture:(UIImage *)pageTexture isDark:(BOOL)isDark;

// Implement if pageLabelForBookmarkPoint: is expensive for smooth slider operation.
- (NSString *)pageLabelForPercentage:(float)percenatage;

// BookMarkRange methods - some of these should be required once flow view is ready
- (BlioBookmarkRange *)selectedRange;

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;

- (void)highlightWordAtBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;
- (void)highlightWordAtBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint saveToHistory:(BOOL)save;

- (void)highlightWordsInBookmarkRange:(BlioBookmarkRange *)bookmarkRange animated:(BOOL)animated;
- (void)highlightWordsInBookmarkRange:(BlioBookmarkRange *)bookmarkRange animated:(BOOL)animated saveToHistory:(BOOL)save;

- (BOOL)toolbarShowShouldBeSuppressed; 
- (BOOL)toolbarHideShouldBeSuppressed; 

- (UIImage*)previewThumbnailForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;

- (void)refreshHighlights;

@end