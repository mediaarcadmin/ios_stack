//
//  BlioUIImageAdditions.m
//  BlioApp
//
//  Created by matt on 04/01/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import "BlioUIImageAdditions.h"

#define TEXTPADDING 2

@implementation UIImage (BlioAdditions)

+ (UIImage *)blioImageWithString:(NSString *)string font:(UIFont *)font size:(CGSize)size baseline:(CGFloat)baseline color:(UIColor *)color{    
    CGSize stringSize = [string sizeWithFont:font];

    if(UIGraphicsBeginImageContextWithOptions != nil) {
        UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    } else {
        UIGraphicsBeginImageContext(size);
    }
    [color set];
    [string drawAtPoint:CGPointMake((size.width - stringSize.width) * 0.5, baseline - font.ascender) withFont:font];
    UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return retImage;
}

+ (UIImage *)blioImageWithString:(NSString *)string font:(UIFont *)font size:(CGSize)size color:(UIColor *)color{    
    return [self blioImageWithString:string font:font size:size baseline:font.ascender color:color];
}

+ (UIImage *)blioImageWithString:(NSString *)string font:(UIFont *)font color:(UIColor *)color{
    CGSize size = [string sizeWithFont:font];
    return [self blioImageWithString:string font:font size:size color:color];
}

+ (UIImage *)imageWithIcon:(UIImage *)image string:(NSString *)string font:(UIFont *)font color:(UIColor *)color textInset:(UIEdgeInsets)inset {
    UIImage *textImage = [UIImage blioImageWithString:string font:font color:color];
    CGRect textRect = CGRectIntegral(CGRectMake(image.size.width + inset.left, 0, textImage.size.width + inset.right, textImage.size.height + (inset.top - inset.bottom)));
    CGRect imageRect = CGRectIntegral(CGRectMake(0, 0, image.size.width, image.size.height));
    CGRect combinedRect = CGRectIntegral(CGRectUnion(imageRect, textRect));
    textRect.origin.y = floor((combinedRect.size.height - textRect.size.height)/2.0f);
    textRect.size.width -= (inset.right);
    textRect.size.height -= (inset.top - inset.bottom);
    imageRect.origin.y = floor((combinedRect.size.height - imageRect.size.height)/2.0f);
    textRect = CGRectIntegral(textRect);
    imageRect = CGRectIntegral(imageRect);
    if(UIGraphicsBeginImageContextWithOptions != nil) {
        UIGraphicsBeginImageContextWithOptions(combinedRect.size, NO, 0);
    } else {
        UIGraphicsBeginImageContext(combinedRect.size);
    }
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, 0.5f), 0.0f, [UIColor colorWithWhite:0.0f alpha:0.5f].CGColor);
    CGContextBeginTransparencyLayer(ctx, NULL);
    [image drawAtPoint:imageRect.origin];
    [textImage drawAtPoint:textRect.origin];
    CGContextEndTransparencyLayer(ctx);
    UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return retImage;
}

+ (UIImage *)imageWithShadow:(UIImage *)image inset:(UIEdgeInsets)inset {
    return [UIImage imageWithShadow:image inset:inset color:[UIColor colorWithWhite:0.0f alpha:0.5f]];
}

+ (UIImage *)imageWithShadow:(UIImage *)image inset:(UIEdgeInsets)inset color:(UIColor *)color {
    CGRect imageRect = CGRectIntegral(CGRectMake(inset.left, inset.top, image.size.width + inset.right, image.size.height + (inset.top + inset.bottom)));
    if(UIGraphicsBeginImageContextWithOptions != nil) {
        UIGraphicsBeginImageContextWithOptions(imageRect.size, NO, 0);
    } else {
        UIGraphicsBeginImageContext(imageRect.size);
    }
    imageRect.size.width -= (inset.right);
    imageRect.size.height -= (inset.top + inset.bottom);
    imageRect = CGRectIntegral(imageRect);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, 0.5f), 0.0f, color.CGColor);
    CGContextBeginTransparencyLayer(ctx, NULL);
    [image drawAtPoint:imageRect.origin];
    CGContextEndTransparencyLayer(ctx);
    UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return retImage;
}

+ (UIImage *)appleLikeBeveledImage:(UIImage *)image
{
    CGSize originalSize = image.size;
    CGSize newSize = originalSize;
    newSize.height++;
    if(UIGraphicsBeginImageContextWithOptions != nil) {
        UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    } else {
        UIGraphicsBeginImageContext(newSize);
    }
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    [[UIColor blackColor] set];
    CGContextFillRect(context, CGRectMake(0, 0, originalSize.width, originalSize.height));
    CGContextRestoreGState(context);    
    
    [image drawAtPoint:CGPointMake(0, 0) blendMode:kCGBlendModeDestinationIn alpha:0.5f];

    [image drawAtPoint:CGPointMake(0, 1)];
        
    UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return retImage;
}


@end
