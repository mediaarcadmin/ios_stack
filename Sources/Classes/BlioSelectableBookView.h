//
//  BlioSelectableBookView.h
//  BlioApp
//
//  Created by James Montgomerie on 11/05/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <libEucalyptus/EucSelector.h>

@protocol BlioBookViewDelegate;
@class BlioBookmarkRange;

@interface BlioSelectableBookView : UIView {
    id<BlioBookViewDelegate> delegate;
    UIColor *lastHighlightColor;
}

// Provides:
@property (nonatomic, assign) id<BlioBookViewDelegate> delegate;
@property (nonatomic, retain) UIColor *lastHighlightColor;
- (NSArray *)menuItemsForEucSelector:(EucSelector *)selector;

// Optional override points (be sure to call super):
- (void)addHighlightWithColor:(UIColor *)color;

// Must be overridden (default implementations do nothing, or return nil):
@property (nonatomic, retain, readonly) EucSelector *selector;
- (void)refreshHighlights;
- (BlioBookmarkRange *)bookmarkRangeFromSelectorRange:(EucSelectorRange *)range;
- (BlioBookmarkRange *)selectedRange; // Should return a no-length range for the page if nothing is selected.

@end
