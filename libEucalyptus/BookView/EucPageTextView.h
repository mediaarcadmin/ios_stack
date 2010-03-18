//
//  EucPageTextView.h
//  libEucalyptus
//
//  Created by James Montgomerie on 27/06/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EucBookTextStyle.h"
#import "THUIViewThreadSafeDrawing.h"

@protocol EucPageTextViewDelegate, EucBook;
@class EucBookPageIndexPoint, EucLocalBookReference;

@protocol EucPageTextView <THUIViewThreadSafeDrawing> 

@property (nonatomic, assign) id<EucPageTextViewDelegate> delegate;
@property (nonatomic, assign) CGFloat pointSize;
@property (nonatomic, assign) BOOL allowScaledImageDistortion;
@property (nonatomic, assign) BOOL backgroundIsDark;

- (id)initWithFrame:(CGRect)frame pointSize:(CGFloat)pointSize;

- (EucBookPageIndexPoint *)layoutPageFromPoint:(EucBookPageIndexPoint *)point
                                        inBook:(id<EucBook>)book;

- (NSArray *)blockIdentifiers;
- (CGRect)frameOfBlockWithIdentifier:(id)id;
- (NSArray *)identifiersForElementsOfBlockWithIdentifier:(id)id;
- (NSArray *)rectsForElementWithIdentifier:(id)paragraphId ofBlockWithIdentifier:(id)wordOffset;

- (void)clear;

- (void)handleTouchBegan:(UITouch *)touch atLocation:(CGPoint)location;
- (void)handleTouchMoved:(UITouch *)touch atLocation:(CGPoint)location;
- (void)handleTouchEnded:(UITouch *)touch atLocation:(CGPoint)location;
- (void)handleTouchCancelled:(UITouch *)touch atLocation:(CGPoint)location;

@end

@protocol EucPageTextViewDelegate <NSObject>

@optional
- (void)bookTextView:(UIView<EucPageTextView> *)bookTextView didReceiveTapOnHyperlinkWithAttributes:(NSDictionary *)attributes;
- (void)bookTextViewDidReceiveTapOnPage:(UIView<EucPageTextView> *)bookTextView;

@end
