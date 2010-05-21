//
//  BlioLayoutContentView.m
//  BlioApp
//
//  Created by matt on 03/03/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "BlioLayoutContentView.h"

@interface BlioLayoutForceCacheOperation : NSOperation {
    BlioLayoutTiledLayer *tiledLayer;
}

- (id)initWithTiledLayer:(BlioLayoutTiledLayer *)aTiledLayer;

@end

@interface BlioLayoutTiledLayer : CATiledLayer {
    NSInteger pageNumber;
    id <BlioLayoutDataSource> dataSource;
    BOOL cached;
    id thumbLayer;
}

@property (nonatomic) NSInteger pageNumber;
@property (nonatomic, assign) id <BlioLayoutDataSource> dataSource;
@property (nonatomic) BOOL cached;
@property (nonatomic, assign) id thumbLayer;

@end

@interface BlioLayoutThumbLayer : CALayer {
    NSInteger pageNumber;
    id <BlioLayoutDataSource> dataSource;
    CGLayerRef cacheLayer;
}

@property (nonatomic) NSInteger pageNumber;
@property (nonatomic, assign) id <BlioLayoutDataSource> dataSource;
@property (nonatomic) CGLayerRef cacheLayer;

@end

@interface BlioLayoutShadowLayer : CALayer {
    NSInteger pageNumber;
    id <BlioLayoutDataSource> dataSource;
}

@property (nonatomic) NSInteger pageNumber;
@property (nonatomic, assign) id <BlioLayoutDataSource> dataSource;

@end

@interface BlioLayoutHighlightsLayer : CATiledLayer {
    NSInteger pageNumber;
    id <BlioLayoutDataSource> dataSource;
    BlioBookmarkRange *excludedHighlight;
}

@property (nonatomic) NSInteger pageNumber;
@property (nonatomic, assign) id <BlioLayoutDataSource> dataSource;
@property (nonatomic, retain) BlioBookmarkRange *excludedHighlight;

@end

@interface BlioLayoutPageLayer()
@property (nonatomic, assign) BlioLayoutThumbLayer *thumbLayer;
- (void)layoutSublayersAfterBoundsChange;
@end

@implementation BlioLayoutContentView

@synthesize dataSource, pageLayers;

- (void)dealloc {
    self.dataSource = nil;
    self.pageLayers = nil;
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
        self.pageLayers = [NSMutableSet setWithCapacity:kBlioLayoutMaxPages];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundColor = [UIColor greenColor];
        self.layer.backgroundColor = [UIColor purpleColor].CGColor;
    }
    return self;
}

