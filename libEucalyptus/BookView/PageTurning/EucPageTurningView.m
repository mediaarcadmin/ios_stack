//
//  THPageTurningView.m
//  PageTurnTest
//
//  Created by James Montgomerie on 07/11/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import "EucPageTurningView.h"
#import "THBackgroundProcessingMediator.h"
#import "THTimer.h"
#import "THUIViewThreadSafeDrawing.h"
#import "THAccessibilityElement.h"
#import "THLog.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <AudioToolbox/AudioToolbox.h>
#import <tgmath.h>
#import "THBaseEAGLView.h"
#import "THGeometryUtils.h"
#import "THEmbeddedResourceManager.h"

#define FOV_ANGLE ((GLfloat)10.0f)


@interface EucPageTurningView ()

@property (nonatomic, assign, readonly) CATransform3D zoomMatrix;
@property (nonatomic, assign) CGRect leftPageFrame;
@property (nonatomic, assign) CGRect rightPageFrame;

- (void)_calculateVertexNormals;    
//- (void)_accumulateForces;  // Not used - see comments around implementation.
- (void)_verlet;
- (BOOL)_satisfyConstraints;
- (void)_setupConstraints;
- (void)_cacheNonVisiblePages;
- (CGFloat)_tapTurnMarginForView:(UIView *)view;
- (void)_setNeedsAccessibilityElementsRebuild;
- (CGPoint)_setZoomMatrixFromTranslation:(CGPoint)translation zoomFactor:(CGFloat)zoomFactor;

@end

@implementation EucPageTurningView

@synthesize delegate = _delegate;

@synthesize viewDataSource = _viewDataSource;
@synthesize bitmapDataSource = _bitmapDataSource;

@synthesize twoSidedPages = _twoSidedPages;
@synthesize fitTwoPages = _fitTwoPages;
@synthesize oddPagesOnRight = _oddPagesOnRight;
@synthesize zoomHandlingKind = _zoomHandlingKind;

@synthesize zoomMatrix = _zoomMatrix;
@synthesize rightPageFrame = _rightPageFrame;
@synthesize leftPageFrame = _leftPageFrame;

@synthesize shininess = _shininess;

@synthesize constantAttenuationFactor = _constantAttenuationFactor;
@synthesize linearAttenutaionFactor = _linearAttenutaionFactor;

@synthesize lightPosition = _lightPosition;

@synthesize pageAspectRatio = _pageAspectRatio;


- (UIColor *)specularColor
{
    return [UIColor colorWithRed:_specularColor[0] green:_specularColor[1] blue:_specularColor[2] alpha:_specularColor[3]];
}
- (void)setSpecularColor:(UIColor *)color
{
    NSParameterAssert(sizeof(CGFloat) == sizeof(GLfloat));
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    memcpy(_specularColor, components, 4 * sizeof(GLfloat));
    [self setNeedsLayout];
}

- (UIColor *)ambientLightColor
{
    return [UIColor colorWithRed:_ambientLightColor[0] green:_ambientLightColor[1] blue:_ambientLightColor[2] alpha:_ambientLightColor[3]];
}
- (void)setAmbientLightColor:(UIColor *)color
{
    NSParameterAssert(sizeof(CGFloat) == sizeof(GLfloat));
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    memcpy(_ambientLightColor, components, 4 * sizeof(GLfloat));
    [self setNeedsLayout];
}
           
- (UIColor *)diffuseLightColor
{
    return [UIColor colorWithRed:_diffuseLightColor[0] green:_diffuseLightColor[1] blue:_diffuseLightColor[2] alpha:_diffuseLightColor[3]];
}
- (void)setDiffuseLightColor:(UIColor *)color
{
    NSParameterAssert(sizeof(CGFloat) == sizeof(GLfloat));
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    memcpy(_diffuseLightColor, components, 4 * sizeof(GLfloat));
    [self setNeedsLayout];
}

- (void)setAnimating:(BOOL)animating
{
    if(animating) {
        if(!self.isAnimating) {
            // Curtail background tasks to allow smooth animation.
            if([_delegate respondsToSelector:@selector(pageTurningViewWillBeginAnimating:)]) {
                [_delegate pageTurningViewWillBeginAnimating:self];   
            }
            [THBackgroundProcessingMediator curtailBackgroundProcessing];
            super.animating = YES;
        }
    } else {
        if(self.isAnimating) {
            // Allow background tasks again.
            [THBackgroundProcessingMediator allowBackgroundProcessing];
            super.animating = NO;
            if([_delegate respondsToSelector:@selector(pageTurningViewDidEndAnimation:)]) {
                [_delegate pageTurningViewDidEndAnimation:self];   
            }        
        }
    }
}

static void texImage2DPVRTC(GLint level, GLsizei bpp, GLboolean hasAlpha, GLsizei length, const void *pvrtcData)
{
    GLenum format;
    GLsizei size = length * length * bpp / 8;
    if(hasAlpha) {
        format = (bpp == 4) ? GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG : GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG;
    } else {
        format = (bpp == 4) ? GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG : GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG;
    }
    if(size < 32) {
        size = 32;
    }
    glCompressedTexImage2D(GL_TEXTURE_2D, level, format, length, length, 0, size, pvrtcData);
}

- (void)_pageTurningViewInternalInit
{               
    _zoomMatrix = CATransform3DIdentity;
    
    EAGLContext *eaglContext = self.eaglContext;
    [EAGLContext setCurrentContext:eaglContext];
    
    GLfloat white[4] = {1.0f, 1.0f, 1.0f, 1.0f};
    memcpy(_specularColor, white, 4 * sizeof(GLfloat));
    _shininess = 60.0;

    _constantAttenuationFactor = 0.55f;   
    _linearAttenutaionFactor = 0.05f;

    GLfloat dim[4] = {0.2f, 0.2f, 0.2f, 1.0f};
    memcpy(_ambientLightColor, dim, 4 * sizeof(GLfloat));
    memcpy(_diffuseLightColor, white, 4 * sizeof(GLfloat));

    _lightPosition.x = 0.5f;
    _lightPosition.y = 0.25f;
    _lightPosition.z = 1.79f;
        
    // Set up our page triangle strips (page coordinates will be set up in
    // -layoutSubviews, below).
    int triangleStripIndex = 0;
    for(int row = 0; row < Y_VERTEX_COUNT - 1; ++row) {
        if((row % 2) == 0) {
            int i = 0;
            _triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(i, row, X_VERTEX_COUNT);
            for(; i < X_VERTEX_COUNT; ++i) {
                _triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(i, row+1, X_VERTEX_COUNT);
                _triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(i, row, X_VERTEX_COUNT);
            }
            _triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(X_VERTEX_COUNT - 1, row+1, X_VERTEX_COUNT);
            _triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(X_VERTEX_COUNT - 1, row+1, X_VERTEX_COUNT);
        } else {
            int i = X_VERTEX_COUNT - 1;
            _triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(i, row, X_VERTEX_COUNT);
            for(; i >= 0; --i) {
                _triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(i, row+1, X_VERTEX_COUNT);
                _triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(i, row, X_VERTEX_COUNT);
            } 
            _triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(0, row+1, X_VERTEX_COUNT);
            _triangleStripIndices[triangleStripIndex++] = THGLIndexForColumnAndRow(0, row+1, X_VERTEX_COUNT);
        }
    }
    NSParameterAssert(triangleStripIndex == TRIANGLE_STRIP_COUNT);

    glGenBuffers(1, &_triangleStripIndicesBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _triangleStripIndicesBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, TRIANGLE_STRIP_COUNT * sizeof(GLubyte), &_triangleStripIndices, GL_STATIC_DRAW);
        
            
    // Construct the texture coordinate mesh (page meshes constructed in 
    // layoutSubviews.
    THVec2 meshTextureCoordinates[Y_VERTEX_COUNT][X_VERTEX_COUNT];

    GLfloat xStep = (1.0f * 2) / (2 * X_VERTEX_COUNT - 3);
    GLfloat yStep = (1.0f / (Y_VERTEX_COUNT - 1));
    GLfloat baseXCoord = 0.0f;
    GLfloat yCoord = 0.0f;
        
    GLfloat maxX = 1.0f;
    GLfloat maxY = 1.0f;
    
    for(int row = 0; row < Y_VERTEX_COUNT; ++row) {
        GLfloat xCoord = baseXCoord;
        for(int column = 0; column < X_VERTEX_COUNT; ++column) {
            meshTextureCoordinates[row][column].x = MIN(xCoord, maxX);
            meshTextureCoordinates[row][column].y = MIN(yCoord, maxY);
            
            if(xCoord == baseXCoord && (row % 2) == 1) {
                xCoord += xStep * 0.5f;
            } else {
                xCoord += xStep;
            }
        }
        yCoord += yStep;
    }
    
    glGenBuffers(1, &_meshTextureCoordinateBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _meshTextureCoordinateBuffer);
    glBufferData(GL_ARRAY_BUFFER, X_VERTEX_COUNT * Y_VERTEX_COUNT * sizeof(THVec2), &meshTextureCoordinates, GL_STATIC_DRAW);
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"BookEdge" ofType:@"pvrtc"];
    NSData *bookEdge = [[NSData alloc] initWithContentsOfMappedFile:path];
    glGenTextures(1, &_bookEdgeTexture);
    glBindTexture(GL_TEXTURE_2D, _bookEdgeTexture);
    texImage2DPVRTC(0, 4, 0, 512, [bookEdge bytes]);
    [bookEdge release];
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
    NSData *vertexShaderSource = [THEmbeddedResourceManager embeddedResourceWithName:@"euc_page_turning.vsh"];
    GLuint vertexShader = THGLLoadShader(GL_VERTEX_SHADER, vertexShaderSource.bytes, vertexShaderSource.length);
    
    NSData *fragmentShaderSource = [THEmbeddedResourceManager embeddedResourceWithName:@"euc_page_turning.fsh"];
    GLuint fragmentShader = THGLLoadShader(GL_FRAGMENT_SHADER, fragmentShaderSource.bytes, fragmentShaderSource.length);

    _program = glCreateProgram();
        
    glAttachShader(_program, vertexShader);
    glAttachShader(_program, fragmentShader);
    glLinkProgram(_program);
    
    GLint linked;
    glGetProgramiv(_program, GL_LINK_STATUS, &linked);
    if(!linked) {
        GLint infoLength;
        glGetProgramiv(_program, GL_INFO_LOG_LENGTH, &infoLength);
        
        if(infoLength) {
            char *infoLog = malloc(infoLength);
            glGetProgramInfoLog(_program, infoLength, NULL, infoLog);
            THLog(@"Error linking shaders into program: \"%s\"", infoLog);
            free(infoLog);
        } else {
            THLog(@"Unknown error linking shaders into program");
        }
        glDeleteProgram(_program);
        _program = 0;
    }
    
    glUseProgram(_program);
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    glEnable(GL_CULL_FACE);
    
    _textureUploadContext = [[EAGLContext alloc] initWithAPI:[eaglContext API] sharegroup:[eaglContext sharegroup]];
    
    _animatedTurnData = [[NSData alloc] initWithContentsOfMappedFile:[[NSBundle mainBundle] pathForResource:@"animatedBookTurnVertices" ofType:@"vertexData"]];
    _animatedTurnFrameCount = _animatedTurnData.length / (X_VERTEX_COUNT * Y_VERTEX_COUNT * sizeof(THVec3) * 2);
    
    _reverseAnimatedTurnData = [[NSData alloc] initWithContentsOfMappedFile:[[NSBundle mainBundle] pathForResource:@"reverseAnimatedBookTurnVertices" ofType:@"vertexData"]];
    _reverseAnimatedTurnFrameCount = _reverseAnimatedTurnData.length / (X_VERTEX_COUNT * Y_VERTEX_COUNT * sizeof(THVec3) * 2);

    self.multipleTouchEnabled = YES;
    //self.exclusiveTouch = YES;
    self.opaque = YES;
    self.userInteractionEnabled = YES;
    //tempFile = fopen("/tmp/vertexdata", "w");
    
    for(NSUInteger i = 0; i < 4; ++i) {
        _pageContentsInformation[i].pageIndex = NSUIntegerMax;
    }
}

