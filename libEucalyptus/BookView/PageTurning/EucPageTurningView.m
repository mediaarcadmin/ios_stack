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
#import <objc/runtime.h>
#import <tgmath.h>
#import "THBaseEAGLView.h"
#import "THOpenGLTexturePool.h"
#import "THGeometryUtils.h"
#import "THEmbeddedResourceManager.h"
#import "THRoundRects.h"
#import "THPair.h"
#import "EucPageTurningPageContentsInformation.h"

#define FOV_ANGLE ((GLfloat)10.0f)

@interface EucPageTurningView ()

@property (nonatomic, assign, readonly) CATransform3D zoomMatrix;
@property (nonatomic, assign) CGRect leftPageFrame;
@property (nonatomic, assign) CGRect rightPageFrame;

- (void)_calculateVertexNormals;    
//- (void)_accumulateForces;  // Not used - see comments around implementation.
- (void)_verlet;
- (BOOL)_satisfyConstraints;
- (BOOL)_satisfyPositioningConstraints;
- (void)_setupConstraints;
- (void)_recachePages;
- (CGFloat)_tapTurnMarginForView:(UIView *)view;
- (void)_setNeedsAccessibilityElementsRebuild;
- (CGPoint)_setZoomMatrixFromTranslation:(CGPoint)translation zoomFactor:(CGFloat)zoomFactor;
- (void)_prepareForTurnForwards:(BOOL)forwards;

- (void)_retextureForPanAndZoom;
- (void)_scheduleRetextureForPanAndZoom;
- (void)_cancelRetextureForPanAndZoom;

- (void)_setTranslation:(CGPoint)translation zoomFactor:(CGFloat)zoomFactor;

- (void)_refreshHighlightsForPageContentsIndex:(NSUInteger)index;

@end

@implementation EucPageTurningView

@synthesize delegate = _delegate;

@synthesize vibratesOnInvalidTurn = _vibratesOnInvalidTurn;

@synthesize viewDataSource = _viewDataSource;
@synthesize bitmapDataSource = _bitmapDataSource;

@synthesize twoUp = _twoUp;
@synthesize oddPagesOnRight = _oddPagesOnRight;
@synthesize zoomHandlingKind = _zoomHandlingKind;

@synthesize maxZoomFactor = _maxZoomFactor;
@synthesize minZoomFactor = _minZoomFactor;
@synthesize zoomMatrix = _zoomMatrix;
@synthesize rightPageFrame = _rightPageFrame;
@synthesize leftPageFrame = _leftPageFrame;
@synthesize unzoomedRightPageFrame = _unzoomedRightPageFrame;
@synthesize unzoomedLeftPageFrame = _unzoomedLeftPageFrame;
@synthesize zoomedTextureWidth = _zoomedTextureWidth;

@synthesize shininess = _shininess;

@synthesize constantAttenuationFactor = _constantAttenuationFactor;
@synthesize linearAttenutaionFactor = _linearAttenutaionFactor;

@synthesize lightPosition = _lightPosition;

@synthesize pageAspectRatio = _pageAspectRatio;
@synthesize animatedZoomFactor = _modelZoomFactor;
@synthesize animatedTranslation = _modelTranslation;

@synthesize focusedPageIndex = _focusedPageIndex;

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
    _zoomedTextureWidth = 1024;
    _minZoomFactor = 1.0f;
    _maxZoomFactor = 14.0f;
    _zoomFactor = 1.0f;
    _zoomMatrix = CATransform3DIdentity;
	_animationIndex = -1;
    
    _vibratesOnInvalidTurn = YES;
    
    EAGLContext *eaglContext = self.eaglContext;
    _texturePool = [[THOpenGLTexturePool alloc] initWithMainThreadContext:eaglContext];

    [eaglContext thPush];
    
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
    _bookEdgeTexture = [_texturePool unusedTexture];
    glBindTexture(GL_TEXTURE_2D, _bookEdgeTexture);
    texImage2DPVRTC(0, 4, 0, 512, [bookEdge bytes]);
    [bookEdge release];
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    _alphaWhiteZoomedContent = [_texturePool unusedTexture];
    glBindTexture(GL_TEXTURE_2D, _alphaWhiteZoomedContent);
    uint32_t whiteSquare[4] = { 0x00000000, 0x00000000, 0x00000000, 0x00000000 };
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 2, 2, 0, GL_RGBA, GL_UNSIGNED_BYTE, &whiteSquare);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    
    _grayThumbnail = [_texturePool unusedTexture];
    glBindTexture(GL_TEXTURE_2D, _grayThumbnail);
    uint32_t graySquare[4] = { 0xff888888, 0xffffffff, 0xffffffff, 0xff888888 };
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 2, 2, 0, GL_RGBA, GL_UNSIGNED_BYTE, &graySquare);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        
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
    
    _textureGenerationOperationQueue = [[NSOperationQueue alloc] init];
	[_textureGenerationOperationQueue setMaxConcurrentOperationCount:1];
    if([_textureGenerationOperationQueue respondsToSelector:@selector(setName:)]) {
        _textureGenerationOperationQueue.name = @"Texture Generation Queue";
    }

    self.multipleTouchEnabled = YES;
    //self.exclusiveTouch = YES;
    self.opaque = YES;
    self.userInteractionEnabled = YES;
    
    [eaglContext thPop];
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
    [_textureGenerationOperationQueue cancelAllOperations];
    [_textureGenerationOperationQueue waitUntilAllOperationsAreFinished];
    [_textureGenerationOperationQueue release];
    
    [_bitmapDataSourceLock release];
    
    [self.eaglContext thPush];
    
    for(NSUInteger i = 0; i < sizeof(_pageContentsInformation) / sizeof(EucPageTurningPageContentsInformation *); ++i) {
        EucPageTurningPageContentsInformation *information = _pageContentsInformation[i];
        _pageContentsInformation[i] = nil;
        [information release];
    }        
    
    if(_meshTextureCoordinateBuffer) {
        glDeleteBuffers(1, &_meshTextureCoordinateBuffer);
    }
    
    if(_triangleStripIndicesBuffer) {
        glDeleteBuffers(1, &_triangleStripIndicesBuffer);
    }
        
    if(_bookEdgeTexture) {
        glDeleteTextures(1, &_bookEdgeTexture);
    }
    if(_grayThumbnail) {
        glDeleteTextures(1, &_grayThumbnail);
    }
    if(_alphaWhiteZoomedContent) {
        glDeleteTextures(1, &_alphaWhiteZoomedContent);
    }
    if(_blankPageTexture) {
        glDeleteTextures(1, &_blankPageTexture);
    }
	
    [_texturePool release];    

    if(_program) {
        glDeleteProgram(_program);
    }
    
    [self.eaglContext thPop];
    
    [_accessibilityElements release];
    [_nextPageTapZone release];
    
    [super dealloc];
}

- (void)_layoutPages
{
    CGSize size = self.bounds.size;
    if(!CGSizeEqualToSize(size, _lastLayoutBoundsSize) ||
       _lastLayoutTwoUp != _twoUp) {
        // Won't be needing any of these.
        [_textureGenerationOperationQueue cancelAllOperations];
        NSUInteger pageContentsInformationCount = sizeof(_pageContentsInformation) / sizeof(EucPageTurningPageContentsInformation *);
        for(NSUInteger i = 0; i < pageContentsInformationCount; ++i) {
            _pageContentsInformation[i].currentTextureGenerationOperation = nil;
            _pageContentsInformation[i].currentZoomedTextureGenerationOperation = nil;
            _pageContentsInformation[i].zoomedTexture = 0;
        }    

        [self willChangeValueForKey:@"zoomMatrix"];
        [self willChangeValueForKey:@"rightPageFrame"];
        [self willChangeValueForKey:@"leftPageFrame"];
        [self willChangeValueForKey:@"unzoomedRightPageFrame"];
        [self willChangeValueForKey:@"unzoomedLeftPageFrame"];
        
        // We'll re-set this at the end.
        NSUInteger oldMinZoomFactor = _minZoomFactor;
        _minZoomFactor = 1.0f;
    
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
            if(!_twoUp || size.width < size.height) {
                aspectRatio = size.width / size.height;
            } else {
                // If we're landscape, and in fit-two mode, use the portrait 
                // aspect for pages.
                aspectRatio = size.height / size.width;
            }
        }
        
        CGFloat availableWidth;
        if(_twoUp) {
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
        
        if(_twoUp) {
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
                
        [self _setupConstraints];
                
        [self _setZoomMatrixFromTranslation:CGPointZero zoomFactor:1.0f];
        
        _unzoomedLeftPageFrame = _leftPageFrame;
        _unzoomedRightPageFrame = _rightPageFrame;        
        
        if(_bitmapDataSource) {
            EucPageTurningPageContentsInformation *oldPageContentsInformation[pageContentsInformationCount];
            
            memcpy(oldPageContentsInformation, _pageContentsInformation, sizeof(_pageContentsInformation));
            for(NSUInteger i = 0; i < pageContentsInformationCount; ++i) {
                _pageContentsInformation[i] = nil;
            }    
            
            if(_twoUp) {
                NSUInteger rightPageIndex = _focusedPageIndex;
                if(_oddPagesOnRight) {
                    if((rightPageIndex % 2) == 0) {
                        rightPageIndex++;
                    }                
                } else {
                    if((rightPageIndex % 2) == 1) {
                        rightPageIndex++;
                    }            
                }
                
                for(NSUInteger i = 0; i < pageContentsInformationCount; ++i) {
                    NSUInteger prospectivePageIndex = oldPageContentsInformation[i] ? oldPageContentsInformation[i].pageIndex : NSUIntegerMax;
                    if(prospectivePageIndex == rightPageIndex - 3) {
                        _pageContentsInformation[0] = [oldPageContentsInformation[i] retain];
                    } else if(prospectivePageIndex == rightPageIndex - 2) {
                        _pageContentsInformation[1] = [oldPageContentsInformation[i] retain];
                    } else if(prospectivePageIndex == rightPageIndex - 1) {
                        _pageContentsInformation[2] = [oldPageContentsInformation[i] retain];
                    } else if(prospectivePageIndex == rightPageIndex) { 
                        _pageContentsInformation[3] = [oldPageContentsInformation[i] retain];
                    } else if(prospectivePageIndex == rightPageIndex + 1) { 
                        _pageContentsInformation[4] = [oldPageContentsInformation[i] retain];
                    } else if(prospectivePageIndex == rightPageIndex + 2) { 
                        _pageContentsInformation[5] = [oldPageContentsInformation[i] retain];
                    }
                }
            } else {
                NSUInteger newPageIndex = _focusedPageIndex;
                for(NSUInteger i = 0; i < pageContentsInformationCount; ++i) {
                    NSUInteger prospectivePageIndex = oldPageContentsInformation[i] ? oldPageContentsInformation[i].pageIndex : NSUIntegerMax;
                    if(prospectivePageIndex == newPageIndex - 1) {
                        _pageContentsInformation[1] = [oldPageContentsInformation[i] retain];
                    } else if(prospectivePageIndex == newPageIndex) { 
                        _pageContentsInformation[3] = [oldPageContentsInformation[i] retain];
                    } else if(prospectivePageIndex == newPageIndex + 1) { 
                        _pageContentsInformation[5] = [oldPageContentsInformation[i] retain];
                    }
                }
            }

            for(NSUInteger i = 0; i < pageContentsInformationCount; ++i) {
                [oldPageContentsInformation[i] release];
                if(_pageContentsInformation[i]) {
                    [self _refreshHighlightsForPageContentsIndex:i];
                }
            }    
                            
            _recacheFlags[0] = YES;
            _recacheFlags[1] = YES;
            _recacheFlags[2] = YES; 
            _recacheFlags[3] = YES;
            _recacheFlags[4] = YES; 
            _recacheFlags[5] = YES; 
            [self _recachePages];
        }
        
        _lastLayoutBoundsSize = size;
        _lastLayoutTwoUp = _twoUp;
        
        if(!_minZoomFactor != oldMinZoomFactor) {
            _minZoomFactor = oldMinZoomFactor;
            [self _setZoomMatrixFromTranslation:CGPointZero zoomFactor:oldMinZoomFactor];
        }
        
        [self setNeedsDraw];
        
        [self didChangeValueForKey:@"unzoomedLeftPageFrame"];
        [self didChangeValueForKey:@"unzoomedRightPageFrame"];
        [self didChangeValueForKey:@"leftPageFrame"];
        [self didChangeValueForKey:@"rightPageFrame"];
        [self didChangeValueForKey:@"zoomMatrix"];        
    }
}    

- (void)waitForAllPageImagesToBeAvailable
{
    [_textureGenerationOperationQueue waitUntilAllOperationsAreFinished];
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

- (GLuint)_createTextureFromRGBABitmapContext:(CGContextRef)context
{
    size_t contextWidth = CGBitmapContextGetWidth(context);
    size_t contextHeight = CGBitmapContextGetHeight(context);
    
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
    
    EAGLContext *eaglContext = [_texturePool checkOutEAGLContext];
    [eaglContext thPush];
    
    GLuint textureRef = [_texturePool unusedTexture];

    glBindTexture(GL_TEXTURE_2D, textureRef); 

    glPixelStorei (GL_UNPACK_ALIGNMENT, 1);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, contextWidth, contextHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);    
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);   
    
    [eaglContext thPop];
    [_texturePool checkInEAGLContext];

    if(textureContext) {
        CGContextRelease(textureContext);
        free(textureData);
    }
    
    THLog(@"Created Texture of size (%ld, %ld)", (long)contextWidth, (long)contextHeight);
    
    return textureRef;
}

