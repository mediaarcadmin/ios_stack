//
//  PageView.h
//  Eucalyptus
//
//  Created by James Montgomerie on 03/06/2008.
//  Copyright 2008 James Montgomerie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EucBookTextView.h"

@protocol EucPageViewDelegate;

@class EucBookTextView, THStringRenderer;

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

@interface EucPageView : UIView <EucBookTextViewDelegate, THUIViewThreadSafeDrawing> {
    CGImageRef _pageImage;

    id<EucPageViewDelegate> _delegate;
    NSString *_title;
    NSString *_pageNumber;
    
    THStringRenderer *_pageNumberRenderer;
    THStringRenderer *_titleRenderer;
    CGFloat _titlePointSize;    
    CGFloat _textPointSize;    

    CGSize _margins;
    
    EucBookTextView *_bookTextView;
    EucPageViewTitleLinePosition _titleLinePosition;
    EucPageViewTitleLineContents _titleLineContents;
    BOOL _fullBleed;
    
    UITouch *_touch;
}

@property (nonatomic, assign) id<EucPageViewDelegate> delegate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *pageNumber;
@property (nonatomic, readonly) EucBookTextView *bookTextView;
@property (nonatomic, assign) EucPageViewTitleLinePosition titleLinePosition;
@property (nonatomic, assign) EucPageViewTitleLineContents titleLineContents;
@property (nonatomic, assign) BOOL fullBleed;

+ (CGRect)bookTextViewFrameForPointSize:(CGFloat)pointSize;

- (id)initWithPointSize:(CGFloat)pointSize 
              titleFont:(NSString *)titleFont
         pageNumberFont:(NSString *)pageNumberFont 
         titlePointSize:(CGFloat)titlePointSize 
             paperImage:(UIImage*)paperImage;

- (id)initWithPointSize:(CGFloat)pointSize;

@end

@protocol EucPageViewDelegate <NSObject>

@optional
- (void)pageView:(EucPageView *)pageView didReceiveTapOnHyperlink:(id)linkObject;

@end
