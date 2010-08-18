//
//  EucBUpePageTextView.h
//  libEucalyptus
//
//  Created by James Montgomerie on 12/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EucPageTextView.h"
#import "THUIViewThreadSafeDrawing.h"

@class EucCSSLayoutPositionedBlock;

@interface EucBUpePageTextView : UIView <EucPageTextView> {
    id<EucPageTextViewDelegate> _delegate;
    
    CGFloat _pointSize;
    CGFloat _scaleFactor;
    BOOL _allowScaledImageDistortion;
    
    EucCSSLayoutPositionedBlock *_positionedBlock;
    NSArray *_runs;
    
    NSArray *_accessibilityElements;
    
    NSArray *_hyperlinkRectAndURLPairs;
    
    UITouch *_touch;
    NSUInteger _touchHyperlinkIndex;
}

- (EucBookPageIndexPoint *)layoutPageFromPoint:(EucBookPageIndexPoint *)point
                                        inBook:(id<EucBook>)bookIn
                                  centerOnPage:(BOOL)centerOnPage;

@end
