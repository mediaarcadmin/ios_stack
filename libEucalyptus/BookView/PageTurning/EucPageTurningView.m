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
#import "THEmbeddedResourceManager.h"

#define FOV_ANGLE ((GLfloat)10.0f)

static CATransform3D THCATransform3DLookAt(CATransform3D modelViewMatrix,
                                           THVec3 eye,
                                           THVec3 lookAt, 
                                           THVec3 up) 
{
    THVec3 viewingVetor = THVec3Normalize(THVec3Subtract(lookAt, eye));

    THVec3 side  = THVec3Normalize(THVec3CrossProduct(viewingVetor, up));
    THVec3 newUp = THVec3Normalize(THVec3CrossProduct(side, viewingVetor));
    
    CATransform3D result = { side.x,  newUp.x, -viewingVetor.x, 0.0f,
                             side.y,  newUp.y, -viewingVetor.y, 0.0f,
                             side.z,  newUp.z, -viewingVetor.z, 0.0f,
                             0.0f,    0.0f,    0.0f,            1.0f };

    result = CATransform3DConcat(modelViewMatrix, result);
    result = CATransform3DTranslate(result, -eye.x, -eye.y, -eye.z);
    
    return result;
}

static CATransform3D THCATransform3DPerspective(CATransform3D perspectiveMatrix, GLfloat fovy, GLfloat aspect, GLfloat near, GLfloat far) 
{ 
    GLfloat left, right, bottom, top;      
    
    top = near * tanf(fovy * (float)M_PI / 360.0f);   
    bottom = -top; 
    
    left = bottom * aspect;
    right = top * aspect;  
        
    GLfloat twoNear = 2.0f * near;
    GLfloat deltaX = right - left;
    GLfloat deltaY = top - bottom;
    GLfloat deltaz = far - near;
    
    CATransform3D m = { twoNear / deltaX, 0.0f, 0.0f, 0.0f,
                        0.0f, twoNear / deltaY, 0.0f, 0.0f,
                        (right + left) / deltaX, (top + bottom) / deltaY, -(far + near) / deltaz, -1.0f,
                        0.0f, 0.0f, (-twoNear * far) / deltaz, 0.0f };
    
    return CATransform3DConcat(perspectiveMatrix, m); 
} 

@interface EucPageTurningView ()

- (void)_calculateVertexNormals;    
//- (void)_accumulateForces;  // Not used - see comments around implementation.
- (void)_verlet;
- (BOOL)_satisfyConstraints;
- (void)_setupConstraints;
- (void)_postAnimationViewAndTextureRecache;
- (CGFloat)_tapTurnMarginForView:(UIView *)view;
- (void)_setNeedsAccessibilityElementsRebuild;

@end

@implementation EucPageTurningView

@synthesize delegate = _delegate;

@synthesize viewDataSource = _viewDataSource;
@synthesize bitmapDataSource = _bitmapDataSource;

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
            if([_delegate respondsToSelector:@selector(pageTurningViewAnimationWillBegin:)]) {
                [_delegate pageTurningViewAnimationWillBegin:self];   
            }
            [THBackgroundProcessingMediator curtailBackgroundProcessing];
            super.animating = YES;
        }
    } else {
        if(self.isAnimating) {
            // Allow background tasks again.
            [THBackgroundProcessingMediator allowBackgroundProcessing];
            super.animating = NO;
            if([_delegate respondsToSelector:@selector(pageTurningViewAnimationDidEnd:)]) {
                [_delegate pageTurningViewAnimationDidEnd:self];   
            }        
        }
    }
}

