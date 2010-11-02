//
//  THOpenGLTexturePool.m
//  libEucalyptus
//
//  Created by James Montgomerie on 02/11/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "THOpenGLUtils.h"
#import "THOpenGLTexturePool.h"

@implementation THOpenGLTexturePool

- (id)initWithMainThreadContext:(EAGLContext *)mainThreadContext
{
    if((self = [super init])) {
        _mainThreadContext = [mainThreadContext retain];
        
        _backgroundThreadContext = [[EAGLContext alloc] initWithAPI:[mainThreadContext API] sharegroup:[mainThreadContext sharegroup]];
        _backgroundThreadContextLock = [[NSRecursiveLock alloc] init];
        _unusedTextures = [[NSMutableArray alloc] init];
        _unusedTexturesLock = [[NSLock alloc] init];
    }
    return self;
}

- (void)dealloc
{
    // Not necessary to lock here,
    // Nothing should be using the context at this stage.
    [_backgroundThreadContext thPush];
    
    for(NSNumber *textureNumber in _unusedTextures) {
        GLuint textureInt = textureNumber.intValue;
        glDeleteTextures(1, &textureInt);
    }
    
    [_backgroundThreadContext thPop];
    
    [_unusedTextures release];
    [_unusedTexturesLock release];
    
    [_backgroundThreadContextLock release];
    [_backgroundThreadContext release];
    
    [_mainThreadContext release];
    
    [super dealloc];
}

- (EAGLContext *)checkOutEAGLContext
{
    if([NSThread isMainThread]) {
        return _mainThreadContext;
    } else {
        // Recursive lock, so if it's already checked out
        // on this thread, this will still allow a second 
        // check-out
        [_backgroundThreadContextLock lock];
        return _backgroundThreadContext;
    }
}

- (void)checkInEAGLContext
{
    if(![NSThread isMainThread]) {
        [_backgroundThreadContextLock unlock];
    }
}

- (GLuint)unusedTexture
{
    GLuint ret;
    
    [_unusedTexturesLock lock];
    if(_unusedTextures.count) {
        ret = [[_unusedTextures objectAtIndex:0] intValue];
        [_unusedTextures removeObjectAtIndex:0];
        [_unusedTexturesLock unlock];
    } else {
        [_unusedTexturesLock unlock];
        EAGLContext *context = [self checkOutEAGLContext];
        [context thPush];
        
        glGenTextures(1, &ret);
        
        [context thPop];
        [self checkInEAGLContext];
    }
    
    return ret;
}

- (void)recycleTexture:(GLuint)texture
{
    [_unusedTexturesLock lock];
    [_unusedTextures addObject:[NSNumber numberWithInt:texture]];
    [_unusedTexturesLock unlock];
}


@end
