//
//  EucCSSLayoutPositionedContainer.m
//  libEucalyptus
//
//  Created by James Montgomerie on 22/07/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutPositionedContainer.h"
#import "EucCSSLayoutPositionedBlock.h"

#import "EucCSSIntermediateDocumentNode.h"

#import "THPair.h"

#import <libcss/libcss.h>

@implementation EucCSSLayoutPositionedContainer

@synthesize parent = _parent;
@synthesize frame = _frame;
@synthesize children = _children;

@synthesize leftFloatChildren = _leftFloatChildren;
@synthesize rightFloatChildren = _rightFloatChildren;

@synthesize intrudingLeftFloats = _intrudingLeftFloats;
@synthesize intrudingRightFloats = _intrudingRightFloats;

- (void)dealloc
{
    [_children release];
    
    if(_leftFloatChildren) {
        [_leftFloatChildren release];
    }
    if(_rightFloatChildren) {
        [_rightFloatChildren release];
    }
    if(_intrudingLeftFloats) {
        [_intrudingLeftFloats release];
    }
    if(_intrudingRightFloats) {
        [_intrudingRightFloats release];
    }        
    
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

- (CGRect)contentRect
{
    CGRect ret = self.frame;
    ret.origin = CGPointZero;
    return ret;
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

- (void)addChild:(EucCSSLayoutPositionedContainer *)child
{
    if(!_children) {
        _children = [[NSMutableArray alloc] init]; 
    }
    [_children addObject:child];
    child.parent = self;
    
    if([child isKindOfClass:[EucCSSLayoutPositionedBlock class]]) {
        EucCSSLayoutPositionedBlock *subBlock = (EucCSSLayoutPositionedBlock *)child;
        if(css_computed_float(subBlock.documentNode.computedStyle) == CSS_FLOAT_NONE) {
            [subBlock collapseTopMarginUpwards];
        }
    }    
}    

- (THPair *)floatsOverlappingYPoint:(CGFloat)contentY height:(CGFloat)height
{
    NSMutableArray *leftRet = nil;
    if(_intrudingLeftFloats) {
        if(!leftRet) {
            leftRet = [[NSMutableArray alloc]  initWithCapacity:_intrudingLeftFloats.count];
        }
        for(EucCSSLayoutPositionedContainer *candidateFloat in _intrudingLeftFloats) {
            CGRect floatFrame = [candidateFloat frameInRelationTo:self];
            if(!(contentY + height < floatFrame.origin.y || 
                 contentY > floatFrame.origin.y + floatFrame.size.height)) {
                [leftRet addObject:candidateFloat];
            }
        }
    }
    if(_leftFloatChildren) {
        if(!leftRet) {
            leftRet = [[NSMutableArray alloc]  initWithCapacity:_leftFloatChildren.count];
        }
        for(EucCSSLayoutPositionedContainer *candidateFloat in _leftFloatChildren) {
            CGRect floatFrame = candidateFloat.frame;
            if(!(contentY + height < floatFrame.origin.y || 
                 contentY > floatFrame.origin.y + floatFrame.size.height)) {
                [leftRet addObject:candidateFloat];
            }
        }
    }
    if(leftRet && !leftRet.count) {
        [leftRet release];
        leftRet = nil;
    }
    
    
    NSMutableArray *rightRet = nil;
    if(_intrudingRightFloats) {
        if(!rightRet) {
            rightRet = [[NSMutableArray alloc]  initWithCapacity:_intrudingRightFloats.count];
        }
        for(EucCSSLayoutPositionedContainer *candidateFloat in _intrudingRightFloats) {
            CGRect floatFrame = [candidateFloat frameInRelationTo:self];
            if(!(contentY + height < floatFrame.origin.y || 
                 contentY > floatFrame.origin.y + floatFrame.size.height)) {
                [rightRet addObject:candidateFloat];
            }
        }
    }    
    if(_rightFloatChildren) {
        if(!rightRet) {
            rightRet = [[NSMutableArray alloc]  initWithCapacity:_rightFloatChildren.count];
        }
        for(EucCSSLayoutPositionedContainer *candidateFloat in _rightFloatChildren) {
            CGRect floatFrame = candidateFloat.frame;
            if(!(contentY + height < floatFrame.origin.y || 
                 contentY > floatFrame.origin.y + floatFrame.size.height)) {
                [rightRet addObject:candidateFloat];
            }
        }
    }
    if(rightRet && !rightRet.count) {
        [rightRet release];
        rightRet = nil;
    }
    
    
    if(rightRet || leftRet) {
        THPair *ret = [THPair pairWithFirst:leftRet second:rightRet];
        [leftRet release];
        [rightRet release];
        return ret;
    } else {
        return nil;
    }
}

- (void)addFloatChild:(EucCSSLayoutPositionedContainer *)child 
           atContentY:(CGFloat)contentY
               onLeft:(BOOL)onLeft
{
    BOOL placeFound = NO;
    CGRect childFrame = child.frame;
    CGFloat floatHeight = childFrame.size.height;
    CGFloat floatWidth = childFrame.size.width;
    CGFloat myContentWidth = self.contentRect.size.width;
    
    THPair *overlapping;
    do {
        overlapping = [self floatsOverlappingYPoint:contentY height:floatHeight];
        if(!overlapping) {
            placeFound = YES;
        } else {
            CGFloat leftUsedWidth = 0;
            NSArray *leftOverlaps = overlapping.first;
            if(leftOverlaps) {
                for(EucCSSLayoutPositionedContainer *lefter in leftOverlaps) {
                    CGFloat lefterMaxX = CGRectGetMaxX([lefter frameInRelationTo:self]);
                    if(lefterMaxX > leftUsedWidth) {
                        leftUsedWidth = lefterMaxX;
                    }
                }
            }
            
            CGFloat rightmostX = myContentWidth;
            NSArray *rightOverlaps = overlapping.second;
            if(rightOverlaps) {
                for(EucCSSLayoutPositionedContainer *righter in rightOverlaps) {
                    CGFloat righterMinX = CGRectGetMinX([righter frameInRelationTo:self]);
                    if(righterMinX < rightmostX) {
                        rightmostX = righterMinX;
                    }
                }
            }
            
            CGFloat remaining = rightmostX - leftUsedWidth;
            if(remaining > floatWidth) {
                placeFound = YES;
            } else {
                CGFloat smallestNextY = CGFLOAT_MAX;
                if(leftOverlaps) {
                    for(EucCSSLayoutPositionedContainer *lefter in leftOverlaps) {
                        CGFloat bottom = CGRectGetMaxY([lefter frameInRelationTo:self]);
                        if(bottom < smallestNextY) {
                            smallestNextY = bottom;
                        }
                    }
                }
                if(rightOverlaps) {
                    for(EucCSSLayoutPositionedContainer *righter in rightOverlaps) {
                        CGFloat bottom = CGRectGetMaxY([righter frameInRelationTo:self]);
                        if(bottom < smallestNextY) {
                            smallestNextY = bottom;
                        }
                    }
                }
                contentY = smallestNextY + 1;
            }
        }
    } while(!placeFound);
    
    CGFloat contentX;
    if(onLeft) {
        contentX = 0;
        NSArray *leftOverlaps = overlapping.first;
        if(leftOverlaps) {
            for(EucCSSLayoutPositionedContainer *lefter in leftOverlaps) {
                CGFloat leftPoint = CGRectGetMaxX([lefter frameInRelationTo:self]);
                if(leftPoint > contentX) {
                    contentX = leftPoint;
                }
            }
        }
        
        if(!_leftFloatChildren) {
            _leftFloatChildren = [[NSMutableArray alloc] init];
        }
        [_leftFloatChildren addObject:child];
    } else {
        contentX = myContentWidth;
        NSArray *rightOverlaps = overlapping.second;
        if(rightOverlaps) {
            for(EucCSSLayoutPositionedContainer *righter in rightOverlaps) {
                CGFloat rightMinPoint = CGRectGetMinX([righter frameInRelationTo:self]);
                if(rightMinPoint < contentX) {
                    contentX = rightMinPoint;
                }
            }
        } 
        contentX -= floatWidth;
        
        if(!_rightFloatChildren) {
            _rightFloatChildren = [[NSMutableArray alloc] init];
        }        
        [_rightFloatChildren addObject:child];
    }
    
    childFrame.origin.x = contentX;
    childFrame.origin.y = contentY;
    
    child.frame = childFrame;
    
    child.parent = self;
}

- (void)closeBottomWithContentHeight:(CGFloat)height
{
    _frame.size.height = height;
}

@end
