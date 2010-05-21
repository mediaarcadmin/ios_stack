//
//  PageView.h
//  libEucalyptus
//
//  Created by James Montgomerie on 03/06/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EucPageTextView.h"
#import "THStringRenderer.h"

@protocol EucPageViewDelegate, EucPageTextView;

typedef enum EucPageViewTitleLinePosition
{
    EucPageViewTitleLinePositionTop,
    EucPageViewTitleLinePositionBottom,
    EucPageViewTitleLinePositionNone,
} EucPageViewTitleLinePosition;

typedef enum EucPageViewTitleLineContents
{
    EucPageViewTitleLineContentsTitleAndPageNumber,
    EucPageViewTitleLineContentsCenteredPageNumber,
} EucPageViewTitleLineContents;

@interface EucPageView : UIView <EucPageTextViewDelegate, THUIViewThreadSafeDrawing> {
    CGImageRef _pageTexture;

    id<EucPageViewDelegate> _delegate;
    NSString *_title;
    NSString *_pageNumber;
    
    THStringRenderer *_pageNumberRenderer;
    THStringRenderer *_titleRenderer;
    CGFloat _titlePointSize;    
    CGFloat _textPointSize;    

    CGSize _margins;
    
    UIView<EucPageTextView> *_bookTextView;
    EucPageViewTitleLinePosition _titleLinePosition;
    EucPageViewTitleLineContents _titleLineContents;
    BOOL _fullBleed;
    
    UITouch *_touch;
    
    NSArray *_accessibilityElements;
}

@property (nonatomic, assign) id<EucPageViewDelegate> delegate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *pageNumberString;
@property (nonatomic, readonly) UIView<EucPageTextView> *bookTextView;
@property (nonatomic, assign) EucPageViewTitleLinePosition titleLinePosition;
@property (nonatomic, assign) EucPageViewTitleLineContents titleLineContents;
@property (nonatomic, assign) BOOL fullBleed;

+ (CGRect)bookTextViewFrameForPointSize:(CGFloat)pointSize;

- (id)initWithPointSize:(CGFloat)pointSize 
              titleFont:(NSString *)titleFont 
    titleFontStyleFlags:(THStringRendererFontStyleFlags)titleFontStyleFlags
         pageNumberFont:(NSString *)pageNumberFont 
pageNumberFontStyleFlags:(THStringRendererFontStyleFlags)pageNumberFontStyleFlags
         titlePointSize:(CGFloat)titlePointSize
            pageTexture:(UIImage *)pageTexture
          textViewClass:(Class)textViewClass;

- (id)initWithPointSize:(CGFloat)pointSize 
            pageTexture:(UIImage *)pageTexture
          textViewClass:(Class)textViewClass;

@end

@protocol EucPageViewDelegate <NSObject>

@optional
- (void)pageView:(EucPageView *)pageView didReceiveTapOnHyperlinkWithAttributes:(NSDictionary *)attributes;

@end
