//
//  THEventCapturingWindow.m
//  libEucalyptus
//
//  Created by James Montgomerie on 18/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import "THEventCapturingWindow.h"


@implementation THEventCapturingWindow

- (void)sendEvent:(UIEvent *)event 
{
    [super sendEvent:event];
    
    if(_eventCaptureViewsToObserve) {
        for(UITouch *touch in [event allTouches]) {
            NSUInteger count = [_eventCaptureViewsToObserve count];
            for(NSUInteger i = 0; i < count; ++i) {
                UIView *viewToObserve = ((NSValue *)[_eventCaptureViewsToObserve objectAtIndex:i]).nonretainedObjectValue;
                if([touch.view isDescendantOfView:viewToObserve]) {
                    [((NSValue *)[_eventCaptureObservers objectAtIndex:i]).nonretainedObjectValue observeTouch:touch];
                }
            }
        }
    }
}

- (void)addTouchObserver:(id <THEventCaptureObserver>)observer forView:(UIView *)view
{
    if(!_eventCaptureObservers) {
        _eventCaptureObservers = [[NSMutableArray alloc] init];
        _eventCaptureViewsToObserve = [[NSMutableArray alloc] init];
    }
    [_eventCaptureObservers addObject:[NSValue valueWithNonretainedObject:observer]];
    [_eventCaptureViewsToObserve addObject:[NSValue valueWithNonretainedObject:view]];
}

- (void)removeTouchObserver:(id <THEventCaptureObserver>)observer forView:(UIView *)view;
{
    NSUInteger count = [_eventCaptureViewsToObserve count];
    if(count) {
        for(NSUInteger i = count-1; i >=0; --i) {
            if(((NSValue *)[_eventCaptureViewsToObserve objectAtIndex:i]).nonretainedObjectValue == view &&
               ((NSValue *)[_eventCaptureObservers objectAtIndex:i]).nonretainedObjectValue == observer) {
                [_eventCaptureViewsToObserve removeObjectAtIndex:i];
                [_eventCaptureObservers removeObjectAtIndex:i];
                break;
            }
        }
    }
    if([_eventCaptureViewsToObserve count] == 0) {
        [_eventCaptureObservers release];
        _eventCaptureObservers = nil;
        [_eventCaptureViewsToObserve release];
        _eventCaptureViewsToObserve = nil;
    }
}

@end
