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
@synthesize isZoomed = _isZoomed;

@synthesize generatedTextureID = _generatedTextureID;

- (void)dealloc
{
    [_generationInvocation release]; 
    [_eaglContext release];
    [_contextLock release];
    
    [super dealloc];
}

- (void)mainThreadNotify
{
	if (self.isCancelled) {
		GLuint texID = self.generatedTextureID;
		glDeleteTextures(1, &texID);
		self.generationInvocation = nil;
	} else {
		[self.delegate textureGenerationOperationGeneratedTexture:self];
	}
}

- (void)main
{
	if (self.isCancelled) {
		self.generationInvocation = nil;
		return;
	}
	
    NSInvocation *generationInvocation = self.generationInvocation;
    [generationInvocation invoke];
    THPair *generatedRGBAContentsAndSize = nil;
    [generationInvocation getReturnValue:&generatedRGBAContentsAndSize];
	
    if(generatedRGBAContentsAndSize) {
        NSData *data = generatedRGBAContentsAndSize.first;
        CGSize size = [(NSValue *)generatedRGBAContentsAndSize.second CGSizeValue];
		
		if (self.isCancelled) {
			[[data retain] autorelease];

			self.generationInvocation = nil;
			return;
		}
        
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
		
		if (self.isCancelled) {
			if (glIsTexture(textureID)) {

				glDeleteTextures(1, &textureID);
			}
			self.generationInvocation = nil;
			return;
		}
        
        self.generatedTextureID = textureID;
        [self  performSelectorOnMainThread:@selector(mainThreadNotify) 
                                withObject:nil 
                             waitUntilDone:NO];
    }
    self.generationInvocation = nil;
}


@end
