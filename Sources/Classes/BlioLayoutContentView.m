//
//  BlioLayoutContentView.m
//  BlioApp
//
//  Created by matt on 03/03/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "BlioLayoutContentView.h"
#import "UIDevice+BlioAdditions.h"

@interface BlioLayoutForceCacheOperation : NSOperation {
    BlioLayoutTiledLayer *tiledLayer;
}

- (id)initWithTiledLayer:(BlioLayoutTiledLayer *)aTiledLayer;

@property (nonatomic, retain) BlioLayoutTiledLayer *tiledLayer;

@end

@interface BlioLayoutTiledLayer : CATiledLayer {
//@interface BlioLayoutTiledLayer : CALayer {
    NSInteger pageNumber;
    id <BlioLayoutRenderingDelegate> renderingDelegate;
    BOOL cached;
    id thumbLayer;
    BOOL isCancelled;
}

@property (nonatomic) NSInteger pageNumber;
@property (nonatomic, assign) id <BlioLayoutRenderingDelegate> renderingDelegate;
@property (nonatomic) BOOL cached;
@property (nonatomic, assign) id thumbLayer;
@property (nonatomic, assign) BOOL isCancelled;

@end

@interface BlioLayoutThumbLayer : CALayer {
    NSInteger pageNumber;
    id <BlioLayoutRenderingDelegate> renderingDelegate;
    CGLayerRef cacheLayer;
    BOOL isCancelled;
}

@property (nonatomic) NSInteger pageNumber;
@property (nonatomic, assign) id <BlioLayoutRenderingDelegate> renderingDelegate;
@property (nonatomic) CGLayerRef cacheLayer;
@property (nonatomic, assign) BOOL isCancelled;

@end

@interface BlioLayoutShadowLayer : CALayer {
    NSInteger pageNumber;
    id <BlioLayoutRenderingDelegate> renderingDelegate;
    BOOL isCancelled;
}

@property (nonatomic) NSInteger pageNumber;
@property (nonatomic, assign) id <BlioLayoutRenderingDelegate> renderingDelegate;
@property (nonatomic, assign) BOOL isCancelled;

@end

@interface BlioLayoutHighlightsLayer : CATiledLayer {
    NSInteger pageNumber;
    id <BlioLayoutRenderingDelegate> renderingDelegate;
    BlioBookmarkRange *excludedHighlight;
    BOOL isCancelled;
}

@property (nonatomic) NSInteger pageNumber;
@property (nonatomic, assign) id <BlioLayoutRenderingDelegate> renderingDelegate;
@property (nonatomic, retain) BlioBookmarkRange *excludedHighlight;
@property (nonatomic, assign) BOOL isCancelled;

@end

@interface BlioLayoutPageLayer()
@property (nonatomic, assign) BlioLayoutThumbLayer *thumbLayer;
- (void)layoutSublayersAfterBoundsChange;
@end

@implementation BlioLayoutContentView

@synthesize renderingDelegate, pageLayers;

- (void)dealloc {
    //NSLog(@"*************** dealloc called for contentView");
    [self abortRendering];
    [super dealloc];
}

- (void)abortRendering {
    //NSLog(@"*************** abort called for contentView");
    
    [self.pageLayers makeObjectsPerformSelector:@selector(abortRendering)];
    self.renderingDelegate = nil;
    self.pageLayers = nil;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
        self.pageLayers = [NSMutableSet setWithCapacity:kBlioLayoutMaxPages];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        maxTileSize = [[UIDevice currentDevice] blioDeviceMaximumTileSize];
    }
    return self;
}

