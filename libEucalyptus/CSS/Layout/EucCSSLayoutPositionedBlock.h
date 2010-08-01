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

@class EucCSSIntermediateDocumentNode;

@interface EucCSSLayoutPositionedBlock : EucCSSLayoutPositionedContainer {
    EucCSSIntermediateDocumentNode *_documentNode;
    
    CGFloat _scaleFactor;
    
    CGRect _borderRect;
    CGRect _paddingRect;
    CGRect _contentRect;
}

@property (nonatomic, retain) EucCSSIntermediateDocumentNode *documentNode;

@property (nonatomic, assign, readonly) struct css_computed_style *computedStyle;

@property (nonatomic, assign, readonly) CGRect borderRect;
@property (nonatomic, assign, readonly) CGRect paddingRect;
@property (nonatomic, assign, readonly) CGRect contentRect;

- (id)initWithDocumentNode:(EucCSSIntermediateDocumentNode *)documentNode
               scaleFactor:(CGFloat)scaleFactor;

- (void)positionInFrame:(CGRect)frame
 afterInternalPageBreak:(BOOL)afterInternalPageBreak;

- (void)closeBottomWithContentHeight:(CGFloat)height atInternalPageBreak:(BOOL)atInternalPageBreak;

- (void)addChild:(EucCSSLayoutPositionedContainer *)child;

@end
