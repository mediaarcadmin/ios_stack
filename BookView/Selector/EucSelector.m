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
#import "THUIViewAdditions.h"
#import "THPair.h"
#import "THImageFactory.h"
#import "THLog.h"

static const CGFloat sLoupePopDuration = 0.05f;

@interface EucSelector ()

@property (nonatomic, retain) UIView *attachedView;

@property (nonatomic, retain) NSMutableArray *temporaryHighlightLayers;

@property (nonatomic, retain) UITouch *trackingTouch;
@property (nonatomic, assign) BOOL trackingTouchHasMoved;
@property (nonatomic, assign, getter=isTracking) BOOL tracking;
@property (nonatomic, assign) EucSelectorTrackingStage trackingStage;

@property (nonatomic, retain) UIView *viewWithSelection;
@property (nonatomic, retain) UIImageView *loupeView;

@property (nonatomic, retain) NSMutableArray *highlightLayers;
@property (nonatomic, retain) THPair *highlightEndLayers;
@property (nonatomic, retain) THPair *highlightKnobLayers;

@property (nonatomic, retain) CALayer *draggingKnob;
@property (nonatomic, assign) CGFloat draggingKnobVerticalOffset;

@property (nonatomic, retain) EucMenuController *menuController;
@property (nonatomic, assign) BOOL menuShouldBeAvailable;

- (CGImageRef)magnificationLoupeImage;
- (void)_trackTouch:(UITouch *)touch;

@end

@implementation EucSelector

@synthesize shouldSniffTouches = _shouldSniffTouches;
@synthesize selectionDisabled = _selectionDisabled;

@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;

@synthesize attachedView = _attachedView;

@synthesize selectedRange = _selectedRange;

@synthesize temporaryHighlightLayers = _temporaryHighlightLayers;

@synthesize trackingTouch = _trackingTouch;
@synthesize trackingTouchHasMoved = _trackingTouchHasMoved;
@synthesize tracking = _tracking;
@synthesize trackingStage = _trackingStage;

@synthesize viewWithSelection = _viewWithSelection;
@synthesize loupeView = _loupeView;

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
    if(self.attachedView) {
        THWarn(@"Highlighter released while still attached to view.");
        [self detatchFromView];
    }
    [_trackingTouch release];
    if(_magnificationLoupeImage) {
        CGImageRelease(_magnificationLoupeImage);
    }    
    
    [super dealloc];
}

- (void)attachToView:(UIView *)view
{
    if(self.attachedView) {
        [self detatchFromView];
    }
    for(THEventCapturingWindow *window in [[UIApplication sharedApplication] windows]) {
        if(self.shouldSniffTouches && [window isKindOfClass:[THEventCapturingWindow class]]) {
            [window addTouchObserver:self forView:view];
        }
    }
    self.attachedView = view;
}

- (void)detatchFromView
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
        if(self.shouldSniffTouches && [window isKindOfClass:[THEventCapturingWindow class]]) {
            [window removeTouchObserver:self forView:attachedView];
        }
    }    
}

#pragma mark -
#pragma mark CAAnimation Delegate Methods

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{   
    NSString *name = [anim valueForKey:@"THName"];
    if(name) {
        if([name isEqualToString:@"EucSelectorLoupePopDown"]) {
            [[anim valueForKey:@"THView"] removeFromSuperview];
        } else if([name isEqualToString:@"EucSelectorEndOfLineHighlight"]) {
            [[anim valueForKey:@"THLayer"] removeFromSuperlayer];
        }
    }
}

#pragma mark -
#pragma mark Temporary Highlights

