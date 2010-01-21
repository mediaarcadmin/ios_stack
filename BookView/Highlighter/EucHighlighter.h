//
//  EucHighlighter.h
//  libEucalyptus
//
//  Created by James Montgomerie on 20/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EucHighlighterOverlayView;

@interface EucHighlighter : NSObject {
    EucHighlighterOverlayView *_overlayView;
}

- (BOOL)attachToView:(UIView *)view forTapAtPoint:(CGPoint)point;
- (void)detatchFromView;

- (void)temporarilyHighlightElementAtIndex:(NSInteger)elementIndex inBlockAtIndex:(NSInteger)blockIndex animated:(BOOL)animated;
- (void)clearTemporaryHighlights;

- (NSInteger)highlightElementsFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;
- (void)removeHighlight:(NSInteger)highlightId;

@end


@protocol EucHighlighterDelegate <NSObject>

- (NSArray *)menuTitlesForEucHighlighter:(EucHighlighter *)highlighter;
- (void)eucHighlighter:(EucHighlighter *)highlighter didSelectMenuItemAtIndex:(NSUInteger)index;

@end


@protocol EucHighlighterDataSource <NSObject>

- (NSUInteger)blockCountForEucHighlighter:(EucHighlighter *)highlighter;
- (CGRect)eucHighlighter:(EucHighlighter *)highlighter frameOfBlockAtIndex:(NSUInteger)index;
- (NSUInteger)eucHighlighter:(EucHighlighter *)highlighter elementCountForBlockAtIndex:(NSInteger)index;
- (NSArray *)rectsForElementsOfBlockAtIndex:(NSUInteger)index;

@end


@interface NSIndexPath (EucHighlighter)

+ (NSIndexPath *)indexPathForElement:(NSUInteger)element inBlock:(NSUInteger)block;

@property(nonatomic,readonly) NSUInteger block;
@property(nonatomic,readonly) NSUInteger element;

@end
