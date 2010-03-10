//
//  BlioLayoutContentView.m
//  BlioApp
//
//  Created by matt on 03/03/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "BlioLayoutContentView.h"

@interface BlioLayoutTiledLayer : CATiledLayer {
    NSInteger pageNumber;
    id <BlioLayoutDataSource> dataSource;
}

@property (nonatomic) NSInteger pageNumber;
@property (nonatomic, assign) id <BlioLayoutDataSource> dataSource;

@end

@interface BlioLayoutThumbLayer : CALayer {
    NSInteger pageNumber;
    id <BlioLayoutDataSource> dataSource;
}

@property (nonatomic) NSInteger pageNumber;
@property (nonatomic, assign) id <BlioLayoutDataSource> dataSource;

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
            
            BlioLayoutShadowLayer *shadowLayer = [BlioLayoutShadowLayer layer];
            shadowLayer.dataSource = self.dataSource;
            shadowLayer.pageNumber = aPageNumber;
            shadowLayer.frame = self.bounds;
            shadowLayer.opaque = YES;
            [pageLayer addSublayer:shadowLayer];
            [pageLayer setShadowLayer:shadowLayer];
            
            BlioLayoutThumbLayer *thumbLayer = [BlioLayoutThumbLayer layer];
            CGImageRef thumbImage = [self.dataSource createThumbImageForPage:aPageNumber];
            if (thumbImage) {
                [thumbLayer setContents:(id)thumbImage];
                CGImageRelease(thumbImage);
            }
            thumbLayer.dataSource = self.dataSource;
//            thumbLayer.pageNumber = aPageNumber;
            thumbLayer.frame = self.bounds;
//            thumbLayer.levelsOfDetail = 1;
//            thumbLayer.tileSize = CGSizeMake(1024, 1024);
            [pageLayer addSublayer:thumbLayer];
            [pageLayer setThumbLayer:thumbLayer];
            
            BlioLayoutTiledLayer *tiledLayer = [BlioLayoutTiledLayer layer];
            tiledLayer.dataSource = self.dataSource;
            tiledLayer.pageNumber = aPageNumber;
            tiledLayer.frame = self.bounds;
            tiledLayer.levelsOfDetail = 7;
            tiledLayer.levelsOfDetailBias = 5;
            tiledLayer.tileSize = CGSizeMake(2048, 2048);
            [pageLayer addSublayer:tiledLayer];
            [pageLayer setTiledLayer:tiledLayer];
            
            BlioLayoutHighlightsLayer *highlightsLayer = [BlioLayoutHighlightsLayer layer];
            highlightsLayer.dataSource = self.dataSource;
            highlightsLayer.pageNumber = aPageNumber;
            highlightsLayer.frame = self.bounds;
            highlightsLayer.levelsOfDetail = 1;
            highlightsLayer.tileSize = CGSizeMake(1024, 1024);
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
    
    [CATransaction commit];
    
    if (nil == pageLayer) {
        NSLog(@"Warning: no pageLayer for page %d", aPageNumber);
    }
    return pageLayer;
}

@end

@implementation BlioLayoutPageLayer

@synthesize pageNumber, tiledLayer, thumbLayer, shadowLayer, highlightsLayer;

- (void)dealloc {
    self.tiledLayer = nil;
    self.thumbLayer = nil;
    self.shadowLayer = nil;
    self.highlightsLayer = nil;
    [super dealloc];
}

- (void)setPageNumber:(NSInteger)newPageNumber {
    pageNumber = newPageNumber;
    [self.tiledLayer setPageNumber:newPageNumber];
    [self.tiledLayer setContents:nil];
    [self.tiledLayer setNeedsDisplay];
    
    [self.shadowLayer setPageNumber:newPageNumber];
    [self.shadowLayer setNeedsDisplay];
    
//    [self.thumbLayer setPageNumber:newPageNumber];
//    [self.thumbLayer setContents:nil];
//    [self.thumbLayer setNeedsDisplay];
    CGImageRef thumbImage = [self.thumbLayer.dataSource createThumbImageForPage:newPageNumber];
    if (thumbImage) {
        [self.thumbLayer setContents:(id)thumbImage];
        CGImageRelease(thumbImage);
    } else {
        [self.thumbLayer setContents:nil];
    }
    
    [self.highlightsLayer setPageNumber:newPageNumber];
    [self.highlightsLayer setContents:nil];
    [self.highlightsLayer setNeedsDisplay];
}

- (void)setExcludedHighlight:(BlioBookmarkRange *)excludedHighlight {
    [self.highlightsLayer setExcludedHighlight:excludedHighlight];
}

- (void)refreshHighlights {
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey: kCATransactionDisableActions];
    [self.highlightsLayer setContents:nil];
    [self.highlightsLayer setNeedsDisplay];
    [CATransaction commit];
}

@end

@implementation BlioLayoutTiledLayer

@synthesize pageNumber, dataSource;

- (void)drawInContext:(CGContextRef)ctx {
    //NSLog(@"Draw tiled layer for page %d", self.pageNumber);

    [self.dataSource drawTiledLayer:self inContext:ctx forPage:self.pageNumber];
    
    if (pageNumber == 1) 
        [[NSNotificationCenter defaultCenter] postNotificationName:@"blioCoverPageDidFinishRender" object:nil];

}

+ (CFTimeInterval)fadeDuration {
    return 0.0;
}

@end

@implementation BlioLayoutThumbLayer

@synthesize pageNumber, dataSource;

//- (void)drawInContext:(CGContextRef)ctx {
//    [self.dataSource drawThumbLayer:self inContext:ctx forPage:self.pageNumber];    
//}

@end

@implementation BlioLayoutShadowLayer

@synthesize pageNumber, dataSource;

- (void)drawInContext:(CGContextRef)ctx {
    //NSLog(@"Draw shadow for page %d", self.pageNumber);
    [self.dataSource drawShadowLayer:self inContext:ctx forPage:self.pageNumber];    
}

@end

@implementation BlioLayoutHighlightsLayer

@synthesize pageNumber, dataSource, excludedHighlight;

- (void)dealloc {
    self.excludedHighlight = nil;
    [super dealloc];
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