- (CALayer *)addPage:(NSInteger)aPageNumber retainPages:(NSSet *)pages {
   // NSLog(@"Add page %d", aPageNumber);
    if (![self.dataSource dataSourceContainsPage:aPageNumber]) {
        return nil;
    }
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey: kCATransactionDisableActions];

    NSInteger furthestPageIndex = 0;
    NSInteger furthestPageDifference = -1;
    NSInteger layerCacheCount = [self.pageLayers count];
    
    BlioLayoutPageLayer *pageLayer = nil;
    NSArray *cachedLayers = [self.pageLayers allObjects];
    
    // First, see if we have it cached and determine the furthest away page
    for(NSInteger i = 0; i < layerCacheCount; ++i) {
        BlioLayoutPageLayer *cachedLayer = [cachedLayers objectAtIndex:i];
        NSInteger cachedPageNumber = cachedLayer.pageNumber;
        if(cachedPageNumber == aPageNumber) {
            //NSLog(@"Cache hit for page %d", aPageNumber);
            pageLayer = cachedLayer;
            break;
        } else {
            NSInteger pageDifference = abs(aPageNumber - cachedPageNumber);
            if (pageDifference > furthestPageDifference) {
                if (![pages containsObject:cachedLayer]) {
                    furthestPageDifference = pageDifference;
                    furthestPageIndex = i;
                }
            }
        }
    }
    
    if(nil == pageLayer) {
         //NSLog(@"Add page no cached version");
        if (layerCacheCount < kBlioLayoutMaxPages) {
            //NSLog(@"Add new layer to cache");
            pageLayer = [BlioLayoutPageLayer layer];
            //[pageLayer setNeedsDisplayOnBoundsChange:YES];
            
            
            BlioLayoutShadowLayer *shadowLayer = [BlioLayoutShadowLayer layer];
            shadowLayer.dataSource = self.dataSource;
            shadowLayer.frame = self.bounds;
            shadowLayer.opaque = YES;
            [shadowLayer setNeedsDisplayOnBoundsChange:YES];
            [pageLayer addSublayer:shadowLayer];
            [pageLayer setShadowLayer:shadowLayer];
            
            BlioLayoutThumbLayer *thumbLayer = [BlioLayoutThumbLayer layer];
            thumbLayer.dataSource = self.dataSource;
            thumbLayer.frame = self.bounds;
            [thumbLayer setNeedsDisplayOnBoundsChange:YES];
            [pageLayer addSublayer:thumbLayer];
            [pageLayer setThumbLayer:thumbLayer];
            
            BlioLayoutTiledLayer *tiledLayer = [BlioLayoutTiledLayer layer];
            tiledLayer.dataSource = self.dataSource;
            tiledLayer.frame = self.bounds;
            tiledLayer.levelsOfDetail = 7;
            tiledLayer.levelsOfDetailBias = 5;
            tiledLayer.tileSize = CGSizeMake(2048, 2048);
            tiledLayer.thumbLayer = (id)thumbLayer;
            [tiledLayer setNeedsDisplayOnBoundsChange:YES];
            [pageLayer addSublayer:tiledLayer];
            [pageLayer setTiledLayer:tiledLayer];
            
            BlioLayoutHighlightsLayer *highlightsLayer = [BlioLayoutHighlightsLayer layer];
            highlightsLayer.dataSource = self.dataSource;
            highlightsLayer.frame = self.bounds;
            highlightsLayer.levelsOfDetail = 1;
            highlightsLayer.tileSize = CGSizeMake(1024, 1024);
            //[highlightsLayer setNeedsDisplayOnBoundsChange:YES];
            [pageLayer addSublayer:highlightsLayer];
            [pageLayer setHighlightsLayer:highlightsLayer];
            
            [self.pageLayers addObject:pageLayer];
            [self.layer addSublayer:pageLayer];
        } else {
            //NSLog(@"using the furthest page index %d", furthestPageIndex);
            pageLayer = [cachedLayers objectAtIndex:furthestPageIndex];
        }
        
        [pageLayer setPageNumber:aPageNumber];
        [pageLayer setNeedsDisplay];
    }
    
    CGRect newFrame = self.bounds;
    newFrame.origin.x = newFrame.size.width * (aPageNumber - 1);
    newFrame.origin.y = 0;
    
    [pageLayer setFrame:newFrame];

    // Adjust the zPosition to ensure this layer is in front of any previous layers at the same position
    // We use zPosition instead of reordering the sublayers array to avoid layoutSubviews being called on the view
    [pageLayer setZPosition:pageLayer.zPosition + [self.pageLayers count]]; 
    
    [CATransaction commit];
    
    if (nil == pageLayer) {
        NSLog(@"Warning: no pageLayer for page %d", aPageNumber);
    }
    return pageLayer;
}

- (void)layoutSubviewsAfterBoundsChange {
    //NSLog(@"Laying out contentView subviews");
    CGRect newFrame = self.bounds;
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey: kCATransactionDisableActions];
    
    for (BlioLayoutPageLayer *pageLayer in self.pageLayers) {
        newFrame.origin.x = newFrame.size.width * ([pageLayer pageNumber] - 1);
        [pageLayer setFrame:newFrame];
        [pageLayer layoutSublayersAfterBoundsChange];
    }
    [CATransaction commit];
    //NSLog(@"Laying out contentView subviews done");
}

- (BOOL)isAccessibilityElement {
    return YES;
}

- (NSString *)accessibilityLabel {
    return @"contentView";
}

