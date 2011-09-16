//
//  BlioLayoutView.m
//  BlioApp
//
//  Created by matt on 18/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "BlioLayoutView.h"
#import "BlioBook.h"
#import "BlioBookManager.h"
#import "BlioBookmark.h"
#import "BlioWebToolsViewController.h"
#import <libEucalyptus/EucMenuItem.h>
#import <libEucalyptus/EucSelectorRange.h>
#import <libEucalyptus/THPositionedCGContext.h>
#import <libEucalyptus/THPair.h>
#import <libEucalyptus/THUIDeviceAdditions.h>
#import <libEucalyptus/THGeometryUtils.h>
#import "UIDevice+BlioAdditions.h"
#import "BlioTextFlowBlockCombiner.h"
#import "BlioLayoutPDFDataSource.h"
#import "BlioLayoutGeometry.h"
#import "BlioLayoutHyperlink.h"
#import "BlioAppSettingsConstants.h"
#import "BlioMediaView.h"
#import "BlioBlendView.h"
#import "BlioGestureSuppressingView.h"
#import "BlioXPSProtocol.h"
#import "BlioXPSProvider.h"
#import "KNFBTOCEntry.h"

#define PAGEHEIGHTRATIO_FOR_BLOCKCOMBINERVERTICALSPACING (1/30.0f)
#define BLIOLAYOUT_LHSHOTZONE 0.25f
#define BLIOLAYOUT_RHSHOTZONE 0.75f

@interface BlioLayoutView()

@property (nonatomic, retain) BlioGestureSuppressingView *overlay;
@property (nonatomic, retain) BlioBookmarkPoint *currentBookmarkPoint;
@property (nonatomic, assign) NSInteger pageCount;
@property (nonatomic, assign) NSInteger pageNumber;
@property (nonatomic, assign) CGSize pageSize;
@property (nonatomic, retain) id<BlioLayoutDataSource> dataSource;
@property (nonatomic, retain) BlioTextFlowBlock *lastBlock;
@property (nonatomic, retain) BlioBookmarkRange *temporaryHighlightRange;
@property (nonatomic, retain) NSArray *accessibilityElements;
@property (nonatomic, retain) UIAccessibilityElement *prevZone;
@property (nonatomic, retain) UIAccessibilityElement *nextZone;
@property (nonatomic, retain) UIAccessibilityElement *pageZone;
@property (nonatomic, assign) BOOL performingAccessibilityZoom;
@property (nonatomic, retain) NSMutableArray *accessibiltyLinesCache;
@property (nonatomic, retain) NSMutableArray *mediaViews;
@property (nonatomic, retain) NSMutableArray *webViews;
@property (nonatomic, readonly, retain) UIImage *pageAlphaMask;
@property (nonatomic, readonly, retain) UIColor *pageMultiplyColor;

- (CGRect)cropForPage:(NSInteger)page;
- (CGRect)cropForPage:(NSInteger)page allowEstimate:(BOOL)estimate;

- (CGAffineTransform)pageTurningViewTransformForPageAtIndex:(NSInteger)page;
- (CGAffineTransform)pageTurningViewTransformForPageAtIndex:(NSInteger)pageIndex offsetOrigin:(BOOL)offset applyZoom:(BOOL)zoom;

- (void)goToPageNumber:(NSInteger)pageNumber animated:(BOOL)animated;

- (NSString *)displayPageNumberForPageAtIndex:(NSUInteger)pageIndex;

- (NSArray *)bookmarkRangesForCurrentPage;
- (EucSelectorRange *)selectorRangeFromBookmarkRange:(BlioBookmarkRange *)range;
- (BlioBookmarkRange *)bookmarkRangeFromSelectorRange:(EucSelectorRange *)range;

- (BOOL)touchesShouldBeSuppressed;
- (void)registerGesturesForPageTurningView:(EucPageTurningView *)aPageTurningView;
- (void)handleDoubleTap:(UITapGestureRecognizer *)sender;
- (void)handleSingleTap:(UITapGestureRecognizer *)sender;

- (NSArray *)hyperlinksForPage:(NSInteger)page;
- (BlioLayoutHyperlink *)hyperlinkForPage:(NSInteger)page atPoint:(CGPoint)point;
- (void)hyperlinkTapped:(NSString *)link;

- (BlioBookmarkRange *)noteBookmarkForPage:(NSInteger)page atPoint:(CGPoint)point;

- (CGRect)visibleRectForPageAtIndex:(NSInteger)pageIndex;
- (void)zoomAtPoint:(CGPoint)point;
- (void)zoomToPreviousBlock;
- (void)zoomToNextBlock;
- (void)zoomToNextBlockReversed:(BOOL)reversed;
- (void)zoomToBlock:(BlioTextFlowBlock *)targetBlock visibleRect:(CGRect)visibleRect reversed:(BOOL)reversed context:(void *)context;
- (void)zoomToBlock:(BlioTextFlowBlock *)targetBlock visibleRect:(CGRect)visibleRect reversed:(BOOL)reversed context:(void *)context center:(CGPoint)centerPoint;
- (void)zoomOut;
- (void)zoomOutAtPoint:(CGPoint)point;
- (void)zoomOutAtPoint:(CGPoint)point animated:(BOOL)animated;
- (void)advanceOrZoomOutAtPoint:(CGPoint)point;
- (void)zoomOutsideBlockAtPoint:(CGPoint)point zoomFactor:(CGFloat)zoomFactor;
- (void)zoomForNewPageAnimated:(BOOL)animated;
- (void)zoomForNewPageAnimatedWithNumberThunk:(NSNumber *)animated;
- (void)zoomToFitAllBlocksOnPageTurningViewAtPoint:(CGPoint)point;
- (void)zoomToFitAllBlocksOnPageTurningViewAtPoint:(CGPoint)point translation:(CGPoint *)translationPtr zoomFactor:(CGFloat *)zoomFactorPtr;
- (void)updateOverlay;
- (void)clearOverlayCaches;
- (void)updateOverlayForPagesInRange:(NSRange)pageRange;
- (void)hideOverlay;
- (void)showOverlay;
- (void)freezeOverlayContents;
- (NSArray *)overlayPositionedContextsForPageAtIndex:(NSUInteger)index;
- (void)updatePositionedOverlayContexts;

- (void)accessibilityEnsureZoomedOut;

@end

@implementation BlioLayoutView

@dynamic delegate; // Provided by BlioSelectableBookView superclass.

@synthesize bookID, textFlow, pageNumber, pageCount, currentBookmarkPoint, selector, pageSize;
@synthesize pageCropsCache, viewTransformsCache, hyperlinksCache;
@synthesize dataSource;
@synthesize pageTurningView;
@synthesize lastBlock;
@synthesize accessibilityElements, prevZone, nextZone, pageZone;
@synthesize temporaryHighlightRange;
@synthesize performingAccessibilityZoom;
@synthesize accessibiltyLinesCache;
@synthesize overlay;
@synthesize mediaViews;
@synthesize webViews;
@synthesize pageAlphaMask;
@synthesize pageMultiplyColor;
@synthesize twoUpLandscape;

- (void)dealloc {
	
    self.currentBookmarkPoint = nil;
    
    [self.webViews makeObjectsPerformSelector:@selector(stopLoading)];
    [self.webViews makeObjectsPerformSelector:@selector(setDelegate:) withObject:nil];
    [self.mediaViews makeObjectsPerformSelector:@selector(stopMediaPlayer)];
    
	self.mediaViews = nil;
	self.webViews = nil;
    [pageAlphaMask release], pageAlphaMask = nil;
	[pageMultiplyColor release], pageMultiplyColor = nil;
    [overlay release], overlay = nil;
    
    self.pageCropsCache = nil;
    self.hyperlinksCache = nil;
    self.viewTransformsCache = nil;
    self.lastBlock = nil;
	self.temporaryHighlightRange = nil;
    
    self.pageTurningView = nil;
        
    [self.dataSource closeDocumentIfRequired];
    self.dataSource = nil;
    
    if(textFlow) {
        [[BlioBookManager sharedBookManager] checkInTextFlowForBookWithID:textFlow.bookID];
        [textFlow release];
    }
    
    if(xpsProvider) {
        [[BlioBookManager sharedBookManager] checkInXPSProviderForBookWithID:xpsProvider.bookID];
        [xpsProvider release];
    }
        
    BlioBook *aBook = [[BlioBookManager sharedBookManager] bookWithID:self.bookID];
    [aBook flushCaches];
    
    self.bookID = nil;
    [layoutCacheLock release];
    [hyperlinksCacheLock release];
	
	self.accessibilityElements = nil;
	self.prevZone = nil;
	self.nextZone = nil;
	self.pageZone = nil;
        
    [super dealloc];
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    NSLog(@"Did receive memory warning in Layout View");
}

#pragma mark -
#pragma mark BlioBookView

- (id)initWithFrame:(CGRect)frame bookID:(NSManagedObjectID *)aBookID animated:(BOOL)animated {
    
    BlioBookManager *bookManager = [BlioBookManager sharedBookManager];
    
    BlioBook *aBook = [bookManager bookWithID:aBookID];
    if (!([aBook hasPdf] || [aBook hasXps])) {
        [self release];
        return nil;
    }
    
    if((self = [super initWithFrame:frame])) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;        
        self.opaque = YES;
        self.multipleTouchEnabled = YES;
        self.bookID = aBookID;
        
        layoutCacheLock = [[NSLock alloc] init];
        hyperlinksCacheLock = [[NSLock alloc] init];
        
        // Prefer the checkout over calling [aBook textFlow] because we wat to retain the result
        textFlow = [[[BlioBookManager sharedBookManager] checkOutTextFlowForBookWithID:self.bookID] retain];
        
        if ([aBook hasXps]) {
            // Prefer the checkout over calling [aBook xpsProvider] because we wat to retain the result
            xpsProvider = [[[BlioBookManager sharedBookManager] checkOutXPSProviderForBookWithID:self.bookID] retain];
            self.dataSource = xpsProvider;
        } else if ([aBook hasPdf]) {
            BlioLayoutPDFDataSource *aPDFDataSource = [[BlioLayoutPDFDataSource alloc] initWithPath:[aBook pdfPath]];
            self.dataSource = aPDFDataSource;
            [aPDFDataSource release];
        }
        
        pageCount = [self.dataSource pageCount];
        // Cache the first page crop to allow fast estimating of crops
        firstPageCrop = [self.dataSource cropRectForPage:1];

        
		if (animated) {
			self.pageNumber = 1;
		} else {
            self.currentBookmarkPoint = aBook.implicitBookmarkPoint;
			NSInteger page = MAX(MIN(aBook.implicitBookmarkPoint.layoutPage, self.pageCount), 1);
			self.pageNumber = page;
		}
    }

    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if(self.selector) {
        [self.selector removeObserver:self forKeyPath:@"tracking"];
        [self.selector detatch];
        self.selector = nil;
    }
    
    if(newSuperview && !self.pageTurningView) {
        EucIndexBasedPageTurningView *aPageTurningView = [[EucIndexBasedPageTurningView alloc] initWithFrame:self.bounds];
        aPageTurningView.delegate = self;
        aPageTurningView.indexBasedDataSource = self;
        aPageTurningView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        aPageTurningView.zoomHandlingKind = EucPageTurningViewZoomHandlingKindZoom;
		aPageTurningView.vibratesOnInvalidTurn = NO;
        
        BOOL hasEnhancedContent = NO;
        if ([(NSObject *)self.dataSource respondsToSelector:@selector(hasEnhancedContent)]) {
            hasEnhancedContent = [self.dataSource hasEnhancedContent];
        }
        
        if (hasEnhancedContent) {
            aPageTurningView.lightIsStaticWhenPagesPannedOrZoomed = NO;
        }
        
        // Must do this here so that teh page aspect ration takes account of the twoUp property
        CGRect myBounds = self.bounds;
        if(myBounds.size.width > myBounds.size.height && self.twoUpLandscape) {
            aPageTurningView.twoUp = YES;
        } else {
            aPageTurningView.twoUp = NO;
        } 
        
        if (CGRectEqualToRect(firstPageCrop, CGRectZero)) {
            [aPageTurningView setPageAspectRatio:0];
        } else {
            [aPageTurningView setPageAspectRatio:firstPageCrop.size.width/firstPageCrop.size.height];
        }
         
        [self registerGesturesForPageTurningView:aPageTurningView];
        [self addSubview:aPageTurningView];
        self.pageTurningView = aPageTurningView;

        [aPageTurningView release];

        [aPageTurningView turnToPageAtIndex:self.pageNumber - 1 animated:NO];
		[aPageTurningView waitForAllPageImagesToBeAvailable];        
    }
}

- (void)didMoveToSuperview
{
    if(self.superview) {
		if (self.textFlow) {
			EucSelector *aSelector = [[EucSelector alloc] init];
			aSelector.shouldTrackSingleTapsOnHighights = NO;
			aSelector.dataSource = self;
			aSelector.delegate =  self;
			[aSelector attachToView:self];
			[aSelector addObserver:self forKeyPath:@"tracking" options:0 context:NULL];
			self.selector = aSelector;
			[aSelector release]; 
		}
    } else {
        EucIndexBasedPageTurningView *aPageTurningView = self.pageTurningView;
        if(aPageTurningView) {
            aPageTurningView.dataSource = nil;
            aPageTurningView.delegate = nil;
            [aPageTurningView removeFromSuperview];
            self.pageTurningView = nil;
        }
    }
}

