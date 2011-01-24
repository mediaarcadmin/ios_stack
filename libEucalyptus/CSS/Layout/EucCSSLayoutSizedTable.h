//
//  EucCSSLayoutSizedTable.h
//  libEucalyptus
//
//  Created by James Montgomerie on 04/01/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

#import "EucCSSLayoutSizedEntity.h"

@class EucCSSLayoutTableWrapper, EucCSSLayoutSizedBlock, EucCSSLayoutPositionedContainer, EucCSSLayoutPositionedTable, EucCSSLayouter;

@interface EucCSSLayoutSizedTable: EucCSSLayoutSizedEntity {
    EucCSSLayoutTableWrapper *_tableWrapper;
    
    NSMutableDictionary *_cellMap;
    CFMutableDictionaryRef _sizedCells;
    
    EucCSSLayoutSizedBlock *_sizedCaptionBlock;
    
    NSUInteger _columnCount;
    NSUInteger _rowCount;
    
    CGFloat *_nonAbsoluteColumnMinWidths;
    CGFloat *_columnMinWidths;
    CGFloat *_columnMaxWidths;
}

@property (nonatomic, retain, readonly) EucCSSLayoutSizedBlock *sizedCaptionBlock;

- (id)initWithTableWrapper:(EucCSSLayoutTableWrapper *)tableWrapper
               scaleFactor:(CGFloat)scaleFactor;

- (CGFloat)widthInContainingBlockOfWidth:(CGFloat)width;

- (EucCSSLayoutPositionedTable *)positionTableForFrame:(CGRect)frame
                                           inContainer:(EucCSSLayoutPositionedContainer *)container
                                         usingLayouter:(EucCSSLayouter *)layouter;

- (EucCSSLayoutPositionedTable *)positionTableForFrame:(CGRect)frame
                                           inContainer:(EucCSSLayoutPositionedContainer *)container
                                         usingLayouter:(EucCSSLayouter *)layouter
                                         fromRowOffset:(NSUInteger)rowOffset;

@end
