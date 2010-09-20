/*
 *  THOpenGLUtils.h
 *  libEucalyptus
 *
 *  Created by James Montgomerie on 09/09/2010.
 *  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
 *
 */

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

typedef struct {
    GLfloat x;
    GLfloat y;
} THGLfloatPoint2D;

static inline THGLfloatPoint2D THGLfloatPoint2DMake(GLfloat x, GLfloat y) {
    THGLfloatPoint2D ret = {x, y};
    return ret;
}

typedef struct {
    GLfloat x;
    GLfloat y;
    GLfloat z;
} THGLfloatPoint3D;

static inline THGLfloatPoint3D THGLfloatPoint3DMake(GLfloat x, GLfloat y, GLfloat z) {
    THGLfloatPoint3D ret = {x, y, z};
    return ret;
}

typedef struct {
    GLuint width;
    GLuint height;
} THGLuintSize;

static inline THGLuintSize THGLuintSizeMake(GLuint width, GLuint height) {
    THGLuintSize ret = {width, height};
    return ret;
}

typedef struct {
    GLfloat width;
    GLfloat height;
} THGLfloatSize;

static inline THGLfloatSize THGLfloatSizeMake(GLfloat width, GLfloat height) {
    THGLfloatSize ret = {width, height};
    return ret;
}

static inline GLuint THGLIndexForColumnAndRow(GLuint column, GLuint row, GLuint rowLength) 
{
    return row * rowLength + column;
}