- (void)layoutSubviews {
    CGRect myBounds = self.bounds;
    if(self.twoUpLandscape && 
       myBounds.size.width > myBounds.size.height) {
        self.pageTurningView.twoUp = YES;        
        // The first page is page 0 as far as the page turning view is concerned,
        // so it's an even page, so if it's mean to to be on the left, the odd 
        // pages should be on the right.
        
        // Disabled for now because many books seem to have the property set even
        // though their first page is the cover, and the odd pages are 
        // clearly meant to be on the left (e.g. they have page numbers on the 
        // outside).
        //self.pageTurningView.oddPagesOnRight = [[[BlioBookManager sharedBookManager] bookWithID:self.bookID] firstLayoutPageOnLeft];
    } else {
        self.pageTurningView.twoUp = NO;
    }   
    [super layoutSubviews];
    CGSize newSize = self.bounds.size;
    if(!CGSizeEqualToSize(newSize, self.pageSize)) {
        if(self.selector.tracking) {
            [self.selector setSelectedRange:nil];
        }
        
		BOOL firstLayout = NO;
		if (CGSizeEqualToSize(self.pageSize, CGSizeZero)) {
			firstLayout = YES;
		}
		self.pageSize = newSize;
        // Perform this after a delay in order to give time for layoutSubviews 
        // to be called on the pageTurningView before we start the zoom
        // (Ick!).
        [self performSelector:@selector(zoomForNewPageAnimatedWithNumberThunk:) withObject:[NSNumber numberWithBool:NO] afterDelay:0.0f];
		if (firstLayout) {
			[self performSelector:@selector(updateOverlay) withObject:nil afterDelay:0.0f];
		}
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if(self.selector) {
        [self.selector removeObserver:self forKeyPath:@"tracking"];
        [self.selector detatch];
        self.selector = nil;
    }
	self.temporaryHighlightRange = nil;
	[self hideOverlay];
	[self clearOverlayCaches];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	self.lastBlock = nil;
	self.accessibilityElements = nil;
	if (self.textFlow) {
		EucSelector *aSelector = [[EucSelector alloc] init];
		aSelector.dataSource = self;
		aSelector.delegate =  self;
		[aSelector attachToView:self];
		[aSelector addObserver:self forKeyPath:@"tracking" options:0 context:NULL];
		self.selector = aSelector;
		[aSelector release];
	}
	[self updateOverlay];
	[self showOverlay];
}

- (UIImage *)dimPageImage
{
    UIImage *ret = nil;
    EucPageTurningView *myPageTurningView = self.pageTurningView;
    [myPageTurningView abortAllAnimation];
    myPageTurningView.dimQuotient = 1.0f;
    ret = myPageTurningView.screenshot;
    myPageTurningView.dimQuotient = 0.0f;
    return ret;
}

- (void)toolbarsWillShow {
    self.pageTurningView.suppressAccessibilityScreenChangedNotificationOnPageTurn = YES;
}

- (void)toolbarsWillHide
{
    self.pageTurningView.suppressAccessibilityScreenChangedNotificationOnPageTurn = NO;
}

#pragma mark -
#pragma mark EucIndexBasedPageTurningViewDataSource

- (CGRect)pageTurningView:(EucIndexBasedPageTurningView *)aPageTurningView contentRectForPageAtIndex:(NSUInteger)index {
    return [self cropForPage:index + 1];
}

- (THPositionedCGContext *)pageTurningView:(EucIndexBasedPageTurningView *)aPageTurningView 
           RGBABitmapContextForPageAtIndex:(NSUInteger)index
                                  fromRect:(CGRect)rect 
                                    atSize:(CGSize)size {
    id backing = nil;
    CGContextRef CGContext = [self.dataSource RGBABitmapContextForPage:index + 1
                                                              fromRect:rect 
                                                                atSize:size
                                                            getBacking:&backing];
    return [[[THPositionedCGContext alloc] initWithCGContext:CGContext backing:backing] autorelease];
}

- (UIImage *)pageTurningView:(EucIndexBasedPageTurningView *)aPageTurningView 
   fastThumbnailUIImageForPageAtIndex:(NSUInteger)index {
    return [self.dataSource thumbnailForPage:index + 1];
}

- (UIImage*)previewThumbnailForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint {
	 return [self.dataSource thumbnailForPage:bookmarkPoint.layoutPage];
}

- (NSString *)pageTurningView:(EucIndexBasedPageTurningView *)aPageTurningView accessibilityPageDescriptionForPagesAtIndexes:(NSArray *)pageIndexes
{
    /*NSString *description = nil;
    if(pageIndexes.count == 2) {
        description = [NSString stringWithFormat:NSLocalizedString(@"Pages %ld and %ld of %ld",@"Accessibility announcement for after a page turn in layut view - landscape with two pages"), 
                       (long)([[pageIndexes objectAtIndex:0] unsignedIntegerValue] + 1),
                       (long)([[pageIndexes objectAtIndex:1] unsignedIntegerValue] + 1),
                       (long)[self pageCount] - 1];
    } else {
        NSUInteger pageIndex = [[pageIndexes objectAtIndex:0] unsignedIntegerValue];
        if(pageIndex) {
            description = [NSString stringWithFormat:NSLocalizedString(@"Page %ld of %ld",@"Accessibility announcement for after a page turn in layut view."), 
                           (long)(pageIndex + 1),
                           (long)[self pageCount] - 1];
        } else {
            description = NSLocalizedString(@"Cover Page",@"Accessibility announcement for after a page turn in layut view - cover page");            
        }
    }*/
    NSMutableString *description = [NSMutableString string];
    
    for(NSNumber *pageIndex in pageIndexes) {
        NSArray *nonFolioPageBlocks = [self.textFlow blocksForPageAtIndex:[pageIndex unsignedIntegerValue] includingFolioBlocks:NO];
        for (BlioTextFlowBlock *block in nonFolioPageBlocks) {
            [description appendString:[block string]];
            [description appendString:@"\n"];
        }
    }
    
    if(!description.length) {
        if(pageIndexes.count == 2) {
            return NSLocalizedString(@"No text on these pages.", @"Accessibility description for otherwise empty two pages (i.e. in landscape) in layout view.");
        } else {
            return NSLocalizedString(@"No text on this page.", @"Accessibility description for otherwise empty page in layout view.");
        }
    }
    
    return description;
}

- (NSUInteger)pageTurningViewPageCount:(EucIndexBasedPageTurningView *)pageTurningView
{
    return self.pageCount;
}

#pragma mark -
#pragma mark Visual Properties

- (void)setPageNumber:(NSInteger)newPageNumber {
	pageNumber = newPageNumber;
	self.selector.selectedRange = nil;
	self.accessibilityElements = nil;
    
	[self updateOverlay];
}

- (void)setPageTexture:(UIImage *)aPageTexture isDark:(BOOL)isDarkIn { 
    [self.pageTurningView setPageTexture:aPageTexture isDark:isDarkIn];
    [self.pageTurningView setNeedsDraw];
    [self clearOverlayCaches];
    [self updateOverlay];
}

- (BOOL)wantsTouchesSniffed {
    return NO;
}

- (void)goToPageNumber:(NSInteger)targetPage animated:(BOOL)animated {
	BlioBookmarkPoint *bookmarkPoint = [[[BlioBookmarkPoint alloc] init] autorelease];
    bookmarkPoint.layoutPage = targetPage;
    [self goToBookmarkPoint:bookmarkPoint animated:animated];
}

- (KNFBTOCEntry *)tocEntryForUuid:(NSString *)uuid
{
    KNFBTOCEntry *tocEntry = nil;
    if ([self.dataSource isKindOfClass:[BlioLayoutPDFDataSource class]]) {
        tocEntry = [(BlioLayoutPDFDataSource *)self.dataSource tocEntryForSectionUuid:uuid];
    } else {
        tocEntry = [self.textFlow tocEntryForSectionUuid:uuid];
    }
    return tocEntry;
}

- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated {
    [self goToPageNumber:[self tocEntryForUuid:uuid].startPage + 1 animated:animated];
}

- (NSString *)currentUuid
{
    BlioBookmarkPoint *bookmarkPoint = self.currentBookmarkPoint;
    NSString *uuid;
    if ([self.dataSource isKindOfClass:[BlioLayoutPDFDataSource class]]) {
		uuid = [(BlioLayoutPDFDataSource *)self.dataSource sectionUuidForPageIndex:bookmarkPoint.layoutPage - 1];
	} else {
		uuid = [self.textFlow sectionUuidForPageIndex:bookmarkPoint.layoutPage - 1];;
	}
    return uuid;
}

- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated {
    [self goToBookmarkPoint:bookmarkPoint animated:animated saveToHistory:YES];
}

- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated saveToHistory:(BOOL)save {
	suppressHistoryAfterTurn = NO;
	
	NSInteger targetPage = bookmarkPoint.layoutPage;
	
	if ((targetPage <= self.pageCount) && (targetPage >=1)) {
		
		if (save && !animated) {
			[self pushCurrentBookmarkPoint];
		} else {
			if (!save && animated) {
				suppressHistoryAfterTurn = YES;
			}
		}
	
		if (self.pageTurningView) {
			[self.pageTurningView turnToPageAtIndex:targetPage - 1 animated:animated];      
			if (!animated) {
				self.pageNumber = targetPage;
			}
		}
	}
    
    self.currentBookmarkPoint = bookmarkPoint;
}

- (BlioBookmarkPoint *)bookmarkPointForPercentage:(float)percentage
{
    BlioBookmarkPoint *bookmarkPoint = [[[BlioBookmarkPoint alloc] init] autorelease];
    NSInteger pageIndex = roundf((self.pageCount - 1) * percentage);
    bookmarkPoint.layoutPage = pageIndex + 1;
    return bookmarkPoint;
}

- (float)percentageForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    float percentage = (float)(bookmarkPoint.layoutPage - 1) / (float)(self.pageCount - 1);
    return MIN(percentage, 1.0f);
}

- (NSString *)displayPageNumberForPageAtIndex:(NSUInteger)pageIndex
{
    NSString *displayPageNumber = nil;    
    
    if ([self.dataSource respondsToSelector:@selector(displayPageNumberForPage:)]) {
        displayPageNumber = [self.dataSource displayPageNumberForPage:pageIndex + 1];
    }
    
    return displayPageNumber;
    
}

- (NSString *)displayPageNumberForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    NSUInteger pageIndex = bookmarkPoint.layoutPage;
    if(pageIndex > 0) {
        pageIndex -= 1;
    }
    
    NSString *pageStr = [self displayPageNumberForPageAtIndex:pageIndex];
    
    if (![pageStr length]) {
        pageStr = [self.contentsDataSource contentsTableViewController:nil displayPageNumberForPageIndex:pageIndex];
    }
    
    return pageStr;
}

- (NSString *)pageLabelForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{        
    NSUInteger pageIndex = bookmarkPoint.layoutPage;
    if(pageIndex > 0) {
        pageIndex -= 1;
    }
    
    NSString *pageStr = [self displayPageNumberForPageAtIndex:pageIndex];
        
    NSString *uuid;
    if ([self.dataSource isKindOfClass:[BlioLayoutPDFDataSource class]]) {
		uuid = [(BlioLayoutPDFDataSource *)self.dataSource sectionUuidForPageIndex:pageIndex];
	} else {
		uuid = [self.textFlow sectionUuidForPageIndex:pageIndex];
	}
    NSString *chapterName = [self.contentsDataSource contentsTableViewController:nil presentationNameAndSubTitleForSectionUuid:uuid].first;
    
    NSString *pageLabel = nil;

    if (chapterName) {
        if ([pageStr length]) {
            pageLabel = [NSString stringWithFormat:NSLocalizedString(@"Page %@ \u2013 %@",@"Page label with page number and chapter (layout view)"), pageStr, chapterName];
        } else {
            pageLabel = [NSString stringWithFormat:@"%@", chapterName];
        }
    } else {
        if (pageStr) {
            pageLabel = [NSString stringWithFormat:NSLocalizedString(@"Page %@ of %lu",@"Page label X of Y (page number of page count) (layout view)"), pageStr, (unsigned long)self.pageCount];
        } else {
            pageLabel = [[BlioBookManager sharedBookManager] bookWithID:self.bookID].title;
        }
    }     
    
    return pageLabel;
}

- (BOOL)currentPageContainsBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint
{
    NSInteger pageIndex = bookmarkPoint.layoutPage - 1;
    return pageIndex == self.pageTurningView.rightPageIndex || pageIndex == self.pageTurningView.leftPageIndex;
}

#pragma mark -
#pragma mark Back Button History

- (void)pushCurrentBookmarkPoint {
    BlioBookmarkPoint *bookmarkPoint = [self currentBookmarkPoint];
    if (bookmarkPoint) {
        [self.delegate pushBookmarkPoint:bookmarkPoint];
    }
}

#pragma mark -
#pragma mark BlioLayoutRenderingDelegate

- (BOOL)dataSourceContainsPage:(NSInteger)page {
    if (page >= 1 && page <= [self pageCount])
        return YES;
    else
        return NO;
}

- (void)createLayoutCacheForPage:(NSInteger)page {
    // N.B. please ensure this is only called with a [layoutCacheLock lock] acquired
    
    
    if (nil == self.pageCropsCache) {
        self.pageCropsCache = [NSMutableDictionary dictionaryWithCapacity:pageCount];
    }
    if (nil == self.viewTransformsCache) {
        self.viewTransformsCache = [NSMutableDictionary dictionaryWithCapacity:pageCount];
    }
    
    // Grab the next 50 pages in one go to stop this interfering with the main thread on each turn
    int j = page + 50;
    for (int i = page; i < j; i++) {
        if (i <= [self pageCount]) {
            NSValue *pageCropValue = [self.pageCropsCache objectForKey:[NSNumber numberWithInt:i]];
            if (nil == pageCropValue) {
                CGRect cropRect = [self.dataSource cropRectForPage:i];
                if (!CGRectEqualToRect(cropRect, CGRectZero)) {
                    [self.pageCropsCache setObject:[NSValue valueWithCGRect:cropRect] forKey:[NSNumber numberWithInt:i]];
                }
            }
        }
    }
}

- (CGRect)cropForPage:(NSInteger)page {
    return [self cropForPage:page allowEstimate:NO];
}

- (CGRect)cropForPage:(NSInteger)page allowEstimate:(BOOL)estimate {
        
    if (estimate) {
        return firstPageCrop;
    }
    
    [layoutCacheLock lock];
    
    NSValue *pageCropValue = [self.pageCropsCache objectForKey:[NSNumber numberWithInt:page]];
    
    if (nil == pageCropValue) {
        [self createLayoutCacheForPage:page];
        pageCropValue = [self.pageCropsCache objectForKey:[NSNumber numberWithInt:page]];
    }
    
    [layoutCacheLock unlock];
    
    if (pageCropValue) {
        CGRect cropRect = [pageCropValue CGRectValue];
        return cropRect;
    }
    
    return CGRectZero;
}

CGAffineTransform transformRectToFitRect(CGRect sourceRect, CGRect targetRect, BOOL preserveAspect) {
    
    CGFloat xScale = targetRect.size.width / sourceRect.size.width;
    CGFloat yScale = targetRect.size.height / sourceRect.size.height;
    
    CGAffineTransform scaleTransform;
    if (preserveAspect) {
        CGFloat scale = xScale < yScale ? xScale : yScale;
        scaleTransform = CGAffineTransformMakeScale(scale, scale);
    } else {
        scaleTransform = CGAffineTransformMakeScale(xScale, yScale);
    } 
    CGRect scaledRect = CGRectApplyAffineTransform(sourceRect, scaleTransform);
    CGFloat xOffset = (targetRect.size.width - scaledRect.size.width);
    CGFloat yOffset = (targetRect.size.height - scaledRect.size.height);
    CGAffineTransform offsetTransform = CGAffineTransformMakeTranslation((targetRect.origin.x - scaledRect.origin.x) + xOffset/2.0f, (targetRect.origin.y - scaledRect.origin.y) + yOffset/2.0f);
    CGAffineTransform transform = CGAffineTransformConcat(scaleTransform, offsetTransform);
    return transform;
}

- (CGAffineTransform)pageTurningViewTransformForPageAtIndex:(NSInteger)pageIndex offsetOrigin:(BOOL)offset applyZoom:(BOOL)applyZoom {
    // TODO: Make sure this is cached in LayoutView or pageTurningView
    CGRect pageCrop = [self pageTurningView:self.pageTurningView contentRectForPageAtIndex:pageIndex];
    CGRect pageFrame;
    
	BOOL isOnRight = YES;
	if (self.pageTurningView.isTwoUp) {
		BOOL rightIsEven = YES;
		BOOL indexIsEven = (pageIndex % 2 == 0);
		if (rightIsEven != indexIsEven) {
			isOnRight = NO;
		}
	}
	
	if (isOnRight) {
		if (applyZoom) {
			pageFrame = [self.pageTurningView rightPageFrame];
		} else {
			pageFrame = [self.pageTurningView unzoomedRightPageFrame];
		}
	} else {
		if (applyZoom) {
			pageFrame = [self.pageTurningView leftPageFrame];
		} else {
			pageFrame = [self.pageTurningView unzoomedLeftPageFrame];
		}
    }
    
    if (!offset) {
        pageFrame.origin = CGPointZero;
    }

    CGAffineTransform pageTransform = transformRectToFitRect(pageCrop, pageFrame, false);
        
    return pageTransform;
}

- (CGAffineTransform)pageTurningViewTransformForPageAtIndex:(NSInteger)pageIndex {
    return [self pageTurningViewTransformForPageAtIndex:pageIndex offsetOrigin:YES applyZoom:YES];
}

#pragma mark -
#pragma mark EucPageTurningView Delegate Methods

- (void)pageTurningViewWillBeginPageTurn:(EucPageTurningView *)aPageTurningView
{
	[self freezeOverlayContents];
    [self updatePositionedOverlayContexts];
	[self hideOverlay];
}

- (void)pageTurningViewDidEndPageTurn:(EucPageTurningView *)aPageTurningView
{
	[self showOverlay];
}

- (void)pageTurningView:(EucPageTurningView *)aPageTurningViewIn didTurnToPageWithIdentifier:(id)identifier
{
    EucIndexBasedPageTurningView *aPageTurningView = (EucIndexBasedPageTurningView *)aPageTurningViewIn;

    NSUInteger pageIndex = [identifier unsignedIntegerValue];
    if(self.pageNumber != pageIndex + 1) {
		if (!suppressHistoryAfterTurn) {
			[self pushCurrentBookmarkPoint];
		}
        self.pageNumber = pageIndex + 1;
    }
    
    NSUInteger leftPageIndex = aPageTurningView.leftPageIndex;
    NSUInteger rightPageIndex = aPageTurningView.rightPageIndex;
    NSInteger currentPageNumber = self.currentBookmarkPoint.layoutPage;
    
    if(!currentPageNumber ||
       (currentPageNumber - 1 != leftPageIndex && currentPageNumber - 1 != rightPageIndex)) {
        NSInteger newPageNumber = 0;
        if(leftPageIndex != NSUIntegerMax) {
            newPageNumber = leftPageIndex + 1;
        } else if(rightPageIndex != NSUIntegerMax) {
            newPageNumber = rightPageIndex + 1;
        }
        if(newPageNumber != 0) {
            
            BlioBookmarkPoint *newBookmarkPoint = [[BlioBookmarkPoint alloc] init];
            newBookmarkPoint.layoutPage = newPageNumber;
            
            self.currentBookmarkPoint = newBookmarkPoint;
            
            [newBookmarkPoint release];
        }
    }
}

