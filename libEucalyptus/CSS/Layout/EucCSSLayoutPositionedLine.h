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
            EucCSSLayoutDocumentRunPoint layoutPoint;
        } stringItem;
        struct {
            CGImageRef image;
            EucCSSLayoutDocumentRunPoint layoutPoint;
        } imageItem;
        struct {
            uint32_t nodeKey;
        } floatPlaceholderItem;
    } item;
    NSString *altText;
} EucCSSLayoutPositionedLineRenderItem;



@interface EucCSSLayoutPositionedLine : EucCSSLayoutPositionedContainer {
    EucCSSLayoutPositionedRun *_positionedRun;
    
    EucCSSLayoutDocumentRunPoint _startPoint;
    EucCSSLayoutDocumentRunPoint _endPoint;
    
    CGFloat _componentWidth;

    EucCSSLayoutPositionedLineLineBox _lineBox;
    CGFloat _baseline;

    
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

- (size_t)renderItemCount;
- (EucCSSLayoutPositionedLineRenderItem *)renderItems;

@end
