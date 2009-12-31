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

@protocol EucPageTextViewDelegate;
@class THStringRenderer, IntegerCache;

@interface EucPageTextView : UIView <THUIViewThreadSafeDrawing> {
    id<EucPageTextViewDelegate> _delegate;
        
    CGFloat _pointSize;
    
    CGFloat _lineHeight;
    CGFloat _spaceWidth;
    CGFloat _emWidth;
    
    CGFloat _nextLineY;
    CGFloat _leftMargin;
    CGFloat _rightMargin;
    CGFloat _textIndent;
    CGFloat _pageYOffset;

    NSUInteger _stringsCapacity;
    NSUInteger _stringsCount;
    id *_stringsWithAttributes;
    CGRect *_stringRects;
    uint64_t *_stringParagraphAndWordOffsets;
    
    void *_sharedHyphenator;
    
    UITouch *_touch;
    BOOL _trackingWord;
    CGRect _trackingRect;
    NSInteger _trackingWordIndex;
    
    BOOL _allowScaledImageDistortion;
}

@property (nonatomic, assign) id<EucPageTextViewDelegate> delegate;
@property (nonatomic, assign) CGFloat pointSize;
@property (nonatomic, assign) CGFloat leftMargin;
@property (nonatomic, assign) CGFloat rightMargin;
@property (nonatomic, assign) CGFloat textIndent;
@property (nonatomic, readonly) CGFloat innerWidth;
@property (nonatomic, readonly) CGFloat outerWidth;

@property (nonatomic, assign) BOOL allowScaledImageDistortion;

- (id)initWithFrame:(CGRect)frame pointSize:(CGFloat)pointSize;

// Returns the number of complete words that sucessfully fitted into the view
// and the number of hyphenated parts of the next, incomplete, word (if any).
// (e.g. If the word is "furniture", it could be broken as "fur-niture" or
// "furni-tuer".  If the line ended "fur-", hyphenatedPartCount would be 1,
// if the line ended "furni-", hyphenatedPartCount would be 2.
typedef struct {
    NSUInteger completeLineCount;
    NSUInteger completeWordCount;
    NSUInteger hyphenationPointsPassedInNextWord;
    NSUInteger removalCookie;
} EucPageTextViewEndPosition;

// Shold change this to take a "flags" argument instead of this crazy bunch of BOOLs...
- (EucPageTextViewEndPosition)addParagraphWithId:(uint32_t)paragraphId
                                           words:(NSArray *)words
                                      attributes:(NSArray *)attributes 
                                      wordOffset:(NSUInteger)wordOffset
                                    hyphenOffset:(NSUInteger)hyphenOffset 
                             indentBrokenLinesBy:(CGFloat)indentBrokenLinesBy
                                          center:(BOOL)center 
                                         justify:(BOOL)justify
                                 justifyLastLine:(BOOL)justifyLastLine
                                       hyphenate:(BOOL)hyphenate;
- (BOOL)addString:(NSString *)string 
           center:(BOOL)center 
          justify:(BOOL)justify
           italic:(BOOL)italic;

- (NSArray *)rectsForWordAtParagraphId:(uint32_t)paragraphId wordOffset:(uint32_t)wordOffset;

- (void)addBlankLines:(CGFloat)blankLineCount;
- (void)addVerticalSpace:(CGFloat)verticalSpace;

- (CGFloat)textIndentForEms:(CGFloat)textIndent;

- (void)setIndentation:(NSUInteger)indentationCount;
- (void)pleasinglyDistributeContentVertically;
- (void)removeFromCookie:(NSUInteger)removalCookie;

- (void)clear;

- (void)handleTouchBegan:(UITouch *)touch atLocation:(CGPoint)location;
- (void)handleTouchMoved:(UITouch *)touch atLocation:(CGPoint)location;
- (void)handleTouchEnded:(UITouch *)touch atLocation:(CGPoint)location;
- (void)handleTouchCancelled:(UITouch *)touch atLocation:(CGPoint)location;

@end

@protocol EucPageTextViewDelegate <NSObject>

@optional
- (void)bookTextView:(EucPageTextView *)bookTextView didReceiveTapOnHyperlinkWithAttributes:(NSDictionary *)attributes;
- (void)bookTextViewDidReceiveTapOnPage:(EucPageTextView *)bookTextView;

@end