- (void)pageTurningViewWillBeginAnimating:(EucPageTurningView *)aPageTurningView
{
    self.selector.selectionDisabled = YES;
    [self.selector removeTemporaryHighlight];
    
    if(!self.performingAccessibilityZoom) {
        if(UIAccessibilityIsVoiceOverRunning == nil ||
           !UIAccessibilityIsVoiceOverRunning()) {
            [self.delegate cancelPendingToolbarShow];
            [self.delegate hideToolbars];
        }
    }
	pageViewIsTurning = YES;

}

- (void)pageTurningViewDidEndAnimating:(EucPageTurningView *)aPageTurningViewIn
{
    EucIndexBasedPageTurningView *aPageTurningView = (EucIndexBasedPageTurningView *)aPageTurningViewIn;

    self.selector.selectionDisabled = NO;
    pageViewIsTurning = NO;
	suppressHistoryAfterTurn = NO;
    	
    if(self.temporaryHighlightRange) {
		NSInteger targetIndex = self.temporaryHighlightRange.startPoint.layoutPage - 1;
		
        if((aPageTurningView.leftPageIndex == targetIndex) || (aPageTurningView.rightPageIndex == targetIndex)) {
            EucSelectorRange *range = [self selectorRangeFromBookmarkRange:self.temporaryHighlightRange];
			[self.selector temporarilyHighlightSelectorRange:range animated:YES];
        }
				
		self.temporaryHighlightRange = nil;
    }
    
    self.performingAccessibilityZoom = NO;    
}

- (void)pageTurningViewWillBeginZooming:(EucPageTurningView *)scrollView 
{
    // Would be nice to just hide the menu and redisplay the range after every 
    // zoom step, but it's far too slow, so we just disable selection while 
    // zooming is going on.
    //[self.selector setShouldHideMenu:YES];
    [self.selector setSelectionDisabled:YES];
	[self.selector removeTemporaryHighlight];
	self.temporaryHighlightRange = nil;
	
}

- (void)pageTurningViewDidEndZooming:(EucPageTurningView *)scrollView 
{
    // See comment in pageTurningViewWillBeginZooming: about disabling selection
    // during zoom.
    // [self.selector setShouldHideMenu:NO];
    [self.selector setSelectionDisabled:NO];
}

- (BOOL)pageTurningView:(EucPageTurningView *)pageTurningView pageEdgeIsRigidForPageWithIdentifier:(id)identifier
{
    NSUInteger pageIndex = [identifier unsignedIntegerValue];
    return pageIndex <= 1;
}

#pragma mark -
#pragma mark Selector

- (UIImage *)viewSnapshotImageForEucSelector:(EucSelector *)selector {
	[self freezeOverlayContents];
    [self updatePositionedOverlayContexts];
	return [self.pageTurningView screenshot];
}

- (NSArray *)blockIdentifiersForEucSelector:(EucSelector *)selector {
    NSMutableArray *pagesBlocks = [NSMutableArray array];
    
    if (self.pageTurningView.isTwoUp) {
        NSInteger leftPageIndex = [self.pageTurningView leftPageIndex];
        if (leftPageIndex >= 0) {
            [pagesBlocks addObjectsFromArray:[self.textFlow blocksForPageAtIndex:leftPageIndex includingFolioBlocks:NO]];
        }
    }
    
    NSInteger rightPageIndex = [self.pageTurningView rightPageIndex];
    if (rightPageIndex < pageCount) {
        [pagesBlocks addObjectsFromArray:[self.textFlow blocksForPageAtIndex:rightPageIndex includingFolioBlocks:NO]];
    }
    
    return [pagesBlocks valueForKey:@"blockID"];
}

- (CGRect)eucSelector:(EucSelector *)selector frameOfBlockWithIdentifier:(id)blockID {
    NSInteger pageIndex = [BlioTextFlowBlock pageIndexForBlockID:blockID];
    
    BlioTextFlowBlock *block = nil;
    // We say "YES" to includingFolioBlocks here because we know that we're not going
    // to be asked about a folio block anyway, and getting all the blocks is more
    // efficient than getting just the non-folio blocks. 
    for (BlioTextFlowBlock *candidateBlock in [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:YES]) {
        if (candidateBlock.blockID == blockID) {
            block = candidateBlock;
            break;
        }
    }
    
    CGAffineTransform viewTransform = [self pageTurningViewTransformForPageAtIndex:pageIndex];
    return block ? CGRectApplyAffineTransform([block rect], viewTransform) : CGRectZero;
}

- (NSArray *)eucSelector:(EucSelector *)selector identifiersForElementsOfBlockWithIdentifier:(id)blockID {
    NSInteger pageIndex = [BlioTextFlowBlock pageIndexForBlockID:blockID];
    
    BlioTextFlowBlock *block = nil;
    for (BlioTextFlowBlock *candidateBlock in [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:YES]) {
        if (candidateBlock.blockID == blockID) {
            block = candidateBlock;
            break;
        }
    }

    if (block) {
        NSArray *words = [block words];
        if (words.count) {
            return [words valueForKey:@"wordID"];
	    }
    }
    return [NSArray array];
}

- (NSArray *)eucSelector:(EucSelector *)selector rectsForElementWithIdentifier:(id)wordID ofBlockWithIdentifier:(id)blockID { 
    NSInteger pageIndex = [BlioTextFlowBlock pageIndexForBlockID:blockID];
    
    BlioTextFlowBlock *block = nil;
    for (BlioTextFlowBlock *candidateBlock in [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:YES]) {
        if (candidateBlock.blockID == blockID) {
            block = candidateBlock;
            break;
        }
    }
    
    if (block) {
        BlioTextFlowPositionedWord *word = nil;
        for (BlioTextFlowPositionedWord *candidateWord in [block words]) {
            if([[candidateWord wordID] isEqual:wordID]) {
                word = candidateWord;
                break;
            }
        }        
        if (word) {
            CGAffineTransform viewTransform = [self pageTurningViewTransformForPageAtIndex:pageIndex];
            CGRect wordRect = [[[block words] objectAtIndex:[wordID integerValue]] rect];            
            return [NSArray arrayWithObject:[NSValue valueWithCGRect:CGRectApplyAffineTransform(wordRect, viewTransform)]];
        }
    } 
    return [NSArray array];
}

- (NSString *)eucSelector:(EucSelector *)selector accessibilityLabelForElementWithIdentifier:(id)wordID ofBlockWithIdentifier:(id)blockID {
    NSInteger pageIndex = [BlioTextFlowBlock pageIndexForBlockID:blockID];
    
    BlioTextFlowBlock *block = nil;
    for (BlioTextFlowBlock *candidateBlock in [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:YES]) {
        if (candidateBlock.blockID == blockID) {
            block = candidateBlock;
            break;
        }
    }
    
    if (block) {
        BlioTextFlowPositionedWord *word = nil;
        for (BlioTextFlowPositionedWord *candidateWord in [block words]) {
            if([[candidateWord wordID] isEqual:wordID]) {
                word = candidateWord;
                break;
            }
        }        
        if (word) {
            return word.string;
        }
    } 
    return nil;
}

- (NSArray *)bookmarkRangesForCurrentPage {
	NSUInteger startPageIndex = self.pageTurningView.leftPageIndex;
    NSUInteger endPageIndex = self.pageTurningView.rightPageIndex;
    if(startPageIndex == NSUIntegerMax) {
        startPageIndex = endPageIndex;
    } 
    if(endPageIndex == NSUIntegerMax) {
        endPageIndex = startPageIndex;
    }
    	
    BlioBookmarkPoint *startPoint = [[BlioBookmarkPoint alloc] init];
	startPoint.layoutPage = startPageIndex + 1;
    
    BlioBookmarkPoint *endPoint = [[BlioBookmarkPoint alloc] init];
    endPoint.layoutPage = endPageIndex + 1;
    
    NSArray *endPageBlocks = [self.textFlow blocksForPageAtIndex:endPageIndex includingFolioBlocks:NO];
    NSUInteger maxOffset = [endPageBlocks count] + 1;
    endPoint.blockOffset = maxOffset;

    BlioBookmarkRange *range = [[BlioBookmarkRange alloc] init];
    range.startPoint = startPoint;
    range.endPoint = endPoint;
    
    NSArray *highlightRanges = [self.delegate rangesToHighlightForRange:range];
    
    [startPoint release];
    [endPoint release];
    [range release];
    
    return [NSArray arrayWithArray:highlightRanges];
}

- (EucSelectorRange *)selectorRangeFromBookmarkRange:(BlioBookmarkRange *)range {
    if (nil == range) return nil;
    
    BlioBookmarkPoint *startPoint = range.startPoint;
    BlioBookmarkPoint *endPoint = range.endPoint;
    
    EucSelectorRange *selectorRange = [[EucSelectorRange alloc] init];
    selectorRange.startBlockId = [BlioTextFlowBlock blockIDForPageIndex:startPoint.layoutPage - 1 blockIndex:startPoint.blockOffset];
    selectorRange.startElementId = [BlioTextFlowPositionedWord wordIDForWordIndex:startPoint.wordOffset];
    selectorRange.endBlockId = [BlioTextFlowBlock blockIDForPageIndex:endPoint.layoutPage - 1 blockIndex:endPoint.blockOffset];
    selectorRange.endElementId = [BlioTextFlowPositionedWord wordIDForWordIndex:endPoint.wordOffset];
    
    return [selectorRange autorelease];
}

- (NSArray *)highlightRangesForEucSelector:(EucSelector *)aSelector {
    NSMutableArray *selectorRanges = [NSMutableArray array];
    
    for (BlioBookmarkRange *highlightRange in [self bookmarkRangesForCurrentPage]) {
        EucSelectorRange *range = [self selectorRangeFromBookmarkRange:highlightRange];
        [selectorRanges addObject:range];
    }
    
    return [NSArray arrayWithArray:selectorRanges];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(object == self.selector &&
       [keyPath isEqualToString:@"tracking"]) {
        BOOL tracking =  ((EucSelector *)object).isTracking;
        self.pageTurningView.userInteractionEnabled = !tracking;
        if(tracking) {
            [self.delegate hideToolbars];
        }
    }
}

- (void)setTwoUpLandscape:(BOOL)newTwoUpLandscape {
    twoUpLandscape = newTwoUpLandscape;
    
    BOOL wasTwoUp = self.pageTurningView.twoUp;
    BOOL shouldBeTwoUp = NO;
    CGRect myBounds = self.bounds;
    if(newTwoUpLandscape && 
       myBounds.size.width > myBounds.size.height) {
        shouldBeTwoUp = YES;        
    }
    if(shouldBeTwoUp != wasTwoUp) {
        self.pageTurningView.twoUp = shouldBeTwoUp;
        [self.pageTurningView layoutSubviews];
        [self zoomForNewPageAnimated:NO];
        [self hideOverlay];
        [self clearOverlayCaches];
        [self performSelector:@selector(updateOverlay) withObject:nil afterDelay:0.1f];
        [self performSelector:@selector(showOverlay) withObject:nil afterDelay:0.11f];
    }
}

- (UIColor *)eucSelector:(EucSelector *)selector willBeginEditingHighlightWithRange:(EucSelectorRange *)selectedRange
{    

    for (BlioBookmarkRange *highlightRange in [self bookmarkRangesForCurrentPage]) {
        EucSelectorRange *range = [self selectorRangeFromBookmarkRange:highlightRange];
        if ([selectedRange isEqual:range]) {
            NSInteger startIndex = highlightRange.startPoint.layoutPage - 1;
            NSInteger endIndex = highlightRange.endPoint.layoutPage - 1;
            
            for (int i = startIndex; i <= endIndex; i++) {
                [self.pageTurningView refreshHighlightsForPageAtIndex:i];
            }
            
			[self.pageTurningView drawView];
            return [highlightRange.color colorWithAlphaComponent:0.3f];
        }
    }
    
    return nil;
}

- (void)eucSelector:(EucSelector *)selector didEndEditingHighlightWithRange:(EucSelectorRange *)fromRange movedToRange:(EucSelectorRange *)toRange
{
	
	BlioBookmarkRange *fromBookmarkRange = [self bookmarkRangeFromSelectorRange:fromRange];
	BlioBookmarkRange *toBookmarkRange = [self bookmarkRangeFromSelectorRange:toRange ? : fromRange];
	
	if ((nil != toRange) && ![fromRange isEqual:toRange]) {
		
        if ([self.delegate respondsToSelector:@selector(updateHighlightAtRange:toRange:withColor:)])
            [self.delegate updateHighlightAtRange:fromBookmarkRange toRange:toBookmarkRange withColor:nil];
        
    }
	
	NSInteger startIndex = MIN(fromBookmarkRange.startPoint.layoutPage, toBookmarkRange.startPoint.layoutPage) - 1;
	NSInteger endIndex = MAX(fromBookmarkRange.endPoint.layoutPage, toBookmarkRange.endPoint.layoutPage) - 1;
	
	// Set this to nil now because the refresh depends on it
    [self.selector setSelectedRange:nil];
	
	for (int i = startIndex; i <= endIndex; i++) {
		[self.pageTurningView refreshHighlightsForPageAtIndex:i];
	}
	
	[self.pageTurningView drawView];
}

- (UIView *)viewForMenuForEucSelector:(EucSelector *)selector {
    return self;
}

- (BlioBookmarkRange *)bookmarkRangeFromSelectorRange:(EucSelectorRange *)range {
    
    if (nil == range) return nil;
    
    BlioBookmarkPoint *startPoint = [[BlioBookmarkPoint alloc] init];
    startPoint.layoutPage = [BlioTextFlowBlock pageIndexForBlockID:range.startBlockId] + 1;
    startPoint.blockOffset = [BlioTextFlowBlock blockIndexForBlockID:range.startBlockId];
    startPoint.wordOffset = [BlioTextFlowPositionedWord wordIndexForWordID:range.startElementId];
    
    BlioBookmarkPoint *endPoint = [[BlioBookmarkPoint alloc] init];
    endPoint.layoutPage = [BlioTextFlowBlock pageIndexForBlockID:range.endBlockId] + 1;
    endPoint.blockOffset = [BlioTextFlowBlock blockIndexForBlockID:range.endBlockId];
    endPoint.wordOffset = [BlioTextFlowPositionedWord wordIndexForWordID:range.endElementId];
    
    BlioBookmarkRange *bookmarkRange = [[BlioBookmarkRange alloc] init];
    bookmarkRange.startPoint = startPoint;
    bookmarkRange.endPoint = endPoint;
    
    [startPoint release];
    [endPoint release];
    
    return [bookmarkRange autorelease];
}

- (BlioBookmarkRange *)selectedRange {
    EucSelectorRange *highlighterRange = [self.selector selectedRange];
    
    BlioBookmarkPoint *startPoint = [[BlioBookmarkPoint alloc] init];
    BlioBookmarkPoint *endPoint = [[BlioBookmarkPoint alloc] init];;
    
    if (nil != highlighterRange) {        
        NSInteger startPageIndex = [BlioTextFlowBlock pageIndexForBlockID:[highlighterRange startBlockId]];
        NSInteger endPageIndex = [BlioTextFlowBlock pageIndexForBlockID:[highlighterRange endBlockId]];
        NSInteger startBlockOffset = [BlioTextFlowBlock blockIndexForBlockID:[highlighterRange startBlockId]];
        NSInteger endBlockOffset = [BlioTextFlowBlock blockIndexForBlockID:[highlighterRange endBlockId]];
        NSInteger startWordOffset = [BlioTextFlowPositionedWord wordIndexForWordID:[highlighterRange startElementId]];
        NSInteger endWordOffset = [BlioTextFlowPositionedWord wordIndexForWordID:[highlighterRange endElementId]];
        
        
        [startPoint setLayoutPage:startPageIndex + 1];
        [startPoint setBlockOffset:startBlockOffset];
        [startPoint setWordOffset:startWordOffset];
        
        [endPoint setLayoutPage:endPageIndex + 1];
        [endPoint setBlockOffset:endBlockOffset];
        [endPoint setWordOffset:endWordOffset];
    } else {
        [startPoint setLayoutPage:self.pageNumber];
        [endPoint setLayoutPage:self.pageNumber];
    }
    
    BlioBookmarkRange *range = [[BlioBookmarkRange alloc] init];
    [range setStartPoint:startPoint];
    [range setEndPoint:endPoint];
    
    [startPoint release];
    [endPoint release];
    
    return [range autorelease];
}

