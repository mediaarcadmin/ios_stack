//
//  EucMenuView.m
//  libEucalyptus
//
//  Created by James Montgomerie on 05/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucMenuView.h"
#import "THUIImageAdditions.h"

static const CGFloat sExtraEdgeMargins = 4.0f;
static const CGFloat sInnerMargins = 14.0f;
static const CGFloat sOuterYPadding = 2.0f;

@interface EucMenuView ()

@property (nonatomic, assign) BOOL arrowAtTop;
@property (nonatomic, assign) CGFloat arrowMidX;
@property (nonatomic, assign) CGRect mainRect;

@property (nonatomic, readonly) UIImage *mainImage;
@property (nonatomic, readonly) UIImage *mainImageHighlighted;
@property (nonatomic, readonly) UIImage *leftShadowImage;
@property (nonatomic, readonly) UIImage *middleShadowImage;
@property (nonatomic, readonly) UIImage *rightShadowImage;
@property (nonatomic, readonly) UIImage *bottomArrowImage;
@property (nonatomic, readonly) UIImage *bottomArrowImageHighlighted;
@property (nonatomic, readonly) UIImage *topArrowImage;
@property (nonatomic, readonly) UIImage *topArrowImageHighlighted;
@property (nonatomic, readonly) UIImage *ridgeImage;
@property (nonatomic, readonly) UIFont *font;

@end

@implementation EucMenuView

@synthesize titles = _titles;
@synthesize colors = _colors;
@synthesize mainRect = _mainRect;
@synthesize arrowAtTop = _arrowAtTop;
@synthesize arrowMidX = _arrowMidX;

@synthesize selectedIndex = _selectedIndex;

- (id)initWithFrame:(CGRect)frame 
{
    if((self = [super initWithFrame:frame])) {
        self.opaque = NO;
        self.clearsContextBeforeDrawing = YES;
        
        self.multipleTouchEnabled = YES;
        self.exclusiveTouch = YES;
    }
    
    return self;
}

- (void)dealloc
{
    [_mainImage release];
    [_mainImageHighlighted release];
    
    [_leftShadowImage release];
    [_middleShadowImage release];
    [_rightShadowImage release];
    
    [_bottomArrowImage release];
    [_bottomArrowImageHighlighted release];
    [_topArrowImage release];
    [_topArrowImageHighlighted release];
    
    [_ridgeImage release];
    
    [_font release];
    
    free(_regionRects);
    
    [super dealloc];
}

- (BOOL)canBecomeFirstResponder
{
    return NO;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *ret = [super hitTest:point withEvent:event];
    if(ret == self) {
        if(!CGRectContainsPoint(self.mainRect, point)) {
            ret = nil;
        }
    }
    return ret;
}

