//
//  EucCSSLayoutPositionedLine.h
//  LibCSSTest
//
//  Created by James Montgomerie on 12/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucCSSLayoutDocumentRun.h"
#import "EucCSSLayoutPositionedContainer.h"

@class EucCSSLayoutDocumentRun, EucCSSLayoutPositionedRun, THStringRenderer;

typedef struct EucCSSLayoutPositionedLineRenderItem
{
    id item;
    CGRect rect;
    CGFloat pointSize;
    EucCSSLayoutDocumentRunPoint point;
    THStringRenderer *stringRenderer;
    NSString *altText;
} EucCSSLayoutPositionedLineRenderItem;

@interface EucCSSLayoutPositionedLine : EucCSSLayoutPositionedContainer {
    EucCSSLayoutPositionedRun *_positionedRun;
    
    EucCSSLayoutDocumentRunPoint _startPoint;
    EucCSSLayoutDocumentRunPoint _endPoint;
    
    CGFloat _baseline;
    CGFloat _componentWidth;
    
    CGFloat _indent;
    uint8_t _align;
    
    EucCSSLayoutPositionedLineRenderItem *_renderItems;
    size_t _renderItemCount;
}

@property (nonatomic, assign) EucCSSLayoutDocumentRunPoint startPoint;
@property (nonatomic, assign) EucCSSLayoutDocumentRunPoint endPoint;

@property (nonatomic, assign) CGFloat indent;
@property (nonatomic, assign) CGFloat baseline;

@property (nonatomic, assign) uint8_t align;

@property (nonatomic, readonly) CGFloat componentWidth;
@property (nonatomic, readonly) CGFloat minimumNeededWidth;

- (void)sizeToFitInWidth:(CGFloat)width;

- (size_t)renderItemCount;
- (EucCSSLayoutPositionedLineRenderItem *)renderItems;

@end
