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
@class THOpenGLTexturePool;

@interface EucPageTurningTextureGenerationOperation : NSOperation {
    id<EucPageTurningTextureGenerationOperationDelegate> _delegate;
    THOpenGLTexturePool *_texturePool;

    NSInvocation *_generationInvocation;
    NSUInteger pageIndex;
    CGRect textureRect;
    BOOL _isZoomed;
    GLuint generatedTextureID;
}

@property (nonatomic, assign) id<EucPageTurningTextureGenerationOperationDelegate> delegate;
@property (nonatomic, retain) THOpenGLTexturePool *texturePool;

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

@end