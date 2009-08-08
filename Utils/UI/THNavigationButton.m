//
//  THNavigationButton.m
//  Eucalyptus
//
//  Created by James Montgomerie on 08/05/2008.
//  Copyright 2008 James Montgomerie. All rights reserved.
//

#import "THNavigationButton.h"

@implementation THNavigationButton

- (void)dealloc
{
    [_firstLine release];
    [_secondLine release];
    [super dealloc];
}

- (UIImage *)_templateImageForBarStyle:(UIBarStyle)barStyle
{
    NSString *imageNameToUse;
    
    switch(barStyle) {
        case UIBarStyleBlackOpaque:
            imageNameToUse = @"rightButtonBlackOpaque.png";
            break;
        case UIBarStyleBlackTranslucent:
            imageNameToUse = @"rightButtonBlackTranslucent.png";
            break;
        case UIBarStyleDefault:
        default:
            imageNameToUse = @"rightButtonBlue.png";
    }
    return [UIImage imageNamed:imageNameToUse];
}


- (UIImage *)_imageForRightNavigationButtonWithFirstLine:(NSString *)firstLine secondLine:(NSString *)secondLine barStyle:(UIBarStyle)barStyle
{
    // Image from the iPhoneButtons sample code (for web developers).
    UIImage *buttonImage = [self _templateImageForBarStyle:barStyle];
    UIImage *stretchableImage = [buttonImage stretchableImageWithLeftCapWidth:4 topCapHeight:12];
    
    // Work out which string is longer - base the button size on this.
    UIFont *font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]-1];
    CGSize nowSize = [firstLine sizeWithFont:font]; 
    CGSize playingSize = [secondLine sizeWithFont:font];
    CGFloat textWidth = MAX(nowSize.width, playingSize.width);
    
    // These statistics worked out from examining a screenshot of the iPod app
    // (found at <http://www.flickr.com/photos/maduarte/1837341115/sizes/o/>).
    CGRect frame = CGRectMake(0, 0, textWidth + 22, 30);

    // Create a bitmap to render the button image into.
    NSMutableData *bitmapData = [[NSMutableData alloc] initWithLength:4 * frame.size.width * frame.size.height];    
    CGColorSpaceRef deviceColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef myContext = CGBitmapContextCreate([bitmapData mutableBytes],
                                                   frame.size.width,
                                                   frame.size.height,
                                                   8,
                                                   4 * frame.size.width,
                                                   deviceColorSpace,
                                                   kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
    
    // We need to flip the bitmap, because we're goung to draw with UIKit routines
    // and they have the opposite coordinate system.
    CGContextTranslateCTM(myContext, 0, frame.size.height);
    CGContextScaleCTM(myContext, 1, -1);

    CGContextClearRect(myContext, frame);

    UIGraphicsPushContext(myContext);

    [stretchableImage drawInRect:frame];
    
    // Draw the text, both lines seperately.
    // Again, hard-coded offsets worked out by examining screenshots.
    
    CGRect textRect = frame;
    textRect.size.width -= 7;
    
    [[[UIColor blackColor] colorWithAlphaComponent:0.5f] set];
    
    textRect.origin.y = 1;
    [firstLine drawInRect:textRect withFont:font lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
    
    textRect.origin.y = 12;
    [secondLine drawInRect:textRect withFont:font lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
    
    
    [[UIColor whiteColor] set];

    textRect.origin.y = 2;
    [firstLine drawInRect:textRect withFont:font lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
    
    textRect.origin.y = 13;
    [secondLine drawInRect:textRect withFont:font lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
    
    // Done drawing!
    UIGraphicsPopContext();
    CGContextRelease(myContext);

    // Create a CGImage around our bitmap data, and create a UIImage from that.
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((CFDataRef)bitmapData);
    CGImageRef newImageRef = CGImageCreate(frame.size.width, frame.size.height, 8, 32, 4 * frame.size.width, 
                                           deviceColorSpace, 
                                           kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast, 
                                           dataProvider, NULL, YES, kCGRenderingIntentDefault);
    UIImage *renderedImage = [UIImage imageWithCGImage:newImageRef];
    CGImageRelease(newImageRef);
    CGColorSpaceRelease(deviceColorSpace);
    CGDataProviderRelease(dataProvider);
    [bitmapData release];

    return renderedImage;
}


- (UIImage *)_imageForLeftNavigationButtonInBarStyle:(UIBarStyle)barStyle
{
    UIImage *buttonImage = [self _templateImageForBarStyle:barStyle];
    UIImage *stretchableImage = [buttonImage stretchableImageWithLeftCapWidth:4 topCapHeight:15];
    CGRect frame = CGRectMake(0, 0, 41, 30);
    
    // Create a bitmap to render the button image into.
    NSMutableData *bitmapData = [[NSMutableData alloc] initWithLength:4 * frame.size.width * frame.size.height];    
    CGColorSpaceRef deviceColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef myContext = CGBitmapContextCreate([bitmapData mutableBytes],
                                                   frame.size.width,
                                                   frame.size.height,
                                                   8,
                                                   4 * frame.size.width,
                                                   deviceColorSpace,
                                                   kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
    
    // We need to flip the bitmap, because we're goung to draw with UIKit routines
    // and they have the opposite coordinate system.
    CGContextTranslateCTM(myContext, 0, frame.size.height);
    CGContextScaleCTM(myContext, 1, -1);
    
    CGContextClearRect(myContext, frame);
    
    UIGraphicsPushContext(myContext);
    
    // Mirror the drawing - we want a left-facing arrow.
    CGContextScaleCTM(myContext, -1, 1);
    CGContextTranslateCTM(myContext, -frame.size.width, 0);
    [stretchableImage drawInRect:frame];
    CGContextScaleCTM(myContext, -1, 1);
    CGContextTranslateCTM(myContext, -frame.size.width, 0);
    
    // Draw the arrow.  Points worked out by examining screenshots.
    // (it's a pity the iPhone has not fonts with the Unicode arrows in them).    
    CGMutablePathRef arrowPath = CGPathCreateMutable();
    CGPathMoveToPoint(arrowPath, NULL,    -0.5,   0);
    CGPathAddLineToPoint(arrowPath, NULL, 10, -9);
    CGPathAddLineToPoint(arrowPath, NULL, 10, -4);
    CGPathAddLineToPoint(arrowPath, NULL, 21, -4);
    CGPathAddLineToPoint(arrowPath, NULL, 21,  4);
    CGPathAddLineToPoint(arrowPath, NULL, 10,  4);
    CGPathAddLineToPoint(arrowPath, NULL, 10,  9);
    CGPathAddLineToPoint(arrowPath, NULL, -0.5,0);
    CGPathCloseSubpath(arrowPath);
    
    [[[UIColor blackColor] colorWithAlphaComponent:0.5f] set];
    CGContextTranslateCTM(myContext, 11, 14);
    CGContextAddPath(myContext, arrowPath);
    CGContextFillPath(myContext);
    
    [[UIColor whiteColor] set];
    CGContextTranslateCTM(myContext, 0, 1);
    CGContextAddPath(myContext, arrowPath);
    CGContextFillPath(myContext);
    
    CFRelease(arrowPath);
    
    // Done drawing!
    UIGraphicsPopContext();
    CGContextRelease(myContext);
    
    // Create a CGImage around our bitmap data, and create a UIImage from that.
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((CFDataRef)bitmapData);
    CGImageRef newImageRef = CGImageCreate(frame.size.width, frame.size.height, 8, 32, 4 * frame.size.width, 
                                           deviceColorSpace, 
                                           kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast, 
                                           dataProvider, NULL, YES, kCGRenderingIntentDefault);
    UIImage *renderedImage = [UIImage imageWithCGImage:newImageRef];
    CGImageRelease(newImageRef);
    CGColorSpaceRelease(deviceColorSpace);
    CGDataProviderRelease(dataProvider);
    [bitmapData release];
    
    return renderedImage;
}    


- (UIBarStyle)barStyle
{
    return _barStyle;
}


- (void)setBarStyle:(UIBarStyle)barStyle
{
    UIImage *image;
    if(_firstLine || _secondLine) {
        image = [self _imageForRightNavigationButtonWithFirstLine:_firstLine secondLine:_secondLine barStyle:barStyle];    
    } else {
        image = [self _imageForLeftNavigationButtonInBarStyle:barStyle];
    }
    [self setImage:image
          forState:UIControlStateNormal];
    _barStyle = barStyle;
}


- (id)_initRightNavigationButtonWithFirstLine:(NSString *)firstLine secondLine:(NSString *)secondLine barStyle:(UIBarStyle)barStyle
{
    if((self = [super init])) {
        _firstLine = [firstLine copy];
        _secondLine = [secondLine copy];

        self.barStyle = barStyle;
        
        self.adjustsImageWhenHighlighted = YES;
        self.showsTouchWhenHighlighted = NO;
        
        CGSize imageSize = [self imageForState:UIControlStateNormal].size;
        self.frame = CGRectMake(0, 0, imageSize.width, imageSize.height);
    }
    return self;
}


- (id)_initLeftNavigationButtonWithArrowInBarStyle:(UIBarStyle)barStyle 
{
    if((self = [super init])) {
        self.barStyle = barStyle;
        
        self.adjustsImageWhenHighlighted = YES;
        self.showsTouchWhenHighlighted = NO;
        
        CGSize imageSize = [self imageForState:UIControlStateNormal].size;
        self.frame = CGRectMake(0, 0, imageSize.width, imageSize.height);
    }
    return self;
}    


+ (id)rightNavigationButtonWithFirstLine:(NSString *)firstLine secondLine:(NSString *)secondLine
{
    return [self rightNavigationButtonWithFirstLine:firstLine secondLine:secondLine barStyle:UIBarStyleDefault];
}


+ (id)rightNavigationButtonWithFirstLine:(NSString *)firstLine secondLine:(NSString *)secondLine barStyle:(UIBarStyle)barStyle
{
    return [[[self alloc] _initRightNavigationButtonWithFirstLine:firstLine secondLine:secondLine barStyle:barStyle] autorelease];
}


+ (id)leftNavigationButtonWithArrow
{
    return [self leftNavigationButtonWithArrowInBarStyle:UIBarStyleDefault];
}


+ (id)leftNavigationButtonWithArrowInBarStyle:(UIBarStyle)barStyle 
{    
    return [[[self alloc] _initLeftNavigationButtonWithArrowInBarStyle:barStyle] autorelease];
}

@end
