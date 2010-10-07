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

@interface BlioLayoutView()

@property (nonatomic, assign) NSInteger pageNumber;
@property (nonatomic, assign) CGSize pageSize;
@property (nonatomic, retain) id<BlioLayoutDataSource> dataSource;
@property (nonatomic, retain) UIImage *pageTexture;
@property (nonatomic, assign) BOOL pageTextureIsDark;
@property (nonatomic, retain) BlioTextFlowBlock *lastBlock;

- (CGRect)cropForPage:(NSInteger)page;
- (CGRect)cropForPage:(NSInteger)page allowEstimate:(BOOL)estimate;

- (CGAffineTransform)pageTurningViewTransformForPageAtIndex:(NSInteger)page;

- (NSArray *)bookmarkRangesForCurrentPage;
- (EucSelectorRange *)selectorRangeFromBookmarkRange:(BlioBookmarkRange *)range;
- (BlioBookmarkRange *)bookmarkRangeFromSelectorRange:(EucSelectorRange *)range;

- (NSInteger)leftPageIndex;
- (NSInteger)rightPageIndex;

- (void)stopSniffingTouches; 
- (void)startSniffingTouches;
- (void)touchBegan:(UITouch *)touch;
- (void)touchMoved:(UITouch *)touch;
- (void)touchEnded:(UITouch *)touch;

- (NSArray *)hyperlinksForPage:(NSInteger)page;
- (BlioLayoutHyperlink *)hyperlinkForPage:(NSInteger)page atPoint:(CGPoint)point;
- (void)hyperlinkTapped:(NSString *)link;

@end

@implementation BlioLayoutView

@synthesize bookID, textFlow, pageNumber, pageCount, selector, pageSize;
@synthesize pageCropsCache, viewTransformsCache, hyperlinksCache;
@synthesize dataSource;
@synthesize pageTurningView, pageTexture, pageTextureIsDark;
@synthesize lastBlock;

- (void)dealloc {
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
        [self stopSniffingTouches];
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
        [aSelector attachToView:pageTurningView];
        [aSelector addObserver:self forKeyPath:@"tracking" options:0 context:NULL];
        self.selector = aSelector;
        [aSelector release];   
        [self startSniffingTouches];
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
    self.selector.selectedRange = nil;
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

- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated {
    [self goToPageNumber:[self.textFlow pageNumberForSectionUuid:uuid] animated:animated];
}

- (void)goToPageNumber:(NSInteger)targetPage animated:(BOOL)animated {
    if(self.pageTurningView) {
        [pageTurningView turnToPageAtIndex:targetPage - 1 animated:animated];      
        self.pageNumber = targetPage;
    }
}

- (BlioBookmarkPoint *)currentBookmarkPoint {
    BlioBookmarkPoint *ret = [[BlioBookmarkPoint alloc] init];
    ret.layoutPage = self.pageNumber;
    return [ret autorelease];
}

- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated {
    [self goToBookmarkPoint:bookmarkPoint animated:animated saveToHistory:YES];
}

- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated saveToHistory:(BOOL)save
{
    if (save) {
        [self pushCurrentBookmarkPoint];
    }
    [self goToPageNumber:bookmarkPoint.layoutPage animated:animated];
}

- (void)goToBookmarkRange:(BlioBookmarkRange *)bookmarkRange animated:(BOOL)animated {
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
    return self.pageTurningView;
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
}

- (void)highlightWordsInBookmarkRange:(BlioBookmarkRange *)bookmarkRange animated:(BOOL)animated {
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

- (void)startSniffingTouches {
    for(THEventCapturingWindow *window in [[UIApplication sharedApplication] windows]) {
        if([window isKindOfClass:[THEventCapturingWindow class]]) {
            [window addTouchObserver:self forView:self.pageTurningView];
        }
    }
}

- (void)stopSniffingTouches {
    for(THEventCapturingWindow *window in [[UIApplication sharedApplication] windows]) {
        if([window isKindOfClass:[THEventCapturingWindow class]]) {
            [window removeTouchObserver:self forView:self.pageTurningView];
        }
    }
}

- (void)observeTouch:(UITouch *)touch {
    switch(touch.phase) {
        case UITouchPhaseBegan:
            [self touchBegan:touch];
            break;
        case UITouchPhaseMoved: 
            [self touchMoved:touch];
            break;
        case UITouchPhaseEnded:
            [self touchEnded:touch];
            break;
        default:
            break;
    }
}

- (void)touchBegan:(UITouch *)touch {
    startTouchPoint = [touch locationInView:self];
}

- (void)touchMoved:(UITouch *)touch {
    startTouchPoint = CGPointMake(-1, -1);
}

- (void)touchEnded:(UITouch *)touch {
    BlioLayoutHyperlink *touchedHyperlink = nil;
    
    if ([self.delegate toolbarsVisible]) {
        return;
    }
    
    CGPoint point = [touch locationInView:self];
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
    }

    if ([touchedHyperlink link]) {
        [self hyperlinkTapped:[touchedHyperlink link]];
    }
}
        
#pragma mark -
#pragma mark Hyperlinks

- (BOOL)toolbarShowShouldBeSuppressed {
    if (hyperlinkTapped) {
        hyperlinkTapped = NO;
        return YES;
    } else {
        return NO;
    }
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

@end
