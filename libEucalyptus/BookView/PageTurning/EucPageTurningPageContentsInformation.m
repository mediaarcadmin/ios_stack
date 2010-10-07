//
//  EucPageTurningPageContentsInformation.m
//  libEucalyptus
//
//  Created by James Montgomerie on 07/10/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucPageTurningPageContentsInformation.h"

@implementation EucPageTurningPageContentsInformation

@synthesize view = _view;
@synthesize pageIndex = _pageIndex;
@synthesize zoomedTextureRect = _zoomedTextureRect;

- (id)initWithMainMainThreadContext:(EAGLContext *)mainThreadContext 
                 otherThreadContext:(EAGLContext *)otherThreadContext
             otherThreadContextLock:(NSLock *)otherThreadContextLock
{
    if((self = [super init])) {
        mainThreadContext = [_mainThreadContext retain];
        otherThreadContext = [_otherThreadContext retain];
        otherThreadContextLock = [_otherThreadContextLock retain];
    }
    return self;
}

- (void)dealloc
{   
    [_view release];
    
    BOOL mainThread = [NSThread isMainThread];
    if(mainThread) {
        [EAGLContext setCurrentContext:_mainThreadContext];
    } else {
        [_otherThreadContextLock lock];
        [EAGLContext setCurrentContext:_otherThreadContext];
    }
    
    if(_texture) {
        glDeleteTextures(1, &_texture);
    }
    if(_zoomedTexture) {
        glDeleteTextures(1, &_zoomedTexture);
    }
    
    if(mainThread) {
        [_otherThreadContextLock unlock];
    }
    [_otherThreadContextLock release];
    
    [_mainThreadContext release];
    [_otherThreadContext release];
    
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
            BOOL mainThread = [NSThread isMainThread];
            if(mainThread) {
                [EAGLContext setCurrentContext:_mainThreadContext];
            } else {
                [_otherThreadContextLock lock];
                [EAGLContext setCurrentContext:_otherThreadContext];
            }
            
            glDeleteTextures(1, &_texture);
            
            if(mainThread) {
                [_otherThreadContextLock unlock];
            }            
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
            BOOL mainThread = [NSThread isMainThread];
            if(mainThread) {
                [EAGLContext setCurrentContext:_mainThreadContext];
            } else {
                [_otherThreadContextLock lock];
                [EAGLContext setCurrentContext:_otherThreadContext];
            }
            
            glDeleteTextures(1, &_zoomedTexture);
            
            if(mainThread) {
                [_otherThreadContextLock unlock];
            }            
        }
        _zoomedTexture = zoomedTexture;
    }
}

@end
