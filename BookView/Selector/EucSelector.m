//
//  EucSelector.m
//  libEucalyptus
//
//  Created by James Montgomerie on 20/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "EucSelector.h"
#import "EucSelectorRange.h"
#import "EucMenuController.h"
#import "EucMenuItem.h"

#import "THGeometryUtils.h"
#import "THEventCapturingWindow.h"
#import "THCALayerAdditions.h"
#import "THUIViewAdditions.h"
#import "THPair.h"
#import "THImageFactory.h"
#import "THLog.h"

static const CGFloat sLoupePopUpDuration = 0.05f;
static const CGFloat sLoupePopDownDuration = 0.1f;

@interface EucSelector ()

@property (nonatomic, retain) UIView *attachedView;
@property (nonatomic, retain) CALayer *attachedLayer;
@property (nonatomic, retain) CALayer *snapshotLayer;

@property (nonatomic, retain) THPair *temporaryHighlightedElement;
@property (nonatomic, retain) NSMutableArray *temporaryHighlightLayers;

@property (nonatomic, assign) BOOL selectedRangeIsHighlight;
@property (nonatomic, retain) EucSelectorRange *selectedRangeOriginalHighlightRange;

@property (nonatomic, assign) UITouch *trackingTouch;
@property (nonatomic, assign) BOOL trackingTouchHasMoved;
@property (nonatomic, assign, getter=isTracking) BOOL tracking;
@property (nonatomic, assign) EucSelectorTrackingStage trackingStage;

@property (nonatomic, retain) UIColor *selectionColor;

@property (nonatomic, retain) NSString *currentLoupeKind;
@property (nonatomic, retain) CALayer *loupeLayer;
@property (nonatomic, retain) CALayer *loupeContentsLayer;
@property (nonatomic, retain) THImageFactory *loupeContentsImageFactory;

@property (nonatomic, retain) NSMutableArray *highlightLayers;
@property (nonatomic, retain) THPair *highlightEndLayers;
@property (nonatomic, retain) THPair *highlightKnobLayers;

@property (nonatomic, retain) CALayer *draggingKnob;
@property (nonatomic, assign) CGFloat draggingKnobVerticalOffset;

@property (nonatomic, retain) EucMenuController *menuController;
@property (nonatomic, assign) BOOL menuShouldBeAvailable;

- (CGImageRef)_cgImageNamed:(NSString *)name;

- (void)_trackTouch:(UITouch *)touch;

// Cache's the data sources responses during selection.
- (void)_clearSelectionCaches;
- (NSArray *)_blockIdentifiers;
- (NSArray *)_identifiersForElementsOfBlockWithIdentifier:(id)blockId;
- (NSArray *)_highlightRanges;

@end

@implementation EucSelector

@synthesize shouldSniffTouches = _shouldSniffTouches;
@synthesize selectionDisabled = _selectionDisabled;

@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;

@synthesize attachedView = _attachedView;
@synthesize attachedLayer = _attachedLayer;
@synthesize snapshotLayer = _snapshotLayer;

@synthesize selectedRange = _selectedRange;

@synthesize temporaryHighlightedElement = _temporaryHighlightedElement;
@synthesize temporaryHighlightLayers = _temporaryHighlightLayers;

@synthesize selectedRangeIsHighlight = _selectedRangeIsHighlight;
@synthesize selectedRangeOriginalHighlightRange = _selectedRangeOriginalHighlightRange;

@synthesize trackingTouch = _trackingTouch;
@synthesize trackingTouchHasMoved = _trackingTouchHasMoved;
@synthesize tracking = _tracking;
@synthesize trackingStage = _trackingStage;

@synthesize selectionColor = _selectionColor;

@synthesize currentLoupeKind = _currentLoupeKind;
@synthesize loupeLayer = _loupeLayer;
@synthesize loupeContentsLayer = _loupeContentsLayer;
@synthesize loupeContentsImageFactory = _loupeContentsImageFactory;

@synthesize loupeBackgroundColor = _loupeBackgroundColor;

@synthesize highlightLayers = _highlightLayers;
@synthesize highlightEndLayers = _highlightEndLayers;
@synthesize highlightKnobLayers = _highlightKnobLayers;

@synthesize draggingKnob = _draggingKnob;
@synthesize draggingKnobVerticalOffset = _draggingKnobVerticalOffset;

@synthesize menuController = _menuController;
@synthesize shouldHideMenu = _shouldHideMenu;
@synthesize menuShouldBeAvailable = _menuShouldBeAvailable;

- (id)init 
{
    if((self = [super init])) {
        _shouldSniffTouches = YES;
    }
    return self;
}

- (void)dealloc
{
    self.selectedRange = nil;
    
    if(self.temporaryHighlightLayers) {
        THWarn(@"Highlighter released with temporary highlight displayed.");
        [self removeTemporaryHighlight];
    }    
    if(self.attachedLayer) {
        THWarn(@"Highlighter released while still attached to view.");
        [self detatch];
    }
    
    [_highlightEndLayers release];
    [_highlightKnobLayers release];
    
    [super dealloc];
}

- (void)attachToLayer:(CALayer *)layer
{
    if(self.attachedLayer) {
        [self detatch];
    }
    self.attachedLayer = layer;
}

- (void)attachToView:(UIView *)view
{
    [self attachToLayer:view.layer];
    if(self.shouldSniffTouches) {
        for(THEventCapturingWindow *window in [[UIApplication sharedApplication] windows]) {
            if([window isKindOfClass:[THEventCapturingWindow class]]) {
                [window addTouchObserver:self forView:view];
            }
        }
    }
    self.attachedView = view;
}

- (void)detatch
{
    self.selectedRange = nil;
    if(self.temporaryHighlightLayers) {
        [self removeTemporaryHighlight];
    }        
    self.menuShouldBeAvailable = NO;
    [self.menuController setMenuVisible:NO animated:NO];
    self.menuController = nil;
    UIView *attachedView = self.attachedView;
    for(THEventCapturingWindow *window in [[UIApplication sharedApplication] windows]) {
        if([window isKindOfClass:[THEventCapturingWindow class]]) {
            [window removeTouchObserver:self forView:attachedView];
        }
    }
    self.attachedView = nil;
    self.attachedLayer = nil;
}

#pragma mark -
#pragma mark CAAnimation Delegate Methods

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{   
    NSString *name = [anim valueForKey:@"THName"];
    if(name) {
        if([name isEqualToString:@"EucSelectorLoupePopDown"] || [name isEqualToString:@"EucSelectorEndOfLineHighlight"]) {
            [[anim valueForKey:@"THLayer"] removeFromSuperlayer];
        }
    }
}

#pragma mark -
#pragma mark Temporary Highlights

