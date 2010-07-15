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
    THLogVerbose(@"Positioned Block: %@", NSStringFromCGRect(block.frame));
    
    CGRect borderRect = block.borderRect;
    CGRect paddingRect = block.paddingRect;
    if(!CGRectEqualToRect(borderRect, paddingRect)) {        
        // Non-zero border width.
        CGContextSaveGState(_cgContext);
        
        // Top.
        
        
        CGContextRestoreGState(_cgContext);
    }
    for(id subEntity in block.subEntities) {
        
        //CGContextStrokeRectWithWidth(_cgContext, block.frame, 2);
        
        [self render:subEntity];
    }    
    THLogVerbose(@"Positioned Block End");
}


- (void)_renderPositionedRun:(EucCSSLayoutPositionedRun *)run
{
    THLogVerbose(@"Positioned Run: %@", NSStringFromCGRect(run.frame));
    //CGContextStrokeRectWithWidth(_cgContext, run.frame, 0.5);

    for(EucCSSLayoutLine *line in run.lines) {
        [self render:line];
    }
    THLogVerbose(@"Positioned Run End");
}

- (void)_renderLine:(EucCSSLayoutLine *)line
{
    EucCSSLayoutLineRenderItem* renderItems = line.renderItems;
    size_t renderItemsCount = line.renderItemCount;
    
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