#pragma mark -
#pragma mark EnhancedContent

- (void)hideOverlay 
{
	[overlay setHidden:YES];
}

- (void)showOverlay
{
	[overlay setHidden:NO];
}

- (void)freezeOverlayContents
{
	for (BlioMediaView *mediaView in self.mediaViews) {
		[mediaView pauseMediaPlayer];
	}
}

- (NSArray *)overlayPositionedContextsForPageAtIndex:(NSUInteger)pageIndex {
	
	NSUInteger viewCount = [self.mediaViews count] + [self.webViews count];
	
	NSMutableArray *overlayViews = [NSMutableArray arrayWithCapacity:viewCount];
	NSMutableArray *positionedContexts = [NSMutableArray arrayWithCapacity:viewCount];
	
	[overlayViews addObjectsFromArray:self.mediaViews];
	[overlayViews addObjectsFromArray:self.webViews];
	
	CGFloat scale = 1;
		
	if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
		scale = [[UIScreen mainScreen] scale];
	}
				 
	for (UIView *view in overlayViews) {
		CGRect contentsFrame = view.layer.bounds;
        
		CGRect viewFrame = [view convertRect:contentsFrame toView:overlay];
        viewFrame.origin.x -= view.frame.origin.x;
        viewFrame.origin.y -= view.frame.origin.y;
        viewFrame.size.width += view.frame.origin.x;
        viewFrame.size.height += view.frame.origin.y;
		
		CGSize size = viewFrame.size;
		size.width *= scale;
		size.height *= scale;
        		
        BOOL onCorrectPage = NO;
		CGAffineTransform pageTransform;
		if(pageIndex == self.pageTurningView.leftPageIndex && CGRectContainsRect(self.pageTurningView.unzoomedLeftPageFrame, viewFrame)) {
			pageTransform = [self pageTurningViewTransformForPageAtIndex:pageIndex offsetOrigin:YES applyZoom:NO];
            onCorrectPage = YES;
		} else {
			pageTransform = [self pageTurningViewTransformForPageAtIndex:pageIndex offsetOrigin:YES applyZoom:NO];
            onCorrectPage = YES;
		}
		
        if(onCorrectPage) {
            CGPoint origin = CGPointMake(viewFrame.origin.x - pageTransform.tx, viewFrame.origin.y - pageTransform.ty);
            
            origin.x = roundf(origin.x * scale);
            origin.y = roundf(origin.y * scale);

            NSInteger width  = size.width;
            NSInteger height = size.height;
            NSInteger bytesPerRow = 4 * width;
            NSInteger totalBytes = bytesPerRow * height;
            
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            
            NSMutableData *bitmapData = [[[NSMutableData alloc] initWithCapacity:totalBytes] autorelease];
            [bitmapData setLength:totalBytes];
            
            CGContextRef bitmapContext = CGBitmapContextCreate(bitmapData.mutableBytes, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);        
            CGColorSpaceRelease(colorSpace);
            
            CGContextTranslateCTM(bitmapContext, view.frame.origin.x, -view.frame.origin.y);
            CGContextScaleCTM(bitmapContext, 1, -1);
            CGContextTranslateCTM(bitmapContext, 0, -height);
            
            
            //CGContextSetInterpolationQuality(bitmapContext, kCGInterpolationNone);
            CGContextScaleCTM(bitmapContext, scale, scale);
            [view.layer renderInContext:bitmapContext];
            
            THPositionedCGContext *positionedContext = [[[THPositionedCGContext alloc] initWithCGContext:bitmapContext origin:origin backing:bitmapData] autorelease];
            [positionedContexts addObject:positionedContext];
        
            CGContextRelease(bitmapContext);
        }
	}

	return positionedContexts;
}

- (void)updatePositionedOverlayContextsForPageIndex:(NSUInteger)pageIndex
{
    NSArray *contexts = [self overlayPositionedContextsForPageAtIndex:pageIndex];
    if(contexts.count) {
        [self.pageTurningView overlayPageAtIndex:pageIndex withPositionedRGBABitmapContexts:contexts];
    }
}

- (void)updatePositionedOverlayContexts
{
    EucIndexBasedPageTurningView *aPageTurningView = self.pageTurningView;
    NSUInteger leftPageIndex = aPageTurningView.leftPageIndex;
    if(leftPageIndex != NSUIntegerMax) {
        [self updatePositionedOverlayContextsForPageIndex:leftPageIndex];
    } 
    NSUInteger rightPageIndex = aPageTurningView.rightPageIndex;
    if(rightPageIndex != NSUIntegerMax) {
        [self updatePositionedOverlayContextsForPageIndex:rightPageIndex];
    } 
}

- (void)updateOverlayForPagesInRange:(NSRange)pageRange 
{
	if (self.pageTurningView && !CGSizeEqualToSize(self.pageSize, CGSizeZero)) {
		if (!self.overlay) {
            BlioGestureSuppressingView *gestureSuppressingView = [[BlioGestureSuppressingView alloc] init];
			gestureSuppressingView.frame = self.pageTurningView.bounds;
			gestureSuppressingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			gestureSuppressingView.backgroundColor = [UIColor clearColor];
            for (UIGestureRecognizer *recognizer in self.pageTurningView.gestureRecognizers) {
                if (![recognizer isEqual:self.pageTurningView.tapGestureRecognizer]) {
                    [gestureSuppressingView.suppressingGestureRecognizer requireGestureRecognizerToFail:recognizer];
                }
            }
            
            self.overlay = gestureSuppressingView;
			[self.pageTurningView addSubview:gestureSuppressingView];
            
            [gestureSuppressingView release];
		}

        [self.webViews makeObjectsPerformSelector:@selector(stopLoading)];
        [self.webViews makeObjectsPerformSelector:@selector(setDelegate:) withObject:nil];
		[self.mediaViews makeObjectsPerformSelector:@selector(stopMediaPlayer)];
		
		for (UIView *view in [self.overlay subviews]) {
			[view removeFromSuperview];
		}
		
		
		[overlay.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
		
		self.mediaViews = [NSMutableArray array];
		self.webViews = [NSMutableArray array];
		
	
		CGMutablePathRef maskPath = nil;
		
		for (int i = pageRange.location; i < pageRange.location + pageRange.length; i++) {
			
			NSUInteger pageIndex = i;
			CGAffineTransform pageTransform = [self pageTurningViewTransformForPageAtIndex:pageIndex offsetOrigin:YES applyZoom:NO];
            CGRect cropRect = [self cropForPage:pageIndex + 1 allowEstimate:NO];
            
            NSArray *content = nil;
			if ([(NSObject *)self.dataSource respondsToSelector:@selector(enhancedContentForPage:)]) {
                content = [self.dataSource enhancedContentForPage:pageIndex + 1];
            }
						
			for (NSDictionary *dict in [content reverseObjectEnumerator]) {
				CGRect displayRegion = [[dict valueForKey:@"displayRegion"] CGRectValue];
                CGRect clippedDisplayRegion = CGRectIntersection(cropRect, displayRegion);
                
				NSString *navigateUri = [dict valueForKey:@"navigateUri"];
				NSString *controlType = [dict valueForKey:@"controlType"];
				CFStringRef bookURIStringRef = (CFStringRef)[[self.bookID URIRepresentation] absoluteString];
				CFStringRef encodedString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, bookURIStringRef, NULL, CFSTR(":/"), kCFStringEncodingUTF8);
				
								
                // N.B. Cannot just use CGRectIntegral because of rounding down to -1 possibility in origin
                
                CGRect blendViewFrame = CGRectApplyAffineTransform(clippedDisplayRegion, pageTransform);
                blendViewFrame.origin.x    = roundf(blendViewFrame.origin.x);
                blendViewFrame.origin.y    = roundf(blendViewFrame.origin.y);
                blendViewFrame.size.width  = roundf(blendViewFrame.size.width);
                blendViewFrame.size.height = roundf(blendViewFrame.size.height);

                CGRect contentsFrame = CGRectApplyAffineTransform(displayRegion, pageTransform);
                contentsFrame.origin.x    = roundf(contentsFrame.origin.x);
                contentsFrame.origin.y    = roundf(contentsFrame.origin.y);
                contentsFrame.size.width  = roundf(contentsFrame.size.width);
                contentsFrame.size.height = roundf(contentsFrame.size.height);
                
				BlioBlendView *blendView = [[BlioBlendView alloc] initWithFrame:blendViewFrame];
                blendView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:0 alpha:0.5f];

                blendView.layer.masksToBounds = YES;
                
                contentsFrame.origin = CGPointMake(CGRectGetMinX(contentsFrame) - CGRectGetMinX(blendViewFrame), CGRectGetMinY(contentsFrame) - CGRectGetMinY(blendViewFrame));
                if (CGRectGetMaxY(contentsFrame) > CGRectGetHeight(blendViewFrame)) {
                    contentsFrame.size.height -= (CGRectGetMaxY(contentsFrame) - CGRectGetHeight(blendViewFrame));
                }
                if (CGRectGetMaxX(contentsFrame) > CGRectGetWidth(blendViewFrame)) {
                    contentsFrame.size.width -= (CGRectGetMaxX(contentsFrame) - CGRectGetWidth(blendViewFrame));
                }
                
                if(!maskPath) {
                    maskPath = CGPathCreateMutable();
                }
				CGPathAddRect(maskPath, NULL, blendViewFrame);
				
				CAReplicatorLayer *replicatorLayer = (CAReplicatorLayer *)blendView.layer;
				replicatorLayer.instanceCount = 1;
				replicatorLayer.instanceColor = self.pageMultiplyColor.CGColor;
				
				if ([controlType isEqualToString:@"WebBrowser"]) {
										
							
					NSString *rootPath = [[self.dataSource enhancedContentRootPath] stringByAppendingPathComponent:navigateUri];
					NSURL *rootXPSURL = [[[NSURL alloc] initWithScheme:@"blioxpsprotocol" host:(NSString *)encodedString path:rootPath] autorelease];
                    
					UIWebView *webView = [[[UIWebView alloc] initWithFrame:contentsFrame] autorelease];
                    webView.backgroundColor = [UIColor whiteColor];
					webView.delegate = self;
					webView.scalesPageToFit = NO;
					
                    [blendView addSubview:webView];
					
					[self.webViews addObject:webView];
 								
                    NSURLRequest *request = [[[NSURLRequest alloc] initWithURL:rootXPSURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:30] autorelease];
					
					[webView loadRequest:request];
				} else if ([controlType isEqualToString:@"iOSCompatibleVideoContent"]) {
					
					NSURL *videoURL = [self.dataSource temporaryURLForEnhancedContentVideoAtPath:[[self.dataSource enhancedContentRootPath] stringByAppendingPathComponent:navigateUri]];
					BlioMediaView * mediaView = [[[BlioMediaView alloc] initWithFrame:contentsFrame contentURL:videoURL] autorelease];

					[blendView addSubview:mediaView];
					[self.mediaViews addObject:mediaView];
				}
 
				[overlay addSubview:blendView];
                [blendView release];
				
				CFRelease(encodedString);
			}
			
            if(maskPath) {
                CAShapeLayer *alphaMaskLayer = [CAShapeLayer layer];
                alphaMaskLayer.frame = self.overlay.bounds;
                alphaMaskLayer.backgroundColor = [UIColor clearColor].CGColor;
                                
                CALayer *alphaLayer = [CALayer layer];
                alphaLayer.backgroundColor = [UIColor clearColor].CGColor;
                alphaLayer.contents = (id)self.pageAlphaMask.CGImage;
                alphaLayer.contentsGravity = kCAGravityResizeAspect;
                alphaLayer.opaque = NO;
                alphaLayer.frame = self.overlay.bounds;
                alphaMaskLayer.path = maskPath;
                CGPathRelease(maskPath);
				maskPath = nil;
                alphaLayer.mask = alphaMaskLayer;
                
                [self.overlay.layer addSublayer:alphaLayer];
            }
		}
    }
}

- (UIColor *)pageMultiplyColor {
	if (!pageMultiplyColor) {
		[self.pageTurningView pagesAlphaMaskGetAverageColor:&pageMultiplyColor];
		[pageMultiplyColor retain];
	}
	
	return pageMultiplyColor;
}	

- (UIImage *)pageAlphaMask {
	if (!pageAlphaMask) {
		pageAlphaMask = [self.pageTurningView pagesAlphaMaskGetAverageColor:&(UIColor *){nil}];
		[pageAlphaMask retain];
	}
	
	return pageAlphaMask;
}

- (void)updateOverlay {
	if ([self.pageTurningView isTwoUp] && (self.pageTurningView.leftPageIndex != NSUIntegerMax)) {
		[self updateOverlayForPagesInRange:NSMakeRange(self.pageTurningView.leftPageIndex, 2)];
	} else {
		[self updateOverlayForPagesInRange:NSMakeRange(self.pageTurningView.rightPageIndex, 1)];
	}
}

- (void)clearOverlayCaches {
	[pageAlphaMask release], pageAlphaMask = nil;
	[pageMultiplyColor release], pageMultiplyColor = nil;
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
    NSMutableString *jsCommand = [NSMutableString string];
	[jsCommand appendString:@"document.documentElement.style.webkitTapHighlightColor = 'rgba(0,0,0,0)';"];
	[jsCommand appendString:@"document.documentElement.style.webkitTouchCallout = 'none';"];
	[aWebView stringByEvaluatingJavaScriptFromString:jsCommand];	
}


#pragma mark -
#pragma mark highlights

- (void)addHighlightWithColor:(UIColor *)color {
    BlioBookmarkRange *toBookmarkRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRange]];

    NSInteger startPage;
    NSInteger endPage;
    
    if ([self.selector selectedRangeIsHighlight]) {
        BlioBookmarkRange *fromBookmarkRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRangeOriginalHighlightRange]];
        startPage = MIN(fromBookmarkRange.startPoint.layoutPage, toBookmarkRange.startPoint.layoutPage) - 1;
        endPage = MAX(fromBookmarkRange.endPoint.layoutPage, toBookmarkRange.endPoint.layoutPage) - 1;
    } else {
        startPage = toBookmarkRange.startPoint.layoutPage;
        endPage = toBookmarkRange.endPoint.layoutPage;
    }
    
    [super addHighlightWithColor:color];
    
    for (int i = startPage; i <= endPage; i++) {
        [self.pageTurningView refreshHighlightsForPageAtIndex:i - 1];
    }
    
    [self.pageTurningView drawView];
}

- (NSArray *)rectsFromBlocksAtPageIndex:(NSInteger)pageIndex inBookmarkRange:(BlioBookmarkRange *)bookmarkRange {
	NSMutableArray *rects = [[NSMutableArray alloc] init];
	
	NSArray *pageBlocks = [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:NO];
	
	CGAffineTransform  pageTransform = [self pageTurningViewTransformForPageAtIndex:pageIndex offsetOrigin:NO applyZoom:NO];

	for (BlioTextFlowBlock *block in pageBlocks) {                
		for (BlioTextFlowPositionedWord *word in [block words]) {
			// If the range starts before this word:
			if ( bookmarkRange.startPoint.layoutPage < (pageIndex + 1) ||
				((bookmarkRange.startPoint.layoutPage == (pageIndex + 1)) && (bookmarkRange.startPoint.blockOffset < block.blockIndex)) ||
				((bookmarkRange.startPoint.layoutPage == (pageIndex + 1)) && (bookmarkRange.startPoint.blockOffset == block.blockIndex) && (bookmarkRange.startPoint.wordOffset <= word.wordIndex)) ) {
				// If the range ends after this word:
				if ( bookmarkRange.endPoint.layoutPage > (pageIndex +1 ) ||
					((bookmarkRange.endPoint.layoutPage == (pageIndex + 1)) && (bookmarkRange.endPoint.blockOffset > block.blockIndex)) ||
					((bookmarkRange.endPoint.layoutPage == (pageIndex + 1)) && (bookmarkRange.endPoint.blockOffset == block.blockIndex) && (bookmarkRange.endPoint.wordOffset >= word.wordIndex)) ) {
					// This word is in the range.
					CGRect pageRect = CGRectApplyAffineTransform([word rect], pageTransform);
					[rects addObject:[NSValue valueWithCGRect:pageRect]];
					
				}                            
			}
		}
	}
	
	return [rects autorelease];
	
}

