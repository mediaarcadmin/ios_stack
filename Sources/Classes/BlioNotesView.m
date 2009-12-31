//
//  BlioNotesView.m
//  BlioApp
//
//  Created by matt on 31/12/2009.
//  Copyright 2009 BitWink. All rights reserved.
//

#import "BlioNotesView.h"



@implementation BlioNotesView


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(ctx, 0.996f, 0.976f, 0.718f, 1.0f);
    CGContextFillRect(ctx, rect);
}


- (void)dealloc {
    [super dealloc];
}


@end