- (void)positionAndResizeForAttachingToRect:(CGRect)rect
{
    CGRect superBounds = self.superview.bounds;
    CGFloat height = self.mainImage.size.height + self.bottomArrowImage.size.height;
    
    NSArray *titles = self.titles;
    NSUInteger titlesCount = titles.count;
    
    free(_regionRects);
    _regionRects = calloc(titlesCount, sizeof(CGRect));
    
    CGFloat mainRectHeight = self.mainImage.size.height;
    CGFloat ridgeWidth  = self.ridgeImage.size.width;
    UIFont *font = self.font;
    
    CGFloat width = sExtraEdgeMargins;
    for(NSUInteger i = 0; i < titlesCount; ++i) {
        if(i > 0) {
            width += ridgeWidth;
        }
        CGFloat startX = width;
        width += sInnerMargins;
        width += [[titles objectAtIndex:i] sizeWithFont:font].width;
        width += sInnerMargins;
        _regionRects[i].origin.x = i == 0 ? 0.0f : startX;
        _regionRects[i].size.width = width - _regionRects[i].origin.x;
        _regionRects[i].size.height = mainRectHeight;
    }
    _regionRects[titlesCount-1].size.width += sExtraEdgeMargins;
    width += sExtraEdgeMargins;
    
    CGPoint fixationPoint = CGPointMake(floorf(rect.origin.x + rect.size.width * 0.5), rect.origin.y - sOuterYPadding);
    if(fixationPoint.y - height < superBounds.origin.y) {
        self.arrowAtTop = YES;
        fixationPoint.y = rect.origin.y + rect.size.height + sOuterYPadding;
        if(fixationPoint.y + height > superBounds.size.height) {
            self.arrowAtTop = NO;
            fixationPoint.y = MIN(floorf(superBounds.size.height * 0.5f), superBounds.size.height - height);
        }
    } else {
        self.arrowAtTop = NO;
    }
    
    CGFloat minX = floorf(fixationPoint.x - width * 0.5f);
    if(minX + width > superBounds.origin.x + superBounds.size.width) {
        minX = superBounds.size.width - width;
    }
    if(minX < superBounds.origin.x) {
        minX = superBounds.origin.x;
    }
    
    self.frame = CGRectMake(minX, 
                            self.arrowAtTop ? fixationPoint.y : fixationPoint.y - height,
                            width, 
                            height);
    self.arrowMidX = fixationPoint.x - minX;
    
    CGRect mainRect = CGRectMake(0.0f, 0.0f, width, mainRectHeight);
    if(self.arrowAtTop) {
        mainRect.origin.y += self.topArrowImage.size.height - 1;
    }
    self.mainRect = mainRect;
    
    [self setNeedsDisplay];
}

-(void)_drawBackground:(CGRect)backgroundRect highlighted:(BOOL)highlighted
{
    CGRect mainRect = self.mainRect;
    
    UIImage *mainImage = highlighted ? self.mainImageHighlighted : self.mainImage;    
    [mainImage drawInRect:mainRect];
    
    UIImage *left = self.leftShadowImage;
    UIImage *middle = self.middleShadowImage;
    UIImage *right = self.rightShadowImage;
    
    CGFloat shadowY = mainRect.origin.y + mainImage.size.height;
    [left drawAtPoint:CGPointMake(mainRect.origin.x, shadowY)];
    [right drawAtPoint:CGPointMake(mainRect.origin.x + backgroundRect.size.width - right.size.width, shadowY)];
    
    if(self.arrowAtTop) {
        [middle drawInRect:CGRectMake(mainRect.origin.x + left.size.width, 
                                      shadowY, 
                                      backgroundRect.size.width - left.size.width - right.size.width, 
                                      middle.size.height)];
        
        UIImage *arrowImage = highlighted ? self.topArrowImageHighlighted : self.topArrowImage;
        CGFloat arrowXMargin = ceilf(left.size.width);
        CGPoint arrowPoint;
        arrowPoint.y = 0.0f;
        arrowPoint.x = floorf(_arrowMidX - arrowImage.size.width * 0.5f);
        if(arrowPoint.x < arrowXMargin) {
            arrowPoint.x = arrowXMargin;
        }
        if(arrowPoint.x > backgroundRect.size.width - arrowXMargin) {
            arrowPoint.x = backgroundRect.size.width - arrowXMargin - arrowImage.size.width;
        }
        [arrowImage drawAtPoint:arrowPoint];
    } else {
        UIImage *arrowImage =  self.bottomArrowImage;
        CGFloat arrowXMargin = ceilf(mainImage.size.width * 0.5f);
        CGPoint arrowPoint;
        arrowPoint.y = shadowY;
        arrowPoint.x = floorf(_arrowMidX - arrowImage.size.width * 0.5f);
        if(arrowPoint.x < arrowXMargin) {
            arrowPoint.x = arrowXMargin;
        }
        if(arrowPoint.x > backgroundRect.size.width - arrowXMargin) {
            arrowPoint.x = backgroundRect.size.width - arrowXMargin - arrowImage.size.width;
        }
        [arrowImage drawAtPoint:arrowPoint];
        
        // Weirdly the highlighted bottom arrow png is an overlay for the non-highlighted
        // arrow.
        if(highlighted) {
            [self.bottomArrowImageHighlighted drawAtPoint:arrowPoint];
        } 
        if(arrowPoint.x > left.size.width) {
            [middle drawInRect:CGRectMake(mainRect.origin.x + left.size.width, 
                                          shadowY, 
                                          arrowPoint.x - (mainRect.origin.x + left.size.width), 
                                          middle.size.height)];            
        }
        if(arrowPoint.x + arrowImage.size.width < backgroundRect.size.width - right.size.width) {
            [middle drawInRect:CGRectMake(arrowPoint.x + arrowImage.size.width, 
                                          shadowY, 
                                          (backgroundRect.size.width - right.size.width) - (arrowPoint.x + arrowImage.size.width), 
                                          middle.size.height)];            
        }
    }
}

