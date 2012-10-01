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

@protocol BlioBookView, BlioBookViewDelegate;

typedef enum BlioPageColor {
    kBlioPageColorWhite = 0,
    kBlioPageColorBlack = 1,
    kBlioPageColorNeutral = 2,
} BlioPageColor;

typedef enum BlioJustification {
    kBlioJustificationFull = 0,
    kBlioJustificationLeft = 1,
    kBlioJustificationOriginal = 2,
} BlioJustification;

typedef enum BlioPageLayout {
    kBlioPageLayoutPlainText = 0,
    kBlioPageLayoutPageLayout = 1,
    kBlioPageLayoutSpeedRead = 2,
} BlioPageLayout;

typedef enum BlioTapTurn {
    kBlioTapTurnOff = 0,
    kBlioTapTurnOn = 1,
} BlioTapTurn;

typedef enum BlioTwoUp {
    kBlioTwoUpNever = 0,
    kBlioTwoUpLandscape = 1,
    kBlioTwoUpAlways = 2,
} BlioTwoUp;

typedef enum BlioExtraBoldness {
    kBlioExtraBoldnessNone = 0,
    kBlioExtraBoldnessExtra = 1,
} BlioExtraBoldness;

extern NSString * const kBlioOriginalFontName;

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

- (void)openWordToolWithRange:(BlioBookmarkRange *)range atRect:(CGRect)rect toolType:(BlioWordToolsType)type;

- (void)showToolbars;
- (void)hideToolbars;
- (void)hideToolbarsAndStatusBar:(BOOL)hidesStatusBar;
- (void)toggleToolbars;
- (BOOL)toolbarsVisible;
- (BOOL)audioPlaying;
- (void)cancelPendingToolbarShow;

- (NSArray *)fontSizesForBlioBookView:(id<BlioBookView>)bookView;

@property (nonatomic, readonly) BOOL audioPlaying;

- (CGRect)nonToolbarRect;

- (void)pushBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;
- (void)pageTurnDidComplete;

@end

#pragma mark -

@protocol EucBookContentsTableViewControllerDataSource;
@class BlioBookmarkPoint;
@class BlioBookmarkRange;

@protocol BlioBookView <NSObject>

@required

@property (nonatomic, assign, readonly) id<BlioBookViewDelegate> delegate;

@property (nonatomic, readonly) BOOL wantsTouchesSniffed;

- (id)initWithFrame:(CGRect)frame
           delegate:(id<BlioBookViewDelegate>)delegate
             bookID:(NSManagedObjectID *)bookID 
           animated:(BOOL)animated;

- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated;
@property (nonatomic, retain, readonly) NSString *currentUuid;

@property (nonatomic, retain, readonly) BlioBookmarkPoint *currentBookmarkPoint;
- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated;
- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated saveToHistory:(BOOL)save;
- (void)pushCurrentBookmarkPoint;

- (void)incrementPage;
- (void)decrementPage;

- (BlioBookmarkPoint *)bookmarkPointForPercentage:(float)percentage;
- (float)percentageForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;

- (NSString *)displayPageNumberForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;
- (NSString *)pageLabelForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;

- (BOOL)currentPageContainsBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;
// The returned range, for historical reasons, might be inclusive /or/
// exclusive of its endpoint.  Whether a specific point within it is actually 
// on the page may be verified by calling the above 
// -currentPageContainsBookmarkPoint:
- (BlioBookmarkRange *)bookmarkRangeForCurrentPage;

@property (nonatomic, readonly) id<EucBookContentsTableViewControllerDataSource> contentsDataSource;
@property (nonatomic, readonly) id currentContentsSectionIdentifier;
- (void)goToContentsSectionIdentifier:(id)identifier animated:(BOOL)animated;


@property (nonatomic, readonly) CGRect firstPageRect;

@optional
@property (nonatomic, assign) NSUInteger fontSizeIndex;
@property (nonatomic, assign) BlioJustification justification;
@property (nonatomic, retain) NSString *fontName;

@property (nonatomic, readonly) UIImage *dimPageImage;

- (void)setPageTexture:(UIImage *)pageTexture isDark:(BOOL)isDark;

@property (nonatomic, assign) BlioTwoUp twoUp;
@property (nonatomic, assign) BOOL shouldTapZoom;
@property (nonatomic, assign) BlioExtraBoldness extraBoldness;

- (NSString *)displayPageNumberForPageAtIndex:(NSUInteger)pageIndex;
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

- (void)toolbarsWillShow;
- (void)toolbarsWillHide;

- (UIImage*)previewThumbnailForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint;

- (void)refreshHighlights;

@end