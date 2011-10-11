//
//  BlioAccessibilitySegmentedControl.h
//  BlioApp
//
//  Created by matt on 22/04/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BlioAccessibilitySegmentedControl : UISegmentedControl {
    NSMutableArray *accessibleSegments;
    NSMutableDictionary *segmentAccessibilityHints;
    NSMutableDictionary *segmentAccessibilityTraits;
}

- (void)setAccessibilityHint:(NSString *)accessibilityHint forSegmentIndex:(NSUInteger)segmentIndex;
- (NSString *)accessibilityHintForSegmentIndex:(NSUInteger)segmentIndex;

- (void)setAccessibilityTraits:(UIAccessibilityTraits)accessibilityTraits forSegmentIndex:(NSUInteger)segmentIndex;
- (UIAccessibilityTraits)accessibilityTraitsForSegmentIndex:(NSUInteger)segmentIndex;

@end
