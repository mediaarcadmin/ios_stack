//
//  BlioCoverView.m
//  BlioApp
//
//  Created by matt on 06/08/2010.
//  Copyright 2010 BitWink. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "BlioCoverView.h"

@interface BlioCoverViewLayer : CALayer {
    CALayer *coverLayer;
    CALayer *textureLayer;
}

@property (nonatomic, retain) CALayer *coverLayer;
@property (nonatomic, retain) CALayer *textureLayer;

@end

@implementation BlioCoverView

@synthesize textureLayer, coverLayer;

- (void)dealloc {
    self.coverLayer = nil;
    self.textureLayer = nil;
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame coverImage:(UIImage *)coverImage {
    
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        
        CALayer *aCoverLayer = [CALayer layer];
        aCoverLayer.contentsGravity = kCAGravityResize;
        aCoverLayer.contents = (id)coverImage.CGImage;
        
        [self.layer addSublayer:aCoverLayer];
        self.coverLayer = aCoverLayer;
        
        CALayer *aTextureLayer = [CALayer layer];
        aTextureLayer.contentsGravity = kCAGravityResize;
        aTextureLayer.contents = (id)[UIImage imageNamed:@"booktextureandshadowsubtle.png"].CGImage;
        
        [self.layer addSublayer:aTextureLayer];
        self.textureLayer = aTextureLayer;
    }
    return self;
}

- (void)layoutSubviews {
    CGFloat width = CGRectGetWidth(self.bounds) / (1 - kBlioLibraryShadowXInset * 2);
    CGFloat height = CGRectGetHeight(self.bounds) / (1 -  kBlioLibraryShadowYInset * 2);
    CGFloat xInset = (CGRectGetWidth(self.bounds) - width) / 2.0f;
    CGFloat yInset = (CGRectGetHeight(self.bounds) - height) / 2.0f;
    CGRect textureFrame = CGRectInset(self.bounds, xInset, yInset);
    
    [self.textureLayer setFrame:textureFrame];
    [self.coverLayer setFrame:self.bounds];
}

@end
