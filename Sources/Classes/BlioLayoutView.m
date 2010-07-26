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
#import "BlioLayoutScrollView.h"
#import "BlioLayoutContentView.h"
#import "UIDevice+BlioAdditions.h"

@interface BlioLayoutPDFDataSource : NSObject<BlioLayoutDataSource> {
    NSData *data;
    NSInteger pageCount;
    CGPDFDocumentRef pdf;
}

@property (nonatomic, retain) NSData *data;

- (id)initWithPath:(NSString *)aPath;

@end

static const CGFloat kBlioPDFBlockInsetX = 6;
static const CGFloat kBlioPDFBlockInsetY = 10;
static const CGFloat kBlioPDFGoToZoomTransitionScale = 0.7f;
static const CGFloat kBlioPDFGoToZoomTargetScale = 1;
static const CGFloat kBlioLayoutShadow = 16.0f;
static const CGFloat kBlioLayoutViewAccessibilityOffset = 0.1f;

@interface BlioLayoutScrollViewAccessibleProxy : NSProxy {
    BlioLayoutScrollView *target;
    CGRect accessibilityFrameProxy;
    NSString *accessibilityLabelProxy;
    NSString *accessibilityHintProxy;
    UIAccessibilityElement *element;
}

@property (nonatomic, retain) BlioLayoutScrollView *target;
@property (nonatomic) CGRect accessibilityFrameProxy;
@property (nonatomic, retain) NSString *accessibilityLabelProxy;
@property (nonatomic, retain) NSString *accessibilityHintProxy;
@property (nonatomic, retain) UIAccessibilityElement *element;

- (void)setProxyContainer:(id)container;

@end


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
@property (nonatomic, retain) BlioTextFlowBlock *lastBlock;
@property (nonatomic, retain) UIImage *pageSnapshot;
@property (nonatomic, retain) UIImage *highlightsSnapshot;
@property (nonatomic, retain) NSMutableArray *accessibilityElements;
@property (nonatomic, retain) NSArray *previousAccessibilityElements;
@property (nonatomic, retain) id<BlioLayoutDataSource> dataSource;

- (void)goToPageNumber:(NSInteger)targetPage animated:(BOOL)animated shouldZoomOut:(BOOL)zoomOut targetZoomScale:(CGFloat)targetZoom targetContentOffset:(CGPoint)targetOffset;

- (CGRect)cropForPage:(NSInteger)page;
- (CGAffineTransform)blockTransformForPage:(NSInteger)page;
- (CGSize)currentContentSize;
- (void)setLayoutMode:(BlioLayoutPageMode)newLayoutMode animated:(BOOL)animated;
- (CGPoint)contentOffsetToCenterPage:(NSInteger)aPageNumber zoomScale:(CGFloat)zoomScale;
- (CGPoint)contentOffsetToFillPage:(NSInteger)aPageNumber zoomScale:(CGFloat *)zoomScale;
- (CGPoint)contentOffsetToFitRect:(CGRect)rect onPage:(NSInteger)aPageNumber zoomScale:(CGFloat *)zoomScale;

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
- (void)displayHighlightsForLayer:(BlioLayoutPageLayer *)aLayer excluding:(BlioBookmarkRange *)excludedBookmark; 
- (NSArray *)highlightRectsForPage:(NSInteger)aPageNumber excluding:(BlioBookmarkRange *)excludedBookmark;

@end

@implementation BlioLayoutView

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

@synthesize bookID, textFlow, scrollView, containerView, contentView, currentPageLayer, disableScrollUpdating, pageNumber, pageCount, selector;
@synthesize lastZoomScale;
@synthesize pageCropsCache, viewTransformsCache, checkerBoard, shadowBottom, shadowTop, shadowLeft, shadowRight;
@synthesize lastBlock, pageSnapshot, highlightsSnapshot;
@synthesize accessibilityElements, previousAccessibilityElements;
@synthesize dataSource;

- (void)dealloc {
    NSLog(@"*************** dealloc called for layoutview");
    isCancelled = YES;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.selector removeObserver:self forKeyPath:@"tracking"];
    [self.selector removeObserver:self forKeyPath:@"trackingStage"];
    [self removeObserver:self forKeyPath:@"currentPageLayer"];
    
    self.delegate = nil;
    
    self.accessibilityElements = nil;
    self.previousAccessibilityElements = nil;
    self.textFlow = nil;
    self.scrollView = nil;
    self.currentPageLayer = nil;
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
    
    [self.contentView abortRendering];
    self.contentView = nil;
    self.containerView = nil;
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
    
    self.bookID = nil;
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    NSLog(@"Did receive memory warning");
    [self clearSnapshots];
}

#pragma mark -
#pragma mark BlioBookView