#if 0
- (NSArray *)accessibleElements
{
    if ( _accessibleElements != nil )
    {
        return _accessibleElements;
    }
    _accessibleElements = [[NSMutableArray alloc] init];
    
    /* Create an accessibility element to represent the first contained element and initialize it as a component of MultiFacetedView. */
    
    UIAccessibilityElement *element = [[[UIAccessibilityElement alloc] initWithAccessibilityContainer:self] autorelease];
    //CGRect pageRect = self.currentPageLayer.bounds;
    
    CGRect cropRect;
    CGAffineTransform boundsTransform = [self boundsTransformForPage:self.currentPageLayer.pageNumber cropRect:&cropRect];
    CGRect pageRect = CGRectApplyAffineTransform(cropRect, boundsTransform);
    
    [element setAccessibilityFrame:pageRect];
    [element setAccessibilityLabel:[NSString stringWithFormat:@"Page %d", self.currentPageLayer.pageNumber]];
    
    /* Set attributes of the first contained element here. */
    
    [_accessibleElements addObject:element];
    
    return _accessibleElements;
}
#endif
/* The following methods are implementations of UIAccessibilityContainer protocol methods. */

- (NSInteger)accessibilityElementCount
{
    return [self.pageLayers count];
}

- (id)accessibilityElementAtIndex:(NSInteger)index
{
    UIAccessibilityElement *element = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
    //CGRect pageRect = self.currentPageLayer.bounds;
    
    [element setAccessibilityFrame:CGRectMake(10,20,30,40)];
    [element setAccessibilityLabel:[NSString stringWithFormat:@"Page %d", [[[self.pageLayers allObjects] objectAtIndex:index] pageNumber]]];
    [element setAccessibilityValue:[[NSNumber numberWithInt:index] stringValue]];
    return element;
    
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
    return [[element accessibilityValue] intValue];
}


@end

@implementation BlioLayoutPageLayer

@synthesize pageNumber, tiledLayer, thumbLayer, shadowLayer, highlightsLayer, cacheQueue;

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(forceThumbCache) object:nil];

    self.tiledLayer = nil;
    self.thumbLayer = nil;
    self.shadowLayer = nil;
    self.highlightsLayer = nil;
    [self.cacheQueue cancelAllOperations];
    [self.cacheQueue waitUntilAllOperationsAreFinished];
    self.cacheQueue = nil;
    [super dealloc];
}

- (void)layoutSublayersAfterBoundsChange {

    CGRect layerBounds = self.bounds;
    //NSLog(@"Laying out pageLayer sublayers at %@", NSStringFromCGRect(layerBounds));
    for (CALayer *subLayer in self.sublayers) {
        subLayer.frame = layerBounds;
    }
    
    //[self setNeedsDisplay];
    //[self.shadowLayer setNeedsDisplay];
    [self.tiledLayer setContents:nil];
    [self.tiledLayer setNeedsDisplay];
    
    [self.highlightsLayer setContents:nil];
    //NSLog(@"Laying out pageLayer sublayers done");
}

- (void)setPageNumber:(NSInteger)newPageNumber {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(forceThumbCache) object:nil];
    [self.cacheQueue cancelAllOperations];
    
    pageNumber = newPageNumber;
    [self.thumbLayer setPageNumber:newPageNumber];
    [self.thumbLayer setNeedsDisplay];
    
    [self.tiledLayer setPageNumber:newPageNumber];
    [self.tiledLayer setNeedsDisplay];
    
    [self.shadowLayer setPageNumber:newPageNumber];
    [self.shadowLayer setNeedsDisplay];
    
    // To minimise load, Highlights are not fetched & rendered until the page becomes current
    [self.highlightsLayer setPageNumber:newPageNumber];
}

- (void)setExcludedHighlight:(BlioBookmarkRange *)excludedHighlight {
    [self.highlightsLayer setExcludedHighlight:excludedHighlight];
}

- (void)refreshHighlights {
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey: kCATransactionDisableActions];
    //[self.highlightsLayer setContents:nil];
    [self.highlightsLayer setNeedsDisplay];
    [CATransaction commit];
}

- (void)forceThumbCacheAfterDelay:(NSTimeInterval)delay {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(forceThumbCache) object:nil];
    [self performSelector:@selector(forceThumbCache) withObject:nil afterDelay:delay];
}

