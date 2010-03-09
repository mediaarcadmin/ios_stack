//
//  EucCSSLayouter.h
//  LibCSSTest
//
//  Created by James Montgomerie on 13/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EucCSSDocument, EucCSSLayoutPositionedBlock;

typedef struct EucCSSLayoutPoint
{
    uint32_t nodeKey;
    uint32_t word;
    uint32_t element;
} EucCSSLayoutPoint;

@interface EucCSSLayouter : NSObject {
    EucCSSDocument *_document;
}

@property (nonatomic, retain) EucCSSDocument *document;

- (EucCSSLayoutPositionedBlock *)layoutFromPoint:(EucCSSLayoutPoint)point
                                          inFrame:(CGRect)frame
                               returningNextPoint:(EucCSSLayoutPoint *)returningNextPoint
                               returningCompleted:(BOOL *)returningCompleted;

@end
