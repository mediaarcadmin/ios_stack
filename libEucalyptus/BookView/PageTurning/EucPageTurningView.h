//
//  THPageTurningView.h
//  PageTurnTest
//
//  Created by James Montgomerie on 07/11/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "THOpenGLUtils.h"
#import "THBaseEAGLView.h"
#import "THAccessibilityElement.h"

@protocol EucPageTurningViewDelegate, EucPageTurningViewViewDataSource, EucPageTurningViewBitmapDataSource;

#define X_VERTEX_COUNT 11
#define Y_VERTEX_COUNT 16
#define TRIANGLE_STRIP_COUNT ((Y_VERTEX_COUNT - 1) * (X_VERTEX_COUNT * 2 + 3))
#define CONSTRAINT_COUNT (((X_VERTEX_COUNT * 2 - 1) + (X_VERTEX_COUNT - 1)) * (Y_VERTEX_COUNT - 1) + (X_VERTEX_COUNT - 1)  + X_VERTEX_COUNT + Y_VERTEX_COUNT)

typedef struct {
    GLubyte particleAIndex;
    GLubyte particleBIndex;
    GLfloat lengthSquared;
} VerletContstraint;

typedef struct {
    THVec2 textureCoordinates[Y_VERTEX_COUNT][X_VERTEX_COUNT];
    GLuint innerPixelWidth;
    GLuint innerPixelHeight;
    GLuint texturePixelWidth;
    GLuint texturePixelHeight;
} TextureCoordinates;

typedef struct {
    NSUInteger pageIndex;
    UIView *view;
    GLuint texture;
    TextureCoordinates *textureCoordinates;
} PageContentsInformation;

@interface EucPageTurningView : THBaseEAGLView <THAccessibilityElementDelegate> {
    GLuint _program;
    
    CGSize _viewportLogicalSize;
    CGFloat _pageAspectRatio;
    CGRect _pageFrame;
    
    THVec3 _stablePageVertices[Y_VERTEX_COUNT][X_VERTEX_COUNT];
    THVec3 _stablePageVertexNormals[Y_VERTEX_COUNT][X_VERTEX_COUNT];

    THVec3 _pageVertices[Y_VERTEX_COUNT][X_VERTEX_COUNT];
    THVec3 _oldPageVertices[Y_VERTEX_COUNT][X_VERTEX_COUNT];
    THVec3 _pageVertexNormals[Y_VERTEX_COUNT][X_VERTEX_COUNT];
    
    GLubyte _triangleStripIndices[TRIANGLE_STRIP_COUNT];

    // Currently unused - see comments in the source file.
    //GLfloatTriplet _forceAccumulators[Y_VERTEX_COUNT][X_VERTEX_COUNT];
    
    VerletContstraint _constraints[CONSTRAINT_COUNT];
    int _constraintCount;
        
    BOOL _pageTextureIsDark;
    GLuint _blankPageTexture;
    TextureCoordinates _blankPageTextureCoordinates;

    GLuint _bookEdgeTexture;
    THVec2 _pageEdgeTextureCoordinates[Y_VERTEX_COUNT][2];
    
    UITouch *_touch;
    NSTimeInterval _touchBeganTime;
    NSInteger _touchRow;
    GLfloat _touchXOffset;
    NSTimeInterval _touchTime;
    THVec3 _touchPoint;
    GLfloat _touchVelocity;
    
    BOOL _pinchUnderway;
    UITouch *_pinchTouches[2];
    CGPoint _pinchStartPoints[2];
    
    BOOL _vibrated;
    
    id<EucPageTurningViewDelegate> _delegate;
    id<EucPageTurningViewViewDataSource> _viewDataSource;
    id<EucPageTurningViewBitmapDataSource> _bitmapDataSource;
    
    EAGLContext *_textureUploadContext;
    PageContentsInformation _pageContentsInformation[4];
    
    int _flatPageIndex;
    BOOL _viewsNeedRecache;
    BOOL _recacheFlags[3];
    
    GLvoid *_atRenderScreenshotBuffer;
    
    GLfloat _dimQuotient;
    
    NSData *_animatedTurnData;
    NSInteger _animatedTurnFrameCount;
    NSData *_reverseAnimatedTurnData;
    NSInteger _reverseAnimatedTurnFrameCount;
    
