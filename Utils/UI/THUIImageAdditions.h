//
//  THUIImageAdditions.h
//  libEucalyptus
//
//  Created by James Montgomerie on 05/05/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIImage (THAdditions)

//- (id)imageByMappingIntensityToAlpha;
+ (UIImage *)imageWithString:(NSString *)string font:(UIFont *)font size:(CGSize)size;

- (UIImage *)midpointStretchableImage;
+ (UIImage *)midpointStretchableImageNamed:(NSString *)name;
+ (UIImage *)stretchableImageNamed:(NSString *)name leftCapWidth:(CGFloat)leftCapWidth topCapHeight:(CGFloat)topCapHeight;
+ (UIImage *)imageWithView:(UIView *)view;

@end
