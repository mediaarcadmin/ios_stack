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
#import "THLog.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <AudioToolbox/AudioToolbox.h>
#include <tgmath.h>
#import "THAppleSampleEAGLView.h"

#define FOV_ANGLE ((GLfloat)10.0f)

// to perform cross product between 2 vectors in myGluLookAt 
static void CrossProd(float x1, float y1, float z1, float x2, float y2, float z2, float res[3]) 
{ 
    res[0] = y1*z2 - y2*z1; 
    res[1] = x2*z1 - x1*z2; 
    res[2] = x1*y2 - x2*y1; 
} 

// From http://www.khronos.org/message_boards/viewtopic.php?t=541
static void FadiGluLookAt(float eyeX, float eyeY, float eyeZ, float lookAtX, float lookAtY, float lookAtZ, float upX, float upY, float upZ) 
{ 
    // i am not using here proper implementation for vectors. 
    // if you want, you can replace the arrays with your own 
    // vector types 
    float f[3]; 
    
    // calculating the viewing vector 
    f[0] = lookAtX - eyeX; 
    f[1] = lookAtY - eyeY; 
    f[2] = lookAtZ - eyeZ; 
    
    GLfloat fMag;//, upMag; 
    fMag = sqrtf(f[0]*f[0] + f[1]*f[1] + f[2]*f[2]); 
    //upMag = sqrt(upX*upX + upY*upY + upZ*upZ); 
    
    // normalizing the viewing vector 
    if( fMag != 0) 
    { 
        f[0] = f[0]/fMag; 
        f[1] = f[1]/fMag; 
        f[2] = f[2]/fMag; 
    } 
    
    // normalising the up vector. no need for this here if you have your 
    // up vector already normalised, which is mostly the case. 
    //if( upMag != 0 ) 
    //{ 
    //    upX = upX/upMag; 
    //    upY = upY/upMag; 
    //    upZ = upZ/upMag; 
    //} 
    
    float s[3], u[3]; 
    
    CrossProd(f[0], f[1], f[2], upX, upY, upZ, s); 
    CrossProd(s[0], s[1], s[2], f[0], f[1], f[2], u); 
    
    float M[]= 
    { 
        s[0], u[0], -f[0], 0, 
        s[1], u[1], -f[1], 0, 
        s[2], u[2], -f[2], 0, 
        0, 0, 0, 1 
    }; 
    
    glMultMatrixf(M); 
    glTranslatef (-eyeX, -eyeY, -eyeZ); 
}

// From http://www.typhoonlabs.com/tutorials/gles/Tutorial2.pdf
static void GLUPerspective(GLfloat fovy, GLfloat aspect, GLfloat zNear, GLfloat zFar) 
{ 
    GLfloat xmin, xmax, ymin, ymax;      
        
    ymax = zNear * ((GLfloat)tanf(fovy * (float)M_PI / 360.0f));   
    ymin = -ymax; 
    
    xmin = ymin * aspect;
    xmax = ymax * aspect;  
    glFrustumf(xmin, xmax, ymin, ymax, zNear, zFar); 
} 


@interface EucPageTurningView (PRIVATE)

- (void)_calculateVertexNormals;    
//- (void)_accumulateForces;  // Not used - see comments around implementation.
- (void)_verlet;
- (void)_satisfyConstraints;
- (void)_setupConstraints;
- (void)_postAnimationViewAndTextureRecache;

@end

@implementation EucPageTurningView

#define PAGE_WIDTH 4
#define PAGE_HEIGHT 6

@synthesize delegate = _delegate;

- (void)startAnimation
{
    if(!_animating) {
        // Curtail background tasks to allow smooth animation.
        [THBackgroundProcessingMediator curtailBackgroundProcessing];
        _animating = YES;
        [super startAnimation];
    }
}

- (void)stopAnimation
{
    if(_animating) {
        // Allow background tasks again.
        [THBackgroundProcessingMediator allowBackgroundProcessing];
        _animating = NO;
        [super stopAnimation];
    }
}

#define indexForPageVertex(row, column) (((void *)(&(_pageVertices[column][row].x)) - (void *)_pageVertices) / (3 * sizeof(GLfloat)))