#define indexForPageVertex(column, row)  ((row) * X_VERTEX_COUNT + (column))

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
        
    NSParameterAssert(triangleStripIndex == TRIANGLE_STRIP_COUNT);
        
    EAGLContext *eaglContext = self.eaglContext;
    [EAGLContext setCurrentContext:eaglContext];
    
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
        _pageContentsInformation[i].textureCoordinates = calloc(1, sizeof(TextureCoordinates));
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
    for(int i = 0; i < 4; ++i) {
        [_pageContentsInformation[i].view release];
        if(_pageContentsInformation[i].texture) {
            glDeleteTextures(1, &(_pageContentsInformation[i].texture));
        }
        free(_pageContentsInformation[i].textureCoordinates);
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

- (void)setPageAspectRatio:(CGFloat)pageAspectRatio
{
    if(_pageAspectRatio != pageAspectRatio) {
        _pageAspectRatio = pageAspectRatio;
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews
{    
    CGSize size = self.bounds.size;
    if(size.width < size.height) {
        _viewportLogicalSize.width = 4.0f;
        _viewportLogicalSize.height = (size.height / size.width) * _viewportLogicalSize.width;
    } else {
        _viewportLogicalSize.height = 4.0f;
        _viewportLogicalSize.width = (size.width / size.height) * _viewportLogicalSize.height;
    }
    
    // Construct a hex-mesh of triangles:
    CGSize pageSize;
    if(_pageAspectRatio == 0.0f) {
        pageSize = _viewportLogicalSize;
    } else {
        pageSize.height = _viewportLogicalSize.height;
        pageSize.width =  pageSize.height * _pageAspectRatio;
        if(pageSize.width > _viewportLogicalSize.width) {
            pageSize.width = _viewportLogicalSize.width;
            pageSize.height = pageSize.width / _pageAspectRatio;
        }        
    }
    GLfloat xStep = ((GLfloat)pageSize.width * 2) / (2 * X_VERTEX_COUNT - 3);
    GLfloat yStep = ((GLfloat)pageSize.height / (Y_VERTEX_COUNT - 1));
    GLfloat baseXCoord = (_viewportLogicalSize.width - pageSize.width) * 0.5f;
    GLfloat yCoord = (_viewportLogicalSize.height - pageSize.height) * 0.5f;

    _pageFrame = CGRectMake(baseXCoord, yCoord, pageSize.width, pageSize.height);
    
    GLfloat maxX = pageSize.width + baseXCoord;
    GLfloat maxY = pageSize.height + yCoord;
        
    for(int row = 0; row < Y_VERTEX_COUNT; ++row) {
        GLfloat xCoord = baseXCoord;
        for(int column = 0; column < X_VERTEX_COUNT; ++column) {
            _stablePageVertices[row][column].x = MIN(xCoord, maxX);
            _stablePageVertices[row][column].y = MIN(yCoord, maxY);
            // z is already 0.
            
            if(xCoord == baseXCoord && (row % 2) == 1) {
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
    
    [super layoutSubviews];
    
    [self setNeedsDraw];
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

- (void)_createTextureIn:(GLuint *)textureRef 
   fromRGBABitmapContext:(CGContextRef)context
   setTextureCoordinates:(TextureCoordinates *)coordinates
{
    size_t contextWidth = CGBitmapContextGetWidth(context);
    size_t contextHeight = CGBitmapContextGetHeight(context);

    size_t powerOfTwoWidth;
    size_t powerOfTwoHeight;
    
    [EAGLContext setCurrentContext:_textureUploadContext];
    
    BOOL newTextureSize = NO;
    BOOL dataIsNonContiguous = CGBitmapContextGetBytesPerRow(context) != contextWidth * 4;
    if(!*textureRef || // There's no existing texture
       !coordinates || // There are no pre-calculated texture coordinates.
       coordinates->texturePixelWidth < contextWidth || 
       coordinates->texturePixelHeight < contextHeight || // The new texture is larger than the existing one.
       dataIsNonContiguous
       ) {
        // If any of the above are true, we can't use upload a subimage to
        // an existing texture, we need a new one.
        newTextureSize = YES;
        
        powerOfTwoWidth = nextPowerOfTwo(contextWidth);
        powerOfTwoHeight = nextPowerOfTwo(contextHeight);

        GLubyte *textureData = NULL;
        
        if(powerOfTwoWidth != contextWidth ||
           powerOfTwoHeight != contextHeight ||
           dataIsNonContiguous) {
            // We need to generate contiguous, power-of-two sized data to
            // upload.
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

            size_t byteLength = powerOfTwoWidth * powerOfTwoHeight * 4;
            textureData = (GLubyte *)malloc(byteLength);
            memset(textureData, 0xFFFFFFFF, byteLength);        
            CGContextRef textureContext = CGBitmapContextCreate(textureData, powerOfTwoWidth, powerOfTwoHeight, 8, powerOfTwoWidth * 4, 
                                                                colorSpace, kCGImageAlphaPremultipliedLast);
            CGImageRef image = CGBitmapContextCreateImage(context);
            
            CGContextDrawImage(textureContext, CGRectMake(0, powerOfTwoHeight - contextHeight, contextWidth, contextHeight), image);
            CGImageRelease(image);
            CGColorSpaceRelease(colorSpace);
            
            context = (CGContextRef)[(id)textureContext autorelease];
        }
        
        if(!*textureRef) { 
            glGenTextures(1, textureRef);
        }
        glBindTexture(GL_TEXTURE_2D, *textureRef); 
        
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, powerOfTwoWidth, powerOfTwoHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, CGBitmapContextGetData(context));
    
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);    
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);    
        
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);        
        
        if(textureData) {
            free(textureData);
        }
    } else {
        // We're able to just overwrite a subsection of the old texture directly.
        glBindTexture(GL_TEXTURE_2D, *textureRef); 
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, contextWidth, contextHeight, GL_RGBA, GL_UNSIGNED_BYTE, CGBitmapContextGetData(context));    
        powerOfTwoWidth = coordinates->texturePixelWidth;
        powerOfTwoHeight = coordinates->texturePixelHeight;
    }
    
    if(coordinates) {
        if(coordinates->innerPixelWidth != contextWidth || coordinates->innerPixelHeight != contextHeight || newTextureSize) {
            // We need to regenerate the texture coordinates.
            CGFloat po2WidthScale = (CGFloat)contextWidth / (CGFloat)powerOfTwoWidth;
            CGFloat po2HeightScale = (CGFloat)contextHeight / (CGFloat)powerOfTwoHeight;
                        
            GLfloat xStep = 2.0f / (2 * X_VERTEX_COUNT - 3);
            GLfloat yStep = 1.0f / (Y_VERTEX_COUNT - 1);
            
            GLfloat yCoord = 0.0f;
            for(int row = 0; row < Y_VERTEX_COUNT; ++row) {
                GLfloat xCoord = 0.0f;
                for(int column = 0; column < X_VERTEX_COUNT; ++column) {
                    coordinates->textureCoordinates[row][column].x = MIN(xCoord, 1.0f) * po2WidthScale;
                    coordinates->textureCoordinates[row][column].y = MIN(yCoord, 1.0f) * po2HeightScale;                    
                    if(xCoord == 0.0f && (row % 2) == 1) {
                        xCoord += xStep * 0.5f;
                    } else {
                        xCoord += xStep;
                    }
                }
                yCoord += yStep;
            }
            
            coordinates->innerPixelWidth = contextWidth;
            coordinates->innerPixelHeight = contextHeight;
            coordinates->texturePixelWidth = powerOfTwoWidth;
            coordinates->texturePixelHeight = powerOfTwoHeight;            
        }
    }    
}

- (void)_createTextureIn:(GLuint *)textureRef 
                    from:(id)viewOrImage
   setTextureCoordinates:(TextureCoordinates *)coordinates
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
    
    CGSize powerOfTwoSize = CGSizeMake(nextPowerOfTwo(scaledSize.width), nextPowerOfTwo(scaledSize.height));

    GLuint powerOfTwoWidth = powerOfTwoSize.height;
    GLuint powerOfTwoHeight = powerOfTwoSize.width;
    
    size_t byteLength = powerOfTwoWidth * powerOfTwoHeight * 4;
    GLubyte *textureData = (GLubyte *)malloc(byteLength);
    
    memset(textureData, 0xFFFFFFFF, byteLength);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef textureContext = CGBitmapContextCreate(textureData, powerOfTwoWidth, powerOfTwoHeight, 8, powerOfTwoWidth * 4, 
                                                        colorSpace, kCGImageAlphaPremultipliedLast);
    CGContextTranslateCTM(textureContext, 0, powerOfTwoHeight - scaledSize.height);
    if([viewOrImage isKindOfClass:[UIView class]]) {
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
        CGImageRef image = ((UIImage *)viewOrImage).CGImage;
        CGContextDrawImage(textureContext, CGRectMake(0, 0, scaledSize.width, scaledSize.height), image);
    }
        
    [self _createTextureIn:textureRef
     fromRGBABitmapContext:textureContext
     setTextureCoordinates:nil];
    
    CGContextRelease(textureContext);
    CGColorSpaceRelease(colorSpace);
    free(textureData);
    
    if(coordinates && coordinates->innerPixelWidth != scaledSize.width && coordinates -> innerPixelHeight != scaledSize.height) {
        // We need to regenerate the texture coordinates.
        CGFloat po2WidthScale = (CGFloat)scaledSize.width / (CGFloat)powerOfTwoWidth;
        CGFloat po2HeightScale = (CGFloat)scaledSize.height / (CGFloat)powerOfTwoHeight;
        
        GLfloat xStep = 2.0f / (2 * X_VERTEX_COUNT - 3);
        GLfloat yStep = 1.0f / (Y_VERTEX_COUNT - 1);
        
        GLfloat yCoord = 0.0f;
        for(int row = 0; row < Y_VERTEX_COUNT; ++row) {
            GLfloat xCoord = 0.0f;
            for(int column = 0; column < X_VERTEX_COUNT; ++column) {
                coordinates->textureCoordinates[row][column].x = MIN(xCoord, 1.0f) * po2WidthScale;
                coordinates->textureCoordinates[row][column].y = MIN(yCoord, 1.0f) * po2HeightScale;                    
                if(xCoord == 0.0f && (row % 2) == 1) {
                    xCoord = xStep * 0.5f;
                } else {
                    xCoord += xStep;
                }
            }
            yCoord += yStep;
        }
        
        coordinates->innerPixelWidth = scaledSize.width;
        coordinates->innerPixelHeight = scaledSize.height;
        coordinates->texturePixelWidth = powerOfTwoWidth;
        coordinates->texturePixelHeight = powerOfTwoHeight;            
    }        
    
    THLog(@"CreatedTexture of scaled size (%f, %f) from point size (%f, %f)", scaledSize.width, scaledSize.height, rawSize.width, rawSize.height);
}

- (void)setPageTexture:(UIImage *)pageTexture isDark:(BOOL)isDark
{
    [self _createTextureIn:&_blankPageTexture 
                      from:pageTexture
     setTextureCoordinates:&_blankPageTextureCoordinates];
    _pageTextureIsDark = isDark;
}

- (void)_setView:(UIView *)view forInternalPageOffsetPage:(int)page
{
    if(_pageContentsInformation[page].view != view) {
        [_pageContentsInformation[page].view release];
        if(view) {
            [self _createTextureIn:&_pageContentsInformation[page].texture
                              from:view
             setTextureCoordinates:_pageContentsInformation[page].textureCoordinates];
        }
        _pageContentsInformation[page].view = [view retain];
    }
}

- (UIView *)currentPageView
{
    return _pageContentsInformation[1].view;
}

- (void)setCurrentPageView:(UIView *)newCurrentView;
{
    if(newCurrentView != _pageContentsInformation[1].view) {
        [self _setView:[_viewDataSource pageTurningView:self previousViewForView:newCurrentView] forInternalPageOffsetPage:0];
        [self _setView:newCurrentView forInternalPageOffsetPage:1];
        [self _setView:[_viewDataSource pageTurningView:self nextViewForView:newCurrentView] forInternalPageOffsetPage:2];
    }
    _flatPageIndex = 1;
}

- (NSArray *)pageViews
{
    return [NSArray arrayWithObjects:_pageContentsInformation[0].view,
            _pageContentsInformation[1].view,
            _pageContentsInformation[2].view,
            _pageContentsInformation[3].view,
            nil];
}

- (void)turnToPageView:(UIView *)newCurrentView forwards:(BOOL)forwards pageCount:(NSUInteger)pageCount;
{
    if(newCurrentView != _pageContentsInformation[1].view) {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        [self _setView:newCurrentView forInternalPageOffsetPage:forwards ? 2 : 0];
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
        
        self.animating = YES;
    }
}

- (void)refreshView:(UIView *)view
{
    for(int i = 0; i < 4; ++i) {
        if(view == _pageContentsInformation[i].view) {
            [self _createTextureIn:&_pageContentsInformation[i].texture
                              from:view
             setTextureCoordinates:_pageContentsInformation[i].textureCoordinates];
            break;
        }
    }
}

- (NSUInteger)currentPageIndex {
    return _pageContentsInformation[1].pageIndex;
}

- (void)_setupBitmapPage:(NSUInteger)newPageIndex 
   forInternalPageOffset:(NSUInteger)pageOffset
                 minSize:(CGSize)minSize
{
    CGRect thisPageRect = [_bitmapDataSource pageTurningView:self 
                                   contentRectForPageAtIndex:newPageIndex];
    if(!CGRectIsEmpty(thisPageRect)) {
        CGContextRef thisPageBitmap = [_bitmapDataSource pageTurningView:self
                                         RGBABitmapContextForPageAtIndex:newPageIndex
                                                                fromRect:thisPageRect
                                                                 minSize:minSize];
        [self _createTextureIn:&_pageContentsInformation[pageOffset].texture
         fromRGBABitmapContext:thisPageBitmap
         setTextureCoordinates:_pageContentsInformation[pageOffset].textureCoordinates];
        _pageContentsInformation[pageOffset].pageIndex = newPageIndex; 
    } else {
        _pageContentsInformation[pageOffset].pageIndex = NSUIntegerMax; 
    }    
}

- (void)_setupBitmapPage:(NSUInteger)newPageIndex 
   forInternalPageOffset:(NSUInteger)pageOffset
{
    CGSize minSize = self.bounds.size;
    if([self respondsToSelector:@selector(contentScaleFactor)]) {
        CGFloat scaleFactor = self.contentScaleFactor;
        minSize.width *= scaleFactor;
        minSize.height *= scaleFactor;
    }
    [self _setupBitmapPage:newPageIndex forInternalPageOffset:pageOffset minSize:minSize];
}

- (void)setCurrentPageIndex:(NSUInteger)newPageIndex
{
    CGSize minSize = self.bounds.size;
    if([self respondsToSelector:@selector(contentScaleFactor)]) {
        CGFloat scaleFactor = self.contentScaleFactor;
        minSize.width *= scaleFactor;
        minSize.height *= scaleFactor;
    }
    if(newPageIndex != _pageContentsInformation[1].pageIndex) {
        [self _setupBitmapPage:newPageIndex forInternalPageOffset:1 minSize:minSize];
        if(newPageIndex >= 0) {
            // Only call this if there could actually be a previous page.
            [self _setupBitmapPage:newPageIndex - 1 forInternalPageOffset:0 minSize:minSize];
        } else {
            _pageContentsInformation[0].pageIndex = NSUIntegerMax;
        }
        [self _setupBitmapPage:newPageIndex + 1 forInternalPageOffset:2 minSize:minSize];
    }
    _flatPageIndex = 1;    
}

- (void)turnToPageAtIndex:(NSUInteger)newPageIndex {
    NSUInteger currentPageIndex = _pageContentsInformation[1].pageIndex;
    if(currentPageIndex != newPageIndex) {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        BOOL forwards = newPageIndex > currentPageIndex;
        
        [self _setupBitmapPage:newPageIndex forInternalPageOffset:forwards ? 2 : 0];
        
        _isTurningAutomatically = YES;
        _automaticTurnIsForwards = forwards;
        if(forwards) {
            _flatPageIndex = 2;
            _automaticTurnFrame = 0;
        } else {
            _flatPageIndex = 1;
            _automaticTurnFrame = 0;
        }
        
        NSUInteger pageCount;
        if(newPageIndex > currentPageIndex) {
            pageCount = newPageIndex - currentPageIndex;
        } else {
            pageCount = currentPageIndex - newPageIndex;
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

- (void)refreshPageAtIndex:(NSUInteger)pageIndex {
    for(NSUInteger i = 0; i < sizeof(_pageContentsInformation) / sizeof(PageContentsInformation); ++i) {
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
        PageContentsInformation tempView = _pageContentsInformation[0];
        _pageContentsInformation[0] = _pageContentsInformation[1];
        _pageContentsInformation[1] = _pageContentsInformation[2];
        _pageContentsInformation[2] = tempView;
    } else {
        PageContentsInformation tempView = _pageContentsInformation[2];
        _pageContentsInformation[2] = _pageContentsInformation[1];
        _pageContentsInformation[1] = _pageContentsInformation[0];
        _pageContentsInformation[0] = tempView;
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
    
    
    // Set up model and perspective matrices.
    CATransform3D modelViewMatrix = CATransform3DMakeRotation((CGFloat)M_PI, 0, 0, 1);
    modelViewMatrix = THCATransform3DLookAt(modelViewMatrix, 
                                            THVec3Make(_viewportLogicalSize.width * 0.5f, _viewportLogicalSize.height * 0.5f, -(_viewportLogicalSize.height * 0.5f) / tanf(FOV_ANGLE * ((float)M_PI / 360.0f))), 
                                            THVec3Make(_viewportLogicalSize.width * 0.5f, _viewportLogicalSize.height * 0.5f, 0.0f), 
                                            THVec3Make(0.0f, 1.0f, 0.0f));

    glUniformMatrix4fv(glGetUniformLocation(_program, "uModelviewMatrix"), sizeof(modelViewMatrix) / sizeof(GLfloat), GL_FALSE, (GLfloat *)&modelViewMatrix);
    
    CATransform3D normalMatrix = THCATransform3DTranspose(CATransform3DInvert(modelViewMatrix));
    glUniformMatrix4fv(glGetUniformLocation(_program, "uNormalMatrix"), sizeof(normalMatrix) / sizeof(GLfloat), GL_FALSE, (GLfloat *)&normalMatrix);

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
    GLint invert = _pageTextureIsDark ? 1 : 0;
    glUniform1i(glGetUniformLocation(_program, "uInvertContentsLuminance"), invert);
    glUniform1i(glGetUniformLocation(_program, "uPaperIsDark"), invert);
    
    // Clear the buffer, ready to draw.
    glEnable(GL_DEPTH_TEST);
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // Assign GL_TEXTUREs to our samplers (we'll bind the textures before use).    
    glUniform1i(glGetUniformLocation(_program, "sPaperTexture"), 0);
    glUniform1i(glGetUniformLocation(_program, "sContentsTexture"), 1);

    // Set up the attributes we're passing arrays to.  We'll set the arrays eow.
    glEnableVertexAttribArray(glGetAttribLocation(_program, "aPageTextureCoordinate"));
    glEnableVertexAttribArray(glGetAttribLocation(_program, "aContentsTextureCoordinate"));
    glEnableVertexAttribArray(glGetAttribLocation(_program, "aPosition"));
    glEnableVertexAttribArray(glGetAttribLocation(_program, "aNormal"));
    
    // Set up to draw the flat page.
    glVertexAttribPointer(glGetAttribLocation(_program, "aPageTextureCoordinate"), 2, GL_FLOAT, GL_FALSE, 0, _blankPageTextureCoordinates.textureCoordinates);
    glVertexAttribPointer(glGetAttribLocation(_program, "aContentsTextureCoordinate"), 2, GL_FLOAT, GL_FALSE, 0, _pageContentsInformation[_flatPageIndex].textureCoordinates->textureCoordinates);
    glVertexAttribPointer(glGetAttribLocation(_program, "aPosition"), 3, GL_FLOAT, GL_FALSE, 0, _stablePageVertices);
    glVertexAttribPointer(glGetAttribLocation(_program, "aNormal"), 3, GL_FLOAT, GL_FALSE, 0, _stablePageVertexNormals);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _blankPageTexture);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _pageContentsInformation[_flatPageIndex].texture);

    glUniform1f(glGetUniformLocation(_program, "uBackContentsBleed"), 0.2);
    
/*
    for(int i = 0; i < TRIANGLE_STRIP_COUNT; ++i) {
        THVec3 vertex = ((THVec3 *)_stablePageVertexNormals)[_triangleStripIndices[i]];
        THVec3 projectedVertex = THVec3Normalize(THCATransform3DVec3Multiply(normalMatrix, vertex));
      //  projectedVertex = THCATransform3DVec3Multiply(projectionMatrix, projectedVertex);
        NSLog(@"[%f, %f, %f] -> [%f, %f, %f]", 
              vertex.x, vertex.y, vertex.z,
              projectedVertex.x, projectedVertex.y, projectedVertex.z);              
    }
*/
  
    // Draw the flat page.
    glDrawElements(GL_TRIANGLE_STRIP, TRIANGLE_STRIP_COUNT, GL_UNSIGNED_BYTE, _triangleStripIndices);

    if(!shouldStopAnimating) {
        // If we're animating, we have a curved page to draw on top.
        
        // Clear the depth buffer so that this page wins if it has coordinates 
        // that conincide with the flat page.
        glClear(GL_DEPTH_BUFFER_BIT);
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, _pageContentsInformation[_flatPageIndex-1].texture);        
        //glVertexAttribPointer(glGetAttribLocation(_program, "aContentsTextureCoordinate"), 2, GL_FLOAT, GL_FALSE, 0, _pageContentsInformation[_flatPageIndex].textureCoordinates->textureCoordinates);
        
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
        
        glDrawElements(GL_TRIANGLE_STRIP, TRIANGLE_STRIP_COUNT - 2, GL_UNSIGNED_BYTE, _triangleStripIndices);
        
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
                
                glVertexAttribPointer(glGetAttribLocation(_program, "aPageTextureCoordinate"), 2, GL_FLOAT, GL_FALSE, 0, _pageEdgeTextureCoordinates);

                glDrawArrays(GL_TRIANGLE_STRIP, 0, Y_VERTEX_COUNT * 2);
                
                glUniform1i(glGetUniformLocation(_program, "uDisableContentsTexture"), 0);
            }
            
            if(++_automaticTurnFrame >= (_automaticTurnIsForwards ? _animatedTurnFrameCount : (_reverseAnimatedTurnFrameCount + 1))) {
                shouldStopAnimating = YES;
                
                _isTurningAutomatically = NO;
                
                [self _cyclePageContentsInformationForTurnForwards:_flatPageIndex == 2];
                _flatPageIndex = 1;
                
                _recacheFlags[0] = YES;
                _recacheFlags[2] = YES;                    
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
        [self _postAnimationViewAndTextureRecache];
    }
    
    if(shouldStopAnimating) {
        self.animating = NO;
    }
}

- (void)setTouchPointForX:(GLfloat)x
{
    _touchPoint.x = x;
    _touchPoint.y = ((GLfloat)_touchRow / (Y_VERTEX_COUNT - 1)) * _viewportLogicalSize.height;
    _touchPoint.z = - _viewportLogicalSize.width * sqrtf(-(powf((x/_viewportLogicalSize.width), 2) - 1));    
}

- (void)setTouchLocationFromTouch:(UITouch *)touch firstTouch:(BOOL)first;
{
    CGSize size = self.bounds.size;
    CGPoint viewTouchPoint =  [touch locationInView:self];

    THVec2 modelTouchPoint = { (viewTouchPoint.x / size.width) * _viewportLogicalSize.width,
                                    (viewTouchPoint.y / size.height) * _viewportLogicalSize.height };
    
    _touchRow = ((modelTouchPoint.y / _viewportLogicalSize.height) + 0.5f / Y_VERTEX_COUNT) * (Y_VERTEX_COUNT - 1);
    if(first) {
        _touchXOffset = _pageVertices[_touchRow][X_VERTEX_COUNT - 1].x - modelTouchPoint.x;
    }
    
    modelTouchPoint.x =  modelTouchPoint.x + _touchXOffset;
    if(modelTouchPoint.x > _viewportLogicalSize.width) {
        modelTouchPoint.x = _viewportLogicalSize.width;
    } 
    NSTimeInterval thisTouchTime = [touch timestamp];
    if(_touchTime) {
        GLfloat difference = (GLfloat)(thisTouchTime - _touchTime);
        if(difference) {
            _touchVelocity = (modelTouchPoint.x - _touchPoint.x) / (30.0f * difference);
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
        _touch = touch;
        _touchBeganTime = [touch timestamp];
        if(self.isAnimating) {
            [self setTouchLocationFromTouch:_touch firstTouch:YES];
        } else {
            _vibrated = NO;
        }
    }
    
    if(self.isAnimating || _vibrated) {
        // We've already started to turn the page.
        // Remove the touch we're 'using' and pass the rest on.
        NSMutableSet *unusedTouches = [touches mutableCopy];
        [unusedTouches removeObject:_touch];
        if(unusedTouches.count) {
            [_pageContentsInformation[1].view touchesBegan:unusedTouches withEvent:event];
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
            
            THLog(@"Pinch Began: %@, %@", NSStringFromCGPoint(_pinchStartPoints[0]), NSStringFromCGPoint(_pinchStartPoints[1]));
        }
        
        [_pageContentsInformation[1].view touchesBegan:touches withEvent:event];
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
                    if(_pageContentsInformation[0].view || _pageContentsInformation[0].pageIndex != NSUIntegerMax) {
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
                } else {
                    if(_pageContentsInformation[2].view || _pageContentsInformation[2].pageIndex != NSUIntegerMax) {
                        _flatPageIndex = 2;
                    } else {
                        shouldAnimate = NO;
                    }
                }
                if(!_vibrated) {
                    [_pageContentsInformation[1].view touchesCancelled:[NSSet setWithObject:_touch] withEvent:event];
                }
                if(shouldAnimate) {
                    _vibrated = NO;
                    [self setTouchLocationFromTouch:_touch firstTouch:YES];
                    self.animating = YES;
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
        }
    } else if([touches containsObject:_pinchTouches[0]] || [touches containsObject:_pinchTouches[1]]) {
        if(!_pinchUnderway) {
            [THBackgroundProcessingMediator curtailBackgroundProcessing];
            [_pageContentsInformation[1].view touchesCancelled:[NSSet setWithObjects:_pinchTouches count:2] withEvent:event];
            _pinchUnderway = YES;
        }        
        
        if([_viewDataSource respondsToSelector:@selector(pageTurningView:scaledViewForView:pinchStartedAt:pinchNowAt:currentScaledView:)]) {
            CGPoint currentPinchPoints[2] = { [_pinchTouches[0] locationInView:self], [_pinchTouches[1] locationInView:self] };
            UIView *scaledView = [_viewDataSource pageTurningView:self 
                                                scaledViewForView:_pageContentsInformation[1].view 
                                                   pinchStartedAt:_pinchStartPoints
                                                       pinchNowAt:currentPinchPoints
                                                currentScaledView:_pageContentsInformation[3].view];
            if(scaledView && scaledView != _pageContentsInformation[3].view) {
                [self _setView:scaledView forInternalPageOffsetPage:3];
                _flatPageIndex = 3;
                
                //NSLog(@"Pinch %f -> %f, scalefactor %f", (float)startDistance,(float)nowDistance, (float)(nowDistance / startDistance));
                
                [self drawView];
            }
        }
    }
    
    if(self.isAnimating || _vibrated || _pinchUnderway) {
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
            [_pageContentsInformation[1].view touchesMoved:unusedTouches withEvent:event];
        }
        [unusedTouches release];
    } else {
        [_pageContentsInformation[1].view touchesMoved:touches withEvent:event];
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
            if(_pageContentsInformation[3].view || _pageContentsInformation[3].pageIndex != NSUIntegerMax) {
                PageContentsInformation tempView = _pageContentsInformation[1];
                _pageContentsInformation[1] = _pageContentsInformation[3];
                _pageContentsInformation[3] = tempView;
                
                [self _setView:nil forInternalPageOffsetPage:3];
                _flatPageIndex = 1;

                if([_delegate respondsToSelector:@selector(pageTurningView:didScaleToView:)]) {
                    [_delegate pageTurningView:self didScaleToView:_pageContentsInformation[1].view];
                }
                
                [self _setView:[_viewDataSource pageTurningView:self previousViewForView:_pageContentsInformation[1].view] forInternalPageOffsetPage:0];
                [self _setView:[_viewDataSource pageTurningView:self nextViewForView:_pageContentsInformation[1].view] forInternalPageOffsetPage:2];

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
    if(self.isAnimating || _vibrated) {
        NSMutableSet *unusedTouches = [touches mutableCopy];
        if(_touch) {
            [unusedTouches removeObject:_touch];
        }
        if(unusedTouches.count) {
            [_pageContentsInformation[1].view touchesEnded:unusedTouches withEvent:event];
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
            [_pageContentsInformation[1].view touchesEnded:unusedTouches withEvent:event];
        }
        [unusedTouches release];     
    } else {
        if(_touch && 
           [touches containsObject:_touch] && 
           [_touch timestamp] - _touchBeganTime < 0.2) {
            BOOL turning = NO;
            
            CGPoint point = [_touch locationInView:self];
            if(_pageContentsInformation[1].view) {
                CGFloat tapTurnMargin = [self _tapTurnMarginForView:_pageContentsInformation[1].view];
                if(point.x < tapTurnMargin && _pageContentsInformation[0].view) {
                    [self turnToPageView:_pageContentsInformation[0].view forwards:NO pageCount:1];
                    turning = YES;
                } else if(point.x > (_pageContentsInformation[1].view.bounds.size.width - tapTurnMargin) && _pageContentsInformation[2].view) {
                    [self turnToPageView:_pageContentsInformation[2].view forwards:YES pageCount:1];
                    turning = YES;
                }                
            } else {
                CGFloat tapTurnMargin = 0.1f * _pageContentsInformation->textureCoordinates->innerPixelWidth;
                if(point.x < tapTurnMargin && _pageContentsInformation[0].pageIndex != NSUIntegerMax) {
                    [self turnToPageAtIndex:_pageContentsInformation[0].pageIndex];
                    turning = YES;
                } else if(point.x > (_pageContentsInformation->textureCoordinates->innerPixelWidth - tapTurnMargin) && _pageContentsInformation[2].pageIndex != NSUIntegerMax) {
                    [self turnToPageAtIndex:_pageContentsInformation[2].pageIndex];
                    turning = YES;
                }                
            }
            
            if(turning) {
                NSMutableSet *unusedTouches = [touches mutableCopy];
                if(_touch) {
                    [unusedTouches removeObject:_touch];
                }
                if(unusedTouches.count) {
                    [_pageContentsInformation[1].view touchesEnded:unusedTouches withEvent:event];
                }
                [unusedTouches release];   
                [_pageContentsInformation[1].view touchesCancelled:[NSSet setWithObject:_touch] withEvent:event];
            } else {
                [_pageContentsInformation[1].view touchesEnded:touches withEvent:event];
            }
        } else {
            [_pageContentsInformation[1].view touchesEnded:touches withEvent:event];
        }
    }
    [self _touchesEndedOrCancelled:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(self.isAnimating || _vibrated) {
        NSMutableSet *unusedTouches = [touches mutableCopy];
        if(_touch) {
            [unusedTouches removeObject:_touch];
        }
        if(unusedTouches.count) {
            [_pageContentsInformation[1].view touchesCancelled:unusedTouches withEvent:event];
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
            [_pageContentsInformation[1].view touchesCancelled:unusedTouches withEvent:event];
        }
        [unusedTouches release];        
    } else {
        [_pageContentsInformation[1].view touchesCancelled:touches withEvent:event];
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
        if([_pageContentsInformation[1].view respondsToSelector:@selector(accessibilityElements)]) {
            pageViewAccessibilityElements = [_pageContentsInformation[1].view  performSelector:@selector(accessibilityElements)];
        }
        NSMutableArray *accessibilityElements = [[NSMutableArray alloc] initWithCapacity:pageViewAccessibilityElements.count + 1];
        
        CGFloat tapZoneWidth = [self _tapTurnMarginForView:_pageContentsInformation[1].view];
            
        for(UIAccessibilityElement *element in pageViewAccessibilityElements) {
            element.accessibilityContainer = self;
            [accessibilityElements addObject:element];
        }

        {
            THAccessibilityElement *nextPageTapZone = [[THAccessibilityElement alloc] initWithAccessibilityContainer:self];
            nextPageTapZone.accessibilityTraits = UIAccessibilityTraitButton;
            if(!_pageContentsInformation[2].view)  {
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
            if(!_pageContentsInformation[0].view)  {
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
        GLfloat newX = _touchPoint.x + _touchVelocity /** difference*/;
        if(newX > _viewportLogicalSize.width) {
            newX = _viewportLogicalSize.width;
        } 
        [self setTouchPointForX:newX];
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
        pageHasRigidEdge = [_delegate pageTurningView:self viewEdgeIsRigid:_pageContentsInformation[_flatPageIndex-1].view];
    } else {
        pageHasRigidEdge = NO;
    }
    
    THVec3 *flatPageVertices = (THVec3 *)_pageVertices;
    int j;
    for(j=0; j < NUM_ITERATIONS; ++j) {              
        if(_touch || _touchVelocity) {        
            _pageVertices[MAX(0, _touchRow-1)][X_VERTEX_COUNT - 1].x = _touchPoint.x;
            _pageVertices[_touchRow][X_VERTEX_COUNT - 1] = _touchPoint;
            _pageVertices[MIN(Y_VERTEX_COUNT - 1, _touchRow+1)][X_VERTEX_COUNT - 1].x = _touchPoint.x;
        }
        
        for(int i = 0; i < CONSTRAINT_COUNT; ++i) {
            VerletContstraint constraint = _constraints[i];
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
            flatPageVertices[constraint.particleAIndex].z = MIN(0, flatPageVertices[constraint.particleAIndex].z);
            flatPageVertices[constraint.particleBIndex].z = MIN(0, flatPageVertices[constraint.particleBIndex].z);            
        }
        
        
        // Make sure the page is attached to the edge, and
        // above the surface.
        BOOL isFlat = !_touch && _touchVelocity >= 0;
        BOOL hasFlipped = !_touch && _touchVelocity <= 0;
        for(int row = 0; row < Y_VERTEX_COUNT; ++row) {
            GLfloat xCoord = _stablePageVertices[row][0].x;
            GLfloat yCoord = _stablePageVertices[row][0].y;
            GLfloat zCoord = _stablePageVertices[row][0].z;
            for(int column = 0; column < X_VERTEX_COUNT; ++column) {
                THVec3 vertex = _pageVertices[row][column];
                
                GLfloat diff = yCoord - vertex.y;
                _pageVertices[row][column].y = (vertex.y += diff * 0.5f);

                if(hasFlipped &&
                   (column > 0 && vertex.x > xCoord && 
                    atanf(-vertex.z / vertex.x) < (((GLfloat)M_PI - (FOV_ANGLE / (360.0f * (GLfloat)M_2_PI))) / 2.0f))) { 
                    hasFlipped = NO;
                }
            }
                                    
            _pageVertices[row][0].x = xCoord;
            _pageVertices[row][0].y = yCoord;
            _pageVertices[row][0].z = zCoord;
            

            if(_pageVertices[row][X_VERTEX_COUNT - 1].x > (_stablePageVertices[row][X_VERTEX_COUNT - 1].x - 0.0125f)) {
                _pageVertices[row][X_VERTEX_COUNT - 1].x = _stablePageVertices[row][X_VERTEX_COUNT - 1].x;
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
        }
        
        if(isFlat || hasFlipped) {
            memcpy(_pageVertices, _stablePageVertices, sizeof(_stablePageVertices));
            memcpy(_oldPageVertices, _stablePageVertices, sizeof(_stablePageVertices));
            _touchVelocity = 0;
            
            if(_flatPageIndex == 2) {
                if(hasFlipped) {
                    [self _cyclePageContentsInformationForTurnForwards:YES];
                    _recacheFlags[2] = YES;
                    _viewsNeedRecache = YES;
                } 
                _flatPageIndex = 1;
            } else {
                if(!hasFlipped) {
                    [self _cyclePageContentsInformationForTurnForwards:NO];
                    _recacheFlags[0] = YES;
                    _viewsNeedRecache = YES;
                }
            }  
            
            shouldStopAnimating = YES;

            break;
        }
    }
    return shouldStopAnimating;
}

- (void)_postAnimationViewAndTextureRecache
{
    if(_recacheFlags[0]) {
        if(_viewDataSource) {
            [self _setView:[_viewDataSource pageTurningView:self previousViewForView:_pageContentsInformation[1].view] forInternalPageOffsetPage:0];
        } else {
            if(_pageContentsInformation[1].pageIndex == 0) {
                _pageContentsInformation[0].pageIndex = NSUIntegerMax;
            } else {
                [self _setupBitmapPage:_pageContentsInformation[1].pageIndex - 1 forInternalPageOffset:0];
            }
        }
        _recacheFlags[0] = NO;
    }     
    if(_recacheFlags[2]) {
        if(_viewDataSource) {
            [self _setView:[_viewDataSource pageTurningView:self nextViewForView:_pageContentsInformation[1].view] forInternalPageOffsetPage:2];
        } else {
            [self _setupBitmapPage:_pageContentsInformation[1].pageIndex + 1 forInternalPageOffset:2];
        }
        _recacheFlags[2] = NO;
    }
    if(_viewDataSource && [_delegate respondsToSelector:@selector(pageTurningView:didTurnToView:)]) {
        [_delegate pageTurningView:self didTurnToView:_pageContentsInformation[1].view];
    }                    
    _viewsNeedRecache = NO;
    
    [self _setNeedsAccessibilityElementsRebuild];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
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

@end
