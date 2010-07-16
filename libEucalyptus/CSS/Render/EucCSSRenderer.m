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
#import "EucCSSLayoutPositionedBlock.h"
#import "EucCSSLayoutDocumentRun.h"
#import "EucCSSLayoutDocumentRun_Package.h"
#import "EucCSSLayoutPositionedRun.h"
#import "EucCSSLayoutLine.h"
#import "EucCSSRenderer.h"
#import "THStringRenderer.h"
#import "THLog.h"

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

- (void)render:(id)layoutEntity
{
    // External generic entry point
    CGContextSaveGState(_cgContext);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextSetFillColorSpace(_cgContext, colorSpace);
    CGContextSetStrokeColorSpace(_cgContext, colorSpace);
    CFRelease(colorSpace);                      
    
    CGContextSetFillColorWithCSSColor(_cgContext, 0x000000FF);
    CGContextSetStrokeColorWithCSSColor(_cgContext, 0x000000FF);
    
    [self _render:(id)layoutEntity];
    
    CGContextRestoreGState(_cgContext);
}

- (void)_render:(id)layoutEntity
{
    // Generic entry point will work out the method to call to render a layout
    // entity of this class.
    
    NSString *entityClassName = NSStringFromClass([layoutEntity class]);
    if([entityClassName hasPrefix:@"EucCSSLayout"]) {
        entityClassName = [entityClassName substringFromIndex:12];
        SEL selector = NSSelectorFromString([NSString stringWithFormat:@"_render%@:", entityClassName]);
        [self performSelector:selector withObject:layoutEntity];
    } else {
        THWarn(@"Attempt to render entity that's not of known class: \"%@\", %@", entityClassName, layoutEntity);
    }
}


- (void)_renderPositionedBlock:(EucCSSLayoutPositionedBlock *)block
{
    THLogVerbose(@"Positioned Block: %@", NSStringFromCGRect(block.frame));
    
    css_computed_style *computedStyle = block.computedStyle;
    css_color color;
    
    if(css_computed_background_color(computedStyle, &color) != CSS_BACKGROUND_COLOR_TRANSPARENT) {
        CGContextSaveGState(_cgContext);
        CGContextSetFillColorWithCSSColor(_cgContext, color);  
        CGContextFillRect(_cgContext, block.borderRect);
        CGContextRestoreGState(_cgContext);
    }
    
    CGRect borderRect = block.borderRect;
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
    if(css_computed_color(computedStyle, &color) == CSS_COLOR_COLOR) {
        CGContextSetFillColorWithCSSColor(_cgContext, color);
        CGContextSetStrokeColorWithCSSColor(_cgContext, color);
    }
    for(id subEntity in block.subEntities) {
        [self _render:subEntity];
    }
    CGContextRestoreGState(_cgContext);
    
    THLogVerbose(@"Positioned Block End");
}


- (void)_renderPositionedRun:(EucCSSLayoutPositionedRun *)run
{
    THLogVerbose(@"Positioned Run: %@", NSStringFromCGRect(run.frame));
    //CGContextStrokeRectWithWidth(_cgContext, run.frame, 0.5);

    for(EucCSSLayoutLine *line in run.lines) {
        [self _render:line];
    }
    THLogVerbose(@"Positioned Run End");
}

- (void)_renderLine:(EucCSSLayoutLine *)line
{
    EucCSSLayoutLineRenderItem* renderItems = line.renderItems;
    size_t renderItemsCount = line.renderItemCount;
    
    CGContextStrokeRect(_cgContext, line.frame);
    
    EucCSSLayoutLineRenderItem* renderItem = renderItems;
    for(size_t i = 0; i < renderItemsCount; ++i, ++renderItem) {
        id item = renderItem->item;
        if([item isKindOfClass:[NSString class]]) {
            [renderItem->stringRenderer drawString:(NSString *)item
                                         inContext:_cgContext 
                                           atPoint:renderItem->rect.origin
                                         pointSize:renderItem->pointSize];
        } else {
            // It's an image.
            CGRect rect = renderItem->rect;
            CGContextSaveGState(_cgContext);
            CGContextScaleCTM(_cgContext, 1.0f, -1.0f);
            CGContextTranslateCTM(_cgContext, rect.origin.x, -(rect.origin.y+rect.size.height));
            CGContextSetInterpolationQuality(_cgContext, kCGInterpolationHigh);
            CGContextDrawImage(_cgContext, CGRectMake(0, 0, rect.size.width, rect.size.height), (CGImageRef)item);
            CGContextRestoreGState(_cgContext);
        }
    }
}

@end
