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
#import "EucPageTurningTextureGenerationOperation.h"
#import "THPair.h"

@class EucPageTurningPageContentsInformation, THOpenGLTexturePool;
@protocol EucPageTurningViewDelegate, EucPageTurningViewViewDataSource, EucPageTurningViewBitmapDataSource;


#pragma mark -
#pragma mark Private constants and structs

#define X_VERTEX_COUNT 11
#define Y_VERTEX_COUNT 16
#define TRIANGLE_STRIP_COUNT ((Y_VERTEX_COUNT - 1) * (X_VERTEX_COUNT * 2 + 3))
#define CONSTRAINT_COUNT (((X_VERTEX_COUNT * 2 - 1) + (X_VERTEX_COUNT - 1)) * (Y_VERTEX_COUNT - 1) + (X_VERTEX_COUNT - 1)  + X_VERTEX_COUNT + Y_VERTEX_COUNT)

// 1/3s at 30 fps.
#define POSITIONING_ANIMATION_ITERATIONS (30 / 3) 

typedef struct {
    GLubyte particleAIndex;
    GLubyte particleBIndex;
    GLfloat lengthSquared;
} EucPageTurningVerletContstraint;

typedef enum EucPageTurningViewZoomHandlingKind {
    EucPageTurningViewZoomHandlingKindInnerScaling = 0,
    EucPageTurningViewZoomHandlingKindZoom,
} EucPageTurningViewZoomHandlingKind;

typedef enum EucPageTurningViewAnimationFlags {
    EucPageTurningViewAnimationFlagsNone                 = 0x00,
    EucPageTurningViewAnimationFlagsDragScroll           = 0x01,
    EucPageTurningViewAnimationFlagsDragTurn             = 0x02,
    EucPageTurningViewAnimationFlagsAutomaticTurn        = 0x04,
    EucPageTurningViewAnimationFlagsAutomaticPositioning = 0x08,
} EucPageTurningViewAnimationFlags;

#pragma mark -

@interface EucPageTurningView : THBaseEAGLView <THAccessibilityElementDelegate, EucPageTurningTextureGenerationOperationDelegate> {
    GLuint _program;
    
    CGSize _lastLayoutBoundsSize;
    BOOL _lastLayoutTwoUp;
    
    CGSize _viewportLogicalSize;
    CGSize _pageLogicalSize;
    CGFloat _pageAspectRatio;
        
    CGAffineTransform _viewportToBoundsPointsTransform;
    
    CATransform3D _rightPageTransform;
    CGRect _rightPageRect;
    CGRect _leftPageRect;
    
    CGRect _unzoomedLeftPageFrame;
    CGRect _unzoomedRightPageFrame;
    
    CGRect _leftPageFrame;
    CGRect _rightPageFrame;
    
    THVec3 _stablePageVertices[Y_VERTEX_COUNT][X_VERTEX_COUNT];
    THVec3 _stablePageVertexNormals[Y_VERTEX_COUNT][X_VERTEX_COUNT];

    THVec3 _pageVertices[Y_VERTEX_COUNT][X_VERTEX_COUNT];
    THVec3 _oldPageVertices[Y_VERTEX_COUNT][X_VERTEX_COUNT];
    THVec3 _pageVertexNormals[Y_VERTEX_COUNT][X_VERTEX_COUNT];
    
    GLubyte _triangleStripIndices[TRIANGLE_STRIP_COUNT];
    
    GLuint _meshTextureCoordinateBuffer;
    GLuint _triangleStripIndicesBuffer;
    
    // Currently unused - see comments in the source file.
    //GLfloatTriplet _forceAccumulators[Y_VERTEX_COUNT][X_VERTEX_COUNT];
    
    EucPageTurningVerletContstraint _constraints[CONSTRAINT_COUNT];
    int _constraintCount;
        
    BOOL _vibratesOnInvalidTurn;
    
    BOOL _pageTextureIsDark;
    GLuint _blankPageTexture;

    GLuint _bookEdgeTexture;
    THVec2 _pageEdgeTextureCoordinates[Y_VERTEX_COUNT][2];
    
    GLuint _grayThumbnail;
    GLuint _alphaWhiteZoomedContent;
    
    UITouch *_touch;
    NSTimeInterval _touchBeganTime;
    NSInteger _touchRow;
    CGPoint _touchStartPoint;
    NSTimeInterval _touchTime;
    THVec3 _pageTouchPoint;
    CGPoint _viewportTouchPoint;
    CGPoint _touchVelocity;

    BOOL _dragUnderway;
    EucPageTurningViewAnimationFlags _animationFlags;
    
    BOOL _pinchUnderway;
    UITouch *_pinchTouches[2];
    CGPoint _pinchStartPoints[2];
    
