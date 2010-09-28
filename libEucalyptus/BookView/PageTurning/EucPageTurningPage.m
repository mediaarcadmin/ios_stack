//
//  EucPageTurningPage.m
//  libEucalyptus
//
//  Created by James Montgomerie on 09/09/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucPageTurningPage.h"
#import "EucPageTurningMeshSource.h"


@interface EucPageTurningPage () 

@property (nonatomic, assign, readonly) THIVec2 meshPointDimensions;

@property (nonatomic, retain) NSData *meshVertices;

@end

@implementation EucPageTurningPage

@synthesize size = _size;
@synthesize meshSource = _meshSource;

@synthesize frontSource = _frontSource;
@synthesize backSource = _backSource;

@synthesize meshVertices = _meshVertices;
@synthesize flatnessState = _flatnessState;

@synthesize frontTexture = _frontTexture;
@synthesize frontTexture = _backTexture;

- (id)initWithMeshSource:(EucPageTurningMeshSource *)meshSource
                    size:(THVec2)size 
             frontSource:(id)frontSource
              backSource:(id)backSource
           flatnessState:(EucPageFlatnessState)flatnessState;
{
    if((self = [super init])) {
        _meshSource = [meshSource retain];
        _size = size;
        _frontSource = [frontSource retain];
        _backSource = [backSource retain];
        self.flatnessState = flatnessState;
    }
    return self;
}

- (void)dealloc
{
    [_frontSource release];
    [_backSource release];
    [_meshVertices release];
    [_meshSource release];
    
    [super dealloc];
}


- (THIVec2)meshPointDimensions
{
    return THIVec2Make(11, 16);
}


-(NSData *)meshTriangleStrip
{
    return [_meshSource triangleStripForMeshWithPointDimensions:self.meshPointDimensions];
}

- (void)setFlatnessState:(EucPageFlatnessState)flatnessState
{
    if(flatnessState == EucPageFlatnessStateFlatRight || 
       flatnessState == EucPageFlatnessStateFlatLeft) {
        self.meshVertices = nil;
        self.meshVertices = [self.meshSource flatMeshWithPointDimensions:self.meshPointDimensions
                                                                    size:self.size
                                                                atOrigin:THVec2Make(0, 0)];
        if(flatnessState == EucPageFlatnessStateFlatLeft) {
            NSMutableData *meshVertices = (NSMutableData *)self.meshVertices;
            THVec2 *vertices = meshVertices.mutableBytes;
            off_t vertexCount = meshVertices.length / sizeof(THVec2);
            for(off_t i = 0; i < vertexCount; ++i) {
                vertices[i].x = -vertices[i].x;
            }
        }
    }
}

@end

