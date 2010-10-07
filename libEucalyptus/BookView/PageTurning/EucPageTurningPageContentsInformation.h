//
//  EucPageTurningPageContentsInformation.h
//  libEucalyptus
//
//  Created by James Montgomerie on 07/10/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "THOpenGLUtils.h"

@class EucPageTurningView;

@interface EucPageTurningPageContentsInformation : NSObject {
    EucPageTurningView *_pageTurningView;
    
    NSUInteger _pageIndex;
    UIView *_view;
    GLuint _texture;
    GLuint _zoomedTexture;
    CGRect _zoomedTextureRect;    
}

@property (nonatomic, retain) UIView *view;
@property (nonatomic, assign) NSUInteger pageIndex;

@property (nonatomic, assign) GLuint texture;
@property (nonatomic, assign) GLuint zoomedTexture;

@property (nonatomic, assign) CGRect zoomedTextureRect;


- (id)initWithPageTurningView:(EucPageTurningView *)pageTurningView;

@end