- (NSArray *)highlightRectsForPageAtIndex:(NSInteger)pageIndex excluding:(BlioBookmarkRange *)excludedBookmark {
    NSMutableArray *allHighlights = [NSMutableArray array];
    NSArray *highlightRanges = nil;
    if (self.delegate) {
        highlightRanges = [self.delegate rangesToHighlightForLayoutPage:pageIndex + 1];
    }

    

    for (BlioBookmarkRange *highlightRange in highlightRanges) {
        
        if (![highlightRange isEqual:excludedBookmark]) {
			
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			NSArray *highlightRects = [self rectsFromBlocksAtPageIndex:pageIndex inBookmarkRange:highlightRange];
            NSArray *coalescedRects = [EucSelector coalescedLineRectsForElementRects:highlightRects];
            
            for (NSValue *rectValue in coalescedRects) {
                THPair *highlightPair = [[THPair alloc] initWithFirst:(id)rectValue second:(id)[highlightRange.color colorWithAlphaComponent:0.3f]];
                [allHighlights addObject:highlightPair];
                [highlightPair release];
            }
            
            [pool drain];
        }
        
    }
    
    return allHighlights;
}

- (NSArray *)pageTurningView:(EucIndexBasedPageTurningView *)pageTurningView highlightsForPageAtIndex:(NSUInteger)pageIndex {

    EucSelectorRange *selectedRange = [self.selector selectedRange];
    BlioBookmarkRange *excludedRange = [self bookmarkRangeFromSelectorRange:selectedRange];
    
    return [self highlightRectsForPageAtIndex:pageIndex excluding:excludedRange];
}

- (void)refreshHighlights {
    NSUInteger pageIndex = self.pageTurningView.leftPageIndex;
    if(pageIndex != NSUIntegerMax) {
        [self.pageTurningView refreshHighlightsForPageAtIndex:pageIndex];
    }
    pageIndex = self.pageTurningView.rightPageIndex;
    if(pageIndex != NSUIntegerMax) {
        [self.pageTurningView refreshHighlightsForPageAtIndex:pageIndex];
    }
}

#pragma mark -
#pragma mark TTS

- (void)highlightWordAtBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint {
    [self highlightWordAtBookmarkPoint:bookmarkPoint saveToHistory:YES];
}

- (void)highlightWordAtBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint saveToHistory:(BOOL)save {
    BlioBookmarkRange *range = [BlioBookmarkRange bookmarkRangeWithBookmarkPoint:bookmarkPoint];
    [self highlightWordsInBookmarkRange:range animated:YES saveToHistory:save];
}

- (void)highlightWordsInBookmarkRange:(BlioBookmarkRange *)bookmarkRange animated:(BOOL)animated {
    [self highlightWordsInBookmarkRange:bookmarkRange animated:animated saveToHistory:!animated];
}

- (void)highlightWordsInBookmarkRange:(BlioBookmarkRange *)bookmarkRange animated:(BOOL)animated saveToHistory:(BOOL)save {

	self.temporaryHighlightRange = bookmarkRange;
	
    if (bookmarkRange && !pageViewIsTurning) {
		BOOL pageIsVisible = YES;
		NSInteger targetIndex = bookmarkRange.startPoint.layoutPage - 1;
		
        if ((self.pageTurningView.leftPageIndex != targetIndex) && (self.pageTurningView.rightPageIndex != targetIndex)) {
            pageIsVisible = NO;
        }
				
		BOOL showHighlight = YES;
		
        if (!pageIsVisible) {
			[self.selector removeTemporaryHighlight];
            [self goToBookmarkPoint:bookmarkRange.startPoint animated:animated saveToHistory:save];
			if (animated) {
				showHighlight = NO;
			}
        } 
		if (showHighlight) {
			CGRect visibleRect = [self visibleRectForPageAtIndex:targetIndex];
			CGRect boundingRect = CGRectNull;
			
			CGAffineTransform  pageTransform = [self pageTurningViewTransformForPageAtIndex:targetIndex offsetOrigin:NO applyZoom:NO];

			NSArray *rectValues = [self rectsFromBlocksAtPageIndex:targetIndex inBookmarkRange:bookmarkRange];
			for (NSValue *rectValue in rectValues) {
				CGRect rect = CGRectApplyAffineTransform([rectValue CGRectValue], CGAffineTransformInvert(pageTransform));
				boundingRect = CGRectUnion(boundingRect, rect);
			}
						
			if (!CGRectEqualToRect(CGRectIntegral(CGRectIntersection(visibleRect, boundingRect)), CGRectIntegral(boundingRect))) {
				
				CGAffineTransform  viewTransform = [self pageTurningViewTransformForPageAtIndex:targetIndex offsetOrigin:YES applyZoom:YES];
				CGRect viewBoundingRect = CGRectApplyAffineTransform(boundingRect, viewTransform);
				CGPoint midPoint = CGPointMake(CGRectGetMidX(viewBoundingRect), CGRectGetMidY(viewBoundingRect));
				
				[self zoomOutAtPoint:midPoint animated:animated];
			}
			
			EucSelectorRange *range = [self selectorRangeFromBookmarkRange:bookmarkRange];
			[self.selector temporarilyHighlightSelectorRange:range animated:animated];
		}
    } else {
        [self.selector removeTemporaryHighlight];
    }
}

#pragma mark -
#pragma mark Goto Animations

- (CGRect)firstPageRect {
	CGRect coverRect = self.pageTurningView.rightPageFrame;	
	return coverRect;
}

- (id<EucBookContentsTableViewControllerDataSource>)contentsDataSource {
	if ([(NSObject *)self.dataSource isKindOfClass:[BlioLayoutPDFDataSource class]]) {
		return (BlioLayoutPDFDataSource *)self.dataSource;
	} else {
		return self.textFlow;
	}
}

#pragma mark -
#pragma mark Touch Handling

- (BOOL)touchesShouldBeSuppressed {
	return YES;
}

- (void)registerGesturesForPageTurningView:(EucPageTurningView *)aPageTurningView;
{
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [aPageTurningView addGestureRecognizer:doubleTap];
        
    [aPageTurningView.tapGestureRecognizer removeTarget:nil action:nil]; 
    [aPageTurningView.tapGestureRecognizer addTarget:self action:@selector(handleSingleTap:)];
    
    [aPageTurningView.tapGestureRecognizer requireGestureRecognizerToFail:doubleTap];

    aPageTurningView.tapGestureRecognizer.cancelsTouchesInView = NO;
    
    [doubleTap release];
}

- (void)handleSingleTap:(UITapGestureRecognizer *)sender {     
    if (sender.state == UIGestureRecognizerStateEnded && 
        !self.selector.isTracking) {
        
        UIView *overlayView = self.overlay;
        UIView *hitTestOverlayView = [overlayView hitTest:[sender locationInView:overlayView] withEvent:nil];
        if(overlayView != hitTestOverlayView) {
            // Hide on taps with overlay contents, otherwise do nothing
            // (we don't want to show the toolbars if the user is just interating
            // with a peice of overlay content.
            [self.delegate hideToolbars];
            return;
        }
            
        CGPoint point = [sender locationInView:self];
        BlioLayoutHyperlink *touchedHyperlink = nil;
        BlioBookmarkRange *touchedNoteBookmark = nil;
        
        if (self.pageTurningView.isTwoUp) {
            NSInteger leftPageIndex = [self.pageTurningView leftPageIndex];
            if (leftPageIndex != NSUIntegerMax) {
                touchedHyperlink = [self hyperlinkForPage:leftPageIndex + 1 atPoint:point];
                touchedNoteBookmark = [self noteBookmarkForPage:leftPageIndex + 1 atPoint:point];
            }
        }
            
        if ((nil == touchedHyperlink) && (nil == touchedNoteBookmark)) {
            NSInteger rightPageIndex = [self.pageTurningView rightPageIndex];
            if (rightPageIndex != NSUIntegerMax) {
                touchedHyperlink = [self hyperlinkForPage:rightPageIndex + 1 atPoint:point];
                touchedNoteBookmark = [self noteBookmarkForPage:rightPageIndex + 1 atPoint:point];
            }
        }
        
        if (touchedNoteBookmark != nil) {
            [self.selector setSelectedRange:[self selectorRangeFromBookmarkRange:touchedNoteBookmark]];
            [self.delegate hideToolbars];
        } else if (touchedHyperlink != nil) {
            [self hyperlinkTapped:touchedHyperlink.link];
        } else {
        
            BOOL voiceOverRunning = NO;
            
            if (UIAccessibilityIsVoiceOverRunning != nil) {
                if (UIAccessibilityIsVoiceOverRunning()) {
                    voiceOverRunning = YES;
                }
            }
            
            if (voiceOverRunning) {
                UIAccessibilityElement *focusedElement = nil;
                
                for (UIAccessibilityElement *element in self.accessibilityElements) {
                    if ([element accessibilityElementIsFocused]) {
                        focusedElement = element;
                        break;
                    }
                }
                
                NSUInteger wantPageIndex = NSUIntegerMax;
                if (self.prevZone && focusedElement == self.prevZone) {
                    if (self.pageTurningView.isTwoUp) {
                        wantPageIndex = self.pageTurningView.leftPageIndex;
                        if(wantPageIndex != NSUIntegerMax) {
                            if(wantPageIndex >= 2) {
                                // Subtract 2 so that the focused page after the turn is
                                // on the right.
                                wantPageIndex -= 2;
                            } else if(wantPageIndex > 0) {
                                --wantPageIndex;
                            } else {
                                // Already at index 0, can't turn.
                                wantPageIndex = NSUIntegerMax;
                            }
                        }
                    } else {
                        wantPageIndex = self.pageTurningView.rightPageIndex;
                        if(wantPageIndex != NSUIntegerMax) {
                            if(wantPageIndex > 0) {
                                --wantPageIndex;
                            } else {
                                // Already at index 0, can't turn.
                                wantPageIndex = NSUIntegerMax;
                            }
                        }                
                    }
                } else if (self.nextZone && focusedElement == self.nextZone) {
                    wantPageIndex = self.pageTurningView.rightPageIndex;
                    if(wantPageIndex != NSUIntegerMax) {
                        ++wantPageIndex;
                    }
                } 
                if(wantPageIndex != NSUIntegerMax) {
                    [self goToPageNumber:wantPageIndex + 1 animated:YES];
                    return;
                } else {
                    [self.delegate toggleToolbars];
                    return;
                }
            }
            
            CGFloat screenWidth = CGRectGetWidth(self.bounds);
            CGFloat leftHandHotZone = screenWidth * BLIOLAYOUT_LHSHOTZONE;
            CGFloat rightHandHotZone = screenWidth * BLIOLAYOUT_RHSHOTZONE;
            
            if (point.x <= leftHandHotZone) {
                [self zoomToPreviousBlock];
                [self.delegate hideToolbars];
            } else if (point.x >= rightHandHotZone) {
                [self zoomToNextBlock];
                [self.delegate hideToolbars];
            } else {
                [self.delegate toggleToolbars];
            }    
        }
    }
    
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)sender {     
    if (sender.state == UIGestureRecognizerStateEnded && 
        !self.pageTurningView.animating)     {
        BOOL performZoom = YES;
        if (UIAccessibilityIsVoiceOverRunning != nil) {
            if (UIAccessibilityIsVoiceOverRunning()) {
                performZoom = NO;
            }
        }
        if (performZoom) {
            [self zoomAtPoint:[sender locationInView:self]];
            [self.delegate hideToolbars];
        } else {
            [self.delegate toggleToolbars]; 
        }
    }
}

        
#pragma mark -
#pragma mark Hyperlinks

- (BOOL)toolbarShowShouldBeSuppressed {
    return [self touchesShouldBeSuppressed];
}

- (BOOL)toolbarHideShouldBeSuppressed {
	return [self touchesShouldBeSuppressed];
}

- (void)hyperlinkTapped:(NSString *)link {	
	if ([(NSObject *)self.dataSource isKindOfClass:[BlioLayoutPDFDataSource class]]) {
		NSInteger page = [link integerValue];
		if (page) {
			[self goToPageNumber:page animated:YES];
		}
	} else {
		BlioTextFlowReference *reference = [self.textFlow referenceForReferenceId:link];
    
		if (reference) {
			[self goToPageNumber:reference.pageIndex + 1 animated:YES];
		}
	}
}

- (NSArray *)hyperlinksForPage:(NSInteger)page {
    
    [hyperlinksCacheLock lock];
    
    NSArray *hyperlinksArray = [self.hyperlinksCache objectForKey:[NSNumber numberWithInt:page]];
    
    if (nil == hyperlinksArray) {
        if (nil == self.hyperlinksCache) {
            self.hyperlinksCache = [NSMutableDictionary dictionaryWithCapacity:pageCount];
        }
        
        NSArray *hyperlinks = [self.dataSource hyperlinksForPage:page];
        if (hyperlinks != nil) {
            [self.hyperlinksCache setObject:hyperlinks forKey:[NSNumber numberWithInt:page]];
        }
        hyperlinksArray = [self.hyperlinksCache objectForKey:[NSNumber numberWithInt:page]];
    }
    
    [hyperlinksCacheLock unlock];
    
    return hyperlinksArray;
}

- (BlioBookmarkRange *)noteBookmarkForPage:(NSInteger)page atPoint:(CGPoint)point {
	
	NSUInteger pageIndex = page - 1;
	
	NSArray *highlightRanges = nil;
    if (self.delegate) {
        highlightRanges = [self.delegate rangesToHighlightForLayoutPage:page];
    }
	
    CGAffineTransform  pageTransform = [self pageTurningViewTransformForPageAtIndex:pageIndex offsetOrigin:NO applyZoom:NO];
	CGAffineTransform  viewTransform = CGAffineTransformConcat(CGAffineTransformInvert(pageTransform), [self pageTurningViewTransformForPageAtIndex:pageIndex offsetOrigin:YES applyZoom:YES]);
	
	BlioBookmarkRange *noteBookmarkMatch = nil;
	
    for (BlioBookmarkRange *highlightRange in highlightRanges) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		NSArray *highlightRects = [self rectsFromBlocksAtPageIndex:pageIndex inBookmarkRange:highlightRange];
		NSArray *coalescedRects = [EucSelector coalescedLineRectsForElementRects:highlightRects];
		
		for (NSValue *rectValue in coalescedRects) {
			CGRect coalescedRect = CGRectApplyAffineTransform([rectValue CGRectValue], viewTransform);
			
			if (CGRectContainsPoint(coalescedRect, point)) {
				noteBookmarkMatch = highlightRange;
				break;
			}
		}
		
		[pool drain];
		
		if (noteBookmarkMatch != nil) {
			break;
		}
        
    }
	
    return noteBookmarkMatch;
}

- (BlioLayoutHyperlink *)hyperlinkForPage:(NSInteger)page atPoint:(CGPoint)point {
    
    BlioLayoutHyperlink *hyperlinkMatch = nil;
    CGAffineTransform viewTransform = [self pageTurningViewTransformForPageAtIndex:page - 1];
    
    for (BlioLayoutHyperlink *hyperlink in [self hyperlinksForPage:page]) {
        CGRect hyperlinkRect = CGRectApplyAffineTransform([hyperlink rect], viewTransform);
        if (CGRectContainsPoint(hyperlinkRect, point)) {
            hyperlinkMatch = hyperlink;
            break;
        }
    }
    
    return hyperlinkMatch;
}

#pragma mark -
#pragma mark Accessibility

#pragma mark Pre-iOS 5

