//
//  THRoundRectView.m
//  Eucalyptus
//
//  Created by James Montgomerie on 09/03/2009.
//  Copyright 2009 James Montgomerie. All rights reserved.
//

#import "THRoundRectView.h"
#import "THRoundRects.h"

@implementation THRoundRectView

@synthesize cornerRadius = _radius;

- (id)initWithFrame:(CGRect)frame 
{
    if((self = [super initWithFrame:frame])) {
        self.clearsContextBeforeDrawing = YES;
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}

- (void)drawRect:(CGRect)rect 
{
    CGRect bounds = self.bounds;
    
    [[UIColor clearColor] set];
    UIRectFill(bounds);
    
    [self.backgroundColor set];
    CGContextRef context = UIGraphicsGetCurrentContext();
    THAddRoundedRectToPath(context, bounds, _radius, _radius);
    CGContextFillPath(context);
}

@end
