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

- (GLuint)triangleStripCountForMeshWithPointDimensions:(THIVec2)meshDimensions;
- (NSData *)triangleStripForMeshWithPointDimensions:(THIVec2)meshDimensions;
- (NSData *)textureCoordinatesForMeshWithPointDimensions:(THIVec2)meshDimensions 
                                             textureSize:(THIVec2)textureSize
                                          validImageRect:(THIVec2)subTextureSize;
- (NSMutableData *)flatMeshWithPointDimensions:(THIVec2)meshDimensions
                                          size:(THVec2)dimensions
                                      atOrigin:(THVec2)origin;
    
@end
