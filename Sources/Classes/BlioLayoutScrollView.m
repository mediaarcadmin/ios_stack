//
//  BlioLayoutScrollView.m
//  BlioApp
//
//  Created by matt on 03/03/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioLayoutScrollView.h"

@interface BlioLayoutScrollView()

@property (nonatomic, retain) NSTimer *doubleTapBeginTimer;
@property (nonatomic, retain) NSTimer *doubleTapEndTimer;
@property (nonatomic) BlioLayoutTouchForwardingState forwardingState;

- (void)handleSingleTouch;

@end

static const CGFloat kBlioLayoutLHSHotZone = 1.0f / 3 * 1;
static const CGFloat kBlioLayoutRHSHotZone = 1.0f / 3 * 2;

@implementation BlioLayoutScrollView

@synthesize selector, doubleTapBeginTimer, doubleTapEndTimer, bookDelegate, forwardingState;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.forwardingState = BlioLayoutTouchForwardingStateNone;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.autoresizesSubviews = YES;
    }
    return self;
}

- (void)dealloc {
    self.selector = nil;
    [self.doubleTapBeginTimer invalidate];
    self.doubleTapBeginTimer = nil;
    [self.doubleTapEndTimer invalidate];
    self.doubleTapEndTimer = nil;
    self.bookDelegate = nil;
    [super dealloc];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.doubleTapBeginTimer invalidate];
    self.doubleTapBeginTimer = nil;
    
    if (nil != self.doubleTapEndTimer) {
//        self.forwardingState = BlioLayoutTouchForwardingStateCancelled;
//        [self.doubleTapEndTimer fire];
        self.forwardingState = BlioLayoutTouchForwardingStateNone;
        [self.doubleTapEndTimer invalidate];
        self.doubleTapEndTimer = nil;
    }
    
    NSSet *allTouches = [event touchesForView:self];
    if ([allTouches count] > 1) {
        
        if (self.forwardingState != BlioLayoutTouchForwardingStateNone) {
            [self.selector touchesCancelled:allTouches];
        }
        
        self.forwardingState = BlioLayoutTouchForwardingStateMultiTouchBegin;
        return;
    }
    
    UITouch * t = [touches anyObject];
    touchesBeginPoint = [t locationInView:(UIView *)self.delegate];
    
    if([t tapCount] == 2) {
        if ([(NSObject *)self.delegate respondsToSelector:@selector(zoomAtPoint:)])
            [(NSObject *)self.delegate performSelector:@selector(zoomAtPoint:) withObject:NSStringFromCGPoint(touchesBeginPoint)];  
        
        [self.bookDelegate hideToolbars];
    } else {
        [self.selector touchesBegan:touches];
        self.forwardingState = BlioLayoutTouchForwardingStateForwardedBegin;
        self.doubleTapBeginTimer = [NSTimer scheduledTimerWithTimeInterval:0.25f target:self selector:@selector(delayedTouchesBegan:) userInfo:nil repeats:NO];
    }
}

- (void)delayedTouchesBegan:(NSTimer *)timer {
    self.forwardingState = BlioLayoutTouchForwardingStateForwardedBeginTimerExpired;
    [self.doubleTapBeginTimer invalidate];
    self.doubleTapBeginTimer = nil;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.forwardingState == BlioLayoutTouchForwardingStateMultiTouchBegin) return;
    
    if (nil != self.doubleTapBeginTimer) {
        [self.doubleTapBeginTimer invalidate];
        self.doubleTapBeginTimer = nil;
    }
    
    [self.doubleTapEndTimer invalidate];
    self.doubleTapEndTimer = nil;
    
    self.forwardingState = BlioLayoutTouchForwardingStateForwardedBeginTimerExpired;
    
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
    if (self.forwardingState == BlioLayoutTouchForwardingStateMultiTouchBegin) {
        NSSet *allTouches = [event touchesForView:self];
        if ([allTouches count] <= 1) self.forwardingState = BlioLayoutTouchForwardingStateNone;
        return;
    }
    
    [self.doubleTapEndTimer invalidate];
    self.doubleTapEndTimer = nil;
    [self.doubleTapBeginTimer invalidate];
    self.doubleTapBeginTimer = nil;
    
    switch (self.forwardingState) {
        case BlioLayoutTouchForwardingStateCancelled:
            [self.selector touchesCancelled:touches];
            self.forwardingState = BlioLayoutTouchForwardingStateNone;
            break;
        case BlioLayoutTouchForwardingStateForwardedBegin:
            self.doubleTapEndTimer = [NSTimer scheduledTimerWithTimeInterval:0.35f target:self selector:@selector(delayedTouchesEnded:) userInfo:touches repeats:NO];
            //[self.selector touchesEnded:touches];
            [self.selector touchesCancelled:touches];
            break;
        case BlioLayoutTouchForwardingStateForwardedBeginTimerExpired:
            self.forwardingState = BlioLayoutTouchForwardingStateNone;
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
    
    //if (self.forwardingState == BlioLayoutTouchForwardingStateCancelled) {
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
    
    self.forwardingState = BlioLayoutTouchForwardingStateNone;
    [self.doubleTapEndTimer invalidate];
    self.doubleTapEndTimer = nil;
}

- (void)handleSingleTouch {
    CGFloat screenWidth = CGRectGetWidth(self.bounds);
    CGFloat leftHandHotZone = screenWidth * kBlioLayoutLHSHotZone;
    CGFloat rightHandHotZone = screenWidth * kBlioLayoutRHSHotZone;
    
    if (touchesBeginPoint.x <= leftHandHotZone) {
        if ([(NSObject *)self.delegate respondsToSelector:@selector(zoomToPreviousBlock)])
            [(NSObject *)self.delegate performSelector:@selector(zoomToPreviousBlock) withObject:nil];
        
        [self.bookDelegate hideToolbars];
    } else if (touchesBeginPoint.x >= rightHandHotZone) {
        if ([(NSObject *)self.delegate respondsToSelector:@selector(zoomToNextBlock)])
            [(NSObject *)self.delegate performSelector:@selector(zoomToNextBlock) withObject:nil]; 
        
        [self.bookDelegate hideToolbars];
    } else {
        [self.bookDelegate toggleToolbars]; 
    }    
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.doubleTapEndTimer invalidate];
    self.doubleTapEndTimer = nil;
    [self.doubleTapBeginTimer invalidate];
    self.doubleTapBeginTimer = nil;
    
    if (self.forwardingState == BlioLayoutTouchForwardingStateMultiTouchBegin) {
        NSSet *allTouches = [event touchesForView:self];
        if ([allTouches count] <= 1) self.forwardingState = BlioLayoutTouchForwardingStateNone;
        return;
    } else if (self.forwardingState != BlioLayoutTouchForwardingStateNone) {
        self.forwardingState = BlioLayoutTouchForwardingStateNone;
        [self.selector touchesCancelled:touches];
    }
}

//- (void)setContentOffset:(CGPoint)newContentOffset {
//    NSLog(@"newContentOffset: %@", NSStringFromCGPoint(newContentOffset));
//    [super setContentOffset:newContentOffset];
//}

- (BOOL)isAccessibilityElement {
    return YES;
}

- (NSString *)accessibilityLabel {
    return @"scrollView";
}

@end    
