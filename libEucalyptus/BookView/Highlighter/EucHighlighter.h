//
//  EucHighlighter.h
//  libEucalyptus
//
//  Created by James Montgomerie on 20/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "THEventCapturingWindow.h"

@class EucHighlighterOverlayView;
@protocol EucHighlighterDataSource;

@interface EucHighlighter : NSObject <THEventCaptureObserver> {
    id<EucHighlighterDataSource> _dataSource;
    
    UIView *_attachedView;
    UITouch *_trackingTouch;
    BOOL _tracking;
}

@property (nonatomic, assign) id<EucHighlighterDataSource> dataSource;
@property (nonatomic, assign, getter=isTracking) BOOL tracking;

- (void)attachToView:(UIView *)view;
- (void)detatchFromView;

- (void)temporarilyHighlightElementWithIdentfier:(id)elementId inBlockWithIdentifier:(id)blockId animated:(BOOL)animated;
- (void)clearTemporaryHighlights;

@end


@protocol EucHighlighterDelegate <NSObject>

- (NSArray *)menuTitlesForEucHighlighter:(EucHighlighter *)highlighter;
- (void)eucHighlighter:(EucHighlighter *)highlighter didSelectMenuItemAtIndex:(NSUInteger)index;

@end


@protocol EucHighlighterDataSource <NSObject>
/*
- (NSArray *)blockIdentifiersForEucHighlighter:(EucHighlighter *)highlighter;
- (CGRect)eucHighlighter:(EucHighlighter *)highlighter frameOfBlockWithIdentifier:(id)id;
- (NSArray *)identifiersForElementsOfBlockAtIndex:(NSUInteger)index;
- (NSArray *)rectsForElementsOfBlockAtIndex:(NSUInteger)index;
*/
@end