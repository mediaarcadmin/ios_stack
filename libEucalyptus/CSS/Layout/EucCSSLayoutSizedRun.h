//
//  EucCSSLayoutSizedRun.h
//  libEucalyptus
//
//  Created by James Montgomerie on 21/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

#import "EucCSSLayoutSizedEntity.h"

struct THBreak;
struct EucCSSLayoutSizedRunBreakInfo;

@class EucCSSLayoutRun, EucCSSLayouter, EucCSSLayoutPositionedContainer, EucCSSLayoutPositionedRun;

typedef struct EucCSSLayoutSizedRunHyphenWidths {
    CGFloat widthBeforeHyphen;
    CGFloat widthAfterHyphen;
} EucCSSLayoutSizedRunHyphenWidths;

typedef union EucCSSLayoutSizedRunWidthInfo {
    CGFloat width;
    CGSize size;
    EucCSSLayoutSizedRunHyphenWidths hyphenWidths;
} EucCSSLayoutSizedRunWidthInfo;

@interface EucCSSLayoutSizedRun : EucCSSLayoutSizedEntity {
    EucCSSLayoutRun *_run;
    
    CGRect _frame;
    
    CGRect _lastSizeDependentComponentCalculationFrame;
    
    EucCSSLayoutSizedRunWidthInfo *_componentWidthInfos;
    
    struct THBreak *_potentialBreaks;
    struct EucCSSLayoutSizedRunBreakInfo *_potentialBreakInfos;
    int _potentialBreaksCount;
}

@property (nonatomic, retain, readonly) EucCSSLayoutRun *run;

// This convenience constructor will return a cached node if one with the same
// attibutes was requested recently.
+ (id)sizedRunWithRun:(EucCSSLayoutRun *)run
          scaleFactor:(CGFloat)scaleFactor;

- (id)initWithRun:(EucCSSLayoutRun *)run
      scaleFactor:(CGFloat)scaleFactor;

- (EucCSSLayoutSizedRunWidthInfo *)componentWidthInfosForFrame:(CGRect)frame;

- (EucCSSLayoutPositionedRun *)positionRunForFrame:(CGRect)frame
                                       inContainer:(EucCSSLayoutPositionedContainer *)container
                              startingAtWordOffset:(uint32_t)wordOffset 
                                     elementOffset:(uint32_t)elementOffset
                            usingLayouterForFloats:(EucCSSLayouter *)layouter;

@end
