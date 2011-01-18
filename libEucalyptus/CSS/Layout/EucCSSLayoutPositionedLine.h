//
//  EucCSSLayoutPositionedLine.h
//  LibCSSTest
//
//  Created by James Montgomerie on 12/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucCSSLayoutRun.h"
#import "EucCSSLayoutPositionedContainer.h"

@class EucCSSLayoutRun, EucCSSLayoutPositionedRun, THStringRenderer;

typedef enum EucCSSLayoutPositionedLineRenderItemKind
{
    EucCSSLayoutPositionedLineRenderItemKindOpenNode,
    EucCSSLayoutPositionedLineRenderItemKindCloseNode,
    EucCSSLayoutPositionedLineRenderItemKindString,
    EucCSSLayoutPositionedLineRenderItemKindImage,
    EucCSSLayoutPositionedLineRenderItemKindFloatPlaceholder,
} EucCSSLayoutPositionedLineRenderItemKind;

typedef struct EucCSSLayoutPositionedLineLineBox
{
    CGFloat width;
    CGFloat height;
    CGFloat baseline;
    NSUInteger verticalAlign;
    CGFloat verticalAlignSetOffset;
} EucCSSLayoutPositionedLineLineBox;

typedef struct EucCSSLayoutPositionedLineRenderItem
{
    EucCSSLayoutPositionedLineRenderItemKind kind;
    NSUInteger parentIndex;
    CGPoint origin;
    EucCSSLayoutPositionedLineLineBox lineBox;
    union {
        struct {
            EucCSSIntermediateDocumentNode *node; // nonretained.
            BOOL implicit;
        } openNodeInfo;
        struct {
            EucCSSIntermediateDocumentNode *node; // nonretained.
            BOOL implicit;
        } closeNodeInfo;
        struct {
            NSString *string;
            CGFloat pointSize;
            EucCSSLayoutRunPoint layoutPoint;
        } stringItem;
        struct {
            CGImageRef image;
            EucCSSLayoutRunPoint layoutPoint;
        } imageItem;
        struct {
            uint32_t nodeKey;
        } floatPlaceholderItem;
    } item;
    NSString *altText;
} EucCSSLayoutPositionedLineRenderItem;

@interface EucCSSLayoutPositionedLine : EucCSSLayoutPositionedContainer {
    EucCSSLayoutPositionedRun *_positionedRun;
    
    EucCSSLayoutRunPoint _startPoint;
    EucCSSLayoutRunPoint _endPoint;
    CGFloat _componentWidth;

    CGRect _parentFrame;

    CGFloat _indent;
    uint8_t _align;
    
    EucCSSLayoutPositionedLineRenderItem *_renderItems;
    size_t _renderItemCount;
}

@property (nonatomic, assign) EucCSSLayoutRunPoint startPoint;
@property (nonatomic, assign) EucCSSLayoutRunPoint endPoint;
@property (nonatomic, assign) CGFloat componentWidth;

@property (nonatomic, assign) CGFloat indent;

@property (nonatomic, assign) uint8_t align;

- (void)sizeToFitInWidth:(CGFloat)width parentFrame:(CGRect)parentFrame;

- (size_t)renderItemCount;
- (EucCSSLayoutPositionedLineRenderItem *)renderItems;

@end