- (void)temporarilyHighlightElementWithIdentfier:(id)elementId inBlockWithIdentifier:(id)blockId animated:(BOOL)animated;
{    
    THPair *currentTemporaryHighlightedElement = self.temporaryHighlightedElement;
    THPair *newTemporaryHighlightedElement = [[THPair alloc] initWithFirst:blockId second:elementId];
    if(!currentTemporaryHighlightedElement || ![currentTemporaryHighlightedElement isEqual:newTemporaryHighlightedElement]) {
        // Don't use the caches in this method, they're only valid during a selection!
        NSArray *rects = [self.dataSource eucSelector:self
                           rectsForElementWithIdentifier:elementId
                                   ofBlockWithIdentifier:blockId];
        
        NSMutableArray *temporaryHighlightLayers = self.temporaryHighlightLayers;
        NSMutableArray *newTemporaryHighlightLayers = [[NSMutableArray alloc] initWithCapacity:2];
        
        CALayer *attachedLayer = self.attachedLayer;
        
        for(NSValue *rectValue in rects) {
            CGRect rect = [rectValue CGRectValue];
            
            CGPoint newCenter = CGPointMake(rect.origin.x + (rect.size.width / 2.0f), rect.origin.y + (rect.size.height / 2.0f));
            CALayer *layer = nil;
            if(temporaryHighlightLayers.count) {
                CGFloat bestDistance = CGFLOAT_MAX;
                for(CALayer *prospectiveLayer in temporaryHighlightLayers) {
                    CGPoint prospectiveCenter = prospectiveLayer.position;
                    if(prospectiveCenter.x < newCenter.x) {  // If the prospective layer is to the let of the desired location
                        CGRect prospectiveRect = prospectiveLayer.frame;
                        if(!(CGRectGetMinY(prospectiveRect) > CGRectGetMaxY(rect) ||
                            CGRectGetMinY(rect) > CGRectGetMaxY(prospectiveRect))) { // And it vertically overlaps.
                            CGFloat thisDistance = CGPointDistance(prospectiveCenter, newCenter);
                            if(thisDistance < bestDistance) {
                                bestDistance = thisDistance;
                                layer = [prospectiveLayer retain];
                            }
                        }
                    }
                }
            } 
            rect.size.width += 4;
            rect.size.height += 4;
            
            if(layer) {
                [temporaryHighlightLayers removeObject:layer];
            } else {                 
                layer = [[CALayer alloc] init];
                layer.cornerRadius = 4;
                layer.backgroundColor = [[[UIColor blueColor] colorWithAlphaComponent:0.25f] CGColor];
                layer.position = CGPointMake(newCenter.x - rect.size.width / 2.0f + 1.0f, newCenter.y);
                layer.bounds = CGRectMake(0, 0, 1, rect.size.height);
                [attachedLayer addSublayer:layer];              
            }
            
            CGRect newBounds = CGRectMake(0, 0, rect.size.width, rect.size.height);
            
            CABasicAnimation *move = [CABasicAnimation animation];
            move.keyPath = @"position";
            move.fromValue = [NSValue valueWithCGPoint:layer.position];
            move.toValue = [NSValue valueWithCGPoint:newCenter];
            CABasicAnimation *shape = [CABasicAnimation animation];
            shape.keyPath = @"bounds";
            shape.fromValue = [NSValue valueWithCGRect:layer.bounds];
            shape.toValue = [NSValue valueWithCGRect:newBounds];
            
            CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
            animationGroup.animations = [NSArray arrayWithObjects:move, shape, nil];
            animationGroup.duration = 0.2f;
            
            [layer addAnimation:animationGroup forKey:nil];
            
            layer.position = newCenter;
            layer.bounds = newBounds;
            
            [newTemporaryHighlightLayers addObject:layer];
            [layer release];
        }
        for(CALayer *layer in temporaryHighlightLayers) {
            CGRect frame = layer.frame;
            CGPoint newCenter = CGPointMake(frame.origin.x + frame.size.width - 1.0f, 
                                            frame.origin.y + frame.size.height / 2.0f);
            CGRect newBounds = CGRectMake(0, 0, 1, frame.size.height);
            
            CABasicAnimation *move = [CABasicAnimation animation];
            move.keyPath = @"position";
            move.fromValue = [NSValue valueWithCGPoint:layer.position];
            move.toValue = [NSValue valueWithCGPoint:newCenter];
            CABasicAnimation *shape = [CABasicAnimation animation];
            shape.keyPath = @"bounds";
            shape.fromValue = [NSValue valueWithCGRect:layer.bounds];
            shape.toValue = [NSValue valueWithCGRect:newBounds];
            
            CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
            animationGroup.animations = [NSArray arrayWithObjects:move, shape, nil];
            animationGroup.duration = 0.2f;
            animationGroup.delegate = self;
            
            [animationGroup setValue:@"EucSelectorEndOfLineHighlight" forKey:@"THName"];
            [animationGroup setValue:layer forKey:@"THLayer"];
            [layer addAnimation:animationGroup forKey:@"EucSelectorEndOfLineHighlight"]; 
            
            layer.position = newCenter;
            layer.bounds = newBounds;
        }
        self.temporaryHighlightLayers = newTemporaryHighlightLayers;
        [newTemporaryHighlightLayers release];
        self.temporaryHighlightedElement = newTemporaryHighlightedElement;
    }
    [newTemporaryHighlightedElement release];
}

- (void)removeTemporaryHighlight
{
    for(CALayer *layer in self.temporaryHighlightLayers) {
        [layer removeFromSuperlayer];
    }
    self.temporaryHighlightLayers = nil;
    self.temporaryHighlightedElement = nil;
}



#pragma mark -
#pragma mark Selection

- (THPair *)highlightEndLayers
{
    if(!_highlightEndLayers)  {
        CGImageRef endImage = [self _cgImageNamed:@"SelectionEnd.png"];
        
        CGFloat imageWidth = CGImageGetWidth(endImage);
        
        CALayer *highlightEndLayer1 = [[CALayer alloc] init];
        highlightEndLayer1.contents = (id)endImage;
        highlightEndLayer1.bounds = CGRectMake(0.0f, 0.0f, imageWidth, 1.0f);
        
        CALayer *highlightEndLayer2 = [[CALayer alloc] init];
        highlightEndLayer2.contents = (id)endImage;
        highlightEndLayer2.bounds = CGRectMake(0.0f, 0.0f, imageWidth, 1.0f);
        
        _highlightEndLayers = [[THPair alloc] initWithFirst:highlightEndLayer1 second:highlightEndLayer2];
        
        [highlightEndLayer1 release];
        [highlightEndLayer2 release];
    }
    return _highlightEndLayers;
}

- (THPair *)highlightKnobLayers
{
    if(!_highlightKnobLayers) {
        CGImageRef knobImage = [self _cgImageNamed:@"SelectionKnob.png"];
        
        CGFloat imageWidth = CGImageGetWidth(knobImage);
        CGFloat imageHeight = CGImageGetHeight(knobImage);
        
        CALayer *highlightKnobLayer1 = [[CALayer alloc] init];
        highlightKnobLayer1.contents = (id)knobImage;
        highlightKnobLayer1.bounds = CGRectMake(0.0f, 0.0f, imageWidth, imageHeight);
        
        CALayer *highlightKnobLayer2 = [[CALayer alloc] init];
        highlightKnobLayer2.contents = (id)knobImage;
        highlightKnobLayer2.bounds = CGRectMake(0.0f, 0.0f, imageWidth, imageHeight);
        
        _highlightKnobLayers = [[THPair alloc] initWithFirst:highlightKnobLayer1 second:highlightKnobLayer2];
        
        [highlightKnobLayer1 release];
        [highlightKnobLayer2 release];        
    }
    return _highlightKnobLayers;
}

