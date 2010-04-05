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
#import "UIDevice+BlioAdditions.h"

static const CGFloat kBlioPDFBlockInsetX = 6;
static const CGFloat kBlioPDFBlockInsetY = 10;
static const CGFloat kBlioPDFShadowShrinkScale = 2;
static const CGFloat kBlioPDFGoToZoomScale = 0.7f;

static const int kBlioLayoutMaxThumbCacheSize = 2088960; // 2BM in bytes

static const CGFloat kBlioLayoutShadow = 16.0f;

@interface BlioLayoutViewColoredRect : NSObject {
    CGRect rect;
    UIColor *color;
}

@property (nonatomic) CGRect rect;
@property (nonatomic, retain) UIColor *color;

@end

@interface BlioLayoutView()

@property (nonatomic) NSInteger pageNumber;
@property (nonatomic) CGFloat lastZoomScale;
@property (nonatomic, retain) NSData *pdfData;
@property (nonatomic, retain) BlioTextFlowBlock *lastBlock;
@property (nonatomic, retain) UIImage *pageSnapshot;
@property (nonatomic, retain) UIImage *highlightsSnapshot;

- (void)goToPageNumber:(NSInteger)targetPage animated:(BOOL)animated shouldZoomOut:(BOOL)zoomOut targetZoomScale:(CGFloat)targetZoom targetContentOffset:(CGPoint)targetOffset;

- (void)zoomToNextBlockReversed:(BOOL)reversed;
- (void)zoomToBlock:(BlioTextFlowBlock *)targetBlock context:(void *)context;
- (void)zoomToPage:(NSInteger)targetPageNumber;
- (void)zoomOut;
- (void)zoomOutsideBlockAtPoint:(CGPoint)point;

- (NSArray *)bookmarkRangesForCurrentPage;
- (EucSelectorRange *)selectorRangeFromBookmarkRange:(BlioBookmarkRange *)range;
- (BlioBookmarkRange *)bookmarkRangeFromSelectorRange:(EucSelectorRange *)range;

- (void)clearSnapshots;
- (void)clearHighlightsSnapshot;
     
- (CGSize)currentContentSize;
- (void)setLayoutMode:(BlioLayoutPageMode)newLayoutMode animated:(BOOL)animated;

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

static CGAffineTransform transformRectToFitRectWidth(CGRect sourceRect, CGRect targetRect) {
    
    CGFloat scale = targetRect.size.width / sourceRect.size.width;
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scale, scale);
    CGRect scaledRect = CGRectApplyAffineTransform(sourceRect, scaleTransform);
    CGFloat xOffset = (targetRect.size.width - scaledRect.size.width);
    CGFloat yOffset = (targetRect.size.height - scaledRect.size.height);
    CGAffineTransform offsetTransform = CGAffineTransformMakeTranslation((targetRect.origin.x - scaledRect.origin.x) + xOffset/2.0f, (targetRect.origin.y - scaledRect.origin.y) + yOffset/2.0f);
    CGAffineTransform transform = CGAffineTransformConcat(scaleTransform, offsetTransform);
    return transform;
}

@synthesize delegate, book, scrollView, contentView, currentPageLayer, tiltScroller, scrollToPageInProgress, disableScrollUpdating, pageNumber, pageCount, selector, lastHighlightColor;
@synthesize pdfPath, pdfData, lastZoomScale;
@synthesize thumbCache, thumbCacheSize, pageCropsCache, viewTransformsCache, checkerBoard, shadowBottom, shadowTop, shadowLeft, shadowRight;
@synthesize lastBlock, pageSnapshot, highlightsSnapshot;

- (void)dealloc {
    isCancelled = YES;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    CGPDFDocumentRelease(pdf);
    
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
    self.pageSnapshot = nil;
    self.highlightsSnapshot = nil;
    self.shadowRight = nil;
    
    self.lastBlock = nil;
    
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
        isCancelled = NO;
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
        aScrollView.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
        aScrollView.pagingEnabled = YES;
        aScrollView.minimumZoomScale = 1.0f;
        aScrollView.maximumZoomScale = [[UIDevice currentDevice] blioDeviceMaximumLayoutZoom];
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
        
        [self addObserver:self forKeyPath:@"currentPageLayer" options:0 context:NULL];
        
        NSNumber *savedPage = [aBook layoutPageNumber];
        NSInteger page = (nil != savedPage) ? [savedPage intValue] : 1;
        
        self.thumbCache = [NSMutableDictionary dictionary];
        self.thumbCacheSize = 0;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cacheThumbImage:) name:@"BlioLayoutThumbLayerContentsAvailable" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        
        if (page > self.pageCount) page = self.pageCount;
        self.pageNumber = page;
        
        // Set the layoutMode after the scrollView, contentView and pageNumber
        BlioLayoutPageMode newLayoutMode;
        if (self.frame.size.width > self.frame.size.height)
            newLayoutMode = BlioLayoutPageModeLandscape;
        else
            newLayoutMode = BlioLayoutPageModePortrait;
        [self setLayoutMode:newLayoutMode animated:NO];
        
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

- (void)setLayoutMode:(BlioLayoutPageMode)newLayoutMode animated:(BOOL)animated {
    
    layoutMode = newLayoutMode;
    
    CGRect newFrame;
    //CGSize newContentSize;
    //CGRect newContentFrame;
//    CGSize newContentSize = [self.scrollView contentSize];
//    CGPoint newContentOffset = [self.scrollView contentOffset];
    
    CGFloat pageWidth = self.scrollView.contentSize.width / pageCount;
    CGFloat pageOffset = ((self.scrollView.contentOffset.x + CGRectGetWidth(self.bounds)/2.0f) / pageWidth) + 1;
    NSLog(@"pageOffset = %f pageWidth: %f", pageOffset, pageWidth);
    
    //    CGFloat zoomScale = [self.scrollView zoomScale];
    //    CGFloat pageWidth = CGRectGetWidth(self.bounds) * zoomScale;
    //    CGFloat yOffset = (CGRectGetHeight(self.bounds) - (CGRectGetHeight(pageRect) * zoomScale)) / 2.0f;
    //    CGPoint viewOrigin = CGPointMake((targetPageNumber - 1) * pageWidth, 0);   
    //    CGPoint newContentOffset = CGPointMake(round(viewOrigin.x + pageRect.origin.x * zoomScale), round((pageRect.origin.y * zoomScale) - yOffset));
    
    switch (newLayoutMode) {
        case BlioLayoutPageModeLandscape:
            newFrame = CGRectMake(0,0,480,320);
            break;
        default: // BlioLayoutPageModePortrait
            newFrame = CGRectMake(0,0,320,480);
            break;
    }
    
    
    
    if (animated) {
        [UIView beginAnimations:@"rotateLayoutView" context:nil];
        [UIView setAnimationDuration:0.5f];
    }
    
    [self setFrame:newFrame];
    [self.scrollView setZoomScale:1.0f];
    
    CGSize newContentSize = [self currentContentSize];
    [self.contentView setFrame:CGRectMake(0,0, newFrame.size.width, newContentSize.height)];
    [self.scrollView setContentSize:newContentSize];
    [self.scrollView setContentOffset:CGPointMake((self.pageNumber - 1) * CGRectGetWidth(newFrame), 0)];
    
    //NSLog(@"pageNum: %d. width %f ContentOffset set to %@", self.pageNumber, CGRectGetWidth(newFrame), NSStringFromCGPoint(self.scrollView.contentOffset));

    //[self.contentView setFrame:CGRectMake(0,0, newFrame.size.width, newContentSize.height)];
//    [self.scrollView setContentOffset:CGPointZero];
    
    if (animated) {
        [UIView commitAnimations];
    }
    
    
    
}
     
- (CGSize)currentContentSize {
    CGSize contentSize;
    CGFloat ratio;
    CGFloat zoomScale = self.scrollView.zoomScale;
    
    switch (layoutMode) {
        case BlioLayoutPageModeLandscape:
            ratio = CGRectGetWidth(self.bounds) / CGRectGetHeight(self.bounds);
            contentSize = CGSizeMake(CGRectGetWidth(self.bounds) * pageCount * zoomScale, CGRectGetWidth(self.bounds) * ratio * zoomScale);
            break;
        default: // BlioLayoutPageModePortrait
            contentSize = CGSizeMake(CGRectGetWidth(self.bounds) * pageCount * zoomScale, CGRectGetHeight(self.bounds) * zoomScale);
            break;
    }
    
    return contentSize;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    NSLog(@"will rotate");
    
    self.disableScrollUpdating = YES;
    
    BlioLayoutPageMode newLayoutMode;
    
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        newLayoutMode = BlioLayoutPageModePortrait;
    } else {
        newLayoutMode = BlioLayoutPageModeLandscape;
    }
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey: kCATransactionDisableActions];
    [self setLayoutMode:newLayoutMode animated:NO];
    [CATransaction commit];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    self.disableScrollUpdating = NO;
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    NSLog(@"Did receive memory warning");
    self.thumbCache = [NSMutableDictionary dictionary];
    self.thumbCacheSize = 0;
    
    [self clearSnapshots];
}

