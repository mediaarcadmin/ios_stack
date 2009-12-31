//
//  BlioLayoutView.m
//  BlioApp
//
//  Created by matt on 18/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "BlioLayoutView.h"

@interface BlioFastCATiledLayer : CATiledLayer
@end

static const CGFloat kBlioLayoutMaxZoom = 54.0f; // That's just showing off!
static const CGFloat kBlioLayoutShadow = 16.0f;
static const NSUInteger kBlioLayoutMaxViews = 5;

@interface BlioPDFTiledLayerDelegate : NSObject {
    CGPDFPageRef page;
    CGAffineTransform fitTransform;
    CGRect pageRect;
}

@property(nonatomic) CGPDFPageRef page;
@property(nonatomic) CGAffineTransform fitTransform;

@end

@interface BlioPDFShadowLayerDelegate : NSObject {
    CGRect pageRect;
}

@property(nonatomic) CGRect pageRect;

@end

@interface BlioPDFBackgroundLayerDelegate : NSObject {
    CGRect pageRect;
}

@property(nonatomic) CGRect pageRect;

@end

@interface BlioPDFDrawingView : UIView {
    CGPDFPageRef page;
    id layoutView;
    BlioFastCATiledLayer *tiledLayer;
    CALayer *backgroundLayer;
    BlioFastCATiledLayer *shadowLayer;
    BlioPDFTiledLayerDelegate *tiledLayerDelegate;
    BlioPDFBackgroundLayerDelegate *backgroundLayerDelegate;
    BlioPDFShadowLayerDelegate *shadowLayerDelegate;
}

@property (nonatomic, assign) id layoutView;
@property (nonatomic, retain) BlioPDFBackgroundLayerDelegate *backgroundLayerDelegate;
@property (nonatomic, retain) BlioPDFTiledLayerDelegate *tiledLayerDelegate;
@property (nonatomic, retain) BlioPDFShadowLayerDelegate *shadowLayerDelegate;
@property (nonatomic) CGPDFPageRef page;

- (id)initWithFrame:(CGRect)frame andPageRef:(CGPDFPageRef)newPage;

@end

@interface BlioLayoutView(private)
NSInteger visiblePage;

- (void)loadPage:(int)pageIndex;

@end

@interface BlioPDFScrollView : UIScrollView <UIScrollViewDelegate> {
    UIView *view;
}

@property (nonatomic, retain) UIView *view;

- (id)initWithView:(UIView *)view;

@end

@implementation BlioLayoutView

@synthesize scrollView, pageViews, navigationController;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    CGPDFDocumentRelease(pdf);
    self.scrollView = nil;
    self.pageViews = nil;
    self.navigationController = nil;
    [super dealloc];
}

- (id)initWithPath:(NSString *)path {
    NSURL *pdfURL = [NSURL fileURLWithPath:path];
    pdf = CGPDFDocumentCreateWithURL((CFURLRef)pdfURL);
    if (NULL == pdf) return nil;
    
    if ((self = [super initWithFrame:CGRectMake(0,0,320,480)])) {
        // Initialization code
        self.clearsContextBeforeDrawing = NO; // Performance optimisation;
        NSInteger pageCount = CGPDFDocumentGetNumberOfPages(pdf);
        
        UIScrollView *aScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        aScrollView.contentSize = CGSizeMake(aScrollView.frame.size.width * pageCount, aScrollView.frame.size.height);
        aScrollView.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
        aScrollView.pagingEnabled = YES;
        aScrollView.showsHorizontalScrollIndicator = NO;
        aScrollView.showsVerticalScrollIndicator = NO;
        aScrollView.scrollsToTop = NO;
        aScrollView.delegate = self;
        [self addSubview:aScrollView];
        self.scrollView = aScrollView;
        [aScrollView release];
        
        // This pattern of an array of lazily loaded views will need to be replaced with a more
        // memory efficient implementation - if ou scrolled to the end of the book you would run out of memory
        
        NSMutableArray *pageViewArray = [[NSMutableArray alloc] initWithCapacity:kBlioLayoutMaxViews];
        self.pageViews = pageViewArray;
        [pageViewArray release];
        
        visiblePage = 0;
        [self loadPage:0];
        [self loadPage:1];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutZoomInProgress:) name:@"BlioLayoutZoomInProgress" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutZoomEnded:) name:@"BlioLayoutZoomEnded" object:nil];
        
    }
    return self;
}

