//
//  BlioLegacyLayoutContentView.h
//  BlioApp
//
//  Created by matt on 03/03/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioLegacyLayoutView.h"

@class BlioLegacyLayoutTiledLayer;
@class BlioLegacyLayoutThumbLayer;
@class BlioLegacyLayoutShadowLayer;
@class BlioLegacyLayoutHighlightsLayer;

@interface BlioLegacyLayoutPageLayer : CALayer {
    NSInteger pageNumber;
    BlioLegacyLayoutTiledLayer *tiledLayer;
    BlioLegacyLayoutThumbLayer *thumbLayer;
    BlioLegacyLayoutShadowLayer *shadowLayer;
    BlioLegacyLayoutHighlightsLayer *highlightsLayer;
    NSOperationQueue *cacheQueue;
    BOOL isCancelled;
}

@property (nonatomic) NSInteger pageNumber;
@property (nonatomic, assign) BlioLegacyLayoutTiledLayer *tiledLayer;
@property (nonatomic, assign) BlioLegacyLayoutShadowLayer *shadowLayer;
@property (nonatomic, assign) BlioLegacyLayoutHighlightsLayer *highlightsLayer;
@property (nonatomic, retain) NSOperationQueue *cacheQueue;

- (void)setExcludedHighlight:(BlioBookmarkRange *)excludedHighlight;
- (void)refreshHighlights;
- (void)forceThumbCacheAfterDelay:(NSTimeInterval)delay;
- (void)abortRendering;

@end

@interface BlioLegacyLayoutContentView : UIView {
    id <BlioLegacyLayoutRenderingDelegate> renderingDelegate;
    NSMutableSet *pageLayers;
    NSInteger maxTileSize;
}

@property (nonatomic, assign) id <BlioLegacyLayoutRenderingDelegate> renderingDelegate;
@property (nonatomic, retain) NSMutableSet *pageLayers;

- (BlioLegacyLayoutPageLayer *)addPage:(int)aPageNumber retainPages:(NSSet *)pages;
- (void)layoutSubviewsAfterBoundsChange;
- (void)abortRendering;

@end
