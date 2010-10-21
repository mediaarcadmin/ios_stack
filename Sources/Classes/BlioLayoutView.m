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

#define PAGEHEIGHTRATIO_FOR_BLOCKCOMBINERVERTICALSPACING (1/30.0f)
#define BLIOLAYOUT_LHSHOTZONE (1.0f/3*1)
#define BLIOLAYOUT_RHSHOTZONE (1.0f/3*2)

@interface BlioPageTurningAnimator : CALayer {
    CGFloat zoomFactor;
}

@property (nonatomic, assign) CGFloat zoomFactor;

@end

@interface BlioLayoutView()

@property (nonatomic, assign) NSInteger pageNumber;
@property (nonatomic, assign) CGSize pageSize;
@property (nonatomic, retain) id<BlioLayoutDataSource> dataSource;
@property (nonatomic, retain) UIImage *pageTexture;
@property (nonatomic, assign) BOOL pageTextureIsDark;
@property (nonatomic, retain) BlioTextFlowBlock *lastBlock;
@property (nonatomic, retain) NSTimer *delayedTouchesBeganTimer;
@property (nonatomic, retain) NSTimer *delayedTouchesEndedTimer;

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

- (CGRect)visibleRectForPageAtIndex:(NSInteger)pageIndex;
- (void)zoomAtPoint:(CGPoint)point;
- (void)zoomToPreviousBlock;
- (void)zoomToNextBlock;
- (void)zoomToNextBlockReversed:(BOOL)reversed;
- (void)zoomToBlock:(BlioTextFlowBlock *)targetBlock visibleRect:(CGRect)visibleRect reversed:(BOOL)reversed context:(void *)context;
- (void)zoomToBlock:(BlioTextFlowBlock *)targetBlock visibleRect:(CGRect)visibleRect reversed:(BOOL)reversed context:(void *)context center:(CGPoint)centerPoint;
- (void)zoomOut;
- (void)zoomOutsideBlockAtPoint:(CGPoint)point;

@end

@implementation BlioLayoutView

@synthesize bookID, textFlow, pageNumber, pageCount, selector, pageSize;
@synthesize pageCropsCache, viewTransformsCache, hyperlinksCache;
@synthesize dataSource;
@synthesize pageTurningView, pageTexture, pageTextureIsDark;
@synthesize lastBlock;
@synthesize delayedTouchesBeganTimer, delayedTouchesEndedTimer;

- (void)dealloc {
    [self.delayedTouchesBeganTimer invalidate];
    self.delayedTouchesBeganTimer = nil;
	
	[self.delayedTouchesEndedTimer invalidate];
	self.delayedTouchesEndedTimer = nil;
    
    self.textFlow = nil;
    self.pageCropsCache = nil;
    self.hyperlinksCache = nil;
    self.viewTransformsCache = nil;
    self.lastBlock = nil;
    
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
        
    [super dealloc];
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    NSLog(@"Did receive memory warning");
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
        self.pageSize = self.bounds.size;
        
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

        NSInteger page = aBook.implicitBookmarkPoint.layoutPage;
        if (page > self.pageCount) page = self.pageCount;
        self.pageNumber = page;
        
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
        
        // Must do this here so that teh page aspect ration takes account of the fitTwoPages property
        CGRect myBounds = self.bounds;
        if(myBounds.size.width > myBounds.size.height) {
            aPageTurningView.fitTwoPages = YES;
            aPageTurningView.twoSidedPages = YES;
        } else {
            aPageTurningView.fitTwoPages = NO;
            aPageTurningView.twoSidedPages = NO;
        } 
        
        if (CGRectEqualToRect(firstPageCrop, CGRectZero)) {
            [aPageTurningView setPageAspectRatio:0];
        } else {
            [aPageTurningView setPageAspectRatio:firstPageCrop.size.width/firstPageCrop.size.height];
        }        
        [self addSubview:aPageTurningView];
        
        self.pageTurningView = aPageTurningView;
        [aPageTurningView release];
        
        [aPageTurningView addObserver:self forKeyPath:@"leftPageFrame" options:0 context:NULL];
        [aPageTurningView addObserver:self forKeyPath:@"rightPageFrame" options:0 context:NULL];        
        
        [aPageTurningView turnToPageAtIndex:self.pageNumber - 1 animated:NO];
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
            [aPageTurningView removeObserver:self forKeyPath:@"leftPageFrame"];
            [aPageTurningView removeObserver:self forKeyPath:@"rightPageFrame"];
            [aPageTurningView removeFromSuperview];
            self.pageTurningView = nil;
        }
    }
}

