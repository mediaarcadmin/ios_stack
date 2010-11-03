//
//  THOpenGLTexturePool.h
//  libEucalyptus
//
//  Created by James Montgomerie on 02/11/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface THOpenGLTexturePool : NSObject {
    EAGLContext *_mainThreadContext;
    EAGLContext *_backgroundThreadContext;
    NSRecursiveLock *_backgroundThreadContextLock;
    
    NSMutableArray *_unusedTextures;
    NSLock *_unusedTexturesLock;
}

- (id)initWithMainThreadContext:(EAGLContext *)mainThreadContext;

- (EAGLContext *)checkOutEAGLContext;
- (void)checkInEAGLContext;

- (GLuint)unusedTexture;
- (void)recycleTexture:(GLuint)texture;

@end
