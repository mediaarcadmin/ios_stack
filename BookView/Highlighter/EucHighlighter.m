//
//  EucHighlighter.m
//  libEucalyptus
//
//  Created by James Montgomerie on 20/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "EucHighlighter.h"
#import "EucHighlighterRange.h"
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
@property (nonatomic, assign) CGFloat draggingKnobVerticalOffset;

- (CGImageRef)magnificationLoupeImage;
- (void)_trackTouch:(UITouch *)touch;

@end

@implementation EucHighlighter

@synthesize shouldSniffTouches = _shouldSniffTouches;
@synthesize selectionDisabled = _selectionDisabled;

@synthesize dataSource = _dataSource;

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
        NSData *imageData = [[NSData alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[EucHighlighter class]] pathForResource:@"SelectionKnob" ofType:@"png"]];
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

    NSArray *highlightLayers = self.highlightLayers;
    
    THPair *highlightEndLayers = self.highlightEndLayers;
    THPair *highlightKnobLayers = self.highlightKnobLayers;
 
    CALayer *leftHighlightLayer = [highlightLayers objectAtIndex:0];
    
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
    
    CALayer *rightHighlightLayer = [highlightLayers lastObject];
    for(NSUInteger i = highlightLayers.count - 2; rightHighlightLayer.isHidden; --i) {
        rightHighlightLayer = [highlightLayers objectAtIndex:i];
    }
    
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
    
    
    CGPoint superviewPoint = [self.viewWithSelection convertPoint:point toView:loupeView.superview];
    
    // Position the loupe.
    CGRect frame = loupeView.frame;
    frame.origin.x = superviewPoint.x - (frame.size.width / 2.0f);
    frame.origin.y = superviewPoint.y - frame.size.height + 3;
    
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
        } else if(previousStage == EucHighlighterTrackingStageChangingSelection) {
            self.draggingKnob = nil;
        }

        switch(stage) {
            case EucHighlighterTrackingStageNone:
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

- (THPair *)_blockAndElementIdsAndHighlightRectsForPoint:(CGPoint)point
{
    id<EucHighlighterDataSource> dataSource = self.dataSource;
    for(id blockId in [dataSource blockIdentifiersForEucHighlighter:self]) {
        if(CGRectContainsPoint([dataSource eucHighlighter:self frameOfBlockWithIdentifier:blockId], point)) {
            for(id elementId in [dataSource eucHighlighter:self identifiersForElementsOfBlockWithIdentifier:blockId]) {
                NSArray *rectsForElement = [dataSource eucHighlighter:self rectsForElementWithIdentifier:elementId ofBlockWithIdentifier:blockId];
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
    
    id<EucHighlighterDataSource> dataSource = self.dataSource;
    for(id blockId in [dataSource blockIdentifiersForEucHighlighter:self]) {
        for(id elementId in [dataSource eucHighlighter:self identifiersForElementsOfBlockWithIdentifier:blockId]) {
            NSArray *rectsForElement = [dataSource eucHighlighter:self rectsForElementWithIdentifier:elementId ofBlockWithIdentifier:blockId];
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

- (void)setSelectedRange:(EucHighlighterRange *)newRange
{
    if(newRange && ![newRange isEqual:_selectedRange]) {        
        id<EucHighlighterDataSource> dataSource = self.dataSource;
        
        // Work out he rects to highlight
        NSMutableArray *highlightRects = [[NSMutableArray alloc] init];
        
        NSArray *blockIds = [dataSource blockIdentifiersForEucHighlighter:self];
        NSUInteger blockIdIndex = 0;
        
        id startBlockId = newRange.startBlockId;
        id endBlockId = newRange.endBlockId;
        id startElementId = newRange.startElementId;
        id endElementId = newRange.endElementId;

        while([[blockIds objectAtIndex:blockIdIndex] compare:startBlockId] == NSOrderedAscending) {
            ++blockIdIndex;
        }
        BOOL isFirstBlock = YES;
        BOOL isLastBlock = NO;
        BOOL isFirstElement = YES;
        CGRect currentLineRect = CGRectZero;
        do {
            id blockId = [blockIds objectAtIndex:blockIdIndex];
                        
            NSArray *elementIds = [dataSource eucHighlighter:self identifiersForElementsOfBlockWithIdentifier:blockId];
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
                for(NSValue *rectValue in [dataSource eucHighlighter:self rectsForElementWithIdentifier:elementId ofBlockWithIdentifier:blockId]) {
                    CGRect thisRect = [rectValue CGRectValue];
                    if(isFirstElement) {
                        currentLineRect = thisRect;
                        isFirstElement = NO;
                    } else {
                        if((currentLineRect.origin.y <= thisRect.origin.y && currentLineRect.origin.y + currentLineRect.size.height > thisRect.origin.y) ||
                           (currentLineRect.origin.y <= thisRect.origin.y + thisRect.size.height  && currentLineRect.origin.y + currentLineRect.size.height > thisRect.origin.y + thisRect.size.height)) {
                            CGFloat newLimit = MAX(currentLineRect.origin.y + currentLineRect.size.height, 
                                                   thisRect.origin.y + thisRect.size.height);
                            currentLineRect.origin.y = MIN(currentLineRect.origin.y, thisRect.origin.y);
                            currentLineRect.size.height = newLimit - currentLineRect.origin.y;
                            currentLineRect.size.width = (thisRect.size.width + thisRect.origin.x) - currentLineRect.origin.x; 
                        } else {
                            [highlightRects addObject:[NSValue valueWithCGRect:currentLineRect]];
                            currentLineRect = thisRect;
                        }
                    }
                }
                ++elementIdIndex;
            } while (isLastBlock ? 
                       ([elementId compare:endElementId] < NSOrderedSame) : 
                       elementIdIndex < elementIdCount);
            ++blockIdIndex;
        } while(!isLastBlock);
        [highlightRects addObject:[NSValue valueWithCGRect:currentLineRect]];

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
        
        if(self.trackingStage != EucHighlighterTrackingStageFirstSelection) {
            [self _positionKnobs];
        }
        
        _selectedRange = [newRange retain];
    } 
    if(!newRange) {
        if(self.trackingStage == EucHighlighterTrackingStageFirstSelection) {
            for(CALayer *layer in self.highlightLayers) {
                layer.hidden = YES;
            }            
        } else {
            [self setTrackingStage:EucHighlighterTrackingStageNone];
        }
    }
}

- (void)_trackTouch:(UITouch *)touch
{       
    UIView *viewWithSelection = self.viewWithSelection;
    CGPoint location = [touch locationInView:viewWithSelection];

    EucHighlighterRange *newSelectedRange = nil;
    
    if(self.trackingStage == EucHighlighterTrackingStageFirstSelection) {   
        [self _loupeToPoint:location];

        THPair *blockAndElementAndHighlightRects = [self _blockAndElementIdsAndHighlightRectsForPoint:location];
        THPair *blockAndElementIds = blockAndElementAndHighlightRects.first;
        
        if(blockAndElementIds) {
            newSelectedRange = [[EucHighlighterRange alloc] init];
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
            newSelectedRange = [[EucHighlighterRange alloc] init];
            
            id blockId = closestBlockAndElement.first;
            id elementId = closestBlockAndElement.second;
            
            EucHighlighterRange *currentSelectedRange = self.selectedRange;

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
}

- (void)_startSelection
{
    self.trackingStage = EucHighlighterTrackingStageFirstSelection;
    
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
            CGRect leftKnobRect = CGRectInset([leftKnobLayer convertRect:leftKnobLayer.bounds toLayer:viewWithSelectionLayer], -8.0f, -8.0f);

            if(CGRectContainsPoint(leftKnobRect, touchPoint)) {
                draggingKnob = leftKnobLayer;
                CALayer *endLayer = self.highlightEndLayers.first;
                CGPoint endLayerCenter = [endLayer convertPoint:endLayer.position toLayer:viewWithSelectionLayer];
                draggingKnobVerticalOffset = endLayerCenter.y - touchPoint.y;
            } else {
                CALayer *rightKnobLayer = self.highlightKnobLayers.second;
                CGRect rightKnobRect = CGRectInset([rightKnobLayer convertRect:rightKnobLayer.bounds toLayer:viewWithSelectionLayer], -8.0f, -8.0f);
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
        self.trackingStage = EucHighlighterTrackingStageNone;
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
                self.trackingStage = EucHighlighterTrackingStageChangingSelection;
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
           (self.trackingStage == EucHighlighterTrackingStageSelectedAndWaiting && !self.draggingKnob)) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_startSelection) object:nil];
            self.trackingTouch = nil;
            self.trackingStage = EucHighlighterTrackingStageNone;
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
           (self.trackingStage == EucHighlighterTrackingStageSelectedAndWaiting && !self.draggingKnob)) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_startSelection) object:nil];
            self.trackingTouch = nil;
            self.trackingStage = EucHighlighterTrackingStageNone;
        } else {
            [self _trackTouch:trackingTouch];
            if(self.trackingTouchHasMoved && self.highlightLayers.count && !((CALayer *)[self.highlightLayers objectAtIndex:0]).isHidden) {
                self.trackingStage = EucHighlighterTrackingStageSelectedAndWaiting;
            } else {
                self.trackingStage = EucHighlighterTrackingStageNone;
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

@end
