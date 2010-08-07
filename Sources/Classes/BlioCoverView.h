/*
 *  BlioBookViewControllerCoverDelegate.h
 *  BlioApp
 *
 *  Created by matt on 05/08/2010.
 *  Copyright 2010 BitWink. All rights reserved.
 *
 */
static const CGFloat kBlioLibraryShadowXInset = 0.10276f; // Nasty hack to work out proportion of texture image is shadow
static const CGFloat kBlioLibraryShadowYInset = 0.07737f;

@interface BlioCoverView : UIView {}

- (id)initWithFrame:(CGRect)frame coverImage:(UIImage *)coverImage;

@property (nonatomic, retain) CALayer *textureLayer;
@property (nonatomic, retain) CALayer *coverLayer;

@end

@protocol BlioCoverViewDelegate <NSObject>

@required

- (BlioCoverView *)coverViewViewForOpening;
- (CGRect)coverViewRectForOpening;
- (UIViewController *)coverViewViewControllerForOpening;

@optional

- (void)coverViewDidAnimatePop;
- (void)coverViewDidAnimateShrink;
- (void)coverViewDidAnimateFade;

@end