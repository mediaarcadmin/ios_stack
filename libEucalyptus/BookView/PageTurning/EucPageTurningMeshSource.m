//
//  EucPageTurningMeshSource.m
//  libEucalyptus
//
//  Created by James Montgomerie on 09/09/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucPageTurningMeshSource.h"

@implementation EucPageTurningMeshSource

- (GLuint)triangleStripCountForMeshWithPointDimensions:(THGLuintSize)meshDimensions
{
    return ((meshDimensions .height - 1) * (meshDimensions.width * 2 + 3));
}

- (NSData *)triangleStripForMeshWithPointDimensions:(THGLuintSize)meshDimensions
{
    GLuint count = [self triangleStripCountForMeshWithPointDimensions:meshDimensions];
    NSMutableData *data = [[NSMutableData alloc] initWithLength:count * sizeof(GLuint)];
   
    GLuint *triangleStripIndices = data.mutableBytes;
    
    GLuint triangleStripIndex = 0;
    GLuint width = meshDimensions.width;
    GLuint lastColumn = width - 1;
    for(GLuint row = 0; row < meshDimensions.height - 1; ++row) {
        if((row % 2) == 0) {
            GLuint i = 0;
            triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(i, row, width);
            for(; i < meshDimensions.width; ++i) {
                triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(i, row+1, width);
                triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(i, row, width);
            }
            triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(lastColumn, row+1, width);
            triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(lastColumn, row+1, width);
        } else {
            GLuint i = meshDimensions.width - 1;
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

- (NSData *)textureCoordinatesForMeshWithPointDimensions:(THGLuintSize)meshDimensions 
                                             textureSize:(THGLuintSize)textureSize
                                          validImageRect:(THGLuintSize)subTextureSize
{
    GLuint count = meshDimensions.width * meshDimensions.height;
    NSMutableData *data = [[NSMutableData alloc] initWithLength:count * sizeof(THGLfloatPoint2D)];
        
    GLfloat po2WidthScale = (GLfloat)subTextureSize.width / (GLfloat)textureSize.width;
    GLfloat po2HeightScale = (GLfloat)subTextureSize.height / (GLfloat)textureSize.height;
    
    GLfloat xStep = 2.0f / (2 * meshDimensions.width - 3);
    GLfloat yStep = 1.0f / (meshDimensions.height - 1);
    
    GLfloat yCoord = 0.0f;
    THGLfloatPoint2D *point = data.mutableBytes;
    for(int row = 0; row < meshDimensions.height; ++row) {
        GLfloat xCoord = 0.0f;
        for(int column = 0; column < meshDimensions.width; ++column) {
            //THGLfloatPoint2D *point = textureCoordinates + THGLIndexForColumnAndRow(column, row, meshSize.width);
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

- (NSMutableData *)flatMeshWithPointDimensions:(THGLuintSize)meshDimensions
                                          size:(THGLfloatSize)dimensions
                                      atOrigin:(THGLfloatPoint2D)origin
{
    GLuint count = meshDimensions.width * meshDimensions.height;
    NSMutableData *data = [[NSMutableData alloc] initWithLength:count * sizeof(THGLfloatPoint3D)];
    
    GLfloat xStep = ((GLfloat)dimensions.width * 2) / (2 * meshDimensions.width - 3);
    GLfloat yStep = ((GLfloat)dimensions.height / (meshDimensions.height - 1));
    GLfloat baseXCoord = origin.x;
    GLfloat yCoord = origin.y;

    GLfloat maxX = dimensions.width + baseXCoord;
    GLfloat maxY = dimensions.height + yCoord;
    
    THGLfloatPoint3D *point = data.mutableBytes;
    
    for(int row = 0; row < meshDimensions.height; ++row) {
        GLfloat xCoord = baseXCoord;
        for(int column = 0; column < meshDimensions.width; ++column) {
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
