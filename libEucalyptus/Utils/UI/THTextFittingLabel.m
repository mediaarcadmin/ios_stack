//
//  THTextFittingLabel.m
//  libEucalyptus
//
//  Created by James Montgomerie on 21/08/2009.
//  Copyright 2009 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "THTextFittingLabel.h"
#import "THStringRenderer.h"

@implementation THTextFittingLabel


- (void)drawTextInRect:(CGRect)rect
{
    CGFloat lineSpacingScaling = 1.2f;
    THStringRenderer *renderer = [[THStringRenderer alloc] initWithFontName:self.font.fontName lineSpacingScaling:lineSpacingScaling];
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    
    NSString *text = self.text;
    
    rect = CGRectInset(rect, 3, 3);
    
    CGSize stringSize = CGSizeZero;
    CGFloat pointSize = self.font.pointSize;
    BOOL tryAgain = YES;
    while(tryAgain) {
        stringSize = [renderer sizeForString:text
                                   inContext:context
                                   pointSize:pointSize 
                                    maxWidth:rect.size.width 
                                       flags:THStringRendererFlagFairlySpaceLastLine | THStringRendererFlagCenter];
        if(pointSize > 1 && stringSize.height > rect.size.height) {
            --pointSize;
        } else {
            tryAgain = NO;
        }
    }
        
    CGFloat lineSpacingWithScaling = [renderer lineSpacingForPointSize:pointSize];
    CGFloat lineSpacingWithoutScaling = lineSpacingWithScaling * lineSpacingScaling;
    
    // The docs imply that we'll be called twice, with the correct color set
    // before each call - once for the shadow, secondly for the text.
    // None of this seems to be true, so we do it all ourselves.
    
    CGPoint textPoint = CGPointMake(rect.origin.x, ceilf((rect.size.height - stringSize.height) / 2.0f) + rect.origin.y - roundf((lineSpacingWithScaling - lineSpacingWithoutScaling) / 2.0f) + 1.0f);
    CGSize shadowOffset = self.shadowOffset;
    if(!CGSizeEqualToSize(shadowOffset, CGSizeZero)) {
        [self.shadowColor setFill]; 
        
        [renderer drawString:text
                   inContext:context 
                     atPoint:CGPointMake(textPoint.x + shadowOffset.width, textPoint.y + shadowOffset.height) 
                   pointSize:pointSize
                    maxWidth:rect.size.width
                       flags:THStringRendererFlagFairlySpaceLastLine | THStringRendererFlagCenter];        
    }
    
    
    [self.textColor setFill];  
    
    [renderer drawString:text
               inContext:context 
                 atPoint:textPoint
               pointSize:pointSize
                maxWidth:rect.size.width
                   flags:THStringRendererFlagFairlySpaceLastLine | THStringRendererFlagCenter];
        
    CGContextRestoreGState(context);
    
    [renderer release];
}


@end