- (id)initWithFrame:(CGRect)frame
             bookID:(NSManagedObjectID *)aBookID 
           animated:(BOOL)animated {

    BlioBook *aBook = [[BlioBookManager sharedBookManager] bookWithID:aBookID];
    if (!([aBook hasPdf] || [aBook hasXps])) {
        return nil;
    }
    
    CGRect rotatedFrame = [UIScreen mainScreen].bounds;
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
        if (rotatedFrame.size.height > rotatedFrame.size.width)
            rotatedFrame.size = CGSizeMake(rotatedFrame.size.height, rotatedFrame.size.width);
    } else {
        if (rotatedFrame.size.width > rotatedFrame.size.height)
            rotatedFrame.size = CGSizeMake(rotatedFrame.size.height, rotatedFrame.size.width);
    }
    
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];

    
    if ((self = [super initWithFrame:rotatedFrame])) {
        // Initialization code
        isCancelled = NO;
        self.bookID = aBookID;
        
        // Prefer the checkout over calling [aBook textFlow] because we wat to retain the result
        textFlow = [[[BlioBookManager sharedBookManager] checkOutTextFlowForBookWithID:self.bookID] retain];
        
        self.clearsContextBeforeDrawing = NO; // Performance optimisation;
        self.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];    
        self.autoresizesSubviews = YES;
        
        self.checkerBoard = [UIImage imageNamed:@"check.png"];
        self.shadowBottom = [UIImage imageNamed:@"shadow-bottom.png"];
        self.shadowTop = [UIImage imageNamed:@"shadow-top.png"];
        self.shadowLeft = [UIImage imageNamed:@"shadow-left.png"];
        self.shadowRight = [UIImage imageNamed:@"shadow-right.png"];
        
        
        lastZoomScale = 1;
        accessibilityRefreshRequired = YES;
        
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
        
        // Populate the cache of page sizes and viewTransforms
        NSMutableDictionary *aPageCropsCache = [[NSMutableDictionary alloc] initWithCapacity:pageCount];
        NSMutableDictionary *aViewTransformsCache = [[NSMutableDictionary alloc] initWithCapacity:pageCount];
        
        CGFloat inset = -kBlioLayoutShadow;
        CGRect insetBounds = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(-inset, -inset, -inset, -inset));
        
        CGFloat dpiRatio = [self.dataSource dpiRatio];
        CGAffineTransform dpiScale = CGAffineTransformMakeScale(dpiRatio, dpiRatio);
        
        [self.dataSource openDocumentIfRequired];
        //NSLog(@"Document opened");
        
        for (int i = 1; i <= pageCount; i++) {
            CGRect cropRect = [self.dataSource cropRectForPage:i];
            CGAffineTransform pageTransform = transformRectToFitRect(cropRect, insetBounds, true);
            CGRect scaledCropRect = CGRectApplyAffineTransform(cropRect, pageTransform);
            [aPageCropsCache setObject:[NSValue valueWithCGRect:scaledCropRect] forKey:[NSNumber numberWithInt:i]];
            
            CGRect mediaRect = [self.dataSource mediaRectForPage:i];
            CGAffineTransform mediaAdjust = CGAffineTransformMakeTranslation(cropRect.origin.x - mediaRect.origin.x, cropRect.origin.y - mediaRect.origin.y);
            CGAffineTransform textTransform = CGAffineTransformConcat(dpiScale, mediaAdjust);
            CGAffineTransform viewTransform = CGAffineTransformConcat(textTransform, pageTransform);
            [aViewTransformsCache setObject:[NSValue valueWithCGAffineTransform:viewTransform] forKey:[NSNumber numberWithInt:i]];
        }
        //NSLog(@"Rects calculated");
        
        [self.dataSource closeDocumentIfRequired];
        
        self.pageCropsCache = [NSDictionary dictionaryWithDictionary:aPageCropsCache];
        self.viewTransformsCache = [NSDictionary dictionaryWithDictionary:aViewTransformsCache];
        [aPageCropsCache release];
        [aViewTransformsCache release];
        
        BlioLayoutScrollView *aScrollView = [[BlioLayoutScrollView alloc] initWithFrame:self.bounds];
        aScrollView.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
        aScrollView.pagingEnabled = YES;
        aScrollView.minimumZoomScale = 1.0f;
        aScrollView.maximumZoomScale = [[UIDevice currentDevice] blioDeviceMaximumLayoutZoom];
        //aScrollView.maximumZoomScale = 8;
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
        
        UIView *aContainerView = [[UIView alloc] initWithFrame:self.bounds];
        [self.scrollView addSubview:aContainerView];
        aContainerView.backgroundColor = [UIColor clearColor];
        aContainerView.autoresizesSubviews = NO;
        self.containerView = aContainerView;
        [aContainerView release];
        
        BlioLayoutContentView *aContentView = [[BlioLayoutContentView alloc] initWithFrame:self.bounds];
        [self.containerView addSubview:aContentView];
        aContentView.renderingDelegate = self;
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
        
        NSInteger page = aBook.implicitBookmarkPoint.layoutPage;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        
        // Set the page number to 1 initially whilst the layout mode is set
        self.pageNumber = 1;
        
        BlioLayoutPageMode newLayoutMode;
        if (self.frame.size.width > self.frame.size.height)
            newLayoutMode = BlioLayoutPageModeLandscape;
        else
            newLayoutMode = BlioLayoutPageModePortrait;
        [self setLayoutMode:newLayoutMode animated:NO];
        
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

- (void)didFinishReading {
    if (xpsProvider) {
        [xpsProvider reportReading]; 
    }
}

- (void)goToUuid:(NSString *)uuid animated:(BOOL)animated {
    [self goToPageNumber:[self.textFlow pageNumberForSectionUuid:uuid] animated:animated];
}

- (void)goToPageNumber:(NSInteger)targetPage animated:(BOOL)animated {
    [self goToPageNumber:targetPage animated:animated shouldZoomOut:YES targetZoomScale:kBlioPDFGoToZoomTargetScale targetContentOffset:CGPointZero];
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
            ret = [NSString stringWithFormat:@"Page %@ - %@", pageStr, chapter.first];
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
#pragma mark BlioBookDelegate

- (void)setDelegate:(id<BlioBookViewDelegate>)newDelegate {
    [self.scrollView setBookViewDelegate:newDelegate];
    delegate = newDelegate;
}

#pragma mark -
#pragma mark Rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [self.selector setSelectedRange:nil];

    self.disableScrollUpdating = YES;
    self.lastBlock = nil;
    cachedViewTransformPage = -1;
    
    BlioLayoutPageMode newLayoutMode;
    
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        newLayoutMode = BlioLayoutPageModePortrait;
    } else {
        newLayoutMode = BlioLayoutPageModeLandscape;
    }
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey: kCATransactionDisableActions];
    [self setLayoutMode:newLayoutMode animated:NO];
    [self.contentView layoutSubviewsAfterBoundsChange];
    [CATransaction commit];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    // Force the selector to reattach
    [self.selector attachToLayer:self.currentPageLayer];
    [self clearSnapshots];
    
    [self displayHighlightsForLayer:self.currentPageLayer excluding:nil];
    
    [self scrollViewDidEndZooming:self.scrollView withView:self.scrollView atScale:self.scrollView.zoomScale];
    [self performSelector:@selector(enableInteractions) withObject:nil afterDelay:0.1f];
    
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);

    //self.accessibilityElements = nil;
    accessibilityRefreshRequired = YES;

}

#pragma mark -
#pragma mark Layout Methods

- (void)setLayoutMode:(BlioLayoutPageMode)newLayoutMode animated:(BOOL)animated {
    
    layoutMode = newLayoutMode;
    
    CGRect newFrame = [[UIScreen mainScreen] bounds];    
    switch (newLayoutMode) {
        case BlioLayoutPageModeLandscape:
            if (newFrame.size.width < newFrame.size.height)
                newFrame.size = CGSizeMake(newFrame.size.height, newFrame.size.width);
            break;
        default: // BlioLayoutPageModePortrait
            if (newFrame.size.width > newFrame.size.height)
                newFrame.size = CGSizeMake(newFrame.size.height, newFrame.size.width);
            break;
    }

    if (animated) {
        [UIView beginAnimations:@"SetBlioLayoutMode" context:nil];
        [UIView setAnimationDuration:0.5f];
    }
    
    [self setFrame:newFrame];
    [self.scrollView setZoomScale:1];
    
    CGSize newContentSize = [self currentContentSize];
    [self.containerView setFrame:CGRectMake(0,0, ceilf(newContentSize.width), ceilf(newContentSize.height))];
    [self.contentView setFrame:CGRectMake(0,0, newFrame.size.width, ceilf(newContentSize.height))];
    [self.scrollView setContentSize:newContentSize];
    [self.scrollView setContentOffset:[self contentOffsetToCenterPage:self.pageNumber zoomScale:1]];
    
    if (animated) {
        [UIView commitAnimations];
    }
}

