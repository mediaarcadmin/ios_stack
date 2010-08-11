//
//  EucCSSLayoutPositionedContainer.m
//  libEucalyptus
//
//  Created by James Montgomerie on 22/07/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutPositionedContainer.h"

@implementation EucCSSLayoutPositionedContainer

@synthesize parent = _parent;
@synthesize frame = _frame;
@synthesize children = _children;

- (CGRect)contentRect
{
    CGRect ret = self.frame;
    ret.origin = CGPointZero;
    return ret;
}

- (void)dealloc
{
    [_children release];
    
    [super dealloc];
}

- (CGRect)frameInRelationTo:(EucCSSLayoutPositionedContainer *)otherContainer
{
    if(self.parent == otherContainer) {
        return self.frame;
    } else{
        CGRect myFrame = self.absoluteFrame;
        CGRect theirFrame = otherContainer.absoluteFrame;
        myFrame.origin.x -= theirFrame.origin.x;
        myFrame.origin.y -= theirFrame.origin.y;
        return myFrame;
    }
}

- (CGRect)convertRect:(CGRect)rect toContainer:(EucCSSLayoutPositionedContainer *)container;
{
    if(self == container) {
        return rect;
    } else {
        CGRect selfFrame = self.frame;
        CGRect selfContentRect = self.contentRect;
        rect.origin.x += selfFrame.origin.x + selfContentRect.origin.x;
        rect.origin.y += selfFrame.origin.y + selfContentRect.origin.y;
        EucCSSLayoutPositionedContainer *myParent = self.parent;
        if(!myParent) {
            return rect;
        } else {
            return [myParent convertRect:rect toContainer:container];
        }
    }
}

- (CGRect)absoluteFrame
{
    CGRect selfFrame = self.frame;
    EucCSSLayoutPositionedContainer *myParent = self.parent;
    if(!myParent) {
        return selfFrame;
    } else {
        return [myParent convertRect:selfFrame toContainer:nil];
    }    
}

- (CGRect)contentBounds
{
    CGRect contentBounds = self.contentRect;
    contentBounds.origin = CGPointZero;
    return contentBounds;
}

- (CGFloat)minimumWidth
{  
    return self.frame.size.width;
}

- (void)sizeToFitInWidth:(CGFloat)width {};

- (void)shrinkToFit
{
    [self sizeToFitInWidth:self.minimumWidth];
}

@end