static uint32_t nextPowerOfTwo(uint32_t n)
{
      --n;
      n |= n >> 16;
      n |= n >> 8;
      n |= n >> 4;
      n |= n >> 2;
      n |= n >> 1;
      ++n;
      return n;
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
    [EAGLContext setCurrentContext:context];

    CGSize boundsSize = self.bounds.size;
    _powerOf2Bounds.width = (CGFloat)nextPowerOfTwo((uint32_t)boundsSize.width);
    _powerOf2Bounds.height = (CGFloat)nextPowerOfTwo((uint32_t)boundsSize.height);
    
    CGFloat po2WidthScale = _powerOf2Bounds.width / boundsSize.width;
    CGFloat po2HeightScale = _powerOf2Bounds.height / boundsSize.height;
    
    GLfloat yCoord = 0;
    
    GLfloat xStep = ((GLfloat)PAGE_WIDTH * 2) / (2 * X_VERTEX_COUNT - 3);
    GLfloat yStep = ((GLfloat)PAGE_HEIGHT / (Y_VERTEX_COUNT - 1));
    
    // Construct a hex-mesh of triangles;
    for(int row = 0; row < Y_VERTEX_COUNT; ++row) {
        GLfloat xCoord = 0;
        for(int column = 0; column < X_VERTEX_COUNT; ++column) {
            _stablePageVertices[row][column].x = MIN(xCoord, (GLfloat)PAGE_WIDTH);
            _stablePageVertices[row][column].y = MIN(yCoord, (GLfloat)PAGE_HEIGHT);
            // z is already 0.
            
            if(xCoord == 0 && row % 2 == 1) {
                xCoord = xStep / 2;
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
    
    memcpy(_pageVertices, _stablePageVertices, sizeof(_oldPageVertices));
    memcpy(_oldPageVertices, _stablePageVertices, sizeof(_oldPageVertices));
    
    int triangleStripIndex = 0;
    for(int row = 0; row < Y_VERTEX_COUNT - 1; ++row) {
        if(row % 2 == 0) {
            int i = 0;
            _triangleStripIndices[triangleStripIndex++] = indexForPageVertex(i, row);
            for(; i < X_VERTEX_COUNT; ++i) {
                _triangleStripIndices[triangleStripIndex++] = indexForPageVertex(i, row+1);
                _triangleStripIndices[triangleStripIndex++] = indexForPageVertex(i, row);
            }
            _triangleStripIndices[triangleStripIndex++] = indexForPageVertex(X_VERTEX_COUNT - 1, row+1);
            _triangleStripIndices[triangleStripIndex++] = indexForPageVertex(X_VERTEX_COUNT - 1, row+1);
        } else {
            int i = X_VERTEX_COUNT - 1;
            _triangleStripIndices[triangleStripIndex++] = indexForPageVertex(i, row);
            for(; i >= 0; --i) {
                _triangleStripIndices[triangleStripIndex++] = indexForPageVertex(i, row+1);
                _triangleStripIndices[triangleStripIndex++] = indexForPageVertex(i, row);
            } 
            _triangleStripIndices[triangleStripIndex++] = indexForPageVertex(0, row+1);
            _triangleStripIndices[triangleStripIndex++] = indexForPageVertex(0, row+1);
        }
    }
    
    [self _setupConstraints];
    
    NSParameterAssert(triangleStripIndex == TRIANGLE_STRIP_COUNT);
    
    glEnable(GL_TEXTURE_2D);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    GLfloat yAddition = (_powerOf2Bounds.height - boundsSize.height) / _powerOf2Bounds.height;
    for(int row = 0; row < Y_VERTEX_COUNT; ++row) {
        for(int column = 0; column < X_VERTEX_COUNT; ++column) {
            _pageTextureCoordinates[row][column].x = _pageVertices[row][column].x / PAGE_WIDTH / po2WidthScale;
            _pageTextureCoordinates[row][column].y = (1 - (_pageVertices[row][column].y / PAGE_HEIGHT)) / po2HeightScale + yAddition; 
        }
    } 
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Square256X256BookPaper" ofType:@"pvrtc"];
    NSData *squareBookPaper = [[NSData alloc] initWithContentsOfMappedFile:path];
    glGenTextures(1, &_blankPageTexture);
    glBindTexture(GL_TEXTURE_2D, _blankPageTexture);
    texImage2DPVRTC(0, 2, 0, 256, [squareBookPaper bytes]);
    [squareBookPaper release];
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    for(int row = 0; row < Y_VERTEX_COUNT; ++row) {
        for(int column = 0; column < X_VERTEX_COUNT; ++column) {
            _blankPageTextureCoordinates[row][column].x = _pageVertices[row][column].x / PAGE_WIDTH;
            _blankPageTextureCoordinates[row][column].y = _pageVertices[row][column].y / PAGE_HEIGHT;
        }
    }         
    
    path = [[NSBundle mainBundle] pathForResource:@"BookEdge" ofType:@"pvrtc"];
    NSData *bookEdge = [[NSData alloc] initWithContentsOfMappedFile:path];
    glGenTextures(1, &_bookEdgeTexture);
    glBindTexture(GL_TEXTURE_2D, _bookEdgeTexture);
    texImage2DPVRTC(0, 4, 0, 512, [bookEdge bytes]);
    [bookEdge release];
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    
    _textureUploadContext = [[EAGLContext alloc] initWithAPI:[context API] sharegroup:[context sharegroup]];
    
    _animatedTurnData = [[NSData alloc] initWithContentsOfMappedFile:[[NSBundle mainBundle] pathForResource:@"animatedBookTurnVertices" ofType:@"vertexData"]];
    _animatedTurnFrameCount = _animatedTurnData.length / (X_VERTEX_COUNT * Y_VERTEX_COUNT * sizeof(GLfloatTriplet) * 2);
    
    _reverseAnimatedTurnData = [[NSData alloc] initWithContentsOfMappedFile:[[NSBundle mainBundle] pathForResource:@"reverseAnimatedBookTurnVertices" ofType:@"vertexData"]];
    _reverseAnimatedTurnFrameCount = _reverseAnimatedTurnData.length / (X_VERTEX_COUNT * Y_VERTEX_COUNT * sizeof(GLfloatTriplet) * 2);

    
    self.multipleTouchEnabled = YES;
    self.exclusiveTouch = YES;
    //tempFile = fopen("/tmp/vertexdata", "w");
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
    
    [EAGLContext setCurrentContext:context];
    for(int i = 0; i < 4; ++i) {
        [_pageViews[i] release];
        if(_pageTextures[i]) {
            glDeleteTextures(1, &(_pageTextures[i]));
        }
    }
    
    [_animatedTurnData release];
    [_reverseAnimatedTurnData release];

    [_touch release]; // This should actually never be non-nil.
    [super dealloc];
}


- (UIImage *)screenshot
{
    CGRect bounds = self.bounds;
    
    CFIndex capacity = bounds.size.width * bounds.size.height * 4;
    CFMutableDataRef newBitmapData = CFDataCreateMutable(kCFAllocatorDefault, capacity);
    CFDataIncreaseLength(newBitmapData, capacity);

    _atRenderScreenshotBuffer = CFDataGetMutableBytePtr(newBitmapData);
    
    [self drawView];
    
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData(newBitmapData);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef newImageRef = CGImageCreate(bounds.size.width, bounds.size.height,
                                           8, 32, 4 * bounds.size.width, 
                                           colorSpace, 
                                           kCGBitmapByteOrderDefault | kCGImageAlphaLast, 
                                           dataProvider, NULL, YES, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    CGColorSpaceRelease(colorSpace);
    
    // The image is upside-down and back-to-front if we use it directly...
    UIGraphicsBeginImageContext(bounds.size);
    CGContextRef cgContext = UIGraphicsGetCurrentContext();
    CGContextDrawImage(cgContext, bounds, newImageRef);    
    UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRelease(newImageRef);
    CFRelease(newBitmapData);
    _atRenderScreenshotBuffer = nil;
    return ret;
}

- (void)_createTextureIn:(GLuint *)textureRef fromView:(UIView *)newCurrentView;
{
    GLuint width, height;
    CGRect bounds = self.bounds;

    
    width = _powerOf2Bounds.height;
    height = _powerOf2Bounds.width;
    
    size_t byteLength = width * height * 4;
    GLubyte *textureData = (GLubyte *)malloc(byteLength);
    memset(textureData, -1, byteLength);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef textureContext = CGBitmapContextCreate(textureData, width, height, 8, width * 4, 
                                                        colorSpace, kCGImageAlphaPremultipliedLast);
    if([newCurrentView respondsToSelector:@selector(drawRect:inContext:)]) {
        CGContextSetFillColorSpace(textureContext, colorSpace);
        CGContextSetStrokeColorSpace(textureContext, colorSpace); 
        
        [(UIView<THUIViewThreadSafeDrawing> *)newCurrentView drawRect:bounds inContext:textureContext];
    } else {
        [newCurrentView.layer renderInContext:textureContext];
    }
    CGContextRelease(textureContext);
    CGColorSpaceRelease(colorSpace);

    [EAGLContext setCurrentContext:_textureUploadContext];
    if(!*textureRef) { 
        glGenTextures(1, textureRef);
    }
    glBindTexture(GL_TEXTURE_2D, *textureRef); 
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);    
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
    
    free(textureData);
}

- (void)_setView:(UIView *)view forPage:(int)page
{
    if(_pageViews[page] != view) {
        if(_pageViews[page] && [_delegate respondsToSelector:@selector(pageTurningView:discardingView:)]) {
            [_delegate pageTurningView:self discardingView:_pageViews[page]];
        }
        [_pageViews[page] release];
        if(view) {
            [self _createTextureIn:&_pageTextures[page] fromView:view];
        }
        _pageViews[page] = [view retain];
    }
}

- (void)setCurrentPageView:(UIView *)newCurrentView;
{
    if(newCurrentView != _pageViews[1]) {
        [self _setView:[_delegate pageTurningView:self previousViewForView:newCurrentView] forPage:0];
        [self _setView:newCurrentView forPage:1];
        [self _setView:[_delegate pageTurningView:self nextViewForView:newCurrentView] forPage:2];
    }
    _flatPageIndex = 1;
}

- (void)turnToPageView:(UIView *)newCurrentView forwards:(BOOL)forwards pageCount:(NSUInteger)pageCount;
{
    if(newCurrentView != _pageViews[1]) {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        [self _setView:newCurrentView forPage:forwards ? 2 : 0];
        _isTurningAutomatically = YES;
        _automaticTurnIsForwards = forwards;
        if(forwards) {
            _flatPageIndex = 2;
            _automaticTurnFrame = 0;
        } else {
            _flatPageIndex = 1;
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
        
        [self startAnimation];
    }
}

- (UIView *)currentPageView
{
    return _pageViews[1];
}

static inline GLfloatTriplet addVector(GLfloatTriplet a, GLfloatTriplet b)
{
    GLfloatTriplet ret = { a.x + b.x, a.y + b.y, a.z + b.z };
    return ret;
}

static inline GLfloatTriplet subtractVector(GLfloatTriplet a, GLfloatTriplet b)
{
    GLfloatTriplet ret = { a.x - b.x, a.y - b.y, a.z - b.z };
    return ret;
}

static inline GLfloatTriplet multiplyVector(GLfloatTriplet a, GLfloat b)
{
    GLfloatTriplet ret = { a.x * b, a.y * b, a.z * b };
    return ret;
}

static inline GLfloatTriplet crossProduct(GLfloatTriplet a, GLfloatTriplet b)
{
    GLfloatTriplet ret = { a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x};
    return ret;
}

static inline GLfloat dotProduct(GLfloatTriplet a) 
{
    return a.x * a.x + a.y * a.y + a.z * a.z;
}

static inline GLfloat magnitude(GLfloatTriplet a) 
{
    return fabsf(sqrtf(dotProduct(a)));
}

static inline GLfloatTriplet normalise(GLfloatTriplet a)
{
    GLfloat aMagnitude = magnitude(a); 
    GLfloatTriplet ret = { a.x / aMagnitude, a.y / aMagnitude, a.z / aMagnitude};
    return ret;
}


static GLfloatTriplet triangleNormal(GLfloatTriplet left, GLfloatTriplet middle, GLfloatTriplet right)
{
    GLfloatTriplet leftVector = subtractVector(right, middle);
    GLfloatTriplet rightVector = subtractVector(right, left);

    return normalise(crossProduct(leftVector, rightVector));
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
        GLfloatTriplet *flatPageVertices = (GLfloatTriplet *)_pageVertices;
        _constraints[_constraintCount].particleAIndex = indexA;
        _constraints[_constraintCount].particleBIndex = indexB;
        _constraints[_constraintCount].lengthSquared = powf(magnitude(subtractVector(flatPageVertices[indexA], flatPageVertices[indexB])), 2);
        
        ++_constraintCount;
    }
}

- (void)_setupConstraints
{
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
        [self _addConstraintFrom:indexForPageVertex(0, i) to:indexForPageVertex(X_VERTEX_COUNT - 1, i)];
    }    
    for(int i = 0; i < X_VERTEX_COUNT; ++i) {
        [self _addConstraintFrom:indexForPageVertex(i, 0) to:indexForPageVertex(i, Y_VERTEX_COUNT - 1)];
    }
    
    //[self _addConstraintFrom:indexForPageVertex(0, 0) to:indexForPageVertex(X_VERTEX_COUNT - 1, Y_VERTEX_COUNT - 1)];
    //[self _addConstraintFrom:indexForPageVertex(X_VERTEX_COUNT - 1, 0) to:indexForPageVertex(0, Y_VERTEX_COUNT - 1)];  
    
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
    
    GLfloatTriplet *flatPageVertexNormals = (GLfloatTriplet *)_pageVertexNormals;
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
            GLfloatTriplet leftVertex = ((GLfloatTriplet *)_pageVertices)[leftVertexIndex];
            GLfloatTriplet middleVertex = ((GLfloatTriplet *)_pageVertices)[middleVertexIndex];
            GLfloatTriplet rightVertex = ((GLfloatTriplet *)_pageVertices)[rightVertexIndex];
            
            GLfloatTriplet normal = triangleNormal(leftVertex, middleVertex, rightVertex);
            flatPageVertexNormals[leftVertexIndex] = 
                            addVector(flatPageVertexNormals[leftVertexIndex], normal);
            flatPageVertexNormals[middleVertexIndex] = 
                            addVector(flatPageVertexNormals[middleVertexIndex], normal);
            flatPageVertexNormals[rightVertexIndex] = 
                            addVector(flatPageVertexNormals[rightVertexIndex], normal);
        }
    }
    for(int i = 0; i < X_VERTEX_COUNT * Y_VERTEX_COUNT; ++i) {
        flatPageVertexNormals[i] = normalise(flatPageVertexNormals[i]);
    }
}

