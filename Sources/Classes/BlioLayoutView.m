//
//  BlioLayoutView.m
//  BlioApp
//
//  Created by matt on 18/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "BlioLayoutView.h"
#import "BlioBookmark.h"
#import "BlioWebToolsViewController.h"
#import <libEucalyptus/EucMenuItem.h>
#import <libEucalyptus/EucSelectorRange.h>
#import "BlioLayoutScrollView.h"
#import "BlioLayoutContentView.h"

static const CGFloat kBlioPDFBlockInsetX = 6;
static const CGFloat kBlioPDFBlockInsetY = 10;
static const CGFloat kBlioPDFShadowShrinkScale = 2;
static const CGFloat kBlioPDFGoToZoomScale = 0.7f;

static const int kBlioLayoutMaxThumbCacheSize = 2088960; // 2BM in bytes

@interface BlioLayoutRenderThumbsOperation : NSOperation {
    NSString *pdfPath;
    NSInteger pageNumber;
    SEL action;
    id target;
}

- (id)initWithPDFPath:(NSString *)aPDFPath pageNumber:(NSInteger)aPageNumber target:(id)aTarget action:(SEL)aAction;

@end

@interface BlioLayoutHighlightsOperation : NSOperation {
    NSInteger pageNumber;
    CALayer *layer;
    BlioBookmarkRange *excludedBookmark;
    NSArray *highlightRanges;
    BlioTextFlow *textFlow;
}

- (id)initWithPage:(NSInteger)aPageNumber layer:(CALayer *)aLayer exclusion:(BlioBookmarkRange *)aExcludedBookmark highlights:(NSArray *)aHighlightRanges textFlow:(BlioTextFlow *)aTextFlow;

@property (nonatomic) NSInteger pageNumber;
@property (nonatomic, retain) CALayer *layer;
@property (nonatomic, retain) BlioBookmarkRange *excludedBookmark;
@property (nonatomic, retain) NSArray *highlightRanges;
@property (nonatomic, retain) BlioTextFlow *textFlow;

@end

static const CGFloat kBlioLayoutMaxZoom = 4.0f;
static const CGFloat kBlioLayoutShadow = 16.0f;

@interface BlioLayoutViewColoredRect : NSObject {
    CGRect rect;
    UIColor *color;
}

@property (nonatomic) CGRect rect;
@property (nonatomic, retain) UIColor *color;

@end


@interface BlioPDFHighlightLayerDelegate : CALayer {
    CGAffineTransform fitTransform;
    NSArray *highlights;
    CGPDFPageRef page;
    CGAffineTransform highlightsTransform;
}

@property(nonatomic) CGAffineTransform fitTransform;
@property(nonatomic) CGAffineTransform highlightsTransform;
@property(nonatomic, retain) NSArray* highlights;
@property(nonatomic) CGPDFPageRef page;

@end

@interface BlioLayoutView()

- (NSArray *)bookmarkRangesForCurrentPage;
- (EucSelectorRange *)selectorRangeFromBookmarkRange:(BlioBookmarkRange *)range;
- (BlioBookmarkRange *)bookmarkRangeFromSelectorRange:(EucSelectorRange *)range;
@property (nonatomic) NSInteger pageNumber;
@property (nonatomic) CGFloat lastZoomScale;
@property (nonatomic, retain) NSData *pdfData;

@end


@implementation BlioLayoutView

static CGAffineTransform transformRectToFitRect(CGRect sourceRect, CGRect targetRect) {
    
    CGFloat xScale = targetRect.size.width / sourceRect.size.width;
    CGFloat yScale = targetRect.size.height / sourceRect.size.height;
    CGFloat scale = xScale < yScale ? xScale : yScale;
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scale, scale);
    CGRect scaledRect = CGRectApplyAffineTransform(sourceRect, scaleTransform);
    CGFloat xOffset = (targetRect.size.width - scaledRect.size.width);
    CGFloat yOffset = (targetRect.size.height - scaledRect.size.height);
    CGAffineTransform offsetTransform = CGAffineTransformMakeTranslation((targetRect.origin.x - scaledRect.origin.x) + xOffset/2.0f, (targetRect.origin.y - scaledRect.origin.y) + yOffset/2.0f);
    //CGAffineTransform transform = CGAffineTransformConcat(offsetTransform, scaleTransform);
    CGAffineTransform transform = CGAffineTransformConcat(scaleTransform, offsetTransform);
    return transform;
}

@synthesize delegate, book, scrollView, contentView, currentPageLayer, tiltScroller, scrollToPageInProgress, disableScrollUpdating, pageNumber, pageCount, selector, lastHighlightColor, fetchHighlightsQueue;
@synthesize pdfPath, pdfData, lastZoomScale;
@synthesize renderThumbsQueue, thumbCache, thumbCacheSize, pageCropsCache, viewTransformsCache, checkerBoard, shadowBottom, shadowTop, shadowLeft, shadowRight;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    CGPDFDocumentRelease(pdf);
    
    [self.fetchHighlightsQueue cancelAllOperations];
    self.fetchHighlightsQueue = nil;
    [self.renderThumbsQueue cancelAllOperations];
    self.renderThumbsQueue = nil;
    self.thumbCache = nil;
    
    [self.selector removeObserver:self forKeyPath:@"tracking"];
    [self.selector removeObserver:self forKeyPath:@"trackingStage"];
    [self removeObserver:self forKeyPath:@"currentPageLayer"];
    
    self.delegate = nil;
    self.book = nil;
    self.scrollView = nil;
    self.contentView = nil;
    self.currentPageLayer = nil;
    self.lastHighlightColor = nil;
    self.pdfPath = nil;
    self.pdfData = nil;
    self.pageCropsCache = nil;
    self.viewTransformsCache = nil;
    self.checkerBoard = nil;
    self.shadowBottom = nil;
    self.shadowTop = nil;
    self.shadowLeft = nil;
    self.shadowRight = nil;
    
    [self.selector detatch];
    self.selector = nil;

    [super dealloc];
}

- (id)initWithBook:(BlioMockBook *)aBook animated:(BOOL)animated {
    
    self.pdfPath = [aBook pdfPath];
    
    self.pdfData = [[NSData alloc] initWithContentsOfMappedFile:[aBook pdfPath]];
    CGDataProviderRef pdfProvider = CGDataProviderCreateWithCFData((CFDataRef)pdfData);
    pdf = CGPDFDocumentCreateWithProvider(pdfProvider);
    CGDataProviderRelease(pdfProvider);
    
    if (NULL == pdf) return nil;
    
    if ((self = [super initWithFrame:[UIScreen mainScreen].bounds])) {
        // Initialization code
        self.book = aBook;
        self.clearsContextBeforeDrawing = NO; // Performance optimisation;
        self.scrollToPageInProgress = NO;
        self.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];    
        self.autoresizesSubviews = YES;
        
        self.checkerBoard = [UIImage imageNamed:@"check.png"];
        self.shadowBottom = [UIImage imageNamed:@"shadow-bottom.png"];
        self.shadowTop = [UIImage imageNamed:@"shadow-top.png"];
        self.shadowLeft = [UIImage imageNamed:@"shadow-left.png"];
        self.shadowRight = [UIImage imageNamed:@"shadow-right.png"];
        
        pageCount = CGPDFDocumentGetNumberOfPages(pdf);
        
        // Populate the cache of page sizes and viewTransforms
        NSMutableDictionary *aPageCropsCache = [[NSMutableDictionary alloc] initWithCapacity:pageCount];
        NSMutableDictionary *aViewTransformsCache = [[NSMutableDictionary alloc] initWithCapacity:pageCount];
        
        CGFloat inset = -kBlioLayoutShadow;
        CGRect insetBounds = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(-inset, -inset, -inset, -inset));
        CGAffineTransform dpiScale = CGAffineTransformMakeScale(72/96.0f, 72/96.0f);
        
        for (int i = 1; i <= pageCount; i++) {
            CGPDFPageRef aPage = CGPDFDocumentGetPage(pdf, i);
            CGRect cropRect = CGPDFPageGetBoxRect(aPage, kCGPDFCropBox);
            CGAffineTransform pdfTransform = transformRectToFitRect(cropRect, insetBounds);
            CGRect scaledCropRect = CGRectApplyAffineTransform(cropRect, pdfTransform);
            [aPageCropsCache setObject:[NSValue valueWithCGRect:scaledCropRect] forKey:[NSNumber numberWithInt:i]];
            
            CGRect mediaRect = CGPDFPageGetBoxRect(aPage, kCGPDFMediaBox);
            CGAffineTransform mediaAdjust = CGAffineTransformMakeTranslation(cropRect.origin.x - mediaRect.origin.x, cropRect.origin.y - mediaRect.origin.y);
            CGAffineTransform textTransform = CGAffineTransformConcat(dpiScale, mediaAdjust);
            CGAffineTransform viewTransform = CGAffineTransformConcat(textTransform, pdfTransform);
            [aViewTransformsCache setObject:[NSValue valueWithCGAffineTransform:viewTransform] forKey:[NSNumber numberWithInt:i]];
        }
        self.pageCropsCache = [NSDictionary dictionaryWithDictionary:aPageCropsCache];
        self.viewTransformsCache = [NSDictionary dictionaryWithDictionary:aViewTransformsCache];
        [aPageCropsCache release];
        [aViewTransformsCache release];
        
        BlioLayoutScrollView *aScrollView = [[BlioLayoutScrollView alloc] initWithFrame:self.bounds];
        aScrollView.contentSize = CGSizeMake(aScrollView.frame.size.width * pageCount, aScrollView.frame.size.height);
        aScrollView.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
        aScrollView.pagingEnabled = YES;
        aScrollView.minimumZoomScale = 1.0f;
        aScrollView.maximumZoomScale = kBlioLayoutMaxZoom;
        aScrollView.showsHorizontalScrollIndicator = NO;
        aScrollView.showsVerticalScrollIndicator = NO;
        aScrollView.clearsContextBeforeDrawing = NO;
        aScrollView.directionalLockEnabled = YES;
        aScrollView.bounces = YES;
        aScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        aScrollView.autoresizesSubviews = YES;
        aScrollView.scrollsToTop = NO;
        aScrollView.delegate = self;
        aScrollView.canCancelContentTouches = YES;
        aScrollView.delaysContentTouches = NO;
        [self addSubview:aScrollView];
        self.scrollView = aScrollView;
        [aScrollView release];
        
        BlioLayoutContentView *aContentView = [[BlioLayoutContentView alloc] initWithFrame:self.bounds];
        [self.scrollView addSubview:aContentView];
        aContentView.dataSource = self;
        aContentView.backgroundColor = [UIColor clearColor];
        aContentView.clipsToBounds = NO;
        self.contentView = aContentView;
        [aContentView release];
        
        EucSelector *aSelector = [[EucSelector alloc] init];
        [aSelector setShouldSniffTouches:NO];
        aSelector.dataSource = self;
        aSelector.delegate =  self;
        aSelector.loupeBackgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
        self.selector = aSelector;
        [aSelector addObserver:self forKeyPath:@"tracking" options:0 context:NULL];
        [aSelector addObserver:self forKeyPath:@"trackingStage" options:0 context:NULL];
        [self.scrollView setSelector:aSelector];
        [aSelector release];
        
        NSOperationQueue* aHighlightsQueue = [[NSOperationQueue alloc] init];
        self.fetchHighlightsQueue = aHighlightsQueue;
        [aHighlightsQueue release];
        
        [self addObserver:self forKeyPath:@"currentPageLayer" options:0 context:NULL];
        
        NSOperationQueue* aThumbsQueue = [[NSOperationQueue alloc] init];
        [aThumbsQueue setMaxConcurrentOperationCount:1];
        self.renderThumbsQueue = aThumbsQueue;
        [aThumbsQueue release];
        
        NSNumber *savedPage = [aBook layoutPageNumber];
        NSInteger page = (nil != savedPage) ? [savedPage intValue] : 1;
        
        //self.thumbCache = [NSMutableDictionary dictionary];
        self.thumbCache = nil;
        self.thumbCacheSize = 0;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        
        if (page > self.pageCount) page = self.pageCount;
        self.pageNumber = page;
        
        if (animated) {
            self.currentPageLayer = [self.contentView addPage:1 retainPages:nil];
            [self.contentView addPage:2 retainPages:nil];
            if (page == 1) {
                for (int i = 2; i < kBlioLayoutMaxPages; i++) {
                    [self.contentView addPage:i+1 retainPages:nil];
                }
            } else {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blioCoverPageDidFinishRender:) name:@"blioCoverPageDidFinishRender" object:nil];
            }
        } else {
            self.currentPageLayer = [self.contentView addPage:self.pageNumber retainPages:nil];
            for (int i = 0; i < kBlioLayoutMaxPages; i++) {
                if (i != 1) [self.contentView addPage:(self.pageNumber - 1 + i) retainPages:nil];
            }
            
            [self goToPageNumber:self.pageNumber animated:NO];
        }
        
        
        
    }
    return self;
}