- (NSArray *)textBlockAccessibilityElements {
    NSMutableArray *elements = [NSMutableArray array];
	
    NSInteger pageIndex = self.pageTurningView.leftPageIndex;
    if(self.pageTurningView.isTwoUp && pageIndex != NSUIntegerMax) {
        CGAffineTransform viewTransform = [self pageTurningViewTransformForPageAtIndex:pageIndex offsetOrigin:YES applyZoom:NO];
        NSArray *nonFolioPageBlocks = [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:NO];
    
        for (BlioTextFlowBlock *block in nonFolioPageBlocks) {
            UIAccessibilityElement *element = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
            CGRect blockRect = CGRectApplyAffineTransform([block rect], viewTransform);
            blockRect = [self.window.layer convertRect:blockRect fromLayer:self.pageTurningView.layer];
            [element setAccessibilityFrame:blockRect];
            [element setAccessibilityLabel:[block string]];
            [elements addObject:element];
            [element release];
        }
    }
	
    pageIndex = self.pageTurningView.rightPageIndex;
    if(pageIndex != NSUIntegerMax) {
        CGAffineTransform viewTransform = [self pageTurningViewTransformForPageAtIndex:pageIndex offsetOrigin:YES applyZoom:NO];
        NSArray *nonFolioPageBlocks = [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:NO];
        
        for (BlioTextFlowBlock *block in nonFolioPageBlocks) {
            UIAccessibilityElement *element = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
            CGRect blockRect = CGRectApplyAffineTransform([block rect], viewTransform);
            blockRect = [self.window.layer convertRect:blockRect fromLayer:self.pageTurningView.layer];
            [element setAccessibilityFrame:blockRect];
            [element setAccessibilityLabel:[block string]];
            [elements addObject:element];
            [element release];
        }
    }
	
	return elements;
}

- (NSArray *)accessibilityElements {
    if(!accessibilityElements) {
        NSMutableArray *newAccessibilityElements = [[NSMutableArray alloc] init];
		
        CGFloat tapZoneWidth = 0.0f;      

        if(&UIAccessibilityPageScrolledNotification == NULL) {
            tapZoneWidth = 0.25f * self.pageTurningView.bounds.size.width;      

            {
                UIAccessibilityElement *nextPageTapZone = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
                nextPageTapZone.accessibilityTraits = UIAccessibilityTraitButton;
                if (self.pageTurningView.rightPageIndex >= (self.pageCount - 1))  {
                    nextPageTapZone.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
                }            
                CGRect frame = self.bounds;
                frame.origin.x = frame.size.width + frame.origin.x - tapZoneWidth;
                frame.size.width = tapZoneWidth;
                frame = [self convertRect:frame toView:self.window];

                nextPageTapZone.accessibilityFrame = frame;
                nextPageTapZone.accessibilityLabel = NSLocalizedString(@"Next Page", @"Accessibility title for Next Page tap zone");            

                self.nextZone = nextPageTapZone;
                
                [newAccessibilityElements addObject:nextPageTapZone];            
                [nextPageTapZone release];
            }      
            
            {
                UIAccessibilityElement *previousPageTapZone = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
                previousPageTapZone.accessibilityTraits = UIAccessibilityTraitButton;
                if (self.pageTurningView.isTwoUp) {
                    if (self.pageTurningView.leftPageIndex <= 0)  {
                        previousPageTapZone.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
                    }
                } else {
                    if (self.pageTurningView.rightPageIndex <= 0)  {
                        previousPageTapZone.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
                    }
                }
                CGRect frame = self.bounds;
                frame.size.width = tapZoneWidth;
                frame = [self convertRect:frame toView:self.window];

                previousPageTapZone.accessibilityFrame = frame;
                previousPageTapZone.accessibilityLabel = NSLocalizedString(@"Previous Page", @"Accessibility title for Previous Page tap zone");
                
                self.prevZone = previousPageTapZone;
                
                [newAccessibilityElements addObject:previousPageTapZone];
                [previousPageTapZone release];
            }
			
		}
        
        
        NSArray *pageAccessibilityElements = [self textBlockAccessibilityElements];
        if(pageAccessibilityElements.count == 0) {
            UIAccessibilityElement *bookPageTapZone = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
            bookPageTapZone.accessibilityTraits = UIAccessibilityTraitStaticText;
            CGRect frame = self.bounds;
            frame.origin.x += tapZoneWidth;
            frame.size.width -= tapZoneWidth * 2.0f;
            
            bookPageTapZone.accessibilityFrame = frame;
            bookPageTapZone.accessibilityLabel = NSLocalizedString(@"No text on this page", @"Accessibility description for otherwise empty page");
                        
            [newAccessibilityElements addObject:bookPageTapZone];
            [bookPageTapZone release];
        } else {            
            for(UIAccessibilityElement *element in pageAccessibilityElements) {
                [newAccessibilityElements addObject:element];
            }           
        }
        
        accessibilityElements = newAccessibilityElements;
    }        
	
    return accessibilityElements;
}


#pragma mark All OSes

- (NSInteger)accessibilityElementCount
{
    [self accessibilityEnsureZoomedOut];
#if TARGET_OS_IPHONE && (__IPHONE_OS_VERSION_MAX_ALLOWED >= 50000)
    if(&UIAccessibilityTraitCausesPageTurn != NULL &&
       [EucPageTurningView conformsToProtocol:@protocol(UIAccessibilityReadingContent)]) {
        return 1;
    } else {
        return [[self accessibilityElements] count];
    }
#else
    return [[self accessibilityElements] count];
#endif
}

- (id)accessibilityElementAtIndex:(NSInteger)index
{
    [self accessibilityEnsureZoomedOut];
#if TARGET_OS_IPHONE && (__IPHONE_OS_VERSION_MAX_ALLOWED >= 50000)
    if(&UIAccessibilityTraitCausesPageTurn != NULL &&
       [EucPageTurningView conformsToProtocol:@protocol(UIAccessibilityReadingContent)]) {
        if(index == 0) {
            return self.pageTurningView;
        } else {
            return nil;
        }
    } else {
        return [[self accessibilityElements] objectAtIndex:index];
    }
#else
    return [[self accessibilityElements] objectAtIndex:index];
#endif
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
#if TARGET_OS_IPHONE && (__IPHONE_OS_VERSION_MAX_ALLOWED >= 50000)
    if(&UIAccessibilityTraitCausesPageTurn != NULL &&
       [EucPageTurningView conformsToProtocol:@protocol(UIAccessibilityReadingContent)]) {
        if(element == self.pageTurningView) {
            return 0;
        } else {
            return NSNotFound;
        }
    } else {
        return [[self accessibilityElements] indexOfObject:element];
    }
#else
    return [[self accessibilityElements] indexOfObject:element];
#endif
}

- (void)accessibilityEnsureZoomedOut
{
    if (self.pageTurningView.zoomFactor > 1.0f) {
        self.performingAccessibilityZoom = YES;
        self.pageTurningView.minZoomFactor = 1.0f;
		[self.pageTurningView setTranslation:CGPointZero zoomFactor:1.0f animated:YES];
	}
}

- (CGRect)accessibilityFrame
{
    return [self convertRect:[self.delegate nonToolbarRect] toView:nil];
}

- (NSString *)accessibilityLabel
{
    return NSLocalizedString(@"Book Page", "Accessibility label for libEucalyptus page view");
}

- (NSString *)accessibilityHint
{
    return NSLocalizedString(@"Double tap to read page with VoiceOver.", "Accessibility label for libEucalyptus page view");
}

- (BOOL)isAccessibilityElement
{
    return [self.delegate toolbarsVisible];
}

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction
{
    return [self.pageTurningView accessibilityScroll:direction];
}

#pragma mark Post-iOS 5, use EucPageTurningView

- (NSArray *)accessibiltyLinesForPageAtIndex:(NSUInteger)pageIndex {
    [self accessibilityEnsureZoomedOut];

    NSMutableArray *ret = nil;

    if(!self.accessibiltyLinesCache) {
        self.accessibiltyLinesCache = [NSMutableArray array]; 
    }
    for(THPair *indexAndLines in self.accessibiltyLinesCache) {
        if([indexAndLines.first unsignedIntegerValue] == pageIndex) {
            ret = indexAndLines.second;
        }
    }
    
    if(!ret) {
        if(self.accessibiltyLinesCache.count == 2) {
            [self.accessibiltyLinesCache removeObjectAtIndex:0];
        }
        
        ret = [NSMutableArray array];
        
        NSArray *nonFolioPageBlocks = [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:NO];
        for(BlioTextFlowBlock *block in nonFolioPageBlocks) {
            CGFloat lineStartX = 0;
            CGFloat lineMinY = 0;
            CGFloat lineMaxY = 0;
            
            // Setting to CGFLOAT_MAX will cause us to start a new line
            // in the first iteration of the loop, below.
            CGFloat previousWordEndX = CGFLOAT_MAX;
            
            NSMutableArray *wordsBuild = [NSMutableArray array];
            for(BlioTextFlowPositionedWord *word in block.words) {
                CGRect wordRect = word.rect;
                if(CGRectGetMinX(wordRect) > previousWordEndX) {
                    [wordsBuild addObject:word];
                    
                    if(lineMaxY < CGRectGetMaxY(wordRect)) {
                        lineMaxY = CGRectGetMaxY(wordRect);
                    }
                    if(lineMinY > CGRectGetMinY(wordRect)) {
                        lineMinY = CGRectGetMinY(wordRect);
                    }
                } else {
                    if(wordsBuild.count) {
                        CGRect lineRect = CGRectMake(lineStartX, lineMinY,
                                                     previousWordEndX - lineStartX, lineMaxY - lineMinY);
                        
                        [ret addPairWithFirst:[NSValue valueWithCGRect:lineRect] second:wordsBuild];
                    }
                    wordsBuild = [NSMutableArray arrayWithObject:word];
                    lineStartX = CGRectGetMinX(wordRect);
                    lineMaxY = CGRectGetMaxY(wordRect);
                    lineMinY = CGRectGetMinY(wordRect);
                }
                previousWordEndX = CGRectGetMaxX(wordRect);
            }
            if(wordsBuild.count) {
                CGRect lineRect = CGRectMake(lineStartX, lineMinY,
                                             previousWordEndX - lineStartX, lineMaxY - lineMinY);
                [ret addPairWithFirst:[NSValue valueWithCGRect:lineRect] second:wordsBuild];
            }
        }        
        [self.accessibiltyLinesCache addPairWithFirst:[NSNumber numberWithUnsignedInteger:pageIndex] second:ret];
    }
    return ret;
}

- (NSInteger)pageTurningView:(EucIndexBasedPageTurningView *)pageTurningView accessibilityLineNumberForInternalPoint:(CGPoint)point forPageAtIndex:(NSUInteger)pageIndex {
    [self accessibilityEnsureZoomedOut];

    NSArray *lines = [self accessibiltyLinesForPageAtIndex:pageIndex];

    NSInteger bestLineIndex = NSNotFound;
    CGFloat bestWordDistance = CGFLOAT_MAX;
    
    // To cope with lines that overlap (for example, a line with a descending 
    // dropcap on the left will overlap lines after it that are flowed around 
    // the dropcap), we find the line containing the point that contains the
    // nearest word to the point.
    if(lines) {
        CGAffineTransform pageTransform = [self pageTurningViewTransformForPageAtIndex:pageIndex offsetOrigin:NO applyZoom:NO];
        CGPoint pagePoint = CGPointApplyAffineTransform(point, CGAffineTransformInvert(pageTransform));
        NSInteger i = 0;
        for(THPair *rectAndLine in lines) {
            CGRect lineRect = [rectAndLine.first CGRectValue];
            if(CGRectContainsPoint(lineRect, pagePoint)) {
                for(BlioTextFlowPositionedWord *word in rectAndLine.second) {
                    CGRect wordRect = word.rect;
                    CGFloat distance = CGPointDistanceFromRect(pagePoint, wordRect);
                    if(distance < bestWordDistance) {
                        bestLineIndex = i;
                        bestWordDistance = distance;
                    }
                }
            }
            ++i;
        }
    }
    
    return bestLineIndex;
}

- (NSString *)pageTurningView:(EucIndexBasedPageTurningView *)pageTurningView accessibilityContentForLineNumber:(NSInteger)lineNumber forPageAtIndex:(NSUInteger)pageIndex {
    [self accessibilityEnsureZoomedOut];

    THPair *pageLine = [[self accessibiltyLinesForPageAtIndex:pageIndex] objectAtIndex:lineNumber];
    return [[pageLine.second valueForKey:@"string"] componentsJoinedByString:@" "];
}

- (CGRect)pageTurningView:(EucIndexBasedPageTurningView *)pageTurningView accessibilityInternalFrameForLineNumber:(NSInteger)lineNumber forPageAtIndex:(NSUInteger)pageIndex {
    [self accessibilityEnsureZoomedOut];

    THPair *pageLine = [[self accessibiltyLinesForPageAtIndex:pageIndex] objectAtIndex:lineNumber];
    CGAffineTransform pageTransform = [self pageTurningViewTransformForPageAtIndex:pageIndex offsetOrigin:NO applyZoom:NO];
    return CGRectApplyAffineTransform([pageLine.first CGRectValue], pageTransform);
}

- (NSInteger)pageTurningView:(EucIndexBasedPageTurningView *)pageTurningView accessibilityLineCountForPageAtIndex:(NSUInteger)pageIndex {
    [self accessibilityEnsureZoomedOut];

    return [self accessibiltyLinesForPageAtIndex:pageIndex].count;
}


#pragma mark -
#pragma mark Zoom Interactions

- (CGFloat)verticalSpacingForPage:(NSInteger)page {
    return [self cropForPage:page].size.height * PAGEHEIGHTRATIO_FOR_BLOCKCOMBINERVERTICALSPACING;
}

- (BOOL)blockRect:(CGRect)blockRect isFullyVisibleInRect:(CGRect)visibleRect {
    CGRect intersection = CGRectIntersection(blockRect, visibleRect);
    if (CGRectEqualToRect(intersection, blockRect)) {
        return YES;
    }
    return NO;
}

- (BOOL)blockRect:(CGRect)blockRect isPartiallyVisibleInRect:(CGRect)visibleRect {
    if ((CGRectGetMinX(blockRect) >= CGRectGetMinX(visibleRect)) && (CGRectGetMaxX(blockRect) <= CGRectGetMaxX(visibleRect))) {
        CGRect intersection = CGRectIntersection(blockRect, visibleRect);
        if (!CGRectIsNull(intersection)) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)blockRect:(CGRect)blockRect isTopVisibleInRect:(CGRect)visibleRect {
    if ([self blockRect:blockRect isPartiallyVisibleInRect:visibleRect]) {
        if ((CGRectGetMinY(blockRect) >= CGRectGetMinY(visibleRect)) && (CGRectGetMinY(blockRect) <= CGRectGetMaxY(visibleRect))) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)blockRect:(CGRect)blockRect isBottomVisibleInRect:(CGRect)visibleRect {
    if ([self blockRect:blockRect isPartiallyVisibleInRect:visibleRect]) {
        if ((CGRectGetMaxY(blockRect) <= CGRectGetMaxY(visibleRect)) && (CGRectGetMaxY(blockRect) >= CGRectGetMinY(visibleRect))) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)fullPageWidthForPage:(NSInteger)page isVisibleInRect:(CGRect)visibleRect {
    CGRect screenCrop = [self cropForPage:page];
    CGAffineTransform viewTransform = [self pageTurningViewTransformForPageAtIndex:page - 1];
    CGRect pageCrop = CGRectApplyAffineTransform(screenCrop, CGAffineTransformInvert(viewTransform));
    
    return [self blockRect:pageCrop isPartiallyVisibleInRect:visibleRect];    
}

- (void)zoomToPreviousBlock {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kBlioTapZoomsDefaultsKey]) {
		blockRecursionDepth = 0;
		[self zoomToNextBlockReversed:YES];
	} else {
		NSUInteger pageIndex = (self.pageTurningView.isTwoUp) ? self.pageTurningView.leftPageIndex : self.pageTurningView.rightPageIndex;
        if(pageIndex != NSUIntegerMax) {
            NSInteger newPageIndex = pageIndex - 1;
            if(self.pageTurningView.isTwoUp && newPageIndex > 0) {
                // We want the left-hand page to be the focused page.
                newPageIndex--;
            }
            [self goToPageNumber:newPageIndex + 1 animated:YES];
            [self zoomForNewPageAnimated:YES];
        }
	}
}

- (void)zoomToNextBlock {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kBlioTapZoomsDefaultsKey]) {
		blockRecursionDepth = 0;
		[self zoomToNextBlockReversed:NO];
	} else {
		NSUInteger pageIndex = self.pageTurningView.rightPageIndex;
        if(pageIndex != NSUIntegerMax) {
            NSInteger newPageIndex = pageIndex + 1;
            [self goToPageNumber:newPageIndex + 1 animated:YES];
            [self zoomForNewPageAnimated:YES];
        }
	}
}