- (void)drawRect:(CGRect)rect 
{
    CGRect bounds = self.bounds;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGContextClearRect(context, bounds);
    
    CGRect selectedRect = CGRectZero;
    NSUInteger selectedIndex = self.selectedIndex;
    if(self.selected) {
        CGContextSaveGState(context);
        // Mask out selected region.
        selectedRect = CGRectMake(_regionRects[selectedIndex].origin.x,
                                  0.0f, 
                                  _regionRects[selectedIndex].size.width,
                                  bounds.size.height);
        CGRect unselectedRects[2];
        unselectedRects[0] = CGRectMake(0.0f, 0.0f, _regionRects[selectedIndex].origin.x, self.bounds.size.height);
        unselectedRects[1].origin.x = selectedRect.origin.x + selectedRect.size.width;
        unselectedRects[1].origin.y = 0.0f;
        unselectedRects[1].size.width = bounds.size.width - unselectedRects[1].origin.x;
        unselectedRects[1].size.height = bounds.size.height;
        CGContextClipToRects(context, unselectedRects, 2);
    }
    [self _drawBackground:bounds highlighted:NO];
    if(self.selected) {
        // Mask in selected region.
        
        CGContextRestoreGState(context);
        CGContextSaveGState(context);
        CGContextClipToRect(context, selectedRect);
        [self _drawBackground:bounds highlighted:YES];
        CGContextRestoreGState(context);
    }
    
    NSArray *titles =  self.titles;
    NSArray *colors =  self.colors;
    NSUInteger titlesCount = titles.count;
    NSUInteger breaks = titlesCount - 1;
    for(int i = 0; i < breaks; ++i) {
        [self.ridgeImage drawAtPoint:CGPointMake(_regionRects[i].origin.x + _regionRects[i].size.width, self.mainRect.origin.y)];
    }
    
    CGFloat mainRectHeight = self.mainRect.size.height;
    UIFont *font = self.font;
    UIColor *whiteColor = [UIColor whiteColor];
    for(int i = 0; i < titlesCount; ++i) {
        NSString *title = [titles objectAtIndex:i];
        UIColor *color = [colors objectAtIndex:i];
        if(color && (id)color != (id)[NSNull null]) {
            [color set];
        } else {
            [whiteColor set];
        }
        
        CGSize titleSize = [title sizeWithFont:font];
        CGPoint stringPoint = CGPointMake(_regionRects[i].origin.x + sInnerMargins, self.mainRect.origin.y);
        if(i == 0) {
            stringPoint.x += sExtraEdgeMargins;
        }
        stringPoint.y += floorf((mainRectHeight - titleSize.height) * 0.5f);
        [title drawAtPoint:stringPoint withFont:font];
    }

    CGContextRestoreGState(context);
}