- (BOOL)wantsTouchesSniffed {
    return NO;
}

- (void)setDelegate:(id<BlioBookDelegate>)newDelegate {
    delegate = newDelegate;
    [self.scrollView setBookDelegate:newDelegate];
}

- (void)setTiltScroller:(MSTiltScroller*)ts {
    tiltScroller = ts;
    [tiltScroller setScrollView:self.scrollView];
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    NSLog(@"Did receive memory warning - PURGING THUMB CACHE");
    self.thumbCache = [NSMutableDictionary dictionary];
    self.thumbCacheSize = 0;
}

#pragma mark -
#pragma mark Thumb Cache Methods

- (CGImageRef)createThumbImageForPage:(NSInteger)page {
    if (nil == self.thumbCache) return nil;
    
    NSMutableDictionary *thumbCacheDictionary = [self.thumbCache objectForKey:[NSNumber numberWithInteger:page]];
    if (nil == thumbCacheDictionary) {
        NSLog(@"THUMB CACHE MISS FOR PAGE %d", page);
        return nil;
    }
    
    NSDate *start = [NSDate date];
    NSData *compressedData = [thumbCacheDictionary valueForKey:@"compressedData"];
    if (nil == compressedData) return nil;
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)compressedData);
    CGImageRef thumb = CGImageCreateWithPNGDataProvider(provider, NULL, NO, kCGRenderingIntentDefault);
    CGDataProviderRelease(provider);
    
    // Update accessedDate
    [thumbCacheDictionary setValue:[NSDate date] forKey:@"accessedDate"];

    NSLog(@"THUMB CACHE HIT FOR PAGE %d", page);
    NSLog(@"It took %.3f seconds to decompress image", -[start timeIntervalSinceNow]);

    return thumb;
}

- (void)addThumbDataToCache:(NSMutableDictionary *)thumbCacheDictionary {
    NSNumber *thumbPage = [thumbCacheDictionary valueForKey:@"pageNumber"];
    NSData *compressedData = [thumbCacheDictionary valueForKey:@"compressedData"];
    NSDate *accessedDate = [thumbCacheDictionary valueForKey:@"accessedDate"];
    
    self.thumbCacheSize += [compressedData length];
    
    if (thumbPage && compressedData && accessedDate) {
        if (nil == [self.thumbCache objectForKey:thumbPage])
            [self.thumbCache setObject:thumbCacheDictionary forKey:thumbPage];
    }
    
    if (self.thumbCacheSize > kBlioLayoutMaxThumbCacheSize) {
        NSSortDescriptor *dateSort = [[[NSSortDescriptor alloc] initWithKey:@"accessedDate" ascending:YES] autorelease];
        NSArray *sortedItems = [[self.thumbCache allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateSort]];
        
        if ([sortedItems count]) {
            id oldestItem = [sortedItems objectAtIndex:0];        
            NSData *compressedData = [oldestItem valueForKey:@"compressedData"];
            NSLog(@"Page %@ purged from cache. Cache size dropped from %d to %d", [oldestItem valueForKey:@"pageNumber"], self.thumbCacheSize, self.thumbCacheSize - [compressedData length]); 
            self.thumbCacheSize -= [compressedData length];
            NSArray *keys = [self.thumbCache allKeysForObject:oldestItem];
            [self.thumbCache removeObjectsForKeys:keys];
        }
    }
}

- (void)cacheThumbImage:(NSDictionary *)thumbDictionary {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    CGImageRef thumbImage = (CGImageRef)[thumbDictionary valueForKey:@"thumbImage"];
    
    NSNumber *thumbPage = [thumbDictionary valueForKey:@"pageNumber"];
    UIImage *image = [[UIImage alloc] initWithCGImage:thumbImage];
    
    NSData *compressedData = UIImagePNGRepresentation(image);
    if (compressedData && thumbPage) {
        NSMutableDictionary *thumbCacheDictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                     compressedData, @"compressedData", 
                                                     thumbPage, @"pageNumber", 
                                                     [NSDate date], @"accessedDate", nil];
        
        [self performSelectorOnMainThread:@selector(addThumbDataToCache:) withObject:thumbCacheDictionary waitUntilDone:NO];
        [thumbCacheDictionary release];
    }
    [image release];
    [pool drain];
}

#pragma mark -
#pragma mark BlioLayoutDataSource

- (BOOL)dataSourceContainsPage:(NSInteger)page {
    if (page >= 1 && page <= [self pageCount])
        return YES;
    else
        return NO;
}

- (CGRect)cropForPage:(NSInteger)page {
    if (nil == pageCropsCache) return CGRectZero;
    NSValue *pageCropValue;
    
    @synchronized (pageCropsCache) {
        pageCropValue = [pageCropsCache objectForKey:[NSNumber numberWithInt:page]];
    }
    
    if (nil == pageCropValue) return CGRectZero;
    
    return [pageCropValue CGRectValue];
}

- (CGAffineTransform)viewTransformForPage:(NSInteger)page {
    if (nil == viewTransformsCache) return CGAffineTransformIdentity;
    NSValue *viewTransformValue;
    
    @synchronized (viewTransformsCache) {
        viewTransformValue = [viewTransformsCache objectForKey:[NSNumber numberWithInt:page]];
    }
    
    if (nil == viewTransformValue) return CGAffineTransformIdentity;
    
    return [viewTransformValue CGAffineTransformValue];
}

#pragma mark -
#pragma mark Tile Rendering

- (void)drawTiledLayer:(CALayer *)aLayer inContext:(CGContextRef)ctx forPage:(NSInteger)aPageNumber {
     //NSLog(@"Tiled rendering started");
//    CGFloat inset = -kBlioLayoutShadow;
    CGRect layerBounds = aLayer.bounds;
    
    CGAffineTransform layerContext = CGContextGetCTM(ctx);
    
    CGContextTranslateCTM(ctx, 0, layerBounds.size.height);
	CGContextScaleCTM(ctx, 1, -1);
    
    //NSLog(@"clipRect %@", NSStringFromCGRect(CGContextGetClipBoundingBox(ctx)));
    
    CGRect scaledCropRect = [self cropForPage:aPageNumber];
    //CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:arc4random() % 1000 / 1000.0f green:arc4random() % 1000 / 1000.0f blue:arc4random() % 1000 / 1000.0f alpha:1].CGColor);
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);

    CGContextFillRect(ctx, scaledCropRect);
    CGContextClipToRect(ctx, scaledCropRect);
    
//    CGRect insetBounds = UIEdgeInsetsInsetRect(layerBounds, UIEdgeInsetsMake(-inset, -inset, -inset, -inset));
    
    CGDataProviderRef pdfProvider = CGDataProviderCreateWithCFData((CFDataRef)self.pdfData);
    CGPDFDocumentRef aPdf = CGPDFDocumentCreateWithProvider(pdfProvider);
    CGPDFPageRef aPage = CGPDFDocumentGetPage(aPdf, aPageNumber);
    
    //CGContextConcatCTM(ctx, CGPDFPageGetDrawingTransform(aPage, kCGPDFCropBox, insetBounds, 0, true));
    
    
    CGRect unscaledCropRect = CGPDFPageGetBoxRect(aPage, kCGPDFCropBox);
    CGAffineTransform pdfTransform = transformRectToFitRect(unscaledCropRect, scaledCropRect);
    
    CGContextConcatCTM(ctx, pdfTransform);
    BOOL createSnapshot = NO;
