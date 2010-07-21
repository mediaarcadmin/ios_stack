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

#import "EucCSSLayoutDocumentRun.h"

@class EucCSSIntermediateDocument, EucCSSIntermediateDocumentNode, EucCSSLayoutPositionedBlock;

typedef struct EucCSSLayoutPoint
{
    uint32_t nodeKey;
    uint32_t word;
    uint32_t element;
} EucCSSLayoutPoint;

@interface EucCSSLayouter : NSObject {
    EucCSSIntermediateDocument *_document;
    CGFloat _scaleFactor;
}

@property (nonatomic, retain) EucCSSIntermediateDocument *document;
@property (nonatomic, assign) CGFloat scaleFactor;

- (id)initWithDocument:(EucCSSIntermediateDocument *)document
           scaleFactor:(CGFloat)scaleFactor;

- (EucCSSLayoutPositionedBlock *)layoutFromPoint:(EucCSSLayoutPoint)point
                                         inFrame:(CGRect)frame
                              returningNextPoint:(EucCSSLayoutPoint *)returningNextPoint
                              returningCompleted:(BOOL *)returningCompleted
                                lastBlockNodeKey:(uint32_t)lastBlockNodeKey;

- (EucCSSLayoutPoint)layoutPointForNode:(EucCSSIntermediateDocumentNode *)node;

@end