- (CGSize)currentContentSize {
    CGSize contentSize;
    CGFloat ratio;
    CGFloat zoomScale = self.scrollView.zoomScale;
    
    // Reduce the conent size dimensions by teh accessibility offset to work around an accessibility bug that 
    // incorrectly states the size as being 1 page larger than it is
    switch (layoutMode) {
        case BlioLayoutPageModeLandscape:
            ratio = CGRectGetWidth(self.bounds) / CGRectGetHeight(self.bounds);
            contentSize = CGSizeMake(floorf(CGRectGetWidth(self.bounds) * pageCount * zoomScale) - kBlioLayoutViewAccessibilityOffset, floorf(CGRectGetWidth(self.bounds) * ratio * zoomScale) - kBlioLayoutViewAccessibilityOffset);
            break;
        default: // BlioLayoutPageModePortrait
            contentSize = CGSizeMake(floorf(CGRectGetWidth(self.bounds) * pageCount * zoomScale) - kBlioLayoutViewAccessibilityOffset, floorf(CGRectGetHeight(self.bounds) * zoomScale) - kBlioLayoutViewAccessibilityOffset);
            break;
    }
    
    return contentSize;
}

- (CGAffineTransform)boundsTransformForPage:(NSInteger)aPageNumber cropRect:(CGRect *)cropRect {
    CGRect pageCropRect = [self cropForPage:aPageNumber];
    *cropRect = pageCropRect;
    CGRect contentBounds = self.contentView.bounds;
    CGRect insetBounds = UIEdgeInsetsInsetRect(contentBounds, UIEdgeInsetsMake(kBlioLayoutShadow, kBlioLayoutShadow, kBlioLayoutShadow, kBlioLayoutShadow));
    CGAffineTransform boundsTransform = transformRectToFitRectWidth(pageCropRect, insetBounds); 
    return boundsTransform;
}

- (CGPoint)contentOffsetToCenterPage:(NSInteger)aPageNumber zoomScale:(CGFloat)zoomScale {
    CGRect viewBounds = self.bounds;
    return  CGPointMake(((aPageNumber - 1) * CGRectGetWidth(viewBounds) * zoomScale) - (CGRectGetWidth(viewBounds) * ((1-zoomScale)/2.0f)), CGRectGetHeight(viewBounds) * ((1-zoomScale)/-2.0f));
}

