//
//  BlioAccessibilitySegmentedControl.m
//  BlioApp
//
//  Created by matt on 22/04/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioAccessibilitySegmentedControl.h"

static const NSString * const sBlioAccessibilitySegmentedControlObserverContext = @"BlioAccessibilitySegmentedControlObserverContext";

@interface BlioAccessibilitySegmentedControl () 
- (NSString *)accessibilityLabelForSegmentIndex:(NSUInteger)i;
- (void)invalidateAccessibilitySegments;
@end

@implementation BlioAccessibilitySegmentedControl

- (id)initWithItems:(NSArray *)items
{
    if((self = [super initWithItems:items])) {
        [self addObserver:self 
               forKeyPath:@"selectedSegmentIndex" 
                  options:0 
                  context:sBlioAccessibilitySegmentedControlObserverContext];
    }
    return self;
}

- (void)dealloc {
    [self removeObserver:self 
              forKeyPath:@"selectedSegmentIndex" 
                 context:sBlioAccessibilitySegmentedControlObserverContext];
    
    if ( accessibleSegments != nil ) {
        [accessibleSegments release];
        accessibleSegments = nil;
        [segmentAccessibilityHints release];
        segmentAccessibilityHints = nil;
        [segmentAccessibilityTraits release];
        segmentAccessibilityTraits = nil;
    }
    
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == sBlioAccessibilitySegmentedControlObserverContext) {
        if (object == self) {
            if ([keyPath isEqualToString:@"selectedSegmentIndex"]) {
                NSString *announcement = nil;
                NSInteger selectedSegmentIndex = self.selectedSegmentIndex;
                if(selectedSegmentIndex != UISegmentedControlNoSegment &&
                   self.numberOfSegments > 1) { // self.numberOfSegments > 1 so that we don't announce if we're just faking a single button.
                    UIAccessibilityElement *currentElement = [self accessibilityElementAtIndex:selectedSegmentIndex];
                    if([currentElement accessibilityElementIsFocused]) {
                        announcement = [NSString stringWithFormat:NSLocalizedString(@"Selected: \"%@\", button", @"Acessibility announcement when a segmented control changes its selection: argument = title of button"),
                                        currentElement.accessibilityLabel];
                    }
                } 
                [self invalidateAccessibilitySegments];
                if(announcement) {
                    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, announcement);
                }
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)invalidateAccessibilitySegments {
    if (accessibleSegments != nil) {
        [accessibleSegments release];
        accessibleSegments = nil;
    }
    
    if(self.window) {
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    }
}

- (void)setAccessibilityHint:(NSString *)accessibilityHint forSegmentIndex:(NSUInteger)segmentIndex
{
    if(!segmentAccessibilityHints) {
        segmentAccessibilityHints = [[NSMutableDictionary alloc] init];
    }
    [segmentAccessibilityHints setObject:accessibilityHint forKey:[NSNumber numberWithUnsignedInteger:segmentIndex]];
    [self invalidateAccessibilitySegments];
}

- (NSString *)accessibilityHintForSegmentIndex:(NSUInteger)segmentIndex
{
    NSString *hint = [[self imageForSegmentAtIndex:segmentIndex] accessibilityHint];
    if(!hint) {
        hint = [segmentAccessibilityHints objectForKey:[NSNumber numberWithUnsignedInteger:segmentIndex]];
    }
    return hint;
}

- (void)setAccessibilityTraits:(UIAccessibilityTraits)accessibilityTraits forSegmentIndex:(NSUInteger)segmentIndex
{
    if(!segmentAccessibilityTraits) {
        segmentAccessibilityTraits = [[NSMutableDictionary alloc] init];
    }
    accessibilityTraits &= ~UIAccessibilityTraitSelected;
    [segmentAccessibilityTraits setObject:[NSNumber numberWithUnsignedLongLong:accessibilityTraits] 
                                   forKey:[NSNumber numberWithUnsignedInteger:segmentIndex]];
    [self invalidateAccessibilitySegments];
}

- (UIAccessibilityTraits)accessibilityTraitsForSegmentIndex:(NSUInteger)segmentIndex
{
    UIAccessibilityTraits traits;
    NSNumber *traitsValue = [segmentAccessibilityTraits objectForKey:[NSNumber numberWithUnsignedInteger:segmentIndex]];
    if(traitsValue) {
        traits = [traitsValue unsignedLongLongValue];
    } else {
        traits = UIAccessibilityTraitButton;
    }
    if(self.selectedSegmentIndex == segmentIndex) {
        traits |= UIAccessibilityTraitSelected;
    }
    return traits;
}

- (NSString *)accessibilityLabelForSegmentIndex:(NSUInteger)i
{
    NSString *label = nil;
    id segmentItem = (id)[self imageForSegmentAtIndex:i] ? : (id)[self titleForSegmentAtIndex:i];
    if (nil != segmentItem) {
        label = [segmentItem accessibilityLabel];
        if ((nil == label) && [segmentItem isKindOfClass:[NSString class]]) 
            label = (NSString *)segmentItem;
    }
    return label;
}
                                           
- (void)setEnabled:(BOOL)enabled {
	[super setEnabled:enabled];
    [self invalidateAccessibilitySegments];
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
        
        for (NSUInteger i = 0; i < numSegments; i++) {
            UIAccessibilityElement *element = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
            id segmentItem = (id)[self imageForSegmentAtIndex:i] ? : (id)[self titleForSegmentAtIndex:i];
            if (nil != segmentItem) {
                CGRect segmentFrame = CGRectMake(i * segmentWidth, 0, segmentWidth, segmentHeight);
                [element setAccessibilityFrame:[self.window convertRect:segmentFrame fromView:self]];

                element.accessibilityLabel = [self accessibilityLabelForSegmentIndex:i];
                element.accessibilityTraits = [self accessibilityTraitsForSegmentIndex:i];
                element.accessibilityHint= [self accessibilityHintForSegmentIndex:i];

                if(!self.enabled || ![self isEnabledForSegmentAtIndex:i]) {
                    element.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
                }
                
                [accessibleSegments addObject:element];
            }
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
