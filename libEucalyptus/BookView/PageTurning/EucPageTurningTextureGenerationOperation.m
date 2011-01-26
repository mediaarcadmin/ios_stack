//
//  EucPageTurningTextureGenerationOperation.m
//  libEucalyptus
//
//  Created by James Montgomerie on 07/10/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucPageTurningTextureGenerationOperation.h"
#import "THPair.h"
#import "THOpenGLTexturePool.h"

@implementation EucPageTurningTextureGenerationOperation

@synthesize delegate = _delegate;
@synthesize texturePool = _texturePool;
@synthesize generationInvocation = _generationInvocation;

@synthesize pageIndex = _pageIndex;
@synthesize textureRect = _textureRect;
@synthesize isZoomed = _isZoomed;

@synthesize generatedTextureID = _generatedTextureID;

- (void)dealloc
{
    [_generationInvocation release]; 
    [_texturePool release];
    
    [super dealloc];
}

- (void)mainThreadNotify
{
    if(self.delegate) {
        [self.delegate textureGenerationOperationGeneratedTexture:self];
    } else {
        [self.texturePool recycleTexture:self.generatedTextureID];
    }
}

- (void)main
{
    [self.delegate willBeginTextureGeneration:self];
    
    NSInvocation *generationInvocation = self.generationInvocation;
    [generationInvocation invoke];
    THPair *generatedRGBAContentsAndSize = nil;
    [generationInvocation getReturnValue:&generatedRGBAContentsAndSize];
	
    if(generatedRGBAContentsAndSize) {
        NSData *data = generatedRGBAContentsAndSize.first;
        CGSize size = [(NSValue *)generatedRGBAContentsAndSize.second CGSizeValue];
        
        THOpenGLTexturePool *texturePool = self.texturePool;
        EAGLContext *context = [texturePool checkOutEAGLContext];
        [context thPush];
        
        GLuint textureID = [texturePool unusedTexture];
        
        glBindTexture(GL_TEXTURE_2D, textureID); 
        
        glPixelStorei (GL_UNPACK_ALIGNMENT, 1);
        
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, size.width, size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data.bytes);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);    
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);    
        
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);   
        
        [context thPop];
		[texturePool checkInEAGLContext];
        
        self.generatedTextureID = textureID;
        [self  performSelectorOnMainThread:@selector(mainThreadNotify) 
                                withObject:nil 
                             waitUntilDone:NO];
    }
    self.generationInvocation = nil;
    
    [self.delegate didEndTextureGeneration:self];
}


@end