- (void)zoomToNextBlockReversed:(BOOL)reversed {
    
    blockRecursionDepth++;
    if (blockRecursionDepth > 100) {
        NSLog(@"Warning: block recursion reached a depth of 100 on page %d. Bailing out.", [self pageNumber]);
        [self zoomOut];
        return;
    }
    
    //[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    NSInteger pageIndex = (self.pageTurningView.isTwoUp) ? self.pageTurningView.leftPageIndex : self.pageTurningView.rightPageIndex;
	
	if (self.pageTurningView.isTwoUp) {
		if (([self.lastBlock pageIndex] != self.pageTurningView.leftPageIndex) &&
			([self.lastBlock pageIndex] != self.pageTurningView.rightPageIndex)) {
			self.lastBlock = nil;
		} else {
			if (reversed) {
				pageIndex = self.pageTurningView.leftPageIndex;
			} else {
				pageIndex = self.pageTurningView.rightPageIndex;
			}
		}
	} else {
		if (([self.lastBlock pageIndex] != self.pageTurningView.rightPageIndex)) {
			self.lastBlock = nil;
		} else {
			pageIndex = self.pageTurningView.rightPageIndex;
		}
	}

	if (self.lastBlock) {
		pageIndex = self.lastBlock.pageIndex;
	}
    
    NSArray *pageBlocks = [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:NO];
    BlioTextFlowBlockCombiner *blockCombiner = [[[BlioTextFlowBlockCombiner alloc] initWithTextFlowBlocks:pageBlocks] autorelease];
    blockCombiner.verticalSpacing = [self verticalSpacingForPage:pageIndex + 1];
    
    BlioTextFlowBlock *targetBlock = nil;
    BlioTextFlowBlock *currentBlock = nil;
    
    // Work out what parts of the page are visible
    CGRect visibleRect = [self visibleRectForPageAtIndex:pageIndex];
    BOOL useVisibleRect = !((self.pageTurningView.zoomFactor == self.pageTurningView.minZoomFactor) && (nil == self.lastBlock));
    
    if (useVisibleRect) {
        // Find first textFlow block that is partially visible. Loop past any textFlow
        // blocks that are fully visible. If we hit a non-visible block exit. If we hit a 
        // another partially visible block make it the target block only if the last block was fully visible
        
        BOOL partiallyVisibleBlockFound = NO;
        BOOL lastBlockWasFullyVisible = NO;
        BOOL matchLastBlock = NO;
        BOOL lastBlockMatched = NO;
        
        if (self.lastBlock) {
            currentBlock = self.lastBlock;
            self.lastBlock = nil;
            matchLastBlock = YES;
        }
        
        NSEnumerator *blockEnumerator;
        if (!reversed) {
            blockEnumerator = [pageBlocks objectEnumerator];
        } else {
            blockEnumerator = [pageBlocks reverseObjectEnumerator];
        }
        
        for (BlioTextFlowBlock *block in blockEnumerator) {
            if (matchLastBlock && !lastBlockMatched) {
                if ([block compare:currentBlock] == NSOrderedSame) {
                    lastBlockMatched = YES;
                } else {
                    continue;
                }
            }
            
            CGRect blockRect = [block rect];
            
            if (!partiallyVisibleBlockFound) {
                if ([self blockRect:blockRect isPartiallyVisibleInRect:visibleRect]) {
                    partiallyVisibleBlockFound = YES;
                    currentBlock = block;
                    if ([self blockRect:blockRect isFullyVisibleInRect:visibleRect]) {
                        lastBlockWasFullyVisible = YES;
                    }
                }
            } else {
                if ([self blockRect:blockRect isFullyVisibleInRect:visibleRect]) {
                    currentBlock = block;
                    lastBlockWasFullyVisible = YES;
                } else {
                    if (lastBlockWasFullyVisible) {
                        if ([self blockRect:blockRect isPartiallyVisibleInRect:visibleRect]) {
                            currentBlock = block;
                        }
                    }
                    break;
                }
            }
        }
    }
    
    
    // If we now have a block that is current work out whether the targetBlock on the same page should be itself, the next or previous block
    if (currentBlock) {
        targetBlock = currentBlock;
        CGRect blockRect = [targetBlock rect];
        
        BOOL topVisible    = [self blockRect:blockRect isTopVisibleInRect:visibleRect];
        BOOL bottomVisible = [self blockRect:blockRect isBottomVisibleInRect:visibleRect];
        
        if (!reversed) {
            if (bottomVisible) {
                while (targetBlock == currentBlock) {
                    targetBlock = [self.textFlow nextBlockForBlock:targetBlock 
                                              includingFolioBlocks:NO
                                                        onSamePage:YES];
                    targetBlock = [blockCombiner lastCombinedBlockForBlock:targetBlock];
                }
            }
        } else {
            if (topVisible) {
                while (targetBlock == currentBlock) {
                    targetBlock = [self.textFlow previousBlockForBlock:targetBlock 
                                                  includingFolioBlocks:NO
                                                            onSamePage:YES];  
                    targetBlock = [blockCombiner firstCombinedBlockForBlock:targetBlock];
                }
            }
        }
    } else {
        if (reversed) {
			if (self.pageTurningView.twoUp) {
				if (self.pageTurningView.focusedPageIndex == self.pageTurningView.rightPageIndex) {
					NSArray *focusedBlocks = [self.textFlow blocksForPageAtIndex:self.pageTurningView.leftPageIndex includingFolioBlocks:NO];
					if (focusedBlocks.count > 0) {
						targetBlock = [focusedBlocks lastObject];
						targetBlock = [blockCombiner lastCombinedBlockForBlock:targetBlock];
					}
				}
			}
		} else {
			NSArray *focusedBlocks = [self.textFlow blocksForPageAtIndex:self.pageTurningView.focusedPageIndex includingFolioBlocks:NO];
            if (focusedBlocks.count > 0) {
                targetBlock = [focusedBlocks objectAtIndex:0];
                targetBlock = [blockCombiner lastCombinedBlockForBlock:targetBlock];
            }
        }
    }
    
    
    // Work out targetBlock on an adjacent page 
    if (nil == targetBlock) {
        // Don't use visibleRect because it is no longer relevalnt
        useVisibleRect = NO;
        
        if (!reversed) {
            if (pageIndex >= ([self pageCount] - 1)) {
                // If we are already at the last page, zoom to page
                //[self zoomToPageIndex:targetPage - 1];
				//[self goToPageNumber:targetPage animated:YES];
				[self zoomOut];
                return;
            }
            
            // Always zoom to the next page (rather than to the first block on it)
            //[self zoomToPageIndex:targetPage - 1 + 1];
			if (self.pageTurningView.isTwoUp && (pageIndex == self.pageTurningView.leftPageIndex)) {
				NSInteger newPageIndex = pageIndex + 1;
				pageBlocks = [self.textFlow blocksForPageAtIndex:newPageIndex includingFolioBlocks:NO];
				blockCombiner = [[[BlioTextFlowBlockCombiner alloc] initWithTextFlowBlocks:pageBlocks] autorelease];
				blockCombiner.verticalSpacing = [self verticalSpacingForPage:newPageIndex + 1];
				
				if (pageBlocks.count > 0) {
					targetBlock = [pageBlocks objectAtIndex:0];
					targetBlock = [blockCombiner firstCombinedBlockForBlock:targetBlock];
				}
			}
			
			if (nil == targetBlock)	{
                if(self.pageTurningView.isTwoUp) {
                    pageIndex = self.pageTurningView.rightPageIndex;
                }
                if (pageIndex >= ([self pageCount] - 1)) {
                    // If we are already at the last page, zoom to page
                    //[self zoomToPageIndex:targetPage - 1];
                    //[self goToPageNumber:targetPage animated:YES];
                    [self zoomOut];
                    return;
                }                
				[self goToPageNumber:(pageIndex + 1) + 1 animated:YES];
                [self zoomForNewPageAnimated:YES];
				return;
			}
        } else {
            if (pageIndex <= 0) {
                // If we are already at the first page, zoom to page
                //[self zoomToPageIndex:targetPage - 1];
				//[self goToPageNumber:targetPage animated:YES];
				[self zoomOut];
                return;
            }
            
            // Zoom to the last block on the previous page, if there are any
            // blocks on it, otherwise zoom to the page.
            NSInteger newPageIndex = pageIndex - 1;
            pageBlocks = [self.textFlow blocksForPageAtIndex:newPageIndex includingFolioBlocks:NO];
            blockCombiner = [[[BlioTextFlowBlockCombiner alloc] initWithTextFlowBlocks:pageBlocks] autorelease];
            blockCombiner.verticalSpacing = [self verticalSpacingForPage:newPageIndex + 1];
            
            if (pageBlocks.count > 0) {
                targetBlock = [pageBlocks lastObject];
                targetBlock = [blockCombiner lastCombinedBlockForBlock:targetBlock];
            } else {
                // If the previous page has no blocks, zoom to page
                //[self zoomToPageIndex:targetPage - 1 - 1];
				[self goToPageNumber:(pageIndex + 1) - 1 animated:YES];
                [self zoomForNewPageAnimated:YES];
                return;
            }
        }
    }
    
    self.lastBlock = targetBlock;
    
    if (nil != targetBlock) {
        NSMethodSignature * zoomToNextBlockSig = [BlioLayoutView instanceMethodSignatureForSelector:@selector(zoomToNextBlockReversed:)];
        NSInvocation * zoomToNextBlockInv = [NSInvocation invocationWithMethodSignature:zoomToNextBlockSig];    
        [zoomToNextBlockInv setTarget:self];    
        [zoomToNextBlockInv setSelector:@selector(zoomToNextBlockReversed:)];
        [zoomToNextBlockInv setArgument:&reversed atIndex:2];
        if (useVisibleRect) {
            [self zoomToBlock:targetBlock visibleRect:visibleRect reversed:reversed context:zoomToNextBlockInv];
        } else {
            [self zoomToBlock:targetBlock visibleRect:CGRectNull reversed:reversed context:zoomToNextBlockInv];
        }
    }
}

- (CGRect)visibleRectForPageAtIndex:(NSInteger)pageIndex {
	CGAffineTransform viewTransform = [self pageTurningViewTransformForPageAtIndex:pageIndex];
	return CGRectApplyAffineTransform(self.pageTurningView.bounds, CGAffineTransformInvert(viewTransform));
}

- (void)zoomAtPoint:(CGPoint)point {

    self.lastBlock = nil;
	    	
	NSInteger pageIndex;
	
	CGRect rightPageFrame = [self.pageTurningView rightPageFrame];
	
	if (CGRectContainsPoint(rightPageFrame, point)) {
		pageIndex = self.pageTurningView.rightPageIndex;
	} else{
		pageIndex = self.pageTurningView.leftPageIndex;
	}
	
	
	CGRect bounds = self.pageTurningView.bounds;
	BOOL viewIsLandscape = bounds.size.width > bounds.size.height;
	
    BlioTextFlowBlock *targetBlock = nil;
	CGAffineTransform viewTransform = [self pageTurningViewTransformForPageAtIndex:pageIndex];
	
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kBlioTapZoomsDefaultsKey]) {
		
		// Page Zoom
		
		CGFloat currentZoomFactor = self.pageTurningView.zoomFactor;
        CGFloat minZoomFactor = self.pageTurningView.minZoomFactor;
        if (currentZoomFactor > minZoomFactor) {
			if (viewIsLandscape && !self.pageTurningView.twoUp) {
				[self advanceOrZoomOutAtPoint:point];
			} else {
				[self zoomOut];
			}
        } else {
			[self zoomToFitAllBlocksOnPageTurningViewAtPoint:point];
		}
		return;
		
    } else {
		NSArray *pageBlocks = [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:NO];
                
        for (BlioTextFlowBlock *block in pageBlocks) {
            CGRect blockRect = [block rect];
            CGRect pageRect = CGRectApplyAffineTransform(blockRect, viewTransform);
            if (CGRectContainsPoint(pageRect, point)) {
                targetBlock = block;
                break;
            }		
        }
	}
    
    if (targetBlock) {
        self.lastBlock = targetBlock;
        [self zoomToBlock:targetBlock visibleRect:[self visibleRectForPageAtIndex:pageIndex] reversed:NO context:nil center:point];
	} else {
        EucPageTurningView *myPageTurningView = self.pageTurningView;
        CGFloat currentZoomFactor = myPageTurningView.zoomFactor;
        CGFloat minZoomFactor = myPageTurningView.minZoomFactor;
        CGFloat doubleFitToBoundsZoomFactor = minZoomFactor * 1.25f;
        if (currentZoomFactor < doubleFitToBoundsZoomFactor) {
            [self zoomOutsideBlockAtPoint:point zoomFactor:doubleFitToBoundsZoomFactor];
        } else {
            [self zoomOut];
        }
    }    
}

- (CGRect)expandRectToMinimumWidth:(CGRect)aRect {
    CGRect viewBounds = self.pageTurningView.bounds;
    CGFloat blockMinimumWidth = CGRectGetWidth(viewBounds) / 3;
    
    if (CGRectGetWidth(aRect) < blockMinimumWidth) {
        aRect.origin.x -= ((blockMinimumWidth - CGRectGetWidth(aRect)))/2.0f;
        aRect.size.width += (blockMinimumWidth - CGRectGetWidth(aRect));
        
        if (aRect.origin.x < 0) {
            aRect.origin.x = 0;
            aRect.size.width += (blockMinimumWidth - CGRectGetWidth(aRect));
        }
        
        if (CGRectGetMaxX(aRect) > CGRectGetWidth(viewBounds)) {
            aRect.origin.x = CGRectGetWidth(viewBounds) - CGRectGetWidth(aRect);
        }
    }
    
    return aRect;
}

- (CGPoint)translationToFitRect:(CGRect)aRect onPage:(NSInteger)aPageNumber zoomScale:(CGFloat *)scale reversed:(BOOL)reversed {
	CGAffineTransform viewTransform = [self pageTurningViewTransformForPageAtIndex:aPageNumber - 1 offsetOrigin:YES applyZoom:NO];
	
    CGRect targetRect = CGRectApplyAffineTransform(aRect, viewTransform);
    CGRect viewBounds = self.pageTurningView.bounds;
    CGFloat zoomScale = CGRectGetWidth(viewBounds) / CGRectGetWidth(targetRect);
    targetRect = CGRectInset(targetRect, -6 / zoomScale, -10 / zoomScale);
    targetRect = [self expandRectToMinimumWidth:targetRect];
	
    zoomScale = CGRectGetWidth(viewBounds) / CGRectGetWidth(targetRect);
    *scale = zoomScale;
    
    CGRect cropRect = [self cropForPage:aPageNumber];
    CGRect pageRect = CGRectApplyAffineTransform(cropRect, viewTransform);
    CGFloat contentOffsetX = roundf( CGRectGetMidX(self.pageTurningView.bounds) - CGRectGetMidX(targetRect));
	CGFloat scaledOffsetX = contentOffsetX * zoomScale;
	
	CGFloat topOfPageOffset = CGRectGetHeight(pageRect)/2.0f;
	CGFloat bottomOfPageOffset = -topOfPageOffset;
	CGFloat rectEdgeOffset;
	CGFloat scaledOffsetY;
	
	if (!reversed) {
		rectEdgeOffset = topOfPageOffset - (CGRectGetMinY(targetRect) - pageRect.origin.y);
		scaledOffsetY = roundf(rectEdgeOffset * zoomScale - CGRectGetMidY(self.pageTurningView.bounds));
	} else {
		rectEdgeOffset = bottomOfPageOffset + (CGRectGetHeight(pageRect) - (CGRectGetMaxY(targetRect) - pageRect.origin.y));
		scaledOffsetY = roundf(rectEdgeOffset * zoomScale + CGRectGetMidY(self.pageTurningView.bounds));
	}
	
	return CGPointMake(scaledOffsetX, scaledOffsetY);
}