- (void)temporarilyHighlightElementWithIdentfier:(id)elementId inBlockWithIdentifier:(id)blockId animated:(BOOL)animated;
{    
    NSArray *rects = [self.dataSource eucSelector:self
                       rectsForElementWithIdentifier:elementId
                               ofBlockWithIdentifier:blockId];
    
    NSMutableArray *temporaryHilightLayers = self.temporaryHighlightLayers;
    NSMutableArray *newTemporaryHighlightLayers = [[NSMutableArray alloc] initWithCapacity:2];
    
    CALayer *attachedViewLayer = self.attachedView.layer;
    
    for(NSValue *rectValue in rects) {
        CGRect rect = [rectValue CGRectValue];
        
        CGPoint newCenter = CGPointMake(rect.origin.x + (rect.size.width / 2.0f), rect.origin.y + (rect.size.height / 2.0f));
        CALayer *layer = nil;
        if(temporaryHilightLayers.count) {
            CGFloat bestDistance = CGFLOAT_MAX;
            for(CALayer *prospectiveLayer in temporaryHilightLayers) {
                CGPoint prospectiveCenter = prospectiveLayer.position;
                if(prospectiveCenter.x < newCenter.x) {
                    CGFloat thisDistance = CGPointDistance(prospectiveCenter, newCenter);
                    if(thisDistance < bestDistance) {
                        bestDistance = thisDistance;
                        layer = [prospectiveLayer retain];
                    }
                }
            }
        } 
        rect.size.width += 4;
        rect.size.height += 4;
        
        if(layer) {
            [temporaryHilightLayers removeObject:layer];
        } else {                 
            layer = [[CALayer alloc] init];
            layer.cornerRadius = 4;
            layer.backgroundColor = [[[UIColor blueColor] colorWithAlphaComponent:0.25f] CGColor];
            layer.position = CGPointMake(newCenter.x - rect.size.width / 2.0f + 1.0f, newCenter.y);
            layer.bounds = CGRectMake(0, 0, 1, rect.size.height);
            [attachedViewLayer addSublayer:layer];              
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
    for(CALayer *layer in temporaryHilightLayers) {
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
}

- (void)removeTemporaryHighlight
{
    for(CALayer *layer in self.temporaryHighlightLayers) {
        [layer removeFromSuperlayer];
    }
    self.temporaryHighlightLayers = nil;
}



#pragma mark -
#pragma mark Selection

- (CGImageRef)magnificationLoupeImage
{
    if(!_magnificationLoupeImage) {
        NSData *data = [[NSData alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[EucSelector class]] pathForResource:@"MagnificationLoupe" ofType:@"png"]];
        _magnificationLoupeImage = CGImageRetain([UIImage imageWithData:data].CGImage);
        [data release];
    }
    return _magnificationLoupeImage;
}

- (THPair *)highlightEndLayers
{
    if(!_highlightEndLayers)  {
        NSData *imageData = [[NSData alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[EucSelector class]] pathForResource:@"SelectionEnd" ofType:@"png"]];
        CGImageRef endImage = [UIImage imageWithData:imageData].CGImage;
        [imageData release];
        
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
        NSData *imageData = [[NSData alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[EucSelector class]] pathForResource:@"SelectionKnob" ofType:@"png"]];
        CGImageRef knobImage = [UIImage imageWithData:imageData].CGImage;
        [imageData release];
        
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
    // at the correct size on screen even if the view they're part of is zoomed.
    CGSize scaleFactors = [self.attachedView screenScaleFactors];
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

- (void)_loupeToPoint:(CGPoint)point;
{
    CGImageRef magnificationLoupeImage = self.magnificationLoupeImage;
    CGSize magnificationLoupeSize = CGSizeMake(CGImageGetWidth(magnificationLoupeImage),
                                               CGImageGetHeight(magnificationLoupeImage));

    UIWindow *window = self.viewWithSelection.window;
    UIImageView *loupeView = self.loupeView;
    if(!self.loupeView) {
        // Create an imageView that will hold the magnified image.
        // If this isn't performant, we can replace this method with a 
        // loupe UIView subclass that draws like below in its drawrect.
        loupeView = [[UIImageView alloc] initWithFrame:CGRectMake(point.x, point.y, 
                                                                  magnificationLoupeSize.width, 
                                                                  magnificationLoupeSize.height)];
        self.loupeView = loupeView;
        // Don't add it to self.viewWithSelection - we're using renderInContext:
        // below, so the effect would be an infinite tunnel after a few moves.
        [window addSubview:loupeView];
        
        CABasicAnimation *loupePopUp = [[CABasicAnimation alloc] init];
        loupePopUp.keyPath = @"transform";
        CATransform3D fromTransform = CATransform3DMakeTranslation(0, magnificationLoupeSize.height / 2.0f, 0);
        fromTransform = CATransform3DScale(fromTransform, 
                                           1.0f / magnificationLoupeSize.width,
                                           1.0f / magnificationLoupeSize.height,
                                           1.0f);
        loupePopUp.fromValue = [NSValue valueWithCATransform3D:fromTransform];
        loupePopUp.duration = sLoupePopDuration;
        [loupeView.layer addAnimation:loupePopUp forKey:@"EucSelectorLoupePopUp"];
        [loupePopUp release];
    }
        
    CGSize viewWithSelectionSize = self.viewWithSelection.bounds.size;
    THImageFactory *loupeContentsFactory = [[THImageFactory alloc] initWithSize:magnificationLoupeSize];
    CGContextRef context = loupeContentsFactory.CGContext;

    // Work out the final scale factor of the view on screen so that we can
    // scale to bigger than that.
    CGSize screenScaleFactors = [self.attachedView screenScaleFactors];    
    
    // We want 1.25 * bigger.
    CGFloat scaleFactorX = screenScaleFactors.width * 1.25;
    CGFloat scaleFactorY = screenScaleFactors.height * 1.25;
    
    // First, draw the magnified view.  We use renderInContents on the 
    // view's layer.
    CGContextSaveGState(context);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    // Scale the context and translate it so that we can draw the view
    // in the correct place.
    CGContextScaleCTM(context, scaleFactorX, -scaleFactorY);
    
    // '* (1 / scaleFactor)' below to counteract the existing * 1.25 scaling.
    CGPoint translationPoint = CGPointMake(-point.x + magnificationLoupeSize.width * (0.5f * (1 / scaleFactorX)), 
                                           -point.y - magnificationLoupeSize.width * (0.5f * (1 / scaleFactorY)));
    
    // Don't show blank area off the bottom of the view.
    translationPoint.y = MAX(-viewWithSelectionSize.height, translationPoint.y); 
    
    CGContextTranslateCTM(context, 
                          translationPoint.x,
                          translationPoint.y);
    
    // Draw the view. 
    [[self.viewWithSelection layer] renderInContext:context];
    CGContextRestoreGState(context);
    
    // Now, mask out the loupe area.
    CGContextSetBlendMode(context, kCGBlendModeDestinationIn);
    CGContextDrawImage(context, 
                       CGRectMake(0, 0, magnificationLoupeSize.width, magnificationLoupeSize.height),
                       magnificationLoupeImage);
    
    // Draw the loupe.
    CGContextSetBlendMode(context, kCGBlendModePlusDarker);
    CGContextDrawImage(context, 
                       CGRectMake(0, 0, magnificationLoupeSize.width, magnificationLoupeSize.height),
                       magnificationLoupeImage);    
    
    // Now get the image we constructed and put it into the loupe view.
    loupeView.image = loupeContentsFactory.snapshotUIImage;
    [loupeContentsFactory release];
    
    
    CGPoint windowPoint = [self.viewWithSelection convertPoint:point toView:window];
    
    // Position the loupe.
    CGRect frame = loupeView.frame;
    frame.origin.x = windowPoint.x - (frame.size.width / 2.0f);
    frame.origin.y = windowPoint.y - frame.size.height + 3;
    
    // Make sure the loupe doesn't go too far off the top of the screen so that 
    // the user can still see the middle of it.
    frame.origin.x = MAX(0, frame.origin.x);
    frame.origin.y = MAX(frame.origin.y, floorf(-magnificationLoupeSize.height * 0.33));
    loupeView.frame = frame;
}

- (void)_removeLoupe
{
    UIImageView *loupeView = self.loupeView;
    CGSize magnificationLoupeSize = loupeView.bounds.size;

    CALayer *loupeViewLayer = loupeView.layer;
    
    CABasicAnimation *loupePopDown = [[CABasicAnimation alloc] init];
    loupePopDown.keyPath = @"transform";
    CATransform3D toTransform = CATransform3DMakeTranslation(0, magnificationLoupeSize.height / 2.0f, 0);
    toTransform = CATransform3DScale(toTransform, 1.0f / magnificationLoupeSize.width,
                                       1.0f / magnificationLoupeSize.height,
                                       1.0f);
    loupePopDown.fromValue = [NSValue valueWithCATransform3D:loupeViewLayer.transform];
    loupePopDown.toValue = [NSValue valueWithCATransform3D:toTransform];
    loupePopDown.duration = sLoupePopDuration;
    loupePopDown.delegate = self;
    [loupePopDown setValue:@"EucSelectorLoupePopDown" forKey:@"THName"];
    [loupePopDown setValue:loupeView forKey:@"THView"];
    [loupeViewLayer addAnimation:loupePopDown forKey:@"EucSelectorLoupePopDown"];
    [loupePopDown release];
    
    // Avoid popping back to full-size.
    loupeViewLayer.transform = toTransform;

    // Forget this loupe.  It will be removed from its superview in the 
    // animationDidStop callback.
    self.loupeView = nil;
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
    CGRect targetRect = [[[self highlightLayers] objectAtIndex:0] frame];
    for(CALayer *layer in self.highlightLayers) {
        if(!layer.isHidden) {
            targetRect = CGRectUnion(targetRect, layer.frame);
        }
    }
    [self.menuController setTargetRect:targetRect inView:self.viewWithSelection];
    
}

- (void)setTrackingStage:(EucSelectorTrackingStage)stage;
{
    if(stage != _trackingStage) {
        EucSelectorTrackingStage previousStage = _trackingStage;
        _trackingStage = stage;
        
        if(previousStage == EucSelectorTrackingStageFirstSelection) {
            [self _removeLoupe];
        } else if(previousStage == EucSelectorTrackingStageChangingSelection) {
            self.draggingKnob = nil;
        } else if(previousStage == EucSelectorTrackingStageSelectedAndWaiting) {
            self.menuShouldBeAvailable = NO;
            [self.menuController setMenuVisible:NO animated:YES];
        }

        switch(stage) {
            case EucSelectorTrackingStageNone:
            {
                if(self.viewWithSelection != self.attachedView) {
                    [(THEventCapturingWindow *)self.viewWithSelection.window removeTouchObserver:self forView:self.viewWithSelection];
                    [self.viewWithSelection removeFromSuperview];
                    self.viewWithSelection = nil;
                }
                [self _removeAllHighlightLayers];
                self.tracking = NO;
                break;
            } 
            case EucSelectorTrackingStageFirstSelection:
            {
                if(previousStage == EucSelectorTrackingStageNone) {
                    if([self.dataSource respondsToSelector:@selector(viewSnapshotImageForEucSelector:)]) {
                        UIView *attachedView = self.attachedView;
                        UIImageView *dummySelectionView = [[UIImageView alloc] initWithImage:[self.dataSource viewSnapshotImageForEucSelector:self]];
                        dummySelectionView.frame = attachedView.frame;
                        [attachedView.superview insertSubview:dummySelectionView aboveSubview:attachedView];
                        [(THEventCapturingWindow *)dummySelectionView.window addTouchObserver:self forView:dummySelectionView];
                        self.viewWithSelection = dummySelectionView;
                        [dummySelectionView release];
                    } else {
                        self.viewWithSelection = self.attachedView;
                    }                                
                    self.tracking = YES;
                } else {
                    [self _removeAllHighlightLayers];
                }
                [self _trackTouch:self.trackingTouch];
                break;
            } 
            case EucSelectorTrackingStageSelectedAndWaiting:
            {
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
                break;
            } 
        }
    }
}

- (THPair *)_blockAndElementIdsAndHighlightRectsForPoint:(CGPoint)point
{
    id<EucSelectorDataSource> dataSource = self.dataSource;
    for(id blockId in [dataSource blockIdentifiersForEucSelector:self]) {
        if(CGRectContainsPoint([dataSource eucSelector:self frameOfBlockWithIdentifier:blockId], point)) {
            for(id elementId in [dataSource eucSelector:self identifiersForElementsOfBlockWithIdentifier:blockId]) {
                NSArray *rectsForElement = [dataSource eucSelector:self rectsForElementWithIdentifier:elementId ofBlockWithIdentifier:blockId];
                for(NSValue *rectValue in rectsForElement) {
                    if(CGRectContainsPoint([rectValue CGRectValue], point)) {
                        return [THPair pairWithFirst:[THPair pairWithFirst:blockId second:elementId] 
                                              second:rectsForElement];
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
    
    id<EucSelectorDataSource> dataSource = self.dataSource;
    for(id blockId in [dataSource blockIdentifiersForEucSelector:self]) {
        for(id elementId in [dataSource eucSelector:self identifiersForElementsOfBlockWithIdentifier:blockId]) {
            NSArray *rectsForElement = [dataSource eucSelector:self rectsForElementWithIdentifier:elementId ofBlockWithIdentifier:blockId];
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


+ (NSArray *)coalescedLineRectsForElementRects:(NSArray *)elementRects inView:(UIView *)view 
{
    // We'll scale the rects to make sure they will be on pixl boundies
    // on screen even if the layer they're in has a scale transform applied.
    CGSize screenScaleFactors = [view screenScaleFactors];        
        
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
                   [ret addObject:[NSValue valueWithCGRect:CGRectScreenIntegral(currentLineRect, screenScaleFactors)]];
                   currentLineRect = thisRect;
               }
        }
    }
    if(!CGRectEqualToRect(currentLineRect, CGRectZero)) {
        [ret addObject:[NSValue valueWithCGRect:CGRectScreenIntegral(currentLineRect, screenScaleFactors)]];
    }   
    return ret;
}

- (NSArray *)highlightRectsForRange:(EucSelectorRange *)selectedRange 
                       inDataSource:(id<EucSelectorDataSource>)dataSource 
                            forView:(UIView *)view 
{                                      
    NSArray *blockIds = [dataSource blockIdentifiersForEucSelector:self];
    NSUInteger blockIdIndex = 0;
    
    NSMutableArray *nonCoalescedRects = [NSMutableArray array];
    
    id startBlockId = selectedRange.startBlockId;
    id endBlockId = selectedRange.endBlockId;
    id startElementId = selectedRange.startElementId;
    id endElementId = selectedRange.endElementId;
    
    while([[blockIds objectAtIndex:blockIdIndex] compare:startBlockId] == NSOrderedAscending) {
        ++blockIdIndex;
    }
    BOOL isFirstBlock = YES;
    BOOL isLastBlock = NO;
    do {
        id blockId = [blockIds objectAtIndex:blockIdIndex];
        
        NSArray *elementIds = [dataSource eucSelector:self identifiersForElementsOfBlockWithIdentifier:blockId];
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
            [nonCoalescedRects addObjectsFromArray:[dataSource eucSelector:self 
                                             rectsForElementWithIdentifier:elementId
                                                     ofBlockWithIdentifier:blockId]];
            ++elementIdIndex;
        } while (isLastBlock ? 
                 ([elementId compare:endElementId] < NSOrderedSame) : 
                 elementIdIndex < elementIdCount);
        ++blockIdIndex;
    } while(!isLastBlock);
    
    return [[self class] coalescedLineRectsForElementRects:nonCoalescedRects inView:view];
}

- (void)redisplaySelectedRange
{
    EucSelectorRange *selectedRange = self.selectedRange;
    if(selectedRange) {
        id<EucSelectorDataSource> dataSource = self.dataSource;
        
        // Work out he rects to highlight
        NSArray *highlightRects = [self highlightRectsForRange:selectedRange 
                                                  inDataSource:dataSource 
                                                       forView:self.attachedView];
        
        // Highlight them, reusing the current highlight layers if possible.
        UIView *viewWithSelection = self.viewWithSelection;
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
                CGColorRef highlightColor = [[UIColor colorWithRed:47.0f/255.0f green:102.0f/255.0f blue:179.0f/255.0f alpha:0.2f] CGColor];
                for(NSUInteger i = unusedHighlightLayersCount; i < highlightRectsCount; ++i) {
                    CALayer *layer = [[CALayer alloc] init];
                    layer.backgroundColor = highlightColor;
                    [highlightLayers addObject:layer];
                    ++unusedHighlightLayersCount;
                    [layer release];
                    [viewWithSelection.layer addSublayer:layer];
                }
            }
        } 
                
        for(NSUInteger i = 0; i < highlightRectsCount; ++i) {
            CALayer *layer = [highlightLayers objectAtIndex:i];
            NSValue *rectValue = [highlightRects objectAtIndex:i];
            layer.frame = [rectValue CGRectValue];
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
        [_selectedRange release];
        _selectedRange = [newRange retain];
        if(newRange) {
            [self redisplaySelectedRange];
        } else {
            if(self.trackingStage == EucSelectorTrackingStageFirstSelection) {
                [CATransaction begin];
                [CATransaction setValue:(id)kCFBooleanTrue forKey: kCATransactionDisableActions];
                for(CALayer *layer in self.highlightLayers) {
                    layer.hidden = YES;
                }      
                [CATransaction commit];
            } else {
                [self setTrackingStage:EucSelectorTrackingStageNone];
            }
        }
    }
}

- (BOOL)selectedRangeIsHighlight
{
    return NO;
}

- (void)_trackTouch:(UITouch *)touch
{       
    UIView *viewWithSelection = self.viewWithSelection;
    CGPoint location = [touch locationInView:viewWithSelection];

    EucSelectorRange *newSelectedRange = nil;
    
    if(self.trackingStage == EucSelectorTrackingStageFirstSelection) {   
        THPair *blockAndElementAndHighlightRects = [self _blockAndElementIdsAndHighlightRectsForPoint:location];
        THPair *blockAndElementIds = blockAndElementAndHighlightRects.first;
        
        if(blockAndElementIds) {
            newSelectedRange = [[EucSelectorRange alloc] init];
            id blockId = blockAndElementIds.first;
            id elementId = blockAndElementIds.second;
            
            newSelectedRange.startBlockId = blockId;
            newSelectedRange.endBlockId = blockId;
            newSelectedRange.startElementId = elementId;
            newSelectedRange.endElementId = elementId;
        }
    } else {
        location.y += self.draggingKnobVerticalOffset;
        THPair *closestBlockAndElement = [self _closestBlockAndElementIdsForPoint:location];
        
        if(closestBlockAndElement) {
            newSelectedRange = [[EucSelectorRange alloc] init];
            
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
        }
    }
        
    self.selectedRange = newSelectedRange;
    [newSelectedRange release];
    
    if(self.trackingStage == EucSelectorTrackingStageFirstSelection) {   
        [self _loupeToPoint:location];
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
            UIView *viewWithSelection = self.viewWithSelection;
            CALayer *viewWithSelectionLayer = viewWithSelection.layer;
            
            CGPoint touchPoint = [touch locationInView:viewWithSelection];
            CGRect leftKnobRect = [leftKnobLayer convertRect:CGRectInset(leftKnobLayer.bounds, -8.0f, -8.0f) toLayer:viewWithSelectionLayer];

            if(CGRectContainsPoint(leftKnobRect, touchPoint)) {
                draggingKnob = leftKnobLayer;
                CALayer *endLayer = self.highlightEndLayers.first;
                CGPoint endLayerCenter = [endLayer convertPoint:endLayer.position toLayer:viewWithSelectionLayer];
                draggingKnobVerticalOffset = endLayerCenter.y - touchPoint.y;
            } else {
                CALayer *rightKnobLayer = self.highlightKnobLayers.second;
                CGRect rightKnobRect = [rightKnobLayer convertRect:CGRectInset(rightKnobLayer.bounds, -8.0f, -8.0f) toLayer:viewWithSelectionLayer];
                if(CGRectContainsPoint(rightKnobRect, touchPoint)) {
                    draggingKnob = rightKnobLayer;
                    CALayer *endLayer = self.highlightEndLayers.second;
                    CGPoint endLayerCenter = [endLayer convertPoint:endLayer.position toLayer:viewWithSelectionLayer];
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
            if(self.trackingTouchHasMoved && self.highlightLayers.count && !((CALayer *)[self.highlightLayers objectAtIndex:0]).isHidden) {
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
    [self touchesEnded:touches];
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

@end
