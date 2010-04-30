//
//  BlioAccessibilitySegmentedControl.m
//  BlioApp
//
//  Created by matt on 22/04/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioAccessibilitySegmentedControl.h"


@implementation BlioAccessibilitySegmentedControl

- (void)dealloc {
    if ( accessibleSegments != nil ) {
        [accessibleSegments release];
        accessibleSegments = nil;
    }
    [super dealloc];
}

- (void)invalidateAccessibilitySegments {
    if (accessibleSegments != nil) {
        [accessibleSegments release];
        accessibleSegments = nil;
    }
    
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

- (void)insertSegmentWithTitle:(NSString *)title atIndex:(NSUInteger)segment animated:(BOOL)animated {
    [super insertSegmentWithTitle:title atIndex:segment animated:animated];
    [self invalidateAccessibilitySegments];
}

- (void)insertSegmentWithImage:(UIImage *)image atIndex:(NSUInteger)segment animated:(BOOL)animated {
    [super insertSegmentWithImage:image atIndex:segment animated:animated];
    [self invalidateAccessibilitySegments];
}

- (void)removeSegmentAtIndex:(NSUInteger)segment animated:(BOOL)animated {
    [super removeSegmentAtIndex:segment animated:animated];
    [self invalidateAccessibilitySegments];
}

- (void)removeAllSegments {
    [super removeAllSegments];
    [self invalidateAccessibilitySegments];
}

- (void)setSelectedSegmentIndex:(NSInteger)index {
    [super setSelectedSegmentIndex:index];
    [self invalidateAccessibilitySegments];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self invalidateAccessibilitySegments];
}

- (BOOL)isAccessibilityElement {
    return NO;
}

- (NSInteger)accessibilityElementCount {
    NSUInteger numSegments = [super numberOfSegments];
    CGFloat segmentWidth = CGRectGetWidth(self.bounds) / numSegments;
    CGFloat segmentHeight = CGRectGetHeight(self.bounds);
    
    if ([accessibleSegments count] != numSegments) {
        if ( accessibleSegments != nil ) [accessibleSegments release];
        accessibleSegments = [[NSMutableArray alloc] init];
        
        NSInteger i;
        for (i = 0; i < numSegments; i++) {
            UIAccessibilityElement *element = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
            id segmentItem = (id)[self imageForSegmentAtIndex:i] ? : (id)[self titleForSegmentAtIndex:i];
            if (nil != segmentItem) {
                [element setIsAccessibilityElement:YES];
                NSString *label = [segmentItem accessibilityLabel];
                if ((nil == label) && [segmentItem isKindOfClass:[NSString class]]) 
                    label = (NSString *)segmentItem;
                [element setAccessibilityLabel:label];
                [element setAccessibilityHint:[segmentItem accessibilityHint]];
                CGRect segmentFrame = CGRectMake(i * segmentWidth, 0, segmentWidth, segmentHeight);
                [element setAccessibilityFrame:[self.window convertRect:segmentFrame fromView:self]];
                UIAccessibilityTraits traits = UIAccessibilityTraitButton;
                if (i == [super selectedSegmentIndex]) traits |= UIAccessibilityTraitSelected;
                [element setAccessibilityTraits:traits];
            }
            [accessibleSegments addObject:element];
            [element release];
        }
    }
    
    return [accessibleSegments count];
}

- (id)accessibilityElementAtIndex:(NSInteger)index {
    return [accessibleSegments objectAtIndex:index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
    return [accessibleSegments indexOfObject:element];
}

@end
