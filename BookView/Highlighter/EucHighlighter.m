//
//  EucHighlighter.m
//  libEucalyptus
//
//  Created by James Montgomerie on 20/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucHighlighter.h"
#import "EucHighlighterOverlayView.h"
#import "THEventCapturingWindow.h"
#import "THLog.h"

@interface EucHighlighter ()

@property (nonatomic, retain) UIView *attachedView;
@property (nonatomic, retain) UITouch *trackingTouch;

@end

@implementation EucHighlighter

@synthesize dataSource = _dataSource;

@synthesize attachedView = _attachedView;
@synthesize trackingTouch = _trackingTouch;
@synthesize tracking = _tracking;

- (void)dealloc
{
    if(self.attachedView) {
        THWarn(@"Highlighter released while still attahed to view");
        [self detatchFromView];
    }
    [_trackingTouch release];
    
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

- (void)_startSelection
{
    self.tracking = YES;
    
    NSLog(@"Start");
}

- (void)observeTouch:(UITouch *)touch
{
    UITouch *trackingTouch = self.trackingTouch;
    UITouchPhase phase = touch.phase;
    
    if(!trackingTouch) {
        self.trackingTouch = touch;
        [self performSelector:@selector(_startSelection) withObject:nil afterDelay:0.5f];
    } else if(touch == trackingTouch) {
        if(!self.isTracking) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_startSelection) object:nil];
            self.trackingTouch = nil;
        } else {        
            if(phase == UITouchPhaseMoved) { 
                NSLog(@"%@", NSStringFromCGPoint([touch locationInView:_attachedView]));
            } else if(phase == UITouchPhaseEnded || phase == UITouchPhaseCancelled) {
                self.trackingTouch = nil;
                self.tracking = NO;
            }
        }
    }
}
@end
