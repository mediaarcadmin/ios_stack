//
//  BlioLayoutContentView.h
//  BlioApp
//
//  Created by matt on 03/03/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioLayoutView.h"

@class BlioLayoutTiledLayer;
@class BlioLayoutThumbLayer;
@class BlioLayoutShadowLayer;
@class BlioLayoutHighlightsLayer;

@interface BlioLayoutPageLayer : CALayer {
    NSInteger pageNumber;
    BlioLayoutTiledLayer *tiledLayer;
    BlioLayoutThumbLayer *thumbLayer;
    BlioLayoutShadowLayer *shadowLayer;
    BlioLayoutHighlightsLayer *highlightsLayer;
    NSOperationQueue *cacheQueue;
}

@property (nonatomic) NSInteger pageNumber;
@property (nonatomic, assign) BlioLayoutTiledLayer *tiledLayer;
@property (nonatomic, assign) BlioLayoutShadowLayer *shadowLayer;
@property (nonatomic, assign) BlioLayoutHighlightsLayer *highlightsLayer;
@property (nonatomic, retain) NSOperationQueue *cacheQueue;

- (void)setExcludedHighlight:(BlioBookmarkRange *)excludedHighlight;
- (void)refreshHighlights;
- (void)forceThumbCacheAfterDelay:(NSTimeInterval)delay;

@end

@interface BlioLayoutContentView : UIView {
    id <BlioLayoutRenderingDelegate> renderingDelegate;
    NSMutableSet *pageLayers;
    NSInteger maxTileSize;
}

@property (nonatomic, assign) id <BlioLayoutRenderingDelegate> renderingDelegate;
@property (nonatomic, retain) NSMutableSet *pageLayers;

- (BlioLayoutPageLayer *)addPage:(int)aPageNumber retainPages:(NSSet *)pages;
- (void)layoutSubviewsAfterBoundsChange;
- (void)abortRendering;

@end
