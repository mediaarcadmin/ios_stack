//
//  EucCSSLayoutSizedBlock.h
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

#import "EucCSSLayoutSizedContainer.h"

@class EucCSSIntermediateDocumentNode, EucCSSLayoutPositionedBlock;

@interface EucCSSLayoutSizedBlock : EucCSSLayoutSizedContainer {
    EucCSSIntermediateDocumentNode *_documentNode;
    CGFloat _widthAddition;
}

@property (nonatomic, retain, readonly) EucCSSIntermediateDocumentNode *documentNode;

- (id)initWithDocumentNode:(EucCSSIntermediateDocumentNode *)documentNode
               scaleFactor:(CGFloat)scaleFactor;

- (EucCSSLayoutPositionedBlock *)positionBlockForFrame:(CGRect)frame
                                           inContainer:(EucCSSLayoutPositionedContainer *)container
                                         usingLayouter:(EucCSSLayouter *)layouter;

@end
