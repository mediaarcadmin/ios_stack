//
//  EucCSSRenderer.m
//  LibCSSTest
//
//  Created by James Montgomerie on 10/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSInternal.h"
#import "EucCSSRenderer.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "EucCSSLayoutPositionedContainer.h"
#import "EucCSSLayoutPositionedBlock.h"
#import "EucCSSLayoutDocumentRun.h"
#import "EucCSSLayoutDocumentRun_Package.h"
#import "EucCSSLayoutPositionedRun.h"
#import "EucCSSLayoutPositionedLine.h"
#import "EucCSSRenderer.h"
#import "THStringRenderer.h"
#import "THLog.h"

#import <objc/message.h>
#import <libcss/libcss.h>

@interface EucCSSRenderer ()

- (void)_render:(id)layoutEntity;

@end

@implementation EucCSSRenderer

@synthesize cgContext = _cgContext;

static void CGContextSetFillColorWithCSSColor(CGContextRef context, css_color color) 
{
    CGFloat components[] = { 
        (CGFloat)(color & 0xFF000000) * (1.0f / (CGFloat)0xFF000000),
        (CGFloat)(color & 0xFF0000) * (1.0f / (CGFloat)0xFF0000),
        (CGFloat)(color & 0xFF00) * (1.0f / (CGFloat)0xFF00),
        1.0f
    };
    CGContextSetFillColor(context, components);
}

static void CGContextSetStrokeColorWithCSSColor(CGContextRef context, css_color color) 
{
    CGFloat components[] = { 
        (CGFloat)(color & 0xFF000000) * (1.0f / (CGFloat)0xFF000000),
        (CGFloat)(color & 0xFF0000) * (1.0f / (CGFloat)0xFF0000),
        (CGFloat)(color & 0xFF00) * (1.0f / (CGFloat)0xFF00),
        1.0f
    };
    CGContextSetStrokeColor(context, components);
}

- (void)render:(EucCSSLayoutPositionedContainer *)layoutEntity atPoint:(CGPoint)point
{
    // External generic entry point
    CGContextSaveGState(_cgContext);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextSetFillColorSpace(_cgContext, colorSpace);
    CGContextSetStrokeColorSpace(_cgContext, colorSpace);
    CFRelease(colorSpace);                      
    
    CGContextSetFillColorWithCSSColor(_cgContext, 0x000000FF);
    CGContextSetStrokeColorWithCSSColor(_cgContext, 0x000000FF);
    
    CGContextTranslateCTM(_cgContext, point.x, point.y);
    
    [self _render:(id)layoutEntity];
    
    CGContextRestoreGState(_cgContext);
}

- (void)_render:(EucCSSLayoutPositionedContainer *)layoutEntity 
{
    // Generic entry point will work out the method to call to render a layout
    // entity of this class.
    

    CGContextSaveGState(_cgContext);
    CGPoint point = layoutEntity.frame.origin;
    CGContextTranslateCTM(_cgContext, point.x, point.y);
    
    NSString *entityClassName = NSStringFromClass([layoutEntity class]);
    entityClassName = [entityClassName substringFromIndex:12]; // 12 for "EucCSSLayout"
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"_render%@:", entityClassName]);
    ((id(*)(id, SEL, id))objc_msgSend)(self, selector, layoutEntity);
    CGContextRestoreGState(_cgContext);

    /*
    CGContextSaveGState(_cgContext);
    CGContextSetStrokeColorWithCSSColor(_cgContext, 0xffff0000);
    CGContextStrokeRect(_cgContext, layoutEntity.frame);
    CGContextRestoreGState(_cgContext);
    */
}