- (GLuint)_createTextureFrom:(id)viewOrImage invertingLuminance:(BOOL)invertingLuminance
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
    
    GLuint ret = [self _createTextureFromRGBABitmapContext:textureContext];

    CGContextRelease(textureContext);
    free(textureData);
    
    THLog(@"Created Texture of scaled size (%f, %f) from point size (%f, %f)", scaledSize.width, scaledSize.height, rawSize.width, rawSize.height);

    return ret;
}

- (GLuint)_createTextureFrom:(id)viewOrImage
{
    return [self _createTextureFrom:viewOrImage invertingLuminance:NO];
}

- (void)setPageTexture:(UIImage *)pageTexture isDark:(BOOL)isDark
{
    _blankPageTexture = [self _createTextureFrom:pageTexture
                              invertingLuminance:isDark];
    _pageTextureIsDark = isDark;
}

- (void)_setView:(UIView *)view forInternalPageOffsetPage:(int)page forceRefresh:(BOOL)forceRefresh
{
    if(forceRefresh || _pageContentsInformation[page].view != view) {
        UIView *oldView = [_pageContentsInformation[page].view retain]; // In case it's the same as the new view.
        [_pageContentsInformation[page] release];
        if(view) {
            _pageContentsInformation[page] = [[EucPageTurningPageContentsInformation alloc] initWithTexturePool:_texturePool];
            _pageContentsInformation[page].view = view;
            _pageContentsInformation[page].texture = [self _createTextureFrom:view];
        } else {
            _pageContentsInformation[page] = nil;
        }
        [oldView release];
    }
}

- (void)_setView:(UIView *)view forInternalPageOffsetPage:(int)page
{
    [self _setView:view forInternalPageOffsetPage:page forceRefresh:NO];
}

- (UIView *)currentPageView
{
    return _pageContentsInformation[3].view;
}

