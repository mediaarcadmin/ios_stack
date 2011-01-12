//
//  EucCSSLayoutSizedTableCell.h
//  libEucalyptus
//
//  Created by James Montgomerie on 11/01/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

#import "EucCSSLayoutSizedContainer.h"

@class EucCSSIntermediateDocumentNode, EucCSSLayoutPositionedTable, EucCSSLayoutPositionedTableCell, EucCSSLayouter;

@interface EucCSSLayoutSizedTableCell : EucCSSLayoutSizedContainer {
    EucCSSIntermediateDocumentNode *_documentNode;
    CGFloat _widthAddition;
}

@property (nonatomic, retain, readonly) EucCSSIntermediateDocumentNode *documentNode;

- (id)initWithDocumentNode:(EucCSSIntermediateDocumentNode *)documentNode
               scaleFactor:(CGFloat)scaleFactor;

- (EucCSSLayoutPositionedTableCell *) positionCellForFrame:(CGRect)cellFrame
                                                   inTable:(EucCSSLayoutPositionedTable *)positionedTable
                                             atColumnIndex:(NSUInteger)columnIndex
                                                  rowIndex:(NSUInteger)rowIndex
                                             usingLayouter:(EucCSSLayouter *)layouter;

@end
