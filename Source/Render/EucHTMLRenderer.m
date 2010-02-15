//
//  EucHTMLRenderer.m
//  LibCSSTest
//
//  Created by James Montgomerie on 10/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucHTMLRenderer.h"
#import "EucHTMLDocumentNode.h"
#import "EucHTMLLayoutPositionedBlock.h"
#import "EucHTMLLayoutDocumentRun.h"
#import "EucHTMLLayoutPositionedRun.h"
#import "EucHTMLLayoutLine.h"
#import "EucHTMLRenderer.h"
#import "THStringRenderer.h"
#import "THLog.h"


@implementation EucHTMLRenderer

@synthesize cgContext = _cgContext;

- (void)render:(id)layoutEntity
{
    // Generic entry point will work out the method to call to render a layout
    // entity of this class.
    
    NSString *entityClassName = NSStringFromClass([layoutEntity class]);
    if([entityClassName hasPrefix:@"EucHTMLLayout"]) {
        entityClassName = [entityClassName substringFromIndex:13];
        SEL selector = NSSelectorFromString([NSString stringWithFormat:@"_render%@:", entityClassName]);
        [self performSelector:selector withObject:layoutEntity];
    } else {
        THWarn(@"Attempt to render entity that's not of known class: \"%@\", %@", entityClassName, layoutEntity);
    }
}

- (void)_renderPositionedBlock:(EucHTMLLayoutPositionedBlock *)block
{
    NSLog(@"Positioned Block: %@", NSStringFromRect(NSRectFromCGRect(block.frame)));
    for(id subEntity in block.subEntities) {
        [self render:subEntity];
    }    
    NSLog(@"Positioned Block End");
}


- (void)_renderPositionedRun:(EucHTMLLayoutPositionedRun *)run
{
    NSLog(@"Positioned Run: %@", NSStringFromRect(NSRectFromCGRect(run.frame)));
    for(EucHTMLLayoutLine *line in run.lines) {
        [self render:line];
    }
    NSLog(@"Positioned Run End");
}

- (void)_renderLine:(EucHTMLLayoutLine *)line
{
    id *components = line.components;
    EucHTMLLayoutDocumentRunComponentInfo *componentInfos = line.componentInfos;
    uint32_t componentCount = line.componentCount;
    Class nsStringClass = [NSString class];
    id singleSpaceMarker = [EucHTMLLayoutDocumentRun singleSpaceMarker];
    
    CGRect lineFrame = line.frame;
    CGFloat xPosition = lineFrame.origin.x;
    CGFloat yPosition = lineFrame.origin.y;
    switch(line.align) {
        case CSS_TEXT_ALIGN_RIGHT:
            {
                xPosition += lineFrame.size.width;
                for(uint32_t i = 0; i < componentCount; ++i) {
                    id component = components[i];
                    EucHTMLLayoutDocumentRunComponentInfo *componentInfo = &(componentInfos[i]); 
                    if([component isKindOfClass:nsStringClass]) {
                        xPosition -= componentInfo->width;
                        THStringRenderer *stringRenderer = componentInfo->documentNode.stringRenderer;
                        [stringRenderer drawString:component
                                         inContext:_cgContext 
                                           atPoint:CGPointMake(xPosition, yPosition)
                                         pointSize:componentInfo->pointSize];
                    } else if(component == singleSpaceMarker) {
                        xPosition -= componentInfo->width;
                    }
                }
            }
            break;            
        case CSS_TEXT_ALIGN_JUSTIFY:
            {
                CGFloat extraWidthNeeded = lineFrame.size.width - line.indent - line.componentWidth;
                CGFloat spacesRemaining = 0.0f;
                for(uint32_t i = 0; i < componentCount; ++i) {
                    if(components[i] == singleSpaceMarker) {
                        spacesRemaining++;
                    }
                }
                xPosition += line.indent;
                for(uint32_t i = 0; i < componentCount; ++i) {
                    id component = components[i];
                    EucHTMLLayoutDocumentRunComponentInfo *componentInfo = &(componentInfos[i]); 
                    if([component isKindOfClass:nsStringClass]) {
                        THStringRenderer *stringRenderer = componentInfo->documentNode.stringRenderer;
                        [stringRenderer drawString:component
                                         inContext:_cgContext 
                                           atPoint:CGPointMake(xPosition, yPosition)
                                         pointSize:componentInfo->pointSize];
                        xPosition += componentInfo->width;
                    } else if(component == singleSpaceMarker) {
                        CGFloat extraSpace = extraWidthNeeded / spacesRemaining;
                        xPosition += componentInfo->width + extraSpace;
                        extraWidthNeeded -= extraSpace;
                        --spacesRemaining;
                    }
                }                
                NSParameterAssert(extraWidthNeeded == 0.0f || componentCount == 1);
            }
            break;
        case CSS_TEXT_ALIGN_CENTER:
            xPosition += (lineFrame.size.width - line.componentWidth) * 0.5f;
            // fall through.
        default:
            {
                xPosition += line.indent;
                for(uint32_t i = 0; i < componentCount; ++i) {
                    id component = components[i];
                    EucHTMLLayoutDocumentRunComponentInfo *componentInfo = &(componentInfos[i]); 
                    if([component isKindOfClass:nsStringClass]) {
                        THStringRenderer *stringRenderer = componentInfo->documentNode.stringRenderer;
                        [stringRenderer drawString:component
                                         inContext:_cgContext 
                                           atPoint:CGPointMake(xPosition, yPosition)
                                         pointSize:componentInfo->pointSize];
                        xPosition += componentInfo->width;
                    } else if(component == singleSpaceMarker) {
                        xPosition += componentInfo->width;
                    }
                }
            }
            break;
    }
}

@end