- (void)setCurrentPageView:(UIView *)newCurrentView;
{
    if(newCurrentView != self.currentPageView) {
        if(!_twoUp) {
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
    _rightFlatPageContentsIndex = 3;
}

- (NSArray *)pageViews
{
    NSMutableArray *views = [[NSMutableArray alloc] initWithCapacity:6];
    for(NSUInteger i = 0; i < sizeof(_pageContentsInformation) / sizeof(EucPageTurningPageContentsInformation *); ++i) {
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
    if(_twoUp && onLeft) {
        internalPageOffset = 2;
    }
    if(newCurrentView != _pageContentsInformation[internalPageOffset].view) {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];

        NSInteger internalPageOffsetForNewViewBeforeTurn;
        if(forwards) {
            internalPageOffsetForNewViewBeforeTurn = 5;
            if(_twoUp && onLeft) {
                internalPageOffsetForNewViewBeforeTurn = 4;
            }
        } else {
            internalPageOffsetForNewViewBeforeTurn = 1;
            if(_twoUp && onLeft) {
                internalPageOffsetForNewViewBeforeTurn = 0;
            }            
        }
        
        [self _setView:newCurrentView forInternalPageOffsetPage:internalPageOffsetForNewViewBeforeTurn];
        if(_twoUp) {
            if(onLeft) {
                [self _setView:[_viewDataSource pageTurningView:self nextViewForView:newCurrentView]
     forInternalPageOffsetPage:internalPageOffsetForNewViewBeforeTurn + 1];
            } else {
                [self _setView:[_viewDataSource pageTurningView:self previousViewForView:newCurrentView]
     forInternalPageOffsetPage:internalPageOffsetForNewViewBeforeTurn - 1];
            }
        }
        
        [self _prepareForTurnForwards:forwards];

        _viewportTouchPoint = CGPointMake(forwards ? _viewportLogicalSize.width : 0.0f, _viewportLogicalSize.height * 0.5f);
        _touchVelocity = CGPointMake(forwards ? -0.4f : 0.4f, 0.0f);
        
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
        
        _animationFlags |= EucPageTurningViewAnimationFlagsAutomaticTurn;
        self.animating = YES;
    }
}

- (void)refreshView:(UIView *)view
{
    for(NSUInteger i = 0; i < sizeof(_pageContentsInformation) / sizeof(EucPageTurningPageContentsInformation *); ++i) {
        if(view == _pageContentsInformation[i].view) {
            [self _setView:view forInternalPageOffsetPage:i forceRefresh:YES];
            break;
        }
    }
}

- (NSUInteger)leftPageIndex 
{
	if (_pageContentsInformation[2]) {
		return _pageContentsInformation[2].pageIndex;
	}
    return NSUIntegerMax;
}

- (NSUInteger)rightPageIndex 
{
	if (_pageContentsInformation[3]) {
		return _pageContentsInformation[3].pageIndex;
	}
    return NSUIntegerMax;
}

- (void)setBitmapDataSource:(id <EucPageTurningViewBitmapDataSource>)bitmapDataSource
{
    if(!_bitmapDataSourceLock) {
        _bitmapDataSourceLock = [[NSLock alloc] init];
    }
    [_bitmapDataSourceLock lock];
    _bitmapDataSource = bitmapDataSource;
    [_bitmapDataSourceLock unlock];
}

- (THPair *)_bitmapDataAndSizeForPageAtIndex:(NSUInteger)index
                                  inPageRect:(CGRect)pageRect
                                      ofSize:(CGSize)size
                                   alphaBled:(BOOL)alphaBled
{
    id memoryContext = nil;
    
    CGContextRef pageBitmapContext;
	THPair *bitmapPair = nil;
    
    [_bitmapDataSourceLock lock];
    if(_bitmapDataSource) {
		if([_bitmapDataSource respondsToSelector:@selector(pageTurningView:RGBABitmapContextForPageAtIndex:fromRect:minSize:getContext:)]) {
            pageBitmapContext = [_bitmapDataSource pageTurningView:self
                                   RGBABitmapContextForPageAtIndex:index
                                                          fromRect:pageRect
                                                           minSize:size
                                                        getContext:&memoryContext];
            [memoryContext retain]; // We'll release it when we're done, below.
        } else {
            pageBitmapContext = [_bitmapDataSource pageTurningView:self
                                   RGBABitmapContextForPageAtIndex:index
                                                          fromRect:pageRect
                                                           minSize:size];
            
        }
        
        size_t contextWidth = CGBitmapContextGetWidth(pageBitmapContext);
        size_t contextHeight = CGBitmapContextGetHeight(pageBitmapContext);
        CGSize correctedSize = CGSizeMake(CGBitmapContextGetWidth(pageBitmapContext), CGBitmapContextGetHeight(pageBitmapContext));
        if(THWillLog()) {
            if(!CGSizeEqualToSize(correctedSize, size)) {
                THLog(@"Generated texture = wanted %@, got %@", NSStringFromCGSize(size), NSStringFromCGSize(correctedSize));
            }
        }
        NSUInteger bufferLength = contextWidth * contextHeight * 4;
        
        if(alphaBled) {
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGContextSetStrokeColorSpace(pageBitmapContext, colorSpace);
            CGColorSpaceRelease(colorSpace);
            CGFloat whiteAlpha[4] = { 1.0f, 1.0f, 1.0f, 0.0f };
            CGContextSetStrokeColor(pageBitmapContext, whiteAlpha);
            CGContextSetBlendMode(pageBitmapContext, kCGBlendModeCopy);
            CGContextStrokeRectWithWidth(pageBitmapContext, CGRectMake(0.5f, 0.5f, correctedSize.width - 1.0f, correctedSize.height - 1.0f), 1.0f);
        }
        
        CGContextRef textureContext = NULL;
        unsigned char *textureData;
        BOOL dataIsNonContiguous = CGBitmapContextGetBytesPerRow(pageBitmapContext) != contextWidth * 4;
        if(dataIsNonContiguous || (textureData = CGBitmapContextGetData(pageBitmapContext)) == NULL) {
            // We need to generate contiguous data to upload, and we need to be
            // able to access the context's backing data.
            
            THLog(@"Inefficient bitmap handling - having to copy image in context returned by RGBABitmapContextForPageAtIndex in order to to upload")
            
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            textureData = malloc(bufferLength);
            textureContext = CGBitmapContextCreate(NULL, contextWidth, contextHeight, 8, contextWidth * 4, 
                                                   colorSpace, kCGImageAlphaPremultipliedLast);
            CGContextSetBlendMode(textureContext, kCGBlendModeCopy);
            
            CGImageRef image = CGBitmapContextCreateImage(pageBitmapContext);
            CGContextDrawImage(textureContext, CGRectMake(0.0f, 0.0f, contextWidth, contextHeight), image);
            CGImageRelease(image);
            CGColorSpaceRelease(colorSpace);
        } 
                
        bitmapPair = [THPair pairWithFirst:[NSData dataWithBytesNoCopy:textureData
                                                                length:bufferLength
                                                          freeWhenDone:textureContext != NULL]
                                    second:[NSValue valueWithCGSize:correctedSize]];
        
        if(textureContext) {
            if(memoryContext) {
                // We're finished with this because we're using our own context now.
                [memoryContext release];
            }
            
            CGContextRelease(textureContext);
            // The backing textureData is owned by the NSData in the pair we're 
            // returning now, so don't free it here.
        } else {
            if(memoryContext) {
                // Keep the memory context we've been handed alive for as long
                // as its accociated NSData.
                objc_setAssociatedObject(bitmapPair.first, memoryContext, @"EucPageTurningViewBitmapMemoryContext", OBJC_ASSOCIATION_RETAIN);
                [memoryContext release];
            }
        }
    }
    [_bitmapDataSourceLock unlock];

    return bitmapPair;
}

- (void)_setupBitmapPage:(NSUInteger)newPageIndex 
   forInternalPageOffset:(NSUInteger)pageOffset
                 minSize:(CGSize)minSize
{
    THLog(@"requesting Texture of size (%f, %f)", minSize.width, minSize.height);

    CGRect thisPageRect = [_bitmapDataSource pageTurningView:self 
                                   contentRectForPageAtIndex:newPageIndex];
    if(!CGRectIsEmpty(thisPageRect)) {
        if(!_pageContentsInformation[pageOffset] || _pageContentsInformation[pageOffset].pageIndex != newPageIndex) {
            [_pageContentsInformation[pageOffset] release];
            _pageContentsInformation[pageOffset] = [[EucPageTurningPageContentsInformation alloc] initWithTexturePool:_texturePool];
            _pageContentsInformation[pageOffset].pageIndex = newPageIndex;
        }

        if(!_pageContentsInformation[pageOffset].texture) {
            UIImage *fastImage = nil;
            if([_bitmapDataSource respondsToSelector:@selector(pageTurningView:fastUIImageForPageAtIndex:)]) {
                fastImage = [_bitmapDataSource pageTurningView:self fastUIImageForPageAtIndex:newPageIndex];
            }
            
            if(fastImage) {
                _pageContentsInformation[pageOffset].texture = [self _createTextureFrom:fastImage];
            }
        }
        
        EucPageTurningTextureGenerationOperation *textureGenerationOperation = [[EucPageTurningTextureGenerationOperation alloc] init];
        textureGenerationOperation.delegate = self;
        textureGenerationOperation.texturePool = _texturePool;
        textureGenerationOperation.pageIndex = newPageIndex;
        textureGenerationOperation.textureRect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
        textureGenerationOperation.isZoomed = NO;
		
        NSInvocation *textureUploadInvocation = [NSInvocation invocationWithMethodSignature:
                                                 [self methodSignatureForSelector:@selector(_bitmapDataAndSizeForPageAtIndex:inPageRect:ofSize:alphaBled:)]];
        textureUploadInvocation.selector = @selector(_bitmapDataAndSizeForPageAtIndex:inPageRect:ofSize:alphaBled:);
        textureUploadInvocation.target = self;
        [textureUploadInvocation setArgument:&newPageIndex atIndex:2];
        [textureUploadInvocation setArgument:&thisPageRect atIndex:3];
        [textureUploadInvocation setArgument:&minSize atIndex:4];
        BOOL no = NO;
        [textureUploadInvocation setArgument:&no atIndex:5];
		
        textureGenerationOperation.generationInvocation = textureUploadInvocation;
        
        _pageContentsInformation[pageOffset].currentTextureGenerationOperation = textureGenerationOperation;
        
        [_textureGenerationOperationQueue addOperation:textureGenerationOperation];
		[textureGenerationOperation release];
        [self _refreshHighlightsForPageContentsIndex:pageOffset];
    } else {
        [_pageContentsInformation[pageOffset] release];
        _pageContentsInformation[pageOffset] = nil;
    }
}

- (void)_setupBitmapPage:(NSUInteger)newPageIndex 
   forInternalPageOffset:(NSUInteger)pageOffset
{
    CGSize minSize = _unzoomedRightPageFrame.size;
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
	BOOL doTurn = NO;
	
	if (_twoUp) {
		if((!_pageContentsInformation[2] || _pageContentsInformation[2].pageIndex != newPageIndex) &&
		   (!_pageContentsInformation[3] || _pageContentsInformation[3].pageIndex != newPageIndex)) {
			doTurn = YES;
		}
	} else {
		if (!_pageContentsInformation[3] || _pageContentsInformation[3].pageIndex != newPageIndex) {
			doTurn = YES;
		}
	}
        
	if (doTurn) {
        BOOL forwards = newPageIndex > _focusedPageIndex;
        
        NSUInteger rightPageIndex = newPageIndex;
        if(_twoUp) {
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

            if(_pageContentsInformation[forwards ? 5 : 1].pageIndex != rightPageIndex) {
                [self _setupBitmapPage:rightPageIndex forInternalPageOffset:forwards ? 5 : 1];
            } 
            if(_pageContentsInformation[forwards ? 4 : 0].pageIndex != rightPageIndex - 1){
                [self _setupBitmapPage:rightPageIndex - 1 forInternalPageOffset:forwards ? 4 : 0];
            }
            
            [self _prepareForTurnForwards:forwards];

            if(forwards) {
                _viewportTouchPoint = CGPointMake(_rightPageRect.size.width, _viewportLogicalSize.height * 0.5f);
                _touchVelocity = CGPointMake(-0.4f, 0.0f);
            } else {
                _viewportTouchPoint = CGPointMake(_rightPageFrame.origin.x > 0.0f ? -_leftPageRect.size.width : 0.0f, _viewportLogicalSize.height * 0.5f);
                _touchVelocity = CGPointMake(0.4f, 0.0f);
            }
            
            NSUInteger pageCount;
            if(forwards) {
                pageCount = rightPageIndex - _pageContentsInformation[3].pageIndex;
            } else {
                if(_twoUp) {
                    pageCount = _pageContentsInformation[2].pageIndex - rightPageIndex;
                } else {
                    pageCount = _pageContentsInformation[3].pageIndex - rightPageIndex;
                }
            }
            
            if(_twoUp) {
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
            		
            _animationFlags |= EucPageTurningViewAnimationFlagsAutomaticTurn;
            self.animating = YES;
        } else {
            [self _setupBitmapPage:rightPageIndex forInternalPageOffset:3];
            if(_twoUp) {
                [self _setupBitmapPage:rightPageIndex - 1 forInternalPageOffset:2];
            }
            
            _rightFlatPageContentsIndex = 3;
            
            _recacheFlags[1] = YES;
            _recacheFlags[5] = YES; 
            if(_twoUp) {
                _recacheFlags[0] = YES;
                _recacheFlags[4] = YES; 
            }
            [self _recachePages];
            
            [self setNeedsDraw];
        }
        [self _retextureForPanAndZoom];
    } 
    
    _focusedPageIndex = newPageIndex;
}

- (void)refreshPageAtIndex:(NSUInteger)pageIndex {
    for(NSUInteger i = 0; i < sizeof(_pageContentsInformation) / sizeof(EucPageTurningPageContentsInformation *); ++i) {
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
    // Clear out the zoomed textures for the old frontmost pages.
    // Pending generations operations will be cancelled in the setters when 
    // they're set to nil.  Any that /do/ complete (because they're already
    // executing) will be ignored in the callbacks unless they're for the 
    // main, non-zoomed, texture.
    _pageContentsInformation[2].currentZoomedTextureGenerationOperation = nil;
    _pageContentsInformation[2].zoomedTexture = 0;
    _pageContentsInformation[3].currentZoomedTextureGenerationOperation = nil;
    _pageContentsInformation[3].zoomedTexture = 0;

    // Now cycle the pages.
    if(forwards) {
        EucPageTurningPageContentsInformation *tempView0 = _pageContentsInformation[0];
        EucPageTurningPageContentsInformation *tempView1 = _pageContentsInformation[1];
        _pageContentsInformation[0] = _pageContentsInformation[2];
        _pageContentsInformation[1] = _pageContentsInformation[3];
        _pageContentsInformation[2] = _pageContentsInformation[4];
        _pageContentsInformation[3] = _pageContentsInformation[5];
        _pageContentsInformation[4] = tempView0;
        _pageContentsInformation[5] = tempView1;
    } else {
        EucPageTurningPageContentsInformation *tempView4 = _pageContentsInformation[4];
        EucPageTurningPageContentsInformation *tempView5 = _pageContentsInformation[5];
        _pageContentsInformation[4] = _pageContentsInformation[2];
        _pageContentsInformation[5] = _pageContentsInformation[3];
        _pageContentsInformation[2] = _pageContentsInformation[0];
        _pageContentsInformation[3] = _pageContentsInformation[1];
        _pageContentsInformation[0] = tempView4;
        _pageContentsInformation[1] = tempView5;
    }
    
    [self _retextureForPanAndZoom];
}

- (void)drawView 
{        
    [super drawView];
	        
    BOOL animating = self.isAnimating;

    if(animating) {
        NSParameterAssert(_animationFlags != EucPageTurningViewAnimationFlagsNone);
    } else {
        NSParameterAssert(_animationFlags == EucPageTurningViewAnimationFlagsNone);
    }
    
    EucPageTurningViewAnimationFlags postDrawAnimationFlags = _animationFlags;
	
    if((_animationFlags & EucPageTurningViewAnimationFlagsDragTurn) ||
       (_animationFlags & EucPageTurningViewAnimationFlagsAutomaticTurn)) {
        //[self _accumulateForces]; // Not used - see comments around implementation.
        [self _verlet];
        BOOL shouldStopAnimating = [self _satisfyConstraints];
        [self _calculateVertexNormals];
        if(shouldStopAnimating) {
            postDrawAnimationFlags &= ~EucPageTurningViewAnimationFlagsDragTurn;
            postDrawAnimationFlags &= ~EucPageTurningViewAnimationFlagsAutomaticTurn;
        }
    }
	
	if(_animationFlags & EucPageTurningViewAnimationFlagsAutomaticPositioning) {
		BOOL shouldStopAnimating = [self _satisfyPositioningConstraints];
        if(shouldStopAnimating) {
            postDrawAnimationFlags &= ~EucPageTurningViewAnimationFlagsAutomaticPositioning;
        }
    }
    
    if(_animationFlags & EucPageTurningViewAnimationFlagsDragScroll) {
        if(!_dragUnderway) {
            _touchVelocity.x /= 1.5f;
            _touchVelocity.y /= 1.5f;
            if(fabsf(_touchVelocity.x * _viewportToBoundsPointsTransform.a) < 0.1f &&
               fabsf(_touchVelocity.y * _viewportToBoundsPointsTransform.d) < 0.1f) {
                postDrawAnimationFlags &= ~EucPageTurningViewAnimationFlagsDragScroll;
                _touchVelocity = CGPointZero;
            } else {
                CGPoint newTranslation = _scrollTranslation;
                newTranslation.x += _touchVelocity.x * _zoomFactor;
                newTranslation.y += _touchVelocity.y * _zoomFactor;
                [self _setZoomMatrixFromTranslation:newTranslation zoomFactor:_zoomFactor];
            }
        }
    }    
    	    
    EAGLContext *eaglContext = self.eaglContext;
    [eaglContext thPush];
    
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
	// Experimenting for the moment...
    glClearColor(0.0, 0.0, 0.0, 1.0);   // Black
    //glClearColor(0.8, 0.8, 0.8, 1.0); // Gray
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
    glUniform1i(glGetUniformLocation(_program, "sZoomedContentsTexture"), 2);
    glUniform1i(glGetUniformLocation(_program, "sHighlightTexture"), 3);

    // 'disable' the zoomed texture
    CGRect invisibleZoomedTextureRect = { { -1.0f, -1.0f } , { -1.0f, -1.0f } };
    glUniform4fv(glGetUniformLocation(_program, "uZoomedTextureRect"), 4, (GLfloat *)&invisibleZoomedTextureRect);
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, _alphaWhiteZoomedContent);
    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_2D, _alphaWhiteZoomedContent);

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
    
    
    // Draw the right-hand (or only) flat page.
    if(_pageContentsInformation[_rightFlatPageContentsIndex]) {
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, _pageContentsInformation[_rightFlatPageContentsIndex].texture ?: _grayThumbnail);    
        if(_pageContentsInformation[_rightFlatPageContentsIndex].zoomedTexture && _zoomFactor > 1.0f) {
            glActiveTexture(GL_TEXTURE2);
            glBindTexture(GL_TEXTURE_2D, _pageContentsInformation[_rightFlatPageContentsIndex].zoomedTexture); 
            CGRect zoomedTextureRect = _pageContentsInformation[_rightFlatPageContentsIndex].zoomedTextureRect;
            glUniform4fv(glGetUniformLocation(_program, "uZoomedTextureRect"), 4, 
                         (GLfloat *)&zoomedTextureRect);
        }
        if(_pageContentsInformation[_rightFlatPageContentsIndex].highlightTexture) {
            glActiveTexture(GL_TEXTURE3);
            glBindTexture(GL_TEXTURE_2D, _pageContentsInformation[_rightFlatPageContentsIndex].highlightTexture); 
        }

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _triangleStripIndicesBuffer);
        glDrawElements(GL_TRIANGLE_STRIP, TRIANGLE_STRIP_COUNT, GL_UNSIGNED_BYTE, 0);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        
        if(_pageContentsInformation[_rightFlatPageContentsIndex].highlightTexture) {
            glActiveTexture(GL_TEXTURE3);
            glBindTexture(GL_TEXTURE_2D, _alphaWhiteZoomedContent); 
        }                
        if(_pageContentsInformation[_rightFlatPageContentsIndex].zoomedTexture && _zoomFactor > 1.0f) {
            glUniform4fv(glGetUniformLocation(_program, "uZoomedTextureRect"), 4, (GLfloat *)&invisibleZoomedTextureRect);
            glActiveTexture(GL_TEXTURE2);
            glBindTexture(GL_TEXTURE_2D, _alphaWhiteZoomedContent);
        }
    }
    
    if(_twoUp && _rightPageFrame.origin.x > 0.0f) {
        NSInteger leftFlatPageContentsIndex = _rightFlatPageContentsIndex - (((postDrawAnimationFlags & EucPageTurningViewAnimationFlagsDragTurn) ||
                                                                              (postDrawAnimationFlags & EucPageTurningViewAnimationFlagsAutomaticTurn)) ? 3 : 1);
        if(leftFlatPageContentsIndex >= 0 && _pageContentsInformation[leftFlatPageContentsIndex]) {
            CATransform3D oldModelViewMatrix = modelViewMatrix;
            modelViewMatrix = CATransform3DRotate(modelViewMatrix, (GLfloat)M_PI, 0, 1, 0);
            glUniformMatrix4fv(glGetUniformLocation(_program, "uModelviewMatrix"), sizeof(modelViewMatrix) / sizeof(GLfloat), GL_FALSE, (GLfloat *)&modelViewMatrix);
            CATransform3D oldNormalMatrix = normalMatrix;
            normalMatrix = THCATransform3DTranspose(CATransform3DInvert(modelViewMatrix));
            glUniformMatrix4fv(glGetUniformLocation(_program, "uNormalMatrix"), sizeof(normalMatrix) / sizeof(GLfloat), GL_FALSE, (GLfloat *)&normalMatrix);
            
            if(_twoUp) {
                glUniform1i(glGetUniformLocation(_program, "uFlipContentsX"), 1);
            } else {
                glUniform1f(glGetUniformLocation(_program, "uContentsBleed"), 0.2f);
            }
            
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(GL_TEXTURE_2D, _pageContentsInformation[leftFlatPageContentsIndex].texture ?: _grayThumbnail);
            if(_pageContentsInformation[leftFlatPageContentsIndex].zoomedTexture && _zoomFactor > 1.0f) {
                glActiveTexture(GL_TEXTURE2);
                glBindTexture(GL_TEXTURE_2D, _pageContentsInformation[leftFlatPageContentsIndex].zoomedTexture);    
                CGRect zoomedTextureRect = _pageContentsInformation[leftFlatPageContentsIndex].zoomedTextureRect;
                glUniform4fv(glGetUniformLocation(_program, "uZoomedTextureRect"), 4, 
                             (GLfloat *)&zoomedTextureRect);
            }
            if(_pageContentsInformation[leftFlatPageContentsIndex].highlightTexture) {
                glActiveTexture(GL_TEXTURE3);
                glBindTexture(GL_TEXTURE_2D, _pageContentsInformation[leftFlatPageContentsIndex].highlightTexture);    
            }                
            
            glCullFace(GL_FRONT);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _triangleStripIndicesBuffer);
            glDrawElements(GL_TRIANGLE_STRIP, TRIANGLE_STRIP_COUNT, GL_UNSIGNED_BYTE, 0);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
            glCullFace(GL_BACK);

            
            if(_pageContentsInformation[leftFlatPageContentsIndex].highlightTexture) {
                glActiveTexture(GL_TEXTURE3);
                glBindTexture(GL_TEXTURE_2D, _alphaWhiteZoomedContent); 
            }                                
            if(_pageContentsInformation[leftFlatPageContentsIndex].zoomedTexture && _zoomFactor > 1.0f) {
                glUniform4fv(glGetUniformLocation(_program, "uZoomedTextureRect"), 4, (GLfloat *)&invisibleZoomedTextureRect);
                glActiveTexture(GL_TEXTURE2);
                glBindTexture(GL_TEXTURE_2D, _alphaWhiteZoomedContent);
            }                                        
            
            if(_twoUp) {
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
    
    if((postDrawAnimationFlags & EucPageTurningViewAnimationFlagsDragTurn) ||
       (postDrawAnimationFlags & EucPageTurningViewAnimationFlagsAutomaticTurn)) {
        // If we're animating, we have a curved page to draw on top.
        
        // Clear the depth buffer so that this page wins if it has coordinates 
        // that conincide with the flat page.
        glClear(GL_DEPTH_BUFFER_BIT);
		                        
        const THVec3 *pageVertices, *pageVertexNormals;        
        pageVertices = (THVec3 *)_pageVertices;
        pageVertexNormals = (THVec3 *)_pageVertexNormals;
        
        glVertexAttribPointer(glGetAttribLocation(_program, "aPosition"), 3, GL_FLOAT, GL_FALSE, 0, pageVertices);
        glVertexAttribPointer(glGetAttribLocation(_program, "aNormal"), 3, GL_FLOAT, GL_FALSE, 0, pageVertexNormals);
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, _pageContentsInformation[_rightFlatPageContentsIndex-2].texture ?: _grayThumbnail);
        if(_pageContentsInformation[_rightFlatPageContentsIndex-2].zoomedTexture && _zoomFactor > 1.0f) {
            CGRect zoomedTextureRect = _pageContentsInformation[_rightFlatPageContentsIndex - 2].zoomedTextureRect;
            glUniform4fv(glGetUniformLocation(_program, "uZoomedTextureRect"), 4, 
                         (GLfloat *)&zoomedTextureRect);
            glActiveTexture(GL_TEXTURE2);
            glBindTexture(GL_TEXTURE_2D, _pageContentsInformation[_rightFlatPageContentsIndex-2].zoomedTexture);
        }           
        if(_pageContentsInformation[_rightFlatPageContentsIndex-2].highlightTexture) {
            glActiveTexture(GL_TEXTURE3);
            glBindTexture(GL_TEXTURE_2D, _pageContentsInformation[_rightFlatPageContentsIndex-2].highlightTexture);
        }
        
        
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _triangleStripIndicesBuffer);

        glDrawElements(GL_TRIANGLE_STRIP, TRIANGLE_STRIP_COUNT, GL_UNSIGNED_BYTE, 0);
        
        if(_twoUp) {
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(GL_TEXTURE_2D, _pageContentsInformation[_rightFlatPageContentsIndex-1].texture ?: _grayThumbnail);
            if(_zoomFactor > 1.0f) {
                if(_pageContentsInformation[_rightFlatPageContentsIndex-1].zoomedTexture) {
                    CGRect zoomedTextureRect = _pageContentsInformation[_rightFlatPageContentsIndex-1].zoomedTextureRect;
                    glUniform4fv(glGetUniformLocation(_program, "uZoomedTextureRect"), 4, 
                                 (GLfloat *)&zoomedTextureRect);
                    glActiveTexture(GL_TEXTURE2);
                    glBindTexture(GL_TEXTURE_2D, _pageContentsInformation[_rightFlatPageContentsIndex-1].zoomedTexture);
                } else {
                    glUniform4fv(glGetUniformLocation(_program, "uZoomedTextureRect"), 4, 
                                 (GLfloat *)&invisibleZoomedTextureRect);
                    glActiveTexture(GL_TEXTURE2);
                    glBindTexture(GL_TEXTURE_2D, _alphaWhiteZoomedContent);                    
                }
            }
            if(_pageContentsInformation[_rightFlatPageContentsIndex-1].highlightTexture) {
                glActiveTexture(GL_TEXTURE3);
                glBindTexture(GL_TEXTURE_2D, _pageContentsInformation[_rightFlatPageContentsIndex-1].highlightTexture); 
            } else {
                glActiveTexture(GL_TEXTURE3);
                glBindTexture(GL_TEXTURE_2D, _alphaWhiteZoomedContent); 
            }
            glUniform1i(glGetUniformLocation(_program, "uFlipContentsX"), 1);
        } else {
            glUniform1f(glGetUniformLocation(_program, "uContentsBleed"), 0.2f);
        }
        
        glCullFace(GL_FRONT);
        glDrawElements(GL_TRIANGLE_STRIP, TRIANGLE_STRIP_COUNT, GL_UNSIGNED_BYTE, 0);

        glCullFace(GL_BACK);
        if(_twoUp) {
            glUniform1i(glGetUniformLocation(_program, "uFlipContentsX"), 0);
        } else {
            glUniform1f(glGetUniformLocation(_program, "uContentsBleed"), 1.0f);
        }
        
        glUniform4fv(glGetUniformLocation(_program, "uZoomedTextureRect"), 4, 
                     (GLfloat *)&invisibleZoomedTextureRect);
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, _alphaWhiteZoomedContent);
        
        glActiveTexture(GL_TEXTURE3);
        glBindTexture(GL_TEXTURE_2D, _alphaWhiteZoomedContent); 
        
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);


        if(postDrawAnimationFlags & EucPageTurningViewAnimationFlagsAutomaticTurn) {
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

                glUniform1f(glGetUniformLocation(_program, "uContentsBleed"), 0.0f);
                
                glVertexAttribPointer(glGetAttribLocation(_program, "aTextureCoordinate"), 2, GL_FLOAT, GL_FALSE, 0, _pageEdgeTextureCoordinates);

                glDrawArrays(GL_TRIANGLE_STRIP, 0, Y_VERTEX_COUNT * 2);
                
                glUniform1f(glGetUniformLocation(_program, "uContentsBleed"), 1.0f);
            }            
        }
    }        
    
    if(_atRenderScreenshotBuffer) {
        glReadPixels(0, 0, _backingWidth, _backingHeight, GL_RGBA, GL_UNSIGNED_BYTE, _atRenderScreenshotBuffer);
    }
    
    glBindRenderbuffer(GL_RENDERBUFFER, _viewRenderbuffer);
    [eaglContext presentRenderbuffer:GL_RENDERBUFFER];

    [eaglContext thPop];
    
    if(_viewsNeedRecache) {
        [self _recachePages];
        [self _setNeedsAccessibilityElementsRebuild];
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
        if(!(_animationFlags & EucPageTurningViewAnimationFlagsAutomaticTurn)) {
            _focusedPageIndex = _pageContentsInformation[2] ? _pageContentsInformation[2].pageIndex : _pageContentsInformation[3].pageIndex;
        }
    }
    
    if(_animationFlags != postDrawAnimationFlags) {
        if((_animationFlags & EucPageTurningViewAnimationFlagsAutomaticTurn) &&
           !(postDrawAnimationFlags & EucPageTurningViewAnimationFlagsAutomaticTurn)) {
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        }
        if((_animationFlags & EucPageTurningViewAnimationFlagsAutomaticPositioning) &&
           !(postDrawAnimationFlags & EucPageTurningViewAnimationFlagsAutomaticPositioning)){
            // May as well kick this off now to avoid the 0.2s delay.
            [self _retextureForPanAndZoom];
        }
        
        _animationFlags = postDrawAnimationFlags;
        if(_animationFlags == EucPageTurningViewAnimationFlagsNone) {
            self.animating = NO;
        }
    }
}