//    CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:arc4random() % 1000 / 1000.0f green:arc4random() % 1000 / 1000.0f blue:arc4random() % 1000 / 1000.0f alpha:1].CGColor);
//    CGContextFillRect(ctx, CGPDFPageGetBoxRect(aPage, kCGPDFCropBox));
//    CGContextClipToRect(ctx, CGPDFPageGetBoxRect(aPage, kCGPDFCropBox));
    // Lock around the drawing so we limit the memory footprint
    NSDate *start = [NSDate date];
    @synchronized ([[UIApplication sharedApplication] delegate]) {
        CGContextDrawPDFPage(ctx, aPage);
        CGPDFDocumentRelease(aPdf);
        //if (self.scrollView.zoomScale = 1) createSnapshot = YES;
    }
    NSLog(@"It took %.3f seconds to draw page %d", -[start timeIntervalSinceNow], aPageNumber);
    CGDataProviderRelease(pdfProvider);
    
    // Don't create a thumb when we are zoomed in, we want to limit the size of the cached image
    if (layerContext.a == 1) createSnapshot = YES;
    
    if (createSnapshot) {
        start = [NSDate date];
        CGImageRef imageRef = CGBitmapContextCreateImage(ctx);
        NSDictionary *thumbDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                                         (id)imageRef, @"thumbImage", 
                                         [NSNumber numberWithInteger:aPageNumber], @"pageNumber", nil];
        [self performSelectorInBackground:@selector(cacheThumbImage:) withObject:thumbDictionary];
        
        
        CGImageRelease(imageRef);
        [thumbDictionary release];
        NSLog(@"It took %.3f seconds to create the cache snapshot", -[start timeIntervalSinceNow]);
    }
    
}

#pragma mark -
#pragma mark Shadow Rendering

- (void)drawShadowLayer:(CALayer *)aLayer inContext:(CGContextRef)ctx forPage:(NSInteger)aPageNumber {
    
    CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor);
    CGRect layerBounds = aLayer.bounds;
    CGContextFillRect(ctx, layerBounds);
    
    CGRect cropRect = [self cropForPage:aPageNumber];
    if (CGRectEqualToRect(cropRect, CGRectZero)) return;
        
    CGContextTranslateCTM(ctx, 0, layerBounds.size.height);
	CGContextScaleCTM(ctx, 1, -1);
    
    CGContextSaveGState(ctx);
    CGContextClipToRect(ctx, cropRect);
    CGContextDrawTiledImage(ctx, CGRectMake(0,0,10,10), checkerBoard.CGImage);
    
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:0.57f alpha:1.0f].CGColor);
    CGContextSetLineWidth(ctx, 2);
    CGContextStrokeRect(ctx, cropRect);
    CGContextRestoreGState(ctx);
    
    CGRect leftShadowRect = CGRectMake(cropRect.origin.x-kBlioLayoutShadow, cropRect.origin.y - shadowBottom.size.height, shadowLeft.size.width, cropRect.size.height + 2*kBlioLayoutShadow);
    CGContextDrawImage(ctx, leftShadowRect, shadowLeft.CGImage);
    
    CGRect rightShadowRect = CGRectMake(CGRectGetMaxX(cropRect), cropRect.origin.y - shadowBottom.size.height, shadowRight.size.width, cropRect.size.height + 2*kBlioLayoutShadow);
    CGContextDrawImage(ctx, rightShadowRect, shadowRight.CGImage);
    
    CGRect bottomShadowRect = CGRectMake(cropRect.origin.x-kBlioLayoutShadow, cropRect.origin.y - shadowBottom.size.height, cropRect.size.width + 2*kBlioLayoutShadow, shadowBottom.size.height);
    CGContextDrawImage(ctx, bottomShadowRect, shadowBottom.CGImage);
    
    CGRect topShadowRect = CGRectMake(cropRect.origin.x-kBlioLayoutShadow, CGRectGetMaxY(cropRect), cropRect.size.width + 2*kBlioLayoutShadow, shadowBottom.size.height);
    CGContextDrawImage(ctx, topShadowRect, shadowTop.CGImage);
     
}

#pragma mark -
#pragma mark Highlights

- (NSArray *)highlightRectsForPage:(NSInteger)aPageNumber excluding:(BlioBookmarkRange *)excludedBookmark {
    
    NSInteger pageIndex = aPageNumber - 1;
    NSMutableArray *allHighlights = [NSMutableArray array];
    NSArray *highlightRanges = [self.delegate rangesToHighlightForLayoutPage:aPageNumber];
    NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
    
    for (BlioBookmarkRange *highlightRange in highlightRanges) {
        
        if (![highlightRange isEqual:excludedBookmark]) {
                        
            NSMutableArray *highlightRects = [NSMutableArray array];
            
            for (BlioTextFlowParagraph *paragraph in pageParagraphs) {
                
                for (BlioTextFlowPositionedWord *word in [paragraph words]) {
                    if ((highlightRange.startPoint.layoutPage < aPageNumber) &&
                        (paragraph.paragraphIndex <= highlightRange.endPoint.paragraphOffset) &&
                        (word.wordIndex <= highlightRange.endPoint.wordOffset)) {
                        
                        [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        
                    } else if ((highlightRange.endPoint.layoutPage > aPageNumber) &&
                               (paragraph.paragraphIndex >= highlightRange.startPoint.paragraphOffset) &&
                               (word.wordIndex >= highlightRange.startPoint.wordOffset)) {
                        
                        [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        
                    } else if ((highlightRange.startPoint.layoutPage == aPageNumber) &&
                               (paragraph.paragraphIndex == highlightRange.startPoint.paragraphOffset) &&
                               (word.wordIndex >= highlightRange.startPoint.wordOffset)) {
                        
                        if ((paragraph.paragraphIndex == highlightRange.endPoint.paragraphOffset) &&
                            (word.wordIndex <= highlightRange.endPoint.wordOffset)) {
                            [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        } else if (paragraph.paragraphIndex < highlightRange.endPoint.paragraphOffset) {
                            [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        }
                        
                    } else if ((highlightRange.startPoint.layoutPage == aPageNumber) &&
                               (paragraph.paragraphIndex > highlightRange.startPoint.paragraphOffset)) {
                        
                        if ((paragraph.paragraphIndex == highlightRange.endPoint.paragraphOffset) &&
                            (word.wordIndex <= highlightRange.endPoint.wordOffset)) {
                            [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        } else if (paragraph.paragraphIndex < highlightRange.endPoint.paragraphOffset) {
                            [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        }
                    }
                }
            }
            
            NSArray *coalescedRects = [EucSelector coalescedLineRectsForElementRects:highlightRects];
            
            for (NSValue *rectValue in coalescedRects) {
                BlioLayoutViewColoredRect *coloredRect = [[BlioLayoutViewColoredRect alloc] init];
                coloredRect.color = highlightRange.color;
                coloredRect.rect = [rectValue CGRectValue];
                [allHighlights addObject:coloredRect];
                [coloredRect release];
            }
        }
    
    }
    
    return allHighlights;
}
        

- (void)drawHighlightsLayer:(CALayer *)aLayer inContext:(CGContextRef)ctx forPage:(NSInteger)aPageNumber excluding:(BlioBookmarkRange *)excludedBookmark {
    
    CGAffineTransform viewTransform = [self viewTransformForPage:aPageNumber];
    
    for (BlioLayoutViewColoredRect *coloredRect in [self highlightRectsForPage:aPageNumber excluding:excludedBookmark]) {
        UIColor *highlightColor = [coloredRect color];
        CGContextSetFillColorWithColor(ctx, [highlightColor colorWithAlphaComponent:0.3f].CGColor);
        CGRect adjustedRect = CGRectApplyAffineTransform([coloredRect rect], viewTransform);
        CGContextFillRect(ctx, adjustedRect);
    }
}

- (void)displayHighlightsForLayer:(BlioLayoutPageLayer *)aLayer excluding:(BlioBookmarkRange *)excludedBookmark {  
    [aLayer setExcludedHighlight:excludedBookmark];
    [aLayer refreshHighlights];
}

- (void)refreshHighlights {
    EucSelectorRange *selectedRange = [self.selector selectedRange];
    BlioBookmarkRange *excludedRange = [self bookmarkRangeFromSelectorRange:selectedRange];
    
    [self displayHighlightsForLayer:self.currentPageLayer excluding:excludedRange];
}

#pragma mark -
#pragma mark Selector

- (UIImage *)viewSnapshotImageForEucSelector:(EucSelector *)selector {
    NSLog(@"requesting snapshot");
    BlioLayoutPageLayer *snapLayer = self.currentPageLayer;
    if (nil == snapLayer) return nil;
    
    CGFloat scale = self.scrollView.zoomScale;
    
    CGSize snapSize = snapLayer.bounds.size;
    
 //   CGImageRef imageRef = (CGImageRef)[[snapLayer presentationLayer] contents];
//    UIImage *image = [UIImage imageWithCGImage:imageRef];
//    NSLog(@"got snapshot");
//    return image;
    
    // Increase snapshot height by 78 to allow for an overlap below the bottom of the page;
    //    snapSize.height += 78; 
    
    UIGraphicsBeginImageContext(snapSize);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGPoint translatePoint = [self.window.layer convertPoint:CGPointZero toLayer:snapLayer];
    CGContextScaleCTM(ctx, scale, scale);
    CGContextTranslateCTM(ctx, -translatePoint.x, -translatePoint.y);
    
    [[snapLayer shadowLayer] renderInContext:ctx];
    [[snapLayer tiledLayer] renderInContext:ctx];
    [[snapLayer highlightsLayer] renderInContext:ctx];
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSLog(@"got snapshot");

    return snapshot;
}

- (UIView *)viewForMenuForEucSelector:(EucSelector *)selector {
    return self.contentView;
}

- (EucSelectorRange *)selectorRangeFromBookmarkRange:(BlioBookmarkRange *)range {
    if (nil == range) return nil;
    
    NSInteger pageIndex = self.pageNumber - 1;
    
    EucSelectorRange *selectorRange = [[EucSelectorRange alloc] init];
    selectorRange.startBlockId = [BlioTextFlowParagraph paragraphIDForPageIndex:pageIndex paragraphIndex:range.startPoint.paragraphOffset];
    selectorRange.startElementId = [BlioTextFlowPositionedWord wordIDForWordIndex:range.startPoint.wordOffset];
    selectorRange.endBlockId = [BlioTextFlowParagraph paragraphIDForPageIndex:pageIndex paragraphIndex:range.endPoint.paragraphOffset];
    selectorRange.endElementId = [BlioTextFlowPositionedWord wordIDForWordIndex:range.endPoint.wordOffset];
    
    return [selectorRange autorelease];
}

- (BlioBookmarkRange *)bookmarkRangeFromSelectorRange:(EucSelectorRange *)range {
    
    if (nil == range) return nil;
    
    NSInteger currentPage = self.pageNumber;
    
    BlioBookmarkPoint *startPoint = [[BlioBookmarkPoint alloc] init];
    startPoint.layoutPage = currentPage;
    startPoint.paragraphOffset = [BlioTextFlowParagraph paragraphIndexForParagraphID:range.startBlockId];
    startPoint.wordOffset = [BlioTextFlowPositionedWord wordIndexForWordID:range.startElementId];
    
    BlioBookmarkPoint *endPoint = [[BlioBookmarkPoint alloc] init];
    endPoint.layoutPage = currentPage;
    endPoint.paragraphOffset = [BlioTextFlowParagraph paragraphIndexForParagraphID:range.endBlockId];
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
    NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
    NSUInteger maxOffset = [pageParagraphs count];
    
    BlioBookmarkPoint *startPoint = [[BlioBookmarkPoint alloc] init];
    startPoint.layoutPage = self.pageNumber;
    startPoint.paragraphOffset = 0;
    
    BlioBookmarkPoint *endPoint = [[BlioBookmarkPoint alloc] init];
    endPoint.layoutPage = self.pageNumber;
    endPoint.paragraphOffset = maxOffset;
    
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

- (UIColor *)eucSelector:(EucSelector *)aSelector willBeginEditingHighlightWithRange:(EucSelectorRange *)selectedRange {
    
    
    for (BlioBookmarkRange *highlightRange in [self bookmarkRangesForCurrentPage]) {
        EucSelectorRange *range = [self selectorRangeFromBookmarkRange:highlightRange];
        if ([selectedRange isEqual:range]) {
            [self displayHighlightsForLayer:self.currentPageLayer excluding:highlightRange];
            return [highlightRange.color colorWithAlphaComponent:0.3f];
        }
    }
    
    return nil;
}

- (void)eucSelector:(EucSelector *)selector didEndEditingHighlightWithRange:(EucSelectorRange *)fromRange movedToRange:(EucSelectorRange *)toRange {
    
    if ((nil != toRange) && ![fromRange isEqual:toRange]) {
    
        BlioBookmarkRange *fromBookmarkRange = [self bookmarkRangeFromSelectorRange:fromRange];
        BlioBookmarkRange *toBookmarkRange = [self bookmarkRangeFromSelectorRange:toRange];

        if ([self.delegate respondsToSelector:@selector(updateHighlightAtRange:toRange:withColor:)])
            [self.delegate updateHighlightAtRange:fromBookmarkRange toRange:toBookmarkRange withColor:nil];
        
    }
    
    // Set this to nil now because the refresh depends on it
    [self.selector setSelectedRange:nil];
    [self refreshHighlights];
}

- (NSArray *)blockIdentifiersForEucSelector:(EucSelector *)selector {
    NSInteger pageIndex = self.pageNumber - 1;
    NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
    NSMutableArray *identifiers = [NSMutableArray array];
    for (BlioTextFlowParagraph *paragraph in pageParagraphs) {
        [identifiers addObject:[paragraph paragraphID]];
    }
    return identifiers;
}

- (CGRect)eucSelector:(EucSelector *)selector frameOfBlockWithIdentifier:(id)paragraphID {
    CGRect pageRect = CGRectZero;
    
    NSInteger pageIndex = [BlioTextFlowParagraph pageIndexForParagraphID:paragraphID];
    NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
    NSInteger currentIndex = [BlioTextFlowParagraph paragraphIndexForParagraphID:paragraphID];
    
    if ([pageParagraphs count] > currentIndex) {
        CGRect blockRect = [[pageParagraphs objectAtIndex:currentIndex] rect];
//        CGAffineTransform viewTransform = [[self.currentPageLayer view] viewTransform];
        CGAffineTransform viewTransform = [self viewTransformForPage:[self.currentPageLayer pageNumber]];
        pageRect = CGRectApplyAffineTransform(blockRect, viewTransform);
    }
    
    return pageRect;
}

- (NSArray *)eucSelector:(EucSelector *)selector identifiersForElementsOfBlockWithIdentifier:(id)paragraphID; {
    NSInteger pageIndex = [BlioTextFlowParagraph pageIndexForParagraphID:paragraphID];
    NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
    NSInteger currentIndex = [BlioTextFlowParagraph paragraphIndexForParagraphID:paragraphID];
    
    if ([pageParagraphs count] > currentIndex) {
        NSMutableArray *identifiers = [NSMutableArray array];
        for (BlioTextFlowPositionedWord *word in [[pageParagraphs objectAtIndex:currentIndex] words]) {
            [identifiers addObject:[word wordID]];
        }
        return identifiers;
    } else {
        return [NSArray array];
    }
}

- (NSArray *)eucSelector:(EucSelector *)selector rectsForElementWithIdentifier:(id)wordID ofBlockWithIdentifier:(id)paragraphID {    
    CGRect pageRect = CGRectZero;
    
    NSInteger pageIndex = [BlioTextFlowParagraph pageIndexForParagraphID:paragraphID];
    NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
    NSInteger currentIndex = [BlioTextFlowParagraph paragraphIndexForParagraphID:paragraphID];
    
    if ([pageParagraphs count] > currentIndex) {
        NSArray *words = [[pageParagraphs objectAtIndex:currentIndex] words];
        NSInteger offset = [wordID integerValue];
        if (offset < [words count]) {
            CGRect wordRect = [[words objectAtIndex:offset] rect];
//            CGAffineTransform viewTransform = [[self.currentPageLayer view] viewTransform];
            CGAffineTransform viewTransform = [self viewTransformForPage:[self.currentPageLayer pageNumber]];
            pageRect = CGRectApplyAffineTransform(wordRect, viewTransform);
        }
    }
    
    return [NSArray arrayWithObject:[NSValue valueWithCGRect:pageRect]];
}

- (NSArray *)colorMenuItems {    
    EucMenuItem *yellowItem = [[[EucMenuItem alloc] initWithTitle:@"●" action:@selector(highlightColorYellow:)] autorelease];
    yellowItem.color = [UIColor yellowColor];
    
    EucMenuItem *redItem = [[[EucMenuItem alloc] initWithTitle:@"●" action:@selector(highlightColorRed:)] autorelease];
    redItem.color = [UIColor redColor];
    
    EucMenuItem *blueItem = [[[EucMenuItem alloc] initWithTitle:@"●" action:@selector(highlightColorBlue:)] autorelease];
    blueItem.color = [UIColor blueColor];
    
    EucMenuItem *greenItem = [[[EucMenuItem alloc] initWithTitle:@"●" action:@selector(highlightColorGreen:)] autorelease];
    greenItem.color = [UIColor greenColor];
    
    NSArray *ret = [NSArray arrayWithObjects:yellowItem, redItem, blueItem, greenItem, nil];
        
    return ret;
}

- (NSArray *)webToolsMenuItems {    
    EucMenuItem *dictionaryItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Dictionary", "\"Dictionary\" option in popup menu in layout view")
                                                               action:@selector(dictionary:)] autorelease];
    
    //EucMenuItem *thesaurusItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Thesaurus", "\"Thesaurus\" option in popup menu in layout view")
    //                                                          action:@selector(thesaurus:)] autorelease];
    
    EucMenuItem *wikipediaItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Encyclopedia", "\"Encyclopedia\" option in popup menu in layout view")
                                                              action:@selector(encyclopedia:)] autorelease];
    
    EucMenuItem *searchItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Search", "\"Search\" option in popup menu in layout view")
                                                           action:@selector(search:)] autorelease];
        
    NSArray *ret = [NSArray arrayWithObjects:dictionaryItem/*, thesaurusItem*/, wikipediaItem, searchItem, nil];
    
    return ret;
}