#pragma mark -
#pragma mark Notification Callbacks

- (void)layoutZoomInProgress:(NSNotification *)notification {
    [self.scrollView setScrollEnabled:NO];
}

- (void)layoutZoomEnded:(NSNotification *)notification {
    [self.scrollView setScrollEnabled:YES];
}


- (void)loadPage:(int)pageIndex {
    if (pageIndex < 0) return;
    if (pageIndex >= CGPDFDocumentGetNumberOfPages (pdf)) return;
	
    BlioPDFScrollView *pageView = nil;
    NSUInteger pageNumber = pageIndex + 1;
    CGPDFPageRef pdfPageRef = CGPDFDocumentGetPage(pdf, pageNumber);
    
    NSUInteger furthestPageIndex = 0;
    NSUInteger furthestPageDifference = 0;
    
    // First, see if we have it cached and determine the furthest away page
    NSInteger viewCacheCount = [self.pageViews count];
    for(NSInteger i = 0; i < viewCacheCount; ++i) {
        BlioPDFScrollView *cachedPageView = [self.pageViews objectAtIndex:i];
        NSUInteger cachedPageNumber = CGPDFPageGetPageNumber([(BlioPDFDrawingView *)[cachedPageView view] page]);
        if(cachedPageNumber == pageNumber) {
            pageView = cachedPageView;
            break;
        } else {
            NSInteger pageDifference = abs(pageNumber - cachedPageNumber);
            if (pageDifference > furthestPageDifference) {
                furthestPageDifference = pageDifference;
                furthestPageIndex = i;
            }
        }
    }
    
    // Not found in cache, so we need to create it.
    if(nil == pageView) {
        if (viewCacheCount < kBlioLayoutMaxViews) {
            BlioPDFDrawingView *pdfView = [[BlioPDFDrawingView alloc] initWithFrame:self.scrollView.bounds andPageRef:pdfPageRef];
            pageView = [[BlioPDFScrollView alloc] initWithView:pdfView];
            [pdfView release];
            [self.pageViews addObject:pageView];
        } else {
            pageView = [self.pageViews objectAtIndex:furthestPageIndex];
            [pageView retain];
            [self.pageViews removeObjectAtIndex:furthestPageIndex];
            [self.pageViews addObject:pageView];
            [pageView release];
            [(BlioPDFDrawingView *)[pageView view] setPage:pdfPageRef];
        }
        
        CGRect frame = self.scrollView.frame;
        frame.origin.x = frame.size.width * pageIndex;
        frame.origin.y = 0;
        [pageView setFrame:frame];
        [self.scrollView addSubview:pageView];
        
    }
}

#pragma mark -
#pragma mark Container UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    
    CGFloat pageWidth = self.scrollView.frame.size.width;
    int currentPage = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
	
    if (currentPage != visiblePage) {
        [self loadPage:currentPage - 1];
        [self loadPage:currentPage];
        [self loadPage:currentPage + 1];
        
        visiblePage = currentPage;
    }
}

@end

@implementation BlioPDFScrollView

@synthesize view;

- (void)dealloc {
    self.view = nil;
    [super dealloc];
}

- (id)initWithView:(BlioPDFDrawingView *)newView {
    NSAssert1(kBlioLayoutMaxViews >= 3, @"Error: kBlioLayoutMaxViews is %d. This must be 3 or greater.", kBlioLayoutMaxViews);
    
    if ((self = [super initWithFrame:newView.frame])) {
        [self addSubview:newView];
        [newView setFrame:newView.bounds];
        self.view = newView;
        self.multipleTouchEnabled = YES;
        self.backgroundColor = [UIColor clearColor];
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.bounces = NO;
        self.clipsToBounds = NO;
        self.directionalLockEnabled = NO;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self;
        self.minimumZoomScale = 1.0f;
        self.maximumZoomScale = kBlioLayoutMaxZoom;
        self.contentSize = newView.bounds.size;
    }
    return self;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
    if (scale == 1) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BlioLayoutZoomEnded" object:nil userInfo:nil];
        scrollView.scrollEnabled = NO;
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BlioLayoutZoomInProgress" object:nil userInfo:nil];
        scrollView.scrollEnabled = YES;
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.view;
}


- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view {
    // get any touch
    UITouch * t = [touches anyObject];
    if( [t tapCount]>1 ) {
        CGPoint point = [t locationInView:self];
        [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(zoomAtPointAfterDelay:) userInfo:NSStringFromCGPoint(point) repeats:NO];
        return NO;
    }
    return YES;
}

- (void)zoomAtPoint:(CGPoint)point {
    if (self.zoomScale > 1.0f) {
        [self setZoomScale:1.0f animated:YES];
    } else {
        CGFloat width  = self.contentSize.width  / 2.75f;
        CGFloat height = self.contentSize.height / 2.75f;
        CGFloat midX = (point.x / CGRectGetWidth(self.bounds)) * self.contentSize.width;
        CGFloat midY = self.contentSize.height - ((point.y / CGRectGetHeight(self.bounds)) * self.contentSize.height);
        CGRect targetRect = CGRectMake(midX - width/2.0f, midY - height/2.0f, width, height);
        [self zoomToRect:targetRect animated:YES];
    }
}

- (void)zoomAtPointAfterDelay:(NSTimer *)timer {
    NSString *pointString = [timer userInfo];
    CGPoint point = CGPointZero;
    if (pointString) point = CGPointFromString(pointString);
    [self zoomAtPoint:point];
}

@end


@implementation BlioPDFDrawingView

@synthesize layoutView, tiledLayerDelegate, backgroundLayerDelegate, shadowLayerDelegate, page;

- (void)dealloc {
    CGPDFPageRelease(page);
    self.layoutView = nil;
    [tiledLayer setDelegate:nil];
    [backgroundLayer setDelegate:nil];
    [shadowLayer setDelegate:nil];
    self.tiledLayerDelegate = nil;
    self.backgroundLayerDelegate = nil;
    self.shadowLayerDelegate = nil;
	[super dealloc];
}

- (void)configureLayers {
    tiledLayer = [BlioFastCATiledLayer layer];
    
    CGRect pageRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    CGFloat inset = -kBlioLayoutShadow;
    CGRect insetBounds = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(-inset, -inset, -inset, -inset));
    
    CGAffineTransform fitTransform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, insetBounds, 0, true);
    CGRect fittedPageRect = CGRectApplyAffineTransform(pageRect, fitTransform);     
    
    int w = pageRect.size.width;
    int h = pageRect.size.height;
    
    int levels = 1;
    while (w > 1 && h > 1) {
        levels++;
        w = w >> 1;
        h = h >> 1;
    }
    
    tiledLayer.levelsOfDetail = levels;
    tiledLayer.levelsOfDetailBias = levels;
    tiledLayer.tileSize = CGSizeMake(1024, 1024);
    
    CGRect origBounds = self.bounds;
    CGRect newBounds = self.bounds;
    
    newBounds.size.width = origBounds.size.width*2;
    insetBounds.origin.x += (newBounds.size.width - origBounds.size.width)/2.0f;
    
    tiledLayer.bounds = newBounds;
    fitTransform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, insetBounds, 0, true);
    
    BlioPDFTiledLayerDelegate *aTileDelegate = [[BlioPDFTiledLayerDelegate alloc] init];
    [aTileDelegate setPage:page];
    [aTileDelegate setFitTransform:fitTransform];
    tiledLayer.delegate = aTileDelegate;
    self.tiledLayerDelegate = aTileDelegate;
    [aTileDelegate release];
    
    tiledLayer.position = CGPointMake(self.layer.bounds.size.width/2.0f, self.layer.bounds.size.height/2.0f);  
    
    // transform the super layer so things draw 'right side up'
    CATransform3D superTransform = CATransform3DMakeTranslation(0.0f, self.bounds.size.height, 0.0f);
    self.layer.transform = CATransform3DScale(superTransform, 1.0, -1.0f, 1.0f);
    [self.layer addSublayer:tiledLayer];
    
    [tiledLayer setNeedsDisplay];
    
    backgroundLayer = [CALayer layer];
    BlioPDFBackgroundLayerDelegate *aBackgroundDelegate = [[BlioPDFBackgroundLayerDelegate alloc] init];
    [aBackgroundDelegate setPageRect:fittedPageRect];
    backgroundLayer.delegate = aBackgroundDelegate;
    self.backgroundLayerDelegate = aBackgroundDelegate;
    [aBackgroundDelegate release];
    
    backgroundLayer.bounds = self.bounds;
    backgroundLayer.position = tiledLayer.position;
    [self.layer insertSublayer:backgroundLayer below:tiledLayer];
    [backgroundLayer setNeedsDisplay];
    
    shadowLayer = [BlioFastCATiledLayer layer];
    BlioPDFShadowLayerDelegate *aShadowDelegate = [[BlioPDFShadowLayerDelegate alloc] init];
    [aShadowDelegate setPageRect:fittedPageRect];
    shadowLayer.delegate = aShadowDelegate;
    shadowLayer.levelsOfDetail = 1;
    shadowLayer.tileSize = CGSizeMake(1024, 1024);
    self.shadowLayerDelegate = aShadowDelegate;
    [aShadowDelegate release];
    
    shadowLayer.bounds = self.bounds;
    shadowLayer.position = tiledLayer.position;
    [self.layer insertSublayer:shadowLayer below:tiledLayer];
    [shadowLayer setNeedsDisplay];
}

