//
//  EucPageTextView.h
//  libEucalyptus
//
//  Created by James Montgomerie on 27/06/2008.
//  Copyright 2008 Things Made Out Of Other Things Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "THUIViewThreadSafeDrawing.h"

@protocol EucPageTextViewDelegate, EucBook;
@class EucBookPageIndexPoint, EucLocalBookReference;

@protocol EucPageTextView <THUIViewThreadSafeDrawing> 

@required

@property (nonatomic, assign) id<EucPageTextViewDelegate> delegate;
@property (nonatomic, assign) CGFloat pointSize;
@property (nonatomic, assign) BOOL allowScaledImageDistortion;

- (id)initWithFrame:(CGRect)frame pointSize:(CGFloat)pointSize;

- (EucBookPageIndexPoint *)layoutPageFromPoint:(EucBookPageIndexPoint *)point
                                        inBook:(id<EucBook>)book;

- (NSArray *)blockIdentifiers;
- (CGRect)frameOfBlockWithIdentifier:(id)blockId;
- (NSArray *)identifiersForElementsOfBlockWithIdentifier:(id)blockId;
- (NSArray *)rectsForElementWithIdentifier:(id)elementId ofBlockWithIdentifier:(id)blockId;
- (NSString *)accessibilityLabelForElementWithIdentifier:(id)elementId ofBlockWithIdentifier:(id)blockId;

- (NSString *)pageText;

- (void)clear;

- (void)handleTouchBegan:(UITouch *)touch atLocation:(CGPoint)location;
- (void)handleTouchMoved:(UITouch *)touch atLocation:(CGPoint)location;
- (BOOL)handleTouchEnded:(UITouch *)touch atLocation:(CGPoint)location; // Returns whether the touch was handled.
- (void)handleTouchCancelled:(UITouch *)touch atLocation:(CGPoint)location;

@optional
- (CGRect)contentRect;

@end

@protocol EucPageTextViewDelegate <NSObject>

@optional
- (void)pageTextView:(UIView<EucPageTextView> *)pageTextView didReceiveTapOnHyperlinkWithURL:(NSURL *)url;

@end