- (void)zoomToBlock:(BlioTextFlowBlock *)targetBlock visibleRect:(CGRect)visibleRect reversed:(BOOL)reversed context:(void *)context center:(CGPoint)centerPoint {
    
	CGPoint currentTranslation = [self.pageTurningView translation];
	CGFloat currentZoomScale = [self.pageTurningView zoomFactor];
	NSInteger currentPage = self.pageNumber;
	
    NSInteger pageIndex = [targetBlock pageIndex];
	NSArray *pageBlocks = [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:NO];
	BlioTextFlowBlockCombiner *blockCombiner = [[[BlioTextFlowBlockCombiner alloc] initWithTextFlowBlocks:pageBlocks] autorelease];
	blockCombiner.verticalSpacing = [self verticalSpacingForPage:pageIndex + 1];
    
	CGRect combined = [blockCombiner combinedRectForBlock:targetBlock];
	
	CGFloat zoomScale;
	CGPoint translation;
	
	if (!CGPointEqualToPoint(centerPoint, CGPointZero)) {
		// Point is specified
		
		translation = [self translationToFitRect:combined onPage:pageIndex + 1 zoomScale:&zoomScale reversed:reversed];
		CGFloat pointOffset = CGRectGetMidY(self.pageTurningView.bounds) - centerPoint.y;
		translation.y = roundf((pointOffset + currentTranslation.y)/currentZoomScale * zoomScale);		
		
	} else {
		// No point specified - zoom to fit the next part of the block
		
    
		
		CGRect nonVisibleBlockRect = combined;
	
		//NSLog(@"zoom to block (%@) with rect %@ in combined block with rect %@", [NSString stringWithFormat:@"%@ %@...", [(id)[[targetBlock words] objectAtIndex:0] string], [(id)[[targetBlock words] objectAtIndex:1] string]], NSStringFromCGRect([targetBlock rect]), NSStringFromCGRect(combined));
    
		if (self.pageTurningView.zoomFactor > self.pageTurningView.minZoomFactor) {
		// Determine if the combined block is currently partially visible (i.e. it's full width is visible and
		// At least part of it's height is visible - so there is an intersection)
		if ([self blockRect:combined isPartiallyVisibleInRect:visibleRect]) {
			CGRect intersection = CGRectIntersection(visibleRect, combined);
			if (!CGRectIsNull(intersection)) {
				if (!reversed) {
					nonVisibleBlockRect.origin.x = CGRectGetMinX(combined);
					nonVisibleBlockRect.origin.y = MAX(CGRectGetMinY(combined), CGRectGetMaxY(intersection));
					nonVisibleBlockRect.size.width = CGRectGetWidth(combined);
					nonVisibleBlockRect.size.height = CGRectGetMaxY(combined) - nonVisibleBlockRect.origin.y;
				} else {
					nonVisibleBlockRect.origin.x = CGRectGetMinX(combined);
					nonVisibleBlockRect.origin.y = MIN(CGRectGetMinY(combined), CGRectGetMinY(intersection));
					nonVisibleBlockRect.size.width = CGRectGetWidth(combined);
					nonVisibleBlockRect.size.height = MIN(CGRectGetMaxY(combined), CGRectGetMinY(intersection)) - nonVisibleBlockRect.origin.y;
				}
			}
		}
		}

		translation = [self translationToFitRect:nonVisibleBlockRect onPage:pageIndex + 1 zoomScale:&zoomScale reversed:reversed];
	}
	
    if ((pageIndex + 1) != currentPage) {
        if (self.pageTurningView.isTwoUp) {
            if ((self.pageTurningView.leftPageIndex != pageIndex) && (self.pageTurningView.rightPageIndex != pageIndex)) {
                // TODO: Add a way for these to be combined
                [self goToPageNumber:(pageIndex + 1) animated:YES];
                [self.pageTurningView setTranslation:translation zoomFactor:zoomScale animated:YES];
                return;
            }
        } else {
            if (self.pageTurningView.rightPageIndex != pageIndex) {
                // TODO: Add a way for these to be combined
                [self goToPageNumber:(pageIndex + 1) animated:YES];
                [self.pageTurningView setTranslation:translation zoomFactor:zoomScale animated:YES];
                return;
            }
        }
    }
	
	[self.pageTurningView setTranslation:translation zoomFactor:zoomScale animated:NO];
	
	CGPoint newTranslation = self.pageTurningView.translation;
	CGFloat newZoomScale = self.pageTurningView.zoomFactor;
	[self.pageTurningView setTranslation:currentTranslation zoomFactor:currentZoomScale animated:NO];
	
	CGFloat yDifference = newTranslation.y - currentTranslation.y;
	CGFloat xDifference = newTranslation.x - currentTranslation.x;
	CGFloat zoomDifference = newZoomScale - currentZoomScale;
	
	if (zoomDifference || 
		(abs(yDifference) >= CGRectGetHeight(self.pageTurningView.bounds)*0.1f) ||
		(abs(xDifference) >= CGRectGetWidth(self.pageTurningView.bounds)*0.1f)) {
		
		[self.pageTurningView setTranslation:translation zoomFactor:zoomScale animated:YES];
		
	} else if (self.pageNumber != currentPage) {
		[self.pageTurningView setTranslation:translation zoomFactor:zoomScale animated:YES];
	} else {
		if (nil != context) {
			NSInvocation *nextInvocation = (NSInvocation *)context;
			[nextInvocation invoke];
		} else {
			CGRect bounds = self.pageTurningView.bounds;
			BOOL viewIsLandscape = bounds.size.width > bounds.size.height;
			if (viewIsLandscape && !self.pageTurningView.twoUp) {
				[self zoomOutAtPoint:centerPoint];
			} else {
				[self zoomOut];
			}
		}
	}
}

- (void)zoomToFitAllBlocksOnPageTurningViewAtPoint:(CGPoint)point translation:(CGPoint *)translationPtr zoomFactor:(CGFloat *)zoomFactorPtr {
		
	NSArray *rightBlocks = [self.textFlow blocksForPageAtIndex:self.pageTurningView.rightPageIndex includingFolioBlocks:NO];
	CGRect rightRect = [BlioTextFlowBlockCombiner rectByCombiningAllBlocks:rightBlocks];
	CGAffineTransform viewTransform = [self pageTurningViewTransformForPageAtIndex:self.pageTurningView.rightPageIndex offsetOrigin:YES applyZoom:NO];
	CGRect targetRect = CGRectApplyAffineTransform(rightRect, viewTransform);

	if (self.pageTurningView.twoUp) {
		CGRect leftRect = [BlioTextFlowBlockCombiner rectByCombiningAllBlocks:[self.textFlow blocksForPageAtIndex:self.pageTurningView.leftPageIndex includingFolioBlocks:NO]];
		CGAffineTransform viewTransform = [self pageTurningViewTransformForPageAtIndex:self.pageTurningView.leftPageIndex offsetOrigin:YES applyZoom:NO];
		CGRect leftTargetRect = CGRectApplyAffineTransform(leftRect, viewTransform);
		targetRect = CGRectUnion(targetRect, leftTargetRect);
	}
	
	BOOL fitWidth = NO;
	
    CGRect viewBounds = self.pageTurningView.bounds;
    CGFloat zoomScale = MIN(CGRectGetWidth(viewBounds) / CGRectGetWidth(targetRect), CGRectGetHeight(viewBounds) / CGRectGetHeight(targetRect));
    targetRect = CGRectInset(targetRect, -6 / zoomScale, -10 / zoomScale);	
    zoomScale = MIN(CGRectGetWidth(viewBounds) / CGRectGetWidth(targetRect), CGRectGetHeight(viewBounds) / CGRectGetHeight(targetRect));
		
	if (zoomScale < self.pageTurningView.minZoomFactor) {
		zoomScale = CGRectGetWidth(viewBounds) / CGRectGetWidth(targetRect);
		targetRect = CGRectInset(targetRect, -6 / zoomScale, -10 / zoomScale);	
		zoomScale = CGRectGetWidth(viewBounds) / CGRectGetWidth(targetRect);
		fitWidth = YES;
	}
	
	CGPoint translation;
	
	if (zoomScale < self.pageTurningView.minZoomFactor || CGRectIsNull(targetRect)) {
		zoomScale = 1.25f * self.pageTurningView.minZoomFactor;
		translation = CGPointZero;
	} else {
    
		CGRect cropRect = [self cropForPage:self.pageTurningView.rightPageIndex + 1];
		CGRect pageRect = CGRectApplyAffineTransform(cropRect, viewTransform);
		
		CGFloat contentOffsetX = roundf( CGRectGetMidX(self.pageTurningView.bounds) - CGRectGetMidX(targetRect));
		CGFloat scaledOffsetX = contentOffsetX * zoomScale;
	
		CGFloat topOfPageOffset = CGRectGetHeight(pageRect)/2.0f;
	
		CGFloat rectEdgeOffset = topOfPageOffset - (CGRectGetMinY(targetRect) - pageRect.origin.y);
		CGFloat scaledOffsetY = roundf(rectEdgeOffset * zoomScale - CGRectGetMidY(viewBounds));
		
		if (fitWidth) {
			CGFloat topAlignedOffset = CGRectGetMidY(targetRect) * zoomScale - CGRectGetMidY(viewBounds);
			
			CGFloat currentOffset = self.pageTurningView.translation.y / self.pageTurningView.zoomFactor * zoomScale;
			CGFloat insetFromTopOfPage = (topAlignedOffset - currentOffset) / zoomScale;
			
			CGFloat positionYInPage = insetFromTopOfPage + point.y / zoomScale;
			translation = CGPointMake(scaledOffsetX, (CGRectGetMidY(viewBounds) - positionYInPage) * zoomScale);
		} else {
			translation = CGPointMake(scaledOffsetX, scaledOffsetY);
		}
	}
	
	*translationPtr = translation;
	*zoomFactorPtr = zoomScale;
	
}

- (void)zoomToFitAllBlocksOnPageTurningViewAtPoint:(CGPoint)point {
	CGFloat zoomScale;
	CGPoint translation;
	[self zoomToFitAllBlocksOnPageTurningViewAtPoint:point translation:&translation zoomFactor:&zoomScale];
	[self.pageTurningView setTranslation:translation zoomFactor:zoomScale animated:YES];
}
	
- (void)zoomToBlock:(BlioTextFlowBlock *)targetBlock visibleRect:(CGRect)visibleRect reversed:(BOOL)reversed context:(void *)context {
	[self zoomToBlock:targetBlock visibleRect:visibleRect reversed:reversed context:context center:CGPointZero];
}

- (void)zoomOut {
    self.lastBlock = nil;
	[self zoomForNewPageAnimated:YES];
    //[self.pageTurningView setTranslation:CGPointZero zoomFactor:self.pageTurningView.minZoomFactor animated:YES];
}

- (void)zoomOutAtPoint:(CGPoint)point {
	[self zoomOutAtPoint:point animated:YES];
}

- (void)zoomOutAtPoint:(CGPoint)point animated:(BOOL)animated {
	CGRect bounds = self.pageTurningView.bounds;
	
	CGRect rightPageFrame = [self.pageTurningView rightPageFrame];
	CGRect pageFrame;
	
	if (CGRectContainsPoint(rightPageFrame, point)) {
		pageFrame = self.pageTurningView.unzoomedRightPageFrame;
	} else{
		pageFrame = self.pageTurningView.unzoomedLeftPageFrame;
	}
	
	CGFloat zoomFactor = self.pageTurningView.minZoomFactor;
	CGFloat topAlignedOffset = CGRectGetMidY(pageFrame) * zoomFactor - CGRectGetMidY(bounds);
	
	CGFloat currentOffset = self.pageTurningView.translation.y / self.pageTurningView.zoomFactor * zoomFactor;
	CGFloat insetFromTopOfPage = (topAlignedOffset - currentOffset) / zoomFactor;
	
	CGPoint offset;
	
	CGFloat positionYInPage = insetFromTopOfPage + point.y / zoomFactor;
	offset = CGPointMake(0, (CGRectGetMidY(bounds) - positionYInPage) * zoomFactor); 
		
	[self.pageTurningView setTranslation:offset zoomFactor:zoomFactor animated:animated];
}

- (void)advanceOrZoomOutAtPoint:(CGPoint)point {
	CGFloat zoomScale;
	CGPoint translation;
	[self zoomToFitAllBlocksOnPageTurningViewAtPoint:point translation:&translation zoomFactor:&zoomScale];
	
	CGPoint currentTranslation = self.pageTurningView.translation;
	CGFloat currentZoomScale = self.pageTurningView.zoomFactor;
	
	[self.pageTurningView setTranslation:translation zoomFactor:zoomScale animated:NO];
	
	CGPoint newTranslation = self.pageTurningView.translation;
	[self.pageTurningView setTranslation:currentTranslation zoomFactor:currentZoomScale animated:NO];
	
	CGFloat difference = newTranslation.y - currentTranslation.y;
	
	if (abs(difference) >= CGRectGetHeight(self.pageTurningView.bounds)*0.1f) {
		[self.pageTurningView setTranslation:translation zoomFactor:zoomScale animated:YES];
	} else {
		[self zoomOutAtPoint:point];
	}
}

- (void)zoomOutsideBlockAtPoint:(CGPoint)point zoomFactor:(CGFloat)zoomFactor {
	self.lastBlock = nil;
    
    CGPoint offset = CGPointMake((CGRectGetMidX(self.pageTurningView.bounds) - point.x) * zoomFactor, (CGRectGetMidY(self.pageTurningView.bounds) - point.y) * zoomFactor); 
	[self.pageTurningView setTranslation:offset zoomFactor:zoomFactor animated:YES];
}

- (void)zoomForNewPageAnimated:(BOOL)animated
{
	EucPageTurningView *myPageTurningView = self.pageTurningView;
    CGRect bounds = myPageTurningView.bounds;
    
    BOOL viewIsLandscape = bounds.size.width > bounds.size.height;

    CGFloat zoomFactor;
	
	if(!viewIsLandscape || myPageTurningView.isTwoUp) {
        zoomFactor = 1.0f;
    } else {
        zoomFactor = myPageTurningView.fitToBoundsZoomFactor;
    }
	
	myPageTurningView.minZoomFactor = zoomFactor;
	
    CGPoint offset = CGPointMake(0, CGRectGetMidY(bounds) * zoomFactor); 
	[myPageTurningView setTranslation:offset zoomFactor:zoomFactor animated:animated];
}

- (void)zoomForNewPageAnimatedWithNumberThunk:(NSNumber *)number
{
    [self zoomForNewPageAnimated:[number boolValue]];
}

- (void)decrementPage
{
    NSUInteger wantPageIndex = NSUIntegerMax;
    if (self.pageTurningView.isTwoUp) {
        wantPageIndex = self.pageTurningView.leftPageIndex;
        if(wantPageIndex != NSUIntegerMax) {
            if(wantPageIndex >= 2) {
                // Subtract 2 so that the focused page after the turn is
                // on the right.
                wantPageIndex -= 2;
            } else if(wantPageIndex > 0) {
                --wantPageIndex;
            } else {
                // Already at index 0, can't turn.
                wantPageIndex = NSUIntegerMax;
            }
        }
    } else {
        wantPageIndex = self.pageTurningView.rightPageIndex;
        if(wantPageIndex != NSUIntegerMax) {
            if(wantPageIndex > 0) {
                --wantPageIndex;
            } else {
                // Already at index 0, can't turn.
                wantPageIndex = NSUIntegerMax;
            }
        }                
    }
    if(wantPageIndex != NSUIntegerMax) {
        [self goToPageNumber:wantPageIndex + 1 animated:YES];
    }
}

- (void)incrementPage
{
    NSUInteger wantPageIndex = self.pageTurningView.rightPageIndex;
    if(wantPageIndex != NSUIntegerMax) {
        ++wantPageIndex;
    }
    if(wantPageIndex != NSUIntegerMax && 
       wantPageIndex < self.pageCount) {
        [self goToPageNumber:wantPageIndex + 1 animated:YES];
    }
}

@end 