- (NSArray *)highlightMenuItemsWithCopy:(BOOL)copy {
    EucMenuItem *addNoteItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Note", "\"Note\" option in popup menu in layout view")                                                    
                                                            action:@selector(addNote:)] autorelease];
    
    EucMenuItem *copyItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy", "\"Copy\" option in popup menu in layout view")
                                                         action:@selector(copy:)] autorelease];
    
    EucMenuItem *colorItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Color", "\"Color\" option in popup menu in layout view")
                                                          action:@selector(showColorMenu:)] autorelease];
    
    EucMenuItem *removeItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Remove", "\"Remove Highlight\" option in popup menu in layout view")
                                                           action:@selector(removeHighlight:)] autorelease];

    NSArray *ret;
    if (copy)
        ret = [NSArray arrayWithObjects:removeItem, addNoteItem, copyItem, colorItem, nil];
    else
        ret = [NSArray arrayWithObjects:removeItem, addNoteItem, colorItem, nil];

    return ret;
}

- (NSArray *)rootMenuItemsWithCopy:(BOOL)copy {
    EucMenuItem *highlightItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Highlight", "\"Hilight\" option in popup menu in layout view")                                                              
                                                              action:@selector(highlight:)] autorelease];
    EucMenuItem *addNoteItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Note", "\"Note\" option in popup menu in layout view")                                                    
                                                            action:@selector(addNote:)] autorelease];
    EucMenuItem *copyItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy", "\"Copy\" option in popup menu in layout view")
                                                         action:@selector(copy:)] autorelease];
    EucMenuItem *showWebToolsItem = [[[EucMenuItem alloc] initWithTitle:NSLocalizedString(@"Tools", "\"Tools\" option in popup menu in layout view")
                                                                 action:@selector(showWebTools:)] autorelease];
    
    NSArray *ret;
    if (copy)
        ret = [NSArray arrayWithObjects:highlightItem, addNoteItem, copyItem, showWebToolsItem, nil];
    else
        ret = [NSArray arrayWithObjects:highlightItem, addNoteItem, showWebToolsItem, nil];
    
    return ret;
}

- (NSArray *)menuItemsForEucSelector:(EucSelector *)hilighter {
    if ([self.selector selectedRangeIsHighlight])
        return [self highlightMenuItemsWithCopy:YES];
    else
        return [self rootMenuItemsWithCopy:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.selector) {
        if ([keyPath isEqualToString:@"tracking"]) {
            if (((EucSelector *)object).isTracking) {
                [self.delegate hideToolbars];
            } else {
                [self.scrollView setScrollEnabled:YES];
            }
                
        } else if ([keyPath isEqualToString:@"trackingStage"]) {
            
            switch ([(EucSelector *)object trackingStage]) {
                case EucSelectorTrackingStageNone:
                    [self.scrollView setScrollEnabled:YES];
                    break;
                case EucSelectorTrackingStageFirstSelection:
                    [self.scrollView setScrollEnabled:NO];
                    break;
                case EucSelectorTrackingStageSelectedAndWaiting:
                    [self.scrollView setScrollEnabled:YES];
                    break;
                case EucSelectorTrackingStageChangingSelection:
                    [self.scrollView setScrollEnabled:NO];
                    break;
                default:
                    break;
            }

        }
    } else if (object == self) {
        if ([keyPath isEqualToString:@"currentPageLayer"]) {
            NSLog(@"pageLayer changed to page %d", self.currentPageLayer.pageNumber);
            [self.selector setSelectedRange:nil];
            [self.selector setSelectedRange:nil];
            [self.selector attachToLayer:self.currentPageLayer];
            [self displayHighlightsForLayer:self.currentPageLayer excluding:nil];
            
        }
    }
}

