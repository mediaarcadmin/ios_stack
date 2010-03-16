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

@implementation EucCSSRenderer

@synthesize cgContext = _cgContext;

- (void)render:(id)layoutEntity
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
    THLog(@"Positioned Block: %@", NSStringFromCGRect(block.frame));
    for(id subEntity in block.subEntities) {
        
        //CGContextStrokeRectWithWidth(_cgContext, block.frame, 2);
        
        [self render:subEntity];
    }    
    THLog(@"Positioned Block End");
}


- (void)_renderPositionedRun:(EucCSSLayoutPositionedRun *)run
{
    THLog(@"Positioned Run: %@", NSStringFromCGRect(run.frame));
    //CGContextStrokeRectWithWidth(_cgContext, run.frame, 0.5);

    for(EucCSSLayoutLine *line in run.lines) {
        [self render:line];
    }
    THLog(@"Positioned Run End");
}

- (void)_renderLine:(EucCSSLayoutLine *)line
{
    Class nsStringClass = [NSString class];
    Class uiImageClass = [UIImage class];
    id singleSpaceMarker = [EucCSSLayoutDocumentRun singleSpaceMarker];
    
    EucCSSLayoutDocumentRun *documentRun = line.containingRun.documentRun;
    
    size_t componentsCount = documentRun.componentsCount;
    id *components = documentRun.components;
    EucCSSLayoutDocumentRunComponentInfo *componentInfos = documentRun.componentInfos;
    
    EucCSSLayoutDocumentRunPoint startPoint = line.startPoint;
    EucCSSLayoutDocumentRunPoint endPoint = line.endPoint;
        
    CGRect lineFrame = line.frame;
    CGFloat xPosition = lineFrame.origin.x;
    CGFloat yPosition = lineFrame.origin.y;
    CGFloat baseline = line.baseline;
    switch(line.align) {
        case CSS_TEXT_ALIGN_RIGHT:
            {
                xPosition += lineFrame.size.width;
                for(uint32_t i = documentRun.wordToComponent[startPoint.word] + startPoint.element;
                    i < componentsCount &&
                    !(componentInfos[i].point.word == endPoint.word && componentInfos[i].point.element == endPoint.element); 
                    ++i) {
                    id component = components[i];
                    EucCSSLayoutDocumentRunComponentInfo *componentInfo = &(componentInfos[i]); 
                    if([component isKindOfClass:nsStringClass]) {
                        THStringRenderer *stringRenderer = componentInfo->documentNode.stringRenderer;
                        [stringRenderer drawString:component
                                         inContext:_cgContext 
                                           atPoint:CGPointMake(xPosition, yPosition + baseline - componentInfo->ascender)
                                         pointSize:componentInfo->pointSize];
                    } else if([component isKindOfClass:uiImageClass]) {
                        CGRect rect = CGRectMake(xPosition, yPosition + baseline - componentInfo->ascender,
                                                 componentInfo->width, componentInfo->pointSize);
                        CGContextSaveGState(_cgContext);
                        CGContextScaleCTM(_cgContext, 1.0f, -1.0f);
                        CGContextTranslateCTM(_cgContext, rect.origin.x, -(rect.origin.y+rect.size.height));
                        CGContextSetInterpolationQuality(_cgContext, kCGInterpolationHigh);
                        CGContextDrawImage(_cgContext, CGRectMake(0, 0, rect.size.width, rect.size.height), [(UIImage *)component CGImage]);
                        CGContextRestoreGState(_cgContext);
                    }
                    xPosition -= componentInfo->width;
                }
            }
            break;            
        case CSS_TEXT_ALIGN_JUSTIFY:
            {
                CGFloat extraWidthNeeded = lineFrame.size.width - line.indent - line.componentWidth;
                CGFloat spacesRemaining = 0.0f;
                for(uint32_t i = documentRun.wordToComponent[startPoint.word] + startPoint.element;
                    i < componentsCount &&
                    !(componentInfos[i].point.word == endPoint.word && componentInfos[i].point.element == endPoint.element); 
                    ++i) {
                    if(components[i] == singleSpaceMarker) {
                        spacesRemaining++;
                    }
                }
                xPosition += line.indent;
                for(uint32_t i = documentRun.wordToComponent[startPoint.word] + startPoint.element;
                    i < componentsCount &&
                    !(componentInfos[i].point.word == endPoint.word && componentInfos[i].point.element == endPoint.element); 
                    ++i) {
                    id component = components[i];
                    EucCSSLayoutDocumentRunComponentInfo *componentInfo = &(componentInfos[i]); 
                    if([component isKindOfClass:nsStringClass]) {
                        THStringRenderer *stringRenderer = componentInfo->documentNode.stringRenderer;
                        [stringRenderer drawString:component
                                         inContext:_cgContext 
                                           atPoint:CGPointMake(xPosition, yPosition + baseline - componentInfo->ascender)
                                         pointSize:componentInfo->pointSize];
                    } else if(component == singleSpaceMarker) {
                        CGFloat extraSpace = extraWidthNeeded / spacesRemaining;
                        xPosition += extraSpace;
                        extraWidthNeeded -= extraSpace;
                        --spacesRemaining;
                    } else if([component isKindOfClass:uiImageClass]) {
                        CGRect rect = CGRectMake(xPosition, yPosition + baseline - componentInfo->ascender,
                                                 componentInfo->width, componentInfo->pointSize);
                        CGContextSaveGState(_cgContext);
                        CGContextScaleCTM(_cgContext, 1.0f, -1.0f);
                        CGContextTranslateCTM(_cgContext, rect.origin.x, -(rect.origin.y+rect.size.height));
                        CGContextSetInterpolationQuality(_cgContext, kCGInterpolationHigh);
                        CGContextDrawImage(_cgContext, CGRectMake(0, 0, rect.size.width, rect.size.height), [(UIImage *)component CGImage]);
                        CGContextRestoreGState(_cgContext);
                    }
                    xPosition += componentInfo->width;
                }                
            }
            break;
        case CSS_TEXT_ALIGN_CENTER:
            xPosition += (lineFrame.size.width - line.componentWidth) * 0.5f;
            // fall through.
        default:
            {
                xPosition += line.indent;
                for(uint32_t i = documentRun.wordToComponent[startPoint.word] + startPoint.element;
                    i < componentsCount &&
                    !(componentInfos[i].point.word == endPoint.word && componentInfos[i].point.element == endPoint.element); 
                    ++i) {
                    id component = components[i];
                    EucCSSLayoutDocumentRunComponentInfo *componentInfo = &(componentInfos[i]); 
                    if([component isKindOfClass:nsStringClass]) {
                        THStringRenderer *stringRenderer = componentInfo->documentNode.stringRenderer;
                        [stringRenderer drawString:component
                                         inContext:_cgContext 
                                           atPoint:CGPointMake(xPosition, yPosition + baseline - componentInfo->ascender)
                                         pointSize:componentInfo->pointSize];
                    } else if([component isKindOfClass:uiImageClass]) {
                        CGRect rect = CGRectMake(xPosition, yPosition + baseline - componentInfo->ascender,
                                                 componentInfo->width, componentInfo->pointSize);
                        CGContextSaveGState(_cgContext);
                        CGContextScaleCTM(_cgContext, 1.0f, -1.0f);
                        CGContextTranslateCTM(_cgContext, rect.origin.x, -(rect.origin.y+rect.size.height));
                        CGContextSetInterpolationQuality(_cgContext, kCGInterpolationHigh);
                        CGContextDrawImage(_cgContext, CGRectMake(0, 0, rect.size.width, rect.size.height), [(UIImage *)component CGImage]);
                        CGContextRestoreGState(_cgContext);
                    }
                    xPosition += componentInfo->width;
                }
            }
            break;
    }
}

@end
