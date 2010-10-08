//
//  EucPageTurningTextureGenerationOperation.h
//  libEucalyptus
//
//  Created by James Montgomerie on 07/10/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "THOpenGLUtils.h"

@protocol EucPageTurningTextureGenerationOperationDelegate;

@interface EucPageTurningTextureGenerationOperation : NSOperation {
    id<EucPageTurningTextureGenerationOperationDelegate> _delegate;
    EAGLContext *_eaglContext;
    NSLock *_contextLock;
    NSInvocation *_generationInvocation;
    NSUInteger pageIndex;
    CGRect textureRect;
    BOOL _isZoomed;
    GLuint generatedTextureID;
}

@property (nonatomic, assign) id<EucPageTurningTextureGenerationOperationDelegate> delegate;
@property (nonatomic, retain) EAGLContext *eaglContext;
@property (nonatomic, retain) NSLock *contextLock;
@property (nonatomic, retain) NSInvocation *generationInvocation;
@property (nonatomic, assign) NSUInteger pageIndex;
@property (nonatomic, assign) CGRect textureRect;
@property (nonatomic, assign) BOOL isZoomed;

@property (nonatomic, assign) GLuint generatedTextureID;

@end


@protocol EucPageTurningTextureGenerationOperationDelegate <NSObject>

@required

// Called on the main thread.
- (void)textureGenerationOperationGeneratedTexture:(EucPageTurningTextureGenerationOperation *)operation;

// Called on background threads.
- (GLuint)textureGenerationOperationGetTextureId:(EucPageTurningTextureGenerationOperation *)operation;

@end