- (id)initWithFrame:(CGRect)frame
{
    if((self = [super initWithFrame:frame])) {
        [self _pageTurningViewInternalInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)coder 
{
    if((self = [super initWithCoder:coder])) {
        [self _pageTurningViewInternalInit];
    }
    return self;
}

- (void)dealloc
{
    [_textureUploadContext release];
    
    [EAGLContext setCurrentContext:self.eaglContext];
    
    if(_meshTextureCoordinateBuffer) {
        glDeleteBuffers(1, &_meshTextureCoordinateBuffer);
    }
    
    if(_triangleStripIndicesBuffer) {
        glDeleteBuffers(1, &_triangleStripIndicesBuffer);
    }
    
    for(int i = 0; i < 7; ++i) {
        [_pageContentsInformation[i].view release];
        if(_pageContentsInformation[i].texture) {
            glDeleteTextures(1, &(_pageContentsInformation[i].texture));
        }
    }    
    
    if(_program) {
        glDeleteProgram(_program);
    }
    
    [_animatedTurnData release];
    [_reverseAnimatedTurnData release];

    [_accessibilityElements release];
    [_nextPageTapZone release];
    
    [super dealloc];
}

- (void)_layoutPages
{
    CGSize size = self.bounds.size;
    if(!CGSizeEqualToSize(size, _lastLayoutBoundsSize)) {
        [self willChangeValueForKey:@"zoomMatrix"];
        [self willChangeValueForKey:@"rightPageFrame"];
        [self willChangeValueForKey:@"leftPageFrame"];
        
        if(size.width < size.height) {
            _viewportLogicalSize.width = 4.0f;
            _viewportLogicalSize.height = (size.height / size.width) * _viewportLogicalSize.width;
        } else {
            // Landscape.
            _viewportLogicalSize.height = 4.0f;
            _viewportLogicalSize.width = (size.width / size.height) * _viewportLogicalSize.height;
        }
        
        CGFloat scaleFactor;
        if([self respondsToSelector:@selector(contentScaleFactor)]) {
            scaleFactor = self.contentScaleFactor;
        } else {
            scaleFactor = 1.0f;
        }        
        CGFloat pixelViewportDimension = (size.width * scaleFactor) / _viewportLogicalSize.width;
        
        _viewportToBoundsPointsTransform = CGAffineTransformMakeScale(size.width /_viewportLogicalSize.width, 
                                                                      size.height /_viewportLogicalSize.height);
        
        // Construct a hex-mesh of triangles:
        CGFloat aspectRatio = _pageAspectRatio;
        if(aspectRatio == 0.0f) {
            if(!_fitTwoPages || size.width < size.height) {
                aspectRatio = size.width / size.height;
            } else {
                // If we're landscape, and in fit-two mode, use the portrait 
                // aspect for pages.
                aspectRatio = size.height / size.width;
            }
        }
        
        CGFloat availableWidth;
        if(_fitTwoPages) {
            availableWidth = _viewportLogicalSize.width * 0.5f;
        } else {
            availableWidth = _viewportLogicalSize.width;
        }
        
        _pageLogicalSize.height = _viewportLogicalSize.height;
        _pageLogicalSize.width =  _pageLogicalSize.height * aspectRatio;
        if(_pageLogicalSize.width > availableWidth) {
            _pageLogicalSize.width = availableWidth;
            _pageLogicalSize.height = _pageLogicalSize.width / aspectRatio;
        }        
        
        // We make sure the height and width are integral pixel sizes, and
        // divisble by two in pixels so that they can lie in an integral
        // rect in the centre of the screen.
        _pageLogicalSize.width = (floorf(_pageLogicalSize.width * pixelViewportDimension * 0.5) * 2) / pixelViewportDimension;
        _pageLogicalSize.height = (floorf(_pageLogicalSize.height * pixelViewportDimension * 0.5) * 2) / pixelViewportDimension;
        
        GLfloat xStep = ((GLfloat)_pageLogicalSize.width * 2) / (2 * X_VERTEX_COUNT - 3);
        GLfloat yStep = ((GLfloat)_pageLogicalSize.height / (Y_VERTEX_COUNT - 1));
        
        if(_fitTwoPages) {
            _rightPageTransform = CATransform3DMakeTranslation(_viewportLogicalSize.width * 0.5f, 
                                                               (_viewportLogicalSize.height - _pageLogicalSize.height) * 0.5f,
                                                               0.0);
        } else {
            _rightPageTransform = CATransform3DMakeTranslation((_viewportLogicalSize.width - _pageLogicalSize.width) * 0.5f, 
                                                               (_viewportLogicalSize.height - _pageLogicalSize.height) * 0.5f,
                                                               0.0);
        }
        
        _rightPageRect = CGRectApplyAffineTransform(CGRectMake(0, 0, _pageLogicalSize.width, _pageLogicalSize.height),
                                                    CATransform3DGetAffineTransform(_rightPageTransform));
        _leftPageRect = _rightPageRect;
        _leftPageRect.origin.x -= _rightPageRect.size.width;
        
        self.rightPageFrame = CGRectApplyAffineTransform(_rightPageRect, _viewportToBoundsPointsTransform);
        self.leftPageFrame = CGRectApplyAffineTransform(_leftPageRect, _viewportToBoundsPointsTransform);
        
        GLfloat maxX = _pageLogicalSize.width;
        GLfloat maxY = _pageLogicalSize.height;
        
        GLfloat yCoord = 0.0f;
        for(int row = 0; row < Y_VERTEX_COUNT; ++row) {
            GLfloat xCoord = 0.0f;
            for(int column = 0; column < X_VERTEX_COUNT; ++column) {
                _stablePageVertices[row][column].x = MIN(xCoord, maxX);
                _stablePageVertices[row][column].y = MIN(yCoord, maxY);
                // z is already 0.
                
                if(xCoord == 0.0f && (row % 2) == 1) {
                    xCoord += xStep * 0.5f;
                } else {
                    xCoord += xStep;
                }
            }
            yCoord += yStep;
        }
        
        for(int row = 0; row < Y_VERTEX_COUNT; ++row) {
            for(int column = 0; column < X_VERTEX_COUNT; ++column) {
                // x and y are already 0.
                _stablePageVertexNormals[row][column].z = -1;
            }
        }
        
        memcpy(_pageVertices, _stablePageVertices, sizeof(_stablePageVertices));
        memcpy(_oldPageVertices, _stablePageVertices, sizeof(_stablePageVertices));
        
        _leftPageVisible = _rightPageRect.origin.x > 0.0f;
        
        [self _setupConstraints];
        
        [super layoutSubviews];
        
        UIView *view = [_pageContentsInformation[3].view retain];
        if(!view) {
            [_pageContentsInformation[2].view retain];
        }
        NSUInteger pageIndex = _pageContentsInformation[3].pageIndex;
        if(pageIndex == NSUIntegerMax) {
            pageIndex = _pageContentsInformation[2].pageIndex;
        }
        
        [EAGLContext setCurrentContext:self.eaglContext];
        for(int i = 0; i < 7; ++i) {
            [_pageContentsInformation[i].view release];
            _pageContentsInformation[i].view = nil;
            if(_pageContentsInformation[i].texture) {
                glDeleteTextures(1, &(_pageContentsInformation[i].texture));
                _pageContentsInformation[i].texture = 0;
            }
            _pageContentsInformation[i].pageIndex = NSUIntegerMax;
        }    
        
        if(view) {
            [self setCurrentPageView:view];
            [view release];
        } else if(pageIndex != NSUIntegerMax) {
            [self turnToPageAtIndex:pageIndex animated:NO];
        }
        
        [self _setZoomMatrixFromTranslation:CGPointZero zoomFactor:1.0f];
        
        [self didChangeValueForKey:@"leftPageFrame"];
        [self didChangeValueForKey:@"rightPageFrame"];
        [self didChangeValueForKey:@"zoomMatrix"];
        
        _lastLayoutBoundsSize = size;
        
        [self setNeedsDraw];
    }
}    

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    [self _layoutPages];
}

- (void)layoutSubviews
{    
    [self _layoutPages];
    [super layoutSubviews];
}

- (void)setPageAspectRatio:(CGFloat)pageAspectRatio
{
    if(_pageAspectRatio != pageAspectRatio) {
        _pageAspectRatio = pageAspectRatio;
        [self _layoutPages];
    }
}

- (UIImage *)screenshot
{
    CGRect bounds = self.bounds;
    
    CFIndex capacity = _backingWidth * _backingHeight * 4;
    CFMutableDataRef newBitmapData = CFDataCreateMutable(kCFAllocatorDefault, capacity);
    CFDataIncreaseLength(newBitmapData, capacity);
    
    _atRenderScreenshotBuffer = CFDataGetMutableBytePtr(newBitmapData);
    
    [self drawView];
    
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData(newBitmapData);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef newImageRef = CGImageCreate(_backingWidth, _backingHeight,
                                           8, 32, 4 * _backingWidth, 
                                           colorSpace, 
                                           kCGBitmapByteOrderDefault | kCGImageAlphaLast, 
                                           dataProvider, NULL, YES, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    CGColorSpaceRelease(colorSpace);
    
    CGFloat scaleFactor;
    if([self respondsToSelector:@selector(contentScaleFactor)]) {
        scaleFactor = self.contentScaleFactor;
    } else {
        scaleFactor = 1.0f;
    }
        
    // The image is upside-down and back-to-front if we use it directly...
    if(scaleFactor != 1.0f) {
        UIGraphicsBeginImageContextWithOptions(bounds.size, NO, scaleFactor);
    } else {
        UIGraphicsBeginImageContext(bounds.size);
    }
    CGContextRef cgContext = UIGraphicsGetCurrentContext();
    CGContextDrawImage(cgContext, bounds, newImageRef);    
    UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRelease(newImageRef);
    CFRelease(newBitmapData);
    _atRenderScreenshotBuffer = nil;
    return ret;
}

- (void)_createTextureIn:(GLuint *)textureRef fromRGBABitmapContext:(CGContextRef)context
{
    size_t contextWidth = CGBitmapContextGetWidth(context);
    size_t contextHeight = CGBitmapContextGetHeight(context);
    
    [EAGLContext setCurrentContext:_textureUploadContext];
    
    CGContextRef textureContext = NULL;
    void *textureData;
    BOOL dataIsNonContiguous = CGBitmapContextGetBytesPerRow(context) != contextWidth * 4;
    if(dataIsNonContiguous || (textureData = CGBitmapContextGetData(context)) == NULL) {
        // We need to generate contiguous data to upload, and we need to be
        // able to access the context's backing data.
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        textureData = malloc(contextWidth * contextHeight * 4);
        textureContext = CGBitmapContextCreate(NULL, contextWidth, contextHeight, 8, contextWidth * 4, 
                                               colorSpace, kCGImageAlphaPremultipliedLast);
        CGContextSetBlendMode(textureContext, kCGBlendModeCopy);
        
        CGImageRef image = CGBitmapContextCreateImage(context);
        CGContextDrawImage(textureContext, CGRectMake(0.0f, 0.0f, contextWidth, contextHeight), image);
        CGImageRelease(image);
        CGColorSpaceRelease(colorSpace);
    }
    
    if(!*textureRef) { 
        glGenTextures(1, textureRef);
    }
    glBindTexture(GL_TEXTURE_2D, *textureRef); 

    glPixelStorei (GL_UNPACK_ALIGNMENT, 1);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, contextWidth, contextHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);    
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);   
    
    if(textureContext) {
        CGContextRelease(textureContext);
        free(textureData);
    }
    
    THLog(@"Created Texture of size (%ld, %ld)", (long)contextWidth, (long)contextHeight);
}

- (void)_createTextureIn:(GLuint *)textureRef from:(id)viewOrImage invertingLuminance:(BOOL)invertingLuminance
{   
    CGFloat scaleFactor = 1.0f;
    CGSize scaledSize, rawSize;
    if([viewOrImage isKindOfClass:[UIView class]]) {
        UIView *view = (UIView *)viewOrImage;
        rawSize = view.bounds.size;
        if([view respondsToSelector:@selector(contentScaleFactor)]) {
            scaleFactor = view.contentScaleFactor;
        }
    } else {
        UIImage *image = (UIImage *)viewOrImage;
        rawSize = [image size];
        if([image respondsToSelector:@selector(scale)]) {
            scaleFactor = image.scale;
        }        
    }
    
    if(scaleFactor != 1.0f) {
        scaledSize.width = rawSize.width * scaleFactor;
        scaledSize.height = rawSize.height * scaleFactor;
    } else {
        scaledSize = rawSize;
    }

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Despite what the slightly misleading docs say, if we don't allocate our
    // own texturedata, CGBitmapContextGetData can return NULL!
    size_t bufferLength = scaledSize.width * scaledSize.height * 4;
    void *textureData = malloc(bufferLength);

    CGContextRef textureContext = CGBitmapContextCreate(textureData, scaledSize.width, scaledSize.height, 8, scaledSize.width * 4, 
                                                        colorSpace, kCGImageAlphaPremultipliedLast);
    if([viewOrImage isKindOfClass:[UIView class]]) {
        uint32_t pattern = 0xFFFFFFFF;
        memset_pattern4(textureData, &pattern, bufferLength);

        CGContextSetFillColorSpace(textureContext, colorSpace);
        CGContextSetStrokeColorSpace(textureContext, colorSpace);
        
        if(scaleFactor != 1.0f) {
            CGContextScaleCTM(textureContext, scaleFactor, scaleFactor);   
        }
        
        CGContextScaleCTM(textureContext, 1.0f, -1.0f);
        CGContextTranslateCTM(textureContext, 0, -rawSize.height);
        
        UIView *view = (UIView *)viewOrImage;
        if([view respondsToSelector:@selector(drawRect:inContext:)] && !view.layer.sublayers) {
            [(UIView<THUIViewThreadSafeDrawing> *)view drawRect:CGRectMake(0, 0, rawSize.width, rawSize.height)
                                                      inContext:textureContext];
        } else {
            [view.layer renderInContext:textureContext];
        }
    } else {
        CGContextSetBlendMode(textureContext, kCGBlendModeCopy);
        CGContextDrawImage(textureContext, CGRectMake(0, 0, scaledSize.width, scaledSize.height), ((UIImage *)viewOrImage).CGImage);
    }
        
    if(invertingLuminance) {
        size_t elements = bufferLength / 4;
        for(size_t i = 0; i < elements; ++i) {
            uint32_t pixel = ((uint32_t *)textureData)[i];
            
            uint32_t blue =  (pixel & 0x00ff0000) >> 16;
            uint32_t green = (pixel & 0x0000ff00) >> 8;
            uint32_t red =   (pixel & 0x000000ff);
            
            CGFloat total = ((CGFloat)red * 0.299 + (CGFloat)green * 0.587 + (CGFloat)blue * 0.114) / 255.0;

            if(total <= 0.0f) {
                pixel = 0xffffffff;
            } else if(total >= 1.0f) {
                pixel = 0xff000000;
            } else {
                CGFloat scale = ((1.0 - total) / total);
                pixel = 0xff000000;
                pixel |= ((uint32_t)((CGFloat)blue * scale)) << 16;
                pixel |= ((uint32_t)((CGFloat)green * scale)) << 8;
                pixel |= ((uint32_t)((CGFloat)red * scale));
            }
            
            ((uint32_t *)textureData)[i] = pixel;
        }
    }
    
    CGColorSpaceRelease(colorSpace);
    
    [self _createTextureIn:textureRef fromRGBABitmapContext:textureContext];

    CGContextRelease(textureContext);
    free(textureData);
    
    THLog(@"Created Texture of scaled size (%f, %f) from point size (%f, %f)", scaledSize.width, scaledSize.height, rawSize.width, rawSize.height);
}

