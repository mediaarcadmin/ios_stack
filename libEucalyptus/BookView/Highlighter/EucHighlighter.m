//
//  EucHighlighter.m
//  libEucalyptus
//
//  Created by James Montgomerie on 20/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "EucHighlighter.h"
#import "EucHighlighterOverlayView.h"
#import "THGeometryUtils.h"
#import "THEventCapturingWindow.h"
#import "THPair.h"
#import "THImageFactory.h"
#import "THLog.h"

static const CGFloat sLoupePopDuration = 0.05f;

@interface EucHighlighter ()

@property (nonatomic, retain) UIView *attachedView;

@property (nonatomic, retain) NSMutableArray *temporaryHighlightLayers;

@property (nonatomic, retain) UITouch *trackingTouch;
@property (nonatomic, assign) BOOL trackingTouchHasMoved;
@property (nonatomic, assign, getter=isTracking) BOOL tracking;
@property (nonatomic, assign) EucHighlighterTrackingStage trackingStage;

@property (nonatomic, retain) UIView *viewWithSelection;
@property (nonatomic, retain) UIImageView *loupeView;

@property (nonatomic, retain) NSMutableArray *highlightLayers;
@property (nonatomic, retain) THPair *highlightEndLayers;
@property (nonatomic, retain) THPair *highlightKnobLayers;

@property (nonatomic, retain) CALayer *draggingKnob;

- (CGImageRef)magnificationLoupeImage;
- (void)_trackTouch:(UITouch *)touch;

@end

@implementation EucHighlighter

@synthesize dataSource = _dataSource;

@synthesize attachedView = _attachedView;

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


- (void)dealloc
{
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
        if([window isKindOfClass:[THEventCapturingWindow class]]) {
            [window addTouchObserver:self forView:view];
        }
    }
    self.attachedView = view;
}

- (void)detatchFromView
{
    UIView *attachedView = self.attachedView;
    for(THEventCapturingWindow *window in [[UIApplication sharedApplication] windows]) {
        if([window isKindOfClass:[THEventCapturingWindow class]]) {
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
        if([name isEqualToString:@"EucHighlighterLoupePopDown"]) {
            [[anim valueForKey:@"THView"] removeFromSuperview];
        } else if([name isEqualToString:@"EucHighlighterEndOfLineHighlight"]) {
            [[anim valueForKey:@"THLayer"] removeFromSuperlayer];
        }
    }
}

#pragma mark -
#pragma mark Temporary Highlights

- (void)temporarilyHighlightElementWithIdentfier:(id)elementId inBlockWithIdentifier:(id)blockId animated:(BOOL)animated;
{    
    NSArray *rects = [self.dataSource eucHighlighter:self
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
        
        [animationGroup setValue:@"EucHighlighterEndOfLineHighlight" forKey:@"THName"];
        [animationGroup setValue:layer forKey:@"THLayer"];
        [layer addAnimation:animationGroup forKey:@"EucHighlighterEndOfLineHighlight"]; 
        
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
        NSData *data = [[NSData alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[EucHighlighter class]] pathForResource:@"MagnificationLoupe" ofType:@"png"]];
        _magnificationLoupeImage = CGImageRetain([UIImage imageWithData:data].CGImage);
        [data release];
    }
    return _magnificationLoupeImage;
}

