//
//  THBaseEAGLView.m
//  libEucalyptus
//
//  Created by James Montgomerie on 07/11/2008.
//  Copyright 2008 Things Made Out Of Other Things Limited. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <objc/message.h>

#import "THLog.h"
#import "THBaseEAGLView.h"

@interface THBaseEAGLView ()

@property (nonatomic, assign) id animationTimer;

- (BOOL)_createFramebuffer;
- (void)_destroyFramebuffer;

@end


@implementation THBaseEAGLView

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
    if([self respondsToSelector:@selector(setContentScaleFactor:)]) {
        [self setContentScaleFactor:[UIScreen mainScreen].scale];
    }    
    
    // Get the layer
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                                    kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
    _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
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
        _needsDraw = YES;
    }
}

- (void)drawView 
{
    _needsDraw = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(drawView) object:nil];
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
    glGenFramebuffers(1, &_viewFramebuffer);
    glGenRenderbuffers(1, &_viewRenderbuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _viewFramebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _viewRenderbuffer);
    [self.eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _viewRenderbuffer);
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    glGenRenderbuffers(1, &_depthRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, _backingWidth, _backingHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderbuffer);

    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        THWarn(@"failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }
    
    return YES;
}


- (void)_destroyFramebuffer 
{    
    glDeleteFramebuffers(1, &_viewFramebuffer);
    _viewFramebuffer = 0;
    glDeleteRenderbuffers(1, &_viewRenderbuffer);
    _viewRenderbuffer = 0;
    
    if(_depthRenderbuffer) {
        glDeleteRenderbuffers(1, &_depthRenderbuffer);
        _depthRenderbuffer = 0;
    }
}


- (void)setAnimating:(BOOL)animating
{
    if(animating != _animating) {
        if(animating) {
            // Actually, don't use displaylink - it causes lots of jittering
            // during interaction on early devices.
            // Use CADisplayLink, if available.
            Class displayLinkClass = NSClassFromString(@"CADisplayLink");
            if(displayLinkClass) {
                if(!self.animationTimer) {
                    id displayLink = objc_msgSend(displayLinkClass, @selector(displayLinkWithTarget:selector:), self, @selector(drawView));
                    objc_msgSend(displayLink, @selector(setFrameInterval:), round(_animationInterval * 60.0));
                    objc_msgSend(displayLink, @selector(addToRunLoop:forMode:), [NSRunLoop currentRunLoop], NSDefaultRunLoopMode);
                    self.animationTimer = displayLink;
                } else {
                    id displayLink = self.animationTimer;
                    objc_msgSend(displayLink, @selector(setFrameInterval:), round(_animationInterval * 60.0));
                    objc_msgSend(displayLink, @selector(setPaused:), NO);
                }
            } else {
                self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:self.animationInterval target:self selector:@selector(drawView) userInfo:nil repeats:YES];
            }
        } else {
            id animationTimer = self.animationTimer;
            if([animationTimer isKindOfClass:[NSTimer class]]) {
                [animationTimer invalidate];
                self.animationTimer = nil;
            } else {
                objc_msgSend(animationTimer, @selector(setPaused:), YES);
            }
        }
        _animating = animating;        
    }
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
    if(self.animationTimer) {
        [self.animationTimer invalidate]; // Works with NSTimer and CADisplayLink.
        self.animationTimer = nil;
    }
    if(_needsDraw) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(drawView) object:nil];
    }
    
    if ([EAGLContext currentContext] == _eaglContext) {
        [EAGLContext setCurrentContext:nil];
    }
    
    [_eaglContext release];  
    [super dealloc];
}

@end
