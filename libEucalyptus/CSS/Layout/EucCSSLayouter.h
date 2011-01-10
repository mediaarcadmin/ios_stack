//
//  EucCSSLayouter.h
//  LibCSSTest
//
//  Created by James Montgomerie on 13/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

#ifdef __cplusplus
#import <vector>
#endif

#import "EucCSSLayoutRun.h"

@class EucCSSIntermediateDocument, EucCSSIntermediateDocumentNode, EucCSSLayoutSizedBlock, EucCSSLayoutPositionedBlock;

typedef struct EucCSSLayoutPoint
{
    uint32_t nodeKey;
    uint32_t word;
    uint32_t element;
} EucCSSLayoutPoint;

@interface EucCSSLayouter : NSObject {
    EucCSSIntermediateDocument *_document;
}

@property (nonatomic, retain) EucCSSIntermediateDocument *document;

- (id)initWithDocument:(EucCSSIntermediateDocument *)document;

- (EucCSSLayoutSizedBlock *)sizedBlockFromNodeWithKey:(uint32_t)nodeKey
                                stopBeforeNodeWithKey:(uint32_t)stopBeforeNodeKey
                                          scaleFactor:(CGFloat)scaleFactor;

- (EucCSSLayoutPositionedBlock *)layoutFromPoint:(EucCSSLayoutPoint)point
                                         inFrame:(CGRect)frame
                              returningNextPoint:(EucCSSLayoutPoint *)returningNextPoint
                              returningCompleted:(BOOL *)returningCompleted
                                     scaleFactor:(CGFloat)scaleFactor;

- (EucCSSLayoutPositionedBlock *)_layoutFromPoint:(EucCSSLayoutPoint)point
                                          inFrame:(CGRect)frame
                               returningNextPoint:(EucCSSLayoutPoint *)returningNextPoint
                               returningCompleted:(BOOL *)returningCompleted
                                 lastBlockNodeKey:(uint32_t)lastBlockNodeKey
                            stopBeforeNodeWithKey:(uint32_t)stopBeforeNodeKey
                            constructingAncestors:(BOOL)constructingAncestors
                                      scaleFactor:(CGFloat)scaleFactor;

- (EucCSSLayoutPoint)layoutPointForNode:(EucCSSIntermediateDocumentNode *)node;

@end