- (void)_renderPositionedBlock:(EucCSSLayoutPositionedBlock *)block 
{
    THLogVerbose(@"Positioned Block: %@", NSStringFromCGRect(block.absoluteFrame));
    
    CGRect borderRect = block.borderRect;
    css_computed_style *computedStyle = block.computedStyle;
    css_color color;
    if(css_computed_background_color(computedStyle, &color) != CSS_BACKGROUND_COLOR_TRANSPARENT) {
        //color = 0xff000000;
        CGContextSaveGState(_cgContext);
        CGContextSetFillColorWithCSSColor(_cgContext, color);  
        CGContextFillRect(_cgContext, borderRect);
        CGContextRestoreGState(_cgContext);
    }
    
    CGRect paddingRect = block.paddingRect;
    if(!CGRectEqualToRect(borderRect, paddingRect)) {        
        // Non-zero border width.
        
        CGPoint maskPoints[4];

        // Top.
        {
            enum css_border_style_e borderStyle;
            if((borderStyle = css_computed_border_top_style(computedStyle)) != CSS_BORDER_STYLE_NONE) {
                if(css_computed_border_top_color(computedStyle, &color) != CSS_BORDER_COLOR_TRANSPARENT) {
                    CGContextSaveGState(_cgContext);
                    CGMutablePathRef maskPath = CGPathCreateMutable();
                    maskPoints[0] = CGPointMake(CGRectGetMinX(borderRect), CGRectGetMinY(borderRect));
                    maskPoints[1] = CGPointMake(CGRectGetMaxX(borderRect), CGRectGetMinY(borderRect));
                    maskPoints[2] = CGPointMake(CGRectGetMaxX(paddingRect), CGRectGetMinY(paddingRect));
                    maskPoints[3] = CGPointMake(CGRectGetMinX(paddingRect), CGRectGetMinY(paddingRect));
                    CGPathAddLines(maskPath, 0, maskPoints, 4);
                    CGContextAddPath(_cgContext, maskPath);
                    CGContextClip(_cgContext);
                    CGContextSetStrokeColorWithCSSColor(_cgContext, color);
                    CGPoint linePoints[2] = { 
                        CGPointMake((maskPoints[0].x + maskPoints[3].x) * 0.5f, (maskPoints[0].y + maskPoints[3].y) * 0.5f),
                        CGPointMake((maskPoints[1].x + maskPoints[2].x) * 0.5f, (maskPoints[1].y + maskPoints[2].y) * 0.5f),
                    };    
                    CGContextStrokeLineSegments(_cgContext, linePoints, 2);
                    CGPathRelease(maskPath);
                    CGContextRestoreGState(_cgContext);                
                }
            }
        }

        // Right.
        {
            enum css_border_style_e borderStyle;
            if((borderStyle = css_computed_border_right_style(computedStyle)) != CSS_BORDER_STYLE_NONE) {
                if(css_computed_border_right_color(computedStyle, &color) != CSS_BORDER_COLOR_TRANSPARENT) {
                    CGContextSaveGState(_cgContext);
                    CGMutablePathRef maskPath = CGPathCreateMutable();
                    maskPoints[0] = CGPointMake(CGRectGetMaxX(borderRect), CGRectGetMinY(borderRect));
                    maskPoints[1] = CGPointMake(CGRectGetMaxX(borderRect), CGRectGetMaxY(borderRect));
                    maskPoints[2] = CGPointMake(CGRectGetMaxX(paddingRect), CGRectGetMaxY(paddingRect));
                    maskPoints[3] = CGPointMake(CGRectGetMaxX(paddingRect), CGRectGetMinY(paddingRect));
                    CGPathAddLines(maskPath, 0, maskPoints, 4);
                    CGContextAddPath(_cgContext, maskPath);
                    CGContextClip(_cgContext);
                    CGContextSetStrokeColorWithCSSColor(_cgContext, color);
                    CGPoint linePoints[2] = { 
                        CGPointMake((maskPoints[0].x + maskPoints[3].x) * 0.5f, (maskPoints[0].y + maskPoints[3].y) * 0.5f),
                        CGPointMake((maskPoints[1].x + maskPoints[2].x) * 0.5f, (maskPoints[1].y + maskPoints[2].y) * 0.5f),
                    };    
                    CGContextStrokeLineSegments(_cgContext, linePoints, 2);
                    CGPathRelease(maskPath);
                    CGContextRestoreGState(_cgContext);
                }
            }
        }

        // Bottom.
        {
            enum css_border_style_e borderStyle;
            if((borderStyle = css_computed_border_bottom_style(computedStyle)) != CSS_BORDER_STYLE_NONE) {
                if(css_computed_border_bottom_color(computedStyle, &color) != CSS_BORDER_COLOR_TRANSPARENT) {
                    CGContextSaveGState(_cgContext);
                    CGMutablePathRef maskPath = CGPathCreateMutable();
                    maskPoints[0] = CGPointMake(CGRectGetMinX(borderRect), CGRectGetMaxY(borderRect));
                    maskPoints[1] = CGPointMake(CGRectGetMaxX(borderRect), CGRectGetMaxY(borderRect));
                    maskPoints[2] = CGPointMake(CGRectGetMaxX(paddingRect), CGRectGetMaxY(paddingRect));
                    maskPoints[3] = CGPointMake(CGRectGetMinX(paddingRect), CGRectGetMaxY(paddingRect));
                    CGPathAddLines(maskPath, 0, maskPoints, 4);
                    CGContextAddPath(_cgContext, maskPath);
                    CGContextClip(_cgContext);
                    CGContextSetStrokeColorWithCSSColor(_cgContext, color);
                    CGPoint linePoints[2] = { 
                        CGPointMake((maskPoints[0].x + maskPoints[3].x) * 0.5f, (maskPoints[0].y + maskPoints[3].y) * 0.5f),
                        CGPointMake((maskPoints[1].x + maskPoints[2].x) * 0.5f, (maskPoints[1].y + maskPoints[2].y) * 0.5f),
                    };    
                    CGContextStrokeLineSegments(_cgContext, linePoints, 2);
                    CGPathRelease(maskPath);
                    CGContextRestoreGState(_cgContext);
                }
            }
        }

        // Left.
        {
            enum css_border_style_e borderStyle;
            if((borderStyle = css_computed_border_left_style(computedStyle)) != CSS_BORDER_STYLE_NONE) {
                if(css_computed_border_left_color(computedStyle, &color) != CSS_BORDER_COLOR_TRANSPARENT) {
                    CGContextSaveGState(_cgContext);
                    CGMutablePathRef maskPath = CGPathCreateMutable();
                    maskPoints[0] = CGPointMake(CGRectGetMinX(borderRect), CGRectGetMaxY(borderRect));
                    maskPoints[1] = CGPointMake(CGRectGetMinX(borderRect), CGRectGetMinY(borderRect));
                    maskPoints[2] = CGPointMake(CGRectGetMinX(paddingRect), CGRectGetMinY(paddingRect));
                    maskPoints[3] = CGPointMake(CGRectGetMinX(paddingRect), CGRectGetMaxY(paddingRect));
                    CGPathAddLines(maskPath, 0, maskPoints, 4);
                    CGContextAddPath(_cgContext, maskPath);
                    CGContextClip(_cgContext);
                    CGContextSetStrokeColorWithCSSColor(_cgContext, color);
                    CGPoint linePoints[2] = { 
                        CGPointMake((maskPoints[0].x + maskPoints[3].x) * 0.5f, (maskPoints[0].y + maskPoints[3].y) * 0.5f),
                        CGPointMake((maskPoints[1].x + maskPoints[2].x) * 0.5f, (maskPoints[1].y + maskPoints[2].y) * 0.5f),
                    };    
                    CGContextStrokeLineSegments(_cgContext, linePoints, 2);
                    CGPathRelease(maskPath);
                    CGContextRestoreGState(_cgContext);
                }
            }
        }
    }
    
    CGContextSaveGState(_cgContext);
    
    CGRect contentRect = block.contentRect;
    if(!CGPointEqualToPoint(contentRect.origin, CGPointZero)) {
        CGContextTranslateCTM(_cgContext, contentRect.origin.x, contentRect.origin.y);
    }
    
    if(css_computed_color(computedStyle, &color) == CSS_COLOR_COLOR) {
        CGContextSetFillColorWithCSSColor(_cgContext, color);
        CGContextSetStrokeColorWithCSSColor(_cgContext, color);
    }
    for(id subEntity in block.children) {
        [self _render:subEntity];
    }
    for(id subEntity in block.leftFloatChildren) {
        [self _render:subEntity];
    }
    for(id subEntity in block.rightFloatChildren) {
        [self _render:subEntity];
    }
    CGContextRestoreGState(_cgContext);
    
    /*
    CGContextSaveGState(_cgContext);
    CGContextSetStrokeColorWithCSSColor(_cgContext, 0xff000000);
    CGContextStrokeRect(_cgContext, block.borderRect);
    CGContextRestoreGState(_cgContext);
    */
    
    THLogVerbose(@"Positioned Block End");
}


