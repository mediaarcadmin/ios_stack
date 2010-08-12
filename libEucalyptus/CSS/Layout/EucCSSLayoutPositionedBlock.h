//
//  EucCSSLayoutPositionedBlock.h
//  LibCSSTest
//
//  Created by James Montgomerie on 12/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

#import "EucCSSLayoutPositionedContainer.h"

struct css_computed_style;

@class EucCSSIntermediateDocumentNode, THPair;

@interface EucCSSLayoutPositionedBlock : EucCSSLayoutPositionedContainer {
    EucCSSIntermediateDocumentNode *_documentNode;
    
    CGFloat _scaleFactor;
    
    CGRect _borderRect;
    CGRect _paddingRect;
    CGRect _contentRect;
    
    NSMutableArray *_leftFloatChildren;
    NSMutableArray *_rightFloatChildren;
    
    NSArray *_intrudingLeftFloats;
    NSArray *_intrudingRightFloats;
}

@property (nonatomic, retain) EucCSSIntermediateDocumentNode *documentNode;

@property (nonatomic, assign, readonly) struct css_computed_style *computedStyle;

@property (nonatomic, assign, readonly) CGRect borderRect;
@property (nonatomic, assign, readonly) CGRect paddingRect;
@property (nonatomic, assign, readonly) CGRect contentRect;

@property (nonatomic, retain, readonly) NSArray *leftFloatChildren;
@property (nonatomic, retain, readonly) NSArray *rightFloatChildren;

@property (nonatomic, retain) NSArray *intrudingLeftFloats;
@property (nonatomic, retain) NSArray *intrudingRightFloats;


- (id)initWithDocumentNode:(EucCSSIntermediateDocumentNode *)documentNode
               scaleFactor:(CGFloat)scaleFactor;

- (void)positionInFrame:(CGRect)frame
 afterInternalPageBreak:(BOOL)afterInternalPageBreak;

- (void)closeBottomWithContentHeight:(CGFloat)height atInternalPageBreak:(BOOL)atInternalPageBreak;

- (void)addChild:(EucCSSLayoutPositionedContainer *)child;
- (void)addFloatChild:(EucCSSLayoutPositionedContainer *)child 
           atContentY:(CGFloat)contentY
               onLeft:(BOOL)onLeft;

- (THPair *)floatsOverlappingYPoint:(CGFloat)contentY height:(CGFloat)height;

@end