- (void)_createTextureIn:(GLuint *)textureRef from:(id)viewOrImage
{
    return [self _createTextureIn:textureRef from:viewOrImage invertingLuminance:NO];
}

- (void)setPageTexture:(UIImage *)pageTexture isDark:(BOOL)isDark
{
    [self _createTextureIn:&_blankPageTexture 
                      from:pageTexture
        invertingLuminance:isDark];
    _pageTextureIsDark = isDark;
}

- (void)_setView:(UIView *)view forInternalPageOffsetPage:(int)page
{
    if(_pageContentsInformation[page].view != view) {
        [_pageContentsInformation[page].view release];
        if(view) {
            [self _createTextureIn:&_pageContentsInformation[page].texture
                              from:view];
        } else {
            [EAGLContext setCurrentContext:self.eaglContext];
            glDeleteTextures(1, &_pageContentsInformation[page].texture);
            _pageContentsInformation[page].texture = 0;
        }
        _pageContentsInformation[page].view = [view retain];
    }
}

- (UIView *)currentPageView
{
    return _pageContentsInformation[3].view;
}

- (void)setCurrentPageView:(UIView *)newCurrentView;
{
    if(newCurrentView != _pageContentsInformation[3].view) {
        if(!_twoSidedPages) {
            [self _setView:[_viewDataSource pageTurningView:self previousViewForView:newCurrentView] forInternalPageOffsetPage:1];
            [self _setView:newCurrentView forInternalPageOffsetPage:3];
            [self _setView:[_viewDataSource pageTurningView:self nextViewForView:newCurrentView] forInternalPageOffsetPage:5];
        } else {
            [self _setView:[_viewDataSource pageTurningView:self previousViewForView:newCurrentView] forInternalPageOffsetPage:2];
            [self _setView:[_viewDataSource pageTurningView:self previousViewForView:_pageContentsInformation[2].view] forInternalPageOffsetPage:1];
            [self _setView:[_viewDataSource pageTurningView:self previousViewForView:_pageContentsInformation[1].view] forInternalPageOffsetPage:0];
            [self _setView:newCurrentView forInternalPageOffsetPage:3];
            [self _setView:[_viewDataSource pageTurningView:self nextViewForView:_pageContentsInformation[3].view] forInternalPageOffsetPage:4];
            [self _setView:[_viewDataSource pageTurningView:self nextViewForView:_pageContentsInformation[4].view] forInternalPageOffsetPage:5];
        }
    }
    _rightFlatPageIndex = 3;
}

- (NSArray *)pageViews
{
    NSMutableArray *views = [[NSMutableArray alloc] initWithCapacity:6];
    for(NSUInteger i = 0; i < 7; ++i) {
        UIView *view = _pageContentsInformation[i].view;
        if(view) {
            [views addObject:view];
        }
    }
    return views;
}

- (void)turnToPageView:(UIView *)newCurrentView forwards:(BOOL)forwards pageCount:(NSUInteger)pageCount onLeft:(BOOL)onLeft
{
    NSInteger internalPageOffset = 3;
    if(_twoSidedPages && onLeft) {
        internalPageOffset = 2;
    }
    if(newCurrentView != _pageContentsInformation[internalPageOffset].view) {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];

        NSInteger internalPageOffsetForNewViewBeforeTurn;
        if(forwards) {
            internalPageOffsetForNewViewBeforeTurn = 5;
            if(_twoSidedPages && onLeft) {
                internalPageOffsetForNewViewBeforeTurn = 4;
            }
        } else {
            internalPageOffsetForNewViewBeforeTurn = 1;
            if(_twoSidedPages && onLeft) {
                internalPageOffsetForNewViewBeforeTurn = 0;
            }            
        }
        
        [self _setView:newCurrentView forInternalPageOffsetPage:internalPageOffsetForNewViewBeforeTurn];
        if(_twoSidedPages) {
            if(onLeft) {
                [self _setView:[_viewDataSource pageTurningView:self nextViewForView:newCurrentView]
     forInternalPageOffsetPage:internalPageOffsetForNewViewBeforeTurn + 1];
            } else {
                [self _setView:[_viewDataSource pageTurningView:self previousViewForView:newCurrentView]
     forInternalPageOffsetPage:internalPageOffsetForNewViewBeforeTurn - 1];
            }
        }
        
        _isTurningAutomatically = YES;
        _automaticTurnIsForwards = forwards;
        if(forwards) {
            _rightFlatPageIndex = 5;
            _automaticTurnFrame = 0;
        } else {
            _rightFlatPageIndex = 3;
            _automaticTurnFrame = 0;
        }
        
        CGFloat percentage = (CGFloat)pageCount / 512.0f;
        if(pageCount == 1) {
            percentage = 0;
        } else if(percentage > 1.0f) {
            percentage = 1.0f;
        } else {
            percentage = powf(percentage, 0.7f);
        }
        for(int row = 0; row < Y_VERTEX_COUNT; ++row) {
            GLfloat yCoord = (GLfloat)row / (GLfloat)Y_VERTEX_COUNT-1;
            _pageEdgeTextureCoordinates[row][0].x = 0.5f + percentage * 0.5f;
            _pageEdgeTextureCoordinates[row][0].y = yCoord;
            _pageEdgeTextureCoordinates[row][1].x = 0.5f - percentage * 0.5f;
            _pageEdgeTextureCoordinates[row][1].y = yCoord;
        }                
        
        _automaticTurnPercentage = percentage;
        
        self.animating = YES;
    }
}

- (void)refreshView:(UIView *)view
{
    for(int i = 0; i < 7; ++i) {
        if(view == _pageContentsInformation[i].view) {
            [self _createTextureIn:&_pageContentsInformation[i].texture
                              from:view];
            break;
        }
    }
}

- (NSUInteger)leftPageIndex 
{
    return _pageContentsInformation[2].pageIndex;
}

- (NSUInteger)rightPageIndex 
{
    return _pageContentsInformation[3].pageIndex;
}

- (void)_setupBitmapPage:(NSUInteger)newPageIndex 
   forInternalPageOffset:(NSUInteger)pageOffset
                 minSize:(CGSize)minSize
{
    THLog(@"requesting Texture of size (%f, %f)", (long)minSize.width, (long)minSize.height);
    
    CGRect thisPageRect = [_bitmapDataSource pageTurningView:self 
                                   contentRectForPageAtIndex:newPageIndex];
    if(!CGRectIsEmpty(thisPageRect)) {
        CGContextRef thisPageBitmap;
        if([_bitmapDataSource respondsToSelector:@selector(pageTurningView:RGBABitmapContextForPageAtIndex:fromRect:minSize:getContext:)]) {
            id context = nil;
            thisPageBitmap = [_bitmapDataSource pageTurningView:self
                                RGBABitmapContextForPageAtIndex:newPageIndex
                                                       fromRect:thisPageRect
                                                        minSize:minSize
                                                     getContext:&context];
            [[context retain] autorelease];
        } else {
            thisPageBitmap = [_bitmapDataSource pageTurningView:self
                                RGBABitmapContextForPageAtIndex:newPageIndex
                                                       fromRect:thisPageRect
                                                        minSize:minSize];
        }
        
        [self _createTextureIn:&_pageContentsInformation[pageOffset].texture
         fromRGBABitmapContext:thisPageBitmap];
        _pageContentsInformation[pageOffset].pageIndex = newPageIndex; 
    } else {
        _pageContentsInformation[pageOffset].pageIndex = NSUIntegerMax; 
        if(_pageContentsInformation[pageOffset].texture) {
            [EAGLContext setCurrentContext:self.eaglContext];
            glDeleteTextures(1, &_pageContentsInformation[pageOffset].texture);
            _pageContentsInformation[pageOffset].texture = 0;
        }
    }    
}

- (void)_setupBitmapPage:(NSUInteger)newPageIndex 
   forInternalPageOffset:(NSUInteger)pageOffset
{
    CGSize minSize = _rightPageFrame.size;
    if([self respondsToSelector:@selector(contentScaleFactor)]) {
        CGFloat scaleFactor = self.contentScaleFactor;
        minSize.width *= scaleFactor;
        minSize.height *= scaleFactor;
    }
    minSize.width = roundf(minSize.width);
    minSize.height = roundf(minSize.height);
    [self _setupBitmapPage:newPageIndex forInternalPageOffset:pageOffset minSize:minSize];
}

- (void)turnToPageAtIndex:(NSUInteger)newPageIndex animated:(BOOL)animated
{
    if(_pageContentsInformation[2].pageIndex != newPageIndex &&
       _pageContentsInformation[3].pageIndex != newPageIndex) {
        
        BOOL forwards = newPageIndex > _pageContentsInformation[3].pageIndex;
        
        NSUInteger rightPageIndex = newPageIndex;
        if(_twoSidedPages) {
            if(_oddPagesOnRight) {
                if((rightPageIndex % 2) == 0) {
                    rightPageIndex++;
                }                
            } else {
                if((rightPageIndex % 2) == 1) {
                    rightPageIndex++;
                }            
            }
        }
        
        if(animated) {
            [[UIApplication sharedApplication] beginIgnoringInteractionEvents];

            [self _setupBitmapPage:rightPageIndex forInternalPageOffset:forwards ? 5 : 1];
            [self _setupBitmapPage:rightPageIndex - 1 forInternalPageOffset:forwards ? 4 : 0];
            
            _isTurningAutomatically = YES;
            _automaticTurnIsForwards = forwards;
            if(forwards) {
                _rightFlatPageIndex = 5;
                _automaticTurnFrame = 0;
            } else {
                _rightFlatPageIndex = 3;
                _automaticTurnFrame = 0;
            }
            
            NSUInteger pageCount;
            if(forwards) {
                pageCount = rightPageIndex - _pageContentsInformation[3].pageIndex;
            } else {
                if(_twoSidedPages) {
                    pageCount = _pageContentsInformation[2].pageIndex - rightPageIndex;
                } else {
                    pageCount = _pageContentsInformation[3].pageIndex - rightPageIndex;
                }
            }
            
            if(_twoSidedPages) {
                pageCount /= 2;
            }
            
            CGFloat percentage = (CGFloat)pageCount / 512.0f;
            if(pageCount == 1) {
                percentage = 0;
            } else if(percentage > 1.0f) {
                percentage = 1.0f;
            } else {
                percentage = powf(percentage, 0.7f);
            }
            for(int row = 0; row < Y_VERTEX_COUNT; ++row) {
                GLfloat yCoord = (GLfloat)row / (GLfloat)Y_VERTEX_COUNT-1;
                _pageEdgeTextureCoordinates[row][0].x = 0.5f + percentage * 0.5f;
                _pageEdgeTextureCoordinates[row][0].y = yCoord;
                _pageEdgeTextureCoordinates[row][1].x = 0.5f - percentage * 0.5f;
                _pageEdgeTextureCoordinates[row][1].y = yCoord;
            }                
            
            _automaticTurnPercentage = percentage;
            
            self.animating = YES;
        } else {
            [self _setupBitmapPage:rightPageIndex forInternalPageOffset:3];
            if(_twoSidedPages) {
                [self _setupBitmapPage:rightPageIndex - 1 forInternalPageOffset:2];
            }
            
            _rightFlatPageIndex = 3;
            
            _recacheFlags[1] = YES;
            _recacheFlags[5] = YES; 
            if(_twoSidedPages) {
                _recacheFlags[0] = YES;
                _recacheFlags[4] = YES; 
            }
            [self _cacheNonVisiblePages];
            
            [self setNeedsDraw];
        }
    }    
}

- (void)refreshPageAtIndex:(NSUInteger)pageIndex {
    for(NSUInteger i = 0; i < sizeof(_pageContentsInformation) / sizeof(EucPageTurningPageContentsInformation); ++i) {
        if(pageIndex == _pageContentsInformation[i].pageIndex) {
            [self _setupBitmapPage:pageIndex forInternalPageOffset:i];
            break;
        }
    }
}

static THVec3 triangleNormal(THVec3 left, THVec3 middle, THVec3 right)
{
    THVec3 leftVector = THVec3Subtract(right, middle);
    THVec3 rightVector = THVec3Subtract(right, left);

    return THVec3Normalize(THVec3CrossProduct(leftVector, rightVector));
}

- (void)_addConstraintFrom:(GLubyte)indexA to:(GLubyte)indexB
{
    BOOL shouldAdd = YES;
    for(int i = 0; shouldAdd && i < _constraintCount; ++i) {
        if((_constraints[i].particleAIndex == indexA && _constraints[i].particleBIndex == indexB) ||
           (_constraints[i].particleAIndex == indexB && _constraints[i].particleBIndex == indexA)) {
            shouldAdd = NO;
        }
    }
    if(shouldAdd) {
        THVec3 *flatPageVertices = (THVec3 *)_pageVertices;
        _constraints[_constraintCount].particleAIndex = indexA;
        _constraints[_constraintCount].particleBIndex = indexB;
        _constraints[_constraintCount].lengthSquared = powf(THVec3Magnitude(THVec3Subtract(flatPageVertices[indexA], flatPageVertices[indexB])), 2);
        
        ++_constraintCount;
    }
}