- (void)_setPageTouchPointForPageX:(GLfloat)x
{
    CGRect touchablePageRect = _rightPageRect;
    CGFloat pageX = x;
    if(pageX > touchablePageRect.size.width) {
        pageX = touchablePageRect.size.width;
    } else if(pageX < -touchablePageRect.size.width) {
        pageX = -touchablePageRect.size.width;
    }
    _pageTouchPoint.x = pageX;
    _pageTouchPoint.y = ((GLfloat)_touchRow / (Y_VERTEX_COUNT - 1)) * touchablePageRect.size.height;
    _pageTouchPoint.z = -touchablePageRect.size.width * sqrtf(-(powf(((pageX)/touchablePageRect.size.width), 2) - 1));
    //_pageTouchPoint.z = -sqrtf(touchablePageRect.size.width * touchablePageRect.size.width - pageX * pageX); 
}

- (void)_prepareForTurnForwards:(BOOL)forwards
{
    if(forwards) {
        memcpy(_pageVertices, _stablePageVertices, sizeof(_stablePageVertices));
        memcpy(_oldPageVertices, _stablePageVertices, sizeof(_stablePageVertices));
        if(_pageContentsInformation[4] ||
           _pageContentsInformation[5]) {
            _rightFlatPageContentsIndex = 5;
            _isTurning = 1;
        } else {
            if(!_vibrated) {
                if(_vibratesOnInvalidTurn) {
                    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
                }
                _vibrated = YES;
            }                
        }
    } else {
        if(_pageContentsInformation[1] ||
           _pageContentsInformation[2]) {
            if(_rightPageFrame.origin.x <= 0.0f) {
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
            _rightFlatPageContentsIndex = 3;
            _isTurning = -1;
        } else {
            if(!_vibrated) {
                AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
                _vibrated = YES;
            }
        }
    }
}

- (void)_setTouchLocationFromTouch:(UITouch *)touch firstTouch:(BOOL)first;
{
    CGSize size = self.bounds.size;
    CGPoint viewTouchPoint =  [touch locationInView:self];

    if(first) {
        _scrollStartZoomMatrix = _zoomMatrix;
    }
    
    CGAffineTransform affineZoomMatrix = CATransform3DGetAffineTransform(_scrollStartZoomMatrix);
    affineZoomMatrix.ty = -affineZoomMatrix.ty; // Screen coordinates are upside-down to GL.
    
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
    CGPoint pageTouchPoint = CGPointMake((projectedTouchPoint.x - projectedPageFrame.origin.x),
                                         (projectedTouchPoint.y - projectedPageFrame.origin.y));
    
    // Scale back to viewport coordinates.
    pageTouchPoint.x /= affineZoomMatrix.a;
    pageTouchPoint.y /= affineZoomMatrix.d;
        
    if(pageTouchPoint.y <= _rightPageRect.origin.y) {
        _touchRow = 0;
    } else if(pageTouchPoint.y >= _rightPageRect.origin.y + _rightPageRect.size.height) {
        _touchRow = Y_VERTEX_COUNT - 1;
    } else {
        _touchRow = (((pageTouchPoint.y - _rightPageRect.origin.y) / 
                       _rightPageRect.size.height) + 0.5f / Y_VERTEX_COUNT) * (Y_VERTEX_COUNT - 1);
    }
    if(first) {
        _scrollStartTranslation = _scrollTranslation;
        if(_animationFlags & EucPageTurningViewAnimationFlagsDragTurn) {
            if(_isTurning == -1) {
                _touchStartPoint.x = _rightPageFrame.origin.x > 0.0f ? (pageTouchPoint.x - _pageVertices[_touchRow][X_VERTEX_COUNT - 1].x) - _rightPageRect.size.width : (pageTouchPoint.x - _pageVertices[_touchRow][X_VERTEX_COUNT - 1].x);
                _touchStartPoint.y = pageTouchPoint.y;
            } else {
                _touchStartPoint.x = _rightPageRect.size.width - (_pageVertices[_touchRow][X_VERTEX_COUNT - 1].x - pageTouchPoint.x);
                _touchStartPoint.y = pageTouchPoint.y;
            }
        } else {       
            _touchStartPoint = pageTouchPoint;
            _isTurning = 0;
        }
    }    
    
    CGPoint translation = pageTouchPoint;
    translation.x -= _touchStartPoint.x;
    translation.y -= _touchStartPoint.y;
    translation.x *= _zoomFactor;
    translation.y *= _zoomFactor;
    
    CGFloat oldViewportTouchX = _viewportTouchPoint.x;
    CGFloat oldViewportTouchY = _viewportTouchPoint.y;

    if(fabsf(translation.x * _viewportToBoundsPointsTransform.a) > 0.5f || fabsf(translation.y * _viewportToBoundsPointsTransform.d) > 0.5f) {
        if(!(_animationFlags & EucPageTurningViewAnimationFlagsDragTurn) || 
           (_animationFlags & EucPageTurningViewAnimationFlagsDragScroll)) {
            translation.x += _scrollStartTranslation.x;
            translation.y += _scrollStartTranslation.y;
            CGPoint translationAfterScroll = [self _setZoomMatrixFromTranslation:translation zoomFactor:_zoomFactor];
            if(!(_animationFlags & EucPageTurningViewAnimationFlagsDragTurn) && 
               !(_animationFlags & EucPageTurningViewAnimationFlagsDragScroll)) {
                if(fabsf(translation.x - _scrollStartTranslation.x) * _viewportToBoundsPointsTransform.a > 0.5f &&
                   fabsf((translation.x - translationAfterScroll.x) - _scrollStartTranslation.x) * _viewportToBoundsPointsTransform.a < 0.5f &&
                   fabsf((translation.y - translationAfterScroll.y) - _scrollStartTranslation.y) * _viewportToBoundsPointsTransform.d < 4.0f) {
                    _animationFlags = EucPageTurningViewAnimationFlagsDragTurn;
                } else {
                    _animationFlags = EucPageTurningViewAnimationFlagsDragScroll;
                }
                self.animating = YES;
            }
            translation = translationAfterScroll;
        }
        
        if((_animationFlags & EucPageTurningViewAnimationFlagsDragTurn)) {
            translation.x /= _zoomFactor;
            translation.y /= _zoomFactor;

            if(translation.x < -0.000001f && _isTurning >= 0) {
                pageTouchPoint = CGPointMake(_rightPageRect.size.width + translation.x,
                                             translation.y);
                if(_isTurning != 1) {
                    [self _prepareForTurnForwards:YES];
                    oldViewportTouchX = pageTouchPoint.x;
                }
            } else if(translation.x > 0.000001f && _isTurning <= 0) {
                pageTouchPoint = CGPointMake(_rightPageFrame.origin.x > 0.0f ? (-_rightPageRect.size.width + translation.x) : translation.x,
                                             translation.y);
                if(_isTurning != -1) {
                    [self _prepareForTurnForwards:NO];
                    oldViewportTouchX = pageTouchPoint.x;
                }
            } else {
                if(_isTurning == 1 && self.isAnimating) {
                    pageTouchPoint = CGPointMake(_stablePageVertices[_touchRow][X_VERTEX_COUNT - 1].x,
                                                 translation.y);
                } else {
                    pageTouchPoint = CGPointMake(_rightPageRect.origin.x != 0.0f ? -_rightPageRect.size.width : 0, translation.y);
                } 
            }
            if(_isTurning == 0) {
                _animationFlags &= ~EucPageTurningViewAnimationFlagsDragTurn;
                self.animating = NO;  
            }

            if(_isTurning != 0) {
                [self _setPageTouchPointForPageX:pageTouchPoint.x];
            }            
        }
    }
    
    NSTimeInterval thisTouchTime = [touch timestamp];
    if(_touchTime) {
        CGFloat difference = (CGFloat)(thisTouchTime - _touchTime);
        if(difference && !first) {
            CGFloat fps = 1.0f / self.animationInterval;
            _touchVelocity.x = (pageTouchPoint.x - oldViewportTouchX) / (fps * difference);
            _touchVelocity.y = (pageTouchPoint.y - oldViewportTouchY) / (fps * difference);
        } else {
            _touchVelocity = CGPointZero;
        }
    } else {
        _touchVelocity = CGPointZero;
    }
    _touchTime = thisTouchTime;
    _viewportTouchPoint = pageTouchPoint;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    // If we're not currently tracking a touch
    if(!_touch && touches.count == 1) {
        // Store touch
        _touch = touch;
        _touchBeganTime = [touch timestamp];
        [self _setTouchLocationFromTouch:_touch firstTouch:YES];
    }
    if(!_pinchUnderway && !_dragUnderway) {
        // This is a pinch.  Track both touches
        // We store the touches in a different ivar for a pinch.
        if(_touch) {
            _pinchTouches[0] = _touch;
        } else {
            _pinchTouches[0] = [touches anyObject];
        }
        for(UITouch *secondTouch in touches) {
            if(secondTouch != _pinchTouches[0]) {
                _pinchTouches[1] = secondTouch;
                break;
            }
        }
        if(_pinchTouches[0] && _pinchTouches[1]) {
            _touch = nil;
            
            _pinchStartPoints[0] = [_pinchTouches[0] locationInView:self];
            _pinchStartPoints[1] = [_pinchTouches[1] locationInView:self];
            
            _pinchStartZoomFactor = _zoomFactor;
            _scrollStartTranslation = _scrollTranslation;
            
            THLog(@"Pinch Began: %@, %@", NSStringFromCGPoint(_pinchStartPoints[0]), NSStringFromCGPoint(_pinchStartPoints[1]));
        } else {
            _pinchTouches[0] = nil;
            _pinchTouches[1] = nil;
        }
    }    
    
    // We haven't started to move yet.  We'll pass all the touches on.
    [_pageContentsInformation[3].view touchesBegan:touches withEvent:event];   
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(_touch && [touches containsObject:_touch]) {
        if(self.userInteractionEnabled) {
            if(!_dragUnderway) {
                _dragUnderway = YES;
                [_pageContentsInformation[3].view touchesCancelled:[NSSet setWithObjects:&_touch count:1] withEvent:event];
            }            
            [self _setTouchLocationFromTouch:_touch firstTouch:NO];
        }
    } else if(_pinchTouches[0] && _pinchTouches[1] &&
              ([touches containsObject:_pinchTouches[0]] || [touches containsObject:_pinchTouches[1]])) {
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
                    _rightFlatPageContentsIndex = 6;
                    
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
            
            newZoomTranslation.x += _scrollStartTranslation.x * newZoomFactor / _pinchStartZoomFactor;
            newZoomTranslation.y += _scrollStartTranslation.y * newZoomFactor / _pinchStartZoomFactor;
            
            [self _setZoomMatrixFromTranslation:newZoomTranslation zoomFactor:newZoomFactor];
        }
    }
    
    NSMutableSet *unusedTouches = [touches mutableCopy];
    if(_dragUnderway && _touch) {
        if([unusedTouches containsObject:_touch]) {
            [unusedTouches removeObject:_touch];
        }            
    } 
    if(_pinchUnderway) {
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
    }
    if(unusedTouches.count) {
        [_pageContentsInformation[3].view touchesMoved:unusedTouches withEvent:event];
    }
    [unusedTouches release];
}

