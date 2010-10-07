//
//  EucPageTurningPageContentsInformation.m
//  libEucalyptus
//
//  Created by James Montgomerie on 07/10/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucPageTurningPageContentsInformation.h"
#import "EucPageTurningView.h"

@implementation EucPageTurningPageContentsInformation

@synthesize view = _view;
@synthesize pageIndex = _pageIndex;
@synthesize zoomedTextureRect = _zoomedTextureRect;

@synthesize currentTextureGenerationOperation = _currentTextureGenerationOperation;
@synthesize currentZoomedTextureGenerationOperation = _currentZoomedTextureGenerationOperation;

- (id)initWithPageTurningView:(EucPageTurningView *)pageTurningView
{
    if((self = [super init])) {
        _pageTurningView = pageTurningView;
    }
    return self;
}

- (void)dealloc
{   
    NSParameterAssert(!_currentTextureGenerationOperation);
    NSParameterAssert(!_currentZoomedTextureGenerationOperation);
    
    [_view release];

    if(_texture) {
        [_pageTurningView _recycleTexture:_texture];
    }
    if(_zoomedTexture) {
        [_pageTurningView _recycleTexture:_zoomedTexture];
    }
        
    [super dealloc];
}

- (GLuint)texture
{
    return _texture;
}

- (void)setTexture:(GLuint)texture
{
    if(texture != _texture) {
        if(_texture) {
            [_pageTurningView _recycleTexture:_texture];
        }
        _texture = texture;
    }
}

- (GLuint)zoomedTexture
{
    return _zoomedTexture;
}

- (void)setZoomedTexture:(GLuint)zoomedTexture
{
    if(zoomedTexture != _zoomedTexture) {
        if(_zoomedTexture) {
            [_pageTurningView _recycleTexture:_zoomedTexture];
        }
        _zoomedTexture = zoomedTexture;
    }
}

- (void)setCurrentTextureGenerationOperation:(EucPageTurningTextureGenerationOperation *)textureGenerationOperation
{
    if(textureGenerationOperation != _currentTextureGenerationOperation) {
        if(_currentTextureGenerationOperation) {
            [_currentTextureGenerationOperation cancel];
            [_currentTextureGenerationOperation release];
        }
        _currentTextureGenerationOperation = [textureGenerationOperation retain];
    }
}

- (void)setCurrentZoomedTextureGenerationOperation:(EucPageTurningTextureGenerationOperation *)zoomedTextureGenerationOperation
{
    if(zoomedTextureGenerationOperation != _currentZoomedTextureGenerationOperation) {
        if(_currentZoomedTextureGenerationOperation) {
            [_currentZoomedTextureGenerationOperation cancel];
            [_currentTextureGenerationOperation release];
        }
        _currentZoomedTextureGenerationOperation = [zoomedTextureGenerationOperation retain];
    }
}


@end
