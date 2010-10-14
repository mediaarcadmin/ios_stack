//
//  BlioLegacyLayoutScrollView.h
//  BlioApp
//
//  Created by matt on 03/03/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlioBookView.h"
#import "BlioLegacyLayoutView.h"
#import <libEucalyptus/EucSelector.h>

typedef enum BlioLegacyLayoutTouchForwardingState {
    BlioLegacyLayoutTouchForwardingStateNone,
    BlioLegacyLayoutTouchForwardingStateForwardedBegin,
    BlioLegacyLayoutTouchForwardingStateForwardedBeginTimerExpired,
    BlioLegacyLayoutTouchForwardingStateMultiTouchBegin,
    BlioLegacyLayoutTouchForwardingStateCancelled
} BlioLegacyLayoutTouchForwardingState;

@interface BlioLegacyLayoutScrollView : UIScrollView {
    EucSelector *selector;
    NSTimer *doubleTapBeginTimer;
    NSTimer *doubleTapEndTimer;
    id<BlioBookViewDelegate> bookViewDelegate;
    BlioLegacyLayoutTouchForwardingState forwardingState;
    CGPoint touchesBeginPoint;
}

@property (nonatomic, assign) EucSelector *selector;
@property (nonatomic, assign) id<BlioBookViewDelegate> bookViewDelegate;
@property (nonatomic, assign) CGPoint touchesBeginPoint;

@end