- (void)_positionKnobs
{   
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey: kCATransactionDisableActions];

    // We scale the layers we're adding or apply transforms to ensure they appear
    // at the correct size on screen even if the layer they're part of is zoomed.
    CGSize scaleFactors = [self.attachedLayer screenScaleFactors];
    CGSize inverseScaleFactors = CGSizeMake(1.0f / scaleFactors.width, 1.0f / scaleFactors.height);
    CATransform3D knobTransform = CATransform3DMakeScale(inverseScaleFactors.width, inverseScaleFactors.height, 1);
    
    NSArray *highlightLayers = self.highlightLayers;
    
    THPair *highlightEndLayers = self.highlightEndLayers;
    THPair *highlightKnobLayers = self.highlightKnobLayers;
 
    CALayer *leftHighlightLayer = [highlightLayers objectAtIndex:0];
    
    CALayer *leftEndLayer = highlightEndLayers.first;
    [leftHighlightLayer addSublayer:leftEndLayer];
    
    CGFloat leftSelectionHeight = leftHighlightLayer.bounds.size.height;
    leftEndLayer.bounds = CGRectMake(0, 0, 3.0f * inverseScaleFactors.width, leftSelectionHeight);
    leftEndLayer.position = CGPointMake(-0.5f * inverseScaleFactors.width, leftSelectionHeight * 0.5f);
    leftEndLayer.hidden = NO;
    
    CALayer *leftKnobLayer = highlightKnobLayers.first;
    [leftHighlightLayer addSublayer:leftKnobLayer];
    leftKnobLayer.position = CGPointMake(-0.5f * inverseScaleFactors.width, -4.5f * inverseScaleFactors.height);
    leftKnobLayer.transform = knobTransform;
    leftKnobLayer.hidden = NO;
    
    
    CALayer *rightHighlightLayer = [highlightLayers lastObject];
    for(NSUInteger i = highlightLayers.count - 2; rightHighlightLayer.isHidden; --i) {
        rightHighlightLayer = [highlightLayers objectAtIndex:i];
    }
    
    CALayer *rightEndLayer = highlightEndLayers.second;
    [rightHighlightLayer addSublayer:rightEndLayer];
    
    CGSize rightSelectionSize = rightHighlightLayer.bounds.size;
    rightEndLayer.bounds = CGRectMake(0, 0, 3.0f * inverseScaleFactors.width, rightSelectionSize.height);
    rightEndLayer.position = CGPointMake(rightSelectionSize.width + (0.5f * inverseScaleFactors.width), rightSelectionSize.height * 0.5f);
    rightEndLayer.hidden = NO;
    
    CALayer *rightKnobLayer = highlightKnobLayers.second;
    [rightHighlightLayer addSublayer:rightKnobLayer];
    rightKnobLayer.position = CGPointMake(rightSelectionSize.width + (0.5f  * inverseScaleFactors.width), rightSelectionSize.height + (7.5f * inverseScaleFactors.width));
    rightKnobLayer.transform = knobTransform;
    rightEndLayer.hidden = NO;

    [CATransaction commit];
}

- (void)_setupLoupe:(NSString *)loupeKind
{
    self.loupeLayer = nil;
    self.loupeContentsLayer = nil;
    self.loupeContentsImageFactory = nil;
        
    if(loupeKind != nil) {
        CGImageRef highImage = [self _cgImageNamed:[NSString stringWithFormat:@"%@LoupeHigh.png", loupeKind]];
        CGImageRef lowImage = [self _cgImageNamed:[NSString stringWithFormat:@"%@LoupeLow.png", loupeKind]];
        CGImageRef maskImage = [self _cgImageNamed:[NSString stringWithFormat:@"%@LoupeMask.png", loupeKind]];
            
        CGSize magnificationLoupeSize = CGSizeMake(CGImageGetWidth(highImage),
                                                   CGImageGetHeight(highImage));
        CGRect magnificationLoupeRect = CGRectMake(0, 0, magnificationLoupeSize.width, magnificationLoupeSize.height);
        
        CALayer *topmostLayer = self.attachedLayer.topmostLayer;
        CALayer *loupeContentsLayer = self.loupeContentsLayer;
        THImageFactory *loupeContentsImageFactory;
        CALayer *loupeLayer;
        if(!loupeContentsLayer) {
            CGPoint magnificationLoupeCenter = CGPointMake(magnificationLoupeSize.width * 0.5f, magnificationLoupeSize.height * 0.5f);
            
            loupeLayer = [[CALayer alloc] init];
            loupeLayer.bounds = magnificationLoupeRect;
            self.loupeLayer = loupeLayer;
            
            loupeLayer.contents = (id)lowImage;
            
            CALayer *contentsMaskLayer = [[CALayer alloc] init];
            contentsMaskLayer.bounds = magnificationLoupeRect;
            contentsMaskLayer.position = magnificationLoupeCenter;
            contentsMaskLayer.contents = (id)maskImage;
            
            loupeContentsLayer = [[CALayer alloc] init];
            loupeContentsLayer.bounds = magnificationLoupeRect;
            loupeContentsLayer.position = magnificationLoupeCenter;
            loupeContentsLayer.mask = contentsMaskLayer;
            
            self.loupeContentsLayer = loupeContentsLayer;
            [loupeLayer addSublayer:loupeContentsLayer];
            
            [loupeContentsLayer release];
            [contentsMaskLayer release];
            
            // The top of the glass.
            CALayer *highLayer = [[CALayer alloc] init];
            highLayer.bounds = magnificationLoupeRect;
            highLayer.contents = (id)highImage;
            [loupeLayer addSublayer:highLayer];
            highLayer.position = CGPointMake(magnificationLoupeSize.width * 0.5f, magnificationLoupeSize.height * 0.5f);
            [highLayer release];
            
            // Don't add it to self.viewWithSelection - we're using renderInContext:
            // below, so the effect would be an infinite tunnel after a few moves.
            [topmostLayer addSublayer:loupeLayer];
            
            CABasicAnimation *loupePopUp = [[CABasicAnimation alloc] init];
            loupePopUp.keyPath = @"transform";
            CATransform3D fromTransform = CATransform3DMakeTranslation(0, magnificationLoupeSize.height * 0.5f, 0);
            fromTransform = CATransform3DScale(fromTransform, 
                                               1.0f / magnificationLoupeSize.width,
                                               1.0f / magnificationLoupeSize.height,
                                               1.0f);
            loupePopUp.fromValue = [NSValue valueWithCATransform3D:fromTransform];
            loupePopUp.duration = sLoupePopUpDuration;
            [loupeLayer addAnimation:loupePopUp forKey:@"EucSelectorLoupePopUp"];
            [loupePopUp release];
            
            loupeContentsImageFactory = [[THImageFactory alloc] initWithSize:magnificationLoupeSize];
            self.loupeContentsImageFactory = loupeContentsImageFactory;
            [loupeContentsImageFactory release];
        }
    }
    self.currentLoupeKind = loupeKind;
}