#pragma mark -
#pragma mark Touch Handling

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    NSUInteger selectedIndex = 0;
    BOOL inRect = NO;
    CGPoint touchPoint = [touch locationInView:self];
    NSUInteger titlesCount = self.titles.count;
    for(int i = 0; i < titlesCount; ++i) {
        if(CGRectContainsPoint(_regionRects[i], touchPoint)) {
            selectedIndex = i;
            inRect = YES;
        }
    }
    if(self.selected != inRect ||
       self.selectedIndex != selectedIndex) {
        self.selectedIndex = selectedIndex;
        self.selected = inRect;
        [self setNeedsDisplay];
    }
    
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event;
{
    if(self.selected) {
        NSUInteger upIndex = 0;
        BOOL inRect = NO;
        CGPoint touchPoint = [touch locationInView:self];
        NSUInteger titlesCount = self.titles.count;
        for(int i = 0; i < titlesCount; ++i) {
            if(CGRectContainsPoint(_regionRects[i], touchPoint)) {
                upIndex = i;
                inRect = YES;
            }
        }
        if(inRect && self.selectedIndex == upIndex) {
            self.selected = YES;
        } else {
            self.selected = NO;
            [self setNeedsDisplay];
        }
    }
    [super endTrackingWithTouch:touch withEvent:event];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
    if(self.selected) {
        self.selected = NO;
        [self setNeedsDisplay];
    }
}

#pragma mark -
#pragma mark Cached Properties

- (UIImage *)mainImage
{
    if(!_mainImage) {
        _mainImage = [[UIImage midpointStretchableImageNamed:@"MenuBackground.png"] retain];
    }
    return _mainImage;
}

- (UIImage *)mainImageHighlighted
{
    if(!_mainImageHighlighted) {
        _mainImageHighlighted = [[UIImage midpointStretchableImageNamed:@"MenuBackgroundHighlighted.png"] retain];
    }
    return _mainImageHighlighted;
}

- (UIImage *)leftShadowImage
{
    if(!_leftShadowImage) {
        _leftShadowImage = [[UIImage midpointStretchableImageNamed:@"MenuBottomShadowLeft.png"] retain];
    }
    return _leftShadowImage;
}

- (UIImage *)middleShadowImage
{
    if(!_middleShadowImage) {
        _middleShadowImage = [[UIImage midpointStretchableImageNamed:@"MenuBottomShadowMiddle.png"] retain];
    }
    return _middleShadowImage;
}

- (UIImage *)rightShadowImage
{
    if(!_rightShadowImage) {
        _rightShadowImage = [[UIImage midpointStretchableImageNamed:@"MenuBottomShadowRight.png"] retain];
    }
    return _rightShadowImage;
}

- (UIImage *)bottomArrowImage
{
    if(!_bottomArrowImage) {
        _bottomArrowImage = [[UIImage midpointStretchableImageNamed:@"MenuArrowBottom.png"] retain];
    }
    return _bottomArrowImage;
}

- (UIImage *)bottomArrowImageHighlighted
{
    if(!_bottomArrowImageHighlighted) {
        _bottomArrowImageHighlighted = [[UIImage midpointStretchableImageNamed:@"MenuArrowBottomHighlighted.png"] retain];
    }
    return _bottomArrowImageHighlighted;
}

- (UIImage *)topArrowImage
{
    if(!_topArrowImage) {
        _topArrowImage = [[UIImage midpointStretchableImageNamed:@"MenuArrowTop.png"] retain];
    }
    return _topArrowImage;
}

- (UIImage *)topArrowImageHighlighted
{
    if(!_topArrowImageHighlighted) {
        _topArrowImageHighlighted = [[UIImage midpointStretchableImageNamed:@"MenuArrowTopHighlighted.png"] retain];
    }
    return _topArrowImageHighlighted;
}

- (UIImage *)ridgeImage
{
    if(!_ridgeImage) {
        _ridgeImage = [[UIImage midpointStretchableImageNamed:@"MenuRidge.png"] retain];
    }
    return _ridgeImage;
}

- (UIFont *)font
{
    if(!_font) {
        _font = [[UIFont boldSystemFontOfSize:[UIFont systemFontSize]] retain];
    }
    return _font;
}
        
@end
