//
//  BlioUIImageAdditions.h
//  BlioApp
//
//  Created by matt on 04/01/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (BlioAdditions)

+ (UIImage *)imageWithString:(NSString *)string font:(UIFont *)font color:(UIColor *)color;
+ (UIImage *)imageWithIcon:(UIImage *)image string:(NSString *)string font:(UIFont *)font color:(UIColor *)color textInset:(UIEdgeInsets)inset;
+ (UIImage *)imageWithShadow:(UIImage *)image inset:(UIEdgeInsets)inset;
+ (UIImage *)appleLikeBeveledImage:(UIImage *)image;

@end