    BOOL _isTurningAutomatically;
    BOOL _automaticTurnIsForwards;
    NSInteger _automaticTurnFrame;
    CGFloat _automaticTurnPercentage;
    
    //FILE *tempFile;
    
    GLfloat _specularColor[4];
    GLfloat _shininess;
    
    GLfloat _constantAttenuationFactor;
    GLfloat _linearAttenutaionFactor;
    GLfloat _quadraticAttenuationFactor;
    
    GLfloat _ambientLightColor[4];
    GLfloat _diffuseLightColor[4];
    
    THVec3 _lightPosition;
    
    NSArray *_accessibilityElements;
    THAccessibilityElement *_nextPageTapZone;
}

@property (nonatomic, assign) id<EucPageTurningViewDelegate> delegate;

// Only set one of these!
@property (nonatomic, assign) id<EucPageTurningViewViewDataSource> viewDataSource;
@property (nonatomic, assign) id<EucPageTurningViewBitmapDataSource> bitmapDataSource;

@property (nonatomic, assign) CGFloat dimQuotient;

@property (nonatomic, readonly) UIImage *screenshot;

@property (nonatomic, copy) UIColor *specularColor;
@property (nonatomic, assign) GLfloat shininess;

@property (nonatomic, assign) GLfloat constantAttenuationFactor;
@property (nonatomic, assign) GLfloat linearAttenutaionFactor;
@property (nonatomic, assign) GLfloat quadraticAttenuationFactor;

@property (nonatomic, copy) UIColor *ambientLightColor;
@property (nonatomic, copy) UIColor *diffuseLightColor;

@property (nonatomic, assign) THVec3 lightPosition;

@property (nonatomic, assign) CGFloat pageAspectRatio; // width / height.  0 = matches screen.  Default is 0.

- (void)setPageTexture:(UIImage *)pageTexture isDark:(BOOL)isDark;

// View based page contents:

@property (nonatomic, retain) UIView *currentPageView;
@property (nonatomic, readonly) NSArray *pageViews;
- (void)turnToPageView:(UIView *)newCurrentView forwards:(BOOL)forwards pageCount:(NSUInteger)pageCount;
- (void)refreshView:(UIView *)view;

// Bitmap based page contents:
@property (nonatomic, assign) NSUInteger currentPageIndex;
- (void)turnToPageAtIndex:(NSUInteger)newPageIndex;
- (void)refreshPageAtIndex:(NSUInteger)pageIndex;

@end


@protocol EucPageTurningViewViewDataSource <NSObject>

@required
- (UIView *)pageTurningView:(EucPageTurningView *)pageTurningView previousViewForView:(UIView *)view;
- (UIView *)pageTurningView:(EucPageTurningView *)pageTurningView nextViewForView:(UIView *)view;

- (UIView *)pageTurningView:(EucPageTurningView *)pageTurningView scaledViewForView:(UIView *)view pinchStartedAt:(CGPoint[])startPinch pinchNowAt:(CGPoint[])currentPinch currentScaledView:(UIView *)currentScaledView;

@end


@protocol EucPageTurningViewBitmapDataSource <NSObject>

- (CGRect)pageTurningView:(EucPageTurningView *)pageTurningView contentRectForPageAtIndex:(NSUInteger)index;
- (CGContextRef)pageTurningView:(EucPageTurningView *)pageTurningView 
RGBABitmapContextForPageAtIndex:(NSUInteger)index
                       fromRect:(CGRect)rect
                        minSize:(CGSize)rect;

@end


@protocol EucPageTurningViewDelegate <NSObject>

@optional

- (void)pageTurningViewAnimationWillBegin:(EucPageTurningView *)pageTurningView;
- (void)pageTurningViewAnimationDidEnd:(EucPageTurningView *)pageTurningView;

- (void)pageTurningView:(EucPageTurningView *)pageTurningView didTurnToView:(UIView *)view;
- (void)pageTurningView:(EucPageTurningView *)pageTurningView didScaleToView:(UIView *)view;

// Views are assumed not to have rigid edges if this is not implemented.
- (BOOL)pageTurningView:(EucPageTurningView *)pageTurningView viewEdgeIsRigid:(UIView *)view;
- (BOOL)pageTurningView:(EucPageTurningView *)pageTurningView tapTurnMarginForView:(UIView *)view;

@end



