/*
 *  THOpenGLUtils.m
 *  libEucalyptus
 *
 *  Created by James Montgomerie on 24/09/2010.
 *  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
 *
 */

#import "THOpenGLUtils.h"
#import "THLog.h"

GLuint THGLLoadShader(GLenum type, const char *shaderSource, GLint shaderSourceLength) 
{
    GLuint shader = glCreateShader(type);
    if(shader) {
        glShaderSource(shader, 1, &shaderSource, &shaderSourceLength);
    
        glCompileShader(shader);
        
        GLint compiled;
        glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
        
        if(!compiled) {
            GLint infoLength;
            glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLength);
            if(infoLength > 1) {
                char *infoLog = malloc(infoLength);
                glGetShaderInfoLog(shader, infoLength, NULL, infoLog);
                THWarn(@"Error compiling shader: \"%s\"", infoLog);
                free(infoLog);
            } else {
                THWarn(@"Unknown error compiling shader");
            }
            
            glDeleteShader(shader);
            shader = 0;
        }
    }

    return shader;
}

CATransform3D THCATransform3DLookAt(CATransform3D modelViewMatrix,
                                    THVec3 eye,
                                    THVec3 lookAt, 
                                    THVec3 up) 
{
    THVec3 viewingVetor = THVec3Normalize(THVec3Subtract(lookAt, eye));
    
    THVec3 side  = THVec3Normalize(THVec3CrossProduct(viewingVetor, up));
    THVec3 newUp = THVec3Normalize(THVec3CrossProduct(side, viewingVetor));
    
    CATransform3D result = { side.x,  newUp.x, -viewingVetor.x, 0.0f,
                             side.y,  newUp.y, -viewingVetor.y, 0.0f,
                             side.z,  newUp.z, -viewingVetor.z, 0.0f,
                             0.0f,    0.0f,    0.0f,            1.0f };
    
    result = CATransform3DConcat(modelViewMatrix, result);
    result = CATransform3DTranslate(result, -eye.x, -eye.y, -eye.z);
    
    return result;
}

CATransform3D THCATransform3DPerspective(CATransform3D perspectiveMatrix, 
                                         GLfloat fovy, 
                                         GLfloat aspect,
                                         GLfloat near,
                                         GLfloat far) 
{ 
    GLfloat top = near * tanf(fovy * (float)M_PI / 360.0f);   
    GLfloat bottom = -top; 
    
    GLfloat left = bottom * aspect;
    GLfloat right = top * aspect;  
    
    GLfloat twoNear = 2.0f * near;
    GLfloat deltaX = right - left;
    GLfloat deltaY = top - bottom;
    GLfloat deltaz = far - near;
    
    CATransform3D m = { twoNear / deltaX, 0.0f, 0.0f, 0.0f,
        0.0f, twoNear / deltaY, 0.0f, 0.0f,
        (right + left) / deltaX, (top + bottom) / deltaY, -(far + near) / deltaz, -1.0f,
        0.0f, 0.0f, (-twoNear * far) / deltaz, 0.0f };
    
    return CATransform3DConcat(perspectiveMatrix, m); 
} 
