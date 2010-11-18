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
#import <libEucalyptus/THPair.h>
#import "UIDevice+BlioAdditions.h"
#import "BlioTextFlowBlockCombiner.h"
#import "BlioLayoutPDFDataSource.h"
#import "BlioLayoutGeometry.h"
#import "BlioLayoutHyperlink.h"
#import "BlioAppSettingsConstants.h"

#define PAGEHEIGHTRATIO_FOR_BLOCKCOMBINERVERTICALSPACING (1/30.0f)
#define BLIOLAYOUT_LHSHOTZONE (1.0f/10*1)
#define BLIOLAYOUT_RHSHOTZONE (1.0f/10*9)

@interface BlioLayoutView()

@property (nonatomic, assign) NSInteger pageNumber;
@property (nonatomic, assign) CGSize pageSize;
@property (nonatomic, retain) id<BlioLayoutDataSource> dataSource;
@property (nonatomic, retain) UIImage *pageTexture;
@property (nonatomic, assign) BOOL pageTextureIsDark;
@property (nonatomic, retain) BlioTextFlowBlock *lastBlock;
@property (nonatomic, retain) BlioBookmarkRange *temporaryHighlightRange;
@property (nonatomic, retain) NSTimer *delayedTouchesBeganTimer;
@property (nonatomic, retain) NSTimer *delayedTouchesEndedTimer;
@property (nonatomic, retain) NSArray *accessibilityElements;
@property (nonatomic, retain) UIAccessibilityElement *prevZone;
@property (nonatomic, retain) UIAccessibilityElement *nextZone;
@property (nonatomic, retain) UIAccessibilityElement *pageZone;

- (CGRect)cropForPage:(NSInteger)page;
- (CGRect)cropForPage:(NSInteger)page allowEstimate:(BOOL)estimate;

- (CGAffineTransform)pageTurningViewTransformForPageAtIndex:(NSInteger)page;
- (CGAffineTransform)pageTurningViewTransformForPageAtIndex:(NSInteger)pageIndex offsetOrigin:(BOOL)offset applyZoom:(BOOL)zoom;

- (NSArray *)bookmarkRangesForCurrentPage;
- (EucSelectorRange *)selectorRangeFromBookmarkRange:(BlioBookmarkRange *)range;
- (BlioBookmarkRange *)bookmarkRangeFromSelectorRange:(EucSelectorRange *)range;

- (BOOL)touchesShouldBeSuppressed;
- (void)handleSingleTapAtPoint:(CGPoint)point;
- (void)handleDoubleTapAtPoint:(CGPoint)point;

- (NSArray *)hyperlinksForPage:(NSInteger)page;
- (BlioLayoutHyperlink *)hyperlinkForPage:(NSInteger)page atPoint:(CGPoint)point;
- (void)hyperlinkTapped:(NSString *)link;

- (BlioBookmarkRange *)noteBookmarkForPage:(NSInteger)page atPoint:(CGPoint)point;
- (void)showNoteForBookmark:(BlioBookmarkRange *)bookmark;

- (CGRect)visibleRectForPageAtIndex:(NSInteger)pageIndex;
- (void)zoomAtPoint:(CGPoint)point;
- (void)zoomToPreviousBlock;
- (void)zoomToNextBlock;
- (void)zoomToNextBlockReversed:(BOOL)reversed;
- (void)zoomToBlock:(BlioTextFlowBlock *)targetBlock visibleRect:(CGRect)visibleRect reversed:(BOOL)reversed context:(void *)context;
- (void)zoomToBlock:(BlioTextFlowBlock *)targetBlock visibleRect:(CGRect)visibleRect reversed:(BOOL)reversed context:(void *)context center:(CGPoint)centerPoint;
- (void)zoomOut;
- (void)zoomOutAtPoint:(CGPoint)point;
- (void)advanceOrZoomOutAtPoint:(CGPoint)point;
- (void)zoomOutsideBlockAtPoint:(CGPoint)point zoomFactor:(CGFloat)zoomFactor;
- (void)zoomForNewPageAnimated:(BOOL)animated;
- (void)zoomForNewPageAnimatedWithNumberThunk:(NSNumber *)animated;
- (void)zoomToFitAllBlocksOnPageTurningViewAtPoint:(CGPoint)point;
- (void)zoomToFitAllBlocksOnPageTurningViewAtPoint:(CGPoint)point translation:(CGPoint *)translationPtr zoomFactor:(CGFloat *)zoomFactorPtr;