- (void)forceThumbCache {
    if (!self.tiledLayer.cached) {
        [self.cacheQueue cancelAllOperations];
        
        if (nil == self.cacheQueue) {
            NSOperationQueue *aQueue = [[NSOperationQueue alloc] init];
            [aQueue setMaxConcurrentOperationCount:1];
            self.cacheQueue = aQueue;
            [aQueue release];
        }
        
        BlioLayoutForceCacheOperation *cacheOp = [[BlioLayoutForceCacheOperation alloc] initWithTiledLayer:self.tiledLayer];
        [self.cacheQueue addOperation:cacheOp];
        [cacheOp release];
    }
}

#pragma mark -
#pragma mark Accessibility

- (BOOL)isAccessibilityElement {
    return YES;
}

//- (NSInteger)accessibilityElementCount
//{
//    return 1;
//}

//- (NSInteger)indexOfAccessibilityElement:(id)element
//{
//    return 0;
//}
//
//- (id)accessibilityElementAtIndex:(NSInteger)index
//{
//    UIAccessibilityElement *element = [[[UIAccessibilityElement alloc] initWithAccessibilityContainer:self] autorelease];
//    CGRect pageRect = [thumbLayer frame];
//    [element setAccessibilityFrame:pageRect];
//    [element setAccessibilityLabel:[NSString stringWithFormat:@"Page %d", self.pageNumber]];
//    return element;
//}

- (NSString *)accessibilityLabel {
    return @"pageLayerLabel";
}

- (CGRect)accessibilityFrame {
    CGRect pageRect = CGRectMake(100,100,100,100);
    return pageRect;
}

@end

@implementation BlioLayoutTiledLayer

@synthesize pageNumber, dataSource, cached, thumbLayer;

- (void)dealloc {
    self.thumbLayer = nil;
    self.dataSource = nil;
    [super dealloc];
}

- (void)cacheReady:(id)aCacheLayer {
    //NSLog(@"Cache ready for page %d", pageNumber);
    [self.thumbLayer setCacheLayer:(CGLayerRef)aCacheLayer];
    [self.thumbLayer setNeedsDisplay];
}

- (void)setPageNumber:(NSInteger)aPageNumber {
    self.contents = nil;
    self.cached = NO;
    pageNumber = aPageNumber;
}

- (void)drawInContext:(CGContextRef)ctx {
    //NSLog(@"Draw tiled layer for page %d with transform %@", self.pageNumber, NSStringFromCGAffineTransform(CGContextGetCTM(ctx)));
    
    if (!self.cached) {
        self.cached = YES;
        [self.dataSource drawTiledLayer:self inContext:ctx forPage:self.pageNumber cacheReadyTarget:self cacheReadySelector:@selector(cacheReady:)];
    } else {
        [self.dataSource drawTiledLayer:self inContext:ctx forPage:self.pageNumber cacheReadyTarget:nil cacheReadySelector:nil];
    }
    
    if (pageNumber == 1) 
        [[NSNotificationCenter defaultCenter] postNotificationName:@"blioCoverPageDidFinishRender" object:nil];

}

+ (CFTimeInterval)fadeDuration {
    return 0.0;
}

@end

@implementation BlioLayoutThumbLayer

@synthesize pageNumber, dataSource, cacheLayer;

- (void)dealloc {
    self.dataSource = nil;
    if (nil != cacheLayer)
        CGLayerRelease(cacheLayer);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)setPageNumber:(NSInteger)aPageNumber {
    //NSLog(@"Updating layer from page %d to %d", pageNumber, aPageNumber);
    [self setCacheLayer:nil];
    self.contents = nil;
    pageNumber = aPageNumber;
}

- (void)setCacheLayer:(CGLayerRef)aNewLayer {
    CGLayerRetain(aNewLayer);
    CGLayerRelease(cacheLayer);
    cacheLayer = aNewLayer;
}

