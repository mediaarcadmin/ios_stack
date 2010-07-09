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

+ (UIImage *)imageWithString:(NSString *)string font:(UIFont *)font color:(UIColor *)color{
    CGSize size = [string sizeWithFont:font];
    
    if(UIGraphicsBeginImageContextWithOptions) {
        UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    } else {
        UIGraphicsBeginImageContext(size);
    }
    [color set];
    [string drawInRect:CGRectIntegral(CGRectMake(0,0,size.width, size.height)) withFont:font];
    UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return retImage;
}

+ (UIImage *)imageWithIcon:(UIImage *)image string:(NSString *)string font:(UIFont *)font color:(UIColor *)color textInset:(UIEdgeInsets)inset {
    UIImage *textImage = [UIImage imageWithString:string font:font color:color];
    CGRect textRect = CGRectIntegral(CGRectMake(image.size.width + inset.left, 0, textImage.size.width + inset.right, textImage.size.height + (inset.top - inset.bottom)));
    CGRect imageRect = CGRectIntegral(CGRectMake(0, 0, image.size.width, image.size.height));
    CGRect combinedRect = CGRectIntegral(CGRectUnion(imageRect, textRect));
    textRect.origin.y = floor((combinedRect.size.height - textRect.size.height)/2.0f);
    textRect.size.width -= (inset.right);
    textRect.size.height -= (inset.top - inset.bottom);
    imageRect.origin.y = floor((combinedRect.size.height - imageRect.size.height)/2.0f);
    textRect = CGRectIntegral(textRect);
    imageRect = CGRectIntegral(imageRect);
    if(UIGraphicsBeginImageContextWithOptions) {
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
    if(UIGraphicsBeginImageContextWithOptions) {
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
    if(UIGraphicsBeginImageContextWithOptions) {
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
