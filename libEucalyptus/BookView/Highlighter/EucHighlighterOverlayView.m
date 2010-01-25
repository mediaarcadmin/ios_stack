//
//  EucHighlighterOverlayView.m
//  libEucalyptus
//
//  Created by James Montgomerie on 20/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucHighlighterOverlayView.h"


@implementation EucHighlighterOverlayView


- (id)initWithFrame:(CGRect)frame 
{
    if((self = [super initWithFrame:frame])) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect 
{
    // Drawing code
}


- (void)dealloc 
{
    [super dealloc];
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%@", touches);
}

@end