- (void)_setupConstraints
{
    _constraintCount = 0;
    
    // Adding the constaints in reverse-order seems to produce nicer turning
    // (perhaps because the eye is less drtawn to the systematic error that is 
    // introdiced by evaluating the constraints in-order during the animation if
    // it's at the bottom of the page?)
    for(int i = TRIANGLE_STRIP_COUNT - 3; i >= 0; --i) {
        GLubyte leftVertexIndex;
        GLubyte middleVertexIndex;
        GLubyte rightVertexIndex;
        if((i % 2) == 0) {
            leftVertexIndex = _triangleStripIndices[i];
            middleVertexIndex = _triangleStripIndices[i + 1];
            rightVertexIndex = _triangleStripIndices[i + 2];
        } else {
            leftVertexIndex = _triangleStripIndices[i + 1];
            middleVertexIndex = _triangleStripIndices[i];
            rightVertexIndex = _triangleStripIndices[i + 2];            
        }
        if(leftVertexIndex != rightVertexIndex &&
           leftVertexIndex != middleVertexIndex &&
           middleVertexIndex != rightVertexIndex) {
            [self _addConstraintFrom:leftVertexIndex to:middleVertexIndex];
            [self _addConstraintFrom:middleVertexIndex to:rightVertexIndex];
            [self _addConstraintFrom:rightVertexIndex to:leftVertexIndex];
        }
    }
    for(int i = 0; i < Y_VERTEX_COUNT; ++i) {
        [self _addConstraintFrom:THGLIndexForColumnAndRow(0, i, X_VERTEX_COUNT) to:THGLIndexForColumnAndRow(X_VERTEX_COUNT - 1, i, X_VERTEX_COUNT)];
    }    
    for(int i = 0; i < X_VERTEX_COUNT; ++i) {
        [self _addConstraintFrom:THGLIndexForColumnAndRow(i, 0, X_VERTEX_COUNT) to:THGLIndexForColumnAndRow(i, Y_VERTEX_COUNT - 1, X_VERTEX_COUNT)];
    }
    
    //[self _addConstraintFrom:THGLIndexForColumnAndRow(0, 0, X_VERTEX_COUNT) to:THGLIndexForColumnAndRow(X_VERTEX_COUNT - 1, Y_VERTEX_COUNT - 1, X_VERTEX_COUNT)];
    //[self _addConstraintFrom:THGLIndexForColumnAndRow(X_VERTEX_COUNT - 1, 0, X_VERTEX_COUNT) to:THGLIndexForColumnAndRow(0, Y_VERTEX_COUNT - 1, X_VERTEX_COUNT)];  
    
    NSParameterAssert(_constraintCount == CONSTRAINT_COUNT);
}

- (void)_calculateVertexNormals
{
    // Run through triangle strip, as it would be drawn.
    // Start with a 0 normal for each vertex.
    // Calculate the normal for each non-degenerate triangle, 
    // and add it to the normal for each vertex of the triangle.
    // After all the normals have been accunulated, 
    // run through the vertex normals normalising them.
    memset(_pageVertexNormals, 0, sizeof(_pageVertexNormals));
    
    THVec3 *flatPageVertexNormals = (THVec3 *)_pageVertexNormals;
    for(int i = 0; i < TRIANGLE_STRIP_COUNT - 2; ++i) {
        GLubyte leftVertexIndex;
        GLubyte middleVertexIndex;
        GLubyte rightVertexIndex;
        if((i % 2) != 0) {
            leftVertexIndex = _triangleStripIndices[i];
            middleVertexIndex = _triangleStripIndices[i + 1];
            rightVertexIndex = _triangleStripIndices[i + 2];
        } else {
            leftVertexIndex = _triangleStripIndices[i + 1];
            middleVertexIndex = _triangleStripIndices[i];
            rightVertexIndex = _triangleStripIndices[i + 2];            
        }
        if(leftVertexIndex != rightVertexIndex &&
           leftVertexIndex != middleVertexIndex &&
           middleVertexIndex != rightVertexIndex) {
            THVec3 leftVertex = ((THVec3 *)_pageVertices)[leftVertexIndex];
            THVec3 middleVertex = ((THVec3 *)_pageVertices)[middleVertexIndex];
            THVec3 rightVertex = ((THVec3 *)_pageVertices)[rightVertexIndex];
            
            THVec3 normal = triangleNormal(leftVertex, middleVertex, rightVertex);
            flatPageVertexNormals[leftVertexIndex] = 
                            THVec3Add(flatPageVertexNormals[leftVertexIndex], normal);
            flatPageVertexNormals[middleVertexIndex] = 
                            THVec3Add(flatPageVertexNormals[middleVertexIndex], normal);
            flatPageVertexNormals[rightVertexIndex] = 
                            THVec3Add(flatPageVertexNormals[rightVertexIndex], normal);
        }
    }
    for(int i = 0; i < X_VERTEX_COUNT * Y_VERTEX_COUNT; ++i) {
        flatPageVertexNormals[i] = THVec3Normalize(flatPageVertexNormals[i]);
    }
}

- (void)_cyclePageContentsInformationForTurnForwards:(BOOL)forwards
{
    if(forwards) {
        EucPageTurningPageContentsInformation tempView0 = _pageContentsInformation[0];
        EucPageTurningPageContentsInformation tempView1 = _pageContentsInformation[1];
        _pageContentsInformation[0] = _pageContentsInformation[2];
        _pageContentsInformation[1] = _pageContentsInformation[3];
        _pageContentsInformation[2] = _pageContentsInformation[4];
        _pageContentsInformation[3] = _pageContentsInformation[5];
        _pageContentsInformation[4] = tempView0;
        _pageContentsInformation[5] = tempView1;
    } else {
        EucPageTurningPageContentsInformation tempView4 = _pageContentsInformation[4];
        EucPageTurningPageContentsInformation tempView5 = _pageContentsInformation[5];
        _pageContentsInformation[4] = _pageContentsInformation[2];
        _pageContentsInformation[5] = _pageContentsInformation[3];
        _pageContentsInformation[2] = _pageContentsInformation[0];
        _pageContentsInformation[3] = _pageContentsInformation[1];
        _pageContentsInformation[0] = tempView4;
        _pageContentsInformation[1] = tempView5;
    }
}

- (void)drawView 
{        
    [super drawView];
        
    BOOL animating = self.isAnimating;
    
    BOOL shouldStopAnimating = !animating;
    if(animating && !_isTurningAutomatically) {
        //[self _accumulateForces]; // Not used - see comments around implementation.
        [self _verlet];
        shouldStopAnimating = [self _satisfyConstraints];
        [self _calculateVertexNormals];
    } 
    
    EAGLContext *eaglContext = self.eaglContext;
    [EAGLContext setCurrentContext:eaglContext];
    
    glBindFramebuffer(GL_FRAMEBUFFER, _viewFramebuffer);
    glViewport(0, 0, _backingWidth, _backingHeight);
    
    
    // Set up model and perspective matrices. We'll mess with the model view
    // matrix a bit more below to position the pages, so this is only what's 
    // necessary to set up the lights.
    CATransform3D modelViewMatrix = CATransform3DMakeRotation((CGFloat)M_PI, 0, 0, 1);
    modelViewMatrix = THCATransform3DLookAt(modelViewMatrix, 
                                            THVec3Make(_viewportLogicalSize.width * 0.5f, _viewportLogicalSize.height * 0.5f, -(_viewportLogicalSize.height * 0.5f) / tanf(FOV_ANGLE * ((float)M_PI / 360.0f))), 
                                            THVec3Make(_viewportLogicalSize.width * 0.5f, _viewportLogicalSize.height * 0.5f, 0.0f), 
                                            THVec3Make(0.0f, 1.0f, 0.0f));
    
    CATransform3D projectionMatrix = CATransform3DIdentity;
    projectionMatrix = THCATransform3DPerspective(projectionMatrix, FOV_ANGLE, (GLfloat)_viewportLogicalSize.width / (GLfloat)_viewportLogicalSize.height, 0.5f, 1000.0f);
    glUniformMatrix4fv(glGetUniformLocation(_program, "uProjectionMatrix"), sizeof(projectionMatrix) / sizeof(GLfloat), GL_FALSE, (GLfloat *)&projectionMatrix);

    // Set up light.
    THVec3 lightPosition = THVec3Make(_viewportLogicalSize.width * _lightPosition.x, 
                                      _viewportLogicalSize.height * _lightPosition.y, 
                                      -MIN(_viewportLogicalSize.width, _viewportLogicalSize.height) * (_lightPosition.z - (_dimQuotient * (_lightPosition.z - 0.3f))));
    lightPosition = THCATransform3DVec3Multiply(modelViewMatrix, lightPosition);
    glUniform3fv(glGetUniformLocation(_program, "uLight.position"), 1, (GLfloat *)&lightPosition);
    
    glUniform4fv(glGetUniformLocation(_program, "uLight.ambientColor"), 1, (GLfloat *)&_ambientLightColor);
    glUniform4fv(glGetUniformLocation(_program, "uLight.diffuseColor"), 1, (GLfloat *)&_diffuseLightColor);

    glUniform2f(glGetUniformLocation(_program, "uLight.attenuationFactors"), 
                _constantAttenuationFactor + (_dimQuotient * (0.9f - 0.55f)), 
                _linearAttenutaionFactor);
    
    // Set up the material.
    glUniform4fv(glGetUniformLocation(_program, "uMaterial.specularColor"), 1, (GLfloat *)&_specularColor);
    glUniform1f(glGetUniformLocation(_program, "uMaterial.shininess"), _shininess);
              
    // Tell the renderer id we're doing white-on-black.
    glUniform1i(glGetUniformLocation(_program, "uInvertContentsLuminance"), _pageTextureIsDark ? 1 : 0);

    glUniform1i(glGetUniformLocation(_program, "uFlipContentsX"), 0);
    glUniform1i(glGetUniformLocation(_program, "uDisableContentsTexture"), 0);

    // Clear the buffer, ready to draw.
    glEnable(GL_DEPTH_TEST);
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // Perform zooming, and finally actually set the model view matrix.
    modelViewMatrix = CATransform3DConcat(_rightPageTransform, modelViewMatrix);
    modelViewMatrix = CATransform3DConcat(modelViewMatrix, _zoomMatrix);
    glUniformMatrix4fv(glGetUniformLocation(_program, "uModelviewMatrix"), sizeof(modelViewMatrix) / sizeof(GLfloat), GL_FALSE, (GLfloat *)&modelViewMatrix);    
    
    CATransform3D normalMatrix = THCATransform3DTranspose(CATransform3DInvert(modelViewMatrix));
    glUniformMatrix4fv(glGetUniformLocation(_program, "uNormalMatrix"), sizeof(normalMatrix) / sizeof(GLfloat), GL_FALSE, (GLfloat *)&normalMatrix);
    
    // Assign GL_TEXTUREs to our samplers (we'll bind the textures before use).    
    glUniform1i(glGetUniformLocation(_program, "sPaperTexture"), 0);
    glUniform1i(glGetUniformLocation(_program, "sContentsTexture"), 1);

    // Enable the array attributes - they'll be set later.    
    
    // Set up to use the unchanging texture coordinates for the mesh.
    glEnableVertexAttribArray(glGetAttribLocation(_program, "aTextureCoordinate"));
    glEnableVertexAttribArray(glGetAttribLocation(_program, "aPosition"));
    glEnableVertexAttribArray(glGetAttribLocation(_program, "aNormal"));

    glBindBuffer(GL_ARRAY_BUFFER, _meshTextureCoordinateBuffer);
    glVertexAttribPointer(glGetAttribLocation(_program, "aTextureCoordinate"), 2, GL_FLOAT, GL_FALSE, 0, 0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    // Set up to draw the flat page.
    glVertexAttribPointer(glGetAttribLocation(_program, "aPosition"), 3, GL_FLOAT, GL_FALSE, 0, _stablePageVertices);
    
    glVertexAttribPointer(glGetAttribLocation(_program, "aNormal"), 3, GL_FLOAT, GL_FALSE, 0, _stablePageVertexNormals);
    
    glUniform1f(glGetUniformLocation(_program, "uContentsBleed"), 1.0f);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _blankPageTexture);
    
    if(_pageContentsInformation[_rightFlatPageIndex].texture) {        
        // Draw the right-hand (or only) flat page.

        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, _pageContentsInformation[_rightFlatPageIndex].texture);    
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _triangleStripIndicesBuffer);
        glDrawElements(GL_TRIANGLE_STRIP, TRIANGLE_STRIP_COUNT, GL_UNSIGNED_BYTE, 0);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }
    
    if(_leftPageVisible) {
        NSInteger leftFlatPageIndex = _rightFlatPageIndex - (shouldStopAnimating ? 1 : 3);
        if(leftFlatPageIndex >= 0 && _twoSidedPages) {
            GLuint texture = _pageContentsInformation[leftFlatPageIndex].texture;
            if(texture) {
                CATransform3D oldModelViewMatrix = modelViewMatrix;
                modelViewMatrix = CATransform3DRotate(modelViewMatrix, (GLfloat)M_PI, 0, 1, 0);
                glUniformMatrix4fv(glGetUniformLocation(_program, "uModelviewMatrix"), sizeof(modelViewMatrix) / sizeof(GLfloat), GL_FALSE, (GLfloat *)&modelViewMatrix);
                CATransform3D oldNormalMatrix = normalMatrix;
                normalMatrix = THCATransform3DTranspose(CATransform3DInvert(modelViewMatrix));
                glUniformMatrix4fv(glGetUniformLocation(_program, "uNormalMatrix"), sizeof(normalMatrix) / sizeof(GLfloat), GL_FALSE, (GLfloat *)&normalMatrix);
                
                if(_twoSidedPages) {
                    glUniform1i(glGetUniformLocation(_program, "uFlipContentsX"), 1);
                } else {
                    glUniform1f(glGetUniformLocation(_program, "uContentsBleed"), 0.2f);
                }
                
                glActiveTexture(GL_TEXTURE1);
                glBindTexture(GL_TEXTURE_2D, texture);
                
                glCullFace(GL_FRONT);
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _triangleStripIndicesBuffer);
                glDrawElements(GL_TRIANGLE_STRIP, TRIANGLE_STRIP_COUNT, GL_UNSIGNED_BYTE, 0);
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
                glCullFace(GL_BACK);

                if(_twoSidedPages) {
                    glUniform1i(glGetUniformLocation(_program, "uFlipContentsX"), 0);
                } else {
                    glUniform1f(glGetUniformLocation(_program, "uContentsBleed"), 1.0f);
                }
                
                modelViewMatrix = oldModelViewMatrix;
                glUniformMatrix4fv(glGetUniformLocation(_program, "uModelviewMatrix"), sizeof(modelViewMatrix) / sizeof(GLfloat), GL_FALSE, (GLfloat *)&modelViewMatrix);
                normalMatrix = oldNormalMatrix;
                glUniformMatrix4fv(glGetUniformLocation(_program, "uNormalMatrix"), sizeof(normalMatrix) / sizeof(GLfloat), GL_FALSE, (GLfloat *)&normalMatrix);
            }
        }
    }
    
    if(!shouldStopAnimating) {
        // If we're animating, we have a curved page to draw on top.
        
        // Clear the depth buffer so that this page wins if it has coordinates 
        // that conincide with the flat page.
        glClear(GL_DEPTH_BUFFER_BIT);
                        
        const THVec3 *pageVertices, *pageVertexNormals;        
        if(!_isTurningAutomatically) {
            pageVertices = (THVec3 *)_pageVertices;
            pageVertexNormals = (THVec3 *)_pageVertexNormals;
            
            //fwrite(pageVertices, sizeof(GLfloatTriplet), X_VERTEX_COUNT * Y_VERTEX_COUNT, tempFile);
            //fwrite(pageVertexNormals, sizeof(GLfloatTriplet), X_VERTEX_COUNT * Y_VERTEX_COUNT, tempFile);
            //fflush(tempFile);
        } else {
            if(!_automaticTurnIsForwards && _automaticTurnFrame == _reverseAnimatedTurnFrameCount) {
                pageVertices = (const THVec3 *)_stablePageVertices;
                pageVertexNormals = (const THVec3 *)_stablePageVertexNormals;
            } else {
                pageVertices = (const THVec3 *)[_automaticTurnIsForwards ? _animatedTurnData : _reverseAnimatedTurnData bytes] + (X_VERTEX_COUNT * Y_VERTEX_COUNT * 2) * _automaticTurnFrame;
                pageVertexNormals = pageVertices + (X_VERTEX_COUNT * Y_VERTEX_COUNT);
            }
        }
        
        glVertexAttribPointer(glGetAttribLocation(_program, "aPosition"), 3, GL_FLOAT, GL_FALSE, 0, pageVertices);
        if(!_isTurningAutomatically && pageVertexNormals != (const THVec3 *)_stablePageVertexNormals) {
            glVertexAttribPointer(glGetAttribLocation(_program, "aNormal"), 3, GL_FLOAT, GL_FALSE, 0, pageVertexNormals);
        } else {
            // The normals in the automatic turn files are acidentally facing
            // backwards.  I should really re-record them.
            // Instead, for the moment, we invert the here.     
            THVec3 invertedPageVertexNormals[X_VERTEX_COUNT * Y_VERTEX_COUNT];
            for(int i = 0; i < X_VERTEX_COUNT * Y_VERTEX_COUNT; ++i) {
                invertedPageVertexNormals[i].x = -(pageVertexNormals)[i].x;
                invertedPageVertexNormals[i].y = -(pageVertexNormals)[i].y;
                invertedPageVertexNormals[i].z = -(pageVertexNormals)[i].z;
            }
            glVertexAttribPointer(glGetAttribLocation(_program, "aNormal"), 3, GL_FLOAT, GL_FALSE, 0, invertedPageVertexNormals);
        }
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, _pageContentsInformation[_rightFlatPageIndex-2].texture);
        
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _triangleStripIndicesBuffer);

        glDrawElements(GL_TRIANGLE_STRIP, TRIANGLE_STRIP_COUNT, GL_UNSIGNED_BYTE, 0);
        
        if(_twoSidedPages) {
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(GL_TEXTURE_2D, _pageContentsInformation[_rightFlatPageIndex-1].texture);
            glUniform1i(glGetUniformLocation(_program, "uFlipContentsX"), 1);
        } else {
            glUniform1f(glGetUniformLocation(_program, "uContentsBleed"), 0.2);
        }
        
        glCullFace(GL_FRONT);
        glDrawElements(GL_TRIANGLE_STRIP, TRIANGLE_STRIP_COUNT, GL_UNSIGNED_BYTE, 0);

        glCullFace(GL_BACK);
        if(_twoSidedPages) {
            glUniform1i(glGetUniformLocation(_program, "uFlipContentsX"), 0);
        } else {
            glUniform1f(glGetUniformLocation(_program, "uContentsBleed"), 1.0);
        }
        
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);


        if(_isTurningAutomatically) {
            if(_automaticTurnPercentage > 0.0f) {
                // Construct and draw the page edge.
                
                THVec3 pageEdge[Y_VERTEX_COUNT][2];
                THVec3 pageEdgeNormals[Y_VERTEX_COUNT * 2] = { {0, 0, 0} };
                int column = X_VERTEX_COUNT - 1;
                for(int row = 0; row < Y_VERTEX_COUNT; ++row) {
                    pageEdge[row][0] = THVec3Add(pageVertices[row * X_VERTEX_COUNT + column] , 
                                                 THVec3Multiply(pageVertexNormals[row * X_VERTEX_COUNT + column], _automaticTurnPercentage));
                    pageEdge[row][1] = pageVertices[row * X_VERTEX_COUNT + column];
                } 
                THVec3 *flatPageEdge = (THVec3 *)pageEdge;
                for(int i = 1; i < Y_VERTEX_COUNT * 2 - 1; ++i) {
                    int leftVertexIndex;
                    int rightVertexIndex;
                    int middleVertexIndex;
                    if((i % 2) != 1) {
                        leftVertexIndex = i - 1;
                        middleVertexIndex = i;
                        rightVertexIndex = i + 1;
                    } else {
                        leftVertexIndex = i + 1;
                        middleVertexIndex = i;
                        rightVertexIndex = i - 1;            
                    }
                    THVec3 leftVertex = flatPageEdge[leftVertexIndex];
                    THVec3 middleVertex = flatPageEdge[middleVertexIndex];
                    THVec3 rightVertex = flatPageEdge[rightVertexIndex];
                    
                    THVec3 normal = triangleNormal(leftVertex, middleVertex, rightVertex);
                    pageEdgeNormals[leftVertexIndex] = 
                        THVec3Add(pageEdgeNormals[leftVertexIndex], normal);
                    pageEdgeNormals[middleVertexIndex] = 
                        THVec3Add(pageEdgeNormals[middleVertexIndex], normal);
                    pageEdgeNormals[rightVertexIndex] = 
                        THVec3Add(pageEdgeNormals[rightVertexIndex], normal);            
                } 
                for(int i = 0; i < Y_VERTEX_COUNT * 2; ++i) {
                    pageEdgeNormals[i] = THVec3Normalize(pageEdgeNormals[i]);
                }
                
                //glClear(GL_DEPTH_BUFFER_BIT);
                
                glVertexAttribPointer(glGetAttribLocation(_program, "aPosition"), 3, GL_FLOAT, GL_FALSE, 0, pageEdge);
                glVertexAttribPointer(glGetAttribLocation(_program, "aNormal"), 3, GL_FLOAT, GL_FALSE, 0, pageEdgeNormals);
                
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, _bookEdgeTexture);

                glUniform1i(glGetUniformLocation(_program, "uDisableContentsTexture"), 1);
                
                glVertexAttribPointer(glGetAttribLocation(_program, "aTextureCoordinate"), 2, GL_FLOAT, GL_FALSE, 0, _pageEdgeTextureCoordinates);

                glDrawArrays(GL_TRIANGLE_STRIP, 0, Y_VERTEX_COUNT * 2);
                
                glUniform1i(glGetUniformLocation(_program, "uDisableContentsTexture"), 0);
            }
            
            if(++_automaticTurnFrame >= (_automaticTurnIsForwards ? _animatedTurnFrameCount : (_reverseAnimatedTurnFrameCount + 1))) {
                shouldStopAnimating = YES;
                
                _isTurningAutomatically = NO;
                
                [self _cyclePageContentsInformationForTurnForwards:_automaticTurnIsForwards];
                _rightFlatPageIndex = 3;
                
                _recacheFlags[1] = YES;
                _recacheFlags[5] = YES; 
                if(_twoSidedPages) {
                    _recacheFlags[0] = YES;
                    _recacheFlags[4] = YES; 
                }
                _viewsNeedRecache = YES;
                
                [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            }     
        }
    }        
    
    if(_atRenderScreenshotBuffer) {
        glReadPixels(0, 0, _backingWidth, _backingHeight, GL_RGBA, GL_UNSIGNED_BYTE, _atRenderScreenshotBuffer);
    }
    
    glBindRenderbuffer(GL_RENDERBUFFER, _viewRenderbuffer);
    [eaglContext presentRenderbuffer:GL_RENDERBUFFER];

    if(_viewsNeedRecache) {
        [self _cacheNonVisiblePages];
        [self _setNeedsAccessibilityElementsRebuild];
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
    }
    
    if(shouldStopAnimating) {
        self.animating = NO;
    }
}

