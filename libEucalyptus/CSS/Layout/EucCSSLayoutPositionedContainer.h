//
//  EucCSSLayoutPositionedContainer.h
//  libEucalyptus
//
//  Created by James Montgomerie on 22/07/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

@class THPair;

@interface EucCSSLayoutPositionedContainer : NSObject { 
    EucCSSLayoutPositionedContainer *_parent;
    CGRect _frame;
    NSMutableArray *_children;
    
    
    NSMutableArray *_leftFloatChildren;
    NSMutableArray *_rightFloatChildren;
    
    NSArray *_intrudingLeftFloats;
    NSArray *_intrudingRightFloats;    
}

@property (nonatomic, assign) EucCSSLayoutPositionedContainer *parent;
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign, readonly) CGRect contentRect;
@property (nonatomic, assign, readonly) CGRect contentBounds;
@property (nonatomic, retain) NSMutableArray *children;

@property (nonatomic, retain, readonly) NSArray *leftFloatChildren;
@property (nonatomic, retain, readonly) NSArray *rightFloatChildren;

@property (nonatomic, retain) NSArray *intrudingLeftFloats;
@property (nonatomic, retain) NSArray *intrudingRightFloats;

- (void)addFloatChild:(EucCSSLayoutPositionedContainer *)child 
           atContentY:(CGFloat)contentY
               onLeft:(BOOL)onLeft;

- (THPair *)floatsOverlappingYPoint:(CGFloat)contentY height:(CGFloat)height;

- (CGRect)frameInRelationTo:(EucCSSLayoutPositionedContainer *)otherContainer;
- (CGRect)convertRect:(CGRect)rect toContainer:(EucCSSLayoutPositionedContainer *)container;
- (CGRect)absoluteFrame;

@property (nonatomic, assign, readonly) CGFloat minimumWidth; // Just returns the current width.
- (void)sizeToFitInWidth:(CGFloat)width;                      // Default behaviour does nothing.
- (void)shrinkToFit;

@end