- (void)_loupeToPoint:(CGPoint)point yOffset:(CGFloat)yOffset;
{
    NSParameterAssert(self.loupeLayer);
    
    CALayer *loupeLayer = self.loupeLayer;
    CALayer *loupeContentsLayer = self.loupeContentsLayer;
    THImageFactory *loupeContentsImageFactory = self.loupeContentsImageFactory;

    CGRect magnificationLoupeRect = loupeLayer.bounds;
    CGSize magnificationLoupeSize = magnificationLoupeRect.size;

    CALayer *layerToMagnify;
    CALayer *snapshotLayer = self.snapshotLayer;
    if(snapshotLayer) {
        layerToMagnify = snapshotLayer;
        point = [snapshotLayer convertPoint:point fromLayer:self.attachedLayer];
    } else {
        layerToMagnify = self.attachedLayer;
    }
    
    CGSize layerToMagnifySize = layerToMagnify.bounds.size;
    
    CALayer *topmostLayer = layerToMagnify.topmostLayer;
    CGSize screenScaleFactors = [layerToMagnify screenScaleFactors];
    
    // We want 1.25 * bigger.
    CGFloat scaleFactorX = screenScaleFactors.width * 1.25f;
    CGFloat scaleFactorY = screenScaleFactors.height * 1.25f;
    
    // Now, the view.
    CGContextRef context = loupeContentsImageFactory.CGContext;
    CGContextSaveGState(context);
    
    UIColor *backgroundColor = self.loupeBackgroundColor;
    if(backgroundColor) {
        CGContextSaveGState(context);
        CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
        CGContextFillRect(context, magnificationLoupeRect);
        CGContextRestoreGState(context);
    } else {
        CGContextClearRect(context, magnificationLoupeRect);
    }
    
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    // Scale the context and translate it so that we can draw the view
    // in the correct place.
    CGContextScaleCTM(context, scaleFactorX, -scaleFactorY);
    
    // '* (1 / scaleFactor)' below to counteract the existing * 1.25 scaling.
    CGPoint translationPoint = CGPointMake(-point.x + magnificationLoupeSize.width * (0.5f * (1.0f / scaleFactorX)), 
                                           -point.y - magnificationLoupeSize.height * (0.5f * (1.0f / scaleFactorY)));
    
    // Don't show blank area off the bottom of the view.
    translationPoint.y = MAX(-layerToMagnifySize.height, translationPoint.y); 
    
    CGContextTranslateCTM(context, 
                          translationPoint.x,
                          translationPoint.y);
    
    // Draw the view. 
    [layerToMagnify renderInContext:context];
    
    CGContextRestoreGState(context);
    
    // Now get the image we constructed and put it into the loupe view.
    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    // We draw the layer content in the -drawLayer:inContext: delegate method.
    loupeContentsLayer.contents = (id)loupeContentsImageFactory.snapshotCGImage;
    
    CGPoint windowPoint = [layerToMagnify convertPoint:point toLayer:topmostLayer];

    // Position the loupe.
    CGRect frame = magnificationLoupeRect;
    frame.origin.x = roundf(windowPoint.x - (frame.size.width * 0.5f));
    frame.origin.y = roundf(windowPoint.y - frame.size.height + yOffset);
    
    // Make sure the loupe doesn't go too far off the top of the screen so that 
    // the user can still see the middle of it.
    CGFloat minY = roundf(-magnificationLoupeSize.height * 0.33f);
    //frame.origin.x = MAX(frame.origin.x, 0);
    frame.origin.y = MAX(frame.origin.y, minY);
    
    loupeLayer.position = CGPointMake(frame.origin.x + frame.size.width * 0.5f, frame.origin.y + frame.size.height * 0.5f);
    [CATransaction commit];
}

- (void)_removeLoupe
{
    CALayer *loupeLayer = self.loupeLayer;
    CGSize magnificationLoupeSize = loupeLayer.bounds.size;
    
    CABasicAnimation *loupePopDown = [[CABasicAnimation alloc] init];
    loupePopDown.keyPath = @"transform";
    CATransform3D toTransform = CATransform3DMakeTranslation(0, magnificationLoupeSize.height / 2.0f, 0);
    toTransform = CATransform3DScale(toTransform, 1.0f / magnificationLoupeSize.width,
                                       1.0f / magnificationLoupeSize.height,
                                       1.0f);
    loupePopDown.fromValue = [NSValue valueWithCATransform3D:loupeLayer.transform];
    loupePopDown.toValue = [NSValue valueWithCATransform3D:toTransform];
    loupePopDown.duration = sLoupePopDownDuration;
    loupePopDown.delegate = self;
    [loupePopDown setValue:@"EucSelectorLoupePopDown" forKey:@"THName"];
    [loupePopDown setValue:loupeLayer forKey:@"THLayer"];
    [loupeLayer addAnimation:loupePopDown forKey:@"EucSelectorLoupePopDown"];
    [loupePopDown release];
    
    // Avoid popping back to full-size.
    loupeLayer.transform = toTransform;

    // Forget this loupe.  It will be removed from its superview in the 
    // animationDidStop callback.
    [self _setupLoupe:nil];
}