- (THPair *)highlightEndLayers
{
    if(!_highlightEndLayers)  {
        NSData *imageData = [[NSData alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[EucHighlighter class]] pathForResource:@"SelectionEnd" ofType:@"png"]];

        CGImageRef endImage = [UIImage imageWithData:imageData].CGImage;
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
        NSData *imageData = [[NSData alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[EucHighlighter class]] pathForResource:@"SelectionKnob" ofType:@"png"]];
        
        CGImageRef knobImage = [UIImage imageWithData:imageData].CGImage;
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

    
    THPair *highlightEndLayers = self.highlightEndLayers;
    THPair *highlightKnobLayers = self.highlightKnobLayers;
 
    CALayer *leftHighlightLayer = [self.highlightLayers objectAtIndex:0];
    
    CALayer *leftEndLayer = highlightEndLayers.first;
    [leftHighlightLayer addSublayer:leftEndLayer];
    CGRect leftEndBounds = leftEndLayer.bounds;
    CGFloat leftSelectionHeight = leftHighlightLayer.bounds.size.height;
    leftEndBounds.size.height = leftSelectionHeight;
    leftEndLayer.bounds = leftEndBounds;
    leftEndLayer.position = CGPointMake(-1.0f, leftSelectionHeight * 0.5f);
    leftEndLayer.hidden = NO;
    
    CALayer *leftKnobLayer = highlightKnobLayers.first;
    [leftHighlightLayer addSublayer:leftKnobLayer];
    leftKnobLayer.position = CGPointMake(-1.5f, -4.5f);
    leftKnobLayer.hidden = NO;
    
    CALayer *rightHighlightLayer = [self.highlightLayers lastObject];
    CALayer *rightEndLayer = highlightEndLayers.second;
    [rightHighlightLayer addSublayer:rightEndLayer];
    CGRect rightEndBounds = rightEndLayer.bounds;
    CGSize rightSelectionSize = rightHighlightLayer.bounds.size;
    rightEndBounds.size.height = rightSelectionSize.height;
    rightEndLayer.bounds = rightEndBounds;
    rightEndLayer.position = CGPointMake(rightSelectionSize.width + 2.0f, rightSelectionSize.height * 0.5f);
    rightEndLayer.hidden = NO;
    
    CALayer *rightKnobLayer = highlightKnobLayers.second;
    [rightHighlightLayer addSublayer:rightKnobLayer];
    rightKnobLayer.position = CGPointMake(rightSelectionSize.width + 1.5f, rightSelectionSize.height + 7.5f);
    rightEndLayer.hidden = NO;

    [CATransaction commit];
}

- (void)_loupeToPoint:(CGPoint)point;
{
    CGImageRef magnificationLoupeImage = self.magnificationLoupeImage;
    CGSize magnificationLoupeSize = CGSizeMake(CGImageGetWidth(magnificationLoupeImage),
                                               CGImageGetHeight(magnificationLoupeImage));

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
        [self.viewWithSelection.window addSubview:loupeView];
        
        CABasicAnimation *loupePopUp = [[CABasicAnimation alloc] init];
        loupePopUp.keyPath = @"transform";
        CATransform3D fromTransform = CATransform3DMakeTranslation(0, magnificationLoupeSize.height / 2.0f, 0);
        fromTransform = CATransform3DScale(fromTransform, 
                                           1.0f / magnificationLoupeSize.width,
                                           1.0f / magnificationLoupeSize.height,
                                           1.0f);
        loupePopUp.fromValue = [NSValue valueWithCATransform3D:fromTransform];
        loupePopUp.duration = sLoupePopDuration;
        [loupeView.layer addAnimation:loupePopUp forKey:@"EucHighlighterLoupePopUp"];
        [loupePopUp release];
    }
        
    CGSize viewWithSelectionSize = self.viewWithSelection.bounds.size;
    THImageFactory *loupeContentsFactory = [[THImageFactory alloc] initWithSize:magnificationLoupeSize];
    CGContextRef context = loupeContentsFactory.CGContext;

    // First, draw the magnified view.  We use renderInContents on the 
    // view's layer.
    CGContextSaveGState(context);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    // Scale the context by 1.25 and translate it so that we can draw the view
    // in the correct place.
    CGContextScaleCTM(context, 1.25f, -1.25f);
    
    // '* 0.8' below to cunteract the 1.25X scaling.
    CGPoint translationPoint = CGPointMake(-point.x + magnificationLoupeSize.width * (0.5f * 0.8f), 
                                           -point.y - magnificationLoupeSize.width * (0.5f * 0.8f));
    
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
    
    // Position the loupe.
    CGRect frame = loupeView.frame;
    frame.origin.x = point.x - (frame.size.width / 2.0f);
    frame.origin.y = point.y - frame.size.height + 3;
    
    // Make sure the loupe doesn't go too far off the top of the screen so that 
    // the user can still see the middle of it.
    frame.origin.y = MAX(frame.origin.y, floorf(-magnificationLoupeSize.height * 0.33));
    loupeView.frame = [self.viewWithSelection convertRect:frame toView:loupeView.superview];
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
    [loupePopDown setValue:@"EucHighlighterLoupePopDown" forKey:@"THName"];
    [loupePopDown setValue:loupeView forKey:@"THView"];
    [loupeViewLayer addAnimation:loupePopDown forKey:@"EucHighlighterLoupePopDown"];
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