- (id)initWithFrame:(CGRect)frame andPageRef:(CGPDFPageRef)newPage {
	self = [super initWithFrame:frame];
	if(self != nil) {
        page = newPage;
        CGPDFPageRetain(page);
        
        self.backgroundColor = [UIColor clearColor];
        
        [self configureLayers];
	}
	return self;
}

- (void)setPage:(CGPDFPageRef)newPage {
    CGRect currentPageRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    CGRect newPageRect = CGPDFPageGetBoxRect(newPage, kCGPDFCropBox);
    
    CGPDFPageRetain(newPage);
    CGPDFPageRelease(page);
    page = newPage;
    
    if (!CGRectEqualToRect(currentPageRect, newPageRect)) {
        [tiledLayer setDelegate:nil];
        [backgroundLayer setDelegate:nil];
        [shadowLayer setDelegate:nil];
        [tiledLayer removeFromSuperlayer];
        [backgroundLayer removeFromSuperlayer];
        [shadowLayer removeFromSuperlayer];
        self.tiledLayerDelegate = nil;
        self.backgroundLayerDelegate = nil;
        self.shadowLayerDelegate = nil;
        
        [self configureLayers];
    } else {
        [[tiledLayer delegate] setPage:page];
        
        // Force the tiled layers to discard their tile caches
        [tiledLayer setContents:nil];
        [tiledLayer setNeedsDisplay];
        [shadowLayer setContents:nil];
        [shadowLayer setNeedsDisplay];
    }
}

@end


@implementation BlioPDFTiledLayerDelegate

@synthesize page, fitTransform;

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    CGContextConcatCTM(ctx, fitTransform);
    CGContextClipToRect(ctx, pageRect);
    CGContextDrawPDFPage(ctx, page);
}

- (void)setPage:(CGPDFPageRef)newPage {
    page = newPage;
    pageRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
}

@end

@implementation BlioPDFBackgroundLayerDelegate

@synthesize pageRect;

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillRect(ctx, pageRect);
}

@end

@implementation BlioPDFShadowLayerDelegate

@synthesize pageRect;

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, (kBlioLayoutShadow/2.0f)), kBlioLayoutShadow, [UIColor colorWithWhite:0.3f alpha:1.0f].CGColor);
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillRect(ctx, pageRect);
}

@end

@implementation BlioFastCATiledLayer
+ (CFTimeInterval)fadeDuration {
    return 0.0;
}
@end