//
//  BlioLegacyLayoutScrollView.m
//  BlioApp
//
//  Created by matt on 03/03/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioLegacyLayoutScrollView.h"

@interface BlioLegacyLayoutScrollView()

@property (nonatomic, retain) NSTimer *doubleTapBeginTimer;
@property (nonatomic, retain) NSTimer *doubleTapEndTimer;
@property (nonatomic) BlioLegacyLayoutTouchForwardingState forwardingState;

- (void)handleSingleTouch;

@end

static const CGFloat kBlioLegacyLayoutLHSHotZone = 1.0f / 3 * 1;
static const CGFloat kBlioLegacyLayoutRHSHotZone = 1.0f / 3 * 2;

@implementation BlioLegacyLayoutScrollView

@synthesize selector, doubleTapBeginTimer, doubleTapEndTimer, bookViewDelegate, forwardingState, touchesBeginPoint;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.forwardingState = BlioLegacyLayoutTouchForwardingStateNone;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.autoresizesSubviews = YES;
    }
    return self;
}

- (void)dealloc {
    //NSLog(@"*************** dealloc called for scrollview");
    self.selector = nil;
    [self.doubleTapBeginTimer invalidate];
    self.doubleTapBeginTimer = nil;
    [self.doubleTapEndTimer invalidate];
    self.doubleTapEndTimer = nil;
    self.bookViewDelegate = nil;
    [super dealloc];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.doubleTapBeginTimer invalidate];
    self.doubleTapBeginTimer = nil;
    
    if (nil != self.doubleTapEndTimer) {
//        self.forwardingState = BlioLegacyLayoutTouchForwardingStateCancelled;
//        [self.doubleTapEndTimer fire];
        self.forwardingState = BlioLegacyLayoutTouchForwardingStateNone;
        [self.doubleTapEndTimer invalidate];
        self.doubleTapEndTimer = nil;
    }
    
    NSSet *allTouches = [event touchesForView:self];
    if ([allTouches count] > 1) {
        
        if (self.forwardingState != BlioLegacyLayoutTouchForwardingStateNone) {
            [self.selector touchesCancelled:allTouches];
        }
        
        self.forwardingState = BlioLegacyLayoutTouchForwardingStateMultiTouchBegin;
        return;
    }
    
    UITouch * t = [touches anyObject];
    touchesBeginPoint = [t locationInView:(UIView *)self.delegate];
    
    if([t tapCount] == 2) {
        if ([(NSObject *)self.delegate respondsToSelector:@selector(zoomAtPoint:)])
            [(NSObject *)self.delegate performSelector:@selector(zoomAtPoint:) withObject:NSStringFromCGPoint(touchesBeginPoint)];  
        
        [self.bookViewDelegate hideToolbars];
    } else {
        [self.selector touchesBegan:touches];
        self.forwardingState = BlioLegacyLayoutTouchForwardingStateForwardedBegin;
        self.doubleTapBeginTimer = [NSTimer scheduledTimerWithTimeInterval:0.25f target:self selector:@selector(delayedTouchesBegan:) userInfo:nil repeats:NO];
    }
}

