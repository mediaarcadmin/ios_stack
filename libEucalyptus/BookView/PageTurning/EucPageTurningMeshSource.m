//
//  EucPageTurningMeshSource.m
//  libEucalyptus
//
//  Created by James Montgomerie on 09/09/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucPageTurningMeshSource.h"

@implementation EucPageTurningMeshSource

- (GLuint)triangleStripCountForMeshWithPointDimensions:(THIVec2)meshDimensions
{
    return ((meshDimensions.y - 1) * (meshDimensions.x * 2 + 3));
}

- (NSData *)triangleStripForMeshWithPointDimensions:(THIVec2)meshDimensions
{
    GLuint count = [self triangleStripCountForMeshWithPointDimensions:meshDimensions];
    NSMutableData *data = [[NSMutableData alloc] initWithLength:count * sizeof(GLuint)];
   
    GLuint *triangleStripIndices = data.mutableBytes;
    
    GLuint triangleStripIndex = 0;
    GLuint width = meshDimensions.x;
    GLuint lastColumn = width - 1;
    for(GLuint row = 0; row < meshDimensions.y - 1; ++row) {
        if((row % 2) == 0) {
            GLuint i = 0;
            triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(i, row, width);
            for(; i < meshDimensions.x; ++i) {
                triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(i, row+1, width);
                triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(i, row, width);
            }
            triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(lastColumn, row+1, width);
            triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(lastColumn, row+1, width);
        } else {
            GLuint i = meshDimensions.x - 1;
            triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(i, row, width);
            for(; i >= 0; --i) {
                triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(i, row+1, width);
                triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(i, row, width);
            } 
            triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(0, row+1, width);
            triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(0, row+1, width);
        }
    }

    return data;
}

- (NSData *)textureCoordinatesForMeshWithPointDimensions:(THIVec2)meshDimensions 
                                             textureSize:(THIVec2)textureSize
                                          validImageRect:(THIVec2)subTextureSize
{
    GLuint count = meshDimensions.x * meshDimensions.y;
    NSMutableData *data = [[NSMutableData alloc] initWithLength:count * sizeof(THVec2)];
        
    GLfloat po2WidthScale = (GLfloat)subTextureSize.x / (GLfloat)textureSize.x;
    GLfloat po2HeightScale = (GLfloat)subTextureSize.y / (GLfloat)textureSize.y;
    
    GLfloat xStep = 2.0f / (2 * meshDimensions.x - 3);
    GLfloat yStep = 1.0f / (meshDimensions.y - 1);
    
    GLfloat yCoord = 0.0f;
    THVec2 *point = data.mutableBytes;
    for(int row = 0; row < meshDimensions.y; ++row) {
        GLfloat xCoord = 0.0f;
        for(int column = 0; column < meshDimensions.x; ++column) {
            //THGLfloatPoint2D *point = textureCoordinates + THGLIndexForColumnAndRow(column, row, meshSize.x);
            point->x = MIN(xCoord, 1.0f) * po2WidthScale;
            point->y = MIN(yCoord, 1.0f) * po2HeightScale;                    
            if(xCoord == 0.0f && (row % 2) == 1) {
                xCoord += xStep * 0.5f;
            } else {
                xCoord += xStep;
            }
            ++point;
        }
        yCoord += yStep;
    }
    
    return data;
}

- (NSMutableData *)flatMeshWithPointDimensions:(THIVec2)meshDimensions
                                          size:(THVec2)dimensions
                                      atOrigin:(THVec2)origin
{
    GLuint count = meshDimensions.x * meshDimensions.y;
    NSMutableData *data = [[NSMutableData alloc] initWithLength:count * sizeof(THVec3)];
    
    GLfloat xStep = ((GLfloat)dimensions.x * 2) / (2 * meshDimensions.x - 3);
    GLfloat yStep = ((GLfloat)dimensions.y / (meshDimensions.y - 1));
    GLfloat baseXCoord = origin.x;
    GLfloat yCoord = origin.y;

    GLfloat maxX = dimensions.x + baseXCoord;
    GLfloat maxY = dimensions.y + yCoord;
    
    THVec3 *point = data.mutableBytes;
    
    for(int row = 0; row < meshDimensions.y; ++row) {
        GLfloat xCoord = baseXCoord;
        for(int column = 0; column < meshDimensions.x; ++column) {
            point->x = MIN(xCoord, maxX);
            point->y = MIN(yCoord, maxY);
            // z is already 0.
            
            if(xCoord == baseXCoord && (row % 2) == 1) {
                xCoord += xStep * 0.5f;
            } else {
                xCoord += xStep;
            }
            ++point;
        }
        yCoord += yStep;
    }
    
    return data;
}

@end
