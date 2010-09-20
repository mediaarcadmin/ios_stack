//
//  EucPageTurningMeshSource.h
//  libEucalyptus
//
//  Created by James Montgomerie on 09/09/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "THOpenGLUtils.h"

@interface EucPageTurningMeshSource : NSObject {}

- (GLuint)triangleStripCountForMeshWithPointDimensions:(THGLuintSize)meshDimensions;
- (NSData *)triangleStripForMeshWithPointDimensions:(THGLuintSize)meshDimensions;
- (NSData *)textureCoordinatesForMeshWithPointDimensions:(THGLuintSize)meshDimensions 
                                             textureSize:(THGLuintSize)textureSize
                                          validImageRect:(THGLuintSize)subTextureSize;
- (NSMutableData *)flatMeshWithPointDimensions:(THGLuintSize)meshDimensions
                                          size:(THGLfloatSize)dimensions
                                      atOrigin:(THGLfloatPoint2D)origin;
    
@end