- (void)_removeAllHighlightLayers
{
    [self.highlightLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    self.highlightLayers = nil;
    self.highlightEndLayers = nil;
    self.highlightKnobLayers = nil;    
}


- (void)changeActiveMenuItemsTo:(NSArray *)menuItems
{
    [self.menuController setMenuItems:menuItems];
}

- (void)_positionMenu
{
    UIView *viewForMenu = self.attachedView;
    id<EucSelectorDataSource> dataSource = self.dataSource;
    if(!viewForMenu || [dataSource respondsToSelector:@selector(viewForMenuForEucSelector:)]) {
        viewForMenu = [dataSource viewForMenuForEucSelector:self];
    }
    
    CGRect targetRect = [[[self highlightLayers] objectAtIndex:0] frame];
    for(CALayer *layer in self.highlightLayers) {
        if(!layer.isHidden) {
            targetRect = CGRectUnion(targetRect, layer.frame);
        }
    }
    [self.menuController setTargetRect:[viewForMenu.layer convertRect:targetRect fromLayer:self.attachedLayer]
                                inView:viewForMenu];
}

- (void)setTrackingStage:(EucSelectorTrackingStage)stage;
{
    if(stage != _trackingStage) {
        EucSelectorTrackingStage previousStage = _trackingStage;
        _trackingStage = stage;
        
        if(previousStage == EucSelectorTrackingStageFirstSelection) {
            [self _removeLoupe];
        } else if(previousStage == EucSelectorTrackingStageChangingSelection) {
            [self _removeLoupe];
            self.draggingKnob = nil;
        } else if(previousStage == EucSelectorTrackingStageSelectedAndWaiting) {
            self.menuShouldBeAvailable = NO;
            [self.menuController setMenuVisible:NO animated:YES];
        }

        if(previousStage != EucSelectorTrackingStageFirstSelection && 
           (stage == EucSelectorTrackingStageNone || stage == EucSelectorTrackingStageFirstSelection)) {
            if(self.selectedRangeIsHighlight &&
               [self.delegate respondsToSelector:@selector(eucSelector:didEndEditingHighlightWithRange:movedToRange:)]) {
                [self.delegate eucSelector:self 
           didEndEditingHighlightWithRange:self.selectedRangeOriginalHighlightRange
                              movedToRange:self.selectedRange];
                
                // The view may change its highlight ranges in response to our callback.
                [_cachedHighlightRanges release];
                _cachedHighlightRanges = nil;                
            }
            self.selectedRangeOriginalHighlightRange = nil;
            self.selectionColor = nil;
        }
        
        if(previousStage == EucSelectorTrackingStageFirstSelection || 
           previousStage == EucSelectorTrackingStageChangingSelection) {
            CALayer *snapshotLayer = self.snapshotLayer;
            if(snapshotLayer) {
                [CATransaction begin];
                [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];

                if(self.highlightLayers.count) {
                    CALayer *attachedLayer = self.attachedLayer;
                    for(CALayer *layer in self.highlightLayers) {
                        [layer removeFromSuperlayer];
                        CGRect frame = layer.frame;
                        layer.frame = [attachedLayer convertRect:frame fromLayer:snapshotLayer];
                        [attachedLayer addSublayer:layer];
                    }
                }
                
                [snapshotLayer removeFromSuperlayer];
                self.snapshotLayer = nil;
                
                [CATransaction commit];
            }
        }
        
        if(stage == EucSelectorTrackingStageFirstSelection || stage == EucSelectorTrackingStageChangingSelection) {
            id<EucSelectorDataSource> dataSource = self.dataSource;
            if([dataSource respondsToSelector:@selector(viewSnapshotImageForEucSelector:)]) {
                [CATransaction begin];
                [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];

                CALayer *attachedLayer = self.attachedLayer;
                CALayer *windowLayer = attachedLayer.windowLayer;                        
                CGRect windowFrame = [windowLayer convertRect:windowLayer.bounds toLayer:attachedLayer];
                
                CALayer *snapshotLayer = [CALayer layer];
                snapshotLayer.contents = (id)([dataSource viewSnapshotImageForEucSelector:self].CGImage);
                snapshotLayer.opaque = YES;
                snapshotLayer.frame = windowFrame;
                [attachedLayer addSublayer:snapshotLayer];
                self.snapshotLayer = snapshotLayer;

                if(self.highlightLayers.count) {
                    for(CALayer *layer in self.highlightLayers) {
                        [layer removeFromSuperlayer];
                        CGRect frame = layer.frame;
                        layer.frame = [snapshotLayer convertRect:frame fromLayer:attachedLayer];
                        [snapshotLayer addSublayer:layer];
                    }
                }
                
                [CATransaction commit];
            }            
        }
        
        switch(stage) {
            case EucSelectorTrackingStageNone:
            {
                self.selectedRangeIsHighlight = NO;
                [self _removeAllHighlightLayers];
                [self _clearSelectionCaches];
                self.tracking = NO;
                break;
            } 
            case EucSelectorTrackingStageFirstSelection:
            {
                if(previousStage == EucSelectorTrackingStageNone) {
                    self.tracking = YES;
                } else {
                    [self _removeAllHighlightLayers];
                }
                [self _setupLoupe:@"Magnification"];
                [self _trackTouch:self.trackingTouch];
                break;
            } 
            case EucSelectorTrackingStageSelectedAndWaiting:
            {
                if(previousStage == EucSelectorTrackingStageFirstSelection && self.selectedRangeIsHighlight) {
                    self.selectedRangeOriginalHighlightRange = self.selectedRange;
                    if([self.delegate respondsToSelector:@selector(eucSelector:willBeginEditingHighlightWithRange:)]) {
                        UIColor *selectionColor = [self.delegate eucSelector:self willBeginEditingHighlightWithRange:self.selectedRange];
                        if(selectionColor) {
                            self.selectionColor = selectionColor;
                            
                            // Recolor any existing highlight layers.
                            CGColorRef cgColor = selectionColor.CGColor;
                            for(CALayer *layer in self.highlightLayers) {
                                layer.backgroundColor = cgColor;
                            }
                        }
                    } 
                }
                
                [self _positionKnobs]; 
                id<EucSelectorDelegate> delegate = self.delegate;
                if([delegate respondsToSelector:@selector(menuItemsForEucSelector:)]) {
                    NSArray *menuItems = [delegate menuItemsForEucSelector:self];
                    if(menuItems) {
                        EucMenuController *menuController = self.menuController;
                        if(!menuController)  {
                            menuController = [[EucMenuController alloc] init];
                            self.menuController = menuController;
                        }
                        
                        menuController.menuItems = menuItems;
                        [self _positionMenu];
                        self.menuShouldBeAvailable = YES;
                        if(!self.shouldHideMenu) {
                            [menuController setMenuVisible:YES animated:YES];
                        }
                    }
                }
                                            
                break;   
            }
            case EucSelectorTrackingStageChangingSelection:
            {         
                [self _setupLoupe:@"Line"];
                break;
            } 
        }
    }
}

- (void)_clearSelectionCaches
{
    [_cachedBlockIdentifiers release];
    _cachedBlockIdentifiers = nil;
    if(_cachedBlockIdentifierToElements) {
        CFRelease(_cachedBlockIdentifierToElements);
        _cachedBlockIdentifierToElements = NULL;
    }
    if(_cachedBlockIdentifierToRects) {
        CFRelease(_cachedBlockIdentifierToRects);
        _cachedBlockIdentifierToRects = NULL;
    }
    if(_cachedBlockAndElementIdentifierToRects) {
        CFRelease(_cachedBlockAndElementIdentifierToRects);
        _cachedBlockAndElementIdentifierToRects = NULL;
    }
    [_cachedHighlightRanges release];
    _cachedHighlightRanges = nil;
}

- (NSArray *)_blockIdentifiers
{
    if(!_cachedBlockIdentifiers) {
        _cachedBlockIdentifiers = [([self.dataSource blockIdentifiersForEucSelector:self] ?: [NSArray array]) retain];
    }
    return _cachedBlockIdentifiers;
}

- (NSArray *)_identifiersForElementsOfBlockWithIdentifier:(id)blockId
{
    if(!_cachedBlockIdentifierToElements) {
        _cachedBlockIdentifierToElements = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                                     0, 
                                                                     &kCFTypeDictionaryKeyCallBacks, 
                                                                     &kCFTypeDictionaryValueCallBacks);
    }
    NSArray *ret = (NSArray *)CFDictionaryGetValue(_cachedBlockIdentifierToElements, blockId);
    if(!ret) {
        ret = [self.dataSource eucSelector:self identifiersForElementsOfBlockWithIdentifier:blockId] ?: [NSArray array];
        if(ret) {
            CFDictionarySetValue(_cachedBlockIdentifierToElements, blockId, ret);
        }
    }
    return ret;
}

- (CGRect)_frameOfBlockWithIdentifier:(id)blockId
{
    if(!_cachedBlockIdentifierToRects) {
        _cachedBlockIdentifierToRects = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                                  0, 
                                                                  &kCFTypeDictionaryKeyCallBacks, 
                                                                  &kCFTypeDictionaryValueCallBacks);
    }
    NSValue *ret = (NSValue *)CFDictionaryGetValue(_cachedBlockIdentifierToRects, blockId);
    if(ret) {
        return [ret CGRectValue];
    } else {
        CGRect rect = [self.dataSource eucSelector:self frameOfBlockWithIdentifier:blockId];
        CFDictionarySetValue(_cachedBlockIdentifierToRects, blockId, [NSValue valueWithCGRect:rect]);
        return rect;
    }
}

- (NSArray *)_rectsForElementWithIdentifier:(id)elementId 
                      ofBlockWithIdentifier:(id)blockId
{
    if(!_cachedBlockAndElementIdentifierToRects) {
        _cachedBlockAndElementIdentifierToRects = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                                            0, 
                                                                            &kCFTypeDictionaryKeyCallBacks, 
                                                                            &kCFTypeDictionaryValueCallBacks);
    }
    CFMutableDictionaryRef thisBlockElementRects = (CFMutableDictionaryRef)CFDictionaryGetValue(_cachedBlockAndElementIdentifierToRects, blockId);
    if(!thisBlockElementRects) {
        thisBlockElementRects = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                          0, 
                                                          &kCFTypeDictionaryKeyCallBacks, 
                                                          &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(_cachedBlockAndElementIdentifierToRects, blockId, thisBlockElementRects);
        CFRelease(thisBlockElementRects);
        
    }
    NSArray *ret = (NSArray *)CFDictionaryGetValue(thisBlockElementRects, elementId);
    if(!ret) {
        ret = [self.dataSource eucSelector:self rectsForElementWithIdentifier:elementId ofBlockWithIdentifier:blockId];
        CFDictionarySetValue(thisBlockElementRects, elementId, ret);
    }
    return ret;
}

