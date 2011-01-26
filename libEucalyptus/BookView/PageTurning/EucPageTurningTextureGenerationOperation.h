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

// Called on backgroud thread.
// In the implementation of these, if the application is in the background,
// willBeginTextureGeneration should stall until it's in the foreground again.
// (e.g. take a lock in willBeginTextureGeneration, release it in didEndTextureGeneration, 
// and also take the same lock on the main thread while the app is in the background).
- (void)willBeginTextureGeneration:(EucPageTurningTextureGenerationOperation *)operation;
- (void)didEndTextureGeneration:(EucPageTurningTextureGenerationOperation *)operation;

@end