    CGFloat _minZoomFactor;
    CGFloat _maxZoomFactor;
    CGFloat _zoomFactor;
    CGPoint _scrollTranslation;
    
    NSUInteger _zoomedTextureWidth;
    
    CGFloat _pinchStartZoomFactor;
    CGPoint _scrollStartTranslation;
    CGRect _scrollStartRightPageRect;
    
    CATransform3D _zoomMatrix;
    CATransform3D _scrollStartZoomMatrix;
	
	NSInteger _animationIndex;
	CGFloat _presentationZoomFactor[POSITIONING_ANIMATION_ITERATIONS];
	CGFloat _presentationTranslationX[POSITIONING_ANIMATION_ITERATIONS];
	CGFloat _presentationTranslationY[POSITIONING_ANIMATION_ITERATIONS];
	CGFloat _modelZoomFactor;
	CGPoint _modelTranslation;
	
    NSInteger _isTurning;
    
    BOOL _vibrated;
    
    id<EucPageTurningViewDelegate> _delegate;
    id<EucPageTurningViewViewDataSource> _viewDataSource;
    id<EucPageTurningViewBitmapDataSource> _bitmapDataSource;
    NSLock *_bitmapDataSourceLock;
    
    BOOL _twoUp;
    BOOL _oddPagesOnRight;
    EucPageTurningViewZoomHandlingKind _zoomHandlingKind;
    BOOL _zoomingDelegateMessageSent;
    
    THOpenGLTexturePool *_texturePool;
    
    EucPageTurningPageContentsInformation *_pageContentsInformation[7];
    NSUInteger _focusedPageIndex;
    
    NSInteger _rightFlatPageContentsIndex;
    BOOL _viewsNeedRecache;
    BOOL _recacheFlags[6];
    
    GLvoid *_atRenderScreenshotBuffer;
    
    GLfloat _dimQuotient;
    NSInteger _reverseAnimatedTurnFrameCount;
    
    CGFloat _automaticTurnPercentage;
    
    //FILE *tempFile;
    
    GLfloat _specularColor[4];
    GLfloat _shininess;
    
    GLfloat _constantAttenuationFactor;
    GLfloat _linearAttenutaionFactor;
    
    GLfloat _ambientLightColor[4];
    GLfloat _diffuseLightColor[4];
    
    THVec3 _lightPosition;
    
    NSArray *_accessibilityElements;
    THAccessibilityElement *_nextPageTapZone;
    
    NSOperationQueue *_textureGenerationOperationQueue;
}

@property (nonatomic, assign) id<EucPageTurningViewDelegate> delegate;

@property (nonatomic, assign) BOOL vibratesOnInvalidTurn;

// Only set one of these!
@property (nonatomic, assign) id<EucPageTurningViewViewDataSource> viewDataSource;
@property (nonatomic, assign) id<EucPageTurningViewBitmapDataSource> bitmapDataSource;

@property (nonatomic, assign) CGFloat dimQuotient;

@property (nonatomic, readonly) UIImage *screenshot;

// These must be set up before the view appears.
@property (nonatomic, assign) CGFloat pageAspectRatio; // width / height.  0 = matches screen.  Default is 0.
@property (nonatomic, assign, getter=isTwoUp) BOOL twoUp;
@property (nonatomic, assign) BOOL oddPagesOnRight;

@property (nonatomic, assign, readonly) CGRect leftPageFrame;
@property (nonatomic, assign, readonly) CGRect rightPageFrame;

@property (nonatomic, assign, readonly) CGRect unzoomedLeftPageFrame;
@property (nonatomic, assign, readonly) CGRect unzoomedRightPageFrame;

@property (nonatomic, assign) EucPageTurningViewZoomHandlingKind zoomHandlingKind;

- (void)setPageTexture:(UIImage *)pageTexture isDark:(BOOL)isDark;

@property (nonatomic, assign) CGFloat minZoomFactor; // default = 1.0f
@property (nonatomic, assign) CGFloat maxZoomFactor; // default = 14.0f
@property (nonatomic, assign, readonly) CGFloat fitToBoundsZoomFactor;
@property (nonatomic, assign, readonly) CGFloat zoomFactor;
@property (nonatomic, assign, readonly) CGPoint translation;
@property (nonatomic, assign, readonly) CGFloat animatedZoomFactor;
@property (nonatomic, assign, readonly) CGPoint animatedTranslation;
- (void)setTranslation:(CGPoint)translation zoomFactor:(CGFloat)zoomFactor animated:(BOOL)animated;


@property (nonatomic, assign) NSUInteger zoomedTextureWidth; // default = 1024


#pragma mark View based page contents