- (NSArray *)_highlightRanges
{
    NSArray *ret = _cachedHighlightRanges;
    if(!ret) {
        id<EucSelectorDataSource> dataSource = self.dataSource;
        if([dataSource respondsToSelector:@selector(highlightRangesForEucSelector:)]) {
            ret = [dataSource highlightRangesForEucSelector:self];
        }
        if(!ret) {
            ret = [NSArray array];
        }
        _cachedHighlightRanges = [ret retain];
    }
    return ret;
}

- (THPair *)_blockAndElementIdsForPoint:(CGPoint)point
{
    for(id blockId in [self _blockIdentifiers]) {
        if(CGRectContainsPoint([self _frameOfBlockWithIdentifier:blockId], point)) {
            for(id elementId in [self _identifiersForElementsOfBlockWithIdentifier:blockId]) {
                NSArray *rectsForElement = [self _rectsForElementWithIdentifier:elementId ofBlockWithIdentifier:blockId];
                for(NSValue *rectValue in rectsForElement) {
                    if(CGRectContainsPoint([rectValue CGRectValue], point)) {
                        return [THPair pairWithFirst:blockId second:elementId];
                    }
                }
            }
        }
    }
    return nil;
}

- (THPair *)_closestBlockAndElementIdsForPoint:(CGPoint)point
{
    id bestBlockId = nil;
    id bestElementId = nil;
    
    CGFloat bestDistance = CGFLOAT_MAX;
    
    for(id blockId in [self _blockIdentifiers]) {
        for(id elementId in [self _identifiersForElementsOfBlockWithIdentifier:blockId]) {
            NSArray *rectsForElement = [self _rectsForElementWithIdentifier:elementId ofBlockWithIdentifier:blockId];
            for(NSValue *rectValue in rectsForElement) {
                CGFloat distance = CGPointDistanceFromRect(point, [rectValue CGRectValue]);
                if(distance < bestDistance) {
                    bestDistance = distance;
                    bestBlockId = blockId;
                    bestElementId = elementId;
                }
            }
        }
    }
    if(bestDistance != CGFLOAT_MAX) {
        return [THPair pairWithFirst:bestBlockId second:bestElementId];
    } else {
        return nil; 
    }
}


+ (NSArray *)coalescedLineRectsForElementRects:(NSArray *)elementRects
{        
    NSMutableArray *ret = [NSMutableArray array];
    CGRect currentLineRect = CGRectZero;
    
    BOOL isFirstElement = YES;
    for(NSValue *rectValue in elementRects) {
        CGRect thisRect = [rectValue CGRectValue];
        if(isFirstElement) {
            currentLineRect = thisRect;
            isFirstElement = NO;
        } else {
            CGFloat overlappingPixels = 
                MIN(currentLineRect.origin.y + currentLineRect.size.height, thisRect.origin.y + thisRect.size.height)
                - MAX(currentLineRect.origin.y, thisRect.origin.y);
            
            // Try to work out if this rect is "on the same line" as
            // the last one, and extend the "line rect" if it is.
            if(thisRect.origin.x >= currentLineRect.origin.x + currentLineRect.size.width &&
               (overlappingPixels > 0.33 * currentLineRect.size.height ||
                overlappingPixels > 0.33 * thisRect.size.height)) {
                   CGFloat newLimit = MAX(currentLineRect.origin.y + currentLineRect.size.height, 
                                          thisRect.origin.y + thisRect.size.height);
                   currentLineRect.origin.y = MIN(currentLineRect.origin.y, thisRect.origin.y);
                   currentLineRect.size.height = newLimit - currentLineRect.origin.y;
                   currentLineRect.size.width = (thisRect.size.width + thisRect.origin.x) - currentLineRect.origin.x; 
               } else {
                   [ret addObject:[NSValue valueWithCGRect:currentLineRect]];
                   currentLineRect = thisRect;
               }
        }
    }
    if(!CGRectEqualToRect(currentLineRect, CGRectZero)) {
        [ret addObject:[NSValue valueWithCGRect:currentLineRect]];
    }   
    return ret;
}

- (NSArray *)highlightRectsForRange:(EucSelectorRange *)selectedRange 
{                                   
    NSArray *blockIds = [self _blockIdentifiers];
    
    id startBlockId = selectedRange.startBlockId;
    id endBlockId = selectedRange.endBlockId;
    id startElementId = selectedRange.startElementId;
    id endElementId = selectedRange.endElementId;
    
    NSMutableArray *nonCoalescedRects = [NSMutableArray array];    
    NSUInteger blockIdIndex = 0;
    NSUInteger blockIdsCount = blockIds.count;    
    
    BOOL isFirstBlock;
    if([[blockIds objectAtIndex:0] compare:startBlockId] == NSOrderedDescending) {
        // The real first block was before the first block we have seen.
        isFirstBlock = NO;
    } else {
        while([[blockIds objectAtIndex:blockIdIndex] compare:startBlockId] == NSOrderedAscending) {
            ++blockIdIndex;
        }
        isFirstBlock = YES;
    }
    
    BOOL isLastBlock = NO;
    while(!isLastBlock && blockIdIndex < blockIdsCount) {
        id blockId = [blockIds objectAtIndex:blockIdIndex];
        
        NSArray *elementIds = [self _identifiersForElementsOfBlockWithIdentifier:blockId];
        NSUInteger elementIdCount = elementIds.count;
        NSUInteger elementIdIndex = 0;
        
        isLastBlock = ([blockId compare:endBlockId] == NSOrderedSame);
        
        id elementId;
        if(isFirstBlock) {
            while([[elementIds objectAtIndex:elementIdIndex] compare:startElementId] == NSOrderedAscending) {
                ++elementIdIndex;
            }
            isFirstBlock = NO;
        }
        
        do {
            elementId = [elementIds objectAtIndex:elementIdIndex];
            [nonCoalescedRects addObjectsFromArray:[self _rectsForElementWithIdentifier:elementId
                                                                  ofBlockWithIdentifier:blockId]];
            ++elementIdIndex;
        } while ((isLastBlock ? ([elementId compare:endElementId] < NSOrderedSame) : YES) &&
                 elementIdIndex < elementIdCount);
        ++blockIdIndex;
    }
    
    NSArray *coalescedRects = [[self class] coalescedLineRectsForElementRects:nonCoalescedRects];
    
    // We'll scale the rects to make sure they will be on pixl boundies
    // on screen even if the layer they're in has a scale transform applied.
    CGSize screenScaleFactors = [self.attachedLayer screenScaleFactors];
    
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:coalescedRects.count];
    for(NSValue *rectValue in coalescedRects) {
        [ret addObject:[NSValue valueWithCGRect:CGRectScreenIntegral([rectValue CGRectValue], screenScaleFactors)]];
    }
    return ret;
}

