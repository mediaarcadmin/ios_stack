//
//  EucPageTurningTextureGenerationOperation.m
//  libEucalyptus
//
//  Created by James Montgomerie on 07/10/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucPageTurningTextureGenerationOperation.h"
#import "THPair.h"

@implementation EucPageTurningTextureGenerationOperation

@synthesize delegate = _delegate;
@synthesize eaglContext = _eaglContext;
@synthesize contextLock = _contextLock;
@synthesize generationInvocation = _generationInvocation;

@synthesize pageIndex = _pageIndex;
@synthesize textureRect = _textureRect;

- (void)dealloc
{
    [_eaglContext release];
    [_contextLock release];
    
    [super dealloc];
}

- (void)main
{
    NSInvocation *generationInvocation = self.generationInvocation;
    [generationInvocation invoke];
    THPair *generatedRGBAContentsAndSize = nil;
    [generationInvocation getReturnValue:&generatedRGBAContentsAndSize];
    if(generatedRGBAContentsAndSize) {
        NSData *data = generatedRGBAContentsAndSize.first;
        CGSize size = [(NSValue *)generatedRGBAContentsAndSize.second CGSizeValue];
        
        NSLock *contextLock = self.contextLock;
        [contextLock lock];
        [EAGLContext setCurrentContext:self.eaglContext];
        GLuint textureID = [self.delegate textureGenerationOperationGetTextureId:self];
        
        glBindTexture(GL_TEXTURE_2D, textureID); 
        
        glPixelStorei (GL_UNPACK_ALIGNMENT, 1);
        
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, size.width, size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data.bytes);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);    
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);    
        
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);   
        
        [contextLock unlock];
        [self.delegate textureGenerationOperation:self generatedTexture:textureID];
    } else {
        [self.delegate textureGenerationOperation:self generatedTexture:0];
    }
    self.generationInvocation = nil;
}


@end