- (void)drawView 
{        
    if(_animating && !_isTurningAutomatically) {
        //[self _accumulateForces]; // Not used - see comments around implementation.
        [self _verlet];
        [self _satisfyConstraints];
        [self _calculateVertexNormals];
    }
    
    [EAGLContext setCurrentContext:context];
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glRotatef(180, 0, 0, 1);
    FadiGluLookAt(PAGE_WIDTH / 2, PAGE_HEIGHT / 2, 1.5f * -((PAGE_WIDTH /2 ) / tanf(FOV_ANGLE * (float)M_PI / 360.0f)), 
                  PAGE_WIDTH / 2, PAGE_HEIGHT / 2, 0, 
                  0, 1, 0);
    
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    //glOrthof(0, PAGE_WIDTH, PAGE_HEIGHT, 0, -PAGE_WIDTH, 0);
    //glFrustumf(0, 1, 0, 1, 0.5, 1000);
    //gluPerspective(45.0, 1.0, 3.0, 7.0); 
    GLUPerspective(FOV_ANGLE, (GLfloat)PAGE_WIDTH / (GLfloat)PAGE_HEIGHT, 0.5, 1000.0);
    
    glMatrixMode(GL_MODELVIEW);
    
    glClearColor (0.0, 0.0, 0.0, 1.0);
    glShadeModel (GL_SMOOTH);
    
    glLightModelx(GL_LIGHT_MODEL_TWO_SIDE, GL_FALSE);
    
    GLfloat mat_specular[] = { 1.0, 1.0, 1.0, 1.0 };
    GLfloat mat_shininess[] = { 60.0 };
    glMaterialfv(GL_FRONT, GL_SPECULAR, mat_specular);
    glMaterialfv(GL_FRONT, GL_SHININESS, mat_shininess);
    
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    glEnable(GL_DEPTH_TEST);
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    GLfloat lightY = PAGE_WIDTH * (1.79f - (_dimQuotient * (1.79f - 0.3f)));
    GLfloat constantAttenuation = 0.55f + (_dimQuotient * (0.9f - 0.55f));
    
    GLfloat lightPosition[] = { PAGE_WIDTH / 2, PAGE_HEIGHT / 2 - PAGE_WIDTH / 4, -lightY, 1.0f};
    GLfloat noAmbient[] = {0.2f, 0.2f, 0.2f, 1.0f};
    GLfloat whiteDiffuse[] = {1.0f, 1.0f, 1.0f, 1.0f};
    glLightfv(GL_LIGHT0, GL_AMBIENT, noAmbient);
    glLightfv(GL_LIGHT0, GL_DIFFUSE, whiteDiffuse);
    glLightfv(GL_LIGHT0, GL_POSITION, lightPosition);
    
    glLightf(GL_LIGHT0, GL_CONSTANT_ATTENUATION, constantAttenuation);
    glLightf(GL_LIGHT0, GL_LINEAR_ATTENUATION, 0.05f);
    glLightf(GL_LIGHT0, GL_QUADRATIC_ATTENUATION, 0.0f);

    glTexCoordPointer(2, GL_FLOAT, 0, _pageTextureCoordinates);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    glBindTexture(GL_TEXTURE_2D, _pageTextures[_flatPageIndex]);

    glVertexPointer(3, GL_FLOAT, 0, _stablePageVertices);
    glEnableClientState(GL_VERTEX_ARRAY);
    
    glNormalPointer(GL_FLOAT, 0, _stablePageVertexNormals);
    glEnableClientState(GL_NORMAL_ARRAY);
    
    glDrawElements(GL_TRIANGLE_STRIP, TRIANGLE_STRIP_COUNT, GL_UNSIGNED_BYTE, _triangleStripIndices);
    
    if(_animating) {
        glClear(GL_DEPTH_BUFFER_BIT);
            
        glBindTexture(GL_TEXTURE_2D, _pageTextures[_flatPageIndex-1]);

        const GLfloatTriplet *pageVertices, *pageVertexNormals;        
        if(!_isTurningAutomatically) {
            pageVertices = (GLfloatTriplet *)_pageVertices;
            pageVertexNormals = (GLfloatTriplet *)_pageVertexNormals;
            
            //fwrite(pageVertices, sizeof(GLfloatTriplet), X_VERTEX_COUNT * Y_VERTEX_COUNT, tempFile);
            //fwrite(pageVertexNormals, sizeof(GLfloatTriplet), X_VERTEX_COUNT * Y_VERTEX_COUNT, tempFile);
            //fflush(tempFile);
        } else {
            if(!_automaticTurnIsForwards && _automaticTurnFrame == _reverseAnimatedTurnFrameCount) {
                pageVertices = (const GLfloatTriplet *)_stablePageVertices;
                pageVertexNormals = (const GLfloatTriplet *)_stablePageVertexNormals;
            } else {
                pageVertices = (const GLfloatTriplet *)[_automaticTurnIsForwards ? _animatedTurnData : _reverseAnimatedTurnData bytes] + (X_VERTEX_COUNT * Y_VERTEX_COUNT * 2) * _automaticTurnFrame;
                pageVertexNormals = pageVertices + (X_VERTEX_COUNT * Y_VERTEX_COUNT);
            }
        }
            
        glVertexPointer(3, GL_FLOAT, 0, pageVertices);
        glEnableClientState(GL_VERTEX_ARRAY);
        
        glNormalPointer(GL_FLOAT, 0, pageVertexNormals);
        glEnableClientState(GL_NORMAL_ARRAY);

        // The front faces of the page.
        if(!_isTurningAutomatically || pageVertexNormals == (const GLfloatTriplet *)_stablePageVertexNormals) {
            // The normals in the automatic turn files are acidentally facing
            // backwards.  I should really re-record them.
            // Instead, for the moment, we draw the face below, after we've
            // inverted the normals.
            glDrawElements(GL_TRIANGLE_STRIP, TRIANGLE_STRIP_COUNT - 2, GL_UNSIGNED_BYTE, _triangleStripIndices);
        }
        
        // Flip the normals and draw the back faces.
        GLfloatTriplet invertedPageVertexNormals[X_VERTEX_COUNT * Y_VERTEX_COUNT];
        for(int i = 0; i < X_VERTEX_COUNT * Y_VERTEX_COUNT; ++i) {
            invertedPageVertexNormals[i].x = -(pageVertexNormals)[i].x;
            invertedPageVertexNormals[i].y = -(pageVertexNormals)[i].y;
            invertedPageVertexNormals[i].z = -(pageVertexNormals)[i].z;
        }
        
        glNormalPointer(GL_FLOAT, 0, invertedPageVertexNormals);
        glEnableClientState(GL_NORMAL_ARRAY);

        if(_isTurningAutomatically && pageVertexNormals != (const GLfloatTriplet *)_stablePageVertexNormals) {
            // Compensating for the normals in the automatic turn files being 
            // backwards (see above).
            glDrawElements(GL_TRIANGLE_STRIP, TRIANGLE_STRIP_COUNT - 2, GL_UNSIGNED_BYTE, _triangleStripIndices);
            
            // Because the normals are backwards, we use the non-inverted
            // (really, the inverted) ones to draw the back face.
            glNormalPointer(GL_FLOAT, 0, pageVertexNormals);
            glEnableClientState(GL_NORMAL_ARRAY);
        }        
        
        glBindTexture(GL_TEXTURE_2D, _blankPageTexture);
        glTexCoordPointer(2, GL_FLOAT, 0, _blankPageTextureCoordinates);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        
        // By starting 1 into the triangle strip in glDrawElements, we draw the
        // strip with the opposite winding order, making the back the front (the
        // first triangle is degenerate anyway, so skippable).        
        glDrawElements(GL_TRIANGLE_STRIP, TRIANGLE_STRIP_COUNT - 3, GL_UNSIGNED_BYTE, _triangleStripIndices + 1);
        
        

        if(_isTurningAutomatically) {
            if(_automaticTurnPercentage > 0.0f) {
                GLfloatTriplet pageEdge[Y_VERTEX_COUNT][2];
                GLfloatTriplet pageEdgeNormals[Y_VERTEX_COUNT * 2] = { {0, 0, 0} };
                int column = X_VERTEX_COUNT - 1;
                for(int row = 0; row < Y_VERTEX_COUNT; ++row) {
                    pageEdge[row][0] = addVector(pageVertices[row * X_VERTEX_COUNT + column] , 
                                                 multiplyVector(pageVertexNormals[row * X_VERTEX_COUNT + column], _automaticTurnPercentage));
                    pageEdge[row][1] = pageVertices[row * X_VERTEX_COUNT + column];
                } 
                GLfloatTriplet *flatPageEdge = (GLfloatTriplet *)pageEdge;
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
                    GLfloatTriplet leftVertex = flatPageEdge[leftVertexIndex];
                    GLfloatTriplet middleVertex = flatPageEdge[middleVertexIndex];
                    GLfloatTriplet rightVertex = flatPageEdge[rightVertexIndex];
                    
                    GLfloatTriplet normal = triangleNormal(leftVertex, middleVertex, rightVertex);
                    pageEdgeNormals[leftVertexIndex] = 
                        addVector(pageEdgeNormals[leftVertexIndex], normal);
                    pageEdgeNormals[middleVertexIndex] = 
                        addVector(pageEdgeNormals[middleVertexIndex], normal);
                    pageEdgeNormals[rightVertexIndex] = 
                        addVector(pageEdgeNormals[rightVertexIndex], normal);            
                } 
                for(int i = 0; i < Y_VERTEX_COUNT * 2; ++i) {
                    pageEdgeNormals[i] = normalise(pageEdgeNormals[i]);
                }
                
                glClear(GL_DEPTH_BUFFER_BIT);
            
                glVertexPointer(3, GL_FLOAT, 0, pageEdge);
                glEnableClientState(GL_VERTEX_ARRAY);

                glNormalPointer(GL_FLOAT, 0, pageEdgeNormals);
                glEnableClientState(GL_NORMAL_ARRAY);
                
                glBindTexture(GL_TEXTURE_2D, _bookEdgeTexture);
                glTexCoordPointer(2, GL_FLOAT, 0, _pageEdgeTextureCoordinates);
                glEnableClientState(GL_TEXTURE_COORD_ARRAY);        
                
                glDrawArrays(GL_TRIANGLE_STRIP, 0, Y_VERTEX_COUNT * 2);
            }
            
            if(++_automaticTurnFrame >= (_automaticTurnIsForwards ? _animatedTurnFrameCount : (_reverseAnimatedTurnFrameCount + 1))) {
                [self stopAnimation];
                [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                
                _isTurningAutomatically = NO;
                _viewsNeedRecache = YES;
                
                if(_flatPageIndex == 2) {
                    UIView *tempView = _pageViews[0];
                    _pageViews[0] = _pageViews[1];
                    _pageViews[1] = _pageViews[2];
                    _pageViews[2] = tempView;
                    
                    GLuint tempTex = _pageTextures[0];
                    _pageTextures[0] = _pageTextures[1];
                    _pageTextures[1] = _pageTextures[2];
                    _pageTextures[2] = tempTex;
                    _flatPageIndex = 1;
                } else {
                    UIView *tempView = _pageViews[2];
                    _pageViews[2] = _pageViews[1];
                    _pageViews[1] = _pageViews[0];
                    _pageViews[0] = tempView;
                    
                    GLuint tempTex = _pageTextures[2];
                    _pageTextures[2] = _pageTextures[1];
                    _pageTextures[1] = _pageTextures[0];
                    _pageTextures[0] = tempTex;
                }
                
                _recacheFlags[0] = YES;
                _recacheFlags[2] = YES;
            }
        } 
        
        /*
        GLfloatTriplet normals[Y_VERTEX_COUNT][X_VERTEX_COUNT][2];
        for(int row = 0; row < Y_VERTEX_COUNT; ++row) {
            for(int column = 0; column < X_VERTEX_COUNT; ++column) {
                normals[row][column][0] = _pageVertices[row][column];
                normals[row][column][1] = addVector(_pageVertices[row][column], _pageVertexNormals[row][column]);
            }
        } 
        
        glClear(GL_DEPTH_BUFFER_BIT);
        glColor4f(1, 0, 0, 1);
        glVertexPointer(3, GL_FLOAT, 0, normals);
        glEnableClientState(GL_NORMAL_ARRAY);
        glDrawArrays(GL_LINES, 0, Y_VERTEX_COUNT * X_VERTEX_COUNT * 2);
        */        
    }
    
    if(_atRenderScreenshotBuffer) {
        CGRect bounds = self.bounds;
        glReadPixels(0, 0, bounds.size.width, bounds.size.height, GL_RGBA, GL_UNSIGNED_BYTE, _atRenderScreenshotBuffer);
    }
        
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];

    if(_viewsNeedRecache) {
        [self _postAnimationViewAndTextureRecache];
    }
}

