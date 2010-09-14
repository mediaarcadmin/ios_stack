//
//  EucPageTurningPage.h
//  libEucalyptus
//
//  Created by James Montgomerie on 09/09/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "THOpenGLUtils.h"

@class EucPageTurningMeshSource;


typedef enum EucPageFlatnessState {
    EucPageFlatnessStateFlatRight,
    EucPageFlatnessStateTurning,
    EucPageFlatnessStateFlatLeft,
} EucPageFlatnessState;

@interface EucPageTurningPage : NSObject {
    EucPageTurningMeshSource *_meshSource;
    
    THGLfloatSize _size;
    id _frontSource;
    id _backSource;
    EucPageFlatnessState _flatnessState;
    
    NSMutableData *_meshVertices;
 
    
    CGSize _naturalPixelSize;
}


- (id)initWithMeshSource:(EucPageTurningMeshSource *)meshSource
                    size:(THGLfloatSize)size 
             frontSource:(id)frontSource
              backSource:(id)backSource
           flatnessState:(EucPageFlatnessState)flatnessState;

@property (nonatomic, assign, readonly) THGLfloatSize size;
@property (nonatomic, retain, readonly) EucPageTurningMeshSource *meshSource;

@property (nonatomic, retain, readonly) id frontSource;
@property (nonatomic, retain, readonly) id backSource;

@property (nonatomic, retain, readonly) NSData *meshVertices;
@property (nonatomic, retain, readonly) NSData *meshTriangleStrip;

@property (nonatomic, assign) EucPageFlatnessState flatnessState;

/*

@property (nonatomic, assign, readonly) GLuint frontTexture;
@property (nonatomic, retain, readonly) NSData *frontTextureCoordinates;

@property (nonatomic, assign, readonly) GLuint backTexture;
@property (nonatomic, retain, readonly) NSData *backTextureCoordinates;

- (void)stepPhysicsForHoldAtPoint:(CGPoint *)point;

*/

@end