- (CALayer *)addPage:(NSInteger)aPageNumber retainPages:(NSSet *)pages {
   // NSLog(@"Add page %d", aPageNumber);
    if (![self.renderingDelegate dataSourceContainsPage:aPageNumber]) {
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
            shadowLayer.renderingDelegate = self.renderingDelegate;
            shadowLayer.frame = self.bounds;
            shadowLayer.geometryFlipped = YES;
            shadowLayer.opaque = YES;
            [shadowLayer setNeedsDisplayOnBoundsChange:YES];
            [pageLayer addSublayer:shadowLayer];
            [pageLayer setShadowLayer:shadowLayer];
            
            BlioLayoutThumbLayer *thumbLayer = [BlioLayoutThumbLayer layer];
            thumbLayer.renderingDelegate = self.renderingDelegate;
            thumbLayer.frame = self.bounds;
            thumbLayer.geometryFlipped = YES;
            [thumbLayer setNeedsDisplayOnBoundsChange:YES];
            [pageLayer addSublayer:thumbLayer];
            [pageLayer setThumbLayer:thumbLayer];
            
            BlioLayoutTiledLayer *tiledLayer = [BlioLayoutTiledLayer layer];
            tiledLayer.renderingDelegate = self.renderingDelegate;
            tiledLayer.frame = self.bounds;
            tiledLayer.geometryFlipped = YES;
            //tiledLayer.levelsOfDetail = 2;
            //tiledLayer.levelsOfDetailBias = 2;
            tiledLayer.levelsOfDetail = 6;
            tiledLayer.levelsOfDetailBias = 5;
            //tiledLayer.tileSize = CGSizeMake(256, 256);
            tiledLayer.tileSize = CGSizeMake(maxTileSize, maxTileSize);
            //tiledLayer.tileSize = CGSizeMake(2048, 2048);
            tiledLayer.thumbLayer = (id)thumbLayer;
            [tiledLayer setNeedsDisplayOnBoundsChange:YES];
            [pageLayer addSublayer:tiledLayer];
            [pageLayer setTiledLayer:tiledLayer];
            
            BlioLayoutHighlightsLayer *highlightsLayer = [BlioLayoutHighlightsLayer layer];
            highlightsLayer.renderingDelegate = self.renderingDelegate;
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
    
    CGRect newFrame = self.bounds;
    //NSLog(@"Laying out contentView subviews after bounds changed to: %@", NSStringFromCGRect(newFrame));
    
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
    return NO;
}

@end

@implementation BlioLayoutPageLayer

@synthesize pageNumber, tiledLayer, thumbLayer, shadowLayer, highlightsLayer, cacheQueue;

- (void)dealloc {
    //NSLog(@"Dealloc BlioLayoutPageLayer for page %d", self.pageNumber);
    [self abortRendering];
    //NSLog(@"cancelPreviousPerformRequestsWithTarget during dealloc");
    
    self.tiledLayer = nil;
    self.thumbLayer = nil;
    self.shadowLayer = nil;
    self.highlightsLayer = nil;
    [super dealloc];
    //NSLog(@"Dealloc BlioLayoutPageLayer for page %d complete", self.pageNumber);
}

- (void)abortRendering {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(forceThumbCache) object:nil];
    [self.cacheQueue cancelAllOperations];
    [self.cacheQueue waitUntilAllOperationsAreFinished];
    self.cacheQueue = nil;

    isCancelled = YES;
    [self.tiledLayer setIsCancelled:YES];
    [self.thumbLayer setIsCancelled:YES];
    [self.shadowLayer setIsCancelled:YES];
    [self.highlightsLayer setIsCancelled:YES];
    
    [self removeFromSuperlayer];
}

