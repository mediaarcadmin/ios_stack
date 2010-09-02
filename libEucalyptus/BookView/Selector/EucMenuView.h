//
//  EucMenuView.h
//  libEucalyptus
//
//  Created by James Montgomerie on 05/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface EucMenuView : UIControl {
    NSArray *_items;
    
    CGRect _mainRect;
    BOOL _arrowAtTop;
    CGFloat _arrowMidX;
    
    UIImage *_mainImage;
    UIImage *_mainImageHighlighted;
    
    UIImage *_leftShadowImage;
    UIImage *_middleShadowImage;
    UIImage *_rightShadowImage;
    
    UIImage *_bottomArrowImage;
    UIImage *_bottomArrowImageHighlighted;
    UIImage *_topArrowImage;
    UIImage *_topArrowImageHighlighted;
    
    UIImage *_ridgeImage;
    
    UIFont *_font;
    
    CGRect *_regionRects;
    
    NSUInteger _selectedIndex;
    
    NSArray *_accessibilityElements;
}

@property (nonatomic, retain) NSArray *items;
@property (nonatomic, assign) NSUInteger selectedIndex;

- (void)positionAndResizeForAttachingToRect:(CGRect)rect fromView:(UIView *)view;

@end