- (void)redisplaySelectedRange
{
    EucSelectorRange *selectedRange = self.selectedRange;
    if(selectedRange) {
        // Work out he rects to highlight
        NSArray *highlightRects = [self highlightRectsForRange:selectedRange];
        
        // Highlight them, reusing the current highlight layers if possible.
        CALayer *attachedLayer = self.attachedLayer;
        NSMutableArray *highlightLayers = self.highlightLayers;
        
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey: kCATransactionDisableActions];
        
        NSUInteger highlightRectsCount = highlightRects.count;
        NSUInteger unusedHighlightLayersCount = highlightLayers.count;
        if(highlightRectsCount) {        
            if(unusedHighlightLayersCount < highlightRects.count) {
                if(!highlightLayers) {
                    highlightLayers = [NSMutableArray arrayWithCapacity:highlightRectsCount];
                    self.highlightLayers = highlightLayers;
                }
                UIColor *highlightUIColor = self.selectionColor ?: [UIColor colorWithRed:47.0f/255.0f green:102.0f/255.0f blue:179.0f/255.0f alpha:0.2f];
                CGColorRef highlightColor = highlightUIColor.CGColor;

                for(NSUInteger i = unusedHighlightLayersCount; i < highlightRectsCount; ++i) {
                    CALayer *layer = [[CALayer alloc] init];
                    layer.backgroundColor = highlightColor;
                    [highlightLayers addObject:layer];
                    ++unusedHighlightLayersCount;
                    [layer release];
                
                    [self.snapshotLayer ?: attachedLayer addSublayer:layer];
                }
            }
        } 
        
        CALayer *snapshotLayer = self.snapshotLayer;
        CGPoint translation = [snapshotLayer convertPoint:CGPointZero fromLayer:attachedLayer];
                
        for(NSUInteger i = 0; i < highlightRectsCount; ++i) {
            CALayer *layer = [highlightLayers objectAtIndex:i];
            NSValue *rectValue = [highlightRects objectAtIndex:i];
            layer.frame = [rectValue CGRectValue];
            
            CGPoint position = layer.position;
            position.x += translation.x;
            position.y += translation.y;
            layer.position = position;
            
            layer.hidden = NO;
            --unusedHighlightLayersCount;
        }
        
        for(NSUInteger i = 0; i < unusedHighlightLayersCount; ++i) {
            // Hide unused layers.
            ((CALayer *)[highlightLayers objectAtIndex:highlightRectsCount + i]).hidden = YES;
        }        
        
        [CATransaction commit];
        
        if(self.trackingStage != EucSelectorTrackingStageFirstSelection) {
            [self _positionKnobs];
        }   
    }
}

- (void)setSelectedRange:(EucSelectorRange *)newRange
{
    if(newRange != _selectedRange &&
       !(newRange && [newRange isEqual:_selectedRange])) {
        if(!newRange) {
            if(self.trackingStage == EucSelectorTrackingStageFirstSelection) {
                [CATransaction begin];
                [CATransaction setValue:(id)kCFBooleanTrue forKey: kCATransactionDisableActions];
                for(CALayer *layer in self.highlightLayers) {
                    layer.hidden = YES;
                }      
                [CATransaction commit];
            } else {
                self.trackingStage = EucSelectorTrackingStageNone;
            }            
        }
        [_selectedRange release];
        _selectedRange = [newRange retain];
        if(newRange) {
            [self redisplaySelectedRange];
        } 
    }
}

- (void)_trackTouch:(UITouch *)touch
{       
    CALayer *attachedLayer = self.attachedLayer;
    CGPoint location = [attachedLayer convertPoint:[touch locationInView:nil] fromLayer:attachedLayer.windowLayer];
    
    if(self.trackingStage == EucSelectorTrackingStageFirstSelection) {
        EucSelectorRange *newSelectedRange = nil;
        BOOL newSelectedRangeIsHighlight = NO;

        THPair *blockAndElementIds = [self _blockAndElementIdsForPoint:location];        
        if(blockAndElementIds) {
            newSelectedRange = [[[EucSelectorRange alloc] init] autorelease];
            id blockId = blockAndElementIds.first;
            id elementId = blockAndElementIds.second;
            
            newSelectedRange.startBlockId = blockId;
            newSelectedRange.endBlockId = blockId;
            newSelectedRange.startElementId = elementId;
            newSelectedRange.endElementId = elementId;

            // If we overlap a highlight range, select the entire range.
            for(EucSelectorRange *highlightRange in [self _highlightRanges]) {
                if([highlightRange overlaps:newSelectedRange]) {
                    newSelectedRange = highlightRange;
                    newSelectedRangeIsHighlight = YES;
                    break;
                }
            }
        }
        
        self.selectedRange = newSelectedRange;
        self.selectedRangeIsHighlight = newSelectedRangeIsHighlight;
        
        [self _loupeToPoint:location yOffset:4.0f];
    } else {
        location.y += self.draggingKnobVerticalOffset;
        THPair *closestBlockAndElement = [self _closestBlockAndElementIdsForPoint:location];
        
        if(closestBlockAndElement) {
            EucSelectorRange *newSelectedRange = [[[EucSelectorRange alloc] init] autorelease];
            
            id blockId = closestBlockAndElement.first;
            id elementId = closestBlockAndElement.second;
            
            EucSelectorRange *currentSelectedRange = self.selectedRange;

            BOOL left = self.draggingKnob == self.highlightKnobLayers.first;
            if(left) {
                newSelectedRange.endBlockId = currentSelectedRange.endBlockId;
                newSelectedRange.endElementId = currentSelectedRange.endElementId;
                NSComparisonResult blockComparison = [blockId compare:currentSelectedRange.endBlockId];
                if(blockComparison == NSOrderedAscending ||
                   (blockComparison == NSOrderedSame && [elementId compare:currentSelectedRange.endElementId] == NSOrderedAscending)) {
                    newSelectedRange.startBlockId = blockId;
                    newSelectedRange.startElementId = elementId;
                } else {
                    newSelectedRange.startBlockId = currentSelectedRange.endBlockId;
                    newSelectedRange.startElementId = currentSelectedRange.endElementId;
                }
            } else {
                newSelectedRange.startBlockId = currentSelectedRange.startBlockId;
                newSelectedRange.startElementId = currentSelectedRange.startElementId;
                NSComparisonResult blockComparison = [blockId compare:currentSelectedRange.startBlockId];
                if(blockComparison == NSOrderedDescending ||
                   (blockComparison == NSOrderedSame && [elementId compare:currentSelectedRange.startElementId] == NSOrderedDescending)) {
                    newSelectedRange.endBlockId = blockId;
                    newSelectedRange.endElementId = elementId;
                } else {
                    newSelectedRange.endBlockId = currentSelectedRange.startBlockId;
                    newSelectedRange.endElementId = currentSelectedRange.startElementId;
                }
            }
            
            // We're not allowed to drag over highlight ranges unless they're
            // the one we started editing, so if we overlap any,
            // reset the selection.
            for(EucSelectorRange *highlightRange in [self _highlightRanges]) {
                if([highlightRange overlaps:newSelectedRange] && 
                   ![highlightRange isEqual:self.selectedRangeOriginalHighlightRange]) {
                    newSelectedRange = nil;
                    break;
                }
            }
            
            if(newSelectedRange) {
                self.selectedRange = newSelectedRange;
            }
            
            CALayer *endLayer = left ? self.highlightEndLayers.first : self.highlightEndLayers.second;
            CGRect endLayerFrame = [endLayer convertRect:endLayer.bounds toLayer:attachedLayer];
            CGRect endLayerScreenBounds = [attachedLayer convertRect:endLayerFrame toLayer:attachedLayer.topmostLayer];
            CGFloat yOffset = - roundf(endLayerScreenBounds.size.height * 0.5f) + (left ? -13.0f : -1.0f);
            [self _loupeToPoint:CGPointMake(roundf(endLayerFrame.origin.x + endLayerFrame.size.width * 0.5f),
                                            roundf(endLayerFrame.origin.y + endLayerFrame.size.height * 0.5f))
                        yOffset:yOffset];                            
        }
    }
}

