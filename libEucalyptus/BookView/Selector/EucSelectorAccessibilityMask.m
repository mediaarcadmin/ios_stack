//
//  EucSelectorAccessibilityMask.m
//  libEucalyptus
//
//  Created by James Montgomerie on 05/09/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucSelectorAccessibilityMask.h"


@implementation EucSelectorAccessibilityMask

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.isAccessibilityElement = NO;
        
        UIView *pageOverlay = [[UIView alloc] initWithFrame:self.bounds];
        pageOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        pageOverlay.accessibilityLabel = @"Book Page";
        pageOverlay.accessibilityHint = @"Double tap to dismiss selection";
        //pageOverlay.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.5f]; 
        pageOverlay.isAccessibilityElement = YES;
        [self addSubview:pageOverlay];
    }
    return self;
}

@end
