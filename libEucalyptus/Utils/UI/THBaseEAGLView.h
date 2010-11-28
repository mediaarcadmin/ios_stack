//
//  THBaseEAGLView.h
//  libEucalyptus
//
//  Created by James Montgomerie on 07/11/2008.
//  Copyright 2008 Things Made Out Of Other Things Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface THBaseEAGLView : UIView {
    GLint _backingWidth;
    GLint _backingHeight;
    
    EAGLContext *_eaglContext;
    
    /* OpenGL names for the renderbuffer and framebuffers used to render to this view */
    GLuint _viewRenderbuffer, _viewFramebuffer;
    
    /* OpenGL name for the depth buffer that is attached to viewFramebuffer */
    GLuint _depthRenderbuffer;
    
    BOOL _animating;
    id _animationTimer;
    NSTimeInterval _animationInterval;
    
    BOOL _needsDraw;
    BOOL _didJustMoveToNewWindow;
}

@property (nonatomic, assign, getter=isAnimating) BOOL animating;
@property (nonatomic, assign) NSTimeInterval animationInterval;
@property (nonatomic, assign) id animationTimer;

- (void)setNeedsDraw;
- (void)drawView;

// Protected.
@property (nonatomic, retain) EAGLContext *eaglContext;

@end
