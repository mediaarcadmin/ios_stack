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
@property (nonatomic, retain) NSTimer *delayedTouchesTimer;

- (CGRect)cropForPage:(NSInteger)page;
- (CGRect)cropForPage:(NSInteger)page allowEstimate:(BOOL)estimate;

- (CGAffineTransform)pageTurningViewTransformForPageAtIndex:(NSInteger)page;

- (NSArray *)bookmarkRangesForCurrentPage;
- (EucSelectorRange *)selectorRangeFromBookmarkRange:(BlioBookmarkRange *)range;
- (BlioBookmarkRange *)bookmarkRangeFromSelectorRange:(EucSelectorRange *)range;

- (NSInteger)leftPageIndex;
- (NSInteger)rightPageIndex;

- (BOOL)touchesShouldBeSuppressed;
- (void)handleTapAtPoint:(CGPoint)point;

- (NSArray *)hyperlinksForPage:(NSInteger)page;
- (BlioLayoutHyperlink *)hyperlinkForPage:(NSInteger)page atPoint:(CGPoint)point;
- (void)hyperlinkTapped:(NSString *)link;

- (void)zoomToPreviousBlock;
- (void)zoomToNextBlock;
- (void)zoomToNextBlockReversed:(BOOL)reversed;
- (void)zoomToPage:(NSInteger)targetPageNumber;
- (void)zoomToBlock:(BlioTextFlowBlock *)targetBlock visibleRect:(CGRect)visibleRect reversed:(BOOL)reversed context:(void *)context;
- (void)zoomOut;
- (void)zoomOutsideBlockAtPoint:(CGPoint)point ;

@end

@implementation BlioLayoutView

@synthesize bookID, textFlow, pageNumber, pageCount, selector, pageSize;
@synthesize pageCropsCache, viewTransformsCache, hyperlinksCache;
@synthesize dataSource;
@synthesize pageTurningView, pageTexture, pageTextureIsDark;
@synthesize lastBlock;
@synthesize delayedTouchesTimer;

- (void)dealloc {
    [self.delayedTouchesTimer invalidate];
    self.delayedTouchesTimer = nil;
    
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
        self.pageSize = newSize;
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.selector setSelectedRange:nil];
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
    ret.layoutPage = self.pageNumber;
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
        [pageTurningView turnToPageAtIndex:targetPage - 1 animated:animated];      
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

