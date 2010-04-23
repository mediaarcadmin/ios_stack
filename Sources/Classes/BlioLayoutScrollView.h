//
//  BlioLayoutScrollView.h
//  BlioApp
//
//  Created by matt on 03/03/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioBookView.h"
#import "BlioLayoutView.h"
#import <libEucalyptus/EucSelector.h>

typedef enum BlioLayoutTouchForwardingState {
    BlioLayoutTouchForwardingStateNone,
    BlioLayoutTouchForwardingStateForwardedBegin,
    BlioLayoutTouchForwardingStateForwardedBeginTimerExpired,
    BlioLayoutTouchForwardingStateMultiTouchBegin,
    BlioLayoutTouchForwardingStateCancelled
} BlioLayoutTouchForwardingState;

@interface BlioLayoutScrollView : UIScrollView {
    EucSelector *selector;
    NSTimer *doubleTapBeginTimer;
    NSTimer *doubleTapEndTimer;
    id<BlioBookDelegate> bookDelegate;
    id<BlioLayoutAccessibilityDelegate> accessibilityDelegate;
    BlioLayoutTouchForwardingState forwardingState;
    CGPoint touchesBeginPoint;
    NSMutableArray *accessibilityElements;

}

@property (nonatomic, assign) EucSelector *selector;
@property (nonatomic, assign) id<BlioBookDelegate> bookDelegate;
@property (nonatomic, assign) id<BlioLayoutAccessibilityDelegate> accessibilityDelegate;

@end