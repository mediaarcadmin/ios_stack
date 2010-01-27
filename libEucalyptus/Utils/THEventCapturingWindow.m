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
        NSUInteger count = _eventCaptureViewsToObserve.count;
        
        // Take copies in case something that we call adds or removes an 
        // observer.
        NSArray *viewsToObserve = [_eventCaptureViewsToObserve copy];
        NSArray *observers = [_eventCaptureObservers copy];
        for(UITouch *touch in [event allTouches]) {
            for(NSUInteger i = 0; i < count; ++i) {
                UIView *viewToObserve = ((NSValue *)[viewsToObserve objectAtIndex:i]).nonretainedObjectValue;
                if([touch.view isDescendantOfView:viewToObserve]) {
                    [((NSValue *)[observers objectAtIndex:i]).nonretainedObjectValue observeTouch:touch];
                }
            }
        }
        [viewsToObserve release];
        [observers release];
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
    NSUInteger i = [_eventCaptureViewsToObserve count];
    if(i) {
        do {
            --i;
            if(((NSValue *)[_eventCaptureViewsToObserve objectAtIndex:i]).nonretainedObjectValue == view &&
               ((NSValue *)[_eventCaptureObservers objectAtIndex:i]).nonretainedObjectValue == observer) {
                [_eventCaptureViewsToObserve removeObjectAtIndex:i];
                [_eventCaptureObservers removeObjectAtIndex:i];
                break;
            }
        } while(i != 0);
    }
    if([_eventCaptureViewsToObserve count] == 0) {
        [_eventCaptureObservers release];
        _eventCaptureObservers = nil;
        [_eventCaptureViewsToObserve release];
        _eventCaptureViewsToObserve = nil;
    }
}

@end