- (void)delayedTouchesBegan:(NSTimer *)timer {
    self.forwardingState = BlioLegacyLayoutTouchForwardingStateForwardedBeginTimerExpired;
    [self.doubleTapBeginTimer invalidate];
    self.doubleTapBeginTimer = nil;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.forwardingState == BlioLegacyLayoutTouchForwardingStateMultiTouchBegin) return;
    
    if (nil != self.doubleTapBeginTimer) {
        [self.doubleTapBeginTimer invalidate];
        self.doubleTapBeginTimer = nil;
    }
    
    [self.doubleTapEndTimer invalidate];
    self.doubleTapEndTimer = nil;
    
    self.forwardingState = BlioLegacyLayoutTouchForwardingStateForwardedBeginTimerExpired;
    
    if ([self.selector isTracking]) {
        switch ([self.selector trackingStage]) {
            case EucSelectorTrackingStageFirstSelection:
            case EucSelectorTrackingStageChangingSelection:
                [self.selector touchesMoved:touches];
                break;
            default:
                break;
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.forwardingState == BlioLegacyLayoutTouchForwardingStateMultiTouchBegin) {
        NSSet *allTouches = [event touchesForView:self];
        if ([allTouches count] <= 1) self.forwardingState = BlioLegacyLayoutTouchForwardingStateNone;
        return;
    }
    
    [self.doubleTapEndTimer invalidate];
    self.doubleTapEndTimer = nil;
    [self.doubleTapBeginTimer invalidate];
    self.doubleTapBeginTimer = nil;
    
    switch (self.forwardingState) {
        case BlioLegacyLayoutTouchForwardingStateCancelled:
            [self.selector touchesCancelled:touches];
            self.forwardingState = BlioLegacyLayoutTouchForwardingStateNone;
            break;
        case BlioLegacyLayoutTouchForwardingStateForwardedBegin:
            self.doubleTapEndTimer = [NSTimer scheduledTimerWithTimeInterval:0.35f target:self selector:@selector(delayedTouchesEnded:) userInfo:touches repeats:NO];
            //[self.selector touchesEnded:touches];
            [self.selector touchesCancelled:touches];
            break;
        case BlioLegacyLayoutTouchForwardingStateForwardedBeginTimerExpired:
            self.forwardingState = BlioLegacyLayoutTouchForwardingStateNone;
//            if (![self.selector isTracking]) {
//                [self.selector touchesEnded:touches];
//                [self handleSingleTouch];
//            } else {
                [self.selector touchesEnded:touches];
            //}
            break;
        default:
            break;
    }
}

- (void)delayedTouchesEnded:(NSTimer *)timer {
    NSSet *touches = (NSSet *)[timer userInfo];
    
    //if (self.forwardingState == BlioLegacyLayoutTouchForwardingStateCancelled) {
//        [self.selector touchesCancelled:touches];
//    } else {
        UITouch * t = [touches anyObject];
        if ((![self.selector isTracking]) && ([t tapCount] == 1)) {
        //if ([t tapCount] == 1) {   
            //[self.selector touchesEnded:touches];
            [self handleSingleTouch];
            
        } else {
            //[self.selector touchesEnded:touches];
            [self.selector setSelectedRange:nil];
        }
    //}
    
    self.forwardingState = BlioLegacyLayoutTouchForwardingStateNone;
    [self.doubleTapEndTimer invalidate];
    self.doubleTapEndTimer = nil;
}

- (void)handleSingleTouch {
    CGFloat screenWidth = CGRectGetWidth(self.bounds);
    CGFloat leftHandHotZone = screenWidth * kBlioLegacyLayoutLHSHotZone;
    CGFloat rightHandHotZone = screenWidth * kBlioLegacyLayoutRHSHotZone;
    
    if (touchesBeginPoint.x <= leftHandHotZone) {
        if ([(NSObject *)self.delegate respondsToSelector:@selector(zoomToPreviousBlock)])
            [(NSObject *)self.delegate performSelector:@selector(zoomToPreviousBlock) withObject:nil];
        
        [self.bookViewDelegate hideToolbars];
    } else if (touchesBeginPoint.x >= rightHandHotZone) {
        if ([(NSObject *)self.delegate respondsToSelector:@selector(zoomToNextBlock)])
            [(NSObject *)self.delegate performSelector:@selector(zoomToNextBlock) withObject:nil]; 
        
        [self.bookViewDelegate hideToolbars];
    } else {
        [self.bookViewDelegate toggleToolbars]; 
    }    
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.doubleTapEndTimer invalidate];
    self.doubleTapEndTimer = nil;
    [self.doubleTapBeginTimer invalidate];
    self.doubleTapBeginTimer = nil;
    
    if (self.forwardingState == BlioLegacyLayoutTouchForwardingStateMultiTouchBegin) {
        NSSet *allTouches = [event touchesForView:self];
        if ([allTouches count] <= 1) self.forwardingState = BlioLegacyLayoutTouchForwardingStateNone;
        return;
    } else if (self.forwardingState != BlioLegacyLayoutTouchForwardingStateNone) {
        self.forwardingState = BlioLegacyLayoutTouchForwardingStateNone;
        [self.selector touchesCancelled:touches];
    }
}

@end    