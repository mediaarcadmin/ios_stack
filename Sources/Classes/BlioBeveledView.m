//
//  THBeveledView.m
//  Eucalyptus
//
//  Created by James Montgomerie on 11/09/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "BlioBeveledView.h"

@implementation BlioBeveledView

- (id)initWithFrame:(CGRect)frame 
{
    if((self = [super initWithFrame:frame])) {
        self.opaque = NO;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:1.0f - 137.0f / 255.0f];
    }
    return self;
}

- (void)drawRect:(CGRect)rect 
{
	[super drawRect:rect];
    
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextSaveGState(currentContext);
    
    CGContextSetLineWidth(currentContext, 1);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextSetStrokeColorSpace(currentContext, colorSpace);
    CGContextSetBlendMode(currentContext, kCGBlendModeCopy);
    {
        CGFloat components[] = { 0.0f, 0.0f, 0.0f, 1.0f - 71.0f / 255.0f * (137.0f / 102.0f) };
        CGContextSetStrokeColor(currentContext, components);
        
        CGRect bounds = self.bounds;
        CGFloat width = bounds.size.width;
        CGFloat y = bounds.size.height - 0.5;
        CGContextMoveToPoint(currentContext, 0, y);
        CGContextAddLineToPoint(currentContext, width, y);
        CGContextStrokePath(currentContext);
    }
    
    {
        CGFloat components[] = { 0.0f, 0.0f, 0.0f, 1.0f - 125.0f / 255.0f * (137.0f / 102.0f)};
        CGContextSetStrokeColor(currentContext, components);
        
        CGRect bounds = self.bounds;
        CGFloat width = bounds.size.width;
        CGFloat y = bounds.size.height - 1.5;
        CGContextMoveToPoint(currentContext, 0, y);
        CGContextAddLineToPoint(currentContext, width, y);
        CGContextStrokePath(currentContext);
    }
    
    CGColorSpaceRelease(colorSpace);
    CGContextRestoreGState(currentContext);
}

@end