- (void)layoutSublayersAfterBoundsChange {

    if (isCancelled) {
        return;
    }
    
    CGRect layerBounds = self.bounds;
    //NSLog(@"Laying out pageLayer sublayers at %@", NSStringFromCGRect(layerBounds));
    for (CALayer *subLayer in self.sublayers) {
        subLayer.frame = layerBounds;
    }
    
    //[self setNeedsDisplay];
    //[self.shadowLayer setNeedsDisplay];
    
    // NEW
    BlioLayoutTiledLayer *aTiledLayer = [BlioLayoutTiledLayer layer];
    aTiledLayer.renderingDelegate = self.tiledLayer.renderingDelegate;
    aTiledLayer.frame = self.tiledLayer.bounds;
    aTiledLayer.geometryFlipped = YES;
    aTiledLayer.levelsOfDetail = self.tiledLayer.levelsOfDetail;
    aTiledLayer.levelsOfDetailBias = self.tiledLayer.levelsOfDetailBias;
    aTiledLayer.tileSize = self.tiledLayer.tileSize;
    aTiledLayer.thumbLayer = (id)self.thumbLayer;
    aTiledLayer.pageNumber = self.tiledLayer.pageNumber;
    [aTiledLayer setNeedsDisplayOnBoundsChange:YES];
    [self insertSublayer:aTiledLayer below:self.highlightsLayer];    
    
    [self.tiledLayer removeFromSuperlayer];
    self.tiledLayer = aTiledLayer;
    
    // END
    //[self.tiledLayer setContents:nil];
    [self.tiledLayer setNeedsDisplay];
    
    // NEW
    BlioLayoutHighlightsLayer *aHighlightsLayer = [BlioLayoutHighlightsLayer layer];
    aHighlightsLayer.renderingDelegate = self.highlightsLayer.renderingDelegate;
    aHighlightsLayer.frame = self.highlightsLayer.bounds;
    aHighlightsLayer.levelsOfDetail = self.highlightsLayer.levelsOfDetail;
    aHighlightsLayer.tileSize = self.highlightsLayer.tileSize;
    [self addSublayer:aHighlightsLayer];
    
    [self.highlightsLayer removeFromSuperlayer];
    self.highlightsLayer = aHighlightsLayer;
    
    // END
    
    //[self.highlightsLayer setContents:nil];
    //NSLog(@"Laying out pageLayer sublayers done");
}

- (void)setPageNumber:(NSInteger)newPageNumber {
    if (isCancelled) {
        return;
    }
    
    //NSLog(@"set page number and cancel force");
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(forceThumbCache) object:nil];
    [self.cacheQueue cancelAllOperations];
    
    pageNumber = newPageNumber;
    
    // NEW
    //BlioLayoutThumbLayer *aThumbLayer = [BlioLayoutThumbLayer layer];
//    aThumbLayer.renderingDelegate = self.thumbLayer.renderingDelegate;
//    aThumbLayer.frame = self.thumbLayer.bounds;
//    aThumbLayer.geometryFlipped = YES;
//    [aThumbLayer setNeedsDisplayOnBoundsChange:YES];
//    [self insertSublayer:aThumbLayer below:self.thumbLayer];
//    
//    [self.thumbLayer removeFromSuperlayer];
//    self.thumbLayer = aThumbLayer;
    
    // END
    [self.thumbLayer setPageNumber:newPageNumber];
    [self.thumbLayer setNeedsDisplay];
    
    // NEW
    BlioLayoutTiledLayer *aTiledLayer = [BlioLayoutTiledLayer layer];
    aTiledLayer.renderingDelegate = self.tiledLayer.renderingDelegate;
    aTiledLayer.frame = self.tiledLayer.bounds;
    aTiledLayer.geometryFlipped = YES;
    aTiledLayer.levelsOfDetail = self.tiledLayer.levelsOfDetail;
    aTiledLayer.levelsOfDetailBias = self.tiledLayer.levelsOfDetailBias;
    aTiledLayer.tileSize = self.tiledLayer.tileSize;
    aTiledLayer.thumbLayer = (id)self.thumbLayer;
    [aTiledLayer setNeedsDisplayOnBoundsChange:YES];
    [self insertSublayer:aTiledLayer below:self.highlightsLayer];    
    
    [self.tiledLayer removeFromSuperlayer];
    self.tiledLayer = aTiledLayer;
    
    // END
    
    [self.tiledLayer setPageNumber:newPageNumber];
    [self.tiledLayer setNeedsDisplay];
    
    [self.shadowLayer setPageNumber:newPageNumber];
    [self.shadowLayer setNeedsDisplay];
    
    // To minimise load, Highlights are not fetched & rendered until the page becomes current
    
    // NEW
    BlioLayoutHighlightsLayer *aHighlightsLayer = [BlioLayoutHighlightsLayer layer];
    aHighlightsLayer.renderingDelegate = self.highlightsLayer.renderingDelegate;
    aHighlightsLayer.frame = self.highlightsLayer.bounds;
    aHighlightsLayer.levelsOfDetail = self.highlightsLayer.levelsOfDetail;
    aHighlightsLayer.tileSize = self.highlightsLayer.tileSize;
    [self addSublayer:aHighlightsLayer];
    
    [self.highlightsLayer removeFromSuperlayer];
    self.highlightsLayer = aHighlightsLayer;
    [self.highlightsLayer setPageNumber:newPageNumber];
    
    // END
}