- (void)_renderPositionedRun:(EucCSSLayoutPositionedRun *)run 
{
    THLogVerbose(@"Positioned Run: %@", NSStringFromCGRect(run.absoluteFrame));
    //CGContextStrokeRectWithWidth(_cgContext, run.contentBounds, 0.25);

    for(EucCSSLayoutPositionedLine *line in run.children) {
        [self _render:line];
    }
    
    THLogVerbose(@"Positioned Run End");
}

- (void)_renderPositionedLine:(EucCSSLayoutPositionedLine *)line 
{
    THLogVerbose(@"Positioned Line: %@", NSStringFromCGRect(line.absoluteFrame));
    
    //CGContextStrokeRectWithWidth(_cgContext, line.contentBounds, 0.5);

    EucCSSLayoutPositionedLineRenderItem* renderItems = line.renderItems;
    size_t renderItemsCount = line.renderItemCount;
    
    EucCSSLayoutPositionedLineRenderItem* renderItem = renderItems;
    
    //BOOL currentUnderline = NO;
    //CGPoint underlinePoints[2] = { { 0 } };    
    CGFloat lastMaxX = 0.0f;
    
    CGContextSaveGState(_cgContext);

    CGPoint currentAbsoluteOrigin = CGPointZero;
    
    EucCSSIntermediateDocumentNode *currentDocumentNode;
    
    for(size_t i = 0; i < renderItemsCount; ++i, ++renderItem) {
        switch(renderItem->kind) {
            case EucCSSLayoutPositionedLineRenderItemKindOpenNode: 
            {
                CGContextSaveGState(_cgContext);

                currentDocumentNode = renderItem->item.openNodeInfo.node;  
                
                css_computed_style *style = currentDocumentNode.computedStyle;
                if(style) {
                    // Color.
                    css_color color = color; 
                    if(css_computed_color(style, &color) == CSS_COLOR_COLOR) {
                        CGContextSetFillColorWithCSSColor(_cgContext, color);
                        CGContextSetStrokeColorWithCSSColor(_cgContext, color);
                    }
                }
                
                currentAbsoluteOrigin.x += renderItem->origin.x;
                currentAbsoluteOrigin.y += renderItem->origin.y;
                break;    
            }
            case EucCSSLayoutPositionedLineRenderItemKindCloseNode:
            {
                EucCSSLayoutPositionedLineRenderItem* parentItem = renderItems + renderItem->parentIndex;
                
                css_computed_style *style = currentDocumentNode.computedStyle;
                if(style) {
                    // Underline.
                    enum css_text_decoration_e textDecoration = css_computed_text_decoration(style);
                    if(textDecoration & CSS_TEXT_DECORATION_UNDERLINE) {
                        CGPoint underlinePoints[2];
                        underlinePoints[0].x = floorf(currentAbsoluteOrigin.x);
                        underlinePoints[0].y = roundf(parentItem->lineBox.baseline + 1.0f) + 0.5f;
                        underlinePoints[1].x = ceilf(currentAbsoluteOrigin.x + renderItem->origin.x);
                        underlinePoints[1].y = roundf(renderItem->lineBox.baseline + 1.0f) + 0.5f;
                        CGContextStrokeLineSegments(_cgContext, underlinePoints, 2);
                    }
                }                    
                
                currentAbsoluteOrigin.x -= parentItem->origin.x;
                currentAbsoluteOrigin.y -= parentItem->origin.y;
                if(parentItem->parentIndex != NSUIntegerMax) {
                    currentDocumentNode = renderItems[parentItem->parentIndex].item.openNodeInfo.node;
                }
                
                CGContextRestoreGState(_cgContext);
                break;    
            }
            case EucCSSLayoutPositionedLineRenderItemKindString: 
            {
                CGRect rect = CGRectMake(currentAbsoluteOrigin.x + renderItem->origin.x,
                                         currentAbsoluteOrigin.y + renderItem->origin.y, 
                                         renderItem->lineBox.width, 
                                         renderItem->lineBox.height);
                [currentDocumentNode.stringRenderer drawString:renderItem->item.stringItem.string
                                                     inContext:_cgContext 
                                                       atPoint:rect.origin
                                                     pointSize:renderItem->lineBox.height];
                lastMaxX = CGRectGetMaxX(rect);
                break;
            }
            case EucCSSLayoutPositionedLineRenderItemKindImage: 
            {
                CGRect rect = CGRectMake(currentAbsoluteOrigin.x + renderItem->origin.x,
                                         currentAbsoluteOrigin.y + renderItem->origin.y, 
                                         renderItem->lineBox.width, 
                                         renderItem->lineBox.height);
                
                // Massage the rect a bit so that if it's an integral
                // width or height, it's placed on a pixel boundary.
                // (not worth trying if they're not integral width or height - 
                // may as well use the precise placement).
                if(fmodf(rect.size.width, 1) == 0.0f){
                    rect.origin.x = roundf(rect.origin.x);
                }
                if(fmodf(rect.size.height, 1) == 0.0f) {
                    rect.origin.y = roundf(rect.origin.y);
                }
                
                CGContextSaveGState(_cgContext);
                CGContextScaleCTM(_cgContext, 1.0f, -1.0f);
                CGContextTranslateCTM(_cgContext, rect.origin.x, -(rect.origin.y+rect.size.height));
                CGContextSetInterpolationQuality(_cgContext, kCGInterpolationHigh);
                CGContextDrawImage(_cgContext, CGRectMake(0, 0, rect.size.width, rect.size.height), renderItem->item.imageItem.image);
                CGContextRestoreGState(_cgContext);
                lastMaxX = CGRectGetMaxX(rect);
                break;
            }
            case EucCSSLayoutPositionedLineRenderItemKindFloatPlaceholder:
            {
                break;
            }
        }
    }

    CGContextRestoreGState(_cgContext);
    
    THLogVerbose(@"Positioned Line End");
}

@end
