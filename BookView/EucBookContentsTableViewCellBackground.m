//
//  BookContentsTableViewCellBackground.m
//  libEucalyptus
//
//  Created by James Montgomerie on 23/01/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

//  Portions from:
//  http://stackoverflow.com/questions/400965/how-to-customize-the-background-border-colors-of-a-grouped-table-view
//  Created by Mike Akers on 11/21/08.

#import "EucBookContentsTableViewCellBackground.h"
#import "THRoundRects.h"

@implementation EucBookContentsTableViewCellBackground

@synthesize borderColor, fillColor, position;

- (void)setPosition:(EucBookContentsTableViewCellPosition)newPosition
{
    if(newPosition != position) {
        position = newPosition;
        [self setNeedsDisplay];
    }
}

- (void)setFillColor:(UIColor *)newColor
{
    if(newColor != fillColor) {
        [fillColor release];
        fillColor = [newColor retain];
        [self setNeedsDisplay];
    }
}

- (void)setBorderColor:(UIColor *)newColor
{
    if(borderColor != borderColor) {
        [borderColor release];
        borderColor = [newColor retain];
        [self setNeedsDisplay];
    }
}

- (id)initWithFrame:(CGRect)frame
{
    if((self = [super initWithFrame:frame])) {
        borderColor = [[[UIColor grayColor] colorWithAlphaComponent:0.65f] retain];
        fillColor = [[UIColor whiteColor] retain];
        self.opaque = YES;
        self.clearsContextBeforeDrawing = YES;
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}

- (void)dealloc
{
    [borderColor release];
    [fillColor release];
    [super dealloc];
}

- (void)drawRect:(CGRect)rect
{
    CGRect bounds = self.bounds;
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGColorRef cgFillColor = [fillColor CGColor];
    
    CGContextSetStrokeColorWithColor(c, [borderColor CGColor]);
    
    
    
    // Set line width to 1, and inset by 0.5 piels to get our lines in the
    // center of pixels.
    CGContextSetLineWidth(c, 1);  
    CGRect strokeRect = CGRectInset(bounds, 0.5, 0.5);

    if(position != EucBookContentsTableViewCellPositionSingle &&
       position != EucBookContentsTableViewCellPositionBottom) {
        // Only single or bottom cells actually draw their own bottom
        // borders (others use the top border of the next cell), so we'll expand
        // the height of the box we're drawing by one and it'lll be clipped out.
        strokeRect.size.height += 1;
    }        
    
    if(position != EucBookContentsTableViewCellPositionSingle) {
        // Some of the corners are square, so 
        // draw a square box around the entire cell.
        CGContextSetFillColorWithColor(c, cgFillColor);
        
        CGContextFillRect(c, bounds);
        CGContextStrokeRect(c, strokeRect);
        
        // Next, we'll draw the rounded corners, so clip out the part of the 
        // cell that should have square corners.
        if (position == EucBookContentsTableViewCellPositionTop) {
            CGContextClipToRect(c, CGRectMake(0.0f, 0.0f, bounds.size.width, 11.0f));
        } else if (position == EucBookContentsTableViewCellPositionBottom) {
            CGContextClipToRect(c, CGRectMake(0.0f, bounds.size.height - 11.0f, bounds.size.width, bounds.size.height));
        }
    }
    
    if(position != EucBookContentsTableViewCellPositionMiddle) {
        // Draw the round corners.
        // The ones that shouldn't be here are already clipped off, above.
        
        // First, the 'background' that is 'showing through' below the corners.
        CGContextSetFillColorWithColor(c, [[UIColor groupTableViewBackgroundColor] CGColor]);
        CGContextFillRect(c, bounds);
        
        // Now, the wounded rect (white filled).
        CGContextSetFillColorWithColor(c, cgFillColor);    
        
        CGContextBeginPath(c);
        THAddRoundedRectToPath(c, strokeRect, 10.0f, 10.0f);
        CGContextFillPath(c);  
        
        CGContextBeginPath(c);
        THAddRoundedRectToPath(c, strokeRect, 10.0f, 10.0f);  
        CGContextStrokePath(c);   
    }
}

@end
