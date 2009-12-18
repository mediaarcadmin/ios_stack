//
//  THEventCapturingWindow.h
//  libEucalyptus
//
//  Created by James Montgomerie on 18/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol THEventCaptureObserver;

@interface THEventCapturingWindow : UIWindow {
    NSMutableArray *_eventCaptureObservers;
    NSMutableArray *_eventCaptureViewsToObserve;
}

- (void)addTouchObserver:(id <THEventCaptureObserver>)observer forView:(UIView *)view;
- (void)removeTouchObserver:(id <THEventCaptureObserver>)observer forView:(UIView *)view;

@end

@protocol THEventCaptureObserver <NSObject>

- (void)observeTouch:(UITouch *)touch;

@end