@property (nonatomic, retain) UIView *currentPageView;
@property (nonatomic, readonly) NSArray *pageViews;
- (void)turnToPageView:(UIView *)newCurrentView forwards:(BOOL)forwards pageCount:(NSUInteger)pageCount onLeft:(BOOL)onLeft;
- (void)refreshView:(UIView *)view;


#pragma mark Bitmap based page contents
// In non-twoUp mode, the right page index only is valid.
// Will return NSUIntegerMax if a page is not visible on the specified side.
@property (nonatomic, assign, readonly) NSUInteger rightPageIndex;
@property (nonatomic, assign, readonly) NSUInteger leftPageIndex;
@property (nonatomic, assign, readonly) NSUInteger focusedPageIndex;

- (void)turnToPageAtIndex:(NSUInteger)newPageIndex animated:(BOOL)animated;
- (void)refreshPageAtIndex:(NSUInteger)pageIndex;
- (void)refreshHighlightsForPageAtIndex:(NSUInteger)index;

- (void)waitForAllPageImagesToBeAvailable;

#pragma mark Light-related properties.

@property (nonatomic, copy) UIColor *specularColor;
@property (nonatomic, assign) GLfloat shininess;

@property (nonatomic, assign) GLfloat constantAttenuationFactor;
@property (nonatomic, assign) GLfloat linearAttenutaionFactor;

@property (nonatomic, copy) UIColor *ambientLightColor;
@property (nonatomic, copy) UIColor *diffuseLightColor;

@property (nonatomic, assign) THVec3 lightPosition;

@end


#pragma mark -

@protocol EucPageTurningViewViewDataSource <NSObject>

@required
- (UIView *)pageTurningView:(EucPageTurningView *)pageTurningView previousViewForView:(UIView *)view;
- (UIView *)pageTurningView:(EucPageTurningView *)pageTurningView nextViewForView:(UIView *)view;

- (UIView *)pageTurningView:(EucPageTurningView *)pageTurningView scaledViewForView:(UIView *)view pinchStartedAt:(CGPoint[])startPinch pinchNowAt:(CGPoint[])currentPinch currentScaledView:(UIView *)currentScaledView;

@end


#pragma mark -

@protocol EucPageTurningViewBitmapDataSource <NSObject>

@required
- (CGRect)pageTurningView:(EucPageTurningView *)pageTurningView contentRectForPageAtIndex:(NSUInteger)index;

@optional
- (CGContextRef)pageTurningView:(EucPageTurningView *)pageTurningView 
RGBABitmapContextForPageAtIndex:(NSUInteger)index
                       fromRect:(CGRect)rect
                        minSize:(CGSize)rect;

// 'context' is an optional object that will be kept alive alongside the
// CGContextRef.  
// This callback was created because before iOS 4 there was no way to specify
// how to free bitmap data that a context had been created 'around'. 
// (CGBitmapContextCreateWithData is new in iOS 4).
// After libEucalyptus supports only iOS 4+, this callback
// will be removed and the regular RGBABitmapContextForPageAtIndex: callback
// made required rather than optional.
- (CGContextRef)pageTurningView:(EucPageTurningView *)pageTurningView 
RGBABitmapContextForPageAtIndex:(NSUInteger)index
                       fromRect:(CGRect)rect
                        minSize:(CGSize)rect
                     getContext:(id *)context;

- (UIImage *)pageTurningView:(EucPageTurningView *)aPageTurningView 
   fastUIImageForPageAtIndex:(NSUInteger)index;

// Return THPairs of [ NSValue: Highlight Rect, UIColor: Highlight Color]
- (NSArray *)pageTurningView:(EucPageTurningView *)pageTurningView highlightsForPageAtIndex:(NSUInteger)index;


@end


#pragma mark -

@protocol EucPageTurningViewDelegate <NSObject>

@optional

- (void)pageTurningViewWillBeginAnimating:(EucPageTurningView *)pageTurningView;
- (void)pageTurningViewDidEndAnimation:(EucPageTurningView *)pageTurningView;

- (void)pageTurningViewWillBeginZooming:(EucPageTurningView *)scrollView; 
- (void)pageTurningViewDidEndZooming:(EucPageTurningView *)scrollView;

- (void)pageTurningView:(EucPageTurningView *)pageTurningView didTurnToView:(UIView *)view;
- (void)pageTurningView:(EucPageTurningView *)pageTurningView didScaleToView:(UIView *)view;

// Views are assumed not to have rigid edges if this is not implemented.
- (BOOL)pageTurningView:(EucPageTurningView *)pageTurningView viewEdgeIsRigid:(UIView *)view;
- (CGFloat)pageTurningView:(EucPageTurningView *)pageTurningView tapTurnMarginForView:(UIView *)view;

@end