- (void)_startSelection
{
    self.trackingStage = EucSelectorTrackingStageFirstSelection;
    
    // This is cheating a bit...
    self.trackingTouchHasMoved = YES;
}

- (void)_setDraggingKnobFromTouch:(UITouch *)touch
{
    CALayer *draggingKnob = nil;
    CGFloat draggingKnobVerticalOffset = 0.0f;
    
    THPair *highlightKnobLayers = self.highlightKnobLayers;
    if(highlightKnobLayers) {
        CALayer *leftKnobLayer = self.highlightKnobLayers.first;
        if(!leftKnobLayer.hidden) {
            CALayer *attachedLayer = self.attachedLayer;
            
            CGPoint touchPoint = [attachedLayer convertPoint:[touch locationInView:nil] fromLayer:attachedLayer.windowLayer];
            CGRect leftKnobRect = [leftKnobLayer convertRect:CGRectInset(leftKnobLayer.bounds, -8.0f, -8.0f) toLayer:attachedLayer];

            if(CGRectContainsPoint(leftKnobRect, touchPoint)) {
                draggingKnob = leftKnobLayer;
                CALayer *endLayer = self.highlightEndLayers.first;
                CGPoint endLayerCenter = [endLayer convertPoint:endLayer.position toLayer:attachedLayer];
                draggingKnobVerticalOffset = endLayerCenter.y - touchPoint.y;
            } else {
                CALayer *rightKnobLayer = self.highlightKnobLayers.second;
                CGRect rightKnobRect = [rightKnobLayer convertRect:CGRectInset(rightKnobLayer.bounds, -8.0f, -8.0f) toLayer:attachedLayer];
                if(CGRectContainsPoint(rightKnobRect, touchPoint)) {
                    draggingKnob = rightKnobLayer;
                    CALayer *endLayer = self.highlightEndLayers.second;
                    CGPoint endLayerCenter = [endLayer convertPoint:endLayer.position toLayer:attachedLayer];
                    draggingKnobVerticalOffset = endLayerCenter.y - touchPoint.y;                    
                }
            }
        }
    }

    self.draggingKnob = draggingKnob;
    self.draggingKnobVerticalOffset = draggingKnobVerticalOffset;
}

- (void)setSelectionDisabled:(BOOL)selectionDisabled
{
    _selectionDisabled = selectionDisabled;
    if(_selectionDisabled) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_startSelection) object:nil];
        self.trackingStage = EucSelectorTrackingStageNone;
        self.trackingTouch = nil;
    }
}

- (void)touchesBegan:(NSSet *)touches
{
    if(!self.selectionDisabled && !self.trackingTouch) {
        UITouch *touch = [touches anyObject];
        BOOL currentlyTracking = self.isTracking;

        self.trackingTouch = touch;
        self.trackingTouchHasMoved = NO;
        if(currentlyTracking) {
            [self _setDraggingKnobFromTouch:touch];
        }
        if(!currentlyTracking || 
           !self.draggingKnob) {
            [self performSelector:@selector(_startSelection) withObject:nil afterDelay:0.5f];
        } else {
            if(self.draggingKnob) {
                self.trackingStage = EucSelectorTrackingStageChangingSelection;
                [self _trackTouch:touch];
            } 
        }
        
    }
}

- (void)touchesMoved:(NSSet *)touches
{
    UITouch *trackingTouch = self.trackingTouch;
    if(!self.selectionDisabled && [touches containsObject:trackingTouch]) {
        if(!self.isTracking || 
           (self.trackingStage == EucSelectorTrackingStageSelectedAndWaiting && !self.draggingKnob)) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_startSelection) object:nil];
            self.trackingTouch = nil;
            self.trackingStage = EucSelectorTrackingStageNone;
        } else {
            self.trackingTouchHasMoved = YES;
            [self _trackTouch:trackingTouch];
        }
    }
}
    
- (void)touchesEnded:(NSSet *)touches
{
    UITouch *trackingTouch = self.trackingTouch;
    if(!self.selectionDisabled && [touches containsObject:trackingTouch]) {
        if(!self.isTracking || 
           (self.trackingStage == EucSelectorTrackingStageSelectedAndWaiting && !self.draggingKnob)) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_startSelection) object:nil];
            self.trackingTouch = nil;
            self.trackingStage = EucSelectorTrackingStageNone;
        } else {
            [self _trackTouch:trackingTouch];
            if((self.trackingStage == EucSelectorTrackingStageChangingSelection && self.draggingKnob) ||
               (self.trackingTouchHasMoved && self.highlightLayers.count && !((CALayer *)[self.highlightLayers objectAtIndex:0]).isHidden)) {
                self.trackingStage = EucSelectorTrackingStageSelectedAndWaiting;
            } else {
                self.trackingStage = EucSelectorTrackingStageNone;
            }
            self.trackingTouch = nil;            
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches
{
    if([touches containsObject:self.trackingTouch]) {
        if(self.trackingStage == EucSelectorTrackingStageSelectedAndWaiting  && !self.draggingKnob) {
            // This was a touch outside the selection.
            // Since it was cancelled, treat it as if it never existed.
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_startSelection) object:nil];
            self.trackingTouch = nil;
        } else {
            [self touchesEnded:touches];
        }
    }
}

- (void)observeTouch:(UITouch *)touch
{
    if(!self.selectionDisabled) {
        NSSet *touchSet = [NSSet setWithObject:touch];
        switch(touch.phase) {
            case UITouchPhaseBegan:
                [self touchesBegan:touchSet];
                break;
            case UITouchPhaseMoved: 
                [self touchesMoved:touchSet];
                break;
            case UITouchPhaseEnded:
                [self touchesEnded:touchSet];
                break;
            case UITouchPhaseCancelled:
            default:
                [self touchesCancelled:touchSet];
                break;
        }
    }
}

- (void)setShouldHideMenu:(BOOL)shouldHideMenu
{
    if(shouldHideMenu != _shouldHideMenu) {
        _shouldHideMenu = shouldHideMenu;
        EucMenuController *menuController = self.menuController;
        if(menuController && self.menuShouldBeAvailable) {
            if(menuController.menuVisible && shouldHideMenu) {
                [menuController setMenuVisible:NO animated:YES];
            } else if(!menuController.menuVisible && !shouldHideMenu) {
                [self _positionMenu];
                [menuController setMenuVisible:YES animated:YES];
            }
        }
    }
}


- (CGImageRef)_cgImageNamed:(NSString *)name
{
    NSData *data = [[NSData alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[EucSelector class]] pathForResource:name ofType:nil]];
    CGImageRef ret = CGImageRetain([UIImage imageWithData:data].CGImage);
    [data release];
    return (CGImageRef)[(id)ret autorelease];
}

@end
