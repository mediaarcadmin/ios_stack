//
//  THAppleSampleEAGLView.m
//  PageTurnTest
//
//  Created by James Montgomerie on 07/11/2008.
//  Copyright 2008 Things Made Out Of Other Things Limited. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "THAppleSampleEAGLView.h"

@interface THAppleSampleEAGLView ()

@property (nonatomic, assign) id animationTimer;

- (BOOL)_createFramebuffer;
- (void)_destroyFramebuffer;

@end


@implementation THAppleSampleEAGLView

@synthesize animating = _animating;
@synthesize eaglContext = _eaglContext;
@synthesize animationTimer = _animationTimer;
@synthesize animationInterval = _animationInterval;

+ (Class)layerClass 
{
    return [CAEAGLLayer class];
}

- (BOOL)_eaglViewInternalInit
{
    // Get the layer
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
    _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    
    if (!_eaglContext || ![EAGLContext setCurrentContext:_eaglContext]) {
        return NO;
    }
    
    _animationInterval = 1.0 / 30.0;
    
    return YES;
}

- (id)initWithCoder:(NSCoder*)coder 
{    
    if ((self = [super initWithCoder:coder])) {
        if(![self _eaglViewInternalInit]) {
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame 
{    
    if ((self = [super initWithFrame:frame])) {
        if(![self _eaglViewInternalInit]) {
            [self release];
            self = nil;
        }
    }
    return self;
}

- (void)setNeedsDraw
{
    if(!_animating && !_needsDraw) {
        [self performSelector:@selector(drawView) withObject:nil afterDelay:0];
    }
}

- (void)drawView 
{
    if(_needsDraw) {
        _needsDraw = NO;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(drawView) object:nil];
    }    
}

- (void)didMoveToWindow
{
    if(self.window) {
        // Make sure we immediately draw so that we don't appear blank.
        _didJustMoveToNewWindow = YES;
    }
    [super didMoveToWindow];
}

- (void)layoutSubviews 
{
    [super layoutSubviews];
    [EAGLContext setCurrentContext:self.eaglContext];
    [self _destroyFramebuffer];
    [self _createFramebuffer];
    if(_didJustMoveToNewWindow) {
        [self drawView];
        _didJustMoveToNewWindow = NO;
    } else {
        [self setNeedsDraw];
    }
}

- (BOOL)_createFramebuffer 
{    
    glGenFramebuffersOES(1, &_viewFramebuffer);
    glGenRenderbuffersOES(1, &_viewRenderbuffer);
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, _viewFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, _viewRenderbuffer);
    [self.eaglContext renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, _viewRenderbuffer);
    
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &_backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &_backingHeight);
    
    glGenRenderbuffersOES(1, &_depthRenderbuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, _depthRenderbuffer);
    glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, _backingWidth, _backingHeight);
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, _depthRenderbuffer);

    if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
    
    return YES;
}


- (void)_destroyFramebuffer 
{    
    glDeleteFramebuffersOES(1, &_viewFramebuffer);
    _viewFramebuffer = 0;
    glDeleteRenderbuffersOES(1, &_viewRenderbuffer);
    _viewRenderbuffer = 0;
    
    if(_depthRenderbuffer) {
        glDeleteRenderbuffersOES(1, &_depthRenderbuffer);
        _depthRenderbuffer = 0;
    }
}


- (void)setAnimating:(BOOL)animating
{
    if(animating != _animating) {
        if(animating) {
            self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:self.animationInterval target:self selector:@selector(drawView) userInfo:nil repeats:YES];
        } else {
            self.animationTimer = nil;
        }
        _animating = animating;        
    }
}

- (void)setAnimationTimer:(NSTimer *)newTimer 
{
    [_animationTimer invalidate];
    _animationTimer = newTimer;
}

- (void)setAnimationInterval:(NSTimeInterval)interval
{    
    _animationInterval = interval;
    if(self.isAnimating) {
        self.animating = NO;
        self.animating = YES;
    }
}

- (void)dealloc 
{    
    self.animating = NO;
    if(!_needsDraw) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(drawView) object:nil];
    }
    
    if ([EAGLContext currentContext] == _eaglContext) {
        [EAGLContext setCurrentContext:nil];
    }
    
    [_eaglContext release];  
    [super dealloc];
}

@end