- (void)updateContents:(NSNotification *)notification {
    if ([[notification object] integerValue] == self.pageNumber) {
        //NSLog(@"updateContents notification received on page %d for page %@", self.pageNumber, [notification object]);
        if (nil == self.contents) {
            NSDictionary *thumbDictionary = [notification userInfo];
            if (nil != thumbDictionary) {
                CGImageRef thumbImage = (CGImageRef)[thumbDictionary valueForKey:@"thumbImage"];
                NSNumber *thumbPage = [thumbDictionary valueForKey:@"pageNumber"];
                
                if (thumbImage && thumbPage) {
                    if ([thumbPage integerValue] == self.pageNumber) {
                        
                        self.contents = (id)thumbImage;
                        [self setNeedsDisplay];
                        NSLog(@"Set thumbLayer contents for page %d", self.pageNumber);
                    }
                }
            }
        }
    }
}

- (void)drawInContext:(CGContextRef)ctx {
    //CGRect ctxBounds = CGContextGetClipBoundingBox(ctx);
//    CGContextClearRect(ctx, ctxBounds);
    
//    CGAffineTransform boundsTransform;
//    CGRect insetBounds = UIEdgeInsetsInsetRect(ctxBounds, UIEdgeInsetsMake(kBlioLayoutShadow, kBlioLayoutShadow, kBlioLayoutShadow, kBlioLayoutShadow));
//    if (layerBounds.size.width < layerBounds.size.height)
//        ctxBounds = transformRectToFitRect(cropRect, insetBounds);
//    else
//        boundsTransform = transformRectToFillRect(cropRect, insetBounds);
//    cropRect = CGRectApplyAffineTransform(cropRect, boundsTransform);
    
    //NSLog(@"Drawing thumb in %@ %@", NSStringFromCGRect(ctxBounds), NSStringFromCGRect(self.bounds));
    if (nil != cacheLayer) {
        [self.dataSource drawThumbLayer:self inContext:ctx forPage:self.pageNumber withCacheLayer:cacheLayer];  
        //CGContextDrawLayerInRect(ctx, ctxBounds, cacheLayer);
    }
}

@end

@implementation BlioLayoutShadowLayer

@synthesize pageNumber, dataSource;

- (void)dealloc {
    self.dataSource = nil;
    [super dealloc];
}

- (void)setPageNumber:(NSInteger)aPageNumber {
    self.contents = nil;
    pageNumber = aPageNumber;
}

- (void)drawInContext:(CGContextRef)ctx {
    //NSLog(@"Draw shadow for page %d", self.pageNumber);
    [self.dataSource drawShadowLayer:self inContext:ctx forPage:self.pageNumber];    
}

@end

@implementation BlioLayoutHighlightsLayer

@synthesize pageNumber, dataSource, excludedHighlight;

- (void)dealloc {
    self.dataSource = nil;
    self.excludedHighlight = nil;
    [super dealloc];
}

- (void)setPageNumber:(NSInteger)aPageNumber {
    self.contents = nil;
    pageNumber = aPageNumber;
}

- (void)drawInContext:(CGContextRef)ctx {
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey: kCATransactionDisableActions];
    //NSLog(@"Draw highlights for page %d", self.pageNumber);
    [self.dataSource drawHighlightsLayer:self inContext:ctx forPage:self.pageNumber excluding:self.excludedHighlight];
    [CATransaction commit];
}

+ (CFTimeInterval)fadeDuration {
    return 0.0;
}

@end

@implementation BlioLayoutForceCacheOperation

- (id)initWithTiledLayer:(BlioLayoutTiledLayer *)aTiledLayer {
    if(aTiledLayer == nil) return nil;
    
    if((self = [super init])) {
        tiledLayer = [aTiledLayer retain];
    }
    
    return self;
}

- (void)main {
    if ([self isCancelled]) return;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                1,
                                                1,
                                                8,
                                                0,
                                                colorSpace,
                                                kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(bitmap, kCGInterpolationNone);
    
    if ([self isCancelled]) { 
        CGContextRelease(bitmap);
        CGColorSpaceRelease(colorSpace);
        [pool drain];
        return;
    }
    
    // Draw into the context; this force the caching
    if (tiledLayer)
        [tiledLayer renderInContext:bitmap];
    
    // Clean up
    CGContextRelease(bitmap);
    CGColorSpaceRelease(colorSpace);
    
    [pool drain];
}

- (void)dealloc {
    [tiledLayer release];
    [super dealloc];
}

@end