- (void)_setPageTouchPointForViewportX:(GLfloat)x
{
    CGRect touchablePageRect = _rightPageRect;
    CGFloat pageX = x - touchablePageRect.origin.x;
    if(pageX > touchablePageRect.size.width) {
        pageX = touchablePageRect.size.width;
    } else if(pageX < -touchablePageRect.size.width) {
        pageX = -touchablePageRect.size.width;
    }
    _pageTouchPoint.x = pageX;
    _pageTouchPoint.y = ((GLfloat)_touchRow / (Y_VERTEX_COUNT - 1)) * touchablePageRect.size.height;
    _pageTouchPoint.z = -sqrtf(touchablePageRect.size.width * touchablePageRect.size.width - pageX * pageX);    
}

- (void)_setTouchLocationFromTouch:(UITouch *)touch firstTouch:(BOOL)first;
{
    CGSize size = self.bounds.size;
    CGPoint viewTouchPoint =  [touch locationInView:self];

    
    CGAffineTransform affineZoomMatrix = CATransform3DGetAffineTransform(_zoomMatrix);
    affineZoomMatrix.ty = -affineZoomMatrix.ty; // Screen coordinates are upside0down to GL.
    
    CGPoint projectedTouchPoint = CGPointMake((viewTouchPoint.x / size.width) * _viewportLogicalSize.width,
                                              (viewTouchPoint.y / size.height) * _viewportLogicalSize.height);
        
    // Project the page rect.
    CGRect projectedPageFrame = _rightPageRect;
    projectedPageFrame.origin.x -= _viewportLogicalSize.width * 0.5f;
    projectedPageFrame.origin.y -= _viewportLogicalSize.height * 0.5f;
    projectedPageFrame = CGRectApplyAffineTransform(projectedPageFrame, affineZoomMatrix);
    projectedPageFrame.origin.x += _viewportLogicalSize.width * 0.5f;
    projectedPageFrame.origin.y += _viewportLogicalSize.height * 0.5f;
    
    // Where on the page is the point?
    CGPoint touchablePagePoint = CGPointMake((projectedTouchPoint.x - projectedPageFrame.origin.x),
                                             (projectedTouchPoint.y - projectedPageFrame.origin.y));
    
    // Scale back to viewport coordinates.
    touchablePagePoint.x /= affineZoomMatrix.a;
    touchablePagePoint.y /= affineZoomMatrix.d;
    touchablePagePoint.x += _rightPageRect.origin.x;
    touchablePagePoint.y += _rightPageRect.origin.y;
    
    NSLog(@"(%f, %f)", touchablePagePoint.x, touchablePagePoint.y);
    
    if(touchablePagePoint.y <= _rightPageRect.origin.x) {
        _touchRow = 0;
    } else if(touchablePagePoint.y >= _rightPageRect.origin.x + _rightPageRect.size.height) {
        _touchRow = Y_VERTEX_COUNT - 1;
    } else {
        _touchRow = (((touchablePagePoint.y - _rightPageRect.origin.y) / 
                       _rightPageRect.size.height) + 0.5f / Y_VERTEX_COUNT) * (Y_VERTEX_COUNT - 1);
    }
    if(first) {
        _touchXOffset = _pageVertices[_touchRow][X_VERTEX_COUNT - 1].x - touchablePagePoint.x;
    }
    
    touchablePagePoint.x += _touchXOffset;
    
    CGFloat oldViewportTouchX = _viewportTouchPoint.x;
    _viewportTouchPoint = touchablePagePoint;
    
    NSTimeInterval thisTouchTime = [touch timestamp];
    if(_touchTime) {
        GLfloat difference = (GLfloat)(thisTouchTime - _touchTime);
        if(difference && !first) {
            _touchVelocity = (touchablePagePoint.x - oldViewportTouchX) / (30.0f * difference);
        } else {
            _touchVelocity = 0;
        }
    } else {
        _touchVelocity = 0;
    }
    _touchTime = thisTouchTime;
    [self _setPageTouchPointForViewportX:touchablePagePoint.x];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    // If we're not currently tracking a touch
    if(!_touch) {
        // Store touch
        _touch = touch;
        _touchBeganTime = [touch timestamp];
        if(self.isAnimating) {
            [self _setTouchLocationFromTouch:_touch firstTouch:YES];
        } else {
            _vibrated = NO;
        }
    }
    
    if(self.isAnimating || _vibrated) {
        // We've already started to turn the page.
        // Remove the touch we're 'using' and pass the rest on.
        NSMutableSet *unusedTouches = [touches mutableCopy];
        if([unusedTouches containsObject:_touch]) {
            [unusedTouches removeObject:_touch];
        }
        if(unusedTouches.count) {
            [_pageContentsInformation[3].view touchesBegan:unusedTouches withEvent:event];
        }
        [unusedTouches release];
    } else {
        // We haven't started to move yet.  We'll pass all the touches on.
        
        if(touches.count > 1 || ![touches containsObject:_touch]) {
            // This is a pinch.  Track both touches
            // We store the touches in a different ivar for a pinch.
            _pinchTouches[0] = _touch;
            _touch = nil;
            
            for(UITouch *secondTouch in touches) {
                if(secondTouch != _pinchTouches[0]) {
                    _pinchTouches[1] = secondTouch;
                    break;
                }
            }
            
            _pinchStartPoints[0] = [_pinchTouches[0] locationInView:self];
            _pinchStartPoints[1] = [_pinchTouches[1] locationInView:self];
            
            _pinchStartZoomFactor = _zoomFactor;
            _pinchStartZoomTranslation = _zoomTranslation;
            
            THLog(@"Pinch Began: %@, %@", NSStringFromCGPoint(_pinchStartPoints[0]), NSStringFromCGPoint(_pinchStartPoints[1]));
        }
        
        [_pageContentsInformation[3].view touchesBegan:touches withEvent:event];
    }
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if([touches containsObject:_touch]) {
        if(self.userInteractionEnabled) {
            // If first movement
            if(!self.isAnimating) {
                // usleep(180000); Test to see if it would be acceptable to re-cache
                // the view here (it would not).
                
                // Store touch, note direction.
                BOOL shouldAnimate = YES;
                CGPoint location = [_touch locationInView:self];
                CGPoint previousLocation = [_touch previousLocationInView:self];
                if(previousLocation.x < location.x) {
                    if(_pageContentsInformation[1].view || _pageContentsInformation[1].pageIndex != NSUIntegerMax) {
                        if(_rightPageRect.origin.x == 0.0f) {
                            // Position the page floating just outside the field of view.
                            for(int column = 1; column < X_VERTEX_COUNT; ++column) {
                                for(int row = 0; row < Y_VERTEX_COUNT; ++row) {                            
                                    GLfloat radius = _pageVertices[row][column].x;                            
                                    _pageVertices[row][column].z = -radius * sinf(((GLfloat)M_PI - (FOV_ANGLE / (360.0f * (GLfloat)M_2_PI))) / 2.0f);
                                    _pageVertices[row][column].x = radius * cosf(((GLfloat)M_PI - (FOV_ANGLE / (360.0f * (GLfloat)M_2_PI))) / 2.0f);
                                }
                            }   
                        } else {
                            // Position the page flat on the left.
                            for(int column = 1; column < X_VERTEX_COUNT; ++column) {
                                for(int row = 0; row < Y_VERTEX_COUNT; ++row) {                            
                                    _pageVertices[row][column].x = -_pageVertices[row][column].x;
                                }
                            }                               
                        }
                        memcpy(_oldPageVertices, _pageVertices, sizeof(_oldPageVertices));
                    } else {
                        shouldAnimate = NO;
                    }
                } else {
                    if(_pageContentsInformation[5].view || _pageContentsInformation[5].pageIndex != NSUIntegerMax) {
                        _rightFlatPageIndex = 5;
                    } else {
                        shouldAnimate = NO;
                    }
                }
                if(!_vibrated) {
                    [_pageContentsInformation[3].view touchesCancelled:[NSSet setWithObject:_touch] withEvent:event];
                }
                if(shouldAnimate) {
                    _vibrated = NO;
                    [self _setTouchLocationFromTouch:_touch firstTouch:YES];
                    self.animating = YES;
                } else {
                    if(!_vibrated) {
                        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
                        _vibrated = YES;
                    }
                }
            } else if(!_vibrated) {
                // Set touch location
                [self _setTouchLocationFromTouch:_touch firstTouch:NO];
            }
        }
    } else if([touches containsObject:_pinchTouches[0]] || [touches containsObject:_pinchTouches[1]]) {
        if(!_pinchUnderway) {
            [THBackgroundProcessingMediator curtailBackgroundProcessing];
            [_pageContentsInformation[3].view touchesCancelled:[NSSet setWithObjects:_pinchTouches count:2] withEvent:event];
            _pinchUnderway = YES;
        }        
        
        CGPoint currentPinchPoints[2] = { [_pinchTouches[0] locationInView:self], [_pinchTouches[1] locationInView:self] };

        if(_zoomHandlingKind == EucPageTurningViewZoomHandlingKindInnerScaling) {
            if([_viewDataSource respondsToSelector:@selector(pageTurningView:scaledViewForView:pinchStartedAt:pinchNowAt:currentScaledView:)]) {
                UIView *scaledView = [_viewDataSource pageTurningView:self 
                                                    scaledViewForView:_pageContentsInformation[3].view 
                                                       pinchStartedAt:_pinchStartPoints
                                                           pinchNowAt:currentPinchPoints
                                                    currentScaledView:_pageContentsInformation[6].view];
                if(scaledView && scaledView != _pageContentsInformation[6].view) {
                    [self _setView:scaledView forInternalPageOffsetPage:6];
                    _rightFlatPageIndex = 6;
                    
                    //NSLog(@"Pinch %f -> %f, scalefactor %f", (float)startDistance,(float)nowDistance, (float)(nowDistance / startDistance));
                    
                    [self drawView];
                }
            }
        } else {
            if(!_zoomingDelegateMessageSent) {
                if([_delegate respondsToSelector:@selector(pageTurningViewWillBeginZooming:)]) {
                    [_delegate pageTurningViewWillBeginZooming:self];   
                }
                _zoomingDelegateMessageSent = YES;
            }
            
            CGFloat newZoomFactor = _pinchStartZoomFactor;
            CGFloat oldDistance = CGPointDistance(_pinchStartPoints[0], _pinchStartPoints[1]);
            CGFloat newDistance = CGPointDistance(currentPinchPoints[0], currentPinchPoints[1]);
            CGFloat zoom = newDistance / oldDistance;
            newZoomFactor *= zoom;

            CGPoint oldCenter = CGPointMake((_pinchStartPoints[0].x + (_pinchStartPoints[1].x - _pinchStartPoints[0].x) * 0.5) / _viewportToBoundsPointsTransform.a - _viewportLogicalSize.width * 0.5,
                                            (_pinchStartPoints[0].y + (_pinchStartPoints[1].y - _pinchStartPoints[0].y) * 0.5) / _viewportToBoundsPointsTransform.d - _viewportLogicalSize.height * 0.5);
            CGPoint newCenter = CGPointMake((currentPinchPoints[0].x + (currentPinchPoints[1].x - currentPinchPoints[0].x) * 0.5) / _viewportToBoundsPointsTransform.a - _viewportLogicalSize.width * 0.5,
                                            (currentPinchPoints[0].y + (currentPinchPoints[1].y - currentPinchPoints[0].y) * 0.5) / _viewportToBoundsPointsTransform.d - _viewportLogicalSize.height * 0.5);
            
            CGPoint zoomCounteractingTranslation = CGPointMake((oldCenter.x * _pinchStartZoomFactor - oldCenter.x * newZoomFactor) / _pinchStartZoomFactor,
                                                               (oldCenter.y * _pinchStartZoomFactor - oldCenter.y * newZoomFactor) / _pinchStartZoomFactor); 
            
            CGPoint movementTranslation = CGPointMake((newCenter.x - oldCenter.x), (newCenter.y - oldCenter.y));
            
            CGPoint newZoomTranslation = CGPointMake(movementTranslation.x + zoomCounteractingTranslation.x,
                                                     movementTranslation.y + zoomCounteractingTranslation.y);
            
            newZoomTranslation.x += _pinchStartZoomTranslation.x * newZoomFactor / _pinchStartZoomFactor;
            newZoomTranslation.y += _pinchStartZoomTranslation.y * newZoomFactor / _pinchStartZoomFactor;
            
            [self _setZoomMatrixFromTranslation:newZoomTranslation zoomFactor:newZoomFactor];
        }
    }
    
    if(self.isAnimating || _vibrated || _pinchUnderway) {
        NSMutableSet *unusedTouches = [touches mutableCopy];
        if(_touch) {
            if([unusedTouches containsObject:_touch]) {
                [unusedTouches removeObject:_touch];
            }            
        } 
        if(_pinchTouches[0]) {
            if([unusedTouches containsObject:_pinchTouches[0]]) {
                [unusedTouches removeObject:_pinchTouches[0]];
            }            
        }
        if(_pinchTouches[1]) {
            if([unusedTouches containsObject:_pinchTouches[1]]) {
                [unusedTouches removeObject:_pinchTouches[1]];
            }            
        }
        if(unusedTouches.count) {
            [_pageContentsInformation[3].view touchesMoved:unusedTouches withEvent:event];
        }
        [unusedTouches release];
    } else {
        [_pageContentsInformation[3].view touchesMoved:touches withEvent:event];
    }    
}

