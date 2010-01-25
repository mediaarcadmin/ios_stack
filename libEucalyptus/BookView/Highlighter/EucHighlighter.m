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
#import "THEventCapturingWindow.h"
#import "THImageFactory.h"
#import "THLog.h"

static const CGFloat sLoupePopDuration = 0.05f;

@interface EucHighlighter ()


@property (nonatomic, retain) UIView *attachedView;
@property (nonatomic, retain) UITouch *trackingTouch;

@property (nonatomic, retain) UIView *viewWithSelection;
@property (nonatomic, retain) UIImageView *loupeView;
@property (nonatomic, retain) NSMutableArray *highlightLayers;

- (CGImageRef)magnificationLoupeImage;
- (void)_trackTouch:(UITouch *)touch;

@end

@implementation EucHighlighter

@synthesize dataSource = _dataSource;

@synthesize attachedView = _attachedView;
@synthesize trackingTouch = _trackingTouch;
@synthesize tracking = _tracking;

@synthesize viewWithSelection = _viewWithSelection;
@synthesize loupeView = _loupeView;
@synthesize highlightLayers = _highlightLayers;

- (void)dealloc
{
    if(self.attachedView) {
        THWarn(@"Highlighter released while still attahed to view");
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

- (void)temporarilyHighlightElementWithIdentfier:(id)elementId inBlockWithIdentifier:(id)blockId animated:(BOOL)animated;
{
    
}

- (void)clearTemporaryHighlights
{
    
}

- (NSInteger)highlightElementsFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    return 0;
}

- (void)removeHighlight:(NSInteger)highlightId 
{
    
}

- (CGImageRef)magnificationLoupeImage
{
    if(!_magnificationLoupeImage) {
        NSData *data = [[NSData alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[EucHighlighter class]] pathForResource:@"MagnificationLoupe" ofType:@"png"]];
        _magnificationLoupeImage = CGImageRetain([UIImage imageWithData:data].CGImage);
        [data release];
    }
    return _magnificationLoupeImage;
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
        [loupeView.layer addAnimation:loupePopUp forKey:@"popup"];
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

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{   
    NSString *name = [anim valueForKey:@"THName"];
    if(name) {
        if([name isEqualToString:@"loupePopDown"]) {
            UIImageView *loupeView = [anim valueForKey:@"THView"];
            [loupeView removeFromSuperview];
        }
    }
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
    loupePopDown.toValue = [NSValue valueWithCATransform3D:toTransform];
    loupePopDown.duration = sLoupePopDuration;
    loupePopDown.delegate = self;
    [loupePopDown setValue:@"loupePopDown" forKey:@"THName"];
    [loupePopDown setValue:loupeView forKey:@"THView"];
    [loupeViewLayer addAnimation:loupePopDown forKey:@"popdown"];
    [loupePopDown release];
    
    // Avoid popping back to full-size.
    loupeViewLayer.transform = toTransform;

    // Forget this loupe.  It will be removed from its superview in the 
    // animationDidStop callback.
    self.loupeView = nil;
}

- (void)setTracking:(BOOL)tracking;
{
    if(tracking) {
        if([self.dataSource respondsToSelector:@selector(viewSnapshotImageForEucHighlighter:)]) {
            UIView *attachedView = self.attachedView;
            UIImageView *dummySelectionView = [[UIImageView alloc] initWithImage:[self.dataSource viewSnapshotImageForEucHighlighter:self]];
            dummySelectionView.frame = attachedView.frame;
            [attachedView.superview insertSubview:dummySelectionView aboveSubview:attachedView];
            self.viewWithSelection = dummySelectionView;
            [dummySelectionView release];
        } else {
            self.viewWithSelection = self.attachedView;
        }
        [self _trackTouch:self.trackingTouch];
    } else {
        [self _removeLoupe];
        
        [self.highlightLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
        self.highlightLayers = nil;
        if(self.viewWithSelection != self.attachedView) {
            [self.viewWithSelection removeFromSuperview];
            self.viewWithSelection = nil;
        }
    }
    _tracking = tracking;
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
                layer.backgroundColor = [[[UIColor blueColor] colorWithAlphaComponent:0.25f] CGColor];
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

- (void)_startSelection
{
    self.tracking = YES;
}

- (void)observeTouch:(UITouch *)touch
{
    UITouch *trackingTouch = self.trackingTouch;
    UITouchPhase phase = touch.phase;
    
    if(!trackingTouch && phase == UITouchPhaseBegan) {
        self.trackingTouch = touch;
        [self performSelector:@selector(_startSelection) withObject:nil afterDelay:0.5f];
    } else if(touch == trackingTouch) {
        if(!self.isTracking) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_startSelection) object:nil];
            self.trackingTouch = nil;
        } else {        
            if(phase == UITouchPhaseMoved) { 
                [self _trackTouch:touch];
            } else if(phase == UITouchPhaseEnded || phase == UITouchPhaseCancelled) {
                self.trackingTouch = nil;
                self.tracking = NO;
            }
        }
    }
}

@end
