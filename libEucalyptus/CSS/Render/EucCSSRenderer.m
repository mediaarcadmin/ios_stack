//
//  EucCSSRenderer.m
//  LibCSSTest
//
//  Created by James Montgomerie on 10/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSInternal.h"
#import "EucCSSRenderer.h"
#import "EucCSSIntermediateDocument.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "EucCSSLayoutPositionedContainer.h"
#import "EucCSSLayoutPositionedBlock.h"
#import "EucCSSLayoutRun.h"
#import "EucCSSLayoutRun_Package.h"
#import "EucCSSLayoutPositionedRun.h"
#import "EucCSSLayoutPositionedLine.h"
#import "EucCSSLayoutPositionedTable.h"
#import "EucCSSRenderer.h"
#import "THNSStringAdditions.h"
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

- (void)render:(EucCSSLayoutPositionedBlock *)layoutEntity atPoint:(CGPoint)point
{
    _currentScaleFactor = layoutEntity.scaleFactor;
    
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
    
    css_computed_style *computedStyle = block.documentNode.computedStyle;
    if(computedStyle) {
        CGRect borderRect = block.borderRect;
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
    }
    
    CGContextSaveGState(_cgContext);
    
    CGRect contentRect = block.contentRect;
    if(!CGPointEqualToPoint(contentRect.origin, CGPointZero)) {
        CGContextTranslateCTM(_cgContext, contentRect.origin.x, contentRect.origin.y);
    }
    
    if(computedStyle) {
        css_color color;
        if(css_computed_color(computedStyle, &color) == CSS_COLOR_COLOR) {
            CGContextSetFillColorWithCSSColor(_cgContext, color);
            CGContextSetStrokeColorWithCSSColor(_cgContext, color);
        }
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

- (void)_renderListItemBulletForRenderItem:(EucCSSLayoutPositionedLineRenderItem *)renderItem atBaselinePoint:(CGPoint)baselinePoint
{
    // TODO: support
    //css_computed_list_style_image(<#const css_computed_style *style#>, <#lwc_string **url#>);
    
    NSString *bulletString = @"";
    EucCSSIntermediateDocumentNode *documentNode = renderItem->item.openNodeInfo.node;

    enum css_list_style_type_e listStyleType = css_computed_list_style_type(documentNode.computedStyle);
    switch(listStyleType) {
        case CSS_LIST_STYLE_TYPE_DISC:
        {
            bulletString = @"\u2022";
            break;
        }
        case CSS_LIST_STYLE_TYPE_CIRCLE:
        {
            bulletString = @"\u25e6";
            break;
        }
        case CSS_LIST_STYLE_TYPE_SQUARE:
        {
            bulletString = @"\u25a0";
            break;
        }        
        default:
        {
            THWarn(@"Unsupported list style %ld", (long)listStyleType);
            listStyleType = CSS_LIST_STYLE_TYPE_DECIMAL;
            // Fall through.
        }            
        case CSS_LIST_STYLE_TYPE_DECIMAL:
        case CSS_LIST_STYLE_TYPE_DECIMAL_LEADING_ZERO:
        case CSS_LIST_STYLE_TYPE_LOWER_ROMAN:
        case CSS_LIST_STYLE_TYPE_UPPER_ROMAN:
        case CSS_LIST_STYLE_TYPE_LOWER_GREEK:
        case CSS_LIST_STYLE_TYPE_LOWER_LATIN:
        case CSS_LIST_STYLE_TYPE_UPPER_LATIN:
        case CSS_LIST_STYLE_TYPE_ARMENIAN:
        case CSS_LIST_STYLE_TYPE_GEORGIAN:
        case CSS_LIST_STYLE_TYPE_LOWER_ALPHA:
        case CSS_LIST_STYLE_TYPE_UPPER_ALPHA:
        {
            NSUInteger index = 0;
            EucCSSIntermediateDocumentNode *parentNode = documentNode.parent;
            EucCSSIntermediateDocument *document = parentNode.document;
            uint32_t myKey = renderItem->item.openNodeInfo.node.key;
            uint32_t childCount = parentNode.childCount;
            uint32_t *childKeys = parentNode.childKeys;
            for(uint32_t i = 0; i < childCount; ++i) {
                uint32_t siblingKey = childKeys[i];
                if(siblingKey == myKey) {
                    break;
                } 
                EucCSSIntermediateDocumentNode *siblingNode = [document nodeForKey:siblingKey];
                css_computed_style *siblingStyle = siblingNode.computedStyle;
                if(siblingStyle) {
                    if(siblingNode.display == CSS_DISPLAY_LIST_ITEM) {
                        ++index;
                    }
                }
            }
            switch(listStyleType) {
                case CSS_LIST_STYLE_TYPE_DECIMAL_LEADING_ZERO:
                {
                    bulletString = [NSString stringWithFormat:@"%02ld.", index + 1];
                    break;
                }
                case CSS_LIST_STYLE_TYPE_DECIMAL:
                {
                    bulletString = [NSString stringWithFormat:@"%ld.", index + 1];
                    break;
                }
                case CSS_LIST_STYLE_TYPE_LOWER_ROMAN:
                {
                    bulletString = [[[NSString stringWithRomanNumeralsFromInteger:index + 1] lowercaseString] stringByAppendingString:@"."];
                    break;
                }
                case CSS_LIST_STYLE_TYPE_UPPER_ROMAN:
                {
                    bulletString = [[NSString stringWithRomanNumeralsFromInteger:index + 1] stringByAppendingString:@"."];
                    break;
                }      
                case CSS_LIST_STYLE_TYPE_LOWER_GREEK:
                {
                    UniChar ch[2];
                    ch[0] = 0x03b1 + (index % 24);
                    ch[1] = '.';
                    bulletString = [NSString stringWithCharacters:ch length:2];
                    break;
                }                                        
                case CSS_LIST_STYLE_TYPE_LOWER_LATIN:
                case CSS_LIST_STYLE_TYPE_LOWER_ALPHA:
                {
                    UniChar ch[2];
                    ch[0] = 'a' + (index % 26);
                    ch[1] = '.';
                    bulletString = [NSString stringWithCharacters:ch length:2];
                    break;
                }                    
                case CSS_LIST_STYLE_TYPE_UPPER_LATIN:
                case CSS_LIST_STYLE_TYPE_UPPER_ALPHA:
                {
                    UniChar ch[2];
                    ch[0] = 'A' + (index % 26);
                    ch[1] = '.';
                    bulletString = [NSString stringWithCharacters:ch length:2];
                    break;
                }                    
                case CSS_LIST_STYLE_TYPE_ARMENIAN:
                {
                    UniChar ch[2];
                    ch[0] = 0x0531 + (index % 10);
                    ch[1] = '.';
                    bulletString = [NSString stringWithCharacters:ch length:2];
                    break;
                }
                case CSS_LIST_STYLE_TYPE_GEORGIAN:
                {
                    UniChar ch[2];
                    ch[0] = 0x10d0 + (index % 10);
                    ch[1] = '.';
                    bulletString = [NSString stringWithCharacters:ch length:2];
                    break;
                }                    
                default:
                    NSParameterAssert(false); // Shouldn't be possible to fall in here.
            }
            break;
        }
        case CSS_LIST_STYLE_TYPE_NONE:
        {
            return;
        }
    }
    
    THStringRenderer *stringRenderer = documentNode.stringRenderer;
    
    CGFloat pointSize = [documentNode textPointSizeWithScaleFactor:_currentScaleFactor];
    CGFloat bulletWidth = [stringRenderer widthOfString:bulletString pointSize:pointSize];
    
    [stringRenderer drawString:bulletString 
                     inContext:_cgContext
                       atPoint:CGPointMake(baselinePoint.x - bulletWidth, 
                                           baselinePoint.y - [stringRenderer ascenderForPointSize:pointSize])
                     pointSize:pointSize];
}

- (void)_renderPositionedLine:(EucCSSLayoutPositionedLine *)line 
{
    THLogVerbose(@"Positioned Line: %@", NSStringFromCGRect(line.absoluteFrame));
    //CGContextStrokeRectWithWidth(_cgContext, line.contentBounds, 0.5);

    EucCSSLayoutPositionedLineRenderItem *renderItems = line.renderItems;
    size_t renderItemsCount = line.renderItemCount;
    
    EucCSSLayoutPositionedLineRenderItem *renderItem = renderItems;

    CGContextSaveGState(_cgContext);

    CGPoint currentAbsoluteOrigin = CGPointZero;
    
    EucCSSIntermediateDocumentNode *currentDocumentNode = nil;
    
    for(size_t i = 0; i < renderItemsCount; ++i, ++renderItem) {
        switch(renderItem->kind) {
            case EucCSSLayoutPositionedLineRenderItemKindOpenNode: 
            {
                CGContextSaveGState(_cgContext);

                currentDocumentNode = renderItem->item.openNodeInfo.node;  
                
                css_computed_style *style = currentDocumentNode.computedStyle;
                if(style) {
                    // Color.
                    css_color color; 
                    if(css_computed_color(style, &color) == CSS_COLOR_COLOR) {
                        CGContextSetFillColorWithCSSColor(_cgContext, color);
                        CGContextSetStrokeColorWithCSSColor(_cgContext, color);
                    }
                    
                    // List bullet
                    if(!renderItem->item.openNodeInfo.implicit &&
                       currentDocumentNode.display == CSS_DISPLAY_LIST_ITEM) {
                        CGPoint baselinePoint = CGPointMake(currentAbsoluteOrigin.x + renderItem->origin.x - roundf(5.0f * _currentScaleFactor),
                                                            renderItem->lineBox.baseline);
                        [self _renderListItemBulletForRenderItem:renderItem 
                                                 atBaselinePoint:baselinePoint];
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
                CGPoint point = CGPointMake(currentAbsoluteOrigin.x + renderItem->origin.x,
                                            currentAbsoluteOrigin.y + renderItem->origin.y);
                [currentDocumentNode.stringRenderer drawString:renderItem->item.stringItem.string
                                                     inContext:_cgContext 
                                                       atPoint:point
                                                     pointSize:renderItem->lineBox.height];
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

- (void)_renderPositionedTable:(EucCSSLayoutPositionedTable *)table 
{
    CGContextStrokeRectWithWidth(_cgContext, table.contentBounds, 0.5);
}

@end