- (void)_touchesEndedOrCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(_touch && [touches containsObject:_touch]) {
        if(_dragUnderway) {
            if([event timestamp] > [_touch timestamp] + 0.1) {
                [self _setTouchLocationFromTouch:_touch firstTouch:NO];
            }
            //NSLog(@"Real: %f, %f", _touchVelocity.x, _touchVelocity.y);
            
            if(_animationFlags & EucPageTurningViewAnimationFlagsDragTurn) {
                CGFloat absTouchVelocity = fabsf(_touchVelocity.x);
                if(absTouchVelocity < 0.02f) {
                    _touchVelocity.x = 0;
                } else if(absTouchVelocity < 0.2f) {
                    _touchVelocity.x = _touchVelocity.x < 0 ? -0.2f : 0.2f;
                } else if(absTouchVelocity > 0.4f) {
                    _touchVelocity.x = _touchVelocity.x < 0 ? -0.4f : 0.4f;
                }
                _touchVelocity.y = 0.0f;
            } 
            /*if(_animationFlags & EucPageTurningViewAnimationFlagsDragScroll) {
                _animationFlags &= ~EucPageTurningViewAnimationFlagsDragScroll;
                if(_animationFlags == EucPageTurningViewAnimationFlagsNone) {
                    self.animating = NO;
                }
            }*/
            //NSLog(@"Corrected: %f, %f", _touchVelocity.x, _touchVelocity.y);
            //_pageTouchPoint.x = _pageVertices[_touchRow][X_VERTEX_COUNT - 1].x;
            _touchTime = 0;
            _dragUnderway = NO;
        }

        _touch = nil;
    } else if((_pinchTouches[0] && [touches containsObject:_pinchTouches[0]]) || 
              (_pinchTouches[1] && [touches containsObject:_pinchTouches[1]])) {
        if(_pinchUnderway) {
            _pinchUnderway = NO;       
            if(_zoomHandlingKind == EucPageTurningViewZoomHandlingKindInnerScaling) {
                if(_pageContentsInformation[6]) {
                    EucPageTurningPageContentsInformation *tempView = _pageContentsInformation[3];
                    _pageContentsInformation[3] = _pageContentsInformation[6];
                    _pageContentsInformation[6] = tempView;
                    
                    [self _setView:nil forInternalPageOffsetPage:6];
                    _rightFlatPageContentsIndex = 3;

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
        _pinchTouches[0] = nil;
        _pinchTouches[1] = nil;
        if(_zoomFactor < _minZoomFactor) { 
            [self setTranslation:_scrollTranslation zoomFactor:_minZoomFactor animated:YES];
        }        
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSMutableSet *unusedTouches = [touches mutableCopy];    
    if(_dragUnderway) {
        if([unusedTouches containsObject:_touch]) {
            [unusedTouches removeObject:_touch];
        }            
    } 
    if(_pinchUnderway) {
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
    }
    
    if(unusedTouches.count) {
        [_pageContentsInformation[3].view touchesEnded:unusedTouches withEvent:event];
    }
    [unusedTouches release];
    
    [self _touchesEndedOrCancelled:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSMutableSet *unusedTouches = [touches mutableCopy];    
    if(_dragUnderway) {
        if([unusedTouches containsObject:_touch]) {
            [unusedTouches removeObject:_touch];
        }            
    } 
    if(_pinchUnderway) {
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
    }
    if(unusedTouches.count) {
        [_pageContentsInformation[3].view touchesCancelled:unusedTouches withEvent:event];
    }
    [unusedTouches release];
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
        ret = 0.25f * view.bounds.size.width;
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
    if(!_touch && _touchVelocity.x) {
        _viewportTouchPoint.x = _viewportTouchPoint.x + _touchVelocity.x /** difference*/;
        [self _setPageTouchPointForPageX:_viewportTouchPoint.x];
    } 
    
    THVec3 *flatPageVertices = (THVec3 *)_pageVertices;
    THVec3 *flatOldPageVertices = (THVec3 *)_oldPageVertices;
    //GLfloatTriplet *flatForceAccumulators = (GLfloatTriplet *)_forceAccumulators;
    GLfloat gravity = (_touch || _touchVelocity.x) ? 0.002 : 0.01;
    GLfloat toAdd = (_touch || _touchVelocity.x) ? 0.6f : 0.99f;
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
        flatPageVertices[i] = THVec3Add(x, THVec3Multiply(THVec3Subtract(x, oldx), toAdd)); 
        flatPageVertices[i].z += gravity;
        
        flatOldPageVertices[i] = temp;
    }
}

#define NUM_ITERATIONS 40

- (BOOL)_satisfyPositioningConstraints
{
    BOOL shouldStopAnimating = YES;
	
	if (_animationIndex >= 0) {
		[self _setTranslation:CGPointMake(_presentationTranslationX[_animationIndex], _presentationTranslationY[_animationIndex]) zoomFactor:_presentationZoomFactor[_animationIndex]];
		_animationIndex++;
		shouldStopAnimating = NO;
	}
	
	if (_animationIndex >= POSITIONING_ANIMATION_ITERATIONS) {
		_animationIndex = -1;
		shouldStopAnimating = YES;
	}
	
	return shouldStopAnimating;	
}

- (BOOL)_satisfyConstraints
{
    BOOL shouldStopAnimating = NO;
    
    BOOL pageHasRigidEdge;
    if(_animationFlags & EucPageTurningViewAnimationFlagsAutomaticTurn) {
        pageHasRigidEdge = YES;
    } else if([_delegate respondsToSelector:@selector(pageTurningView:viewEdgeIsRigid:)]) {
        pageHasRigidEdge = [_delegate pageTurningView:self viewEdgeIsRigid:_pageContentsInformation[_rightFlatPageContentsIndex-2].view];
    } else {
        pageHasRigidEdge = NO;
    }
    
    CGFloat pageOriginX = _rightPageRect.origin.x;
    THVec3 pageTouchPoint = _pageTouchPoint;
        
    THVec3 *flatPageVertices = (THVec3 *)_pageVertices;
    int j;
    for(j=0; j < NUM_ITERATIONS; ++j) {              
        if(_touch || _touchVelocity.x) {        
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
        BOOL isFlat = !_touch && _touchVelocity.x >= 0;
        BOOL hasFlipped = !_touch && _touchVelocity.x <= 0;
        BOOL hasFlippedFlat = !_touch && _touchVelocity.x <= 0;
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
                if(_touch || _touchVelocity.x) {
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
            _touchVelocity = CGPointZero;
            
            if(_rightFlatPageContentsIndex == 5) {
                if(hasFlipped) {
                    [self _cyclePageContentsInformationForTurnForwards:YES];
                    if(_twoUp) {
                        if((_animationFlags & EucPageTurningViewAnimationFlagsDragTurn) != EucPageTurningViewAnimationFlagsDragTurn) {
                            _recacheFlags[0] = YES;
                        }                        
                        _recacheFlags[4] = YES;
                    }
                    if((_animationFlags & EucPageTurningViewAnimationFlagsDragTurn) != EucPageTurningViewAnimationFlagsDragTurn) {
                        _recacheFlags[1] = YES;
                    }
					_recacheFlags[5] = YES; 

                    _viewsNeedRecache = YES;
                } 
                _rightFlatPageContentsIndex = 3;
            } else {
                if(!hasFlipped) {
                    [self _cyclePageContentsInformationForTurnForwards:NO];
                    if(_twoUp) {
                        _recacheFlags[0] = YES;
                        if((_animationFlags & EucPageTurningViewAnimationFlagsDragTurn) != EucPageTurningViewAnimationFlagsDragTurn) {
                            _recacheFlags[5] = YES;
                        }
                    }                    
                    _recacheFlags[1] = YES;
                    if((_animationFlags & EucPageTurningViewAnimationFlagsDragTurn) != EucPageTurningViewAnimationFlagsDragTurn) {
                        _recacheFlags[5] = YES;
                    }
					
                    _viewsNeedRecache = YES;
                }
            }  
            
            shouldStopAnimating = YES;

            break;
        }
    }
    return shouldStopAnimating;
}

- (void)_recachePages
{
    // Don't fetch page numbers for indexes 2 and 3, they'll already be set.
    if(_recacheFlags[3] && _pageContentsInformation[3]) {
        if(_viewDataSource) {
            if(_pageContentsInformation[3].view) {
                [self _setView:_pageContentsInformation[3].view forInternalPageOffsetPage:3 forceRefresh:YES];
            }
        } else {
            [self _setupBitmapPage:_pageContentsInformation[3].pageIndex forInternalPageOffset:3];
        }
    }
    
    if(_twoUp) { 
        if(_recacheFlags[2] && _pageContentsInformation[2]) {
            if(_viewDataSource) {
                if(_pageContentsInformation[2].view) {
                    [self _setView:_pageContentsInformation[2].view forInternalPageOffsetPage:2 forceRefresh:YES];
                }
            } else {
                [self _setupBitmapPage:_pageContentsInformation[2].pageIndex forInternalPageOffset:2];
            }
        }
        
        if(_recacheFlags[1]) {
            if(_viewDataSource) {
                if(_pageContentsInformation[2].view) {
                    [self _setView:[_viewDataSource pageTurningView:self 
                                                previousViewForView:_pageContentsInformation[2].view] forInternalPageOffsetPage:1];
                } else {
                    [self _setView:nil forInternalPageOffsetPage:1];
                }
            } else {
                if(_pageContentsInformation[2]) {
                    [self _setupBitmapPage:_pageContentsInformation[2].pageIndex - 1 forInternalPageOffset:1];
                } else {
                    [_pageContentsInformation[1] release];
                    _pageContentsInformation[1] = nil;
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
                if(_pageContentsInformation[1]) {
                    [self _setupBitmapPage:_pageContentsInformation[1].pageIndex - 1 forInternalPageOffset:0];
                } else {
                    [_pageContentsInformation[0] release];
                    _pageContentsInformation[0] = nil;
                }
            }
        }
                
        if(_recacheFlags[4]) {
            if(_viewDataSource) {
                if(_pageContentsInformation[3].view) {
                    [self _setView:[_viewDataSource pageTurningView:self 
                                                    nextViewForView:_pageContentsInformation[3].view] forInternalPageOffsetPage:4];
                } else {
                    [self _setView:nil forInternalPageOffsetPage:4];
                }         
            } else {
                if(_pageContentsInformation[3]) {
                    [self _setupBitmapPage:_pageContentsInformation[3].pageIndex + 1 forInternalPageOffset:4];
                } else {
                    [_pageContentsInformation[4] release];
                    _pageContentsInformation[4] = nil;
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
                if(_pageContentsInformation[4]) {
                    [self _setupBitmapPage:_pageContentsInformation[4].pageIndex + 1 forInternalPageOffset:5];
                } else {
                    [_pageContentsInformation[5] release];
                    _pageContentsInformation[5] = nil;
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
                if(_pageContentsInformation[3]) {
                    [self _setupBitmapPage:_pageContentsInformation[3].pageIndex - 1 forInternalPageOffset:1];
                } else {
                    [_pageContentsInformation[1] release];
                    _pageContentsInformation[1] = nil;
                }
            }
        }
        
        if(_recacheFlags[5]) {
            if(_viewDataSource) {
                if(_pageContentsInformation[3].view) {
                    [self _setView:[_viewDataSource pageTurningView:self 
                                                    nextViewForView:_pageContentsInformation[3].view] forInternalPageOffsetPage:5];
                } else {
                    [self _setView:nil forInternalPageOffsetPage:5];
                }         
            } else {
                if(_pageContentsInformation[3]) {
                    [self _setupBitmapPage:_pageContentsInformation[3].pageIndex + 1 forInternalPageOffset:5];
                } else {
                    [_pageContentsInformation[5] release];
                    _pageContentsInformation[5] = nil;
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

- (CGFloat)zoomFactor
{
    return _zoomFactor;
}

- (CGPoint)translation
{
    CGPoint translation = _scrollTranslation;
    translation.x *= _viewportToBoundsPointsTransform.a;
    translation.y *= _viewportToBoundsPointsTransform.d;
    return translation;
}

- (CGFloat)fitToBoundsZoomFactor
{
    CGRect bounds = self.bounds;
    CGRect pageRect;
    if(_twoUp) {
        pageRect = CGRectUnion(_unzoomedLeftPageFrame, _unzoomedRightPageFrame);
    } else {
        pageRect = _unzoomedRightPageFrame;
    }
    
    CGFloat widthZoom = bounds.size.width / pageRect.size.width;
    CGFloat heightZoom = bounds.size.height / pageRect.size.height;

    return MAX(widthZoom, heightZoom);
}

- (void)_setTranslation:(CGPoint)translation zoomFactor:(CGFloat)zoomFactor
{
	translation.x /= _viewportToBoundsPointsTransform.a;
	translation.y /= _viewportToBoundsPointsTransform.d;
	[self _setZoomMatrixFromTranslation:translation zoomFactor:zoomFactor];
}

// With a little help from http://www.anima-entertainment.de/?p=252:
// assuming :
// t is a value between 0 and 1
// b is an offset
// c is the height
/*
static CGFloat easeIn (CGFloat t, CGFloat b, CGFloat c) {
    return c*pow(t, 3.0f) + b;
}

static CGFloat easeOut (CGFloat t, CGFloat b, CGFloat c) {
    return c*(pow(t-1, 3.0f) + 1) + b;
}
*/
static CGFloat easeInOut (CGFloat t, CGFloat b, CGFloat c) {
    if ( (t*2.0f) < 1.0f)
        return c*0.5f*powf(t*2.0f, 3.0f) + b;
    else
        return c*0.5f*(powf(t*2.0f-2.0f, 3.0f) + 2.0f) + b;
}

- (void)setTranslation:(CGPoint)translation zoomFactor:(CGFloat)zoomFactor animated:(BOOL)animated
{	
    if(animated) {
        CGFloat currentZoom = _zoomFactor;
        CGPoint currentTranslation = self.translation;
        
        // Setting the translation so we can check what the final positions will be (by interrogating the _animatedZoomFactor and _animatedTranslation)
        [self _setTranslation:translation zoomFactor:zoomFactor];
        _modelZoomFactor = _zoomFactor;
        _modelTranslation = self.translation;
        [self _setTranslation:currentTranslation zoomFactor:currentZoom];
                    
        CGFloat zoomDelta = (_modelZoomFactor - _zoomFactor);
        CGFloat translationXDelta = (_modelTranslation.x - currentTranslation.x); 
        CGFloat translationYDelta = (_modelTranslation.y - currentTranslation.y); 
        
        for (int i = 0; i < POSITIONING_ANIMATION_ITERATIONS; i++) {
            CGFloat step = (CGFloat)i / (CGFloat)(POSITIONING_ANIMATION_ITERATIONS - 1);
            if(step > 1.0f) {
                step = 1.0f;
            }
            _presentationZoomFactor[i] = easeInOut(step, currentZoom, zoomDelta);
            _presentationTranslationX[i] = easeInOut(step, currentTranslation.x, translationXDelta);
            _presentationTranslationY[i] = easeInOut(step, currentTranslation.y, translationYDelta);
        }
        
        _animationIndex = 0;
            
        _animationFlags |= EucPageTurningViewAnimationFlagsAutomaticPositioning;
        self.animating = YES;
    } else {
        [self _setTranslation:translation zoomFactor:zoomFactor];
    }
}

- (CGPoint)_setZoomMatrixFromTranslation:(CGPoint)translation zoomFactor:(CGFloat)zoomFactor
{
    if(_zoomFactor == 1.0 && zoomFactor == 1.0) {
        if(_pageContentsInformation[2].currentZoomedTextureGenerationOperation) {
            _pageContentsInformation[2].currentZoomedTextureGenerationOperation = nil;
        }
        if(_pageContentsInformation[3].currentZoomedTextureGenerationOperation) {
            _pageContentsInformation[3].currentZoomedTextureGenerationOperation = nil;
        }
        return translation;
    } else {
        CGFloat previousZoomFactor = _zoomFactor;
        CGPoint previousTranslation = _scrollTranslation;
        
        [self willChangeValueForKey:@"translation"];
        [self willChangeValueForKey:@"zoomFactor"];
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
        
        if(zoomFactor > _maxZoomFactor) {
            zoomFactor = _maxZoomFactor;
        }        
        CGFloat compensatedZoomFactor = zoomFactor;
        if(compensatedZoomFactor < _minZoomFactor) {
            // Make the zoom factor larger to make it feel 'springy'.
            compensatedZoomFactor = _minZoomFactor * (powf(compensatedZoomFactor / _minZoomFactor, 0.5f) + 0.5f) / 1.5f;
        }
        
        // Massage the zoom matrix to the nearest matrix that will scale the zoom 
        // rect edges to pixel boundaries, so that our page textures will look
        // nice and crisp, and the pages with have pixel-aligned edges.
        // Make sure the width is also divisible by two so that it can be centered
        // on a pixel boundry.
        zoomMatrix.m11 = roundf(pixelSize.width * compensatedZoomFactor * 0.5f) / (pixelSize.width * 0.5f);
        zoomMatrix.m22 = roundf(pixelSize.height * compensatedZoomFactor * 0.5f) / (pixelSize.height * 0.5f);
        
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
        CGPoint remainingTranslation = CGPointZero;
        
        CGRect pagesRect;
        if(_twoUp) {
            pagesRect = CGRectUnion(leftPageFrame, rightPageFrame);
        } else {
            pagesRect = rightPageFrame;
        }
        
        // Fix up things in the X axis.
        if(pagesRect.size.width <= _viewportLogicalSize.width) {
            // If it fits on the screen, center it.
            CGFloat centeringOffset = (0.5f * (_viewportLogicalSize.width - pagesRect.size.width)) - pagesRect.origin.x;
            rightPageFrame.origin.x += centeringOffset;
            leftPageFrame.origin.x += centeringOffset;
            pagesRect.origin.x += centeringOffset;
            zoomMatrix.m41 += centeringOffset;
            remainingTranslation.x -= centeringOffset;
        } else {
            // If it doesn't fit on the screen, make sure there's no blank space
            // between the page edge and the edge of the screen.
            CGFloat leftUnderflow = pagesRect.origin.x;
            if(leftUnderflow > 0.0f) {
                rightPageFrame.origin.x -= leftUnderflow;
                leftPageFrame.origin.x -= leftUnderflow;
                pagesRect.origin.x -= leftUnderflow;
                zoomMatrix.m41 -= leftUnderflow;
                remainingTranslation.x += leftUnderflow;
            } else {
                CGFloat rightUnderflow = _viewportLogicalSize.width - CGRectGetMaxX(pagesRect);
                if(rightUnderflow > 0.0f) {
                    rightPageFrame.origin.x += rightUnderflow;
                    leftPageFrame.origin.x += rightUnderflow;
                    pagesRect.origin.x += rightUnderflow;
                    zoomMatrix.m41 += rightUnderflow;
                    remainingTranslation.x -= rightUnderflow;
                }
            }
        }
        
        // Fix up things in the Y axis.
        if(pagesRect.size.height <= _viewportLogicalSize.height) {
            // If it fits on the screen, center it.
            CGFloat centeringOffset = (0.5f * (_viewportLogicalSize.height - pagesRect.size.height)) - pagesRect.origin.y;
            rightPageFrame.origin.y += centeringOffset;
            leftPageFrame.origin.y += centeringOffset;
            pagesRect.origin.y += centeringOffset;
            zoomMatrix.m42 += centeringOffset;
            remainingTranslation.y -= centeringOffset;
        } else {
            // If it doesn't fit on the screen, make sure there's no blank space
            // between the page edge and the edge of the screen.
            CGFloat topUnderflow = pagesRect.origin.y;
            if(topUnderflow > 0.0f) {
                rightPageFrame.origin.y -= topUnderflow;
                leftPageFrame.origin.y -= topUnderflow;
                pagesRect.origin.y -= topUnderflow;
                zoomMatrix.m42 -= topUnderflow;
                remainingTranslation.y += topUnderflow;
            } else {
                CGFloat bottomUnderflow = _viewportLogicalSize.height - CGRectGetMaxY(pagesRect);
                if(bottomUnderflow > 0.0f) {
                    rightPageFrame.origin.y += bottomUnderflow;
                    leftPageFrame.origin.y += bottomUnderflow;
                    pagesRect.origin.y += bottomUnderflow;
                    zoomMatrix.m42 += bottomUnderflow;
                    remainingTranslation.y -= bottomUnderflow;
                }
            }
        }
        
        _zoomFactor = zoomFactor;
        _scrollTranslation = CGPointMake(zoomMatrix.m41, zoomMatrix.m42);

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
        [self didChangeValueForKey:@"zoomFactor"];
        [self didChangeValueForKey:@"translation"];
        
        if(_zoomFactor != previousZoomFactor || 
           !CGPointEqualToPoint(_scrollTranslation, previousTranslation)) {
            [self _scheduleRetextureForPanAndZoom];
        }
        [self setNeedsDraw];

        return remainingTranslation;
    }
}

- (void)_retextureForPanAndZoom
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_retextureForPanAndZoom) object:nil];
    if(_zoomFactor != 1.0f) {
        CGFloat contentScaleFactor;
        if([self respondsToSelector:@selector(contentScaleFactor)]) {
            contentScaleFactor = self.contentScaleFactor;
        } else {
            contentScaleFactor = 1.0f;
        }
                
        CGRect bounds = self.bounds;
        for(NSInteger i = 2; i <= 3; ++i) {
            if(_pageContentsInformation[i]) {
                CGRect pageFrame = i == 2 ? _leftPageFrame : _rightPageFrame;
                if(CGRectIntersectsRect(pageFrame, bounds)) {
                    NSUInteger pageIndex = _pageContentsInformation[i].pageIndex;
                    
                    CGRect scaledPageFrame = pageFrame;
                    scaledPageFrame.origin.x *= contentScaleFactor;
                    scaledPageFrame.origin.y *= contentScaleFactor;
                    scaledPageFrame.size.width *= contentScaleFactor;
                    scaledPageFrame.size.height *= contentScaleFactor;
                    
                    CGPoint center = CGPointMake((bounds.size.width * contentScaleFactor) * 0.5f,
                                                 (bounds.size.height * contentScaleFactor) * 0.5f);
                    
                    CGRect centeredTextureRect;
                    centeredTextureRect.origin = CGPointMake(center.x - (_zoomedTextureWidth * 0.5f), center.y - (_zoomedTextureWidth * 0.5f));
                    centeredTextureRect.size = CGSizeMake(center.x + (_zoomedTextureWidth * 0.5f) - centeredTextureRect.origin.x, 
                                                          center.y + (_zoomedTextureWidth * 0.5f) - centeredTextureRect.origin.y);
                    
                    CGRect intersect = CGRectIntersection(scaledPageFrame, centeredTextureRect);
                    
                    CGRect scaledIntersection = CGRectMake((intersect.origin.x  - scaledPageFrame.origin.x) / scaledPageFrame.size.width,
                                                           (intersect.origin.y  - scaledPageFrame.origin.y) / scaledPageFrame.size.height,
                                                           intersect.size.width / scaledPageFrame.size.width, 
                                                           intersect.size.height / scaledPageFrame.size.height);
                    EucPageTurningTextureGenerationOperation *textureGenerationOperation = [[EucPageTurningTextureGenerationOperation alloc] init];
                    textureGenerationOperation.delegate = self;
                    textureGenerationOperation.texturePool = _texturePool;
                    textureGenerationOperation.pageIndex = pageIndex;
                    textureGenerationOperation.textureRect = scaledIntersection;
                    textureGenerationOperation.isZoomed = YES;

                    CGRect thisPageRect = [_bitmapDataSource pageTurningView:self 
                                                   contentRectForPageAtIndex:pageIndex];
                    CGRect textureFrom = CGRectMake(thisPageRect.origin.x + scaledIntersection.origin.x * thisPageRect.size.width,
                                                    thisPageRect.origin.y + scaledIntersection.origin.y * thisPageRect.size.height,
                                                    scaledIntersection.size.width * thisPageRect.size.width,
                                                    scaledIntersection.size.height * thisPageRect.size.height);
                    
                    NSInvocation *textureUploadInvocation = [NSInvocation invocationWithMethodSignature:
                                                             [self methodSignatureForSelector:@selector(_bitmapDataAndSizeForPageAtIndex:inPageRect:ofSize:alphaBled:)]];
                    textureUploadInvocation.selector = @selector(_bitmapDataAndSizeForPageAtIndex:inPageRect:ofSize:alphaBled:);
                    textureUploadInvocation.target = self;
                    [textureUploadInvocation setArgument:&pageIndex atIndex:2];
                    [textureUploadInvocation setArgument:&textureFrom atIndex:3];
                    [textureUploadInvocation setArgument:&(intersect.size) atIndex:4];
                    BOOL alphaBled = !CGRectEqualToRect(intersect, scaledPageFrame);
                    [textureUploadInvocation setArgument:&alphaBled atIndex:5];

                    textureGenerationOperation.generationInvocation = textureUploadInvocation;
                    
                    _pageContentsInformation[i].currentZoomedTextureGenerationOperation = textureGenerationOperation;
                    
                    [_textureGenerationOperationQueue addOperation:textureGenerationOperation];
					[textureGenerationOperation release];
                }
            }
        }
    }
}            
             
- (void)_scheduleRetextureForPanAndZoom
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_retextureForPanAndZoom) object:nil];
    [self performSelector:@selector(_retextureForPanAndZoom) withObject:nil afterDelay:0.2f];
}

- (void)_cancelRetextureForPanAndZoom
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_retextureForPanAndZoom) object:nil];
}

#pragma mark -
#pragma mark Texture Generation Delegate

- (void)textureGenerationOperationGeneratedTexture:(EucPageTurningTextureGenerationOperation *)operation;
{
    NSUInteger index = NSUIntegerMax;
    
    GLuint texture = operation.generatedTextureID;
    NSUInteger operationPageIndex = operation.pageIndex;
    CGRect textureRect = operation.textureRect;
    
    for(NSUInteger i = 0; i < sizeof(_pageContentsInformation) / sizeof(EucPageTurningPageContentsInformation *); ++i) {
        if(_pageContentsInformation[i] && _pageContentsInformation[i].pageIndex == operationPageIndex) {
            index = i;
            break;
        }
    }        
    
    if(index != NSUIntegerMax) {
        BOOL isZoomed = operation.isZoomed;
        if(isZoomed) {
            if(index == 3 || index == 2) {
                if(texture) {
                    _pageContentsInformation[index].zoomedTexture = texture;
                    _pageContentsInformation[index].zoomedTextureRect = textureRect;
                }
            } else {
                // This is an old zoom operation, for a non-front-facing page.
                [_texturePool recycleTexture:texture];
            }
            if(_pageContentsInformation[index].currentZoomedTextureGenerationOperation == operation) {
                _pageContentsInformation[index].currentZoomedTextureGenerationOperation = nil;
            }                         
        } else if(!isZoomed) {
            if(texture) {
                _pageContentsInformation[index].texture = texture;
            }
            if(_pageContentsInformation[index].currentTextureGenerationOperation == operation) {
                _pageContentsInformation[index].currentTextureGenerationOperation = nil;
            }                        
        }
        [self setNeedsDraw];
    } else {
        // This is an old operation, for a page we don't have any more.
        [_texturePool recycleTexture:texture];
    }    
}

#pragma mark -
#pragma mark Highlights

- (void)_refreshHighlightsForPageContentsIndex:(NSUInteger)index
{
    BOOL gotHighlights = NO;
    if([NSThread isMainThread]) {
        // Don't do this first on a non-main thread, it will cause 
        // glitching.
        _pageContentsInformation[index].highlightTexture = 0;
    }
    if([_bitmapDataSource respondsToSelector:@selector(pageTurningView:highlightsForPageAtIndex:)]) {
        NSArray *highlights = [_bitmapDataSource pageTurningView:self highlightsForPageAtIndex:_pageContentsInformation[index].pageIndex];
        
        CGFloat textureScale = 0.25f;
        
        CGSize minSize = _unzoomedRightPageFrame.size;
        minSize.width = ceilf(minSize.width * textureScale);
        minSize.height = ceilf(minSize.height * textureScale);
        
        if(highlights && highlights.count) {                
            size_t bufferLength = minSize.width * minSize.height * 4;
            unsigned char *textureData = malloc(bufferLength);
            uint32_t pattern = 0x00000000;
            memset_pattern4(textureData, &pattern, bufferLength);

            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGContextRef textureContext = CGBitmapContextCreate(textureData, minSize.width, minSize.height, 8, minSize.width * 4, 
                                                                colorSpace, kCGImageAlphaPremultipliedLast);
            CGColorSpaceRelease(colorSpace);
            CGContextScaleCTM(textureContext, 1.0f, -1.0f);
            CGContextTranslateCTM(textureContext, 0, -minSize.height);

            CGFloat cornerRadius = 4.0f * textureScale;
            CGContextSetBlendMode(textureContext, kCGBlendModeNormal);
            for(THPair *highlight in highlights) {
                CGRect highlightRect = [highlight.first CGRectValue];
                highlightRect.origin.x *= textureScale;
                highlightRect.origin.y *= textureScale;
                highlightRect.size.width *= textureScale;
                highlightRect.size.height *= textureScale;
                highlightRect = CGRectIntegral(highlightRect);
                
                UIColor *highlightColor = highlight.second;
                CGContextSetFillColorWithColor(textureContext, highlightColor.CGColor);
                CGContextBeginPath(textureContext);
                THAddRoundedRectToPath(textureContext, highlightRect, cornerRadius, cornerRadius);
                CGContextFillPath(textureContext);
            }
            
            // Unpremultiply the alpha for OpenGL.
            for(int i = 0; i < bufferLength; i += 4) {
                int alpha = textureData[i+3];
                if(alpha > 0) {
                    textureData[i] = (255 * (int)textureData[i]) / alpha;
                    textureData[i+1] = (255 * (int)textureData[i+1]) / alpha;
                    textureData[i+2] = (255 * (int)textureData[i+2]) / alpha;
                }
            }
            
            _pageContentsInformation[index].highlightTexture = [self _createTextureFromRGBABitmapContext:textureContext];
            gotHighlights = YES;
            
            CGContextRelease(textureContext);
            free(textureData);
        }
    }
    if(!gotHighlights) {
        _pageContentsInformation[index].highlightTexture = 0;
    }
}

- (void)refreshHighlightsForPageAtIndex:(NSUInteger)pageIndex
{
	NSUInteger pageContentsIndex = NSUIntegerMax;
    
    for(NSUInteger i = 0; i < sizeof(_pageContentsInformation) / sizeof(EucPageTurningPageContentsInformation *); ++i) {
        if(_pageContentsInformation[i] && _pageContentsInformation[i].pageIndex == pageIndex) {
            pageContentsIndex = i;
            break;
        }
    }   
    if(pageContentsIndex != NSUIntegerMax) {
        [self _refreshHighlightsForPageContentsIndex:pageContentsIndex];
        [self setNeedsDraw];
    }
}

@end