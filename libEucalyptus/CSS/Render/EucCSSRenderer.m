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
    
    BOOL currentUnderline = NO;
    CGPoint underlinePoints[2] = { { 0 } };    
    CGFloat lastMaxX = 0;
    
    for(size_t i = 0; i < renderItemsCount; ++i, ++renderItem) {
        switch(renderItem->kind) {
            case EucCSSLayoutPositionedLineRenderItemKindString: {
                CGRect rect = renderItem->item.stringItem.rect;
                [renderItem->item.stringItem.stringRenderer drawString:renderItem->item.stringItem.string
                                                             inContext:_cgContext 
                                                               atPoint:rect.origin
                                                             pointSize:renderItem->item.stringItem.pointSize];
                lastMaxX = CGRectGetMaxX(rect);
                break;
            }
            case EucCSSLayoutPositionedLineRenderItemKindImage: {
                CGRect rect = renderItem->item.stringItem.rect;
                CGContextSaveGState(_cgContext);
                CGContextScaleCTM(_cgContext, 1.0f, -1.0f);
                CGContextTranslateCTM(_cgContext, rect.origin.x, -(rect.origin.y+rect.size.height));
                CGContextSetInterpolationQuality(_cgContext, kCGInterpolationHigh);
                CGContextDrawImage(_cgContext, CGRectMake(0, 0, rect.size.width, rect.size.height), renderItem->item.imageItem.image);
                CGContextRestoreGState(_cgContext);
                lastMaxX = CGRectGetMaxX(rect);
                break;
            }
            case EucCSSLayoutPositionedLineRenderItemKindUnderlineStart: {
                currentUnderline = YES;
                underlinePoints[0] = renderItem->item.underlineItem.underlinePoint;
                underlinePoints[1].y = renderItem->item.underlineItem.underlinePoint.y;                
                break;
            }
            case EucCSSLayoutPositionedLineRenderItemKindUnderlineStop: {
                NSParameterAssert(currentUnderline);
                underlinePoints[1].x = renderItem->item.underlineItem.underlinePoint.x;
                CGContextStrokeLineSegments(_cgContext, underlinePoints, 2);
                currentUnderline = NO;                
                break;
            }
            case EucCSSLayoutPositionedLineRenderItemKindHyperlinkStart:
            case EucCSSLayoutPositionedLineRenderItemKindHyperlinkStop:
                break;
        }
    }

    if(currentUnderline) {
        underlinePoints[1].x = lastMaxX;
        CGContextStrokeLineSegments(_cgContext, underlinePoints, 2);        
    }
    
    THLogVerbose(@"Positioned Line End");
}

@end