- (BlioBookmarkRange *)selectedRange {
    EucSelectorRange *highlighterRange = [self.selector selectedRange];
    
    BlioBookmarkPoint *startPoint = [[BlioBookmarkPoint alloc] init];
    BlioBookmarkPoint *endPoint = [[BlioBookmarkPoint alloc] init];;

    if (nil != highlighterRange) {        
        NSInteger startPageIndex = [BlioTextFlowParagraph pageIndexForParagraphID:[highlighterRange startBlockId]];
        NSInteger endPageIndex = [BlioTextFlowParagraph pageIndexForParagraphID:[highlighterRange endBlockId]];
        NSInteger startParagraphOffset = [BlioTextFlowParagraph paragraphIndexForParagraphID:[highlighterRange startBlockId]];
        NSInteger endParagraphOffset = [BlioTextFlowParagraph paragraphIndexForParagraphID:[highlighterRange endBlockId]];
        NSInteger startWordOffset = [BlioTextFlowPositionedWord wordIndexForWordID:[highlighterRange startElementId]];
        NSInteger endWordOffset = [BlioTextFlowPositionedWord wordIndexForWordID:[highlighterRange endElementId]];
        
        
        [startPoint setLayoutPage:startPageIndex + 1];
        [startPoint setParagraphOffset:startParagraphOffset];
        [startPoint setWordOffset:startWordOffset];
        
        [endPoint setLayoutPage:endPageIndex + 1];
        [endPoint setParagraphOffset:endParagraphOffset];
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
    if ([self.selector selectedRangeIsHighlight]) {
        BlioBookmarkRange *fromBookmarkRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRangeOriginalHighlightRange]];
        BlioBookmarkRange *toBookmarkRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRange]];
        
        if ([self.delegate respondsToSelector:@selector(updateHighlightAtRange:toRange:withColor:)])
            [self.delegate updateHighlightAtRange:fromBookmarkRange toRange:toBookmarkRange withColor:color];
        
        // Deselect, this will fire the endEditing highlight callback which refreshes
        [self.selector setSelectedRange:nil];

    } else {
        
        if ([self.delegate respondsToSelector:@selector(addHighlightWithColor:)])
            [self.delegate addHighlightWithColor:color];
        
        // Set this to nil now because the refresh depends on it
        [self.selector setSelectedRange:nil];
        [self refreshHighlights];
    }
    
    self.lastHighlightColor = color;
}

- (void)highlightColorYellow:(id)sender {
    [self addHighlightWithColor:[UIColor yellowColor]];
}

- (void)highlightColorRed:(id)sender {
    [self addHighlightWithColor:[UIColor redColor]];
}

- (void)highlightColorBlue:(id)sender {
    [self addHighlightWithColor:[UIColor blueColor]];
}

- (void)highlightColorGreen:(id)sender {
    [self addHighlightWithColor:[UIColor greenColor]];
}

- (void)highlight:(id)sender {
    [self addHighlightWithColor:self.lastHighlightColor];
}

- (void)showColorMenu:(id)sender {
    [self.selector changeActiveMenuItemsTo:[self colorMenuItems]];
}

- (void)removeHighlight:(id)sender {
    BlioBookmarkRange *highlightRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRangeOriginalHighlightRange]];

    if ([self.delegate respondsToSelector:@selector(removeHighlightAtRange:)])
        [self.delegate removeHighlightAtRange:highlightRange];
    
    // Set this to nil now because the refresh depends on it
    [self.selector setSelectedRange:nil];
    [self refreshHighlights];
}

- (void)addNote:(id)sender {
    if ([self.selector selectedRangeIsHighlight]) {
        BlioBookmarkRange *highlightRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRangeOriginalHighlightRange]];
        if ([self.delegate respondsToSelector:@selector(updateHighlightNoteAtRange:withColor:)])
            [self.delegate updateHighlightNoteAtRange:highlightRange withColor:nil];
    } else {
        if ([self.delegate respondsToSelector:@selector(addHighlightNoteWithColor:)])
            [self.delegate addHighlightNoteWithColor:self.lastHighlightColor];
    }
    
    // TODO - this probably doesn't want to deselect yet in case the note is cancelled
    // Or the selection could be saved and reinstated
    // Or we could just not bother but it might be annoying
    [self.selector setSelectedRange:nil];
    [self refreshHighlights];
}

- (void)copy:(id)sender {    
    BlioBookmarkRange *copyRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRange]];
    if ([self.delegate respondsToSelector:@selector(copyWithRange:)]) {
        [self.delegate copyWithRange:copyRange];
        
        if ([self.selector selectedRangeIsHighlight])
            [self.selector changeActiveMenuItemsTo:[self highlightMenuItemsWithCopy:NO]];
        else
            [self.selector changeActiveMenuItemsTo:[self rootMenuItemsWithCopy:NO]];
    }    
}

- (void)showWebTools:(id)sender {
    [self.selector changeActiveMenuItemsTo:[self webToolsMenuItems]];
}


- (void)dictionary:(id)sender {
    BlioBookmarkRange *webToolRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRange]];
    if ([self.delegate respondsToSelector:@selector(openWebToolWithRange:toolType:)]) {
        [self.delegate openWebToolWithRange:webToolRange  toolType:dictionaryTool];
        [self.selector setSelectedRange:nil];
    }
}

/*
- (void)thesaurus:(id)sender {
    BlioBookmarkRange *webToolRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRange]];
    if ([self.delegate respondsToSelector:@selector(openWebToolWithRange:toolType:)]) {
        [self.delegate openWebToolWithRange:webToolRange toolType:thesaurusTool];
        
        [self.selector setSelectedRange:nil];
    }
}
 */

- (void)encyclopedia:(id)sender {
    BlioBookmarkRange *webToolRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRange]];
    if ([self.delegate respondsToSelector:@selector(openWebToolWithRange:toolType:)]) {
        [self.delegate openWebToolWithRange:webToolRange toolType:encyclopediaTool];
        [self.selector setSelectedRange:nil];
    }
}

- (void)search:(id)sender {
    BlioBookmarkRange *webToolRange = [self bookmarkRangeFromSelectorRange:[self.selector selectedRange]];
    if ([self.delegate respondsToSelector:@selector(openWebToolWithRange:toolType:)]) {
        [self.delegate openWebToolWithRange:webToolRange toolType:searchTool];
        [self.selector setSelectedRange:nil];
    }
}

- (UIColor *)lastHighlightColor {
    if (nil == lastHighlightColor) {
        lastHighlightColor = [UIColor yellowColor];
        [lastHighlightColor retain];
    }
    
    return lastHighlightColor;
}

#pragma mark -
#pragma mark TTS

- (id)getCurrentParagraphId {
    NSInteger pageIndex = self.pageNumber - 1;
    NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];

    if (![pageParagraphs count])
        return nil;
    else
        return [[pageParagraphs objectAtIndex:0] paragraphID];
}

- (uint32_t)getCurrentWordOffset {
    return 0;
}

- (id)paragraphIdForParagraphAfterParagraphWithId:(id)paragraphID {    
    if (!paragraphID) {
        NSInteger pageIndex = -1;
        while (++pageIndex < ([self pageCount])) {
            NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
            if ([pageParagraphs count])
                return (id)[[pageParagraphs objectAtIndex:0] paragraphID];
        }
        return nil;
    } else {

        NSInteger pageIndex = [BlioTextFlowParagraph pageIndexForParagraphID:paragraphID];
        NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
        NSInteger currentIndex = [BlioTextFlowParagraph paragraphIndexForParagraphID:paragraphID];
        
            if (++currentIndex < [pageParagraphs count]) {
                return (id)[[pageParagraphs objectAtIndex:currentIndex] paragraphID];
            } else {
                while (++pageIndex < ([self pageCount])) {
                    NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
                    if ([pageParagraphs count])
                        return (id)[[pageParagraphs objectAtIndex:0] paragraphID];
                }
            }
        
    }
    return nil;
}

- (NSArray *)paragraphWordsForParagraphWithId:(id)paragraphID {
    NSInteger pageIndex = [BlioTextFlowParagraph pageIndexForParagraphID:paragraphID];
    NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
    NSInteger currentIndex = [BlioTextFlowParagraph paragraphIndexForParagraphID:paragraphID];
    
    if ([pageParagraphs count] > currentIndex)
        return [[pageParagraphs objectAtIndex:currentIndex] wordsArray];
    else
        return nil;
    
}

- (void)highlightWordAtParagraphId:(id)paragraphID wordOffset:(uint32_t)wordOffset {
    NSInteger pageIndex = [BlioTextFlowParagraph pageIndexForParagraphID:paragraphID];
    NSArray *pageParagraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
    NSInteger currentIndex = [BlioTextFlowParagraph paragraphIndexForParagraphID:paragraphID];
    
    if ([pageParagraphs count] > currentIndex) {
        BlioTextFlowParagraph *currentParagraph = [pageParagraphs objectAtIndex:currentIndex];
        NSInteger targetPageNumber = ++pageIndex;
        if ((self.pageNumber != targetPageNumber) && !self.disableScrollUpdating) {
            [self goToPageNumber:targetPageNumber animated:YES];
        }
        
        NSArray *words = [currentParagraph words];
        if ([words count] > wordOffset) {
            BlioTextFlowPositionedWord *word = [words objectAtIndex:wordOffset];
            [self.selector temporarilyHighlightElementWithIdentfier:[word wordID] inBlockWithIdentifier:paragraphID animated:YES];
        }
                                                   
    }

}

#pragma mark -
#pragma mark BlioBookView Protocol Methods

- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated {
    return;
}

- (void)gotoCurrentPageAnimated {
    [self goToPageNumber:self.pageNumber animated:YES];
}

