//
//  EucHighlighter.h
//  libEucalyptus
//
//  Created by James Montgomerie on 20/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "THEventCapturingWindow.h"

@class EucHighlighterRange, THPair;
@protocol EucHighlighterDataSource;

typedef enum EucHighlighterTrackingStage {
    EucHighlighterTrackingStageNone,
    EucHighlighterTrackingStageFirstSelection,
    EucHighlighterTrackingStageSelectedAndWaiting,
    EucHighlighterTrackingStageChangingSelection,
} EucHighlighterTrackingStage;
    

@interface EucHighlighter : NSObject <THEventCaptureObserver> {
    BOOL _shouldSniffTouches;
    BOOL _selectionDisabled;
    
    id<EucHighlighterDataSource> _dataSource;
    
    CGImageRef _magnificationLoupeImage;
    
    UIView *_attachedView;
    
    NSMutableArray *_temporaryHighlightLayers;

    UITouch *_trackingTouch;
    BOOL _trackingTouchHasMoved;
    BOOL _tracking;
    EucHighlighterTrackingStage _trackingStage;
    
    EucHighlighterRange *_selectedRange;

    UIView *_viewWithSelection;
    UIImageView *_loupeView;
    
    NSMutableArray *_highlightLayers;
    THPair *_highlightEndLayers;
    THPair *_highlightKnobLayers;    
    
    CALayer *_draggingKnob;
    CGFloat _draggingKnobVerticalOffset;
}

@property (nonatomic, assign) BOOL selectionDisabled;

@property (nonatomic, assign) id<EucHighlighterDataSource> dataSource;
@property (nonatomic, retain) EucHighlighterRange *selectedRange;

@property (nonatomic, assign, readonly, getter=isTracking) BOOL tracking;
@property (nonatomic, assign, readonly) EucHighlighterTrackingStage trackingStage;

- (void)attachToView:(UIView *)view;
- (void)detatchFromView;

- (void)temporarilyHighlightElementWithIdentfier:(id)elementId inBlockWithIdentifier:(id)blockId animated:(BOOL)animated;
- (void)removeTemporaryHighlight;

// Can be called e.g. after a view is zoomed to redisplay the selection with
// handles sized correctly.
- (void)redisplaySelectedRange; 

// Controls whether the highlighter sniff touches for the view it's attached
// to.  
// Default = YES.  
// If set to NO, touch should be forwarded to the 
// bedin, moved, ended, cancelled etc. interfaces.
// Do not change this while the highlighter is attached to a view.
@property (nonatomic, assign) BOOL shouldSniffTouches;

- (void)touchesBegan:(NSSet *)touches;
- (void)touchesMoved:(NSSet *)touches;
- (void)touchesEnded:(NSSet *)touches;
- (void)touchesCancelled:(NSSet *)touches;

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