#pragma mark -
#pragma mark Thumb Cache Methods

- (void)requestThumbImageForPage:(NSInteger)page {
    if (nil == self.thumbCache) return;
    
    NSMutableDictionary *thumbCacheDictionary = [self.thumbCache objectForKey:[NSNumber numberWithInteger:page]];
    if (nil == thumbCacheDictionary) {
        NSLog(@"THUMB CACHE MISS FOR PAGE %d", page);
    } else {
        NSLog(@"THUMB CACHE HIT FOR PAGE %d", page);
        [self performSelectorInBackground:@selector(decompressThumbDataInBackground:) withObject:thumbCacheDictionary];
    }
}

- (void)decompressThumbDataInBackground:(NSMutableDictionary *)thumbCacheDictionary {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    //NSDate *start = [NSDate date];
    NSData *compressedData = [thumbCacheDictionary valueForKey:@"compressedData"];
    NSNumber *thumbPage = [thumbCacheDictionary valueForKey:@"pageNumber"];
    if (!compressedData || !thumbPage) {
        [pool drain];
        return;
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)compressedData);
    CGImageRef thumbImage = CGImageCreateWithPNGDataProvider(provider, NULL, NO, kCGRenderingIntentDefault);
    CGDataProviderRelease(provider);
    
    // Update accessedDate
    [thumbCacheDictionary setValue:[NSDate date] forKey:@"accessedDate"];

    NSDictionary *thumbDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                                     (id)thumbImage, @"thumbImage", 
                                     thumbPage, @"pageNumber", nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BlioLayoutThumbLayerContentsAvailable" object:thumbPage userInfo:thumbDictionary];
    
    //NSLog(@"It took %.3f seconds to decompress image", -[start timeIntervalSinceNow]);

    [thumbDictionary release];
    CGImageRelease(thumbImage);
    [pool drain];
}

- (void)cacheThumbImage:(NSNotification *)notification {
    //NSLog(@"cacheThumbImage notification received for page %@", [notification object]);
    NSDictionary *thumbDictionary = [notification userInfo];
    if (nil != thumbDictionary) {
        NSNumber *thumbPage = [thumbDictionary valueForKey:@"pageNumber"];
    
        if (thumbPage) {
            if (nil == [self.thumbCache objectForKey:thumbPage])
                [self performSelectorInBackground:@selector(cacheThumbImageInBackground:) withObject:thumbDictionary];
        }
    }
}