- (void)goToPageNumber:(NSInteger)targetPage animated:(BOOL)animated {
    
    if (targetPage < 1 )
        targetPage = 1;
    else if (targetPage > pageCount)
        targetPage = pageCount;
    
    [self willChangeValueForKey:@"pageNumber"];
    
    if (animated) {
        // Animation steps:
        // 1. Move the current page and its adjacent pages next to the target page's adjacent pages
        // 2. Load the target page and its adjacent pages
        // 3. Zoom out the current page
        // 4. Scroll to the target page
        // 5. Zoom in the target page
        
        // 1. Move the current page and its adjacent pages next to the target page's adjacent pages
        CGFloat pageWidth = self.scrollView.contentSize.width / pageCount;
        NSInteger startPage = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 2;
        if (startPage == targetPage) return;
        
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        self.pageNumber = targetPage;
        NSInteger pagesToGo = targetPage - startPage;
        NSInteger pagesToOffset = 0;
        
        self.disableScrollUpdating = YES;
        [self.scrollView setPagingEnabled:NO]; // Paging affects the animations
        
        CGPoint currentOffset = self.scrollView.contentOffset;
        NSMutableSet *pageLayersToPreserve = [NSMutableSet set];
        
        
        if (abs(pagesToGo) > 3) {
            pagesToOffset = pagesToGo - (3 * (pagesToGo/abs(pagesToGo)));
            CGFloat frameOffset = pagesToOffset * self.scrollView.frame.size.width;
//            CGRect firstFrame = CGRectMake((startPage - 2) * self.scrollView.frame.size.width, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
//            CGRect lastFrame = CGRectMake((startPage - 2 + 2) * self.scrollView.frame.size.width, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
//            CGRect pagesToOffsetRect = CGRectUnion(firstFrame, lastFrame);
            
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey: kCATransactionDisableActions];
                        
            if (self.currentPageLayer) {
                CGRect newFrame = self.currentPageLayer.frame;
                newFrame.origin.x += frameOffset;
                self.currentPageLayer.frame = newFrame;
                [pageLayersToPreserve addObject:self.currentPageLayer];
            }

            NSSet *prevLayerSet = [[self.contentView pageLayers] filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"pageNumber==%d", startPage - 1]];
            if ([prevLayerSet count]) {
                CALayer *prevLayer = [[prevLayerSet allObjects] objectAtIndex:0];
                CGRect newFrame = self.currentPageLayer.frame;
                newFrame.origin.x -= pageWidth;
                prevLayer.frame = newFrame;
                [pageLayersToPreserve addObject:prevLayer];
            } else {
                NSLog(@"No prev found");
            }
            
            NSSet *nextLayerSet = [[self.contentView pageLayers] filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"pageNumber==%d", startPage + 1]];
            if ([nextLayerSet count]) {
                CALayer *nextLayer = [[nextLayerSet allObjects] objectAtIndex:0];
                CGRect newFrame = self.currentPageLayer.frame;
                newFrame.origin.x += pageWidth;
                nextLayer.frame = newFrame;
                [pageLayersToPreserve addObject:nextLayer];
            } else {
                NSLog(@"No next found");
            }

            [CATransaction commit];
            
            /*
            for (BlioPDFPageView *page in self.pageViews) {
                if (!CGRectIsNull(CGRectIntersection(page.frame, pagesToOffsetRect))) {
                    NSInteger preservePageNum = CGPDFPageGetPageNumber([page.view page]);
                    if (NSLocationInRange(preservePageNum, NSMakeRange(startPage - 1, 3))) {
                        CGRect newFrame = page.frame;
                        newFrame.origin.x += frameOffset;
                        page.frame = newFrame;
                        [page setValid:NO];
                        BlioPDFPageView *existingPage = nil;
                        for (BlioPDFPageView *preservedPage in pagesToPreserve) {
                            if ((CGRectEqualToRect(page.frame, preservedPage.frame)) &&
                                (preservePageNum == CGPDFPageGetPageNumber([preservedPage.view page]))) {
                                    existingPage = page;
                                    break;
                                }
                        }
                        if (nil == existingPage) [pagesToPreserve addObject:page];
                    } //else {
//                        NSLog(@"Page in position but wrong page number");
//                    }
                }
            }
             */
            currentOffset = CGPointMake(currentOffset.x + frameOffset*self.scrollView.zoomScale, currentOffset.y);
            [self.scrollView setContentOffset:currentOffset animated:NO];
        }
        
        if ([pageLayersToPreserve count] > 3) {
            NSLog(@"WARNING: more than 3 pages found to preserve during go to animation: %@", [pageLayersToPreserve description]); 
        } else if ([pageLayersToPreserve count] < 3) {
            NSLog(@"Less than 3");
        }
        
        // 2. Load the target page and its adjacent pages
        BlioLayoutPageLayer *aLayer = [self.contentView addPage:targetPage retainPages:pageLayersToPreserve];
        if (aLayer) {
            [pageLayersToPreserve addObject:aLayer];
            self.currentPageLayer = aLayer;
        }
        aLayer = [self.contentView addPage:targetPage - 1 retainPages:pageLayersToPreserve];
        if (aLayer) [pageLayersToPreserve addObject:aLayer];
        [self.contentView addPage:targetPage + 1 retainPages:pageLayersToPreserve];
        
        // The rest of the steps are performed after the animation thread has been run
        NSInteger fromPage = startPage + pagesToOffset;

        NSMethodSignature * mySignature = [BlioLayoutView instanceMethodSignatureForSelector:@selector(performGoToPageStep1FromPage:)];
        NSInvocation * myInvocation = [NSInvocation invocationWithMethodSignature:mySignature];    
        [myInvocation setTarget:self];    
        [myInvocation setSelector:@selector(performGoToPageStep1FromPage:)];
        [myInvocation setArgument:&fromPage atIndex:2];
        [myInvocation performSelector:@selector(invoke) withObject:nil afterDelay:0.1f];
    } else {
        self.currentPageLayer = [self.contentView addPage:targetPage retainPages:nil];
        [self.contentView addPage:targetPage - 1 retainPages:nil];
        [self.contentView addPage:targetPage + 1 retainPages:nil];

        [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width * pageCount * self.scrollView.zoomScale, self.scrollView.frame.size.height * self.scrollView.zoomScale)];
        [self.scrollView setContentOffset:CGPointMake((targetPage - 1) * self.scrollView.frame.size.width * self.scrollView.zoomScale, 0)];
        self.pageNumber = targetPage;
        [self didChangeValueForKey:@"pageNumber"];
    }
}

- (void)performGoToPageStep1FromPage:(NSInteger)fromPage {

    [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width * pageCount * self.scrollView.zoomScale, self.scrollView.frame.size.height * self.scrollView.zoomScale)];
    [self.scrollView setContentOffset:CGPointMake(((fromPage - 1) * self.scrollView.bounds.size.width * kBlioPDFGoToZoomScale) - (self.scrollView.bounds.size.width * ((1-kBlioPDFGoToZoomScale)/2.0f)), self.scrollView.frame.size.height * ((1-kBlioPDFGoToZoomScale)/-2.0f))];
    
    CFTimeInterval shrinkDuration = 0.25f + (0.5f * (self.scrollView.zoomScale / self.scrollView.maximumZoomScale));
    [UIView beginAnimations:@"BlioLayoutGoToPageStep1" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [UIView setAnimationDuration:shrinkDuration];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [self.scrollView setMinimumZoomScale:kBlioPDFGoToZoomScale];
    [self.scrollView setZoomScale:kBlioPDFGoToZoomScale];
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width * pageCount * self.scrollView.zoomScale, self.scrollView.frame.size.height * self.scrollView.zoomScale)];
    [self.scrollView setContentOffset:CGPointMake(((fromPage - 1) * self.scrollView.bounds.size.width * kBlioPDFGoToZoomScale) - (self.scrollView.bounds.size.width * ((1-kBlioPDFGoToZoomScale)/2.0f)), self.scrollView.frame.size.height * ((1-kBlioPDFGoToZoomScale)/-2.0f))];
    [UIView commitAnimations];
}
    
- (void)performGoToPageStep2 {
    CFTimeInterval scrollDuration = 0.75f;
    [UIView beginAnimations:@"BlioLayoutGoToPageStep2" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [UIView setAnimationDuration:scrollDuration];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [self.scrollView setContentOffset:CGPointMake(((self.pageNumber - 1) * self.scrollView.bounds.size.width * kBlioPDFGoToZoomScale) - (self.scrollView.bounds.size.width * ((1-kBlioPDFGoToZoomScale)/2.0f)), self.scrollView.frame.size.height * ((1-kBlioPDFGoToZoomScale)/-2.0f))];
    [UIView commitAnimations];
}

- (void)performGoToPageStep3 {  
    
    CFTimeInterval zoomDuration = 0.25f;
    [UIView beginAnimations:@"BlioLayoutGoToPageStep3" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:zoomDuration];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [self.scrollView setMinimumZoomScale:1];
    [self.scrollView setZoomScale:1];
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width * pageCount * self.scrollView.zoomScale, self.scrollView.frame.size.height * self.scrollView.zoomScale)];
    [self.scrollView setContentOffset:CGPointMake((self.pageNumber - 1) * self.scrollView.frame.size.width, 0)];
    [UIView commitAnimations];
    [self didChangeValueForKey:@"pageNumber"];
}

- (BlioBookmarkAbsolutePoint *)pageBookmarkPoint
{
    BlioBookmarkAbsolutePoint *ret = [[BlioBookmarkAbsolutePoint alloc] init];
    ret.layoutPage = self.pageNumber;
    return [ret autorelease];
}

- (void)goToBookmarkPoint:(BlioBookmarkAbsolutePoint *)bookmarkPoint animated:(BOOL)animated
{
    [self goToPageNumber:bookmarkPoint.layoutPage animated:animated];
}

- (void)goToBookmarkRange:(BlioBookmarkRange *)bookmarkRange animated:(BOOL)animated {
    [self goToPageNumber:bookmarkRange.startPoint.layoutPage animated:animated];
}

- (NSInteger)pageNumberForBookmarkPoint:(BlioBookmarkAbsolutePoint *)bookmarkPoint
{
    return bookmarkPoint.layoutPage;
}

- (NSInteger)pageNumberForBookmarkRange:(BlioBookmarkRange *)bookmarkRange {
    return bookmarkRange.startPoint.layoutPage;
}

- (id<EucBookContentsTableViewControllerDataSource>)contentsDataSource {
    return self;
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    if (finished) {
        //NSLog(@"Animation: %@ did finish", animationID);
        if ([animationID isEqualToString:@"BlioLayoutGoToPageStep1"]) {
            [self performSelector:@selector(performGoToPageStep2)];
        } else if ([animationID isEqualToString:@"BlioLayoutGoToPageStep2"]) {
            [self performSelector:@selector(performGoToPageStep3)];
        } else if ([animationID isEqualToString:@"BlioLayoutGoToPageStep3"]) {
            [self scrollViewDidEndScrollingAnimation:self.scrollView];
            [self scrollViewDidEndZooming:self.scrollView withView:self.scrollView atScale:self.scrollView.zoomScale];
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        } else if ([animationID isEqualToString:@"BlioZoomPage"]) {
            [self scrollViewDidEndZooming:self.scrollView withView:self.scrollView atScale:self.scrollView.zoomScale];
            [self performSelector:@selector(enableInteractions) withObject:nil afterDelay:0.1f];
        }
    }
} 

