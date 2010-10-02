//
//  EucSelector.h
//  libEucalyptus
//
//  Created by James Montgomerie on 20/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "THEventCapturingWindow.h"
#import "EucSelectorKnob.h"

@class EucSelectorRange, THPair, EucMenuController, EucSelectorAccessibilityMask, THImageFactory;
@protocol EucSelectorDataSource, EucSelectorDelegate;

typedef enum EucSelectorTrackingStage {
    EucSelectorTrackingStageNone,
    EucSelectorTrackingStageFirstSelection,
    EucSelectorTrackingStageSelectedAndWaiting,
    EucSelectorTrackingStageChangingSelection,
} EucSelectorTrackingStage;

@interface EucSelector : NSObject <THEventCaptureObserver, EucSelectorKnobDelegate> {
    BOOL _shouldSniffTouches;
    BOOL _selectionDisabled;
    
    id<EucSelectorDataSource> _dataSource;
    id<EucSelectorDelegate> _delegate;
    
    UIView *_attachedView;
    CALayer *_attachedLayer;
    CALayer *_snapshotLayer;
     
    EucSelectorRange *_temporarilyHighlightedRange;
    NSMutableArray *_temporaryHighlightLayers;

    UITouch *_trackingTouch;
    BOOL _trackingTouchHasMoved;
    BOOL _tracking;
    EucSelectorTrackingStage _trackingStage;
    
    EucSelectorRange *_selectedRange;
    EucSelectorRange *_selectedRangeOriginalHighlightRange;
    BOOL _selectedRangeIsHighlight;
    UIColor *_selectionColor;
    
    NSString *_currentLoupeKind;
    CALayer *_loupeLayer;
    CALayer *_loupeContentsLayer;
    THImageFactory *_loupeContentsImageFactory;
    UIColor *_loupeBackgroundColor;
    
    NSMutableArray *_highlightLayers;
    THPair *_highlightEndLayers;
    THPair *_highlightKnobs;    
    
    UIView *_draggingKnob;
    CGFloat _draggingKnobVerticalOffset;
    
    EucMenuController *_menuController;
    BOOL _shouldHideMenu;
    BOOL _menuShouldBeAvailable;
    
    NSArray *_cachedBlockIdentifiers;
    CFMutableDictionaryRef _cachedBlockIdentifierToElements;
    CFMutableDictionaryRef _cachedBlockIdentifierToRects;
    CFMutableDictionaryRef _cachedBlockAndElementIdentifierToRects;
    NSArray *_cachedHighlightRanges;
    
    CGFloat _screenScaleFactor;
    
    EucSelectorAccessibilityMask *_accessibilityMask;
    BOOL _accessibilityAnnouncedSelecting;
}

@property (nonatomic, assign) BOOL selectionDisabled;
@property (nonatomic, assign) BOOL shouldHideMenu; // This is intended to be used to temporarily hide a menu (i.e. while zooming).

@property (nonatomic, assign) id<EucSelectorDataSource> dataSource;
@property (nonatomic, assign) id<EucSelectorDelegate> delegate;

@property (nonatomic, retain) EucSelectorRange *selectedRange;
@property (nonatomic, assign, readonly) BOOL selectedRangeIsHighlight;
@property (nonatomic, retain, readonly) EucSelectorRange *selectedRangeOriginalHighlightRange;

@property (nonatomic, retain) UIColor *loupeBackgroundColor;

@property (nonatomic, assign, readonly, getter=isTracking) BOOL tracking;
@property (nonatomic, assign, readonly) EucSelectorTrackingStage trackingStage;

@property (nonatomic, retain, readonly) UIView *attachedView;
@property (nonatomic, retain, readonly) CALayer *attachedLayer;

- (void)attachToView:(UIView *)view;
- (void)attachToLayer:(CALayer *)view;
- (void)detatch;

- (void)temporarilyHighlightSelectorRange:(EucSelectorRange *)range animated:(BOOL)animated;
- (void)temporarilyHighlightElementWithIdentfier:(id)elementId inBlockWithIdentifier:(id)blockId animated:(BOOL)animated;
- (void)removeTemporaryHighlight;

// Can be called in a menu callback to change the menu items rather than
// dismissing the menu.
- (void)changeActiveMenuItemsTo:(NSArray *)menuItems;

// Can be called e.g. after a view is zoomed to redisplay the selection with
// handles sized correctly.
- (void)redisplaySelectedRange; 

// Utility class method exposed for outside use.
+ (NSArray *)coalescedLineRectsForElementRects:(NSArray *)elementRects;

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

// Between willBegin/didEnd, the highlighter will highlight the range it's
// notifying the delagete of.  If the delegate is displaying its own highlight
// for the range usually, it should 'turn it off' during this time.

// Optionally return a UIColor to use for the selection highlight (nil = default blue color).
- (UIColor *)eucSelector:(EucSelector *)selector willBeginEditingHighlightWithRange:(EucSelectorRange *)selectedRange;
- (void)eucSelector:(EucSelector *)selector didEndEditingHighlightWithRange:(EucSelectorRange *)selectedRange movedToRange:(EucSelectorRange *)selectedRange;

@end


@protocol EucSelectorDataSource <NSObject>

@required
- (NSArray *)blockIdentifiersForEucSelector:(EucSelector *)selector;
- (CGRect)eucSelector:(EucSelector *)selector frameOfBlockWithIdentifier:(id)id;
- (NSArray *)eucSelector:(EucSelector *)selector identifiersForElementsOfBlockWithIdentifier:(id)id;
- (NSArray *)eucSelector:(EucSelector *)selector rectsForElementWithIdentifier:(id)elementId ofBlockWithIdentifier:(id)blockId;
- (NSString *)eucSelector:(EucSelector *)selector accessibilityLabelForElementWithIdentifier:(id)elementId ofBlockWithIdentifier:(id)blockId;

@optional
// Should return an array of EucSelectorRanges.
// These are used to tell if the user has tapped in an already-highlighted
// area.
- (NSArray *)highlightRangesForEucSelector:(EucSelector *)selector;

// Data source can supply an image that will be used to replace the view while
// selection is taking place.  This is uesful if he view's layer would otherwise
// not respond to renderInContext: 'correctly' (for example, it's an OpenGL
// backed view), or if rendering the view is too expensive to be performed
// quickly when rendering the magnified view in the loupe.
- (UIImage *)viewSnapshotImageForEucSelector:(EucSelector *)selector;

// Should be implemented if the selector is attached to a layer (will cause a 
// crash if not!).  Can optionally be implemented otherwise.
- (UIView *)viewForMenuForEucSelector:(EucSelector *)selector;

@end