- (void)cacheThumbImageInBackground:(NSDictionary *)thumbDictionary {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    //NSLog(@"cacheThumbImageInBackground");
    CGImageRef imageRef = (CGImageRef)[thumbDictionary valueForKey:@"thumbImage"];
    CGFloat scaleFactor = CGImageGetWidth(imageRef) / 160.0f;
    // BEGIN
    
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, CGImageGetWidth(imageRef) * scaleFactor, CGImageGetHeight(imageRef) * scaleFactor));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                newRect.size.width,
                                                newRect.size.height,
                                                8,
                                                0,
                                                colorSpace,
                                                kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(bitmap, kCGInterpolationHigh);
    
    // Draw into the context; this scales the image
    CGContextDrawImage(bitmap, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *image = [[UIImage alloc] initWithCGImage:newImageRef];
    
    // Clean up
    CGImageRelease(newImageRef);
    CGContextRelease(bitmap);
    CGColorSpaceRelease(colorSpace);
    
    // END
    
    //CGImageRef smallImage = CGImageCreateWithImageInRect(thumbImage, CGRectMake(0,0,160,480));
    NSNumber *thumbPage = [thumbDictionary valueForKey:@"pageNumber"];
    //UIImage *image = [[UIImage alloc] initWithCGImage:newThumb];
    
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

- (void)addThumbDataToCache:(NSMutableDictionary *)thumbCacheDictionary {
    NSNumber *thumbPage = [thumbCacheDictionary valueForKey:@"pageNumber"];
    NSData *compressedData = [thumbCacheDictionary valueForKey:@"compressedData"];
    NSDate *accessedDate = [thumbCacheDictionary valueForKey:@"accessedDate"];
    
    self.thumbCacheSize += [compressedData length];
    
    if (thumbPage && compressedData && accessedDate) {
        if (nil == [self.thumbCache objectForKey:thumbPage]) {
            [self.thumbCache setObject:thumbCacheDictionary forKey:thumbPage];
            //NSLog(@"added thumb image for page %@ to cache", thumbPage);
        }
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

- (CGAffineTransform)viewTransformForPage:(NSInteger)aPageNumber {
    
    if (nil == viewTransformsCache) return CGAffineTransformIdentity;
    NSValue *viewTransformValue;
    
    @synchronized (viewTransformsCache) {
        viewTransformValue = [viewTransformsCache objectForKey:[NSNumber numberWithInt:aPageNumber]];
    }
    
    if (nil == viewTransformValue) return CGAffineTransformIdentity;
    
    CGAffineTransform viewTransform = [viewTransformValue CGAffineTransformValue];
    
    //CGRect cropRect = [self cropForPage:aPageNumber];
    //if (CGRectEqualToRect(cropRect, CGRectZero)) return CGAffineTransformIdentity;
    
    //CGRect insetBounds = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(kBlioLayoutShadow, kBlioLayoutShadow, kBlioLayoutShadow, kBlioLayoutShadow));
    //CGAffineTransform boundsTransform = transformRectToFitRect(cropRect, insetBounds);
    CGAffineTransform boundsTransform = transformRectToFitRect(CGRectMake(0,0,320,480), self.contentView.bounds);
    CGAffineTransform concatTransform = CGAffineTransformConcat(viewTransform, boundsTransform);
    NSLog(@"orig: %@, new: %@, concat: %@", NSStringFromCGAffineTransform(viewTransform), NSStringFromCGAffineTransform(boundsTransform), NSStringFromCGAffineTransform(concatTransform));
    
    return concatTransform;
}

- (CGPoint)contentOffsetToFillPage:(NSInteger)aPageNumber zoomScale:(CGFloat *)zoomScale {
    
    CGRect cropRect = [self cropForPage:aPageNumber];
    if (CGRectEqualToRect(cropRect, CGRectZero)) return CGPointZero;
    
    CGRect viewBounds = self.bounds;
    CGRect contentBounds = self.contentView.bounds;
    CGRect insetBounds = UIEdgeInsetsInsetRect(contentBounds, UIEdgeInsetsMake(kBlioLayoutShadow, kBlioLayoutShadow, kBlioLayoutShadow, kBlioLayoutShadow));
    CGAffineTransform boundsTransform = transformRectToFitRectWidth(cropRect, insetBounds);    
    CGRect pageRect = CGRectApplyAffineTransform(cropRect, boundsTransform);
    
    CGFloat blockMinimumWidth = CGRectGetWidth(viewBounds) / self.scrollView.maximumZoomScale;
    
    if (CGRectGetWidth(pageRect) < blockMinimumWidth) {
        pageRect.origin.x -= ((blockMinimumWidth - CGRectGetWidth(pageRect)))/2.0f;
        pageRect.size.width += (blockMinimumWidth - CGRectGetWidth(pageRect));
        
        if (pageRect.origin.x < 0) {
            pageRect.origin.x = 0;
            pageRect.size.width += (blockMinimumWidth - CGRectGetWidth(pageRect));
        }
        
        if (CGRectGetMaxX(pageRect) > CGRectGetWidth(viewBounds)) {
            pageRect.origin.x = CGRectGetWidth(viewBounds) - CGRectGetWidth(pageRect);
        }
    }
    
    CGFloat scale = CGRectGetWidth(viewBounds) / CGRectGetWidth(pageRect);
    *zoomScale = scale;
    
    CGFloat pageWidth = CGRectGetWidth(viewBounds) * scale;
    CGFloat cropHeight = CGRectGetHeight(pageRect) * scale;
    CGPoint viewOrigin = CGPointMake((aPageNumber - 1) * pageWidth, 0); 
    
    CGFloat contentOffsetX = round(viewOrigin.x + (pageRect.origin.x * scale));
    CGFloat contentOffsetY;
    if (cropHeight < CGRectGetHeight(viewBounds)) {
        CGFloat yOffset = (CGRectGetHeight(viewBounds) - cropHeight) / 2.0f;
        contentOffsetY = round((pageRect.origin.y * scale) - yOffset);
    } else {
        contentOffsetY = round((pageRect.origin.y * scale));
    }
    
    return CGPointMake(contentOffsetX, contentOffsetY);
}

#pragma mark -
#pragma mark Thumb Rendering

- (void)drawThumbLayer:(CALayer *)aLayer inContext:(CGContextRef)ctx  forPage:(NSInteger)aPageNumber withCacheLayer:(CGLayerRef)cacheLayer {
    CGRect layerBounds = aLayer.bounds;
    CGRect cropRect = [self cropForPage:aPageNumber];
    if (CGRectEqualToRect(cropRect, CGRectZero)) return;
    
    CGRect insetBounds = UIEdgeInsetsInsetRect(layerBounds, UIEdgeInsetsMake(kBlioLayoutShadow, kBlioLayoutShadow, kBlioLayoutShadow, kBlioLayoutShadow));
    CGAffineTransform boundsTransform = transformRectToFitRect(cropRect, insetBounds);
    cropRect = CGRectApplyAffineTransform(cropRect, boundsTransform);
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillRect(ctx, cropRect);
    CGContextDrawLayerInRect(ctx, cropRect, cacheLayer);
}

#pragma mark -
#pragma mark Tile Rendering

- (void)drawTiledLayer:(CALayer *)aLayer inContext:(CGContextRef)ctx forPage:(NSInteger)aPageNumber cacheReadyTarget:(id)target cacheReadySelector:(SEL)readySelector {
    NSLog(@"Tiled rendering started");
//    CGFloat inset = -kBlioLayoutShadow;
    
    // Because this occurs on a background thread but accesses self, we must check whether we have been cancelled
    
    CGRect layerBounds = aLayer.bounds;
    
    //CGAffineTransform layerContext = CGContextGetCTM(ctx);
    
    CGContextTranslateCTM(ctx, 0, layerBounds.size.height);
	CGContextScaleCTM(ctx, 1, -1);
    
    //NSLog(@"clipRect %@", NSStringFromCGRect(CGContextGetClipBoundingBox(ctx)));
    if (isCancelled) return;
    CGRect scaledCropRect = [self cropForPage:aPageNumber];
    CGRect insetBounds = UIEdgeInsetsInsetRect(layerBounds, UIEdgeInsetsMake(kBlioLayoutShadow, kBlioLayoutShadow, kBlioLayoutShadow, kBlioLayoutShadow));
    CGAffineTransform boundsTransform = transformRectToFitRect(scaledCropRect, insetBounds);
    scaledCropRect = CGRectApplyAffineTransform(scaledCropRect, boundsTransform);
    //CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:arc4random() % 1000 / 1000.0f green:arc4random() % 1000 / 1000.0f blue:arc4random() % 1000 / 1000.0f alpha:1].CGColor);
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);

    CGContextFillRect(ctx, scaledCropRect);
    CGContextClipToRect(ctx, scaledCropRect);
    
//    CGRect insetBounds = UIEdgeInsetsInsetRect(layerBounds, UIEdgeInsetsMake(-inset, -inset, -inset, -inset));
    if (isCancelled) return;
    CGDataProviderRef pdfProvider = CGDataProviderCreateWithCFData((CFDataRef)self.pdfData);
    CGPDFDocumentRef aPdf = CGPDFDocumentCreateWithProvider(pdfProvider);
    CGPDFPageRef aPage = CGPDFDocumentGetPage(aPdf, aPageNumber);
    
    //CGContextConcatCTM(ctx, CGPDFPageGetDrawingTransform(aPage, kCGPDFCropBox, insetBounds, 0, true));
    
    
    CGRect unscaledCropRect = CGPDFPageGetBoxRect(aPage, kCGPDFCropBox);
    //CGAffineTransform pdfTransform = transformRectToFitRect(unscaledCropRect, scaledCropRect);
    CGAffineTransform pdfTransform = transformRectToFitRectWidth(unscaledCropRect, scaledCropRect);
    
    CGContextConcatCTM(ctx, pdfTransform);
    //BOOL createSnapshot = NO;
    //BOOL createSnapshot = YES;
//    CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:arc4random() % 1000 / 1000.0f green:arc4random() % 1000 / 1000.0f blue:arc4random() % 1000 / 1000.0f alpha:1].CGColor);
//    CGContextFillRect(ctx, CGPDFPageGetBoxRect(aPage, kCGPDFCropBox));
//    CGContextClipToRect(ctx, CGPDFPageGetBoxRect(aPage, kCGPDFCropBox));
    // Lock around the drawing so we limit the memory footprint
   // NSDate *start = [NSDate date];
    
        if (nil != target) {
            CGRect cacheRect = CGRectIntegral(CGRectMake(0, 0, 160, 240));
            CGAffineTransform cacheTransform = transformRectToFitRectWidth(unscaledCropRect, cacheRect);
            cacheRect = CGRectApplyAffineTransform(unscaledCropRect, cacheTransform);
            cacheRect.origin = CGPointZero;
            cacheTransform = transformRectToFitRect(unscaledCropRect, cacheRect);
            
            //CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//            CGContextRef bitmap = CGBitmapContextCreate(NULL,
//                                                        cacheRect.size.width,
//                                                        cacheRect.size.height,
//                                                        8,
//                                                        0,
//                                                        colorSpace,
//                                                        kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
//            
//            // Set the quality level to use when rescaling
//            CGContextSetInterpolationQuality(bitmap, kCGInterpolationHigh);
            
            CGLayerRef aCGLayer = CGLayerCreateWithContext(ctx, cacheRect.size, NULL);
            CGContextRef cacheCtx = CGLayerGetContext(aCGLayer);
            CGContextTranslateCTM(cacheCtx, 0, cacheRect.size.height);
            CGContextScaleCTM(cacheCtx, 1, -1);
            
            CGContextConcatCTM(cacheCtx, cacheTransform);
            CGContextSetFillColorWithColor(cacheCtx, [UIColor whiteColor].CGColor);
            CGContextClipToRect(cacheCtx, unscaledCropRect);
            CGContextFillRect(cacheCtx, unscaledCropRect);

            @synchronized ([[UIApplication sharedApplication] delegate]) {
                CGContextDrawPDFPage(cacheCtx, aPage);

                if ([target respondsToSelector:readySelector])
                    [target performSelectorOnMainThread:readySelector withObject:(id)aCGLayer waitUntilDone:NO];
                
                CGLayerRelease(aCGLayer);

                if (isCancelled) {
                    CGDataProviderRelease(pdfProvider);
                    return;
                }
                
                CGContextDrawPDFPage(ctx, aPage);
                CGPDFDocumentRelease(aPdf);
            }
            
        } else {

            @synchronized ([[UIApplication sharedApplication] delegate]) {
                //start = [NSDate date];
                CGContextDrawPDFPage(ctx, aPage);
                //NSLog(@"It took %.3f seconds to draw 2 page %d", -[start timeIntervalSinceNow], aPageNumber);
                CGPDFDocumentRelease(aPdf);
            }
        //if (self.scrollView.zoomScale = 1) createSnapshot = YES;
        }
    //NSLog(@"It took %.3f seconds to draw page %d", -[start timeIntervalSinceNow], aPageNumber);
    CGDataProviderRelease(pdfProvider);
    
    // Don't create a thumb when we are zoomed in, we want to limit the size of the cached image
    //if (layerContext.a == 1) createSnapshot = YES;
    //NSLog(@"layerContext.a %f", layerContext.a);
    
    //if (createSnapshot) {
        
    
        //CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, imageBuffer, rowBytes * height, NULL);
        //CGContextSaveGState(ctx);
        //NSLog(@"Clip bounds before: %@", NSStringFromCGRect(CGContextGetClipBoundingBox(ctx)));
        //NSLog(@"Context before: %@", NSStringFromCGAffineTransform(CGContextGetCTM(ctx)));
        //CGContextScaleCTM(ctx, 1/layerContext.a, 1/layerContext.a);
        //CGContextClipToRect(ctx, CGRectMake(0,0,320,480));
        //NSLog(@"Context after: %@", NSStringFromCGAffineTransform(CGContextGetCTM(ctx)));
       // NSLog(@"Clip bounds after: %@", NSStringFromCGRect(CGContextGetClipBoundingBox(ctx)));
        //CGContextBeginTransparencyLayerWithRect(ctx, CGRectMake(0,0,160,240), NULL);
        //start = [NSDate date];
        //CGLayerRef aLayer = CGLayerCreateWithContext(ctx, CGSizeMake(160,240), NULL);
    
        //CGImageRef imageRef = CGBitmapContextCreateImage(ctx);
        //CGContextEndTransparencyLayer(ctx);
        //CGContextRestoreGState(ctx);
        //NSLog(@"Image is size %d x %d", CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
        //NSDictionary *thumbDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
         //                                (id)imageRef, @"thumbImage", 
        //                                 [NSNumber numberWithInteger:aPageNumber], @"pageNumber", nil];
        
        //if (isCancelled) {
        //    CGImageRelease(imageRef);
         //   [thumbDictionary release];
        //    return;
        //}
        //[self performSelectorInBackground:@selector(cacheThumbImage:) withObject:thumbDictionary];
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"BlioLayoutThumbLayerContentsAvailable" object:[NSNumber numberWithInteger:aPageNumber] userInfo:thumbDictionary];
        
        //CGImageRelease(imageRef);
        //[thumbDictionary release];
        //NSLog(@"It took %.3f seconds to create the cache snapshot", -[start timeIntervalSinceNow]);
    //}
    
}

#pragma mark -
#pragma mark Shadow Rendering

- (void)drawShadowLayer:(CALayer *)aLayer inContext:(CGContextRef)ctx forPage:(NSInteger)aPageNumber {
    
    CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor);
    CGRect layerBounds = aLayer.bounds;
    CGContextFillRect(ctx, layerBounds);
    
//    for (int i = 0; i <= layerBounds.size.height; i = i + 100) {
//        CGContextSetRGBFillColor(ctx, arc4random() % 1000 / 1000.0f, arc4random() % 1000 / 1000.0f, arc4random() % 1000 / 1000.0f, 1);
//        CGContextFillRect(ctx, CGRectMake(0, i, layerBounds.size.width, 100));
//    }

    CGRect cropRect = [self cropForPage:aPageNumber];
    if (CGRectEqualToRect(cropRect, CGRectZero)) return;
    
    CGRect insetBounds = UIEdgeInsetsInsetRect(layerBounds, UIEdgeInsetsMake(kBlioLayoutShadow, kBlioLayoutShadow, kBlioLayoutShadow, kBlioLayoutShadow));
    CGAffineTransform boundsTransform = transformRectToFitRect(cropRect, insetBounds);
    cropRect = CGRectApplyAffineTransform(cropRect, boundsTransform);
    
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
    NSArray *pageBlocks = [[self.book textFlow] nonFolioBlocksForPageAtIndex:pageIndex];
    
    for (BlioBookmarkRange *highlightRange in highlightRanges) {
        
        if (![highlightRange isEqual:excludedBookmark]) {
                        
            NSMutableArray *highlightRects = [NSMutableArray array];
            
            for (BlioTextFlowBlock *block in pageBlocks) {
                
                for (BlioTextFlowPositionedWord *word in [block words]) {
                    if ((highlightRange.startPoint.layoutPage < aPageNumber) &&
                        (block.blockIndex <= highlightRange.endPoint.blockOffset) &&
                        (word.wordIndex <= highlightRange.endPoint.wordOffset)) {
                        
                        [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        
                    } else if ((highlightRange.endPoint.layoutPage > aPageNumber) &&
                               (block.blockIndex >= highlightRange.startPoint.blockOffset) &&
                               (word.wordIndex >= highlightRange.startPoint.wordOffset)) {
                        
                        [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        
                    } else if ((highlightRange.startPoint.layoutPage == aPageNumber) &&
                               (block.blockIndex == highlightRange.startPoint.blockOffset) &&
                               (word.wordIndex >= highlightRange.startPoint.wordOffset)) {
                        
                        if ((block.blockIndex == highlightRange.endPoint.blockOffset) &&
                            (word.wordIndex <= highlightRange.endPoint.wordOffset)) {
                            [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        } else if (block.blockIndex < highlightRange.endPoint.blockOffset) {
                            [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        }
                        
                    } else if ((highlightRange.startPoint.layoutPage == aPageNumber) &&
                               (block.blockIndex > highlightRange.startPoint.blockOffset)) {
                        
                        if ((block.blockIndex == highlightRange.endPoint.blockOffset) &&
                            (word.wordIndex <= highlightRange.endPoint.wordOffset)) {
                            [highlightRects addObject:[NSValue valueWithCGRect:[word rect]]];
                        } else if (block.blockIndex < highlightRange.endPoint.blockOffset) {
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

- (void)clearSnapshots {
    self.pageSnapshot = nil;
    self.highlightsSnapshot = nil; 
}

- (void)clearHighlightsSnapshot {
    self.highlightsSnapshot = nil; 
}

- (UIImage *)viewSnapshotImageForEucSelector:(EucSelector *)selector {
    BlioLayoutPageLayer *snapLayer = self.currentPageLayer;
    if (nil == snapLayer) return nil;
    
    CGFloat scale = self.scrollView.zoomScale * 1.2f;
    CGSize snapSize = snapLayer.bounds.size;
    snapSize.width *= 1.2f;
    snapSize.height *= 1.2f;
    
    if (nil == self.pageSnapshot) {
        UIGraphicsBeginImageContext(snapSize);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGPoint translatePoint = [self.window.layer convertPoint:CGPointZero toLayer:snapLayer];
        CGContextScaleCTM(ctx, scale, scale);
        CGContextTranslateCTM(ctx, -translatePoint.x, -translatePoint.y);
        [[snapLayer shadowLayer] renderInContext:ctx];
        [[snapLayer tiledLayer] renderInContext:ctx];
        self.pageSnapshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    if (nil == self.highlightsSnapshot) {
        UIGraphicsBeginImageContext(snapSize);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        [self.pageSnapshot drawAtPoint:CGPointZero];
        CGPoint translatePoint = [self.window.layer convertPoint:CGPointZero toLayer:snapLayer];
        CGContextScaleCTM(ctx, scale, scale);
        CGContextTranslateCTM(ctx, -translatePoint.x, -translatePoint.y);
        [[snapLayer highlightsLayer] renderInContext:ctx];
        self.highlightsSnapshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return self.highlightsSnapshot;
}

- (UIView *)viewForMenuForEucSelector:(EucSelector *)selector {
    return self.contentView;
}

- (EucSelectorRange *)selectorRangeFromBookmarkRange:(BlioBookmarkRange *)range {
    if (nil == range) return nil;
    
    NSInteger pageIndex = self.pageNumber - 1;
    
    EucSelectorRange *selectorRange = [[EucSelectorRange alloc] init];
    selectorRange.startBlockId = [BlioTextFlowBlock blockIDForPageIndex:pageIndex blockIndex:range.startPoint.blockOffset];
    selectorRange.startElementId = [BlioTextFlowPositionedWord wordIDForWordIndex:range.startPoint.wordOffset];
    selectorRange.endBlockId = [BlioTextFlowBlock blockIDForPageIndex:pageIndex blockIndex:range.endPoint.blockOffset];
    selectorRange.endElementId = [BlioTextFlowPositionedWord wordIDForWordIndex:range.endPoint.wordOffset];
    
    return [selectorRange autorelease];
}

- (BlioBookmarkRange *)bookmarkRangeFromSelectorRange:(EucSelectorRange *)range {
    
    if (nil == range) return nil;
    
    NSInteger currentPage = self.pageNumber;
    
    BlioBookmarkPoint *startPoint = [[BlioBookmarkPoint alloc] init];
    startPoint.layoutPage = currentPage;
    startPoint.blockOffset = [BlioTextFlowBlock blockIndexForBlockID:range.startBlockId];
    startPoint.wordOffset = [BlioTextFlowPositionedWord wordIndexForWordID:range.startElementId];
    
    BlioBookmarkPoint *endPoint = [[BlioBookmarkPoint alloc] init];
    endPoint.layoutPage = currentPage;
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
    NSArray *pageBlocks = [[self.book textFlow] nonFolioBlocksForPageAtIndex:pageIndex];
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

- (UIColor *)eucSelector:(EucSelector *)aSelector willBeginEditingHighlightWithRange:(EucSelectorRange *)selectedRange {
    
    [self clearHighlightsSnapshot];
    
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
    [self clearHighlightsSnapshot];
    
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
    NSArray *pageBlocks = [[self.book textFlow] nonFolioBlocksForPageAtIndex:pageIndex];
    NSMutableArray *identifiers = [NSMutableArray array];
    for (BlioTextFlowBlock *block in pageBlocks) {
        [identifiers addObject:[block blockID]];
    }
    return identifiers;
}

- (CGRect)eucSelector:(EucSelector *)selector frameOfBlockWithIdentifier:(id)blockID {
    CGRect pageRect = CGRectZero;
    
    NSInteger pageIndex = [BlioTextFlowBlock pageIndexForBlockID:blockID];
    NSArray *pageBlocks = [[self.book textFlow] blocksForPageAtIndex:pageIndex];
    NSArray *nonFolioPageBlocks = [[self.book textFlow] nonFolioBlocksForPageAtIndex:pageIndex];
    NSInteger blockIndex = [BlioTextFlowBlock blockIndexForBlockID:blockID];
    BlioTextFlowBlock *currentBlock = (blockIndex < [pageBlocks count]) ? [pageBlocks objectAtIndex:blockIndex] : nil;
    NSInteger currentIndex = [nonFolioPageBlocks indexOfObject:currentBlock];
    
    if ([nonFolioPageBlocks count] > currentIndex) {
        CGRect blockRect = [[nonFolioPageBlocks objectAtIndex:currentIndex] rect];
//        CGAffineTransform viewTransform = [[self.currentPageLayer view] viewTransform];
        CGAffineTransform viewTransform = [self viewTransformForPage:[self.currentPageLayer pageNumber]];
        pageRect = CGRectApplyAffineTransform(blockRect, viewTransform);
    }
    
    return pageRect;
}

- (NSArray *)eucSelector:(EucSelector *)selector identifiersForElementsOfBlockWithIdentifier:(id)blockID; {
    NSInteger pageIndex = [BlioTextFlowBlock pageIndexForBlockID:blockID];
    NSArray *pageBlocks = [[self.book textFlow] blocksForPageAtIndex:pageIndex];
    NSArray *nonFolioPageBlocks = [[self.book textFlow] nonFolioBlocksForPageAtIndex:pageIndex];
    NSInteger blockIndex = [BlioTextFlowBlock blockIndexForBlockID:blockID];
    BlioTextFlowBlock *currentBlock = (blockIndex < [pageBlocks count]) ? [pageBlocks objectAtIndex:blockIndex] : nil;
    NSInteger currentIndex = [nonFolioPageBlocks indexOfObject:currentBlock];
    
    if ([nonFolioPageBlocks count] > currentIndex) {
        NSMutableArray *identifiers = [NSMutableArray array];
        for (BlioTextFlowPositionedWord *word in [[nonFolioPageBlocks objectAtIndex:currentIndex] words]) {
            [identifiers addObject:[word wordID]];
        }
        return identifiers;
    } else {
        return [NSArray array];
    }
}

- (NSArray *)eucSelector:(EucSelector *)selector rectsForElementWithIdentifier:(id)wordID ofBlockWithIdentifier:(id)blockID {    
    CGRect pageRect = CGRectZero;
    
    NSInteger pageIndex = [BlioTextFlowBlock pageIndexForBlockID:blockID];
    NSArray *pageBlocks = [[self.book textFlow] blocksForPageAtIndex:pageIndex];
    NSArray *nonFolioPageBlocks = [[self.book textFlow] nonFolioBlocksForPageAtIndex:pageIndex];
    NSInteger blockIndex = [BlioTextFlowBlock blockIndexForBlockID:blockID];
    BlioTextFlowBlock *currentBlock = (blockIndex < [pageBlocks count]) ? [pageBlocks objectAtIndex:blockIndex] : nil;
    NSInteger currentIndex = [nonFolioPageBlocks indexOfObject:currentBlock];
    
    if ([nonFolioPageBlocks count] > currentIndex) {
        NSArray *words = [[nonFolioPageBlocks objectAtIndex:currentIndex] words];
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
                    //[self clearSnapshots];
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
//            NSLog(@"pageLayer changed to page %d", self.currentPageLayer.pageNumber);
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
        
        [self clearHighlightsSnapshot];
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

- (id)getCurrentBlockId {
    NSInteger pageIndex = self.pageNumber - 1;
    NSArray *nonFolioPageBlocks = [[self.book textFlow] nonFolioBlocksForPageAtIndex:pageIndex];

    if (![nonFolioPageBlocks count])
        return nil;
    else
        return [[nonFolioPageBlocks objectAtIndex:0] blockID];
}

- (uint32_t)getCurrentWordOffset {
    return 0;
}

- (id)blockIdForBlockAfterBlockWithId:(id)blockID {    
    if (!blockID) {
        NSInteger pageIndex = -1;
        while (++pageIndex < ([self pageCount])) {
            NSArray *pageBlocks = [[self.book textFlow] nonFolioBlocksForPageAtIndex:pageIndex];
            if ([pageBlocks count])
                return (id)[[pageBlocks objectAtIndex:0] blockID];
        }
        return nil;
    } else {

        NSInteger pageIndex = [BlioTextFlowBlock pageIndexForBlockID:blockID];
        NSArray *pageBlocks = [[self.book textFlow] blocksForPageAtIndex:pageIndex];
        NSArray *nonFolioPageBlocks = [[self.book textFlow] nonFolioBlocksForPageAtIndex:pageIndex];
        NSInteger blockIndex = [BlioTextFlowBlock blockIndexForBlockID:blockID];
        BlioTextFlowBlock *currentBlock = (blockIndex < [pageBlocks count]) ? [pageBlocks objectAtIndex:blockIndex] : nil;
        NSInteger currentIndex = [nonFolioPageBlocks indexOfObject:currentBlock];
        
            if (++currentIndex < [nonFolioPageBlocks count]) {
                return (id)[[nonFolioPageBlocks objectAtIndex:currentIndex] blockID];
            } else {
                while (++pageIndex < ([self pageCount])) {
                    NSArray *pageBlocks = [[self.book textFlow] nonFolioBlocksForPageAtIndex:pageIndex];
                    if ([pageBlocks count])
                        return (id)[[pageBlocks objectAtIndex:0] blockID];
                }
            }
        
    }
    return nil;
}

- (NSArray *)blockWordsForBlockWithId:(id)blockID {
    NSInteger pageIndex = [BlioTextFlowBlock pageIndexForBlockID:blockID];
    NSArray *pageBlocks = [[self.book textFlow] blocksForPageAtIndex:pageIndex];
    NSArray *nonFolioPageBlocks = [[self.book textFlow] nonFolioBlocksForPageAtIndex:pageIndex];
    NSInteger blockIndex = [BlioTextFlowBlock blockIndexForBlockID:blockID];
    BlioTextFlowBlock *currentBlock = (blockIndex < [pageBlocks count]) ? [pageBlocks objectAtIndex:blockIndex] : nil;
    NSInteger currentIndex = [nonFolioPageBlocks indexOfObject:currentBlock];
    
    if ([nonFolioPageBlocks count] > currentIndex)
        return [[nonFolioPageBlocks objectAtIndex:currentIndex] wordStrings];
    else
        return nil;
    
}

- (void)highlightWordAtBlockId:(id)blockID wordOffset:(uint32_t)wordOffset {
    NSInteger pageIndex = [BlioTextFlowBlock pageIndexForBlockID:blockID];
    NSArray *pageBlocks = [[self.book textFlow] blocksForPageAtIndex:pageIndex];
    NSArray *nonFolioPageBlocks = [[self.book textFlow] nonFolioBlocksForPageAtIndex:pageIndex];
    NSInteger blockIndex = [BlioTextFlowBlock blockIndexForBlockID:blockID];
    BlioTextFlowBlock *currentBlock = (blockIndex < [pageBlocks count]) ? [pageBlocks objectAtIndex:blockIndex] : nil;
    NSInteger currentIndex = [nonFolioPageBlocks indexOfObject:currentBlock];
    
    if ([nonFolioPageBlocks count] > currentIndex) {
        BlioTextFlowBlock *currentBlock = [nonFolioPageBlocks objectAtIndex:currentIndex];
        NSInteger targetPageNumber = ++pageIndex;
        if ((self.pageNumber != targetPageNumber) && !self.disableScrollUpdating) {
            [self goToPageNumber:targetPageNumber animated:YES];
        }
        
        NSArray *words = [currentBlock words];
        if ([words count] > wordOffset) {
            BlioTextFlowPositionedWord *word = [words objectAtIndex:wordOffset];
            [self.selector temporarilyHighlightElementWithIdentfier:[word wordID] inBlockWithIdentifier:blockID animated:YES];
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
    [self goToPageNumber:targetPage animated:animated shouldZoomOut:YES targetZoomScale:1 targetContentOffset:CGPointZero];
}

- (void)goToPageNumber:(NSInteger)targetPage animated:(BOOL)animated shouldZoomOut:(BOOL)zoomOut targetZoomScale:(CGFloat)targetZoom targetContentOffset:(CGPoint)targetOffset {
    //NSLog(@"Goto page %d", targetPage);
    if (targetPage < 1 )
        targetPage = 1;
    else if (targetPage > pageCount)
        targetPage = pageCount;
    
    targetZoomScale = targetZoom;
    targetContentOffset = targetOffset;
    shouldZoomOut = zoomOut;
    
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
        //NSInteger startPage = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 2;
        NSInteger startPage = floor((self.scrollView.contentOffset.x + CGRectGetWidth(self.bounds)/2.0f) / pageWidth) + 1;
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
            CGFloat frameOffset = pagesToOffset * CGRectGetWidth(self.bounds);
            
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
                newFrame.origin.x -= CGRectGetWidth(self.currentPageLayer.frame);
                prevLayer.frame = newFrame;
                [pageLayersToPreserve addObject:prevLayer];
            } //else {
//                NSLog(@"No prev found");
//            }
            
            NSSet *nextLayerSet = [[self.contentView pageLayers] filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"pageNumber==%d", startPage + 1]];
            if ([nextLayerSet count]) {
                CALayer *nextLayer = [[nextLayerSet allObjects] objectAtIndex:0];
                CGRect newFrame = self.currentPageLayer.frame;
                newFrame.origin.x += CGRectGetWidth(self.currentPageLayer.frame);
                nextLayer.frame = newFrame;
                [pageLayersToPreserve addObject:nextLayer];
            } //else {
//                NSLog(@"No next found");
//            }

            
            
            currentOffset = CGPointMake(currentOffset.x + frameOffset*self.scrollView.zoomScale, currentOffset.y);
            [self.scrollView setContentOffset:currentOffset animated:NO];
            
            [CATransaction commit];
        }
        
        // TODO -remove these checks
        if ([pageLayersToPreserve count] > 3) {
            NSLog(@"WARNING: more than 3 pages found to preserve during go to animation: %@", [pageLayersToPreserve description]); 
        } //else if ([pageLayersToPreserve count] < 3) {
//            NSLog(@"Less than 3");
//        }
        
        // 2. Load the target page and its adjacent pages
        BlioLayoutPageLayer *aLayer = [self.contentView addPage:targetPage retainPages:pageLayersToPreserve];
        if (aLayer) {
            [pageLayersToPreserve addObject:aLayer];
            self.currentPageLayer = aLayer;
            [aLayer forceThumbCacheAfterDelay:0];
            //[self performSelectorInBackground:@selector(forceCacheForLayer:) withObject:aLayer];
                        //UIGraphicsBeginImageContext(CGSizeMake(0.1,0.1));
//                        CGContextRef ctx = UIGraphicsGetCurrentContext();
//                        [aLayer renderInContext:ctx];
//                        UIGraphicsEndImageContext();
        }
        BlioLayoutPageLayer *prevLayer = [self.contentView addPage:targetPage - 1 retainPages:pageLayersToPreserve];
        if (prevLayer) { 
            [pageLayersToPreserve addObject:prevLayer];
        }
        BlioLayoutPageLayer *nextLayer = [self.contentView addPage:targetPage + 1 retainPages:pageLayersToPreserve];
        //if (aLayer) { 
//            [aLayer performSelector:@selector(forceThumbCache) withObject:nil];
//        }
        
        if (startPage > targetPage) {
            [prevLayer forceThumbCacheAfterDelay:0.85f];
        } else {
            [nextLayer forceThumbCacheAfterDelay:0.85f];
        }
        
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

        [self.scrollView setContentSize:CGSizeMake(CGRectGetWidth(self.bounds) * pageCount * self.scrollView.zoomScale, CGRectGetHeight(self.bounds) * self.scrollView.zoomScale)];
        [self.scrollView setContentOffset:CGPointMake((targetPage - 1) * CGRectGetWidth(self.bounds) * self.scrollView.zoomScale, 0)];
        self.pageNumber = targetPage;
        [self didChangeValueForKey:@"pageNumber"];
    }
}

/*
- (void)forceCacheForLayer:(CALayer *)aLayer {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSLog(@"Start forceCacheForLayer");
    //            UIGraphicsBeginImageContext(CGSizeMake(1,1));
    //            CGContextRef ctx = UIGraphicsGetCurrentContext();
    //            [aLayer renderInContext:ctx];
    //            UIGraphicsEndImageContext();
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                1,
                                                1,
                                                8,
                                                0,
                                                colorSpace,
                                                kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(bitmap, kCGInterpolationHigh);
    
    // Draw into the context; this force the caching
    [aLayer renderInContext:bitmap];
    
    // Clean up
    CGContextRelease(bitmap);
    CGColorSpaceRelease(colorSpace);
    
    NSLog(@"End forceCacheForLayer");
    
    [pool drain];
}
*/
- (void)performGoToPageStep1FromPage:(NSInteger)fromPage {

    [self.scrollView setContentSize:[self currentContentSize]];
    //[self.scrollView setContentSize:CGSizeMake(CGRectGetWidth(self.bounds) * pageCount * self.scrollView.zoomScale, CGRectGetHeight(self.bounds) * self.scrollView.zoomScale)];
    [self.scrollView setContentOffset:CGPointMake(((fromPage - 1) * CGRectGetWidth(self.bounds) * kBlioPDFGoToZoomScale) - (CGRectGetWidth(self.bounds) * ((1-kBlioPDFGoToZoomScale)/2.0f)), CGRectGetHeight(self.bounds) * ((1-kBlioPDFGoToZoomScale)/-2.0f))];
    
    CFTimeInterval shrinkDuration = 0.25f + (0.5f * (self.scrollView.zoomScale / self.scrollView.maximumZoomScale));
    [UIView beginAnimations:@"BlioLayoutGoToPageStep1" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    //[UIView setAnimationWillStartSelector:@selector(animationWillStart:context:)];
    [UIView setAnimationDuration:shrinkDuration];
    [UIView setAnimationBeginsFromCurrentState:YES];
    if (shouldZoomOut) {
        [self.scrollView setMinimumZoomScale:kBlioPDFGoToZoomScale];
        [self.scrollView setZoomScale:kBlioPDFGoToZoomScale];
        [self.scrollView setContentSize:[self currentContentSize]];
        //[self.scrollView setContentSize:CGSizeMake(CGRectGetWidth(self.bounds) * pageCount * self.scrollView.zoomScale, CGRectGetHeight(self.bounds) * self.scrollView.zoomScale)];
        [self.scrollView setContentOffset:CGPointMake(((fromPage - 1) * CGRectGetWidth(self.bounds) * kBlioPDFGoToZoomScale) - (CGRectGetWidth(self.bounds) * ((1-kBlioPDFGoToZoomScale)/2.0f)), CGRectGetHeight(self.bounds) * ((1-kBlioPDFGoToZoomScale)/-2.0f))];
    } else {
        [UIView setAnimationDuration:0.0f];
    }
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
    if (shouldZoomOut) {
        [self.scrollView setContentOffset:CGPointMake(((self.pageNumber - 1) * CGRectGetWidth(self.bounds) * kBlioPDFGoToZoomScale) - (CGRectGetWidth(self.bounds) * ((1-kBlioPDFGoToZoomScale)/2.0f)), CGRectGetHeight(self.bounds) * ((1-kBlioPDFGoToZoomScale)/-2.0f))];
    } else {
         [UIView setAnimationDuration:0.0f];
    }
    [UIView commitAnimations];
}

- (void)performGoToPageStep3 {  
    CFTimeInterval zoomDuration = 0.25f;
    [UIView beginAnimations:@"BlioLayoutGoToPageStep3" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    if (shouldZoomOut) {
        [UIView setAnimationDuration:zoomDuration];
    } else {
        [UIView setAnimationDuration:0.75f];
    }
    
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [self.scrollView setMinimumZoomScale:1];
    [self.scrollView setZoomScale:targetZoomScale];
    [self.scrollView setContentSize:[self currentContentSize]];
    //[self.scrollView setContentSize:CGSizeMake(CGRectGetWidth(self.bounds) * pageCount * self.scrollView.zoomScale, CGRectGetHeight(self.bounds) * self.scrollView.zoomScale)];
    CGPoint newContentOffset = CGPointEqualToPoint(targetContentOffset, CGPointZero) ? CGPointMake((self.pageNumber - 1) * CGRectGetWidth(self.bounds), 0) : targetContentOffset;
    [self.scrollView setContentOffset:newContentOffset];
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

//- (void)animationWillStart:(NSString *)animationID context:(void *)context {
//    if ([animationID isEqualToString:@"BlioLayoutGoToPageStep1"]) {
//        [self.currentPageLayer performSelectorOnMainThread:@selector(forceThumbCache) withObject:nil waitUntilDone:NO];
//    }
//}

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
        } else if ([animationID isEqualToString:@"BlioZoomToBlock"]) {
            [self scrollViewDidEndZooming:self.scrollView withView:self.scrollView atScale:self.scrollView.zoomScale];
            self.disableScrollUpdating = NO;
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
    NSLog(@"scrollViewDidEndZooming");
    [self clearSnapshots];
    
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
        //scrollView.pagingEnabled = YES;
        scrollView.bounces = NO;
        //scrollView.bounces = YES;
        scrollView.directionalLockEnabled = YES;
    }
    
}

- (void)enableInteractions {
    self.disableScrollUpdating = NO;
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)aScrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self clearSnapshots];
        [self.selector setShouldHideMenu:NO];
    }
    if (tiltScroller) [tiltScroller resetAngle];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    //NSLog(@"scrollViewDidScroll");
    [self.selector setShouldHideMenu:YES];

    if (self.disableScrollUpdating) return;

    NSInteger currentPageNumber;
    
    if (sender.zoomScale != lastZoomScale) {
        [sender setContentSize:[self currentContentSize]];
        //[sender setContentSize:CGSizeMake(CGRectGetWidth(self.bounds) * pageCount * sender.zoomScale, CGRectGetHeight(self.bounds) * sender.zoomScale)];
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
                BlioLayoutPageLayer *prevLayer = [self.contentView addPage:currentPageNumber - 1 retainPages:nil];
                [prevLayer forceThumbCacheAfterDelay:0.75f];
            }
            if (currentPageNumber > self.pageNumber) {
                BlioLayoutPageLayer *nextLayer = [self.contentView addPage:currentPageNumber + 1 retainPages:nil];
                [nextLayer forceThumbCacheAfterDelay:0.75f];
            }
            self.pageNumber = currentPageNumber;
            self.currentPageLayer = aLayer;
            self.lastBlock = nil;
        } else {
            NSLog(@"Scrolltopageinprogress");
        }

    }
}

- (void)updateAfterScroll {
    NSLog(@"updateAfterScroll");
    [self clearSnapshots];
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

- (void)zoomToPreviousBlock {
    [self zoomToNextBlockReversed:YES];
}

- (void)zoomToNextBlock {
    [self zoomToNextBlockReversed:NO];
}

- (void)zoomToNextBlockReversed:(BOOL)reversed {
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        
    if (nil == self.currentPageLayer) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        return;
    }
    
    NSInteger targetPage = [currentPageLayer pageNumber];
    NSInteger pageIndex = targetPage - 1;
    if ([self.lastBlock pageIndex] != pageIndex) self.lastBlock = nil;
    
    self.disableScrollUpdating = YES;
    NSArray *blocks = [[self.book textFlow] nonFolioBlocksForPageAtIndex:pageIndex];
    
    [self.scrollView setPagingEnabled:NO];
    [self.scrollView setBounces:NO];
    
    BlioTextFlowBlock *targetBlock = nil;
    //CGAffineTransform viewTransform = [self viewTransformForPage:targetPage];
    
    NSUInteger count = [blocks count];
   // NSUInteger targetIndex;
    
    // Work out targetBlock on the current page
    if (count > 0) {
        if (nil == self.lastBlock) {
            if (!reversed)
                targetBlock = [blocks objectAtIndex:0];
        } else if (reversed) {
            NSInteger prevIndex = [blocks indexOfObject:self.lastBlock] - 1;
            if (prevIndex >= 0)
                targetBlock = [blocks objectAtIndex:prevIndex];
        } else {
            NSInteger nextIndex = [blocks indexOfObject:self.lastBlock] + 1;
            if (nextIndex < count)
                targetBlock = [blocks objectAtIndex:nextIndex];
        }
    }
    
    // Work out targetBlock on an adjacent page 
    if (nil == targetBlock) {
        if (!reversed) {
            if (pageIndex >= ([self pageCount] - 1)) {
                // If we are already at the last page, zoom to page
                [self zoomToPage:targetPage];
                return;
            }
            
            //NSInteger newPageIndex = pageIndex + 1;
            //NSArray *pageBlocks = [[self.book textFlow] paragraphsForBlockAtIndex:newPageIndex];
            
            // Always zoom to the next page (rather than to the first block on it)
            [self zoomToPage:targetPage + 1];
            //                return;
            //if ([pageBlocks count] > 0) {
//                targetBlock = [pageBlocks objectAtIndex:0];
//            } else {
//                // If the next page has no blocks, zoom to page
//                [self zoomToPage:targetPage + 1];
//                return;
//            }
        } else {
            if (pageIndex <= 0) {
                // If we are already at the first page, zoom to page
                [self zoomToPage:targetPage];
                return;
            }
            
            NSInteger newPageIndex = pageIndex - 1;
            NSArray *pageBlocks = [[self.book textFlow] nonFolioBlocksForPageAtIndex:newPageIndex];
            
            // Always zoom to the previous page (rather than to the last block on it)
            //[self zoomToPage:targetPage - 1];
            if ([pageBlocks count] > 0) {
                targetBlock = [pageBlocks lastObject];
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
        [self zoomToBlock:targetBlock context:zoomToNextBlockInv];
    }
}

- (void)zoomAtPoint:(NSString *)pointString {
    if ([self.scrollView isDecelerating]) return;
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    CGPoint point = CGPointFromString(pointString);
    
    BlioLayoutPageLayer *targetLayer = nil;
    CGPoint pointInTargetPage;
    
    NSArray *orderedLayers = [[self.contentView layer] sublayers];
    for (int i = [orderedLayers count]; i > 0; i--) {
        CALayer *pageLayer = [orderedLayers objectAtIndex:(i - 1)];
//    for (BlioLayoutPageLayer *pageLayer in [self.contentView pageLayers]) {
        pointInTargetPage = [pageLayer convertPoint:point fromLayer:self.layer];
        if ([pageLayer containsPoint:pointInTargetPage]) {
            targetLayer = (BlioLayoutPageLayer *)pageLayer;
            break;
        }
    }
    
    if (nil == targetLayer) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        return;
    }
    
    NSInteger targetPage = [targetLayer pageNumber];
    NSInteger pageIndex = targetPage - 1;
    
    self.disableScrollUpdating = YES;
    NSArray *blocks = [[self.book textFlow] nonFolioBlocksForPageAtIndex:pageIndex];

    [self.scrollView setPagingEnabled:NO];
    [self.scrollView setBounces:NO];
    
    BlioTextFlowBlock *targetBlock = nil;
    CGAffineTransform viewTransform = [self viewTransformForPage:targetPage];
    
    NSUInteger count = [blocks count];
    NSUInteger targetIndex;
    
    if (count > 0) { 
        for (NSUInteger index = 0; index < count; index++) {
            BlioTextFlowBlock *block = [blocks objectAtIndex:index];
            CGRect blockRect = [block rect];
            CGRect pageRect = CGRectApplyAffineTransform(blockRect, viewTransform);
            if (CGRectContainsPoint(pageRect, pointInTargetPage)) {
                targetBlock = block;
                targetIndex = index;
                break;
            }
        }
    }
    
    if (nil != targetBlock) {
        self.lastBlock = targetBlock;
        [self zoomToBlock:targetBlock context:nil];
        return;
    } else if (self.scrollView.zoomScale > 1) {
        [self zoomOut];
    } else {
        [self zoomToPage:targetPage];
    }
    
    self.lastBlock = nil;
}

- (void)zoomToPage:(NSInteger)targetPageNumber {
    // TODO - there is a lot of duplicate code with zoomToBlock - refactor into 1
    //CGRect pageRect = CGRectApplyAffineTransform([self cropForPage:targetPageNumber], CATransform3DGetAffineTransform([self.currentPageLayer transform]));
    //CGRect cropRect = [self cropForPage:targetPageNumber];
//    //if (CGRectEqualToRect(cropRect, CGRectZero)) return CGAffineTransformIdentity;
//    
//    CGRect insetBounds = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(kBlioLayoutShadow, kBlioLayoutShadow, kBlioLayoutShadow, kBlioLayoutShadow));
//    CGAffineTransform boundsTransform = transformRectToFitRectWidth(cropRect, insetBounds);
//    
//    //CGAffineTransform boundsTransform = transformRectToFitRect(CGRectMake(0,0,320,480), self.contentView.bounds);
//    CGRect pageRect = CGRectApplyAffineTransform(cropRect, boundsTransform);
//    NSLog(@"Pagerect: %@", NSStringFromCGRect(pageRect));
//    
//    CGFloat blockMinimumWidth = self.bounds.size.width / self.scrollView.maximumZoomScale;
//
//    if (CGRectGetWidth(pageRect) < blockMinimumWidth) {
//        pageRect.origin.x -= ((blockMinimumWidth - CGRectGetWidth(pageRect)))/2.0f;
//        pageRect.size.width += (blockMinimumWidth - CGRectGetWidth(pageRect));
//        
//        if (pageRect.origin.x < 0) {
//            pageRect.origin.x = 0;
//            pageRect.size.width += (blockMinimumWidth - CGRectGetWidth(pageRect));
//        }
//        
//        if (CGRectGetMaxX(pageRect) > CGRectGetWidth(self.bounds)) {
//            pageRect.origin.x = CGRectGetWidth(self.bounds) - CGRectGetWidth(pageRect);
//        }
//    }
//
//    CGFloat zoomScale = CGRectGetWidth(self.bounds) / CGRectGetWidth(pageRect);
    //CGFloat pageWidth = CGRectGetWidth(self.bounds) * zoomScale;
//    CGFloat yOffset = (CGRectGetHeight(self.bounds) - (CGRectGetHeight(pageRect) * zoomScale)) / 2.0f;
//    CGPoint viewOrigin = CGPointMake((targetPageNumber - 1) * pageWidth, 0);   
//    CGPoint newContentOffset = CGPointMake(round(viewOrigin.x + pageRect.origin.x * zoomScale), round((pageRect.origin.y * zoomScale) - yOffset));
    CGFloat zoomScale;
    CGPoint newContentOffset = [self contentOffsetToFillPage:targetPageNumber zoomScale:&zoomScale];
    CGPoint currentContentOffset = [self.scrollView contentOffset];

    if (!CGPointEqualToPoint(newContentOffset, currentContentOffset)) {
        if (targetPageNumber != self.pageNumber) {
            [self goToPageNumber:targetPageNumber animated:YES shouldZoomOut:NO targetZoomScale:zoomScale targetContentOffset:newContentOffset];
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        } else {
            [UIView beginAnimations:@"BlioZoomPage" context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationBeginsFromCurrentState:YES];
            [UIView setAnimationDuration:0.35f];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
            
            [self.scrollView setZoomScale:zoomScale];
            [self.scrollView setContentSize:[self currentContentSize]];
            //[self.scrollView setContentSize:CGSizeMake(CGRectGetWidth(self.bounds) * pageCount * self.scrollView.zoomScale, CGRectGetHeight(self.bounds) * self.scrollView.zoomScale)];
            [self.scrollView setContentOffset:newContentOffset];
            self.lastZoomScale = self.scrollView.zoomScale;
            [UIView commitAnimations];
        }
    } else {
        [self zoomOut];
        //[[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }
    
}

- (void)zoomToBlock:(BlioTextFlowBlock *)targetBlock context:(void *)context {
    NSInteger targetPageNumber = [targetBlock pageIndex] + 1;
    
    CGAffineTransform viewTransform = [self viewTransformForPage:targetPageNumber];
    CGRect targetRect = CGRectApplyAffineTransform([targetBlock rect], viewTransform);
    targetRect = CGRectInset(targetRect, -kBlioPDFBlockInsetX, -kBlioPDFBlockInsetY);
    
    CGFloat blockMinimumWidth = self.bounds.size.width / self.scrollView.maximumZoomScale;
    
    if (CGRectGetWidth(targetRect) < blockMinimumWidth) {
        targetRect.origin.x -= ((blockMinimumWidth - CGRectGetWidth(targetRect)))/2.0f;
        targetRect.size.width += (blockMinimumWidth - CGRectGetWidth(targetRect));
        
        if (targetRect.origin.x < 0) {
            targetRect.origin.x = 0;
            targetRect.size.width += (blockMinimumWidth - CGRectGetWidth(targetRect));
        }
        
        if (CGRectGetMaxX(targetRect) > CGRectGetWidth(self.bounds)) {
            targetRect.origin.x = CGRectGetWidth(self.bounds) - CGRectGetWidth(targetRect);
        }
    }
    
    CGFloat zoomScale = CGRectGetWidth(self.bounds) / CGRectGetWidth(targetRect);
    CGFloat pageWidth = CGRectGetWidth(self.bounds) * zoomScale; 
    CGPoint viewOrigin = CGPointMake((targetPageNumber - 1) * pageWidth, 0);
    
    CGRect pageRect = CGRectApplyAffineTransform([self cropForPage:targetPageNumber], CATransform3DGetAffineTransform([self.currentPageLayer transform]));
    
    CGFloat maxYOffset = ((CGRectGetMaxY(pageRect) * zoomScale) - CGRectGetHeight(self.bounds)) / zoomScale;
    CGFloat yDiff = targetRect.origin.y - maxYOffset;
    
    if (yDiff > 0) {
        targetRect.origin.y -= yDiff;
        targetRect.size.height += yDiff;
    }
    
    CGPoint newContentOffset = CGPointMake(round(viewOrigin.x + targetRect.origin.x * zoomScale), round(viewOrigin.y + targetRect.origin.y * zoomScale));
    CGPoint currentContentOffset = [self.scrollView contentOffset];
    
    if (!CGPointEqualToPoint(newContentOffset, currentContentOffset)) {
        if (targetPageNumber != self.pageNumber) {
            [self goToPageNumber:targetPageNumber animated:YES shouldZoomOut:NO targetZoomScale:zoomScale targetContentOffset:newContentOffset];
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        } else {
            [UIView beginAnimations:@"BlioZoomToBlock" context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationBeginsFromCurrentState:YES];
            [UIView setAnimationDuration:0.35f];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
            
            [self.scrollView setZoomScale:zoomScale];
            [self.scrollView setContentSize:[self currentContentSize]];
            //[self.scrollView setContentSize:CGSizeMake(CGRectGetWidth(self.bounds) * pageCount * self.scrollView.zoomScale, CGRectGetHeight(self.bounds) * self.scrollView.zoomScale)];
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

        //[self zoomOut];
        //[[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }
}

- (void)zoomOut {
    [UIView beginAnimations:@"BlioZoomPage" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.35f];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [self.scrollView setZoomScale:1.0f];
    [self.scrollView setContentSize:[self currentContentSize]];
    //[self.scrollView setContentSize:CGSizeMake(CGRectGetWidth(self.bounds) * pageCount * self.scrollView.zoomScale, CGRectGetHeight(self.bounds) * self.scrollView.zoomScale)];
    [self.scrollView setContentOffset:CGPointMake((self.pageNumber - 1) * CGRectGetWidth(self.bounds), 0)];
    self.lastZoomScale = self.scrollView.zoomScale;
    [UIView commitAnimations];
    self.lastBlock = nil;
}

- (void)zoomOutsideBlockAtPoint:(CGPoint)point {
    [UIView beginAnimations:@"BlioZoomPage" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.35f];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [self.scrollView setZoomScale:2.0f];
    [self.scrollView setContentSize:[self currentContentSize]];
    //[self.scrollView setContentSize:CGSizeMake(CGRectGetWidth(self.bounds) * pageCount * self.scrollView.zoomScale, CGRectGetHeight(self.bounds) * self.scrollView.zoomScale)];
    
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

@implementation BlioLayoutViewColoredRect

@synthesize rect, color;

- (void)dealloc {
    self.color = nil;
    [super dealloc];
}

@end