- (CGAffineTransform)pageTurningViewTransformForPageAtIndex:(NSInteger)pageIndex {
    // TODO: Make sure this is cached in LayoutView or pageTurningView
    CGRect pageCrop = [self pageTurningView:self.pageTurningView contentRectForPageAtIndex:pageIndex];
    CGRect pageFrame;
    
    if (pageIndex == [self leftPageIndex]) {
        pageFrame = [self.pageTurningView leftPageFrame];
    } else {
        pageFrame = [self.pageTurningView rightPageFrame];
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

- (NSInteger)leftPageIndex {
    return [self.pageTurningView leftPageIndex];
}

- (NSInteger)rightPageIndex {
    return [self.pageTurningView rightPageIndex];
}

- (NSArray *)blockIdentifiersForEucSelector:(EucSelector *)selector {
    NSMutableArray *pagesBlocks = [NSMutableArray array];
    
    if (self.pageTurningView.fitTwoPages) {
        NSInteger leftPageIndex = [self leftPageIndex];
        if (leftPageIndex >= 0) {
            [pagesBlocks addObjectsFromArray:[self.textFlow blocksForPageAtIndex:leftPageIndex includingFolioBlocks:NO]];
        }
    }
    
    NSInteger rightPageIndex = [self rightPageIndex];
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
    NSInteger pageIndex = self.pageNumber - 1;
    NSArray *pageBlocks = [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:NO];
    NSUInteger maxOffset = [pageBlocks count];
    
    BlioBookmarkPoint *startPoint = [[BlioBookmarkPoint alloc] init];
    startPoint.layoutPage = self.pageNumber;
    startPoint.blockOffset = 0;
    
    BlioBookmarkPoint *endPoint = [[BlioBookmarkPoint alloc] init];
    endPoint.layoutPage = self.pageNumber;
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

    UIColor *ret = nil;
    #if 0
    for(EucHighlightRange *highlightRange in [_pageTurningView.currentPageView.layer valueForKey:@"EucBookViewHighlightRanges"]) {
        if([[highlightRange selectorRange] isEqual:selectedRange]) {
            NSParameterAssert(!_rangeBeingEdited);
            ret = [highlightRange.color colorWithAlphaComponent:0.3f];
            _rangeBeingEdited = [highlightRange copy];
            break;
        }
    }
    
    [self refreshHighlights];
#endif
    
    return ret;
}

- (void)eucSelector:(EucSelector *)selector didEndEditingHighlightWithRange:(EucSelectorRange *)fromRange movedToRange:(EucSelectorRange *)toRange
{
#if 0
    if(toRange && ![fromRange isEqual:toRange]) {
        NSParameterAssert([[_rangeBeingEdited selectorRange] isEqual:fromRange]);
        EucHighlightRange *fromHighlightRange = _rangeBeingEdited;
        EucHighlightRange *toHighlightRange = [_rangeBeingEdited copy];
        
        toHighlightRange.startPoint.block = [toRange.startBlockId integerValue];
        toHighlightRange.startPoint.word = [toRange.startElementId integerValue];
        toHighlightRange.startPoint.element = 0;
        
        toHighlightRange.endPoint.block = [toRange.endBlockId integerValue];
        toHighlightRange.endPoint.word = [toRange.endElementId integerValue];
        toHighlightRange.endPoint.element = 0;
        
        if([self.delegate respondsToSelector:@selector(bookView:didUpdateHighlightAtRange:toRange:)]) {
            [self.delegate bookView:self didUpdateHighlightAtRange:fromHighlightRange toRange:toHighlightRange];
        }
        
        [toHighlightRange release];
    }
    
    [_rangeBeingEdited release];
    _rangeBeingEdited = nil;
    
    self.selector.selectedRange = nil;
    [self refreshHighlights];
#endif
}


- (void)refreshHighlights
{
#if 0
    EucPageView *currentPageView = (EucPageView *)(_pageTurningView.currentPageView);
    
    if(_rangeBeingEdited) {  
        // We know that only the current page can be viewed, so only update it.
        [self _applyHighlightLayersToPageView:currentPageView refreshingFromBook:NO];
        [_pageTurningView refreshView:currentPageView];
    } else {
        EucBookViewHighlightSurroundingPageFlags surroundingPageFlags = [self _applyHighlightLayersToPageView:currentPageView refreshingFromBook:YES];
        [_pageTurningView refreshView:currentPageView];
        
        if(surroundingPageFlags != EucBookViewHighlightSurroundingPageFlagsNone) {
            NSArray *pageViews = _pageTurningView.pageViews;
            NSUInteger indexOfCurrentPage = [pageViews indexOfObject:currentPageView];
            
            if((surroundingPageFlags & EucBookViewHighlightSurroundingPageFlagsPrevious) == EucBookViewHighlightSurroundingPageFlagsPrevious &&
               indexOfCurrentPage >= 1) {
                EucPageView *pageView = [pageViews objectAtIndex:indexOfCurrentPage-1];
                [self _applyHighlightLayersToPageView:pageView refreshingFromBook:YES];
                [_pageTurningView refreshView:pageView];
            }
            if((surroundingPageFlags & EucBookViewHighlightSurroundingPageFlagsNext) == EucBookViewHighlightSurroundingPageFlagsNext &&
               indexOfCurrentPage < (pageViews.count - 1)) {
                EucPageView *pageView = [pageViews objectAtIndex:indexOfCurrentPage+1];
                [self _applyHighlightLayersToPageView:pageView refreshingFromBook:YES];
                [_pageTurningView refreshView:pageView];
            }
        }
    }
    [_pageTurningView drawView];
#endif
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
#pragma mark Selector Menu Responder Actions 

- (void)addHighlightWithColor:(UIColor *)color {
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
    return [[UIScreen mainScreen] bounds];
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
    if (hyperlinkTapped || pageViewIsTurning || self.selector.tracking || self.selector.selectedRange) {
        hyperlinkTapped = NO;
        return YES;
    } else {
        return NO;
    }
}

- (void)delayedTouchesBegan:(NSTimer *)timer {
    startTouchPoint = CGPointMake(-1, -1);

    NSDictionary *touchesAndEvent = [timer userInfo];
    [self.pageTurningView touchesBegan:[touchesAndEvent valueForKey:@"touches"] withEvent:[touchesAndEvent valueForKey:@"event"]];
    self.delayedTouchesTimer = nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {    
    if ([[event touchesForView:self] count] > 1) {
        startTouchPoint = CGPointMake(-1, -1);
        [self.delayedTouchesTimer fire];
        self.delayedTouchesTimer = nil;
        [self.pageTurningView touchesBegan:touches withEvent:event];
    } else {
        [self.delayedTouchesTimer invalidate];
        self.delayedTouchesTimer = nil;
        
        startTouchPoint = [[touches anyObject] locationInView:self];
        NSDictionary *touchesAndEvent = [NSDictionary dictionaryWithObjectsAndKeys:touches, @"touches", event, @"event", nil];
        self.delayedTouchesTimer = [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(delayedTouchesBegan:) userInfo:touchesAndEvent repeats:NO];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    startTouchPoint = CGPointMake(-1, -1);
    
    [self.delayedTouchesTimer fire];
    self.delayedTouchesTimer = nil;

    [self.pageTurningView touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.delayedTouchesTimer invalidate];
    self.delayedTouchesTimer = nil;
    
    BlioLayoutHyperlink *touchedHyperlink = nil;
    CGPoint point = [[touches anyObject] locationInView:self];
    
    if (CGPointEqualToPoint(point, startTouchPoint)) {
        if (self.pageTurningView.fitTwoPages) {
            NSInteger leftPageIndex = [self leftPageIndex];
            if (leftPageIndex >= 0) {
                touchedHyperlink = [self hyperlinkForPage:leftPageIndex + 1 atPoint:point];
            }
        }
        
        if (nil == touchedHyperlink) {
            NSInteger rightPageIndex = [self rightPageIndex];
            if (rightPageIndex < pageCount) {
                touchedHyperlink = [self hyperlinkForPage:rightPageIndex + 1 atPoint:point];
            }
        }
        
        if ([self touchesShouldBeSuppressed]) {
            return;
        } else if ([touchedHyperlink link]) {
            [self hyperlinkTapped:[touchedHyperlink link]];
        } else {
            [self handleTapAtPoint:point];
        }
    } else {
        [self.pageTurningView touchesEnded:touches withEvent:event];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.delayedTouchesTimer invalidate];
    self.delayedTouchesTimer = nil;
    
    CGPoint point = [[touches anyObject] locationInView:self];
    
    if (!CGPointEqualToPoint(point, startTouchPoint)) {
        [self.pageTurningView touchesCancelled:touches withEvent:event];
    }
}

- (void)handleTapAtPoint:(CGPoint)point {
    
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
    return;
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
    [self.pageTurningView setTranslation:CGPointMake(currentTranslation.x + 10, currentTranslation.y + 10) zoomFactor:1.2];
        currentTranslation = [self.pageTurningView translation];
        [self.pageTurningView drawView];
    }

}

- (void)zoomToNextBlock {
    return;
    [self.pageTurningView setTranslation:CGPointZero zoomFactor:1];
    CGFloat newZoom = 2;
    CGFloat distance = fabs(newZoom - 1);
    CGFloat duration = 0.25f;
    CGFloat increment = (distance / 30.0f) / duration;
    
    NSDictionary *animationDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                         self.pageTurningView, @"target",
                                         @"zoomFactor", @"keyPath",
                                         [NSNumber numberWithFloat:newZoom], @"stop",
                                         [NSNumber numberWithFloat:increment], @"increment", nil];
    
    NSTimer *zoomAnimTimer = [NSTimer timerWithTimeInterval:(1/30.0f) target:self selector:@selector(incrementProperty:) userInfo:animationDictionary repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:zoomAnimTimer forMode:NSDefaultRunLoopMode];
    return;
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
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    NSInteger targetPage = [self pageNumber];
    NSInteger pageIndex = targetPage - 1;
    
    if ([self.lastBlock pageIndex] != pageIndex) {
        self.lastBlock = nil;
    }
    
    NSArray *pageBlocks = [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:NO];
    BlioTextFlowBlockCombiner *blockCombiner = [[[BlioTextFlowBlockCombiner alloc] initWithTextFlowBlocks:pageBlocks] autorelease];
    blockCombiner.verticalSpacing = [self verticalSpacingForPage:targetPage];
    
    BlioTextFlowBlock *targetBlock = nil;
    BlioTextFlowBlock *currentBlock = nil;
    
    // Work out what parts of the page are visible
    CGRect visibleRect;
    
    if (pageIndex == [self.pageTurningView leftPageIndex]) {
        visibleRect = [self.pageTurningView leftPageFrame];
    } else {
        visibleRect = [self.pageTurningView rightPageFrame];
    }
    
    BOOL fullPageWidthVisible = [self fullPageWidthForPage:targetPage isVisibleInRect:visibleRect];
    BOOL useVisibleRect = !(fullPageWidthVisible && (nil == self.lastBlock));
    
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
                [self zoomToPage:targetPage];
                return;
            }
            
            // Always zoom to the next page (rather than to the first block on it)
            [self zoomToPage:targetPage + 1];
        } else {
            if (pageIndex <= 0) {
                // If we are already at the first page, zoom to page
                [self zoomToPage:targetPage];
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
                [self zoomToPage:targetPage - 1];
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

- (void)zoomAtPoint:(NSString *)pointString {
#if 0
    self.lastBlock = nil;
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    CGPoint point = CGPointFromString(pointString);
    
    BlioLegacyLayoutPageLayer *targetLayer = nil;
    CGPoint pointInTargetPage;
    
    NSArray *orderedLayers = [[self.contentView layer] sublayers];
    for (int i = [orderedLayers count]; i > 0; i--) {
        CALayer *pageLayer = [orderedLayers objectAtIndex:(i - 1)];
        pointInTargetPage = [pageLayer convertPoint:point fromLayer:self.layer];
        if ([pageLayer containsPoint:pointInTargetPage]) {
            targetLayer = (BlioLegacyLayoutPageLayer *)pageLayer;
            break;
        }
    }
    
    if (nil == targetLayer) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        return;
    }
    
    NSInteger targetPage = [targetLayer pageNumber];
    NSInteger pageIndex = targetPage - 1;
    
    self.scrollingAnimationInProgress = YES;
    NSArray *pageBlocks = [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:NO];
    
    [self.scrollView setPagingEnabled:NO];
    [self.scrollView setBounces:NO];
    
    BlioTextFlowBlock *targetBlock = nil;
    CGAffineTransform viewTransform = [self blockTransformForPage:targetPage];
    
    NSUInteger count = [pageBlocks count];
    
    if (count > 0) { 
        for (NSUInteger index = 0; index < count; index++) {
            BlioTextFlowBlock *block = [pageBlocks objectAtIndex:index];
            CGRect blockRect = [block rect];
            CGRect pageRect = CGRectApplyAffineTransform(blockRect, viewTransform);
            if (CGRectContainsPoint(pageRect, pointInTargetPage)) {
                targetBlock = block;
                break;
            }
        }
    }
    
    if (nil != targetBlock) {
        self.lastBlock = targetBlock;
        [self zoomToBlock:targetBlock visibleRect:CGRectNull reversed:NO context:nil];
    } else if (self.scrollView.zoomScale > 1) {
        [self zoomOut];
    } else {
        [self zoomToPage:targetPage];
    }    
#endif
}

- (void)zoomToPage:(NSInteger)targetPageNumber {
#if 0
    self.lastBlock = nil;
    
    CGFloat zoomScale;
    CGPoint newContentOffset = [self contentOffsetToFillPage:targetPageNumber zoomScale:&zoomScale];
    CGPoint currentContentOffset = [self.scrollView contentOffset];
    
    if (!CGPointEqualToPoint(newContentOffset, currentContentOffset)) {
        if (targetPageNumber != self.pageNumber) {
            [self goToPageNumber:targetPageNumber animated:YES shouldZoomOut:NO targetZoomScale:zoomScale targetContentOffset:newContentOffset];
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        } else {
            self.scrollingAnimationInProgress = YES;
            [self.scrollView setPagingEnabled:NO];
            [self.scrollView setBounces:NO];
            
            [UIView beginAnimations:@"BlioZoomPage" context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationBeginsFromCurrentState:YES];
            [UIView setAnimationDuration:0.35f];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
            
            [self.scrollView setZoomScale:zoomScale];
            CGSize newContentSize = [self currentContentSize];
            [self.containerView setFrame:CGRectMake(0,0, ceilf(newContentSize.width), ceilf(newContentSize.height))];
            [self.scrollView setContentSize:newContentSize];
            [self.scrollView setContentOffset:newContentOffset];
            self.lastZoomScale = self.scrollView.zoomScale;
            [UIView commitAnimations];
        }
    } else {
        [self zoomOut];
    }
#endif
}

- (void)zoomToBlock:(BlioTextFlowBlock *)targetBlock visibleRect:(CGRect)visibleRect reversed:(BOOL)reversed context:(void *)context {
    
    NSInteger pageIndex = [targetBlock pageIndex];
    
    NSArray *pageBlocks = [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:NO];
    BlioTextFlowBlockCombiner *blockCombiner = [[[BlioTextFlowBlockCombiner alloc] initWithTextFlowBlocks:pageBlocks] autorelease];
    blockCombiner.verticalSpacing = [self verticalSpacingForPage:pageIndex + 1];
    
    CGRect combined = [blockCombiner combinedRectForBlock:targetBlock];
    CGRect nonVisibleBlockRect = combined;
    
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
    
    //NSInteger targetPageNumber = pageIndex + 1;
#if 0
    CGFloat zoomScale;
    CGPoint newContentOffset = [self contentOffsetToFitRect:nonVisibleBlockRect onPage:targetPageNumber zoomScale:&zoomScale reversed:reversed];
    newContentOffset = CGPointMake(roundf(newContentOffset.x), roundf(newContentOffset.y));
    CGPoint currentContentOffset = [self.scrollView contentOffset];
    
    if (!CGPointEqualToPoint(newContentOffset, currentContentOffset)) {
        if (targetPageNumber != self.pageNumber) {
            [self goToPageNumber:targetPageNumber animated:YES shouldZoomOut:NO targetZoomScale:zoomScale targetContentOffset:newContentOffset];
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        } else {
            self.scrollingAnimationInProgress = YES;
            [self.scrollView setPagingEnabled:NO];
            [self.scrollView setBounces:NO];
            
            [UIView beginAnimations:@"BlioZoomToBlock" context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationBeginsFromCurrentState:YES];
            [UIView setAnimationDuration:0.35f];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
            
            [self.scrollView setZoomScale:zoomScale];
            CGSize newContentSize = [self currentContentSize];
            [self.containerView setFrame:CGRectMake(0,0, ceilf(newContentSize.width), ceilf(newContentSize.height))];
            [self.scrollView setContentSize:newContentSize];
            [self.scrollView setContentOffset:newContentOffset];
            self.lastZoomScale = self.scrollView.zoomScale;
            [UIView commitAnimations];
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        }
    } else {
        
        if (nil != context) {
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            NSInvocation *nextInvocation = (NSInvocation *)context;
            [nextInvocation invoke];
        } else {
            [self zoomOut];
            return;
        }
    }
#endif
}

- (void)zoomOut {
#if 0
    self.lastBlock = nil;
    
    [UIView beginAnimations:@"BlioZoomPage" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.35f];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [self.scrollView setZoomScale:1];
    CGSize newContentSize = [self currentContentSize];
    [self.containerView setFrame:CGRectMake(0,0, ceilf(newContentSize.width), ceilf(newContentSize.height))];
    [self.scrollView setContentSize:newContentSize];
    [self.scrollView setContentOffset:[self contentOffsetToCenterPage:self.pageNumber zoomScale:1]]; 
    self.lastZoomScale = 1;
    [UIView commitAnimations];
#endif
}

- (void)zoomOutsideBlockAtPoint:(CGPoint)point {
#if 0
    self.lastBlock = nil;
    
    [UIView beginAnimations:@"BlioZoomPage" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.35f];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [self.scrollView setZoomScale:2.0f];
    CGSize newContentSize = [self currentContentSize];
    [self.containerView setFrame:CGRectMake(0,0, ceilf(newContentSize.width), ceilf(newContentSize.height))];
    [self.scrollView setContentSize:newContentSize];
    
    CGFloat pageWidth = CGRectGetWidth(self.bounds) * self.scrollView.zoomScale;
    CGFloat pageWidthExpansion = pageWidth - CGRectGetWidth(self.bounds);
    CGFloat pageHeight = CGRectGetHeight(self.bounds) * self.scrollView.zoomScale;
    CGFloat pageHeightExpansion = pageHeight - CGRectGetHeight(self.bounds);
    
    CGPoint viewOrigin = CGPointMake((self.pageNumber - 1) * pageWidth, 0);
    CGFloat xOffset = pageWidthExpansion * (point.x / CGRectGetWidth(self.bounds));
    CGFloat yOffset = pageHeightExpansion * (point.y / CGRectGetHeight(self.bounds));
    [self.scrollView setContentOffset:CGPointMake(viewOrigin.x + xOffset, viewOrigin.y + yOffset)];
    
    self.lastZoomScale = self.scrollView.zoomScale;
    [UIView commitAnimations];
#endif
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