- (void)setTrackingStage:(EucHighlighterTrackingStage)stage;
{
    if(stage != _trackingStage) {
        EucHighlighterTrackingStage previousStage = _trackingStage;
        _trackingStage = stage;
        
        if(previousStage == EucHighlighterTrackingStageFirstSelection) {
            [self _removeLoupe];
        } else if(previousStage == EucHighlighterTrackingStageFirstSelection) {
            self.draggingKnob = nil;
        }

        switch(stage) {
            case EucHighlighterTrackingStageNone:
            {
                [self _removeAllHighlightLayers];
                if(self.viewWithSelection != self.attachedView) {
                    [(THEventCapturingWindow *)self.viewWithSelection.window removeTouchObserver:self forView:self.viewWithSelection];
                    [self.viewWithSelection removeFromSuperview];
                    self.viewWithSelection = nil;
                }
                self.tracking = NO;
                
                break;
            } 
            case EucHighlighterTrackingStageFirstSelection:
            {
                if(previousStage == EucHighlighterTrackingStageNone) {
                    if([self.dataSource respondsToSelector:@selector(viewSnapshotImageForEucHighlighter:)]) {
                        UIView *attachedView = self.attachedView;
                        UIImageView *dummySelectionView = [[UIImageView alloc] initWithImage:[self.dataSource viewSnapshotImageForEucHighlighter:self]];
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
            case EucHighlighterTrackingStageSelectedAndWaiting:
            {
                // Clean up extraneous highlighting layers.
                NSMutableArray *highlightLayers = self.highlightLayers;
                for(CALayer *layer = [highlightLayers lastObject]; layer.isHidden; layer = [highlightLayers lastObject]) {
                    [layer removeFromSuperlayer];
                    [highlightLayers removeLastObject];
                }
                [self _positionKnobs]; 
                
                break;   
            }
            case EucHighlighterTrackingStageChangingSelection:
            {                
                break;
            } 
        }
    }
}

- (NSArray *)_highlightRectsForPoint:(CGPoint)point
{
    id<EucHighlighterDataSource> dataSource = self.dataSource;
    for(id blockId in [dataSource blockIdentifiersForEucHighlighter:self]) {
        if(CGRectContainsPoint([dataSource eucHighlighter:self frameOfBlockWithIdentifier:blockId], point)) {
            for(id elementId in [dataSource eucHighlighter:self identifiersForElementsOfBlockWithIdentifier:blockId]) {
                NSArray *rectsForElement = [dataSource eucHighlighter:self rectsForElementWithIdentifier:elementId ofBlockWithIdentifier:blockId];
                for(NSValue *rectValue in rectsForElement) {
                    if(CGRectContainsPoint([rectValue CGRectValue], point)) {
                        return rectsForElement;
                    }
                }
            }
        }
    }
    return nil;
}

- (void)_trackTouch:(UITouch *)touch
{
    if(self.trackingStage == EucHighlighterTrackingStageFirstSelection) {
        UIView *viewWithSelection = self.viewWithSelection;
        CGPoint location = [touch locationInView:viewWithSelection];
        
        NSArray *highlightRects = [self _highlightRectsForPoint:location];
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
                for(NSUInteger i = unusedHighlightLayersCount; i < highlightRectsCount; ++i) {
                    CALayer *layer = [[CALayer alloc] init];
                    layer.backgroundColor = [[UIColor colorWithRed:47.0f/255.0f green:102.0f/255.0f blue:179.0f/255.0f alpha:0.2f] CGColor];
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
            ((CALayer *)[highlightLayers objectAtIndex:highlightRectsCount + i]).hidden = YES;
        }
        
        [CATransaction commit];

        [self _loupeToPoint:location];
    }
}

- (void)_startSelection
{
    self.trackingStage = EucHighlighterTrackingStageFirstSelection;
    
    // This is cheating a bit...
    self.trackingTouchHasMoved = YES;
}

- (CALayer *)_knobForTouch:(UITouch *)touch
{
    CALayer *ret = nil;
    
    THPair *highlightKnobLayers = self.highlightKnobLayers;
    if(highlightKnobLayers) {
        CALayer *leftKnobLayer = self.highlightKnobLayers.first;
        if(!leftKnobLayer.hidden) {
            UIView *viewWithSelection = self.viewWithSelection;
            CALayer *viewWithSelectionLayer = viewWithSelection.layer;
            
            CGPoint touchPoint = [touch locationInView:viewWithSelection];
            CGRect leftKnobRect = [leftKnobLayer convertRect:leftKnobLayer.bounds toLayer:viewWithSelectionLayer];

            if(CGRectContainsPoint(leftKnobRect, touchPoint)) {
                ret = leftKnobLayer;
            } else {
                CALayer *rightKnobLayer = self.highlightKnobLayers.second;
                CGRect rightKnobRect = [rightKnobLayer convertRect:rightKnobLayer.bounds toLayer:viewWithSelectionLayer];
                if(CGRectContainsPoint(rightKnobRect, touchPoint)) {
                    ret = rightKnobLayer;
                }
            }
        }
    }
    return ret;
}

- (void)observeTouch:(UITouch *)touch
{
    UITouch *trackingTouch = self.trackingTouch;
    UITouchPhase phase = touch.phase;
    BOOL currentlyTracking = self.isTracking;
    
    if(!trackingTouch && phase == UITouchPhaseBegan) {
        self.trackingTouch = touch;
        self.trackingTouchHasMoved = NO;
        if(!currentlyTracking || 
           !(self.draggingKnob = [self _knobForTouch:touch])) {
            [self performSelector:@selector(_startSelection) withObject:nil afterDelay:0.5f];
        } else {
            if(self.draggingKnob) {
                self.trackingStage = EucHighlighterTrackingStageChangingSelection;
                [self _trackTouch:touch];
            } 
        }
    } else if(touch == trackingTouch) {
        if(!currentlyTracking || 
           (self.trackingStage == EucHighlighterTrackingStageSelectedAndWaiting && !self.draggingKnob)) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_startSelection) object:nil];
            self.trackingTouch = nil;
            self.trackingStage = EucHighlighterTrackingStageNone;
        } else {        
            if(phase == UITouchPhaseMoved) { 
                self.trackingTouchHasMoved = YES;
                [self _trackTouch:touch];
            } else if(phase == UITouchPhaseEnded || phase == UITouchPhaseCancelled) {
                [self _trackTouch:touch];
                if(self.trackingTouchHasMoved && self.highlightLayers.count && !((CALayer *)[self.highlightLayers objectAtIndex:0]).isHidden) {
                    self.trackingStage = EucHighlighterTrackingStageSelectedAndWaiting;
                } else {
                    self.trackingStage = EucHighlighterTrackingStageNone;
                }
                self.trackingTouch = nil;
            }
        }
    }
}

@end
