//
//  BlioUIImageAdditions.h
//  BlioApp
//
//  Created by matt on 04/01/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (BlioAdditions)


+ (UIImage *)blioImageWithString:(NSString *)string font:(UIFont *)font size:(CGSize)size baseline:(CGFloat)baseline color:(UIColor *)color                   rightArrowRect:(CGRect)rightArrowRect;
+ (UIImage *)blioImageWithString:(NSString *)string font:(UIFont *)font size:(CGSize)size baseline:(CGFloat)baseline color:(UIColor *)color;    
+ (UIImage *)blioImageWithString:(NSString *)string font:(UIFont *)font size:(CGSize)size color:(UIColor *)color;
+ (UIImage *)blioImageWithString:(NSString *)string font:(UIFont *)font color:(UIColor *)color;

- (UIImage *)blioImageByRotatingTo:(UIImageOrientation)orientation;

+ (UIImage *)imageWithIcon:(UIImage *)image string:(NSString *)string font:(UIFont *)font color:(UIColor *)color textInset:(UIEdgeInsets)inset;
+ (UIImage *)imageWithShadow:(UIImage *)image inset:(UIEdgeInsets)inset;
+ (UIImage *)imageWithShadow:(UIImage *)image inset:(UIEdgeInsets)inset color:(UIColor *)color;

+ (UIImage *)appleLikeBeveledImage:(UIImage *)image;

@end