- (CGRect)fitRectToContentView:(CGRect)aRect {
    CGRect viewBounds = self.contentView.bounds;
    CGFloat blockMinimumWidth = CGRectGetWidth(viewBounds) / self.scrollView.maximumZoomScale;
    
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

- (CGPoint)contentOffsetToFillPage:(NSInteger)aPageNumber zoomScale:(CGFloat *)zoomScale {
    
    CGRect cropRect;
    CGAffineTransform boundsTransform = [self boundsTransformForPage:aPageNumber cropRect:&cropRect];
    if (CGRectEqualToRect(cropRect, CGRectZero)) return CGPointZero;   
    CGRect pageRect = CGRectApplyAffineTransform(cropRect, boundsTransform);
    pageRect = [self fitRectToContentView:pageRect];
        
    CGRect viewBounds = self.contentView.bounds;
    CGFloat scale = CGRectGetWidth(viewBounds) / CGRectGetWidth(pageRect);
    *zoomScale = scale;
    
    CGFloat pageWidth = CGRectGetWidth(viewBounds) * scale;
    CGPoint viewOrigin = CGPointMake((aPageNumber - 1) * pageWidth, 0); 
    
    CGFloat contentOffsetX = round(viewOrigin.x + (pageRect.origin.x * scale));
    CGFloat contentOffsetY;
    
    // Vertically center if smaller than height, otherwise top align
    if ((CGRectGetHeight(pageRect) * scale) < CGRectGetHeight(viewBounds)) {
        CGFloat yOffset = (CGRectGetHeight(viewBounds) - (CGRectGetHeight(pageRect) * scale)) / 2.0f;
        contentOffsetY = round((pageRect.origin.y * scale) - yOffset);
    } else {
        contentOffsetY = round((pageRect.origin.y * scale));
    }

    return CGPointMake(contentOffsetX, contentOffsetY);
}

- (CGPoint)contentOffsetToFitRect:(CGRect)aRect onPage:(NSInteger)aPageNumber zoomScale:(CGFloat *)scale {
    CGAffineTransform blockTransform = [self blockTransformForPage:aPageNumber];
    CGRect targetRect = CGRectApplyAffineTransform(aRect, blockTransform);
    CGRect viewBounds = self.contentView.bounds;
    CGFloat zoomScale = CGRectGetWidth(viewBounds) / CGRectGetWidth(targetRect);
    targetRect = CGRectInset(targetRect, -kBlioPDFBlockInsetX / zoomScale, -kBlioPDFBlockInsetY / zoomScale);
    targetRect = [self fitRectToContentView:targetRect];

    // Clamp the page crop to the bottom of the layout view
    zoomScale = CGRectGetWidth(viewBounds) / CGRectGetWidth(targetRect);
    *scale = zoomScale;
    
    CGFloat pageWidth = CGRectGetWidth(viewBounds) * zoomScale;
    CGPoint viewOrigin = CGPointMake((aPageNumber - 1) * pageWidth, 0); 
    CGFloat contentOffsetX = round(viewOrigin.x + (targetRect.origin.x * zoomScale));
    
    CGRect cropRect;
    CGAffineTransform boundsTransform = [self boundsTransformForPage:aPageNumber cropRect:&cropRect];
    CGRect pageRect = CGRectApplyAffineTransform(cropRect, boundsTransform);
    
    CGFloat contentOffsetY = round(targetRect.origin.y * zoomScale);
    // maxContentOffsetYToClampPage = A - B - C
    // Where A = scaled content view height
    //       B = height of layout view
    //       C = scaled inset of page crop
    CGFloat scaledContentViewHeight = CGRectGetHeight(viewBounds) * zoomScale;
    CGFloat heightOfScrollView = CGRectGetHeight(self.bounds);
    CGFloat scaledInsetOfPageCrop = CGRectGetMinY(pageRect) * zoomScale;
    CGFloat maxContentOffsetYToClampPage = scaledContentViewHeight - heightOfScrollView - scaledInsetOfPageCrop;
    
    if (contentOffsetY > maxContentOffsetYToClampPage) {
        contentOffsetY = maxContentOffsetYToClampPage;
    }

    return CGPointMake(contentOffsetX, contentOffsetY);
}


#pragma mark -
#pragma mark BlioLayoutRenderingDelegate

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

- (CGAffineTransform)blockTransformForPage:(NSInteger)aPageNumber {
    if (cachedViewTransformPage != aPageNumber) {
        
        if (nil == viewTransformsCache) return CGAffineTransformIdentity;
        NSValue *viewTransformValue;
        
        @synchronized (viewTransformsCache) {
            viewTransformValue = [viewTransformsCache objectForKey:[NSNumber numberWithInt:aPageNumber]];
        }
        
        if (nil == viewTransformValue) return CGAffineTransformIdentity;
        
        CGAffineTransform viewTransform = [viewTransformValue CGAffineTransformValue];
        
        CGRect cropRect;
        CGAffineTransform boundsTransform = [self boundsTransformForPage:aPageNumber cropRect:&cropRect];  
        cachedViewTransform = CGAffineTransformConcat(viewTransform, boundsTransform);
        cachedViewTransformPage = aPageNumber;
    }
    
    return cachedViewTransform;
}

- (void)drawThumbLayer:(CALayer *)aLayer inContext:(CGContextRef)ctx  forPage:(NSInteger)aPageNumber withCacheLayer:(CGLayerRef)cacheLayer {
    UIImage *thumbImage = [self.dataSource thumbnailForPage:aPageNumber];
    if (thumbImage) {
        CGRect cropRect;
        CGAffineTransform boundsTransform = [self boundsTransformForPage:aPageNumber cropRect:&cropRect];
        if (CGRectEqualToRect(cropRect, CGRectZero)) return;
        cropRect = CGRectApplyAffineTransform(cropRect, boundsTransform);
        
        CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
        CGContextFillRect(ctx, cropRect);
        
        CGContextSetInterpolationQuality(ctx, kCGInterpolationLow);
        CGContextDrawImage(ctx, cropRect, thumbImage.CGImage);
    } else {
        if (cacheLayer) {
            CGRect cropRect;
            CGAffineTransform boundsTransform = [self boundsTransformForPage:aPageNumber cropRect:&cropRect];
            if (CGRectEqualToRect(cropRect, CGRectZero)) return;
            cropRect = CGRectApplyAffineTransform(cropRect, boundsTransform);
            
            CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
            CGContextFillRect(ctx, cropRect);
            CGContextDrawLayerInRect(ctx, cropRect, cacheLayer);
        }
    }
}

- (void)drawTiledLayer:(CALayer *)aLayer inContext:(CGContextRef)ctx forPage:(NSInteger)aPageNumber cacheReadyTarget:(id)target cacheReadySelector:(SEL)readySelector {
    //NSLog(@"Tiled rendering started for page %d isCancelled %d", aPageNumber, isCancelled);
    // Because this occurs on a background thread but accesses self, we must check whether we have been cancelled
    //CGRect layerBounds = aLayer.bounds;
    //fprintf(stderr, "\n");

   // NSLog(@"drawTile %d inContext %@ inBounds %@ withClip %@", aPageNumber, NSStringFromCGAffineTransform(CGContextGetCTM(ctx)), NSStringFromCGRect(aLayer.bounds), NSStringFromCGRect(CGContextGetClipBoundingBox(ctx)));
    //NSLog(@"drawTile %d subRect %@", aPageNumber, NSStringFromCGRect(CGRectApplyAffineTransform(CGContextGetClipBoundingBox(ctx), CGContextGetCTM(ctx))));
        
    //CGContextTranslateCTM(ctx, 0, layerBounds.size.height);
	//CGContextScaleCTM(ctx, 1, -1);
    
    if (isCancelled) return;
    
    CGRect cropRect;
    CGAffineTransform boundsTransform = [self boundsTransformForPage:aPageNumber cropRect:&cropRect];
    if (CGRectEqualToRect(cropRect, CGRectZero)) return;
    cropRect = CGRectApplyAffineTransform(cropRect, boundsTransform);
    //CGContextSetFillColorWithColor(ctx, [UIColor yellowColor].CGColor);

    //CGContextFillRect(ctx, cropRect);
    //CGContextClipToRect(ctx, cropRect);
    
    if (isCancelled) return;

    @synchronized (self.dataSource) {
        [self.dataSource openDocumentIfRequired];
        CGRect unscaledCropRect = [self.dataSource cropRectForPage:aPageNumber];
        //NSLog(@"unscaledCropRect %@", NSStringFromCGRect(unscaledCropRect));
        CGAffineTransform pageTransform = transformRectToFitRectWidth(unscaledCropRect, cropRect);
        
        //CGContextConcatCTM(ctx, pageTransform);
        //if (false) {
        if (nil != target) {
            
            UIImage *thumbImage = [self.dataSource thumbnailForPage:aPageNumber];
            CGLayerRef aCGLayer;
            
            if (thumbImage) {
                CGSize thumbSize = thumbImage.size;
                CGRect cacheRect = CGRectMake(0, 0, thumbSize.width, thumbSize.height);
                aCGLayer = CGLayerCreateWithContext(ctx, cacheRect.size, NULL);
                CGContextRef cacheCtx = CGLayerGetContext(aCGLayer);
                CGContextSetInterpolationQuality(cacheCtx, kCGInterpolationNone);
                CGContextDrawImage(cacheCtx, cacheRect, thumbImage.CGImage);
            } else {
                CGRect cacheRect = CGRectIntegral(CGRectMake(0, 0, 160, 240));
                CGAffineTransform cacheTransform = transformRectToFitRect(unscaledCropRect, cacheRect, false);
//            cacheRect = CGRectApplyAffineTransform(unscaledCropRect, cacheTransform);
//            cacheRect.origin = CGPointZero;
            //cacheTransform = transformRectToFitRect(unscaledCropRect, cacheRect);
            
                aCGLayer = CGLayerCreateWithContext(ctx, cacheRect.size, NULL);
                CGContextRef cacheCtx = CGLayerGetContext(aCGLayer);
            //CGContextTranslateCTM(cacheCtx, 0, cacheRect.size.height);
            //CGContextScaleCTM(cacheCtx, 1, -1);
            
            //CGContextConcatCTM(cacheCtx, cacheTransform);
            
            //CGContextSetFillColorWithColor(cacheCtx, [UIColor whiteColor].CGColor);
            //CGContextClipToRect(cacheCtx, unscaledCropRect);
//            CGContextFillRect(cacheCtx, unscaledCropRect);
            //CGContextFillRect(cacheCtx, cacheRect);
            
//            [self.dataSource drawPage:aPageNumber inContext:cacheCtx withTransform:CGAffineTransformConcat(pageTransform, cacheTransform)];
                [self.dataSource drawPage:aPageNumber inBounds:cacheRect withInset:0 inContext:cacheCtx inRect:cacheRect withTransform:cacheTransform observeAspect:NO];
            }
            
            if ([target respondsToSelector:readySelector])
                [target performSelectorOnMainThread:readySelector withObject:(id)aCGLayer waitUntilDone:NO];
            
            CGLayerRelease(aCGLayer);
            
            if (isCancelled) {
                //[self.dataSource closeDocumentIfRequired];
                return;
            }
            [self.dataSource drawPage:aPageNumber inBounds:aLayer.bounds withInset:kBlioLayoutShadow inContext:ctx inRect:cropRect withTransform:pageTransform observeAspect:YES];
            
        } else {
            [self.dataSource drawPage:aPageNumber inBounds:aLayer.bounds withInset:kBlioLayoutShadow inContext:ctx inRect:cropRect withTransform:pageTransform observeAspect:YES];
//            [self.dataSource drawPage:aPageNumber inContext:ctx inRect:cropRect withTransform:pageTransform];
        }
        if (isCancelled) {
            //[self.dataSource closeDocumentIfRequired];
            return;
        }
        [self.dataSource closeDocumentIfRequired];

    }
}

- (void)drawShadowLayer:(CALayer *)aLayer inContext:(CGContextRef)ctx forPage:(NSInteger)aPageNumber {
    
    CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor);
    CGRect layerBounds = aLayer.bounds;
    CGContextFillRect(ctx, layerBounds);

    CGRect cropRect;
    CGAffineTransform boundsTransform = [self boundsTransformForPage:aPageNumber cropRect:&cropRect];
    if (CGRectEqualToRect(cropRect, CGRectZero)) return;
    cropRect = CGRectApplyAffineTransform(cropRect, boundsTransform);
    
//    CGContextTranslateCTM(ctx, 0, layerBounds.size.height);
//	CGContextScaleCTM(ctx, 1, -1);
    
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

- (void)drawHighlightsLayer:(CALayer *)aLayer inContext:(CGContextRef)ctx forPage:(NSInteger)aPageNumber excluding:(BlioBookmarkRange *)excludedBookmark {
    CGAffineTransform viewTransform = [self blockTransformForPage:aPageNumber];
    
    for (BlioLayoutViewColoredRect *coloredRect in [self highlightRectsForPage:aPageNumber excluding:excludedBookmark]) {
        UIColor *highlightColor = [coloredRect color];
        CGContextSetFillColorWithColor(ctx, [highlightColor colorWithAlphaComponent:0.3f].CGColor);
        CGRect adjustedRect = CGRectApplyAffineTransform([coloredRect rect], viewTransform);
        CGContextFillRect(ctx, adjustedRect);
    }
}

#pragma mark -
#pragma mark Highlights

- (NSArray *)highlightRectsForPage:(NSInteger)aPageNumber excluding:(BlioBookmarkRange *)excludedBookmark {
    
    NSInteger pageIndex = aPageNumber - 1;
    NSMutableArray *allHighlights = [NSMutableArray array];
    NSArray *highlightRanges = [self.delegate rangesToHighlightForLayoutPage:aPageNumber];
    NSArray *pageBlocks = [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:NO];
    
    for (BlioBookmarkRange *highlightRange in highlightRanges) {
        
        if (![highlightRange isEqual:excludedBookmark]) {
            NSMutableArray *highlightRects = [[NSMutableArray alloc] init];
            
            for (BlioTextFlowBlock *block in pageBlocks) {                
                for (BlioTextFlowPositionedWord *word in [block words]) {
                    // If the range starts before this word:
                    if ( highlightRange.startPoint.layoutPage < aPageNumber ||
                       ((highlightRange.startPoint.layoutPage == aPageNumber) && (highlightRange.startPoint.blockOffset < block.blockIndex)) ||
                       ((highlightRange.startPoint.layoutPage == aPageNumber) && (highlightRange.startPoint.blockOffset == block.blockIndex) && (highlightRange.startPoint.wordOffset <= word.wordIndex)) ) {
                        // If the range ends after this word:
                        if ( highlightRange.endPoint.layoutPage > aPageNumber ||
                            ((highlightRange.endPoint.layoutPage == aPageNumber) && (highlightRange.endPoint.blockOffset > block.blockIndex)) ||
                            ((highlightRange.endPoint.layoutPage == aPageNumber) && (highlightRange.endPoint.blockOffset == block.blockIndex) && (highlightRange.endPoint.wordOffset >= word.wordIndex)) ) {
                            // This word is in the range.
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
            
            [highlightRects release];
        }
    
    }
    
    return allHighlights;
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
    
    CGFloat scale = self.scrollView.zoomScale * 1.2;
    CGSize snapSize = self.bounds.size;
    snapSize.width *= 1.2;
    snapSize.height *= 1.2;
    
    if (nil == self.pageSnapshot) {
        UIGraphicsBeginImageContext(snapSize);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGPoint translatePoint = [snapLayer convertPoint:CGPointZero fromLayer:[self.scrollView.layer superlayer]];
        //CGContextTranslateCTM(ctx, 0, snapSize.height);
        CGContextTranslateCTM(ctx, -translatePoint.x*scale, (snapSize.height/1.2 - translatePoint.y)*scale);
        
        CGContextScaleCTM(ctx, 1, -1);
        
        CGContextScaleCTM(ctx, scale, scale);
        //CGContextTranslateCTM(ctx, -translatePoint.x, snapSize.height -translatePoint.y);
        [[snapLayer shadowLayer] renderInContext:ctx];        
        [[snapLayer tiledLayer] renderInContext:ctx];
        self.pageSnapshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    if (nil == self.highlightsSnapshot) {
        UIGraphicsBeginImageContext(snapSize);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        [self.pageSnapshot drawAtPoint:CGPointZero];
        CGPoint translatePoint = [snapLayer convertPoint:CGPointZero fromLayer:[self.scrollView.layer superlayer]];
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
//            NSLog(@"pageLayer changed to page %d", self.currentPageLayer.pageNumber);
            [self.selector setSelectedRange:nil];
            [self.selector attachToLayer:self.currentPageLayer];
            [self displayHighlightsForLayer:self.currentPageLayer excluding:nil];
            if (![self.delegate audioPlaying]) {
                UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
                UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
                accessibilityRefreshRequired = YES;
            }
        }
    } else if (object == self.delegate) {
        if ([keyPath isEqualToString:@"audioPlaying"]) {
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
            accessibilityRefreshRequired = YES;
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
    if(![self.selector selectedRangeIsHighlight]) {
        [self clearHighlightsSnapshot];
    }    
    
    [super addHighlightWithColor:color];
}


#pragma mark -
#pragma mark TTS

- (void)highlightWordAtBookmarkPoint:(BlioBookmarkPoint *)bookmarkPoint {
    if(bookmarkPoint) {
        NSInteger pageIndex = bookmarkPoint.layoutPage - 1;
        NSArray *pageBlocks = [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:YES];
        BlioTextFlowBlock *currentBlock = [pageBlocks objectAtIndex:bookmarkPoint.blockOffset];

        NSInteger targetPageNumber = pageIndex + 1;
        if ((self.pageNumber != targetPageNumber) && !self.disableScrollUpdating) {
            [self goToPageNumber:targetPageNumber animated:YES];
        }
        
        NSUInteger wordOffset = bookmarkPoint.wordOffset;
        BlioTextFlowPositionedWord *word = [[currentBlock words] objectAtIndex:wordOffset];
        [self.selector temporarilyHighlightElementWithIdentfier:[word wordID] inBlockWithIdentifier:currentBlock.blockID animated:YES];
        
    } else {
        [self.selector removeTemporaryHighlight];
    }
}

#pragma mark -
#pragma mark Goto Animations


- (void)gotoCurrentPageAnimated {
    [self goToPageNumber:self.pageNumber animated:YES];
}

- (void)goToPageNumber:(NSInteger)targetPage animated:(BOOL)animated shouldZoomOut:(BOOL)zoomOut targetZoomScale:(CGFloat)targetZoom targetContentOffset:(CGPoint)targetOffset {
    //NSLog(@"Goto page %d : %d %d %f %@", targetPage, animated, zoomOut, targetZoom, NSStringFromCGPoint(targetOffset));
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
        NSInteger fromPage = startPage;
        
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        self.pageNumber = targetPage;
        NSInteger pagesToGo = targetPage - startPage;
        
        self.disableScrollUpdating = YES;
        [self.scrollView setPagingEnabled:NO]; // Paging affects the animations
        
        NSMutableSet *pageLayersToPreserve = [NSMutableSet set];
        
        
        if (abs(pagesToGo) > 3) {
            NSInteger pagesToOffset = pagesToGo - (3 * (pagesToGo/abs(pagesToGo)));
            CGFloat frameOffset = pagesToOffset * CGRectGetWidth(self.bounds);
            fromPage = startPage + pagesToOffset;
                        
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey: kCATransactionDisableActions];
                        
            // The current offset and pageFrames are translated to move the next to the targetPage's adjacent page
            [self.scrollView setContentOffset:CGPointApplyAffineTransform([self.scrollView contentOffset], CGAffineTransformMakeTranslation(frameOffset*self.scrollView.zoomScale, 0))];
            
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
            }
            
            NSSet *nextLayerSet = [[self.contentView pageLayers] filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"pageNumber==%d", startPage + 1]];
            if ([nextLayerSet count]) {
                CALayer *nextLayer = [[nextLayerSet allObjects] objectAtIndex:0];
                CGRect newFrame = self.currentPageLayer.frame;
                newFrame.origin.x += CGRectGetWidth(self.currentPageLayer.frame);
                nextLayer.frame = newFrame;
                [pageLayersToPreserve addObject:nextLayer];
            }
            
            // Shift all the other layers offscreen so that they don't appear in the wrong place (e.g. to the left of the first page)
            NSMutableSet *nonPreserved = [NSMutableSet setWithSet:[self.contentView pageLayers]];
            [nonPreserved minusSet:pageLayersToPreserve];
            for (CALayer *layer in nonPreserved) {
                [layer setPosition:CGPointMake(-10000, -10000)];
            }
            
            [CATransaction commit];
        }
        
        // TODO -remove these checks
        if ([pageLayersToPreserve count] > 3) {
            NSLog(@"WARNING: more than 3 pages found to preserve during go to animation: %@", [pageLayersToPreserve description]); 
        }
        
        // 2. Load the target page and its adjacent pages
        BlioLayoutPageLayer *aLayer = [self.contentView addPage:targetPage retainPages:pageLayersToPreserve];
        if (aLayer) {
            [pageLayersToPreserve addObject:aLayer];
            self.currentPageLayer = aLayer;
            [aLayer forceThumbCacheAfterDelay:0];
        }
        
        BlioLayoutPageLayer *prevLayer = [self.contentView addPage:targetPage - 1 retainPages:pageLayersToPreserve];
        if (prevLayer) { 
            [pageLayersToPreserve addObject:prevLayer];
        }
        
        BlioLayoutPageLayer *nextLayer = [self.contentView addPage:targetPage + 1 retainPages:pageLayersToPreserve];
        
        if (startPage > targetPage) {
            [prevLayer forceThumbCacheAfterDelay:0.85f];
        } else {
            [nextLayer forceThumbCacheAfterDelay:0.85f];
        }
        
        // The rest of the steps are performed after the animation thread has been run
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

        CGSize newContentSize = [self currentContentSize];
        [self.containerView setFrame:CGRectMake(0,0, ceilf(newContentSize.width), ceilf(newContentSize.height))];
        [self.scrollView setContentSize:newContentSize];
        [self.scrollView setContentOffset:[self contentOffsetToCenterPage:targetPage zoomScale:self.scrollView.zoomScale]]; 
        self.pageNumber = targetPage;
        [self didChangeValueForKey:@"pageNumber"];
    }
}

- (void)performGoToPageStep1FromPage:(NSInteger)fromPage {

    CFTimeInterval shrinkDuration = 0.25f + (0.5f * (self.scrollView.zoomScale / self.scrollView.maximumZoomScale));
    [UIView beginAnimations:@"BlioLayoutGoToPageStep1" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [UIView setAnimationDuration:shrinkDuration];
    [UIView setAnimationBeginsFromCurrentState:YES];
    if (shouldZoomOut) {
        [self.scrollView setMinimumZoomScale:kBlioPDFGoToZoomTransitionScale];
        [self.scrollView setZoomScale:kBlioPDFGoToZoomTransitionScale];
        CGSize newContentSize = [self currentContentSize];
        [self.containerView setFrame:CGRectMake(0,0, ceilf(newContentSize.width), ceilf(newContentSize.height))];
        [self.scrollView setContentSize:newContentSize];
        [self.scrollView setContentOffset:[self contentOffsetToCenterPage:fromPage zoomScale:kBlioPDFGoToZoomTransitionScale]]; 
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
        [self.scrollView setContentOffset:[self contentOffsetToCenterPage:self.pageNumber zoomScale:kBlioPDFGoToZoomTransitionScale]]; 
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
    CGSize newContentSize = [self currentContentSize];
    [self.containerView setFrame:CGRectMake(0,0, ceilf(newContentSize.width), ceilf(newContentSize.height))];
    [self.scrollView setContentSize:newContentSize];
    if (CGPointEqualToPoint(targetContentOffset, CGPointZero))
        [self.scrollView setContentOffset:[self contentOffsetToCenterPage:self.pageNumber zoomScale:kBlioPDFGoToZoomTargetScale]]; 
    else
        [self.scrollView setContentOffset:targetContentOffset];
    
    [UIView commitAnimations];
    [self didChangeValueForKey:@"pageNumber"];    
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    if (finished) {
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

- (CGRect)firstPageRect {
    if ([self pageCount] > 0) {
        CGRect cropRect;
        CGAffineTransform boundsTransform = [self boundsTransformForPage:1 cropRect:&cropRect];
        CGRect pageRect = CGRectApplyAffineTransform(cropRect, boundsTransform);
        //return self.contentView.frame;
        return pageRect;
    } else {
        return self.contentView.frame;
    }
}

- (id<EucBookContentsTableViewControllerDataSource>)contentsDataSource {
    return self.textFlow;
}

#pragma mark -
#pragma mark Container UIScrollView Delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.containerView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)aScrollView withView:(UIView *)view atScale:(float)scale {
    //NSLog(@"scrollViewDidEndZooming");
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
        [self clearSnapshots];
        [self.selector setShouldHideMenu:NO];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    //NSLog(@"scrollViewDidScroll");
    [self.selector setShouldHideMenu:YES];

    if (self.disableScrollUpdating) return;

    NSInteger currentPageNumber;
    
    if (sender.zoomScale != lastZoomScale) {
        CGSize newContentSize = [self currentContentSize];
        [self.containerView setFrame:CGRectMake(0,0, ceilf(newContentSize.width), ceilf(newContentSize.height))];
        [sender setContentSize:newContentSize];
        self.lastZoomScale = sender.zoomScale;
        
        // If we are zooming, don't update the page number - (contentOffset gets set to zero so it wouldn't work)
        currentPageNumber = self.pageNumber;
    } else {
        CGFloat pageWidth = sender.contentSize.width / pageCount;
        currentPageNumber = floor((sender.contentOffset.x + CGRectGetWidth(self.bounds)/2.0f) / pageWidth) + 1;
    }
    
    //NSLog(@"Current page %d, pageNum %d", currentPageNumber, self.pageNumber);
    if (currentPageNumber != self.pageNumber) {
        
        BlioLayoutPageLayer *aLayer = [self.contentView addPage:currentPageNumber retainPages:nil];
        
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
        if (nil != self.accessibilityElements) {
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
            accessibilityRefreshRequired = YES;
        }
    }
}

- (void)updateAfterScroll {
    //NSLog(@"updateAfterScroll");
    [self clearSnapshots];
    [self.selector setShouldHideMenu:NO];
    if (self.disableScrollUpdating) return;
    
    
//    if (self.scrollToPageInProgress) {
//        self.scrollToPageInProgress = NO;
//        
//        [self.contentView addPage:self.pageNumber - 1 retainPages:nil];
//        [self.contentView addPage:self.pageNumber + 1 retainPages:nil];
//    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    self.disableScrollUpdating = NO;
    [self updateAfterScroll];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self updateAfterScroll];
}

#pragma mark -
#pragma mark Zoom Interactions

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
    
    [self.scrollView setPagingEnabled:NO];
    [self.scrollView setBounces:NO];
    
    BlioTextFlowBlock *targetBlock = nil;
    
    // Work out targetBlock on the current page
    if (self.lastBlock) {
        if (!reversed) {
            targetBlock = [self.textFlow nextBlockForBlock:self.lastBlock 
                                           includingFolioBlocks:NO
                                                     onSamePage:YES];                
        } else {
            targetBlock = [self.textFlow previousBlockForBlock:self.lastBlock 
                                               includingFolioBlocks:NO
                                                         onSamePage:YES];        
        }
    } else {
        if (!reversed) {
            NSArray *pageBlocks = [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:NO];
            if (pageBlocks.count > 0) {
                targetBlock = [pageBlocks objectAtIndex:0];
            }
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
            NSArray *pageBlocks = [self.textFlow blocksForPageAtIndex:newPageIndex includingFolioBlocks:NO];
            
            if (pageBlocks.count > 0) {
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
    NSArray *blocks = [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:NO];

    [self.scrollView setPagingEnabled:NO];
    [self.scrollView setBounces:NO];
    
    BlioTextFlowBlock *targetBlock = nil;
    CGAffineTransform viewTransform = [self blockTransformForPage:targetPage];
    
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
    
}

- (void)zoomToBlock:(BlioTextFlowBlock *)targetBlock context:(void *)context {
    NSInteger targetPageNumber = [targetBlock pageIndex] + 1;
    CGFloat zoomScale;
    CGPoint newContentOffset = [self contentOffsetToFitRect:[targetBlock rect] onPage:targetPageNumber zoomScale:&zoomScale];
    newContentOffset = CGPointMake(roundf(newContentOffset.x), roundf(newContentOffset.y));
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
}

- (void)zoomOut {
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
}

#pragma mark -
#pragma mark Manual KVO overrides

- (void)setPageNumber:(NSInteger)newPageNumber {
    if (!self.disableScrollUpdating) {
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

#pragma mark -
#pragma mark Accessibility

- (void)createAccessibilityElements {
    NSMutableArray *elements = nil;
    if (![self.delegate audioPlaying]) {
        

    
    elements = [NSMutableArray array];
    NSInteger currentPage = self.pageNumber;
    
    CGRect cropRect;
    CGAffineTransform boundsTransform = [self boundsTransformForPage:currentPage cropRect:&cropRect];
    cropRect = CGRectApplyAffineTransform(cropRect, boundsTransform);
    
    if (layoutMode == BlioLayoutPageModeLandscape) {
        //CGRect newCropRect = CGRectMake(-CGRectGetHeight(self.contentView.frame) + CGRectGetHeight(self.frame) + cropRect.origin.y, cropRect.origin.x, cropRect.size.height, cropRect.size.width);
        //cropRect.origin.y -= self.scrollView.contentOffset.y;
        CGRect newCropRect = [self.window.layer convertRect:cropRect fromLayer:self.currentPageLayer];
        
        //CGFloat originY = [self.window.layer convertPoint:newCropRect.origin fromLayer:self.currentPageLayer].y;
        if ((CGRectGetWidth(newCropRect) > CGRectGetHeight(self.scrollView.frame)) && (CGRectGetMinX(newCropRect) < CGRectGetMinY(self.scrollView.frame))) {
            CGFloat diff = CGRectGetMinY(self.scrollView.frame) - CGRectGetMinX(newCropRect);
            newCropRect.origin.x += diff;
            newCropRect.size.width -= diff;
        }
        
        if ((CGRectGetWidth(newCropRect) > CGRectGetHeight(self.scrollView.frame)) && (CGRectGetMaxX(newCropRect) > CGRectGetMaxY(self.scrollView.frame))) {
            CGFloat diff = CGRectGetMaxX(newCropRect) - CGRectGetMaxY(self.scrollView.frame);
            //newCropRect.origin.x += diff;
            newCropRect.size.width -= diff;
        }
        //if (CGRectGetWidth(newCropRect) > CGRectGetHeight(self.scrollView.frame)) {
//            CGFloat diff = CGRectGetWidth(newCropRect) - CGRectGetHeight(self.scrollView.frame);
//            newCropRect.origin.x += diff;
//            newCropRect.size.width -= diff;
//        }
        cropRect = newCropRect;
    }
    
    //if (![self.delegate audioPlaying]) {
//        UIAccessibilityElement *element = [[[UIAccessibilityElement alloc] initWithAccessibilityContainer:self] autorelease];
//        [element setAccessibilityFrame:cropRect];
//        [self.scrollView setIsAccessibilityElement:NO];
//        [elements addObject:element];        
//    } else {
        CGAffineTransform viewTransform = [self blockTransformForPage:currentPage];
        
        [self.scrollView setIsAccessibilityElement:YES];
        
        NSInteger pageIndex = currentPage - 1;
        NSArray *nonFolioPageBlocks = [self.textFlow blocksForPageAtIndex:pageIndex includingFolioBlocks:NO];
        
        NSMutableString *allWords = [NSMutableString string];
        for (BlioTextFlowBlock *block in nonFolioPageBlocks) {
            [allWords appendString:[block string]];
            BlioLayoutScrollViewAccessibleProxy *aProxy = [BlioLayoutScrollViewAccessibleProxy alloc];
            [aProxy setTarget:self.scrollView];
            CGRect blockRect = CGRectApplyAffineTransform([block rect], viewTransform);
            if (layoutMode == BlioLayoutPageModeLandscape) {
                //blockRect = CGRectMake(blockRect.origin.y-90, blockRect.origin.x, blockRect.size.height, blockRect.size.width);
                blockRect.origin.y -= self.scrollView.contentOffset.y;
                blockRect = [self.window.layer convertRect:blockRect fromLayer:self.currentPageLayer];
                blockRect.origin.x -= self.scrollView.contentOffset.y;
                //if (CGRectGetWidth(blockRect) > CGRectGetHeight(self.scrollView.frame)) {
//                    CGFloat diff = CGRectGetWidth(blockRect) - CGRectGetHeight(self.scrollView.frame);
//                    blockRect.origin.x += diff;
//                    blockRect.size.width -= diff;
//                }
                if ((CGRectGetWidth(blockRect) > CGRectGetHeight(self.scrollView.frame)) && (CGRectGetMinX(blockRect) < CGRectGetMinY(self.scrollView.frame))) {
                    CGFloat diff = CGRectGetMinY(self.scrollView.frame) - CGRectGetMinX(blockRect);
                    blockRect.origin.x += diff;
                    blockRect.size.width -= diff;
                }
                
                if ((CGRectGetWidth(blockRect) > CGRectGetHeight(self.scrollView.frame)) && (CGRectGetMaxX(blockRect) > CGRectGetMaxY(self.scrollView.frame))) {
                    CGFloat diff = CGRectGetMaxX(blockRect) - CGRectGetMaxY(self.scrollView.frame);
                    blockRect.size.width -= diff;
                }
            }
                                
            [aProxy setAccessibilityFrameProxy:blockRect];
            [aProxy setAccessibilityLabelProxy:[block string]];
            [elements addObject:aProxy];
            [aProxy release];
        }
        
        BlioLayoutScrollViewAccessibleProxy *aProxy = [BlioLayoutScrollViewAccessibleProxy alloc];
        [aProxy setTarget:self.scrollView];
        [aProxy setAccessibilityFrameProxy:cropRect];
        [aProxy setAccessibilityHintProxy:NSLocalizedString(@"Swipe to advance page.", @"Accessibility hint for page swipe advance")];
        
        if ([nonFolioPageBlocks count] == 0)
            [aProxy setAccessibilityLabelProxy:[NSString stringWithFormat:NSLocalizedString(@"Page %d is blank", @"Accessibility label for blank book page"), currentPage]];
        else
            [aProxy setAccessibilityLabelProxy:[NSString stringWithFormat:NSLocalizedString(@"End of page %d", @"Accessibility label for end of page"), currentPage]];
        
        [elements addObject:aProxy];
        [aProxy release];
        
   // }
    }
    
    // We keep around a copy of the previous accessibility elements because 
    // the OS doesn't retain them but can attempt to access them
    for (NSObject *accessibilityElement in self.accessibilityElements) {
        if ([accessibilityElement respondsToSelector:@selector(setProxyContainer:)])
            [accessibilityElement performSelector:@selector(setProxyContainer:) withObject:self];
    }
    
    self.previousAccessibilityElements = self.accessibilityElements;
    self.accessibilityElements = elements;
    accessibilityRefreshRequired = NO;
    //[elements release];
}

- (BOOL)isAccessibilityElement {
    if (accessibilityRefreshRequired) {
        [self createAccessibilityElements];
    }
    
    if (!self.disableScrollUpdating) {
    // If we are querying the accessibility mode, force us to zoom out to page
        if ([self.scrollView zoomScale] != kBlioPDFGoToZoomTargetScale) {
            [self.scrollView setZoomScale:kBlioPDFGoToZoomTargetScale animated:NO];
            CGSize newContentSize = [self currentContentSize];
            [self.containerView setFrame:CGRectMake(0,0, ceilf(newContentSize.width), ceilf(newContentSize.height))];
            [self.scrollView setContentSize:newContentSize];
        }
        
        CGPoint centeredOffset = [self contentOffsetToCenterPage:self.currentPageLayer.pageNumber zoomScale:kBlioPDFGoToZoomTargetScale];
        if ([self.scrollView contentOffset].x != centeredOffset.x) {
            [self.scrollView setContentOffset:centeredOffset animated:NO]; 
        }
    }
    return NO;
}

- (NSInteger)accessibilityElementCount {
    if (accessibilityRefreshRequired) {
        [self createAccessibilityElements];
    }
    
    return [self.accessibilityElements count];
}


- (id)accessibilityElementAtIndex:(NSInteger)index {
    if (accessibilityRefreshRequired) {
        [self createAccessibilityElements];
    }

    return [self.accessibilityElements objectAtIndex:index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
    if (accessibilityRefreshRequired) {
        [self createAccessibilityElements];
    }
    return [self.accessibilityElements indexOfObject:element];
}

@end

@implementation BlioLayoutViewColoredRect

@synthesize rect, color;

- (void)dealloc {
    self.color = nil;
    [super dealloc];
}

@end


@implementation BlioLayoutScrollViewAccessibleProxy

@synthesize target, accessibilityFrameProxy, accessibilityLabelProxy, accessibilityHintProxy, element;

- (void)dealloc {
    self.target = nil;
    self.accessibilityLabelProxy = nil;
    self.accessibilityHintProxy = nil;
    self.element = nil;
    [super dealloc];
}

- (NSMethodSignature *) methodSignatureForSelector:(SEL)aSelector {
    if (nil != self.element)
        return [self.element methodSignatureForSelector:aSelector];
    else
        return [self.target methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation*)anInvocation {
    if (nil != self.element) {
        [anInvocation invokeWithTarget:self.element];
    } else {
        
        [self.target setAccessibilityFrame:self.accessibilityFrameProxy];
        [self.target setAccessibilityLabel:self.accessibilityLabelProxy];
        [self.target setAccessibilityHint:self.accessibilityHintProxy];
        
        // Force the touches begin point to be the mid-point of the view
        // So that it only ever toggles the toolbars in accessibility mode
        // If we could check for voice-over mode being active we would just
        // handle this in the touch handling code
        [self.target setTouchesBeginPoint:CGPointMake(CGRectGetMidX([self.target frame]), CGRectGetMidY([self.target frame]))];
        
        [anInvocation invokeWithTarget:self.target];
    }
}

- (void)setProxyContainer:(id)container {
    // The proxy container is set when this object is no longer neded but might
    // still be accessed by internal accessibility methods
    UIAccessibilityElement *anElement = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:container];
    self.element = anElement;
    [anElement release];
}

@end

@implementation BlioLayoutPDFDataSource

@synthesize data;

- (void)dealloc {
    if (pdf) CGPDFDocumentRelease(pdf);
    self.data = nil;
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
    }
    return self;
}

- (NSInteger)pageCount {
    return pageCount;
}

- (CGRect)cropRectForPage:(NSInteger)page {
    CGPDFPageRef aPage = CGPDFDocumentGetPage(pdf, page);
    return CGPDFPageGetBoxRect(aPage, kCGPDFCropBox);
}

- (CGRect)mediaRectForPage:(NSInteger)page {
    CGPDFPageRef aPage = CGPDFDocumentGetPage(pdf, page);
    return CGPDFPageGetBoxRect(aPage, kCGPDFMediaBox);
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
    CGPDFPageRef aPage = CGPDFDocumentGetPage(pdf, page);
    CGPDFPageRetain(aPage);
    CGContextDrawPDFPage(ctx, aPage);
    CGPDFPageRelease(aPage);
}

- (void)openDocumentIfRequired {
    CGDataProviderRef pdfProvider = CGDataProviderCreateWithCFData((CFDataRef)self.data);
    pdf = CGPDFDocumentCreateWithProvider(pdfProvider);
    CGDataProviderRelease(pdfProvider);
}

- (UIImage *)thumbnailForPage:(NSInteger)pageNumber {
    return nil;
}

- (void)closeDocument {
    if (pdf) CGPDFDocumentRelease(pdf);
    pdf = NULL;
}

- (void)closeDocumentIfRequired {
    [self closeDocument];
}

@end