- (void)setTouchPointForX:(GLfloat)x
{
    _touchPoint.x = x;
    _touchPoint.y = ((GLfloat)_touchRow / (Y_VERTEX_COUNT - 1)) * PAGE_HEIGHT;
    _touchPoint.z = - PAGE_WIDTH * sqrtf(-(powf((x/PAGE_WIDTH), 2) - 1));    
}

- (void)setTouchLocationFromTouch:(UITouch *)touch firstTouch:(BOOL)first;
{
    CGSize size = self.bounds.size;
    CGPoint viewTouchPoint =  [touch locationInView:self];

    GLfloatPair modelTouchPoint = { (viewTouchPoint.x / size.width) * PAGE_WIDTH,
                                    (viewTouchPoint.y / size.height) * PAGE_HEIGHT };
    
    _touchRow = ((modelTouchPoint.y / PAGE_HEIGHT) + 0.5f / Y_VERTEX_COUNT) * (Y_VERTEX_COUNT - 1);
    if(first) {
        _touchXOffset = _pageVertices[_touchRow][X_VERTEX_COUNT - 1].x - modelTouchPoint.x;
    }
    
    modelTouchPoint.x =  modelTouchPoint.x + _touchXOffset;
    if(modelTouchPoint.x > PAGE_WIDTH) {
        modelTouchPoint.x = PAGE_WIDTH;
    } 
    NSTimeInterval thisTouchTime = [touch timestamp];
    if(_touchTime) {
        GLfloat difference = (GLfloat)(thisTouchTime - _touchTime);
        if(difference) {
            _touchVelocity = (modelTouchPoint.x - _touchPoint.x) / (30 * difference);
        } else {
            _touchVelocity = 0;
        }
    }
    _touchTime = thisTouchTime;
    [self setTouchPointForX:modelTouchPoint.x];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    // If we're not currently tracking a touch
    if(!_touch) {
        // Store touch
        _touch = [touch retain];
        if(_animating) {
            [self setTouchLocationFromTouch:_touch firstTouch:YES];
        } else {
            _vibrated = NO;
        }
    }
    
    if(_animating || _vibrated) {
        // We've already started to turn the page.
        // Remove the touch we're 'using' and pass the rest on.
        NSMutableSet *unusedTouches = [touches mutableCopy];
        [unusedTouches removeObject:_touch];
        if(unusedTouches.count) {
            [_pageViews[1] touchesBegan:unusedTouches withEvent:event];
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
                    _pinchTouches[1] = [secondTouch retain];
                    break;
                }
            }
            
            _pinchStartPoints[0] = [_pinchTouches[0] locationInView:self];
            _pinchStartPoints[1] = [_pinchTouches[1] locationInView:self];
            
            THLog(@"Pinch Began: %@, %@", NSStringFromCGPoint(_pinchStartPoints[0]), NSStringFromCGPoint(_pinchStartPoints[1]));
        }
        
        [_pageViews[1] touchesBegan:touches withEvent:event];
    }
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if([touches containsObject:_touch]) {
        // If first movement
        if(!_animating) {
            // Store touch, note direction.
            BOOL shouldAnimate = YES;
            CGPoint location = [_touch locationInView:self];
            CGPoint previousLocation = [_touch previousLocationInView:self];
            if(!_animating && previousLocation.x < location.x) {
                if(_pageViews[0]) {
                    for(int column = 1; column < X_VERTEX_COUNT; ++column) {
                        for(int row = 0; row < Y_VERTEX_COUNT; ++row) {                            
                            GLfloat radius = _pageVertices[row][column].x;                            
                            _pageVertices[row][column].z = -radius * sinf(((GLfloat)M_PI - (FOV_ANGLE / (360.0f * (GLfloat)M_2_PI))) / 2.0f);
                            _pageVertices[row][column].x = radius * cosf(((GLfloat)M_PI - (FOV_ANGLE / (360.0f * (GLfloat)M_2_PI))) / 2.0f);
                        }
                    }                    
                } else {
                    shouldAnimate = NO;
                }
            } else if (!_animating) {
                if(_pageViews[2]) {
                    _flatPageIndex = 2;
                } else {
                    shouldAnimate = NO;
                }
            }
            if(!_animating && !_vibrated) {
                [_pageViews[1] touchesCancelled:[NSSet setWithObject:_touch] withEvent:event];
            }
            if(shouldAnimate) {
                _vibrated = NO;
                [self setTouchLocationFromTouch:_touch firstTouch:YES];
                [self startAnimation];
            } else {
                if(!_vibrated) {
                    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
                    _vibrated = YES;
                }
            }
        } else if(!_vibrated) {
            // Set touch location
            [self setTouchLocationFromTouch:_touch firstTouch:NO];
        }
    } else if([touches containsObject:_pinchTouches[0]] || [touches containsObject:_pinchTouches[1]]) {
        if(!_pinchUnderway) {
            [THBackgroundProcessingMediator curtailBackgroundProcessing];
            [_pageViews[1] touchesCancelled:[NSSet setWithObjects:_pinchTouches count:2] withEvent:event];
            _pinchUnderway = YES;
        }        
        
        if([_delegate respondsToSelector:@selector(pageTurningView:scaledViewForView:pinchStartedAt:pinchNowAt:currentScaledView:)]) {
            CGPoint currentPinchPoints[2] = { [_pinchTouches[0] locationInView:self], [_pinchTouches[1] locationInView:self] };
            UIView *scaledView = [_delegate pageTurningView:self 
                                          scaledViewForView:_pageViews[1] 
                                             pinchStartedAt:_pinchStartPoints
                                                 pinchNowAt:currentPinchPoints
                                          currentScaledView:_pageViews[3]];
            if(scaledView && scaledView != _pageViews[3]) {
                [self _setView:scaledView forPage:3];
                _flatPageIndex = 3;
                
                //NSLog(@"Pinch %f -> %f, scalefactor %f", (float)startDistance,(float)nowDistance, (float)(nowDistance / startDistance));
                
                [self drawView];
            }
        }
    }
    
    if(_animating || _vibrated || _pinchUnderway) {
        NSMutableSet *unusedTouches = [touches mutableCopy];
        if(_touch) {
            [unusedTouches removeObject:_touch];
        } 
        if(_pinchTouches[0]) {
            [unusedTouches removeObject:_pinchTouches[0]];
        }
        if(_pinchTouches[1]) {
            [unusedTouches removeObject:_pinchTouches[1]];
        }
        if(unusedTouches.count) {
            [_pageViews[1] touchesMoved:unusedTouches withEvent:event];
        }
        [unusedTouches release];
    } else {
        [_pageViews[1] touchesMoved:touches withEvent:event];
    }    
}