@end

@implementation BlioLayoutView

@synthesize bookID, textFlow, pageNumber, pageCount, selector, pageSize;
@synthesize pageCropsCache, viewTransformsCache, hyperlinksCache;
@synthesize dataSource;
@synthesize pageTurningView, pageTexture, pageTextureIsDark;
@synthesize lastBlock;
@synthesize delayedTouchesBeganTimer, delayedTouchesEndedTimer;
@synthesize accessibilityElements, prevZone, nextZone, pageZone;
@synthesize temporaryHighlightRange;

- (void)dealloc {
    [self.delayedTouchesBeganTimer invalidate];
    self.delayedTouchesBeganTimer = nil;
	
	[self.delayedTouchesEndedTimer invalidate];
	self.delayedTouchesEndedTimer = nil;
    
    self.pageCropsCache = nil;
    self.hyperlinksCache = nil;
    self.viewTransformsCache = nil;
    self.lastBlock = nil;
	self.temporaryHighlightRange = nil;
    
    self.pageTurningView = nil;
    self.pageTexture = nil;
        
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
    
    self.delegate = nil;
    
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
        EucPageTurningView *aPageTurningView = [[EucPageTurningView alloc] initWithFrame:self.bounds];
        aPageTurningView.delegate = self;
        aPageTurningView.bitmapDataSource = self;
        aPageTurningView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        aPageTurningView.zoomHandlingKind = EucPageTurningViewZoomHandlingKindZoom;
		
        // Must do this here so that teh page aspect ration takes account of the twoUp property
        CGRect myBounds = self.bounds;
        if(myBounds.size.width > myBounds.size.height) {
            aPageTurningView.twoUp = YES;
        } else {
            aPageTurningView.twoUp = NO;
        } 
        
        if (CGRectEqualToRect(firstPageCrop, CGRectZero)) {
            [aPageTurningView setPageAspectRatio:0];
        } else {
            [aPageTurningView setPageAspectRatio:firstPageCrop.size.width/firstPageCrop.size.height];
        }
        
        [self addSubview:aPageTurningView];
        self.pageTurningView = aPageTurningView;
        [aPageTurningView release];

        [aPageTurningView turnToPageAtIndex:self.pageNumber - 1 animated:NO];
		[aPageTurningView waitForAllPageImagesToBeAvailable];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:kBlioLandscapeTwoPagesDefaultsKey
                                                   options:0
                                                   context:NULL];
        
    }
}

- (void)didMoveToSuperview
{
    if(self.superview) {
        EucSelector *aSelector = [[EucSelector alloc] init];
        aSelector.shouldSniffTouches = YES;
        aSelector.dataSource = self;
        aSelector.delegate =  self;
        [aSelector attachToView:self];
        [aSelector addObserver:self forKeyPath:@"tracking" options:0 context:NULL];
        self.selector = aSelector;
        [aSelector release];   
    } else {
        EucPageTurningView *aPageTurningView = self.pageTurningView;
        if(aPageTurningView) {
            aPageTurningView.bitmapDataSource = nil;
            aPageTurningView.delegate = nil;
            [aPageTurningView removeFromSuperview];
            self.pageTurningView = nil;
            [[NSUserDefaults standardUserDefaults] removeObserver:self
                                                       forKeyPath:kBlioLandscapeTwoPagesDefaultsKey];
        }
    }
}

