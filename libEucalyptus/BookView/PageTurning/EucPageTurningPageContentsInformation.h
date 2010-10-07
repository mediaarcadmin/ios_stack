//
//  EucPageTurningPageContentsInformation.h
//  libEucalyptus
//
//  Created by James Montgomerie on 07/10/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "THOpenGLUtils.h"

@interface EucPageTurningPageContentsInformation : NSObject {
    EAGLContext *_mainThreadContext;
    EAGLContext *_otherThreadContext;
    NSLock *_otherThreadContextLock;
    
    NSUInteger _pageIndex;
    UIView *_view;
    GLuint _texture;
    GLuint _zoomedTexture;
    CGRect _zoomedTextureRect;    
}

@property (nonatomic, retain) UIView *view;
@property (nonatomic, assign) NSUInteger pageIndex;


// These /say/ assign, but actually, after assignment, the textures belong
// to this object, and will be deleted when they're finished with.
@property (nonatomic, assign) GLuint texture;
@property (nonatomic, assign) GLuint zoomedTexture;

@property (nonatomic, assign) CGRect zoomedTextureRect;


- (id)initWithMainMainThreadContext:(EAGLContext *)mainThreadContext 
                 otherThreadContext:(EAGLContext *)otherThreadContext
             otherThreadContextLock:(NSLock *)otherThreadContextLock;

@end
