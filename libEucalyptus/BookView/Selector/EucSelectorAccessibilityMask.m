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
        pageOverlay.accessibilityHint = @"Double tap to dismiss selection";
        pageOverlay.accessibilityTraits = UIAccessibilityTraitUpdatesFrequently;
        pageOverlay.isAccessibilityElement = YES;
        _pageOverlay = pageOverlay;
        [self setSelectionString:nil];
        [self addSubview:pageOverlay];
    }
    return self;
}

- (void)setSelectionString:(NSString *)label
{
    if(label.length) {
        NSString *labelFormat = NSLocalizedString(@"Selection: %@", @"Accessibility summary for selection.  Arg = selected string");
        [_pageOverlay setAccessibilityLabel:[NSString stringWithFormat:labelFormat, label]];
    } else {
        [_pageOverlay setAccessibilityLabel:NSLocalizedString(@"Selection", @"Accessibility summary for selection with zero length")];
    }
}


@end
