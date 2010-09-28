/*
 *  THOpenGLUtils.h
 *  libEucalyptus
 *
 *  Created by James Montgomerie on 09/09/2010.
 *  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
 *
 */

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>

#pragma mark -
#pragma mark Sanity Checks

// We assume that CATransform3D == mat4 so that we can use the CA matrix 
// routines.
// This should cause an error if that is ever inadvisable because iOS has been
// upgraded to 64-bit CGFloats

#if CGFLOAT_IS_DOUBLE

#error Uh-oh!  libEucalyptus code assumes CGFloat == float == GLFloat, and this is not true.  Some work is required to stop using CGFloat based code!

#endif

#pragma mark -
#pragma mark Primitives

typedef struct {
    GLfloat x;
    GLfloat y;
    GLfloat z;
} THVec3;

static inline THVec3 THVec3Make(GLfloat x, GLfloat y, GLfloat z) {
    THVec3 ret = {x, y, z};
    return ret;
}

typedef struct {
    GLfloat x;
    GLfloat y;
    GLfloat z;
    GLfloat w;
} THVec4;

static inline THVec4 THVec4Make(GLfloat x, GLfloat y, GLfloat z, GLfloat w) {
    THVec4 ret = {x, y, z, w};
    return ret;
}

static inline THVec3 THVec3FromVec4(THVec4 vec4) {
    return THVec3Make(vec4.x / vec4.w, vec4.y / vec4.w, vec4.z / vec4.w);
}

typedef struct {
    GLfloat x;
    GLfloat y;
} THVec2;

static inline THVec2 THVec2Make(GLfloat x, GLfloat y) {
    THVec2 ret = {x, y};
    return ret;
}

typedef struct {
    GLuint x;
    GLuint y;
} THIVec2;


static inline THIVec2 THIVec2Make(GLuint x, GLuint y) {
    THIVec2 ret = {x, y};
    return ret;
}

#pragma mark -
#pragma mark Operations

static inline THVec3 THVec3Add(THVec3 a, THVec3 b)
{
    THVec3 ret = { a.x + b.x, a.y + b.y, a.z + b.z };
    return ret;
}

static inline THVec3 THVec3Subtract(THVec3 a, THVec3 b)
{
    THVec3 ret = { a.x - b.x, a.y - b.y, a.z - b.z };
    return ret;
}

static inline THVec3 THVec3Multiply(THVec3 a, GLfloat b)
{
    THVec3 ret = { a.x * b, a.y * b, a.z * b };
    return ret;
}

static inline THVec3 THVec3CrossProduct(THVec3 a, THVec3 b)
{
    THVec3 ret = { a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x};
    return ret;
}

static inline GLfloat THVec3DotProduct(THVec3 a) 
{
    return a.x * a.x + a.y * a.y + a.z * a.z;
}

static inline GLfloat THVec3Magnitude(const THVec3 a) 
{
    return sqrtf(THVec3DotProduct(a));
}


static inline GLfloat THVec3AbsMagnitude(const THVec3 a) 
{
    return fabsf(THVec3Magnitude(a));
}

static inline THVec3 THVec3Normalize(const THVec3 a)
{
    GLfloat aMagnitude = THVec3Magnitude(a); 
    THVec3 ret = { a.x / aMagnitude, a.y / aMagnitude, a.z / aMagnitude};
    return ret;
}

static inline CATransform3D THCATransform3DTranspose(CATransform3D m) 
{
    CATransform3D ret = { m.m11, m.m21, m.m31, m.m41,
                          m.m12, m.m22, m.m32, m.m42,
                          m.m13, m.m23, m.m33, m.m43,
                          m.m14, m.m24, m.m34, m.m44 };
    return ret;
}

static inline THVec4 THCATransform3DVec4Multiply(CATransform3D m, THVec4 v) 
{
    return THVec4Make(m.m11 * v.x + m.m21 * v.y + m.m31 * v.z + m.m41 * v.w,
                      m.m12 * v.x + m.m22 * v.y + m.m32 * v.z + m.m42 * v.w,
                      m.m13 * v.x + m.m23 * v.y + m.m33 * v.z + m.m43 * v.w,
                      m.m14 * v.x + m.m24 * v.y + m.m34 * v.z + m.m44 * v.w);
}


static inline THVec3 THCATransform3DVec3Multiply(CATransform3D m, THVec3 v) 
{
    THVec4 vec4 = THVec4Make(v.x, v.y, v.z, 1.0f);
    return THVec3FromVec4(THCATransform3DVec4Multiply(m, vec4));
}


static inline GLuint THGLIndexForColumnAndRow(GLuint column, GLuint row, GLuint rowLength) 
{
    return row * rowLength + column;
}

#pragma mark -
#pragma mark Utility Functions

GLuint THGLLoadShader(GLenum type, const char *shaderSource, GLint shaderSourceLength);

CATransform3D THCATransform3DLookAt(CATransform3D modelViewMatrix, THVec3 eye, THVec3 lookAt, THVec3 up);

CATransform3D THCATransform3DPerspective(CATransform3D perspectiveMatrix, GLfloat fovy, GLfloat aspect, GLfloat near, GLfloat far);