#pragma mark -
#pragma mark Contents Data Source protocol methods

- (NSArray *)sectionUuids
{
  return [NSArray arrayWithObject:@"dummy-uuid"];
}

- (NSString *)sectionUuidForPageNumber:(NSUInteger)page
{
  return @"dummy-uuid";
}

- (THPair *)presentationNameAndSubTitleForSectionUuid:(NSString *)sectionUuid
{
  return NULL;
}

- (NSInteger)pageNumberForSectionUuid:(NSString *)sectionUuid
{
  return 1; // only one section, very easy
}

- (NSString *)displayPageNumberForPageNumber:(NSInteger)aPageNumber
{
  return [NSString stringWithFormat:@"%d", aPageNumber];
}

- (CGRect)firstPageRect {
    if ([self pageCount] > 0) {
        CGPDFPageRef firstPage = CGPDFDocumentGetPage(pdf, 1);
        CGFloat inset = -kBlioLayoutShadow;
        CGRect insetBounds = UIEdgeInsetsInsetRect([[UIScreen mainScreen] bounds], UIEdgeInsetsMake(-inset, -inset, -inset, -inset));
        CGAffineTransform fitTransform = CGPDFPageGetDrawingTransform(firstPage, kCGPDFCropBox, insetBounds, 0, true);
        CGRect coverRect = CGPDFPageGetBoxRect(firstPage, kCGPDFCropBox);
        return CGRectApplyAffineTransform(coverRect, fitTransform);
    } else {
        return [[UIScreen mainScreen] bounds];
    }
}
    
#pragma mark -
#pragma mark Container UIScrollView Delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.contentView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)aScrollView withView:(UIView *)view atScale:(float)scale {

    if([self.selector isTracking])
        [self.selector redisplaySelectedRange];
    
    if (![self.scrollView isDragging]) {
        [self.selector setShouldHideMenu:NO];
    }

    
    if (scale == 1.0f) {
        scrollView.pagingEnabled = YES;
        scrollView.bounces = YES;
        scrollView.directionalLockEnabled = NO;
    } else {
        scrollView.pagingEnabled = NO;
        scrollView.bounces = NO;
        scrollView.directionalLockEnabled = YES;
    }
    
}

- (void)enableInteractions {
    self.disableScrollUpdating = NO;
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)aScrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self.selector setShouldHideMenu:NO];
    }
    if (tiltScroller) [tiltScroller resetAngle];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    [self.selector setShouldHideMenu:YES];

    if (self.disableScrollUpdating) return;

    NSInteger currentPageNumber;
    
    if (sender.zoomScale != lastZoomScale) {
        [sender setContentSize:CGSizeMake(sender.frame.size.width * pageCount * sender.zoomScale, sender.frame.size.height * sender.zoomScale)];
        self.lastZoomScale = sender.zoomScale;
        
        // If we are zooming, don't update the page number - (contentOffset gets set to zero so it wouldn't work)
        currentPageNumber = self.pageNumber;
    } else {
        CGFloat pageWidth = sender.contentSize.width / pageCount;
        currentPageNumber = floor((sender.contentOffset.x + CGRectGetWidth(self.bounds)/2.0f) / pageWidth) + 1;
    }
    
    
    if (currentPageNumber != self.pageNumber) {
        
        BlioLayoutPageLayer *aLayer = [self.contentView addPage:currentPageNumber retainPages:nil];
        
        if (!self.scrollToPageInProgress) {
            if (currentPageNumber < self.pageNumber) {
                [self.contentView addPage:currentPageNumber - 1 retainPages:nil];
            }
            if (currentPageNumber > self.pageNumber) {
                [self.contentView addPage:currentPageNumber + 1 retainPages:nil];
            }
            self.pageNumber = currentPageNumber;
            self.currentPageLayer = aLayer;
        }

    }
}

- (void)updateAfterScroll {
    [self.selector setShouldHideMenu:NO];
    if (self.disableScrollUpdating) return;
    
    
    if (self.scrollToPageInProgress) {
        self.scrollToPageInProgress = NO;
        
        [self.contentView addPage:self.pageNumber - 1 retainPages:nil];
        [self.contentView addPage:self.pageNumber + 1 retainPages:nil];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    self.disableScrollUpdating = NO;
    [self updateAfterScroll];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self updateAfterScroll];
}

- (void)zoomAtPoint:(NSString *)pointString {
    if ([self.scrollView isDecelerating]) return;
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    CGPoint point = CGPointFromString(pointString);
    CGPoint pointInView = [self.currentPageLayer convertPoint:point fromLayer:self.layer];
    NSInteger pageIndex = self.pageNumber - 1;
    
    self.disableScrollUpdating = YES;
    NSArray *paragraphs = [[self.book textFlow] paragraphsForPageAtIndex:pageIndex];
    
    [self.scrollView setPagingEnabled:NO];
    [self.scrollView setBounces:NO];
    
    BlioTextFlowParagraph *targetParagraph = nil;
    CGAffineTransform viewTransform = [self viewTransformForPage:[self.currentPageLayer pageNumber]];
    //CGAffineTransform viewTransform = [[self.currentPageLayer view] viewTransform];
    //CGAffineTransform viewTransform = CGAffineTransformIdentity;
    
    if ([paragraphs count]) {        
        for (BlioTextFlowParagraph *paragraph in paragraphs) {
            CGRect blockRect = [paragraph rect];
            CGRect pageRect = CGRectApplyAffineTransform(blockRect, viewTransform);
            if (CGRectContainsPoint(pageRect, pointInView)) {
                targetParagraph = paragraph;
                break;
            }
        }
    }
    
    if (nil != targetParagraph) {            
        CGRect targetRect = CGRectApplyAffineTransform([targetParagraph rect], viewTransform);
        targetRect = CGRectInset(targetRect, -kBlioPDFBlockInsetX, -kBlioPDFBlockInsetY);
        
        CGFloat blockMinimumWidth = self.bounds.size.width / kBlioLayoutMaxZoom;
        
        if (CGRectGetWidth(targetRect) < blockMinimumWidth) {
            targetRect.origin.x -= ((blockMinimumWidth - CGRectGetWidth(targetRect)))/2.0f;
            targetRect.size.width += (blockMinimumWidth - CGRectGetWidth(targetRect));
            
            if (targetRect.origin.x < 0) {
                targetRect.origin.x = 0;
                targetRect.size.width += (blockMinimumWidth - CGRectGetWidth(targetRect));
            }
            
            if (CGRectGetMaxX(targetRect) > CGRectGetWidth(self.scrollView.bounds)) {
                targetRect.origin.x = CGRectGetWidth(targetRect) - blockMinimumWidth;
            }
        }
        
                                                                                                                                                                                                                                                                              
        
        CGFloat zoomScale = CGRectGetWidth(self.scrollView.bounds) / CGRectGetWidth(targetRect);
        CGFloat pageWidth = self.scrollView.frame.size.width * zoomScale; 
        CGPoint viewOrigin = CGPointMake((self.pageNumber - 1) * pageWidth, 0);
        
        //CGRect pageRect = CGRectApplyAffineTransform([[[self.currentPageLayer view] shadowLayerDelegate] pageRect], CATransform3DGetAffineTransform([[[self.currentPageLayer view] shadowLayer] transform]));
        CGRect pageRect = CGRectApplyAffineTransform([self cropForPage:[self.currentPageLayer pageNumber]], CATransform3DGetAffineTransform([self.currentPageLayer transform]));
        
        CGFloat maxYOffset = ((CGRectGetMaxY(pageRect) * zoomScale) - self.scrollView.frame.size.height) / zoomScale;
        CGFloat yDiff = targetRect.origin.y - maxYOffset;
        
        if (yDiff > 0) {
            targetRect.origin.y -= yDiff;
            targetRect.size.height += yDiff;
        }
        CGPoint newContentOffset = CGPointMake(round(viewOrigin.x + targetRect.origin.x * zoomScale), round(viewOrigin.y + targetRect.origin.y * zoomScale));


        CGPoint currentContentOffset = [self.scrollView contentOffset];
        
        if (!CGPointEqualToPoint(newContentOffset, currentContentOffset)) {
            [UIView beginAnimations:@"BlioZoomPage" context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationBeginsFromCurrentState:YES];
            [UIView setAnimationDuration:0.35f];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
            
            [self.scrollView setZoomScale:zoomScale];
            [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width * pageCount * self.scrollView.zoomScale, self.scrollView.frame.size.height * self.scrollView.zoomScale)];
            [self.scrollView setContentOffset:newContentOffset];
            self.lastZoomScale = self.scrollView.zoomScale;
            [UIView commitAnimations];
            return;
        }
    }
    
    if (self.scrollView.zoomScale > 1.0f) {
        [UIView beginAnimations:@"BlioZoomPage" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:0.35f];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        [self.scrollView setZoomScale:1.0f];
        [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width * pageCount * self.scrollView.zoomScale, self.scrollView.frame.size.height * self.scrollView.zoomScale)];
        [self.scrollView setContentOffset:CGPointMake((self.pageNumber - 1) * self.scrollView.frame.size.width, 0)];
        self.lastZoomScale = self.scrollView.zoomScale;
        [UIView commitAnimations];
    } else {
        [UIView beginAnimations:@"BlioZoomPage" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:0.35f];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        [self.scrollView setZoomScale:2.0f];
        [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width * pageCount * self.scrollView.zoomScale, self.scrollView.frame.size.height * self.scrollView.zoomScale)];
        
        CGFloat pageWidth = self.scrollView.frame.size.width * self.scrollView.zoomScale;
        CGFloat pageWidthExpansion = pageWidth - self.scrollView.frame.size.width;
        CGFloat pageHeight = self.scrollView.frame.size.height * self.scrollView.zoomScale;
        CGFloat pageHeightExpansion = pageHeight - self.scrollView.frame.size.height;
        
        CGPoint viewOrigin = CGPointMake((self.pageNumber - 1) * pageWidth, 0);
        CGFloat xOffset = pageWidthExpansion * (point.x / CGRectGetWidth(self.scrollView.bounds));
        CGFloat yOffset = pageHeightExpansion * (point.y / CGRectGetHeight(self.scrollView.bounds));
        [self.scrollView setContentOffset:CGPointMake(viewOrigin.x + xOffset, viewOrigin.y + yOffset)];
        
        self.lastZoomScale = self.scrollView.zoomScale;
        [UIView commitAnimations];
    }
}

#pragma mark -
#pragma mark Manual KVO overrides

