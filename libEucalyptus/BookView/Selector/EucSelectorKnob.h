//
//  EucSelectorKnob.h
//  libEucalyptus
//
//  Created by James Montgomerie on 01/09/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EucSelectorKnobDelegate;

typedef enum {
    EucSelectorKnobKindLeft,
    EucSelectorKnobKindRight,
} EucSelectorKnobKind;

@interface EucSelectorKnob : UIView {
    id<EucSelectorKnobDelegate> *delegate;
    EucSelectorKnobKind _kind;
}

@property (nonatomic, assign) id<EucSelectorKnobDelegate> delegate;
@property (nonatomic, assign, readonly) EucSelectorKnobKind kind;

- (id)initWithKind:(EucSelectorKnobKind)kind;

@end


@protocol EucSelectorKnobDelegate

@required

- (void)eucSelectorKnobShouldIncrement:(EucSelectorKnob *)knob;
- (void)eucSelectorKnobShouldDecrement:(EucSelectorKnob *)knob;

@end