- (void)setExcludedHighlight:(BlioBookmarkRange *)excludedHighlight {
    if (isCancelled) {
        return;
    }
    [self.highlightsLayer setExcludedHighlight:excludedHighlight];
}

- (void)refreshHighlights {
    if (isCancelled) {
        return;
    }
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey: kCATransactionDisableActions];
    //[self.highlightsLayer setContents:nil];
    [self.highlightsLayer setNeedsDisplay];
    [CATransaction commit];
}

- (void)forceThumbCacheAfterDelay:(NSTimeInterval)delay {
    if (isCancelled) {
        return;
    }
    //return;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(forceThumbCache) object:nil];
    //NSLog(@"forceThumbCacheAfterDelay: %f for page %d", delay, self.pageNumber);
    CGFloat cacheDelay = delay;
    [self performSelector:@selector(forceThumbCache) withObject:nil afterDelay:cacheDelay inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
}

- (void)forceThumbCache {
    if (isCancelled) {
        return;
    }
    //NSLog(@"forceThumbCache fired after delay for page %d", self.pageNumber);
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
    } //else {
//        NSLog(@"already cached");
//
//    }
}

#pragma mark -
#pragma mark Accessibility

- (BOOL)isAccessibilityElement {
    return NO;
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

//- (NSString *)accessibilityLabel {
//    return @"pageLayerLabel";
//}
//
//- (CGRect)accessibilityFrame {
//    CGRect pageRect = CGRectMake(100,100,100,100);
//    return pageRect;
//}

@end

@implementation BlioLayoutTiledLayer

@synthesize pageNumber, renderingDelegate, cached, thumbLayer, isCancelled;

- (void)dealloc {
    //NSLog(@"Tiled layer dealloc for page %d", self.pageNumber);
    self.isCancelled = YES;
    self.thumbLayer = nil;
    self.renderingDelegate = nil;
    [super dealloc];
}

- (void)cacheReady:(id)aCacheLayer {
    //NSLog(@"Cache ready for page %d", pageNumber);
    if (self.isCancelled) {
        return;
    }
    [self.thumbLayer setCacheLayer:(CGLayerRef)aCacheLayer];
    [self.thumbLayer setNeedsDisplay];
}

- (void)setPageNumber:(NSInteger)aPageNumber {
    if (self.isCancelled) {
        return;
    }
    self.contents = nil;
    self.cached = NO;
    pageNumber = aPageNumber;
}

- (void)drawInContext:(CGContextRef)ctx {
    
    //NSLog(@"Draw tiled layer for page %d with transform %@ and clipbounds %@ and layerbounds %@", self.pageNumber, NSStringFromCGAffineTransform(CGContextGetCTM(ctx)), NSStringFromCGRect(CGContextGetClipBoundingBox(ctx)), NSStringFromCGRect(self.frame));
    if (self.isCancelled) {
        return;
    }
    
    if (!self.renderingDelegate) {
        return;
    }
    
    if (!self.cached) {
        self.cached = YES;
        [self.renderingDelegate drawTiledLayer:self inContext:ctx forPage:self.pageNumber cacheReadyTarget:self cacheReadySelector:@selector(cacheReady:)];
    } else {
        if (self.isCancelled) {
            return;
        }
        [self.renderingDelegate drawTiledLayer:self inContext:ctx forPage:self.pageNumber cacheReadyTarget:nil cacheReadySelector:nil];
    }
    
    if (pageNumber == 1) {
        //NSLog(@"Finished rendering page 1 tile layer");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"blioCoverPageDidFinishRender" object:nil];
    }
    //NSLog(@"Draw tiled layer complete for page %d", self.pageNumber);
}

+ (CFTimeInterval)fadeDuration {
    return 0.0;
}

@end

@implementation BlioLayoutThumbLayer

@synthesize pageNumber, renderingDelegate, cacheLayer, isCancelled;

- (void)dealloc {
    self.isCancelled = YES;
    self.renderingDelegate = nil;
    if (nil != cacheLayer)
        CGLayerRelease(cacheLayer);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)setPageNumber:(NSInteger)aPageNumber {
    //NSLog(@"Updating layer from page %d to %d", pageNumber, aPageNumber);
    if (self.isCancelled) {
        return;
    }
    [self setCacheLayer:nil];
    self.contents = nil;
    pageNumber = aPageNumber;
}

- (void)setCacheLayer:(CGLayerRef)aNewLayer {
    if (self.isCancelled) {
        return;
    }
    CGLayerRetain(aNewLayer);
    CGLayerRelease(cacheLayer);
    cacheLayer = aNewLayer;
}

- (void)drawInContext:(CGContextRef)ctx {
    //if (nil != cacheLayer) {
    if (self.isCancelled) {
        return;
    }
    [self.renderingDelegate drawThumbLayer:self inContext:ctx forPage:self.pageNumber withCacheLayer:cacheLayer];  
    
    if (cacheLayer && pageNumber == 1) {
        //NSLog(@"Finished rendering page 1 thumb layer");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"blioCoverPageDidFinishRender" object:nil];
    }
    //}
}

@end

@implementation BlioLayoutShadowLayer

@synthesize pageNumber, renderingDelegate, isCancelled;

- (void)dealloc {
    self.isCancelled = YES;
    self.renderingDelegate = nil;
    [super dealloc];
}

- (void)setPageNumber:(NSInteger)aPageNumber {
    if (self.isCancelled) {
        return;
    }
    self.contents = nil;
    pageNumber = aPageNumber;
}

- (void)drawInContext:(CGContextRef)ctx {
    if (self.isCancelled) {
        return;
    }
    //NSLog(@"Draw shadow for page %d", self.pageNumber);
    [self.renderingDelegate drawShadowLayer:self inContext:ctx forPage:self.pageNumber];    
}

@end

@implementation BlioLayoutHighlightsLayer

@synthesize pageNumber, renderingDelegate, excludedHighlight, isCancelled;

- (void)dealloc {
    //NSLog(@"BlioLayoutHighlightsLayer dealloc for page %d", pageNumber);
    self.isCancelled = YES;
    self.renderingDelegate = nil;
    self.excludedHighlight = nil;
    [super dealloc];
}

- (void)setPageNumber:(NSInteger)aPageNumber {
    if (self.isCancelled) {
        return;
    }
    //self.contents = nil;
    pageNumber = aPageNumber;
}

- (void)drawInContext:(CGContextRef)ctx {
    if (self.isCancelled) {
        return;
    }
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey: kCATransactionDisableActions];
    //NSLog(@"Draw highlights for page %d", self.pageNumber);
    if (self.renderingDelegate != nil) {
        [self.renderingDelegate drawHighlightsLayer:self inContext:ctx forPage:self.pageNumber excluding:self.excludedHighlight];
    }
    [CATransaction commit];
}

+ (CFTimeInterval)fadeDuration {
    return 0.0;
}

@end

@implementation BlioLayoutForceCacheOperation

@synthesize tiledLayer;

- (id)initWithTiledLayer:(BlioLayoutTiledLayer *)aTiledLayer {
    if(aTiledLayer == nil) return nil;
    
    if((self = [super init])) {
        self.tiledLayer = aTiledLayer;
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
    if (self.tiledLayer != nil) {
        //NSLog(@"Force tile caching from operation");
        [self.tiledLayer renderInContext:bitmap];
    }
    
    // Clean up
    CGContextRelease(bitmap);
    CGColorSpaceRelease(colorSpace);
    
    [pool drain];
}

- (void)dealloc {
    self.tiledLayer = nil;
    [super dealloc];
}

@end
