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
    
    printf("Rendering %p: %s:\t", line, [NSStringFromRect(NSRectFromCGRect(line.frame)) UTF8String]);

    CGFloat xPosition = line.frame.origin.x + line.indent;
    CGFloat yPosition = line.frame.origin.y;
    for(uint32_t i = 0; i < componentCount; ++i) {
        id component = components[i];
        EucHTMLLayoutDocumentRunComponentInfo *componentInfo = &(componentInfos[i]); 
        if([component isKindOfClass:nsStringClass]) {
            THStringRenderer *stringRenderer = componentInfo->documentNode.stringRenderer;
            [stringRenderer drawString:component
                             inContext:_cgContext 
                               atPoint:CGPointMake(xPosition, yPosition)
                             pointSize:componentInfo->pointSize];
            printf("%s", [component UTF8String]);
            xPosition += componentInfo->width;
        } else if(component == singleSpaceMarker) {
            putchar(' ');
            xPosition += componentInfo->width;
        }
    }
    
    printf(" :  %fpx", xPosition);
    
    if(xPosition > 480) {
        NSLog(@"Warning!");
    }
    
    printf("\n");
}

@end
