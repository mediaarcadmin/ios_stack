//
//  PageView.h
//  libEucalyptus
//
//  Created by James Montgomerie on 03/06/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EucPageTextView.h"

@protocol EucPageViewDelegate;

@class EucPageTextView, THStringRenderer;

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
    
    EucPageTextView *_bookTextView;
    EucPageViewTitleLinePosition _titleLinePosition;
    EucPageViewTitleLineContents _titleLineContents;
    BOOL _fullBleed;
    
    UITouch *_touch;
}

@property (nonatomic, assign) id<EucPageViewDelegate> delegate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *pageNumber;
@property (nonatomic, readonly) EucPageTextView *bookTextView;
@property (nonatomic, assign) EucPageViewTitleLinePosition titleLinePosition;
@property (nonatomic, assign) EucPageViewTitleLineContents titleLineContents;
@property (nonatomic, assign) BOOL fullBleed;

+ (CGRect)bookTextViewFrameForPointSize:(CGFloat)pointSize;

- (id)initWithPointSize:(CGFloat)pointSize 
              titleFont:(NSString *)titleFont
         pageNumberFont:(NSString *)pageNumberFont 
         titlePointSize:(CGFloat)titlePointSize 
             pageTexture:(UIImage*)pageTexture;

- (id)initWithPointSize:(CGFloat)pointSize pageTexture:(UIImage *)pageTexture;

@end

@protocol EucPageViewDelegate <NSObject>

@optional
- (void)pageView:(EucPageView *)pageView didReceiveTapOnHyperlinkWithAttributes:(NSDictionary *)attributes;

@end