- (void)setPageNumber:(NSInteger)newPageNumber {
    if (!self.scrollToPageInProgress) {
        [self willChangeValueForKey:@"pageNumber"];
        pageNumber=newPageNumber;
        [self didChangeValueForKey:@"pageNumber"];
    } else {
        pageNumber=newPageNumber;
    }
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
    BOOL automatic = NO;
    
    if ([theKey isEqualToString:@"pageNumber"]) {
        automatic=NO;
    } else {
        automatic=[super automaticallyNotifiesObserversForKey:theKey];
    }
    return automatic;
}

#pragma mark -
#pragma mark Notification Callbacks

- (void)blioCoverPageDidFinishRenderAfterDelay:(NSNotification *)notification {
    [self goToPageNumber:self.pageNumber animated:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:@"blioCoverPageDidFinishRender" 
                                                  object:nil];
    
}

- (void)blioCoverPageDidFinishRenderOnMainThread:(NSNotification *)notification {
    // To allow the tiled view to do its fading out.
    [self performSelector:@selector(blioCoverPageDidFinishRenderAfterDelay:) withObject:notification afterDelay:0.75];
}

- (void)blioCoverPageDidFinishRender:(NSNotification *)notification  {
    [self performSelectorOnMainThread:@selector(blioCoverPageDidFinishRenderOnMainThread:) withObject:notification waitUntilDone:YES];
}


@end



@implementation BlioLayoutRenderThumbsOperation

- (id)initWithPDFPath:(NSString *)aPDFPath pageNumber:(NSInteger)aPageNumber target:(id)aTarget action:(SEL)aAction {
    if(!aPDFPath) return nil;
    
    if((self = [super init])) {
        pdfPath = [aPDFPath retain];
        pageNumber = aPageNumber;
        target = aTarget;
        action = aAction;
    }
    
    return self;
}

- (void)main {

    if ([self isCancelled]) return;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    CGRect thumbRect = CGRectMake(0,0,80,120);
    
    CGColorSpaceRef colorSpace;
    CGContextRef bitmap;
    
    NSData *pdfData = [NSData dataWithContentsOfMappedFile:pdfPath];
    CGDataProviderRef pdfProvider = CGDataProviderCreateWithCFData((CFDataRef)pdfData);
    CGPDFDocumentRef aPdf = CGPDFDocumentCreateWithProvider(pdfProvider);
    CGPDFPageRef aPage = CGPDFDocumentGetPage(aPdf, pageNumber);
    CGRect cropRect = CGPDFPageGetBoxRect(aPage, kCGPDFCropBox);
    CGFloat xScale = thumbRect.size.width / cropRect.size.width;
    CGFloat yScale = thumbRect.size.height / cropRect.size.height;
    CGFloat scale = xScale < yScale ? xScale : yScale;
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scale, scale);
    CGRect scaledRect = CGRectIntegral(CGRectApplyAffineTransform(cropRect, scaleTransform));
    scaledRect.origin = CGPointZero;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    bitmap = CGBitmapContextCreate(NULL,
                                                scaledRect.size.width,
                                                scaledRect.size.height,
                                                8,
                                                0,
                                                colorSpace,
                                                kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipLast);
    
    if ([self isCancelled]) {
        CGDataProviderRelease(pdfProvider);
        CGPDFDocumentRelease(aPdf);
        CGContextRelease(bitmap);
        CGColorSpaceRelease(colorSpace);
        [pool drain];
        return;
    }
    
    CGContextSetFillColorWithColor(bitmap, [UIColor whiteColor].CGColor);
    CGContextFillRect(bitmap, scaledRect);
    CGContextConcatCTM(bitmap, CGPDFPageGetDrawingTransform(aPage, kCGPDFCropBox, scaledRect, 0, true));

    // Lock around the drawing so we limit the memory footprint
    @synchronized ([[UIApplication sharedApplication] delegate]) {
        CGContextDrawPDFPage(bitmap, aPage);
    }
    CGPDFDocumentRelease(aPdf);
    CGDataProviderRelease(pdfProvider);
    
    
    if ([self isCancelled]) { 
        CGContextRelease(bitmap);
        CGColorSpaceRelease(colorSpace);
        [pool drain];
        return;
    }
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);

    // Clean up
    CGContextRelease(bitmap);
    CGColorSpaceRelease(colorSpace);
    
    if ([self isCancelled]) { 
        CGImageRelease(newImageRef);
        [pool drain];
        return;
    }
    
    UIImage *uncompressedImage = [[UIImage alloc] initWithCGImage:newImageRef];
    CGImageRelease(newImageRef);
    NSData *compressedData = UIImagePNGRepresentation(uncompressedImage);
    [uncompressedImage release];
    
    if ([self isCancelled]) { 
        [pool drain];
        return;
    }
    
    NSDictionary *thumbDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                                     compressedData, @"compressedData", 
                                     [NSNumber numberWithInteger:pageNumber], @"pageNumber", nil];
    
    if([target respondsToSelector:action])
        [target performSelectorOnMainThread:action withObject:thumbDictionary waitUntilDone:YES];
        
    [thumbDictionary release];
    
    [pool drain];
}

- (void)dealloc {
    [pdfPath release];
    [super dealloc];
}

@end

@implementation BlioPDFHighlightLayerDelegate


@synthesize page, fitTransform, highlights, highlightsTransform;

- (void)dealloc {
    self.highlights = nil;
    [super dealloc];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    CGRect boundingRect = CGContextGetClipBoundingBox(ctx);
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -CGRectGetHeight(boundingRect));
    
    //CGContextSetRGBFillColor(ctx, 1, 1, 0, 0.3f);
//    CGFloat dash[2]={0.5f,1.5f};
//    CGContextSetLineDash (ctx, 0, dash, 2);
    
    CGContextConcatCTM(ctx, fitTransform);
        
    for (BlioLayoutViewColoredRect *coloredRect in self.highlights) {
        UIColor *highlightColor = [coloredRect color];
        CGContextSetFillColorWithColor(ctx, [highlightColor colorWithAlphaComponent:0.3f].CGColor);
        //CGContextSetStrokeColorWithColor(ctx, [highlightColor colorWithAlphaComponent:1.0f].CGColor);
        //CGContextSetLineWidth(ctx, 1.0f);
        
        CGRect highlightRect = [coloredRect rect];
        CGRect adjustedRect = CGRectApplyAffineTransform(highlightRect, highlightsTransform);
        //CGContextClearRect(ctx, CGRectInset(adjustedRect, -1, -1));
        CGContextFillRect(ctx, adjustedRect);
        //CGContextStrokeRect(ctx, adjustedRect);
    }
}

@end


@implementation BlioLayoutViewColoredRect

@synthesize rect, color;

- (void)dealloc {
    self.color = nil;
    [super dealloc];
}

@end

@implementation BlioLayoutHighlightsOperation

@synthesize pageNumber, layer, excludedBookmark, highlightRanges, textFlow;

- (void)dealloc {
    self.layer = nil;
    self.excludedBookmark = nil;
    self.highlightRanges = nil;
    self.textFlow = nil;
    [super dealloc];
}

- (id)initWithPage:(NSInteger)aPageNumber layer:(CALayer *)aLayer exclusion:(BlioBookmarkRange *)aExcludedBookmark highlights:(NSArray *)aHighlightRanges textFlow:(BlioTextFlow *)aTextFlow {
    if((self = [super init])) {
        
        self.pageNumber = aPageNumber;
        self.layer = aLayer;
        self.excludedBookmark = aExcludedBookmark;
        self.highlightRanges = aHighlightRanges;
        self.textFlow = aTextFlow;
    }
    
    return self;
}

- (void)main {
    if ([self isCancelled]) return;
        
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSInteger pageIndex = self.pageNumber - 1;
    NSArray *pageParagraphs = [self.textFlow paragraphsForPageAtIndex:pageIndex];
    
    if ([self isCancelled]) return;
    
    NSMutableArray *allHighlights = [NSMutableArray array];
    for (BlioBookmarkRange *highlightRange in self.highlightRanges) {
        if ([self isCancelled]) return;
        
        if (![highlightRange isEqual:self.excludedBookmark]) {
            
            NSMutableArray *highlightRects = [NSMutableArray array];
            
            for (BlioTextFlowParagraph *paragraph in pageParagraphs) {
                if ([self isCancelled]) return;
                
                for (BlioTextFlowPositionedWord *word in [paragraph words]) {
                    if ((highlightRange.startPoint.layoutPage < self.pageNumber) &&
                        (paragraph.paragraphIndex <= highlightRange.endPoint.paragraphOffset) &&
                        (word.wordIndex <= highlightRange.endPoint.wordOffset)) {
                        
                        [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        
                    } else if ((highlightRange.endPoint.layoutPage > self.pageNumber) &&
                               (paragraph.paragraphIndex >= highlightRange.startPoint.paragraphOffset) &&
                               (word.wordIndex >= highlightRange.startPoint.wordOffset)) {
                        
                        [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        
                    } else if ((highlightRange.startPoint.layoutPage == self.pageNumber) &&
                               (paragraph.paragraphIndex == highlightRange.startPoint.paragraphOffset) &&
                               (word.wordIndex >= highlightRange.startPoint.wordOffset)) {
                        
                        if ((paragraph.paragraphIndex == highlightRange.endPoint.paragraphOffset) &&
                            (word.wordIndex <= highlightRange.endPoint.wordOffset)) {
                            [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        } else if (paragraph.paragraphIndex < highlightRange.endPoint.paragraphOffset) {
                            [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        }
                        
                    } else if ((highlightRange.startPoint.layoutPage == self.pageNumber) &&
                               (paragraph.paragraphIndex > highlightRange.startPoint.paragraphOffset)) {
                        
                        if ((paragraph.paragraphIndex == highlightRange.endPoint.paragraphOffset) &&
                            (word.wordIndex <= highlightRange.endPoint.wordOffset)) {
                            [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        } else if (paragraph.paragraphIndex < highlightRange.endPoint.paragraphOffset) {
                            [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        }
                    }
                }
            }
            
            if ([self isCancelled]) return;
            NSArray *coalescedRects = [EucSelector coalescedLineRectsForElementRects:highlightRects];
            
            for (NSValue *rectValue in coalescedRects) {
                BlioLayoutViewColoredRect *coloredRect = [[BlioLayoutViewColoredRect alloc] init];
                coloredRect.color = highlightRange.color;
                coloredRect.rect = [rectValue CGRectValue];
                [allHighlights addObject:coloredRect];
                [coloredRect release];
            }
        }
        
    }
    if ([self isCancelled]) return;
    [self.layer performSelectorOnMainThread:@selector(setHighlights:) withObject:allHighlights waitUntilDone:NO];
    
    [pool drain];
}

@end

