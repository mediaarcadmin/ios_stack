//
//  THPageTurningView.h
//  PageTurnTest
//
//  Created by James Montgomerie on 07/11/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "THAppleSampleEAGLView.h"

@protocol EucPageTurningViewDelegate;

#define X_VERTEX_COUNT 11
#define Y_VERTEX_COUNT 16
#define TRIANGLE_STRIP_COUNT ((Y_VERTEX_COUNT - 1) * (X_VERTEX_COUNT * 2 + 3))
#define CONSTRAINT_COUNT (((X_VERTEX_COUNT * 2 - 1) + (X_VERTEX_COUNT - 1)) * (Y_VERTEX_COUNT - 1) + (X_VERTEX_COUNT - 1)  + X_VERTEX_COUNT + Y_VERTEX_COUNT)

typedef struct {
    GLfloat x;
    GLfloat y;
} GLfloatPair;

typedef struct {
    GLfloat x;
    GLfloat y;
    GLfloat z;
} GLfloatTriplet;

typedef struct {
    GLubyte particleAIndex;
    GLubyte particleBIndex;
    GLfloat lengthSquared;
} VerletContstraint;

@interface EucPageTurningView : THAppleSampleEAGLView {
    GLfloat _touchVelocity;

    CGSize _powerOf2Bounds;

    GLfloatTriplet _stablePageVertices[Y_VERTEX_COUNT][X_VERTEX_COUNT];
    GLfloatTriplet _stablePageVertexNormals[Y_VERTEX_COUNT][X_VERTEX_COUNT];

    GLfloatTriplet _pageVertices[Y_VERTEX_COUNT][X_VERTEX_COUNT];
    GLfloatTriplet _oldPageVertices[Y_VERTEX_COUNT][X_VERTEX_COUNT];
    GLfloatTriplet _pageVertexNormals[Y_VERTEX_COUNT][X_VERTEX_COUNT];
    
    GLubyte _triangleStripIndices[TRIANGLE_STRIP_COUNT];

    // Currently unused - see comments in the source file.
    //GLfloatTriplet _forceAccumulators[Y_VERTEX_COUNT][X_VERTEX_COUNT];
    
    VerletContstraint _constraints[CONSTRAINT_COUNT];
    int _constraintCount;
    
    GLfloatPair _pageTextureCoordinates[Y_VERTEX_COUNT][X_VERTEX_COUNT];
    
    GLuint _blankPageTexture;
    GLfloatPair _blankPageTextureCoordinates[Y_VERTEX_COUNT][X_VERTEX_COUNT];
    
    GLuint _bookEdgeTexture;
    GLfloatPair _pageEdgeTextureCoordinates[Y_VERTEX_COUNT][2];
    
    UITouch *_touch;
    NSTimeInterval _touchBeganTime;
    NSInteger _touchRow;
    GLfloat _touchXOffset;
    NSTimeInterval _touchTime;
    GLfloatTriplet _touchPoint;
    
    BOOL _pinchUnderway;
    UITouch *_pinchTouches[2];
    CGPoint _pinchStartPoints[2];
    
    BOOL _animating;
    BOOL _vibrated;
    
    id<EucPageTurningViewDelegate> _delegate;
    
    EAGLContext *_textureUploadContext;
    UIView *_pageViews[4];
    GLuint _pageTextures[4];
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
    
    GLfloatTriplet _lightPosition;
    
    NSArray *_accessibilityElements;
}

@property (nonatomic,assign) id<EucPageTurningViewDelegate> delegate;
@property (nonatomic,retain) UIView *currentPageView;
@property (nonatomic, readonly) UIImage *screenshot;
@property (nonatomic, assign) CGFloat dimQuotient;


@property (nonatomic, copy) UIColor *specularColor;
@property (nonatomic, assign) GLfloat shininess;

@property (nonatomic, assign) GLfloat constantAttenuationFactor;
@property (nonatomic, assign) GLfloat linearAttenutaionFactor;
@property (nonatomic, assign) GLfloat quadraticAttenuationFactor;

@property (nonatomic, copy) UIColor *ambientLightColor;
@property (nonatomic, copy) UIColor *diffuseLightColor;

@property (nonatomic, assign) GLfloatTriplet lightPosition;

- (void)turnToPageView:(UIView *)newCurrentView forwards:(BOOL)forwards pageCount:(NSUInteger)pageCount;

- (void)setNeedsAccessibilityElementsRebuild;

@end


@protocol EucPageTurningViewDelegate <NSObject>

@required
- (UIView *)pageTurningView:(EucPageTurningView *)pageTurningView previousViewForView:(UIView *)view;
- (UIView *)pageTurningView:(EucPageTurningView *)pageTurningView nextViewForView:(UIView *)view;

@optional
- (UIView *)pageTurningView:(EucPageTurningView *)pageTurningView scaledViewForView:(UIView *)view pinchStartedAt:(CGPoint[])startPinch pinchNowAt:(CGPoint[])currentPinch currentScaledView:(UIView *)currentScaledView;

- (void)pageTurningViewAnimationWillBegin:(EucPageTurningView *)pageTurningView;
- (void)pageTurningViewAnimationDidEnd:(EucPageTurningView *)pageTurningView;

- (void)pageTurningView:(EucPageTurningView *)pageTurningView didTurnToView:(UIView *)view;
- (void)pageTurningView:(EucPageTurningView *)pageTurningView didScaleToView:(UIView *)view;
- (void)pageTurningView:(EucPageTurningView *)pageTurningView discardingView:(UIView *)view;

// Views are assumed not to have rigid edges if this is not implemented.
- (BOOL)pageTurningView:(EucPageTurningView *)pageTurningView viewEdgeIsRigid:(UIView *)view;
- (BOOL)pageTurningView:(EucPageTurningView *)pageTurningView tapTurnMarginForView:(UIView *)view;

@end



