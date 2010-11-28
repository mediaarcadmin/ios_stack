//
//  EucPageTurningPageContentsInformation.m
//  libEucalyptus
//
//  Created by James Montgomerie on 07/10/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucPageTurningPageContentsInformation.h"
#import "EucPageTurningView.h"
#import "THLog.h"

@implementation EucPageTurningPageContentsInformation

@synthesize view = _view;
@synthesize pageIndex = _pageIndex;
@synthesize zoomedTextureRect = _zoomedTextureRect;

@synthesize currentTextureGenerationOperation = _currentTextureGenerationOperation;
@synthesize currentZoomedTextureGenerationOperation = _currentZoomedTextureGenerationOperation;

- (id)initWithTexturePool:(THOpenGLTexturePool *)texturePool
{
    if((self = [super init])) {
        _texturePool = [texturePool retain];
    }
    return self;
}

- (void)dealloc
{   
    if(_currentTextureGenerationOperation) {
        THLog(@"EucPageTurningPageContentsInformation deallocing with pending texture generation operation (this is not an error).");
        _currentTextureGenerationOperation.delegate = nil;
        [_currentTextureGenerationOperation release];
        _currentTextureGenerationOperation = nil;
    }
    if(_currentZoomedTextureGenerationOperation) {
        THLog(@"EucPageTurningPageContentsInformation deallocing with pending zoomed texture generation operation (this is not an error).");
        _currentZoomedTextureGenerationOperation.delegate = nil;
        [_currentZoomedTextureGenerationOperation release];
        _currentZoomedTextureGenerationOperation = nil;
    }

    [_view release];
        
    if(_texture) {
        [_texturePool recycleTexture:_texture];
    }
    if(_zoomedTexture) {
        [_texturePool recycleTexture:_zoomedTexture];
    }
	if(_highlightTexture) {
        [_texturePool recycleTexture:_highlightTexture];
    }
    
    [_texturePool release];
        
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
            [_texturePool recycleTexture:_texture];
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
            [_texturePool recycleTexture:_zoomedTexture];
        }
        _zoomedTexture = zoomedTexture;
    }
}

- (GLuint)highlightTexture
{
    return _highlightTexture;
}

- (void)setHighlightTexture:(GLuint)texture
{
    if(texture != _highlightTexture) {
        if(_highlightTexture) {
            [_texturePool recycleTexture:_highlightTexture];
        }
        _highlightTexture = texture;
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
            [_currentZoomedTextureGenerationOperation release];
        }
        _currentZoomedTextureGenerationOperation = [zoomedTextureGenerationOperation retain];
    }
}

@end
