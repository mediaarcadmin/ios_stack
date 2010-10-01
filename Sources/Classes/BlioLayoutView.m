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

#define PAGEHEIGHTRATIO_FOR_BLOCKCOMBINERVERTICALSPACING (1/30.0f)

@interface BlioLayoutPDFDataSource : NSObject<BlioLayoutDataSource> {
    NSData *data;
    NSInteger pageCount;
    CGPDFDocumentRef pdf;
    NSLock *pdfLock;
}

@property (nonatomic, retain) NSData *data;

- (id)initWithPath:(NSString *)aPath;

@end

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

@end

@implementation BlioLayoutView

@synthesize bookID, textFlow, pageNumber, pageCount, selector, pageSize;
@synthesize pageCropsCache, viewTransformsCache;
@synthesize dataSource;
@synthesize pageTurningView, pageTexture, pageTextureIsDark;
@synthesize lastBlock;

- (void)dealloc {
    self.textFlow = nil;
    self.pageCropsCache = nil;
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
    if(newSuperview && !self.superview) {
        EucPageTurningView *aPageTurningView = [[EucPageTurningView alloc] initWithFrame:self.bounds];
        aPageTurningView.delegate = self;
        aPageTurningView.bitmapDataSource = self;
        aPageTurningView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        aPageTurningView.zoomHandlingKind = EucPageTurningViewZoomHandlingKindZoom;
        [self addSubview:aPageTurningView];
        self.pageTurningView = aPageTurningView;
        [aPageTurningView release];
        
        [aPageTurningView addObserver:self forKeyPath:@"leftPageFrame" options:0 context:NULL];
        [aPageTurningView addObserver:self forKeyPath:@"rightPageFrame" options:0 context:NULL];        
        
        self.pageTurningView.currentPageIndex = self.pageNumber - 1;
    } else if (!newSuperview) {
        EucPageTurningView *aPageTurningView = self.pageTurningView;
        [aPageTurningView removeObserver:self forKeyPath:@"leftPageFrame"];
        [aPageTurningView removeObserver:self forKeyPath:@"rightPageFrame"];        
    }
    
    if (CGRectEqualToRect(firstPageCrop, CGRectZero)) {
        [self.pageTurningView setPageAspectRatio:0];
    } else {
        [self.pageTurningView setPageAspectRatio:firstPageCrop.size.width/firstPageCrop.size.height];
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
            [pageTurningView setCurrentPageIndex:targetPage - 1];      
            [pageTurningView setNeedsDraw];
        self.pageNumber = targetPage;
    }
}

- (BlioBookmarkPoint *)currentBookmarkPoint {
    BlioBookmarkPoint *ret = [[BlioBookmarkPoint alloc] init];
    ret.layoutPage = self.pageNumber;
    return [ret autorelease];
}

