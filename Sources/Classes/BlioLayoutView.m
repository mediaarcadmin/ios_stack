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

@property (nonatomic) NSInteger pageNumber;
@property (nonatomic, retain) UIImage *pageSnapshot;
@property (nonatomic, retain) UIImage *highlightsSnapshot;
@property (nonatomic, retain) id<BlioLayoutDataSource> dataSource;
@property (nonatomic, retain) UIImage *pageTexture;
@property (nonatomic, assign) BOOL pageTextureIsDark;

- (CGRect)cropForPage:(NSInteger)page;
- (CGRect)cropForPage:(NSInteger)page allowEstimate:(BOOL)estimate;
- (CGAffineTransform)blockTransformForPage:(NSInteger)page;

- (NSArray *)bookmarkRangesForCurrentPage;
- (EucSelectorRange *)selectorRangeFromBookmarkRange:(BlioBookmarkRange *)range;
- (BlioBookmarkRange *)bookmarkRangeFromSelectorRange:(EucSelectorRange *)range;

- (void)clearSnapshots;
- (void)clearHighlightsSnapshot;

@end

@implementation BlioLayoutView

@synthesize bookID, textFlow, pageNumber, pageCount, selector;
@synthesize pageCropsCache, viewTransformsCache;
@synthesize pageSnapshot, highlightsSnapshot;
@synthesize dataSource;
@synthesize pageTurningView, pageTexture, pageTextureIsDark;

- (void)dealloc {
    self.textFlow = nil;
    self.pageCropsCache = nil;
    self.viewTransformsCache = nil;
    self.pageSnapshot = nil;
    self.highlightsSnapshot = nil;
    
    self.pageTurningView = nil;
    self.pageTexture = nil;
    
    [self.selector detatch];
    self.selector = nil;
    
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
    
    self.bookID = nil;
    [layoutCacheLock release];
        
    [super dealloc];
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    NSLog(@"Did receive memory warning");
    [self clearSnapshots];
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
        
        EucPageTurningView *aPageTurningView = [[EucPageTurningView alloc] initWithFrame:self.bounds];
        aPageTurningView.delegate = self;
        aPageTurningView.bitmapDataSource = self;
        aPageTurningView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self addSubview:aPageTurningView];
        self.pageTurningView = aPageTurningView;
        [aPageTurningView release];
        
        pageCount = [self.dataSource pageCount];
        // Cache the first page crop to allow fast estimating of crops
        firstPageCrop = [self.dataSource cropRectForPage:1];
        if (CGRectEqualToRect(firstPageCrop, CGRectZero)) {
            [self.pageTurningView setPageAspectRatio:1];
        } else {
            [self.pageTurningView setPageAspectRatio:firstPageCrop.size.width/firstPageCrop.size.height];
        }

        
        EucSelector *aSelector = [[EucSelector alloc] init];
        [aSelector setShouldSniffTouches:NO];
        aSelector.dataSource = self;
        aSelector.delegate =  self;
        aSelector.loupeBackgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
        self.selector = aSelector;
       // [aSelector addObserver:self forKeyPath:@"tracking" options:0 context:NULL];
        //[aSelector addObserver:self forKeyPath:@"trackingStage" options:0 context:NULL];
        [aSelector release];
        
       // [self addObserver:self forKeyPath:@"currentPageLayer" options:0 context:NULL];
        
        NSInteger page = aBook.implicitBookmarkPoint.layoutPage;
        if (page > self.pageCount) page = self.pageCount;
        self.pageNumber = page;
        
        self.pageTurningView.currentPageIndex = self.pageNumber - 1;
    }

    return self;
}

#pragma mark -
#pragma mark EucPageTurningViewBitmapDataSource

- (CGRect)pageTurningView:(EucPageTurningView *)aPageTurningView contentRectForPageAtIndex:(NSUInteger)index {
    return [self cropForPage:index + 1];
}

- (CGContextRef)pageTurningView:(EucPageTurningView *)aPageTurningView 
RGBABitmapContextForPageAtIndex:(NSUInteger)index
                       fromRect:(CGRect)rect 
                        minSize:(CGSize)size {
    return [self.dataSource RGBABitmapContextForPage:index + 1
                                            fromRect:rect 
                                             minSize:size];
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

- (void)didFinishReading {
    if (xpsProvider) {
        [xpsProvider reportReading]; 
    }
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

- (CGAffineTransform)blockTransformForPage:(NSInteger)page {
    return CGAffineTransformIdentity;
}

#pragma mark -
#pragma mark Selector

- (void)clearSnapshots {
    self.pageSnapshot = nil;
    self.highlightsSnapshot = nil; 
}

- (void)clearHighlightsSnapshot {
    self.highlightsSnapshot = nil; 
}

- (UIImage *)viewSnapshotImageForEucSelector:(EucSelector *)selector {
    return nil;
}

- (UIView *)viewForMenuForEucSelector:(EucSelector *)selector {
    return self.pageTurningView;
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

- (NSArray *)highlightRangesForEucSelector:(EucSelector *)aSelector {
    NSMutableArray *selectorRanges = [NSMutableArray array];
    
    for (BlioBookmarkRange *highlightRange in [self bookmarkRangesForCurrentPage]) {
        EucSelectorRange *range = [self selectorRangeFromBookmarkRange:highlightRange];
        [selectorRanges addObject:range];
    }
    
    return [NSArray arrayWithArray:selectorRanges];
}

- (NSArray *)blockIdentifiersForEucSelector:(EucSelector *)selector {
    NSInteger pageIndex = self.pageNumber - 1;
    NSArray *pageBlocks = [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:NO];
    return [pageBlocks valueForKey:@"blockID"];
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
    
    CGAffineTransform viewTransform = [self blockTransformForPage:pageIndex + 1];
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
            CGAffineTransform viewTransform = [self blockTransformForPage:pageIndex + 1];
            CGRect wordRect = [[[block words] objectAtIndex:[wordID integerValue]] rect];            
            return [NSArray arrayWithObject:[NSValue valueWithCGRect:CGRectApplyAffineTransform(wordRect, viewTransform)]];
        }
    } 
    return [NSArray array];
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