- (void)_touchesEndedOrCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if([touches containsObject:_touch]) {
        if([event timestamp] > [_touch timestamp] + 0.1) {
            [self setTouchLocationFromTouch:_touch firstTouch:NO];
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
        _touchPoint.x = _pageVertices[_touchRow][X_VERTEX_COUNT - 1].x;
        _touchTime = 0;
        
        [_touch release];
        _touch = nil;
    } else if([touches containsObject:_pinchTouches[0]] || [touches containsObject:_pinchTouches[1]]) {
        UITouch *remainingTouch = nil;
        if(![touches containsObject:_pinchTouches[0]]) {
            remainingTouch = _pinchTouches[0];
        } else if(![touches containsObject:_pinchTouches[1]]) {
            remainingTouch = _pinchTouches[1];
        }
        
        [_pinchTouches[0] release];
        _pinchTouches[0] = nil;
        [_pinchTouches[1] release];
        _pinchTouches[1] = nil;
        
        if(_pinchUnderway) {
            _pinchUnderway = NO;            
            if(_pageViews[3]) {
                UIView *tempView = _pageViews[1];
                _pageViews[1] = _pageViews[3];
                _pageViews[3] = tempView;
                
                GLuint tempTex = _pageTextures[1];
                _pageTextures[1] = _pageTextures[3];
                _pageTextures[3] = tempTex;            
                
                [self _setView:nil forPage:3];
                _flatPageIndex = 1;

                if([_delegate respondsToSelector:@selector(pageTurningView:didScaleToView:)]) {
                    [_delegate pageTurningView:self didScaleToView:_pageViews[1]];
                }
                
                [self _setView:[_delegate pageTurningView:self previousViewForView:_pageViews[1]] forPage:0];
                [self _setView:[_delegate pageTurningView:self nextViewForView:_pageViews[1]] forPage:2];

                [self drawView];
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
    if(_animating || _vibrated) {
        NSMutableSet *unusedTouches = [touches mutableCopy];
        if(_touch) {
            [unusedTouches removeObject:_touch];
        }
        if(unusedTouches.count) {
            [_pageViews[1] touchesEnded:unusedTouches withEvent:event];
        }
        [unusedTouches release];
    } else if(_pinchUnderway) {
        NSMutableSet *unusedTouches = [touches mutableCopy];
        if(_pinchTouches[0]) {
            [unusedTouches removeObject:_pinchTouches[0]];
        }
        if(_pinchTouches[1]) {
            [unusedTouches removeObject:_pinchTouches[1]];
        }
        if(unusedTouches.count) {
            [_pageViews[1] touchesEnded:unusedTouches withEvent:event];
        }
        [unusedTouches release];     
    } else {
        [_pageViews[1] touchesEnded:touches withEvent:event];
    }
    [self _touchesEndedOrCancelled:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(_animating || _vibrated) {
        NSMutableSet *unusedTouches = [touches mutableCopy];
        if(_touch) {
            [unusedTouches removeObject:_touch];
        }
        if(unusedTouches.count) {
            [_pageViews[1] touchesCancelled:unusedTouches withEvent:event];
        }
        [unusedTouches release];
    } else if(_pinchUnderway) {
        NSMutableSet *unusedTouches = [touches mutableCopy];
        if(_pinchTouches[0]) {
            [unusedTouches removeObject:_pinchTouches[0]];
        }
        if(_pinchTouches[1]) {
            [unusedTouches removeObject:_pinchTouches[1]];
        }
        if(unusedTouches.count) {
            [_pageViews[1] touchesCancelled:unusedTouches withEvent:event];
        }
        [unusedTouches release];        
    } else {
        [_pageViews[1] touchesCancelled:touches withEvent:event];
    }
    [self _touchesEndedOrCancelled:touches withEvent:event];
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
        GLfloat newX = _touchPoint.x + _touchVelocity /** difference*/;
        if(newX > PAGE_WIDTH) {
            newX = PAGE_WIDTH;
        } 
        [self setTouchPointForX:newX];
    }
    
    GLfloatTriplet *flatPageVertices = (GLfloatTriplet *)_pageVertices;
    GLfloatTriplet *flatOldPageVertices = (GLfloatTriplet *)_oldPageVertices;
    //GLfloatTriplet *flatForceAccumulators = (GLfloatTriplet *)_forceAccumulators;
    GLfloat gravity = (_touch || _touchVelocity) ? 0.002 : 0.01;
    
    for(int i = 0; i < X_VERTEX_COUNT * Y_VERTEX_COUNT; ++i) {
        GLfloatTriplet x = flatPageVertices[i];
        GLfloatTriplet temp = x;
        GLfloatTriplet oldx = flatOldPageVertices[i];
        //GLfloatTriplet a = flatForceAccumulators[i];
        
        // This gives better time-correct movement, but makes the model unstable.
        //flatPageVertices[i] = addVector(x, addVector(multiplyVector(multiplyVector(subtractVector(x, oldx), (_touch || _touchVelocity) ? 0.6 : 0.99), (difference / previousDifference)), multiplyVector(a, difference * difference))); // Should add timestep ^ 2 here if it might vary.   
       
        //flatPageVertices[i] = addVector(x, addVector(multiplyVector(subtractVector(x, oldx), (_touch || _touchVelocity) ? 0.6f : 0.99f), a));  
        
        // The above, commented out line is correct, but for optimization, 
        // we just manually add gravity instead of using the forces from 
        // -_accumulateForces since it's the only force.
        flatPageVertices[i] = addVector(x, multiplyVector(subtractVector(x, oldx), (_touch || _touchVelocity) ? 0.6f : 0.99f)); 
        flatPageVertices[i].z += gravity;
        
        flatOldPageVertices[i] = temp;
    }
}

#define NUM_ITERATIONS 40

- (void)_satisfyConstraints
{
    BOOL pageHasRigidEdge;
    if([_delegate respondsToSelector:@selector(pageTurningView:viewEdgeIsRigid:)]) {
        pageHasRigidEdge = [_delegate pageTurningView:self viewEdgeIsRigid:_pageViews[_flatPageIndex-1]];
    } else {
        pageHasRigidEdge = NO;
    }
    
    GLfloatTriplet *flatPageVertices = (GLfloatTriplet *)_pageVertices;
    int j;
    for(j=0; j < NUM_ITERATIONS; ++j) {              
        if(_touch || _touchVelocity) {        
            _pageVertices[MAX(0, _touchRow-1)][X_VERTEX_COUNT - 1].x = _touchPoint.x;
            _pageVertices[_touchRow][X_VERTEX_COUNT - 1] = _touchPoint;
            _pageVertices[MIN(Y_VERTEX_COUNT - 1, _touchRow+1)][X_VERTEX_COUNT - 1].x = _touchPoint.x;
        }
        
        for(int i = 0; i < CONSTRAINT_COUNT; ++i) {
            VerletContstraint constraint = _constraints[i];
            GLfloatTriplet a = flatPageVertices[constraint.particleAIndex];
            GLfloatTriplet b = flatPageVertices[constraint.particleBIndex];
            GLfloatTriplet delta = subtractVector(b, a);
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
            delta = multiplyVector(delta, contraintLengthSquared/(dotProduct(delta)+contraintLengthSquared)-0.5);
            flatPageVertices[constraint.particleAIndex] = subtractVector(a, delta); 
            flatPageVertices[constraint.particleBIndex] = addVector(b, delta); 
            flatPageVertices[constraint.particleAIndex].z = MIN(0, flatPageVertices[constraint.particleAIndex].z);
            flatPageVertices[constraint.particleBIndex].z = MIN(0, flatPageVertices[constraint.particleBIndex].z);            
        }
        
        
        // Make sure the page is attached to the edge, and
        // above the surface.
        BOOL isFlat = !_touch && _touchVelocity >= 0;
        BOOL hasFlipped = !_touch && _touchVelocity <= 0;
        GLfloat yStep = ((GLfloat)PAGE_HEIGHT / (Y_VERTEX_COUNT - 1));
        GLfloat yCoord = 0;
        for(int row = 0; row < Y_VERTEX_COUNT; ++row) {
            for(int column = 0; column < X_VERTEX_COUNT; ++column) {
                GLfloatTriplet vertex = _pageVertices[row][column];
                
                GLfloat diff = yCoord - vertex.y;
                _pageVertices[row][column].y = (vertex.y += diff * 0.5f);

                /*if(!_touch) {
                    if(fabsf(vertex.x - _stablePageVertices[row][column].x) <=  0.0125) {
                    //    _pageVertices[row][column].x = (vertex.x =  _stablePageVertices[row][column].x);
                    } else if(isFlat) {
                        isFlat = NO;
                    } 
                    if(fabsf(vertex.y - yCoord) <= 0.0125) {
                    //    _pageVertices[row][column].y = (vertex.y = _stablePageVertices[row][column].y);
                    } else if(isFlat) {
                        isFlat = NO;
                    } 
                }*/
                
                //if(vertex.z > 0) {
                //    _pageVertices[row][column].z = (vertex.z = 0);
                //} 
                        
                if(hasFlipped &&
                   (column > 0 && vertex.x > 0 && 
                    atanf(-vertex.z / vertex.x) < (((GLfloat)M_PI - (FOV_ANGLE / (360.0f * (GLfloat)M_2_PI))) / 2.0f))) { 
                    hasFlipped = NO;
                }
            }
                                    
            _pageVertices[row][0].x = 0;
            _pageVertices[row][0].z = 0;
            _pageVertices[row][0].y = yCoord;
            

            if(_pageVertices[row][X_VERTEX_COUNT - 1].x > (PAGE_WIDTH - 0.0125f)) {
                _pageVertices[row][X_VERTEX_COUNT - 1].x = PAGE_WIDTH;
            } else {
                if(isFlat) {
                    isFlat = NO;
                }                
                if(_touch || _touchVelocity) {
                    if(pageHasRigidEdge) {
                        _pageVertices[row][X_VERTEX_COUNT - 1].x = _touchPoint.x;
                        _pageVertices[row][X_VERTEX_COUNT - 1].z = _touchPoint.z;
                    } else {
                        GLfloat diff = _touchPoint.x - _pageVertices[row][X_VERTEX_COUNT - 1].x;
                        _pageVertices[row][X_VERTEX_COUNT - 1].x += diff * 0.2f;
                    }
                }
            }
            

            yCoord += yStep;
            if(yCoord > PAGE_HEIGHT) {
                yCoord = PAGE_HEIGHT;
            }            
        }
        
        if(isFlat || hasFlipped) {
            memcpy(_pageVertices, _stablePageVertices, sizeof(_stablePageVertices));
            memcpy(_oldPageVertices, _stablePageVertices, sizeof(_stablePageVertices));
            [self stopAnimation];
            _touchVelocity = 0;
            
            if(_flatPageIndex == 2) {
                if(hasFlipped) {
                    UIView *tempView = _pageViews[0];
                    _pageViews[0] = _pageViews[1];
                    _pageViews[1] = _pageViews[2];
                    _pageViews[2] = tempView;
                    
                    GLuint tempTex = _pageTextures[0];
                    _pageTextures[0] = _pageTextures[1];
                    _pageTextures[1] = _pageTextures[2];
                    _pageTextures[2] = tempTex;
                    _viewsNeedRecache = YES;
                    _recacheFlags[2] = YES;
                } 
                _flatPageIndex = 1;
            } else {
                if(!hasFlipped) {
                    UIView *tempView = _pageViews[2];
                    _pageViews[2] = _pageViews[1];
                    _pageViews[1] = _pageViews[0];
                    _pageViews[0] = tempView;
                    
                    GLuint tempTex = _pageTextures[2];
                    _pageTextures[2] = _pageTextures[1];
                    _pageTextures[1] = _pageTextures[0];
                    _pageTextures[0] = tempTex;
                    _viewsNeedRecache = YES;
                    _recacheFlags[0] = YES;
                }
            }  
            break;
        }
    }
}

- (void)_postAnimationViewAndTextureRecache
{
    if(_recacheFlags[0]) {
        [self _setView:[_delegate pageTurningView:self previousViewForView:_pageViews[1]] forPage:0];
        _recacheFlags[0] = NO;
    }     
    if(_recacheFlags[2]) {
        //THTimer *timr = [THTimer timerWithName:@"20 View Caches"];
        //for(int i = 0; i < 20; ++i) {
            //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            //[self _setView:[_delegate pageTurningView:self nextViewForView:_pageViews[i == 0 ?  1 : 2]] forPage:2];
            //[pool drain];
        //}
        //[timr report];
        [self _setView:[_delegate pageTurningView:self nextViewForView:_pageViews[1]] forPage:2];
        _recacheFlags[2] = NO;
    }
    if([_delegate respondsToSelector:@selector(pageTurningView:didTurnToView:)]) {
        [_delegate pageTurningView:self didTurnToView:_pageViews[1]];
    }                    
    _viewsNeedRecache = NO;
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

@end