- (void)goToBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint animated:(BOOL)animated {
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

static CGAffineTransform transformRectToFitRect(CGRect sourceRect, CGRect targetRect, BOOL preserveAspect) {
    
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

    return transformRectToFitRect(pageCrop, pageFrame, true);
}

#pragma mark -
#pragma mark Status callbacks

- (void)pageTurningViewAnimationWillBegin:(EucPageTurningView *)aPageTurningView
{
    
    self.selector.selectionDisabled = YES;
    //self.temporaryHighlightingDisabled = YES;
    //[self _removeTemporaryHighlights];    
}

- (void)pageTurningViewAnimationDidEnd:(EucPageTurningView *)aPageTurningView
{
    self.selector.selectionDisabled = NO;
    self.pageNumber = aPageTurningView.currentPageIndex + 1;
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

#pragma mark -
#pragma mark Selector

- (UIImage *)viewSnapshotImageForEucSelector:(EucSelector *)selector {
    return [self.pageTurningView screenshot];
}

- (NSInteger)leftPageIndex {
    return self.pageNumber - 2;
}

- (NSInteger)rightPageIndex {
    return self.pageNumber - 1;
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
            CGRect frame = ((EucPageTurningView *)object).leftPageFrame;
            NSLog(@"Left page frame: { { %f, %f }, { %f, %f } }", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height); 
        } else if([keyPath isEqualToString:@"rightPageFrame"]) {
            CGRect frame = ((EucPageTurningView *)object).rightPageFrame;
            NSLog(@"Right page frame: { { %f, %f }, { %f, %f } }", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height); 
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

@end

@implementation BlioLayoutPDFDataSource

@synthesize data;

- (void)dealloc {
    [pdfLock lock];
    if (pdf) CGPDFDocumentRelease(pdf);
    self.data = nil;
    [pdfLock unlock];
    [pdfLock release];
    [super dealloc];
}

- (id)initWithPath:(NSString *)aPath {
    if ((self = [super init])) {
        NSData *aData = [[NSData alloc] initWithContentsOfMappedFile:aPath];
        CGDataProviderRef pdfProvider = CGDataProviderCreateWithCFData((CFDataRef)aData);
        CGPDFDocumentRef aPdf = CGPDFDocumentCreateWithProvider(pdfProvider);
        pageCount = CGPDFDocumentGetNumberOfPages(aPdf);
        CGPDFDocumentRelease(aPdf);
        CGDataProviderRelease(pdfProvider);
        self.data = aData;
        [aData release];
        
        pdfLock = [[NSLock alloc] init];
    }
    return self;
}

- (NSInteger)pageCount {
    return pageCount;
}

- (void)openDocumentWithoutLock {
    if (self.data) {
        CGDataProviderRef pdfProvider = CGDataProviderCreateWithCFData((CFDataRef)self.data);
        pdf = CGPDFDocumentCreateWithProvider(pdfProvider);
        CGDataProviderRelease(pdfProvider);
    }
}

- (CGRect)cropRectForPage:(NSInteger)page {
    [pdfLock lock];
    if (nil == pdf) {
        [self openDocumentWithoutLock];
        if (nil == pdf) {
            [pdfLock unlock];
            return CGRectZero;
        }
    }
    CGPDFPageRef aPage = CGPDFDocumentGetPage(pdf, page);
    CGRect cropRect = CGPDFPageGetBoxRect(aPage, kCGPDFCropBox);
    [pdfLock unlock];
    
    return cropRect;
}

- (CGRect)mediaRectForPage:(NSInteger)page {    
    [pdfLock lock];
    if (nil == pdf) {
        [self openDocumentWithoutLock];
        if (nil == pdf) {
            [pdfLock unlock];
            return CGRectZero;
        }
    }
    CGPDFPageRef aPage = CGPDFDocumentGetPage(pdf, page);
    CGRect mediaRect = CGPDFPageGetBoxRect(aPage, kCGPDFMediaBox);
    [pdfLock unlock];
    
    return mediaRect;
}

- (CGFloat)dpiRatio {
    return 72/96.0f;
}


- (CGContextRef)RGBABitmapContextForPage:(NSUInteger)page
                                fromRect:(CGRect)rect
                                 minSize:(CGSize)size 
                              getContext:(id *)context {
    
    if (nil == pdf) return nil;

    size_t width  = size.width;
    size_t height = size.height;
        
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    //CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceCMYK();
        
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, width, height, 8, 4 * width, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);        
    CGColorSpaceRelease(colorSpace);
    
    CGFloat widthScale  = size.width / CGRectGetWidth(rect);
    CGFloat heightScale = size.height / CGRectGetHeight(rect);
    heightScale = heightScale;widthScale = widthScale;
    
    CGContextSetFillColorWithColor(bitmapContext, [UIColor whiteColor].CGColor);
    
    CGRect pageRect = CGRectMake(0, 0, width, height);
    CGContextFillRect(bitmapContext, pageRect);
    CGContextClipToRect(bitmapContext, pageRect);
    
    CGRect cropRect = [self cropRectForPage:page];
    CGAffineTransform fitTransform = transformRectToFitRect(cropRect, pageRect, YES);
    //CGContextConcatCTM(bitmapContext, CGAffineTransformMakeScale(widthScale, heightScale));
    CGContextConcatCTM(bitmapContext, fitTransform);
    
    [pdfLock lock];
    CGPDFPageRef aPage = CGPDFDocumentGetPage(pdf, page);
    CGContextDrawPDFPage(bitmapContext, aPage);
    [pdfLock unlock];
    
    return (CGContextRef)[(id)bitmapContext autorelease];
}

- (void)drawPage:(NSInteger)page inBounds:(CGRect)bounds withInset:(CGFloat)inset inContext:(CGContextRef)ctx inRect:(CGRect)rect withTransform:(CGAffineTransform)transform observeAspect:(BOOL)aspect {
    //NSLog(@"drawPage %d inContext %@ inRect: %@ withTransform %@ andBounds %@", page, NSStringFromCGAffineTransform(CGContextGetCTM(ctx)), NSStringFromCGRect(rect), NSStringFromCGAffineTransform(transform), NSStringFromCGRect(CGContextGetClipBoundingBox(ctx)));
    
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);    
    CGContextFillRect(ctx, rect);
    CGContextClipToRect(ctx, rect);
    
    CGContextConcatCTM(ctx, transform);
    [pdfLock lock];
    if (nil == pdf) return;
    CGPDFPageRef aPage = CGPDFDocumentGetPage(pdf, page);
    CGPDFPageRetain(aPage);
    CGContextDrawPDFPage(ctx, aPage);
    CGPDFPageRelease(aPage);
    [pdfLock unlock];
}

- (void)openDocumentIfRequired {
    [pdfLock lock];
    [self openDocumentWithoutLock];
    [pdfLock unlock];
}

- (UIImage *)thumbnailForPage:(NSInteger)pageNumber {
    return nil;
}

- (void)closeDocument {
    [pdfLock lock];
    if (pdf) CGPDFDocumentRelease(pdf);
    pdf = NULL;
    [pdfLock unlock];
}

- (void)closeDocumentIfRequired {
    [self closeDocument];
}

@end