- (void)_touchesEndedOrCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if([touches containsObject:_touch]) {
        if([event timestamp] > [_touch timestamp] + 0.1) {
            [self _setTouchLocationFromTouch:_touch firstTouch:NO];
        }
        //NSLog(@"Real: %f", _touchVelocity);
        
        GLfloat absTouchVelocity = fabsf(_touchVelocity);
        if(absTouchVelocity < 0.02f) {
            _touchVelocity = 0;
        } else if(absTouchVelocity < 0.2f) {
            _touchVelocity = _touchVelocity < 0 ? -0.2f : 0.2f;
        } else if(absTouchVelocity > 0.4f) {
            _touchVelocity = _touchVelocity < 0 ? -0.4f : 0.4f;
        }
        //NSLog(@"Corrected: %f", _touchVelocity);
        //_pageTouchPoint.x = _pageVertices[_touchRow][X_VERTEX_COUNT - 1].x;
        _touchTime = 0;
        
        _touch = nil;
    } else if([touches containsObject:_pinchTouches[0]] || [touches containsObject:_pinchTouches[1]]) {
        UITouch *remainingTouch = nil;
        if(![touches containsObject:_pinchTouches[0]]) {
            remainingTouch = _pinchTouches[0];
        } else if(![touches containsObject:_pinchTouches[1]]) {
            remainingTouch = _pinchTouches[1];
        }
        
        _pinchTouches[0] = nil;
        _pinchTouches[1] = nil;
        
        if(_pinchUnderway) {
            _pinchUnderway = NO;       
            if(_zoomHandlingKind == EucPageTurningViewZoomHandlingKindInnerScaling) {
                if(_pageContentsInformation[6].view || _pageContentsInformation[6].pageIndex != NSUIntegerMax) {
                    EucPageTurningPageContentsInformation tempView = _pageContentsInformation[3];
                    _pageContentsInformation[3] = _pageContentsInformation[6];
                    _pageContentsInformation[6] = tempView;
                    
                    [self _setView:nil forInternalPageOffsetPage:6];
                    _rightFlatPageIndex = 3;

                    if([_delegate respondsToSelector:@selector(pageTurningView:didScaleToView:)]) {
                        [_delegate pageTurningView:self didScaleToView:_pageContentsInformation[3].view];
                    }
                    
                    [self _setView:[_viewDataSource pageTurningView:self previousViewForView:_pageContentsInformation[3].view] forInternalPageOffsetPage:1];
                    [self _setView:[_viewDataSource pageTurningView:self nextViewForView:_pageContentsInformation[3].view] forInternalPageOffsetPage:5];

                    [self drawView];
                }
            } else {
                if([_delegate respondsToSelector:@selector(pageTurningViewDidEndZooming:)]) {
                    [_delegate pageTurningViewDidEndZooming:self];   
                }
                _zoomingDelegateMessageSent = NO;
            }
            [THBackgroundProcessingMediator allowBackgroundProcessing];
        }
        
        if(remainingTouch) {
            [self touchesBegan:[NSSet setWithObject:remainingTouch] withEvent:event];
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(self.isAnimating || _vibrated) {
        NSMutableSet *unusedTouches = [touches mutableCopy];
        if(_touch) {
            if([unusedTouches containsObject:_touch]) {
                [unusedTouches removeObject:_touch];
            }            
        }
        if(unusedTouches.count) {
            [_pageContentsInformation[3].view touchesEnded:unusedTouches withEvent:event];
        }
        [unusedTouches release];
    } else if(_pinchUnderway) {
        NSMutableSet *unusedTouches = [touches mutableCopy];
        if(_pinchTouches[0]) {
            if([unusedTouches containsObject:_pinchTouches[0]]) {
                [unusedTouches removeObject:_pinchTouches[0]];
            }            
        }
        if(_pinchTouches[1]) {
            if([unusedTouches containsObject:_pinchTouches[1]]) {
                [unusedTouches removeObject:_pinchTouches[1]];
            }            
        }
        if(unusedTouches.count) {
            [_pageContentsInformation[3].view touchesEnded:unusedTouches withEvent:event];
        }
        [unusedTouches release];     
    } else {
        if(_touch && 
           [touches containsObject:_touch] && 
           [_touch timestamp] - _touchBeganTime < 0.2) {
            BOOL turning = NO;
            
            CGPoint point = [_touch locationInView:self];
            if(_pageContentsInformation[3].view) {
                CGFloat tapTurnMargin = [self _tapTurnMarginForView:_pageContentsInformation[3].view];
                if(point.x < tapTurnMargin && _pageContentsInformation[1].view) {
                    [self turnToPageView:_pageContentsInformation[1].view forwards:NO pageCount:1 onLeft:NO];
                    turning = YES;
                } else if(point.x > (_pageContentsInformation[3].view.bounds.size.width - tapTurnMargin) && _pageContentsInformation[5].view) {
                    [self turnToPageView:_pageContentsInformation[5].view forwards:YES pageCount:1 onLeft:NO];
                    turning = YES;
                }                
            } else {
                CGFloat tapTurnMargin = 0.1f * self.bounds.size.width;
                if(point.x < tapTurnMargin) {
                    if(_pageContentsInformation[1].pageIndex != NSUIntegerMax) {
                        [self turnToPageAtIndex:_pageContentsInformation[1].pageIndex animated:YES];
                        turning = YES;
                    } 
                } else if(point.x > (self.bounds.size.width - tapTurnMargin)) {
                    if(_pageContentsInformation[4].pageIndex != NSUIntegerMax) {
                        [self turnToPageAtIndex:_pageContentsInformation[4].pageIndex animated:YES];
                        turning = YES;
                    } else if(_pageContentsInformation[5].pageIndex != NSUIntegerMax) {
                        [self turnToPageAtIndex:_pageContentsInformation[5].pageIndex animated:YES];
                        turning = YES;
                    }
                }                
            }
            
            if(turning) {
                NSMutableSet *unusedTouches = [touches mutableCopy];
                if(_touch) {
                    if([unusedTouches containsObject:_touch]) {
                        [unusedTouches removeObject:_touch];
                    }            
                }
                if(unusedTouches.count) {
                    [_pageContentsInformation[3].view touchesEnded:unusedTouches withEvent:event];
                }
                [unusedTouches release];   
                [_pageContentsInformation[3].view touchesCancelled:[NSSet setWithObject:_touch] withEvent:event];
            } else {
                [_pageContentsInformation[3].view touchesEnded:touches withEvent:event];
            }
        } else {
            [_pageContentsInformation[3].view touchesEnded:touches withEvent:event];
        }
    }
    [self _touchesEndedOrCancelled:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(self.isAnimating || _vibrated) {
        NSMutableSet *unusedTouches = [touches mutableCopy];
        if(_touch) {
            if([unusedTouches containsObject:_touch]) {
                [unusedTouches removeObject:_touch];
            }            
        }
        if(unusedTouches.count) {
            [_pageContentsInformation[3].view touchesCancelled:unusedTouches withEvent:event];
        }
        [unusedTouches release];
    } else if(_pinchUnderway) {
        NSMutableSet *unusedTouches = [touches mutableCopy];
        if(_pinchTouches[0]) {
            if([unusedTouches containsObject:_pinchTouches[0]]) {
                [unusedTouches removeObject:_pinchTouches[0]];
            }            
        }
        if(_pinchTouches[1]) {
            if([unusedTouches containsObject:_pinchTouches[1]]) {
                [unusedTouches removeObject:_pinchTouches[1]];
            }            
        }
        if(unusedTouches.count) {
            [_pageContentsInformation[3].view touchesCancelled:unusedTouches withEvent:event];
        }
        [unusedTouches release];        
    } else {
        [_pageContentsInformation[3].view touchesCancelled:touches withEvent:event];
    }
    [self _touchesEndedOrCancelled:touches withEvent:event];
}

- (void)setUserInteractionEnabled:(BOOL)enabled
{
    if(!enabled && _touch) {
        [self _touchesEndedOrCancelled:[NSSet setWithObject:_touch] withEvent:nil];
    }
    [super setUserInteractionEnabled:enabled];
}



- (CGFloat)_tapTurnMarginForView:(UIView *)view
{
    CGFloat ret;
    id<EucPageTurningViewDelegate> delegate = self.delegate;
    if([delegate respondsToSelector:@selector(pageTurningView:tapTurnMarginForView:)]) {
        ret = [delegate pageTurningView:self tapTurnMarginForView:view];
    } else {
        ret = 0.1f * view.bounds.size.width;
    }
    return ret;
}

- (NSArray *)accessibilityElements
{
    if(!_accessibilityElements) {
        NSArray *pageViewAccessibilityElements = nil;
        if([_pageContentsInformation[3].view respondsToSelector:@selector(accessibilityElements)]) {
            pageViewAccessibilityElements = [_pageContentsInformation[3].view  performSelector:@selector(accessibilityElements)];
        }
        NSMutableArray *accessibilityElements = [[NSMutableArray alloc] initWithCapacity:pageViewAccessibilityElements.count + 1];
        
        CGFloat tapZoneWidth = [self _tapTurnMarginForView:_pageContentsInformation[3].view];
            
        for(UIAccessibilityElement *element in pageViewAccessibilityElements) {
            element.accessibilityContainer = self;
            [accessibilityElements addObject:element];
        }

        {
            THAccessibilityElement *nextPageTapZone = [[THAccessibilityElement alloc] initWithAccessibilityContainer:self];
            nextPageTapZone.accessibilityTraits = UIAccessibilityTraitButton;
            if(!_pageContentsInformation[5].view)  {
                nextPageTapZone.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
            }            
            CGRect frame = [self convertRect:self.bounds toView:nil];
            frame.origin.x = frame.size.width + frame.origin.x - tapZoneWidth;
            frame.size.width = tapZoneWidth;
            nextPageTapZone.accessibilityFrame = frame;
            nextPageTapZone.accessibilityLabel = NSLocalizedString(@"Next Page", @"Accessibility title for previous page tap zone");
            
            nextPageTapZone.delegate = self;
            
            [accessibilityElements addObject:nextPageTapZone];
            _nextPageTapZone = [nextPageTapZone retain];
            
            [nextPageTapZone release];
        }        
        
        {
            UIAccessibilityElement *previousPageTapZone = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
            previousPageTapZone.accessibilityTraits = UIAccessibilityTraitButton;
            if(!_pageContentsInformation[1].view)  {
                previousPageTapZone.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
            }
            CGRect frame = [self convertRect:self.bounds toView:nil];
            frame.size.width = tapZoneWidth;
            previousPageTapZone.accessibilityFrame = frame;
            previousPageTapZone.accessibilityLabel = NSLocalizedString(@"Previous Page", @"Accessibility title for next page tap zone");
            
            [accessibilityElements addObject:previousPageTapZone];
            [previousPageTapZone release];
        }        

        {
            CGRect frame = [self convertRect:self.bounds toView:nil];
            frame.origin.y = 0;
            frame.size.height = tapZoneWidth;
            frame.size.width -= 2 * tapZoneWidth;
            frame.origin.x += tapZoneWidth;

            UIAccessibilityElement *toolbarTapButton = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
            toolbarTapButton.accessibilityFrame = frame;
            toolbarTapButton.accessibilityLabel = NSLocalizedString(@"Book Page", @"Accessibility title for previous page tap zone");
            toolbarTapButton.accessibilityHint = NSLocalizedString(@"Double tap to return to controls.", @"Accessibility title for previous page tap zone");
            
            [accessibilityElements addObject:toolbarTapButton];
            [toolbarTapButton release];
        }
                
        _accessibilityElements = accessibilityElements;
    }
    return _accessibilityElements;
}

- (BOOL)isAccessibilityElement
{
    return NO;
}

- (NSInteger)accessibilityElementCount
{
    return [[self accessibilityElements] count];
}

- (id)accessibilityElementAtIndex:(NSInteger)index
{
    return [[self accessibilityElements] objectAtIndex:index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
    return [[self accessibilityElements] indexOfObject:element];
}

- (void)thAccessibilityElementDidBecomeFocused:(THAccessibilityElement *)element
{
    // An attempt to auto-read the book.  Doesn't really work.
    /*if(element == _nextPageTapZone) {
        if(element.accessibilityElementIsFocused) {
            [self turnToPageView:_pageViews[2] forwards:YES pageCount:1];
        }
    }*/
}

// Since gravity is the only force we're using, we just manually add it in 
// -_verlet;
/*
- (void)_accumulateForces
{
    GLfloatTriplet *flatForceAccumulators = (GLfloatTriplet *)_forceAccumulators;
    for(int i=0; i< X_VERTEX_COUNT * Y_VERTEX_COUNT; i++) {
        flatForceAccumulators[i].x = 0;
        flatForceAccumulators[i].y = 0;
        flatForceAccumulators[i].z = (_touch || _touchVelocity) ? 0.002 : 0.005;
    } 
}
*/

- (void)_verlet
{    
    if(!_touch && _touchVelocity) {
        GLfloat newX = _viewportTouchPoint.x + _touchVelocity /** difference*/;
        _viewportTouchPoint.x = newX;
        [self _setPageTouchPointForViewportX:newX];
    }
    
    THVec3 *flatPageVertices = (THVec3 *)_pageVertices;
    THVec3 *flatOldPageVertices = (THVec3 *)_oldPageVertices;
    //GLfloatTriplet *flatForceAccumulators = (GLfloatTriplet *)_forceAccumulators;
    GLfloat gravity = (_touch || _touchVelocity) ? 0.002 : 0.01;
    
    for(int i = 0; i < X_VERTEX_COUNT * Y_VERTEX_COUNT; ++i) {
        THVec3 x = flatPageVertices[i];
        THVec3 temp = x;
        THVec3 oldx = flatOldPageVertices[i];
        //GLfloatTriplet a = flatForceAccumulators[i];
        
        // This gives better time-correct movement, but makes the model unstable.
        //flatPageVertices[i] = addVector(x, addVector(multiplyVector(multiplyVector(subtractVector(x, oldx), (_touch || _touchVelocity) ? 0.6 : 0.99), (difference / previousDifference)), multiplyVector(a, difference * difference))); // Should add timestep ^ 2 here if it might vary.   
       
        //flatPageVertices[i] = addVector(x, addVector(multiplyVector(subtractVector(x, oldx), (_touch || _touchVelocity) ? 0.6f : 0.99f), a));  
        
        // The above, commented out line is correct, but for optimization, 
        // we just manually add gravity instead of using the forces from 
        // -_accumulateForces since it's the only force.
        flatPageVertices[i] = THVec3Add(x, THVec3Multiply(THVec3Subtract(x, oldx), (_touch || _touchVelocity) ? 0.6f : 0.99f)); 
        flatPageVertices[i].z += gravity;
        
        flatOldPageVertices[i] = temp;
    }
}

#define NUM_ITERATIONS 40

- (BOOL)_satisfyConstraints
{
    BOOL shouldStopAnimating = NO;
    
    BOOL pageHasRigidEdge;
    if([_delegate respondsToSelector:@selector(pageTurningView:viewEdgeIsRigid:)]) {
        pageHasRigidEdge = [_delegate pageTurningView:self viewEdgeIsRigid:_pageContentsInformation[_rightFlatPageIndex-2].view];
    } else {
        pageHasRigidEdge = NO;
    }
    
    CGFloat pageOriginX = _rightPageRect.origin.x;
    THVec3 pageTouchPoint = _pageTouchPoint;
        
    THVec3 *flatPageVertices = (THVec3 *)_pageVertices;
    int j;
    for(j=0; j < NUM_ITERATIONS; ++j) {              
        if(_touch || _touchVelocity) {        
            _pageVertices[MAX(0, _touchRow-1)][X_VERTEX_COUNT - 1].x = pageTouchPoint.x;
            _pageVertices[_touchRow][X_VERTEX_COUNT - 1] = pageTouchPoint;
            _pageVertices[MIN(Y_VERTEX_COUNT - 1, _touchRow+1)][X_VERTEX_COUNT - 1].x = pageTouchPoint.x;
        }
        
        for(int i = 0; i < CONSTRAINT_COUNT; ++i) {
            EucPageTurningVerletContstraint constraint = _constraints[i];
            THVec3 a = flatPageVertices[constraint.particleAIndex];
            THVec3 b = flatPageVertices[constraint.particleBIndex];
            THVec3 delta = THVec3Subtract(b, a);
            /*
            GLfloat distance = magnitude(delta);
            GLfloat diff = (distance - constraint.length)/distance;
            if(diff) {
                GLfloatTriplet deltaTimesHalfDiff = multiplyVector(delta, diff / 2);
                flatPageVertices[constraint.particleAIndex] = addVector(a, deltaTimesHalfDiff); 
                flatPageVertices[constraint.particleBIndex] = subtractVector(b, deltaTimesHalfDiff); 
            }*/
            // Sqrt-approximated version of above code:
            CGFloat contraintLengthSquared = constraint.lengthSquared;
            delta = THVec3Multiply(delta, contraintLengthSquared/(THVec3DotProduct(delta)+contraintLengthSquared)-0.5);
            flatPageVertices[constraint.particleAIndex] = THVec3Subtract(a, delta); 
            flatPageVertices[constraint.particleBIndex] = THVec3Add(b, delta); 
            flatPageVertices[constraint.particleAIndex].z = MIN(0.0f, flatPageVertices[constraint.particleAIndex].z);
            flatPageVertices[constraint.particleBIndex].z = MIN(0.0f, flatPageVertices[constraint.particleBIndex].z);            
        }
        
        
        // Make sure the page is attached to the edge, and
        // above the surface.
        BOOL isFlat = !_touch && _touchVelocity >= 0;
        BOOL hasFlipped = !_touch && _touchVelocity <= 0;
        BOOL hasFlippedFlat = !_touch && _touchVelocity <= 0;
        for(int row = 0; row < Y_VERTEX_COUNT; ++row) {
            GLfloat xCoord = _stablePageVertices[row][0].x;
            GLfloat yCoord = _stablePageVertices[row][0].y;
            GLfloat zCoord = _stablePageVertices[row][0].z;
            for(int column = 0; column < X_VERTEX_COUNT; ++column) {
                THVec3 vertex = _pageVertices[row][column];
                
                GLfloat diff = yCoord - vertex.y;
                _pageVertices[row][column].y = (vertex.y += diff * 0.5f);

                // Test if this vertes is out of our field of view.
                if(hasFlipped && 
                   column > 0) {
                    // See if the vertex is outside the FOV angle.
                    CGFloat angle = atanf(-vertex.z / (vertex.x + pageOriginX));
                    if(angle < 0) {
                        angle = (GLfloat)M_PI + angle;
                    }
                    if(angle < (((GLfloat)M_PI - (FOV_ANGLE / (360.0f * ((GLfloat)M_PI * 2.0f)))) / 2.0f)) { 
                        hasFlipped = NO;
                    }
                }
            }
                                    
            _pageVertices[row][0].x = xCoord;
            _pageVertices[row][0].y = yCoord;
            _pageVertices[row][0].z = zCoord;
            
            CGFloat lastx = _pageVertices[row][X_VERTEX_COUNT - 1].x;
            if(lastx > (_stablePageVertices[row][X_VERTEX_COUNT - 1].x - 0.0125f)) {
                _pageVertices[row][X_VERTEX_COUNT - 1].x = _stablePageVertices[row][X_VERTEX_COUNT - 1].x;
                if(hasFlippedFlat) {
                    hasFlippedFlat = NO;
                }                
            } else if(lastx < (-_stablePageVertices[row][X_VERTEX_COUNT - 1].x + 0.0125f)) {
                _pageVertices[row][X_VERTEX_COUNT - 1].x = -_stablePageVertices[row][X_VERTEX_COUNT - 1].x;
                if(isFlat) {
                    isFlat = NO;
                }                         
            } else {
                if(hasFlippedFlat) {
                    hasFlippedFlat = NO;
                }
                if(isFlat) {
                    isFlat = NO;
                }         
                if(_touch || _touchVelocity) {
                    if(pageHasRigidEdge) {
                        _pageVertices[row][X_VERTEX_COUNT - 1].x = pageTouchPoint.x;
                        _pageVertices[row][X_VERTEX_COUNT - 1].z = pageTouchPoint.z;
                    } else {
                        GLfloat diff = pageTouchPoint.x - _pageVertices[row][X_VERTEX_COUNT - 1].x;
                        _pageVertices[row][X_VERTEX_COUNT - 1].x += diff * 0.2f;
                    }
                }
            }
        }
                   
        if(hasFlippedFlat) {
            hasFlipped = YES;
        }
        
        if(isFlat || hasFlipped) {
            memcpy(_pageVertices, _stablePageVertices, sizeof(_stablePageVertices));
            memcpy(_oldPageVertices, _stablePageVertices, sizeof(_stablePageVertices));
            _touchVelocity = 0;
            
            if(_rightFlatPageIndex == 5) {
                if(hasFlipped) {
                    [self _cyclePageContentsInformationForTurnForwards:YES];
                    if(_twoSidedPages) {
                        _recacheFlags[4] = YES;
                    }
                    _recacheFlags[5] = YES;
                    _viewsNeedRecache = YES;
                } 
                _rightFlatPageIndex = 3;
            } else {
                if(!hasFlipped) {
                    [self _cyclePageContentsInformationForTurnForwards:NO];
                    if(_twoSidedPages) {
                        _recacheFlags[0] = YES;
                    }                    
                    _recacheFlags[1] = YES;
                    _viewsNeedRecache = YES;
                }
            }  
            
            shouldStopAnimating = YES;

            break;
        }
    }
    return shouldStopAnimating;
}

- (void)_cacheNonVisiblePages
{
    [EAGLContext setCurrentContext:self.eaglContext];
    if(_twoSidedPages) {
        if(_recacheFlags[1]) {
            if(_viewDataSource) {
                if(_pageContentsInformation[2].view) {
                    [self _setView:[_viewDataSource pageTurningView:self 
                                                previousViewForView:_pageContentsInformation[2].view] forInternalPageOffsetPage:1];
                } else {
                    [self _setView:nil forInternalPageOffsetPage:1];
                }
            } else {
                if(_pageContentsInformation[2].pageIndex != NSUIntegerMax) {
                    [self _setupBitmapPage:_pageContentsInformation[2].pageIndex - 1 forInternalPageOffset:1];
                } else {
                    _pageContentsInformation[1].pageIndex = NSUIntegerMax;
                    glDeleteTextures(1, &_pageContentsInformation[1].texture);
                    _pageContentsInformation[1].texture = 0;                    
                }
            }
        }
        if(_recacheFlags[0]) {
            if(_viewDataSource) {
                if(_pageContentsInformation[1].view) {
                    [self _setView:[_viewDataSource pageTurningView:self 
                                                previousViewForView:_pageContentsInformation[1].view] forInternalPageOffsetPage:0];
                } else {
                    [self _setView:nil forInternalPageOffsetPage:0];
                }
            } else {
                if(_pageContentsInformation[1].pageIndex != NSUIntegerMax) {
                    [self _setupBitmapPage:_pageContentsInformation[1].pageIndex - 1 forInternalPageOffset:0];
                } else {
                    _pageContentsInformation[0].pageIndex = NSUIntegerMax;
                    glDeleteTextures(1, &_pageContentsInformation[0].texture);
                    _pageContentsInformation[0].texture = 0;                    
                }
            }
        }
        
        // Pages 2 and 3 are already set.
        
        if(_recacheFlags[4]) {
            if(_viewDataSource) {
                if(_pageContentsInformation[3].view) {
                    [self _setView:[_viewDataSource pageTurningView:self 
                                                    nextViewForView:_pageContentsInformation[3].view] forInternalPageOffsetPage:4];
                } else {
                    [self _setView:nil forInternalPageOffsetPage:4];
                }         
            } else {
                if(_pageContentsInformation[3].pageIndex != NSUIntegerMax) {
                    [self _setupBitmapPage:_pageContentsInformation[3].pageIndex + 1 forInternalPageOffset:4];
                } else {
                    _pageContentsInformation[4].pageIndex = NSUIntegerMax;
                    glDeleteTextures(1, &_pageContentsInformation[4].texture);
                    _pageContentsInformation[4].texture = 0;                    
                }
            }
        }
        if(_recacheFlags[5]) {
            if(_viewDataSource) {
                if(_pageContentsInformation[4].view) {
                    [self _setView:[_viewDataSource pageTurningView:self 
                                                    nextViewForView:_pageContentsInformation[4].view] forInternalPageOffsetPage:5];
                } else {
                    [self _setView:nil forInternalPageOffsetPage:5];
                }    
            } else {
                if(_pageContentsInformation[4].pageIndex != NSUIntegerMax) {
                    [self _setupBitmapPage:_pageContentsInformation[4].pageIndex + 1 forInternalPageOffset:5];
                } else {
                    _pageContentsInformation[5].pageIndex = NSUIntegerMax;
                    glDeleteTextures(1, &_pageContentsInformation[5].texture);
                    _pageContentsInformation[5].texture = 0;                    
                }
            }
        }
    } else {
        if(_recacheFlags[1]) {
            if(_viewDataSource) {
                if(_pageContentsInformation[3].view) {
                    [self _setView:[_viewDataSource pageTurningView:self 
                                                previousViewForView:_pageContentsInformation[3].view] forInternalPageOffsetPage:1];
                } else {
                    [self _setView:nil forInternalPageOffsetPage:1];
                }
            } else {
                if(_pageContentsInformation[3].pageIndex != NSUIntegerMax) {
                    [self _setupBitmapPage:_pageContentsInformation[3].pageIndex - 1 forInternalPageOffset:1];
                } else {
                    _pageContentsInformation[1].pageIndex = NSUIntegerMax;
                    glDeleteTextures(1, &_pageContentsInformation[1].texture);
                    _pageContentsInformation[1].texture = 0;                    
                }
            }
        }
        
        // Pages 3 is already set.
        
        if(_recacheFlags[5]) {
            if(_viewDataSource) {
                if(_pageContentsInformation[3].view) {
                    [self _setView:[_viewDataSource pageTurningView:self 
                                                    nextViewForView:_pageContentsInformation[3].view] forInternalPageOffsetPage:5];
                } else {
                    [self _setView:nil forInternalPageOffsetPage:5];
                }         
            } else {
                if(_pageContentsInformation[3].pageIndex != NSUIntegerMax) {
                    [self _setupBitmapPage:_pageContentsInformation[3].pageIndex + 1 forInternalPageOffset:5];
                } else {
                    _pageContentsInformation[5].pageIndex = NSUIntegerMax;
                    glDeleteTextures(1, &_pageContentsInformation[5].texture);
                    _pageContentsInformation[5].texture = 0;                    
                }
            }
        }
    }
    
    memset(_recacheFlags, 0, sizeof(_recacheFlags));
    _viewsNeedRecache = NO;    

    if(_viewDataSource && [_delegate respondsToSelector:@selector(pageTurningView:didTurnToView:)]) {
        [_delegate pageTurningView:self didTurnToView:_pageContentsInformation[3].view ?: _pageContentsInformation[2].view];
    }                    
}

- (void)_setNeedsAccessibilityElementsRebuild
{
    [_accessibilityElements release];
    _accessibilityElements = nil;
    [_nextPageTapZone release];
    _nextPageTapZone = nil;
}

- (void)setDimQuotient:(CGFloat)dimQuotient
{
    _dimQuotient = dimQuotient;
    [self setNeedsLayout];
}

- (CGFloat)dimQuotient
{
    return _dimQuotient;
}

- (CGPoint)_setZoomMatrixFromTranslation:(CGPoint)translation zoomFactor:(CGFloat)zoomFactor
{
    [self willChangeValueForKey:@"rightPageFrame"];
    [self willChangeValueForKey:@"leftPageFrame"];
    
    CATransform3D zoomMatrix = CATransform3DIdentity;
    
    CGSize bounds = self.bounds.size;
    CGFloat pointViewportDimension = bounds.width / _viewportLogicalSize.width;

    CGFloat contentScaleFactor;
    if([self respondsToSelector:@selector(contentScaleFactor)]) {
        contentScaleFactor = self.contentScaleFactor;
    } else {
        contentScaleFactor = 1.0f;
    }
    
    CGFloat pixelViewportDimension = pointViewportDimension * contentScaleFactor;
    
 
    CGSize pixelSize = CGSizeMake(_rightPageRect.size.width * pixelViewportDimension,
                                  _rightPageRect.size.height * pixelViewportDimension);
    
    if(zoomFactor < 1.0f) {
        zoomFactor = 1.0f;
    }
    
    // Temporary - constrain to 2048 sided textures.
    CGFloat maxSide = MAX(pixelSize.width, pixelSize.height);
    if(maxSide * zoomFactor > 2048.0f) {
        zoomFactor = 2048.0f / maxSide;  
        pixelSize = CGSizeMake(_rightPageRect.size.width * pixelViewportDimension,
                               _rightPageRect.size.height * pixelViewportDimension);
    }
    
    // Massage the zoom matrix to the nearest matrix that will scale the zoom 
    // rect edges to pixel boundaries, so that our page textures will look
    // nice and crisp, and the pages with have pixel-aligned edges.
    // Make sure the width is also divisible by two so that it can be centered
    // on a pixel boundry.
    zoomMatrix.m11 = roundf(pixelSize.width * zoomFactor * 0.5f) / (pixelSize.width * 0.5f);
    zoomMatrix.m22 = roundf(pixelSize.height * zoomFactor * 0.5f) / (pixelSize.height * 0.5f);
    
    CGPoint wholePixelTranslation = CGPointMake(roundf(translation.x * pixelViewportDimension) / pixelViewportDimension,
                                                roundf(translation.y * pixelViewportDimension) / pixelViewportDimension);
    
    zoomMatrix.m41 = wholePixelTranslation.x;
    zoomMatrix.m42 = wholePixelTranslation.y;
    
    //self.layer.sublayerTransform = zoomMatrix;
    
    CGRect rightPageFrame = _rightPageRect;
    rightPageFrame.origin.x -= _viewportLogicalSize.width * 0.5f;
    rightPageFrame.origin.y -= _viewportLogicalSize.height * 0.5f;
    rightPageFrame = CGRectApplyAffineTransform(rightPageFrame, CATransform3DGetAffineTransform(zoomMatrix));
    rightPageFrame.origin.x += _viewportLogicalSize.width * 0.5f;
    rightPageFrame.origin.y += _viewportLogicalSize.height * 0.5f;
    
    
    CGRect leftPageFrame = rightPageFrame;
    leftPageFrame.origin.x -= rightPageFrame.size.width;

    // Now, fix up the translation to make sure the pages are not outside where 
    // they're meant to be.
    CGFloat widthMargin = _viewportLogicalSize.width - (_rightPageRect.origin.x + _rightPageRect.size.width);
    CGFloat heightMargin = _rightPageRect.origin.y;
            
    CGPoint remainingTranslation = CGPointZero;
    
    CGFloat leftUnderflow = (_fitTwoPages ? leftPageFrame.origin.x : rightPageFrame.origin.x) - widthMargin;
    if(leftUnderflow > 0.0f) {
        rightPageFrame.origin.x -= leftUnderflow;
        leftPageFrame.origin.x -= leftUnderflow;
        zoomMatrix.m41 -= leftUnderflow;
        remainingTranslation.x += leftUnderflow;
    }
        
    CGFloat rightUnderflow = (_viewportLogicalSize.width - widthMargin) - (rightPageFrame.origin.x + rightPageFrame.size.width);
    if(rightUnderflow > 0.0f) {
        rightPageFrame.origin.x += rightUnderflow;
        leftPageFrame.origin.x += rightUnderflow;
        zoomMatrix.m41 += rightUnderflow;
        remainingTranslation.x -= rightUnderflow;
    }
    
    CGFloat topUnderflow = rightPageFrame.origin.y - heightMargin;
    if(topUnderflow > 0.0f) {
        leftPageFrame.origin.y -= topUnderflow;
        rightPageFrame.origin.y -= topUnderflow;
        zoomMatrix.m42 -= topUnderflow;
        remainingTranslation.y -= topUnderflow;
    }
    
    CGFloat bottomUnderflow = (_viewportLogicalSize.height - heightMargin) - (rightPageFrame.origin.y + rightPageFrame.size.height);
    if(bottomUnderflow > 0.0f) {
        leftPageFrame.origin.y += bottomUnderflow;
        rightPageFrame.origin.y += bottomUnderflow;
        zoomMatrix.m42 += bottomUnderflow;
        remainingTranslation.y += bottomUnderflow;
    }
    
    _zoomFactor = MIN(zoomMatrix.m11, zoomMatrix.m22);
    _zoomTranslation = CGPointMake(zoomMatrix.m41, zoomMatrix.m42);

    _zoomMatrix = zoomMatrix;
    _zoomMatrix.m42 = -zoomMatrix.m42; // OpenGL coordinates are upside-down compared to screen, so flip the y translation.
    
    rightPageFrame.origin.x *= pointViewportDimension;
    rightPageFrame.origin.y *= pointViewportDimension;
    rightPageFrame.size.width *= pointViewportDimension;
    rightPageFrame.size.height *= pointViewportDimension;
    
    leftPageFrame.origin.x *= pointViewportDimension;
    leftPageFrame.origin.y *= pointViewportDimension;
    leftPageFrame.size.width *= pointViewportDimension;
    leftPageFrame.size.height *= pointViewportDimension;
    
    _rightPageFrame = rightPageFrame;
    _leftPageFrame = leftPageFrame;
    
    [self didChangeValueForKey:@"leftPageFrame"];
    [self didChangeValueForKey:@"rightPageFrame"];
    
    [self setNeedsDraw];
    
    return remainingTranslation;
}

@end
