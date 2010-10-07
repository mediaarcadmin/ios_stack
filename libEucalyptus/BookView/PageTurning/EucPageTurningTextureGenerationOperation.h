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
}

@property (nonatomic, assign) id<EucPageTurningTextureGenerationOperationDelegate> delegate;
@property (nonatomic, retain) EAGLContext *eaglContext;
@property (nonatomic, retain) NSLock *contextLock;
@property (nonatomic, retain) NSInvocation *generationInvocation;
@property (nonatomic, assign) NSUInteger pageIndex;
@property (nonatomic, assign) CGRect textureRect;

@end


@protocol EucPageTurningTextureGenerationOperationDelegate

@required

// Called on the main thread.
- (void)textureGenerationOperation:(EucPageTurningTextureGenerationOperation *)operation generatedTexture:(GLuint)texture;

// Called on background thread.
- (GLuint)textureGenerationOperationGetTextureId:(EucPageTurningTextureGenerationOperation *)operation;

@end