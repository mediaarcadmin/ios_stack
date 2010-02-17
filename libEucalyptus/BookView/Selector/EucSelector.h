//
//  EucSelector.h
//  libEucalyptus
//
//  Created by James Montgomerie on 20/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "THEventCapturingWindow.h"

@class EucSelectorRange, THPair, EucMenuController;
@protocol EucSelectorDataSource, EucSelectorDelegate;

typedef enum EucSelectorTrackingStage {
    EucSelectorTrackingStageNone,
    EucSelectorTrackingStageFirstSelection,
    EucSelectorTrackingStageSelectedAndWaiting,
    EucSelectorTrackingStageChangingSelection,
} EucSelectorTrackingStage;

@interface EucSelector : NSObject <THEventCaptureObserver> {
    BOOL _shouldSniffTouches;
    BOOL _selectionDisabled;
    
    id<EucSelectorDataSource> _dataSource;
    id<EucSelectorDelegate> _delegate;
    
    CGImageRef _magnificationLoupeImage;
    
    UIView *_attachedView;
    
    NSMutableArray *_temporaryHighlightLayers;

    UITouch *_trackingTouch;
    BOOL _trackingTouchHasMoved;
    BOOL _tracking;
    EucSelectorTrackingStage _trackingStage;
    
    EucSelectorRange *_selectedRange;

    UIView *_viewWithSelection;
    UIImageView *_loupeView;
    
    NSMutableArray *_highlightLayers;
    THPair *_highlightEndLayers;
    THPair *_highlightKnobLayers;    
    
    CALayer *_draggingKnob;
    CGFloat _draggingKnobVerticalOffset;
    
    EucMenuController *_menuController;
    BOOL _shouldHideMenu;
    BOOL _menuShouldBeAvailable;
}

@property (nonatomic, assign) BOOL selectionDisabled;
@property (nonatomic, assign) BOOL shouldHideMenu; // This is intended to be used to temporarily hide a menu (i.e. while zooming).

@property (nonatomic, assign) id<EucSelectorDataSource> dataSource;
@property (nonatomic, assign) id<EucSelectorDelegate> delegate;
@property (nonatomic, retain) EucSelectorRange *selectedRange;

@property (nonatomic, assign, readonly, getter=isTracking) BOOL tracking;
@property (nonatomic, assign, readonly) EucSelectorTrackingStage trackingStage;

- (void)attachToView:(UIView *)view;
- (void)detatchFromView;

- (void)temporarilyHighlightElementWithIdentfier:(id)elementId inBlockWithIdentifier:(id)blockId animated:(BOOL)animated;
- (void)removeTemporaryHighlight;

// Can be called e.g. after a view is zoomed to redisplay the selection with
// handles sized correctly.
- (void)redisplaySelectedRange; 

// Controls whether the selector sniff touches for the view it's attached
// to.  
// Default = YES.  
// If set to NO, touch should be forwarded to the 
// bedin, moved, ended, cancelled etc. interfaces.
// Do not change this while the selector is attached to a view.
@property (nonatomic, assign) BOOL shouldSniffTouches;

- (void)touchesBegan:(NSSet *)touches;
- (void)touchesMoved:(NSSet *)touches;
- (void)touchesEnded:(NSSet *)touches;
- (void)touchesCancelled:(NSSet *)touches;

@end


@protocol EucSelectorDelegate <NSObject>

@optional
// An array of EucMenuItems.
- (NSArray *)menuItemsForEucSelector:(EucSelector *)selector;

@end


@protocol EucSelectorDataSource <NSObject>

@required
- (NSArray *)blockIdentifiersForEucSelector:(EucSelector *)selector;
- (CGRect)eucSelector:(EucSelector *)selector frameOfBlockWithIdentifier:(id)id;
- (NSArray *)eucSelector:(EucSelector *)selector identifiersForElementsOfBlockWithIdentifier:(id)id;
- (NSArray *)eucSelector:(EucSelector *)selector rectsForElementWithIdentifier:(id)elementId ofBlockWithIdentifier:(id)blockId;

@optional
// Data source can supply an image that will be used to replace the view while
// selection is taking place.  This is uesful if he view's layer would otherwise
// not respond to renderInContext: 'correctly' (for example, it's an OpenGL
// backed view.
- (UIImage *)viewSnapshotImageForEucSelector:(EucSelector *)selector;

@end