- (void)layoutSubviews {
    CGRect myBounds = self.bounds;
    if([[NSUserDefaults standardUserDefaults] boolForKey:kBlioLandscapeTwoPagesDefaultsKey] && 
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
		self.pageSize = newSize;
        // Perform this after a delay in order to give time for layoutSubviews 
        // to be called on the pageTurningView before we start the zoom
        // (Ick!).
        [self performSelector:@selector(zoomForNewPageAnimatedWithNumberThunk:) withObject:[NSNumber numberWithBool:NO] afterDelay:0.0f];;
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if(self.selector) {
        [self.selector removeObserver:self forKeyPath:@"tracking"];
        [self.selector detatch];
        self.selector = nil;
    }
	self.temporaryHighlightRange = nil;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	self.lastBlock = nil;
	self.accessibilityElements = nil;
	
	EucSelector *aSelector = [[EucSelector alloc] init];
	aSelector.shouldSniffTouches = YES;
	aSelector.dataSource = self;
	aSelector.delegate =  self;
	[aSelector attachToView:self];
	[aSelector addObserver:self forKeyPath:@"tracking" options:0 context:NULL];
	self.selector = aSelector;
	[aSelector release];
}

#pragma mark -
#pragma mark EucPageTurningViewBitmapDataSource

- (CGRect)pageTurningView:(EucPageTurningView *)aPageTurningView contentRectForPageAtIndex:(NSUInteger)index {
    return [self cropForPage:index + 1];
}

- (CGContextRef)pageTurningView:(EucPageTurningView *)aPageTurningView 
RGBABitmapContextForPageAtIndex:(NSUInteger)index
                       fromRect:(CGRect)rect 
                        minSize:(CGSize)size 
                     getContext:(id *)context {
    return [self.dataSource RGBABitmapContextForPage:index + 1
                                            fromRect:rect 
                                             minSize:size
                                          getContext:context];
}

- (UIImage *)pageTurningView:(EucPageTurningView *)aPageTurningView 
   fastUIImageForPageAtIndex:(NSUInteger)index {
    return [self.dataSource thumbnailForPage:index + 1];
}

#pragma mark -
#pragma mark Visual Properties

- (void)setPageNumber:(NSInteger)newPageNumber {
	pageNumber = newPageNumber;
	self.selector.selectedRange = nil;
	self.accessibilityElements = nil;
}

- (void)setPageTexture:(UIImage *)aPageTexture isDark:(BOOL)isDarkIn { 
    if(self.pageTexture != aPageTexture || self.pageTextureIsDark != isDarkIn) {
        [self.pageTurningView setPageTexture:aPageTexture isDark:isDarkIn];
        [self.pageTurningView setNeedsDraw];
        self.pageTexture = aPageTexture;
        self.pageTextureIsDark = isDarkIn;
    }
}

- (BOOL)wantsTouchesSniffed {
    return YES;
}

- (BlioBookmarkPoint *)currentBookmarkPoint {
    BlioBookmarkPoint *ret = [[BlioBookmarkPoint alloc] init];
    ret.layoutPage = MAX(self.pageNumber, 1);
    return [ret autorelease];
}

- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated {
    [self goToPageNumber:[self.textFlow pageNumberForSectionUuid:uuid] animated:animated];
}

- (void)goToPageNumber:(NSInteger)targetPage animated:(BOOL)animated {
	BlioBookmarkPoint *bookmarkPoint = [[[BlioBookmarkPoint alloc] init] autorelease];
    bookmarkPoint.layoutPage = targetPage;
    [self goToBookmarkPoint:bookmarkPoint animated:animated];
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
	
}

- (void)goToBookmarkRange:(BlioBookmarkRange *)bookmarkRange animated:(BOOL)animated {
    [self goToBookmarkPoint:bookmarkRange.startPoint animated:animated];
}

- (NSInteger)pageNumberForBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint {
    return bookmarkPoint.layoutPage;
}

- (NSInteger)pageNumberForBookmarkRange:(BlioBookmarkRange *)bookmarkRange {
    return bookmarkRange.startPoint.layoutPage;
}

- (NSString *)pageLabelForPageNumber:(NSInteger)page {
    NSString *ret = nil;
    
    BlioTextFlow *myTextFlow = self.textFlow;
    NSString* section = [myTextFlow sectionUuidForPageNumber:page];
    THPair* chapter = [myTextFlow presentationNameAndSubTitleForSectionUuid:section];
    NSString* pageStr = [myTextFlow displayPageNumberForPageNumber:page];

    if (section && chapter.first) {
        if (pageStr) {
            ret = [NSString stringWithFormat:@"Page %@ \u2013 %@", pageStr, chapter.first];
        } else {
            ret = [NSString stringWithFormat:@"%@", chapter.first];
        }
    } else {
        if (pageStr) {
            ret = [NSString stringWithFormat:@"Page %@ of %lu", pageStr, (unsigned long)self.pageCount];
        } else {
            ret = [[BlioBookManager sharedBookManager] bookWithID:self.bookID].title;
        }
    } // of no section name
    
    return ret;
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
    
    CGRect cropRect = [self.dataSource cropRectForPage:page];
    if (!CGRectEqualToRect(cropRect, CGRectZero)) {
        [self.pageCropsCache setObject:[NSValue valueWithCGRect:cropRect] forKey:[NSNumber numberWithInt:page]];
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
		BOOL rightIsEven = (self.pageTurningView.rightPageIndex % 2 == 0);
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
    
    CGFloat dpiRatio = [self.dataSource dpiRatio];
    
    if (dpiRatio != 1) {
        CGAffineTransform dpiScale = CGAffineTransformMakeScale(dpiRatio, dpiRatio);
        
        CGRect mediaRect = [self.dataSource mediaRectForPage:pageIndex + 1];
        CGAffineTransform mediaAdjust = CGAffineTransformMakeTranslation(pageCrop.origin.x - mediaRect.origin.x, pageCrop.origin.y - mediaRect.origin.y);
        CGAffineTransform textTransform = CGAffineTransformConcat(dpiScale, mediaAdjust);
        CGAffineTransform viewTransform = CGAffineTransformConcat(textTransform, pageTransform);
        return viewTransform;
    }
        
    return pageTransform;
}

- (CGAffineTransform)pageTurningViewTransformForPageAtIndex:(NSInteger)pageIndex {
    return [self pageTurningViewTransformForPageAtIndex:pageIndex offsetOrigin:YES applyZoom:YES];
}

#pragma mark -
#pragma mark Status callbacks

- (void)pageTurningViewWillBeginAnimating:(EucPageTurningView *)aPageTurningView
{
    self.selector.selectionDisabled = YES;
    [self.delegate cancelPendingToolbarShow];
	[self.selector removeTemporaryHighlight];
	pageViewIsTurning = YES;
}

- (void)pageTurningViewDidEndAnimation:(EucPageTurningView *)aPageTurningView
{
    NSUInteger pageIndex = aPageTurningView.focusedPageIndex;
    if(self.pageNumber != pageIndex + 1) {
		if (!suppressHistoryAfterTurn) {
			[self pushCurrentBookmarkPoint];
		}
        self.pageNumber = pageIndex + 1;
    }
	
    self.selector.selectionDisabled = NO;
    pageViewIsTurning = NO;
	suppressHistoryAfterTurn = NO;
	
    if(self.temporaryHighlightRange) {
		NSInteger targetIndex = self.temporaryHighlightRange.startPoint.layoutPage - 1;
		
        if((self.pageTurningView.leftPageIndex == targetIndex) || (self.pageTurningView.rightPageIndex == targetIndex)) {
            EucSelectorRange *range = [self selectorRangeFromBookmarkRange:self.temporaryHighlightRange];
			[self.selector temporarilyHighlightSelectorRange:range animated:YES];
        }
				
		self.temporaryHighlightRange = nil;
    }
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

#pragma mark -
#pragma mark Selector

- (UIImage *)viewSnapshotImageForEucSelector:(EucSelector *)selector {
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
    
    NSArray *endPageBlocks = [self.textFlow blocksForPageAtIndex:[self.pageTurningView rightPageIndex] includingFolioBlocks:NO];
    NSUInteger maxOffset = [endPageBlocks count];
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
        self.pageTurningView.userInteractionEnabled = !((EucSelector *)object).isTracking;
    } else if(object == [NSUserDefaults standardUserDefaults]) {
        if([keyPath isEqualToString:kBlioLandscapeTwoPagesDefaultsKey]) {
            BOOL wasTwoUp = self.pageTurningView.twoUp;
            BOOL shouldBeTwoUp = NO;
            CGRect myBounds = self.bounds;
            if([[NSUserDefaults standardUserDefaults] boolForKey:kBlioLandscapeTwoPagesDefaultsKey] && 
               myBounds.size.width > myBounds.size.height) {
                shouldBeTwoUp = YES;        
            }
            if(shouldBeTwoUp != wasTwoUp) {
                self.pageTurningView.twoUp = shouldBeTwoUp;
                [self.pageTurningView layoutSubviews];
                [self zoomForNewPageAnimated:NO];
            }
        }
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

- (NSArray *)pageTurningView:(EucPageTurningView *)pageTurningView highlightsForPageAtIndex:(NSUInteger)pageIndex {

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
    return self.textFlow;
}

#pragma mark -
#pragma mark Touch Handling

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if ([self pointInside:point withEvent:event]) {
        return self;
    } else {
        return nil;
    }
}

- (BOOL)touchesShouldBeSuppressed {
	return YES;
    //if (hyperlinkTapped || pageViewIsTurning || self.selector.tracking || self.selector.selectedRange) {
//        hyperlinkTapped = NO;
//        return YES;
//    } else {
//        return NO;
    //}
}

- (void)delayedTouchesBegan:(NSTimer *)timer {
    startTouchPoint = CGPointMake(-1, -1);

    NSDictionary *touchesAndEvent = [timer userInfo];
    [self.pageTurningView touchesBegan:[touchesAndEvent valueForKey:@"touches"] withEvent:[touchesAndEvent valueForKey:@"event"]];
    self.delayedTouchesBeganTimer = nil;
	
	self.lastBlock = nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {   	
	if (([touches count] == 1) 
        && ([[touches anyObject] tapCount] > 1) 
        && !self.pageTurningView.animating) {
		// Double-tap.  (Ignore double-taps if the page is animating)
		if (self.delayedTouchesBeganTimer != nil) {
			[self.delayedTouchesBeganTimer invalidate];
			self.delayedTouchesBeganTimer = nil;
		} else {
			if (!CGPointEqualToPoint(startTouchPoint, CGPointMake(-1, -1))) {
				[self.pageTurningView touchesCancelled:touches withEvent:event];
			}
		}
		
		startTouchPoint = [[touches anyObject] locationInView:self];
		
    } else if ([[event touchesForView:self] count] > 1) {
        startTouchPoint = CGPointMake(-1, -1);
        [self.delayedTouchesBeganTimer fire];
        self.delayedTouchesBeganTimer = nil;
        [self.pageTurningView touchesBegan:touches withEvent:event];
    } else {
        if(self.pageTurningView.animating) {
            // If there's a page-turn in progress (probably a user-initiated
            // one 'drifting' due to gravity), pass the touch immediately
            // so that the user can 'grab' the falling page.
            startTouchPoint = CGPointMake(-1, -1);
            [self.delayedTouchesBeganTimer fire];
            self.delayedTouchesBeganTimer = nil;
            [self.pageTurningView touchesBegan:touches withEvent:event];
        } else {
            [self.delayedTouchesBeganTimer invalidate];
            self.delayedTouchesBeganTimer = nil;
            
            startTouchPoint = [[touches anyObject] locationInView:self];
            NSDictionary *touchesAndEvent = [NSDictionary dictionaryWithObjectsAndKeys:touches, @"touches", event, @"event", nil];
            self.delayedTouchesBeganTimer = [NSTimer scheduledTimerWithTimeInterval:0.31f target:self selector:@selector(delayedTouchesBegan:) userInfo:touchesAndEvent repeats:NO];
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    startTouchPoint = CGPointMake(-1, -1);
    
    [self.delayedTouchesBeganTimer fire];
    self.delayedTouchesBeganTimer = nil;

    [self.pageTurningView touchesMoved:touches withEvent:event];
}

- (void)delayedTouchesEnded:(NSTimer *)timer {

    startTouchPoint = CGPointMake(-1, -1);
	
    NSDictionary *touchesInfo = [timer userInfo];
	NSString *link = [touchesInfo valueForKey:@"link"];
	BlioBookmarkRange *noteBookmark = [touchesInfo valueForKey:@"noteBookmark"];
	
	if (noteBookmark != (id)[NSNull null]) {
		[self showNoteForBookmark:noteBookmark];
	} else if (link != (id)[NSNull null]) {
		[self hyperlinkTapped:link];
	} else {
		[self handleSingleTapAtPoint:[[[touchesInfo valueForKey:@"touches"] anyObject] locationInView:self]];
	}
	
	self.delayedTouchesEndedTimer = nil;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

	[self.delayedTouchesEndedTimer invalidate];
    self.delayedTouchesEndedTimer = nil;
	
    [self.delayedTouchesBeganTimer invalidate];
    self.delayedTouchesBeganTimer = nil;
    
    BlioLayoutHyperlink *touchedHyperlink = nil;
	BlioBookmarkRange *touchedNoteBookmark = nil;
	
    CGPoint point = [[touches anyObject] locationInView:self];
    
    if (!CGPointEqualToPoint(startTouchPoint, CGPointMake(-1, -1))) {
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
		
		if (([touches count] == 1) && ([[touches anyObject] tapCount] == 2)) {
			// Double-tap			
			[self handleDoubleTapAtPoint:startTouchPoint];
			return;
        } else if (self.selector.tracking || self.selector.selectedRange) {
            return;
        }
		
		NSDictionary *touchesInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 touches, @"touches", 
									 event, @"event", 
									 [touchedHyperlink link] ? : (id)[NSNull null], @"link", 
									 touchedNoteBookmark ? : (id)[NSNull null], @"noteBookmark", 
									 nil];
		
        self.delayedTouchesEndedTimer = [NSTimer scheduledTimerWithTimeInterval:0.3f target:self selector:@selector(delayedTouchesEnded:) userInfo:touchesInfo repeats:NO];
		
    } else {
        [self.pageTurningView touchesEnded:touches withEvent:event];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.delayedTouchesBeganTimer invalidate];
    self.delayedTouchesBeganTimer = nil;
    
    CGPoint point = [[touches anyObject] locationInView:self];
    
    if (!CGPointEqualToPoint(point, startTouchPoint)) {
        [self.pageTurningView touchesCancelled:touches withEvent:event];
    }
}

- (void)handleSingleTapAtPoint:(CGPoint)point {
	
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
		if (focusedElement == self.prevZone) {
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
				return;
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
				return;
			}
		} else if (focusedElement == self.nextZone) {
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

- (void)handleDoubleTapAtPoint:(CGPoint)point {
	BOOL performZoom = YES;
	if (UIAccessibilityIsVoiceOverRunning != nil) {
		if (UIAccessibilityIsVoiceOverRunning()) {
			performZoom = NO;
		}
	}
	if (performZoom) {
        [self zoomAtPoint:point];
		[self.delegate hideToolbars];
	} else {
        [self.delegate toggleToolbars]; 
    }
}

#pragma mark -
#pragma mark Actions

- (void)showNoteForBookmark:(BlioBookmarkRange *)bookmarkRange {
	//EucSelectorRange *selectedRange = [self selectorRangeFromBookmarkRange:bookmarkRange];
	//[self.selector setSelectedRange:selectedRange];
	[self.delegate updateHighlightNoteAtRange:bookmarkRange toRange:nil withColor:nil];
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
    hyperlinkTapped = YES;
    BlioTextFlowReference *reference = [self.textFlow referenceForReferenceId:link];
    
    if (reference) {
        [self goToPageNumber:reference.pageIndex + 1 animated:YES];
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

- (NSArray *)textBlockAccessibilityElements {
    NSMutableArray *elements = [NSMutableArray array];
	
    NSInteger pageIndex = self.pageTurningView.leftPageIndex;
    if(pageIndex != NSUIntegerMax) {
        CGAffineTransform viewTransform = [self pageTurningViewTransformForPageAtIndex:pageIndex];
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
        CGAffineTransform viewTransform = [self pageTurningViewTransformForPageAtIndex:pageIndex];
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

- (NSArray *)accessibilityElements
{
    if(!accessibilityElements) {
        accessibilityElements = [[NSMutableArray arrayWithArray:[self textBlockAccessibilityElements]] retain];

        CGFloat tapZoneWidth = 0.1f * self.pageTurningView.bounds.size.width;
		
        {
            UIAccessibilityElement *nextPageTapZone = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
            nextPageTapZone.accessibilityTraits = UIAccessibilityTraitButton;
            if (self.pageTurningView.rightPageIndex >= (self.pageCount - 1))  {
                nextPageTapZone.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
            }            
            CGRect frame = self.pageTurningView.bounds;
            frame.origin.x = frame.size.width + frame.origin.x - tapZoneWidth;
            frame.size.width = tapZoneWidth;
			frame = [self.window.layer convertRect:frame fromLayer:self.pageTurningView.layer];

            nextPageTapZone.accessibilityFrame = frame;
            nextPageTapZone.accessibilityLabel = NSLocalizedString(@"Next Page", @"Accessibility title for previous page tap zone");
			self.nextZone = nextPageTapZone;
            [accessibilityElements addObject:nextPageTapZone];            
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
            
            CGRect frame = self.pageTurningView.bounds;
            frame.size.width = tapZoneWidth;
			frame = [self.window.layer convertRect:frame fromLayer:self.pageTurningView.layer];

            previousPageTapZone.accessibilityFrame = frame;
            previousPageTapZone.accessibilityLabel = NSLocalizedString(@"Previous Page", @"Accessibility title for next page tap zone");
            [accessibilityElements addObject:previousPageTapZone];
			self.prevZone = previousPageTapZone;
            [previousPageTapZone release];
        }        
		
        {
            CGRect frame = self.pageTurningView.bounds;
            frame.origin.y = 0;
            frame.size.height = tapZoneWidth;
            frame.size.width -= 2 * tapZoneWidth;
            frame.origin.x += tapZoneWidth;
			frame = [self.window.layer convertRect:frame fromLayer:self.pageTurningView.layer];

			
            UIAccessibilityElement *toolbarTapButton = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
            toolbarTapButton.accessibilityFrame = frame;
            toolbarTapButton.accessibilityLabel = NSLocalizedString(@"Book Page", @"Accessibility title for book page tap zone");
            toolbarTapButton.accessibilityHint = NSLocalizedString(@"Double tap to return to controls.", @"Accessibility title for previous page tap zone");
            self.pageZone = toolbarTapButton;
            [accessibilityElements addObject:toolbarTapButton];
            [toolbarTapButton release];
        }
		
	}
	
	if (self.pageTurningView.zoomFactor > 1) {
		[self.pageTurningView setTranslation:CGPointZero zoomFactor:1 animated:YES];
	}
	
    return accessibilityElements;
}

- (NSInteger)accessibilityElementCount
{
    return [[self accessibilityElements] count];
}

- (id)accessibilityElementAtIndex:(NSInteger)index
{
    return [[self accessibilityElements] objectAtIndex:index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
    return [[self accessibilityElements] indexOfObject:element];
}

- (CGRect)accessibilityFrame
{
    CGRect bounds;
    if([self.delegate respondsToSelector:@selector(nonToolbarRect)]) {
        bounds = [self.delegate nonToolbarRect];
    } else {
        bounds = self.bounds;
    }
    return [self convertRect:bounds toView:nil];
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
    if([self.delegate respondsToSelector:@selector(toolbarsVisible)]) {
        return [self.delegate toolbarsVisible];
    } else {
        return NO;
    }
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
	
	CGRect bounds = self.pageTurningView.bounds;
	
	CGRect rightPageFrame = [self.pageTurningView rightPageFrame];
	CGRect pageFrame;
	
	if (CGRectContainsPoint(rightPageFrame, point)) {
		pageFrame = self.pageTurningView.unzoomedRightPageFrame;
	} else{
		pageFrame = self.pageTurningView.unzoomedLeftPageFrame;
	}
	
	CGFloat zoomFactor = self.pageTurningView.fitToBoundsZoomFactor;
	CGFloat topAlignedOffset = CGRectGetMidY(pageFrame) * zoomFactor - CGRectGetMidY(bounds);

	CGFloat currentOffset = self.pageTurningView.translation.y / self.pageTurningView.zoomFactor * zoomFactor;
	CGFloat insetFromTopOfPage = (topAlignedOffset - currentOffset) / zoomFactor;
	
	CGFloat positionYInPage = insetFromTopOfPage + point.y / zoomFactor;
    CGPoint offset = CGPointMake(0, (CGRectGetMidY(bounds) - positionYInPage) * zoomFactor); 

	[self.pageTurningView setTranslation:offset zoomFactor:zoomFactor animated:YES];

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
    CGRect pagesFrame;
    if(self.pageTurningView.isTwoUp) {
        pagesFrame = CGRectUnion(self.pageTurningView.unzoomedLeftPageFrame, self.pageTurningView.unzoomedRightPageFrame);
    } else {
        pagesFrame = self.pageTurningView.unzoomedRightPageFrame;
    }
    BOOL pageAreLandscape = pagesFrame.size.width > pagesFrame.size.height;
    
    CGFloat zoomFactor;
    if(pageAreLandscape == viewIsLandscape) {
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

@end