- (void)layoutSubviews {
    CGRect myBounds = self.bounds;
    if(myBounds.size.width > myBounds.size.height) {
        self.pageTurningView.fitTwoPages = YES;
        self.pageTurningView.twoSidedPages = YES;
        // The first page is page 0 as far as the page turning view is concerned,
        // so it's an even page, so if it's mean to to be on the left, the odd 
        // pages should be on the right.
        
        // Disabled for now because many books seem to have the property set even
        // though their first page is the cover, and the odd pages are 
        // clearly meant to be on the left (e.g. they have page numbers on the 
        // outside).
        //self.pageTurningView.oddPagesOnRight = [[[BlioBookManager sharedBookManager] bookWithID:self.bookID] firstLayoutPageOnLeft];
    } else {
        self.pageTurningView.fitTwoPages = NO;
        self.pageTurningView.twoSidedPages = NO;
    }    
    [super layoutSubviews];
    CGSize newSize = self.bounds.size;
    if(!CGSizeEqualToSize(newSize, self.pageSize)) {
        if(self.selector.tracking) {
            [self.selector setSelectedRange:nil];
        }
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.selector setSelectedRange:nil];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	self.lastBlock = nil;
	
	// TODO: Get Jamie to provide an asynchronous update mechanism for this so we don't see a checkerboard flash
	[self.pageTurningView refreshPageAtIndex:self.pageTurningView.rightPageIndex];
	[self.pageTurningView refreshPageAtIndex:self.pageTurningView.rightPageIndex - 1];
	[self.pageTurningView refreshPageAtIndex:self.pageTurningView.rightPageIndex - 2];
	[self.pageTurningView refreshPageAtIndex:self.pageTurningView.rightPageIndex + 1];
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

- (void)setPageTexture:(UIImage *)aPageTexture isDark:(BOOL)isDark
{    
    if (self.pageTexture != aPageTexture || self.pageTextureIsDark != isDark) {
        self.pageTexture = aPageTexture;
        self.pageTextureIsDark = isDark;
        [self.pageTurningView setPageTexture:aPageTexture isDark:isDark];
        [self.pageTurningView setNeedsDraw];
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
    [self pushCurrentBookmarkPoint];
    [self goToPageNumber:[self.textFlow pageNumberForSectionUuid:uuid] animated:animated];
}

- (void)goToPageNumber:(NSInteger)targetPage animated:(BOOL)animated {
    [self goToPageNumber:targetPage animated:animated saveToHistory:YES];
}

- (void)goToPageNumber:(NSInteger)targetPage animated:(BOOL)animated saveToHistory:(BOOL)save {
    if (save) {
        [self pushCurrentBookmarkPoint];
    }
    
    if(self.pageTurningView) {
        [self.pageTurningView turnToPageAtIndex:targetPage - 1 animated:animated];      
        self.pageNumber = targetPage;
    }
}

- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated {
    [self goToBookmarkPoint:bookmarkPoint animated:animated saveToHistory:YES];
}

- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated saveToHistory:(BOOL)save
{
    if (save) {
        [self pushCurrentBookmarkPoint];
        [self goToPageNumber:bookmarkPoint.layoutPage animated:animated saveToHistory:YES];
    } else {
        [self goToPageNumber:bookmarkPoint.layoutPage animated:animated saveToHistory:NO];
    }
}

- (void)goToBookmarkRange:(BlioBookmarkRange *)bookmarkRange animated:(BOOL)animated {
    [self goToBookmarkRange:bookmarkRange animated:animated saveToHistory:YES];
}

- (void)goToBookmarkRange:(BlioBookmarkRange *)bookmarkRange animated:(BOOL)animated saveToHistory:(BOOL)save {
    if (save) {
        [self pushCurrentBookmarkPoint];
    }
    [self goToPageNumber:bookmarkRange.startPoint.layoutPage animated:animated];
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
    
    if (self.pageTurningView.twoSidedPages && (pageIndex == [self.pageTurningView leftPageIndex])) {
		if (applyZoom) {
			pageFrame = [self.pageTurningView leftPageFrame];
		} else {
			pageFrame = [self.pageTurningView unzoomedLeftPageFrame];
		}
    } else {
		if (applyZoom) {
			pageFrame = [self.pageTurningView rightPageFrame];
		} else {
			pageFrame = [self.pageTurningView unzoomedRightPageFrame];
		}
    }
    
    if (!offset) {
        pageFrame.origin = CGPointZero;
		if (self.pageTurningView.twoSidedPages && (pageIndex != [self.pageTurningView leftPageIndex])) {
			if (applyZoom) {
				pageFrame.origin = CGPointMake(CGRectGetMidX(self.pageTurningView.bounds) * self.pageTurningView.zoomFactor, 0);
			} else {
				pageFrame.origin = CGPointMake(CGRectGetMidX(self.pageTurningView.bounds), 0);
			}
		} else {
			pageFrame.origin = CGPointZero;
		}
    }

    CGAffineTransform pageTransform = transformRectToFitRect(pageCrop, pageFrame, true);
    
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
    pageViewIsTurning = YES;
    //self.temporaryHighlightingDisabled = YES;
    //[self _removeTemporaryHighlights];    
}

- (void)pageTurningViewDidEndAnimation:(EucPageTurningView *)aPageTurningView
{
    NSUInteger pageIndex = aPageTurningView.rightPageIndex;
    if(pageIndex == NSUIntegerMax) {
        pageIndex = aPageTurningView.leftPageIndex;
    }
    if(self.pageNumber != pageIndex + 1) {
		[self pushCurrentBookmarkPoint];
        self.pageNumber = pageIndex + 1;
        self.selector.selectedRange = nil;
    }
    self.selector.selectionDisabled = NO;
    pageViewIsTurning = NO;
    //_temporaryHighlightingDisabled = NO;
#if 0
    if(_temporaryHighlightRange) {
        EucPageView *currentPageView = (EucPageView *)(_pageTurningView.currentPageView);
        CALayer *pageLayer = currentPageView.layer;
        THPair *indexPointRange = [pageLayer valueForKey:@"EucBookViewIndexPointRange"];
        EucHighlightRange *pageRange = [[EucHighlightRange alloc] init];
        pageRange.startPoint = indexPointRange.first;
        pageRange.endPoint = indexPointRange.second;
        
        if([pageRange intersects:_temporaryHighlightRange] && 
           ![pageRange.endPoint isEqual:_temporaryHighlightRange.startPoint]) { 
            // And clause because highlight ranges are inclusive, but the
            // ranges stored in EucBookViewIndexPointRange are exclusive
            // of the end point...
            [self _displayTemporaryHighlightsAnimated:YES];
        }
        [pageRange release];
    }
#endif
}

- (void)pageTurningViewWillBeginZooming:(EucPageTurningView *)scrollView 
{
    // Would be nice to just hide the menu and redisplay the range after every 
    // zoom step, but it's far too slow, so we just disable selection while 
    // zooming is going on.
    //[self.selector setShouldHideMenu:YES];
    [self.selector setSelectionDisabled:YES];
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
    
    if (self.pageTurningView.fitTwoPages) {
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
	BlioBookmarkPoint *startPoint = [[BlioBookmarkPoint alloc] init];
	startPoint.blockOffset = 0;
	
	if (self.pageTurningView.fitTwoPages) {
		startPoint.layoutPage = [self.pageTurningView leftPageIndex] + 1;
	} else {
		startPoint.layoutPage = [self.pageTurningView rightPageIndex] + 1;
	}
	
    NSArray *rightPageBlocks = [self.textFlow blocksForPageAtIndex:[self.pageTurningView rightPageIndex] includingFolioBlocks:NO];
    NSUInteger maxOffset = [rightPageBlocks count];
    
    BlioBookmarkPoint *endPoint = [[BlioBookmarkPoint alloc] init];
    endPoint.layoutPage = [self.pageTurningView rightPageIndex] + 1;
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
    } else if(object == self.pageTurningView) {
        if([keyPath isEqualToString:@"leftPageFrame"]) {
            //CGRect frame = ((EucPageTurningView *)object).leftPageFrame;
            //NSLog(@"Left page frame: { { %f, %f }, { %f, %f } }", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height); 
        } else if([keyPath isEqualToString:@"rightPageFrame"]) {
            //CGRect frame = ((EucPageTurningView *)object).rightPageFrame;
            //NSLog(@"Right page frame: { { %f, %f }, { %f, %f } }", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height); 
            
            // Would be nice, but it's /really/ slow.
            //[self.selector redisplaySelectedRange];
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

- (NSArray *)highlightRectsForPageAtIndex:(NSInteger)pageIndex excluding:(BlioBookmarkRange *)excludedBookmark {
    NSMutableArray *allHighlights = [NSMutableArray array];
    NSArray *highlightRanges = nil;
    if (self.delegate) {
        highlightRanges = [self.delegate rangesToHighlightForLayoutPage:pageIndex + 1];
    }

    NSArray *pageBlocks = [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:NO];
    CGAffineTransform  pageTransform = [self pageTurningViewTransformForPageAtIndex:pageIndex offsetOrigin:NO applyZoom:NO];

    for (BlioBookmarkRange *highlightRange in highlightRanges) {
        
        if (![highlightRange isEqual:excludedBookmark]) {
            NSMutableArray *highlightRects = [[NSMutableArray alloc] init];
            
            for (BlioTextFlowBlock *block in pageBlocks) {                
                for (BlioTextFlowPositionedWord *word in [block words]) {
                    // If the range starts before this word:
                    if ( highlightRange.startPoint.layoutPage < (pageIndex + 1) ||
                        ((highlightRange.startPoint.layoutPage == (pageIndex + 1)) && (highlightRange.startPoint.blockOffset < block.blockIndex)) ||
                        ((highlightRange.startPoint.layoutPage == (pageIndex + 1)) && (highlightRange.startPoint.blockOffset == block.blockIndex) && (highlightRange.startPoint.wordOffset <= word.wordIndex)) ) {
                        // If the range ends after this word:
                        if ( highlightRange.endPoint.layoutPage > (pageIndex +1 ) ||
                            ((highlightRange.endPoint.layoutPage == (pageIndex + 1)) && (highlightRange.endPoint.blockOffset > block.blockIndex)) ||
                            ((highlightRange.endPoint.layoutPage == (pageIndex + 1)) && (highlightRange.endPoint.blockOffset == block.blockIndex) && (highlightRange.endPoint.wordOffset >= word.wordIndex)) ) {
                            // This word is in the range.
                            CGRect pageRect = CGRectApplyAffineTransform([word rect], pageTransform);
                            [highlightRects addObject:[NSValue valueWithCGRect:pageRect]];
                        }                            
                    }
                }
            }
            
            NSArray *coalescedRects = [EucSelector coalescedLineRectsForElementRects:highlightRects];
            
            for (NSValue *rectValue in coalescedRects) {
                THPair *highlightPair = [[THPair alloc] initWithFirst:(id)rectValue second:(id)[highlightRange.color colorWithAlphaComponent:0.3f]];
                [allHighlights addObject:highlightPair];
                [highlightPair release];
            }
            
            [highlightRects release];
        }
        
    }
    
    return allHighlights;
}

- (NSArray *)pageTurningView:(EucPageTurningView *)pageTurningView highlightsForPageAtIndex:(NSUInteger)pageIndex {

    EucSelectorRange *selectedRange = [self.selector selectedRange];
    BlioBookmarkRange *excludedRange = [self bookmarkRangeFromSelectorRange:selectedRange];
    
    return [self highlightRectsForPageAtIndex:pageIndex excluding:excludedRange];
}


#pragma mark -
#pragma mark TTS

- (void)highlightWordAtBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint {
    [self highlightWordAtBookmarkPoint:bookmarkPoint saveToHistory:NO];
}

- (void)highlightWordAtBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint saveToHistory:(BOOL)save {
    if (save) {
        [self pushCurrentBookmarkPoint];
    }
    BlioBookmarkRange *range = [BlioBookmarkRange bookmarkRangeWithBookmarkPoint:bookmarkPoint];
    [self highlightWordsInBookmarkRange:range animated:YES];
}

- (void)highlightWordsInBookmarkRange:(BlioBookmarkRange *)bookmarkRange animated:(BOOL)animated {
    [self highlightWordsInBookmarkRange:bookmarkRange animated:animated saveToHistory:NO];
}

- (void)highlightWordsInBookmarkRange:(BlioBookmarkRange *)bookmarkRange animated:(BOOL)animated saveToHistory:(BOOL)save {
    
    if (save) {
        [self pushCurrentBookmarkPoint];
    }
    
    if (bookmarkRange) {
        if (self.pageNumber != bookmarkRange.startPoint.layoutPage) {
            [self goToPageNumber:bookmarkRange.startPoint.layoutPage animated:animated];
        }
        EucSelectorRange *range = [self selectorRangeFromBookmarkRange:bookmarkRange];
        [self.selector temporarilyHighlightSelectorRange:range animated:animated];
    } else {
        [self.selector removeTemporaryHighlight];
    }
}

#pragma mark -
#pragma mark Goto Animations

- (CGRect)firstPageRect {
    return [self.pageTurningView rightPageFrame];
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
	if (([touches count] == 1) && ([[touches anyObject] tapCount] > 1)) {
		// Double-tap
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
		NSLog(@"touchesBegan pinch to page tunring view");
        [self.pageTurningView touchesBegan:touches withEvent:event];
    } else {
        [self.delayedTouchesBeganTimer invalidate];
        self.delayedTouchesBeganTimer = nil;
        
        startTouchPoint = [[touches anyObject] locationInView:self];
        NSDictionary *touchesAndEvent = [NSDictionary dictionaryWithObjectsAndKeys:touches, @"touches", event, @"event", nil];
        self.delayedTouchesBeganTimer = [NSTimer scheduledTimerWithTimeInterval:0.31f target:self selector:@selector(delayedTouchesBegan:) userInfo:touchesAndEvent repeats:NO];
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
	
    NSDictionary *touchesEventAndLink = [timer userInfo];
	NSString *link = [touchesEventAndLink valueForKey:@"link"];
		
	if (link) {
		[self hyperlinkTapped:link];
	} else {
		[self handleSingleTapAtPoint:[[[touchesEventAndLink valueForKey:@"touches"] anyObject] locationInView:self]];
	}
	
	self.delayedTouchesEndedTimer = nil;
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

	[self.delayedTouchesEndedTimer invalidate];
    self.delayedTouchesEndedTimer = nil;
	
    [self.delayedTouchesBeganTimer invalidate];
    self.delayedTouchesBeganTimer = nil;
    
    BlioLayoutHyperlink *touchedHyperlink = nil;
    CGPoint point = [[touches anyObject] locationInView:self];
    
    if (!CGPointEqualToPoint(startTouchPoint, CGPointMake(-1, -1))) {
        if (self.pageTurningView.fitTwoPages) {
            NSInteger leftPageIndex = [self.pageTurningView leftPageIndex];
            if (leftPageIndex >= 0) {
                touchedHyperlink = [self hyperlinkForPage:leftPageIndex + 1 atPoint:point];
            }
        }
        
        if (nil == touchedHyperlink) {
            NSInteger rightPageIndex = [self.pageTurningView rightPageIndex];
            if (rightPageIndex < pageCount) {
                touchedHyperlink = [self hyperlinkForPage:rightPageIndex + 1 atPoint:point];
            }
        }
		
		if (([touches count] == 1) && ([[touches anyObject] tapCount] == 2)) {
			// Double-tap			
			[self handleDoubleTapAtPoint:startTouchPoint];
			return;
        } else if (self.selector.tracking || self.selector.selectedRange) {
            return;
        }
		
		NSDictionary *touchesEventAndLink = [NSDictionary dictionaryWithObjectsAndKeys:touches, @"touches", event, @"event", [touchedHyperlink link], @"link", nil];
        self.delayedTouchesEndedTimer = [NSTimer scheduledTimerWithTimeInterval:0.3f target:self selector:@selector(delayedTouchesEnded:) userInfo:touchesEventAndLink repeats:NO];
		
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
	[self zoomAtPoint:point];
	[self.delegate hideToolbars];
}
        
#pragma mark -
#pragma mark Hyperlinks

- (BOOL)toolbarShowShouldBeSuppressed {
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
    blockRecursionDepth = 0;
    [self zoomToNextBlockReversed:YES];
}

- (void)incrementProperty:(NSTimer *)timer {
   // NSDictionary *animationDictionary = [timer userInfo];
    //id target           = [animationDictionary valueForKey:@"target"];
   // NSString *keyPath   = [animationDictionary valueForKey:@"keyPath"];
//    NSNumber *stop      = [animationDictionary valueForKey:@"stop"];
//    NSNumber *increment = [animationDictionary valueForKey:@"increment"];

    //NSNumber *currentKeyPathValue = [target valueForKeyPath:keyPath];
    //NSNumber *newKeyPathValue = [NSNumber numberWithFloat:[currentKeyPathValue floatValue] + [increment floatValue]];
    
    //if ([newKeyPathValue floatValue] > [stop floatValue]) {
//        newKeyPathValue = stop;
//        [timer invalidate];
//    }
    
    CGPoint currentTranslation = [self.pageTurningView translation];
    if (currentTranslation.x >= 100) {
        [timer invalidate];
    } else {
    
    //[target setValue:newKeyPathValue forKeyPath:keyPath];
		[self.pageTurningView setTranslation:CGPointMake(currentTranslation.x + 10, currentTranslation.y + 10) zoomFactor:1.2 animated:YES];
        currentTranslation = [self.pageTurningView translation];
        [self.pageTurningView drawView];
    }

}

- (void)zoomToNextBlock {
    blockRecursionDepth = 0;
    [self zoomToNextBlockReversed:NO];
}

- (void)zoomToNextBlockReversed:(BOOL)reversed {
    
    blockRecursionDepth++;
    if (blockRecursionDepth > 100) {
        NSLog(@"Warning: block recursion reached a depth of 100 on page %d. Bailing out.", [self pageNumber]);
        [self zoomOut];
        return;
    }
    
    //[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    NSInteger pageIndex = (self.pageTurningView.twoSidedPages) ? self.pageTurningView.leftPageIndex : self.pageTurningView.rightPageIndex;
	
	if (self.pageTurningView.twoSidedPages) {
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
    BOOL useVisibleRect = !((self.pageTurningView.zoomFactor == 1) && (nil == self.lastBlock));
    
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
        if (!reversed) {
            if (pageBlocks.count > 0) {
                targetBlock = [pageBlocks objectAtIndex:0];
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
			if (self.pageTurningView.twoSidedPages && (pageIndex == self.pageTurningView.leftPageIndex)) {
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
				[self goToPageNumber:(pageIndex + 1) + 1 animated:YES];
				[self.pageTurningView setTranslation:CGPointZero zoomFactor:1 animated:YES];
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
				[self.pageTurningView setTranslation:CGPointZero zoomFactor:1 animated:YES];
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
	
	if (self.pageTurningView.zoomFactor > 1) {
		[self zoomOut];
		return;
	}
    	
	NSInteger pageIndex;
	
	CGRect rightPageFrame = [self.pageTurningView rightPageFrame];
	
	if (CGRectContainsPoint(rightPageFrame, point)) {
		pageIndex = self.pageTurningView.rightPageIndex;
	} else{
		pageIndex = self.pageTurningView.leftPageIndex;
	}
	
	NSArray *pageBlocks = [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:NO];
	
    BlioTextFlowBlock *targetBlock = nil;
	CGAffineTransform viewTransform = [self pageTurningViewTransformForPageAtIndex:pageIndex];
    
	for (BlioTextFlowBlock *block in pageBlocks) {
		CGRect blockRect = [block rect];
		CGRect pageRect = CGRectApplyAffineTransform(blockRect, viewTransform);
		if (CGRectContainsPoint(pageRect, point)) {
			targetBlock = block;
			break;
		}		
	}
    
    if (nil != targetBlock) {
        self.lastBlock = targetBlock;
        [self zoomToBlock:targetBlock visibleRect:[self visibleRectForPageAtIndex:pageIndex] reversed:NO context:nil center:point];
	} else {
		[self zoomOutsideBlockAtPoint:point];
    }    
}

- (CGRect)expandRectToMinimumWidth:(CGRect)aRect {
    CGRect viewBounds = self.pageTurningView.bounds;
    CGFloat blockMinimumWidth = CGRectGetWidth(viewBounds) / 8;
    
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
		rectEdgeOffset = topOfPageOffset - CGRectGetMinY(targetRect);
		scaledOffsetY = roundf(rectEdgeOffset * zoomScale - CGRectGetMidY(self.pageTurningView.bounds));
	} else {
		rectEdgeOffset = bottomOfPageOffset + (CGRectGetHeight(pageRect) - CGRectGetMaxY(targetRect));
		scaledOffsetY = roundf(rectEdgeOffset * zoomScale + CGRectGetMidY(self.pageTurningView.bounds));
	}
	
	return CGPointMake(scaledOffsetX, scaledOffsetY);
}

- (void)zoomToBlock:(BlioTextFlowBlock *)targetBlock visibleRect:(CGRect)visibleRect reversed:(BOOL)reversed context:(void *)context center:(CGPoint)centerPoint {
    
    NSInteger pageIndex = [targetBlock pageIndex];
    
    NSArray *pageBlocks = [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:NO];
    BlioTextFlowBlockCombiner *blockCombiner = [[[BlioTextFlowBlockCombiner alloc] initWithTextFlowBlocks:pageBlocks] autorelease];
    blockCombiner.verticalSpacing = [self verticalSpacingForPage:pageIndex + 1];
    
    CGRect combined = [blockCombiner combinedRectForBlock:targetBlock];
	CGRect nonVisibleBlockRect = combined;
	
	//NSLog(@"zoom to block (%@) with rect %@ in combined block with rect %@", [NSString stringWithFormat:@"%@ %@...", [(id)[[targetBlock words] objectAtIndex:0] string], [(id)[[targetBlock words] objectAtIndex:1] string]], NSStringFromCGRect([targetBlock rect]), NSStringFromCGRect(combined));
    
	if (self.pageTurningView.zoomFactor > 1) {
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

    CGFloat zoomScale;
    CGPoint translation = [self translationToFitRect:nonVisibleBlockRect onPage:pageIndex + 1 zoomScale:&zoomScale reversed:reversed];
	
	CGPoint currentTranslation = [self.pageTurningView translation];
	CGFloat currentZoom = [self.pageTurningView zoomFactor];
	NSInteger currentPage = self.pageNumber;
	
	if (!CGPointEqualToPoint(centerPoint, CGPointZero)) {
		CGFloat pointOffset = CGRectGetMidY(self.pageTurningView.bounds) - centerPoint.y;
		translation.y = roundf((pointOffset + currentTranslation.y) * zoomScale);		
	}

    
        if ((pageIndex + 1) != currentPage) {
			if (self.pageTurningView.twoSidedPages) {
				if ((self.pageTurningView.leftPageIndex != pageIndex) && (self.pageTurningView.rightPageIndex != pageIndex)) {
					// TODO: Add a way for these to be combined
					[self.pageTurningView setTranslation:translation zoomFactor:zoomScale animated:YES];
					[self goToPageNumber:(pageIndex + 1) animated:YES];
					return;
				}
			} else {
				if (self.pageTurningView.rightPageIndex != pageIndex) {
					// TODO: Add a way for these to be combined
					[self.pageTurningView setTranslation:translation zoomFactor:zoomScale animated:YES];
					[self goToPageNumber:(pageIndex + 1) animated:YES];
					return;
				}
			}
		}
	
	[self.pageTurningView setTranslation:translation zoomFactor:zoomScale animated:YES];

	if ((roundf(self.pageTurningView.translation.x) == roundf(currentTranslation.x)) && (roundf(self.pageTurningView.translation.y) == roundf(currentTranslation.y))) {
		if (self.pageTurningView.zoomFactor == currentZoom) {
			if (self.pageNumber == currentPage) {
				if (nil != context) {
					NSInvocation *nextInvocation = (NSInvocation *)context;
					[nextInvocation invoke];
				} else {
					[self zoomOut];
					return;
				}
			}
		} 
	}
}

- (void)zoomToBlock:(BlioTextFlowBlock *)targetBlock visibleRect:(CGRect)visibleRect reversed:(BOOL)reversed context:(void *)context {
	[self zoomToBlock:targetBlock visibleRect:visibleRect reversed:reversed context:context center:CGPointZero];
}

- (void)zoomOut {
    self.lastBlock = nil;
    [self.pageTurningView setTranslation:CGPointZero zoomFactor:1 animated:YES];
}

- (void)zoomOutsideBlockAtPoint:(CGPoint)point {
	self.lastBlock = nil;
	
	CGFloat zoomFactor = 2;
	CGPoint offset = CGPointMake((CGRectGetMidX(self.pageTurningView.bounds) - point.x) * zoomFactor, (CGRectGetMidY(self.pageTurningView.bounds) - point.y) * zoomFactor); 
	[self.pageTurningView setTranslation:offset zoomFactor:zoomFactor animated:YES];
}

@end

@implementation BlioPageTurningAnimator

@synthesize zoomFactor;

- (void)setValue:(id)value forKey:(NSString *)key {
    NSString *animationKeyPath = [self valueForKey:@"animationKeyPath"];
    if ([key isEqualToString:animationKeyPath]) {
        id animationTarget = [self valueForKey:@"animationTarget"];
        [animationTarget setValue:value forKeyPath:animationKeyPath];
    } else {
        [super setValue:value forKey:key];
    }
}

- (void)setZoomFactor:(CGFloat)newZoom {
    id animationTarget = [self valueForKey:@"animationTarget"];
    [animationTarget setValue:[NSNumber numberWithFloat:newZoom] forKeyPath:@"zoomFactor"];
}

- (void)setValue:(id)value forKeyPath:(NSString *)keyPath {
    NSString *animationKeyPath = [self valueForKey:@"animationKeyPath"];
    if ([keyPath isEqualToString:animationKeyPath]) {
        id animationTarget = [self valueForKey:@"animationTarget"];
        [animationTarget setValue:value forKeyPath:animationKeyPath];
    } else {
        [super setValue:value forKeyPath:keyPath];
    }
}

@end

