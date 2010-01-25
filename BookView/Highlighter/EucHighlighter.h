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
    CGImageRef _magnificationLoupeImage;
    
    UIView *_attachedView;
    UITouch *_trackingTouch;
    BOOL _tracking;
    
    UIView *_viewWithSelection;
    UIImageView *_loupeView;
    
    NSMutableArray *_highlightLayers;
}

@property (nonatomic, assign) id<EucHighlighterDataSource> dataSource;
@property (nonatomic, assign, getter=isTracking) BOOL tracking;

- (void)attachToView:(UIView *)view;
- (void)detatchFromView;

/*
- (void)temporarilyHighlightElementWithIdentfier:(id)elementId inBlockWithIdentifier:(id)blockId animated:(BOOL)animated;
- (void)clearTemporaryHighlights;
*/

@end


@protocol EucHighlighterDelegate <NSObject>

- (NSArray *)menuTitlesForEucHighlighter:(EucHighlighter *)highlighter;
- (void)eucHighlighter:(EucHighlighter *)highlighter didSelectMenuItemAtIndex:(NSUInteger)index;

@end


@protocol EucHighlighterDataSource <NSObject>

@required
- (NSArray *)blockIdentifiersForEucHighlighter:(EucHighlighter *)highlighter;
- (CGRect)eucHighlighter:(EucHighlighter *)highlighter frameOfBlockWithIdentifier:(id)id;
- (NSArray *)eucHighlighter:(EucHighlighter *)highlighter identifiersForElementsOfBlockWithIdentifier:(id)id;
- (NSArray *)eucHighlighter:(EucHighlighter *)highlighter rectsForElementWithIdentifier:(id)elementId ofBlockWithIdentifier:(id)blockId;

@optional
// Data source can supply an image that will be used to replace the view while
// selection is taking place.  This is uesful if he view's layer would otherwise
// not respond to renderInContext: 'correctly' (for example, it's an OpenGL
// backed view.
- (UIImage *)viewSnapshotImageForEucHighlighter:(EucHighlighter *)highlighter;

@end