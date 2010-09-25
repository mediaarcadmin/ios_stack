/*
 *  THOpenGLUtils.c
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
