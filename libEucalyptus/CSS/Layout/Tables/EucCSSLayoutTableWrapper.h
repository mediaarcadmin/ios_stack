//
//  EucCSSLayoutTableWrapper.h
//  libEucalyptus
//
//  Created by James Montgomerie on 21/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucCSSLayoutTableBox.h"

@class EucCSSLayouter, EucCSSLayoutTableCaption, EucCSSLayoutTableTable;

@interface EucCSSLayoutTableWrapper : EucCSSLayoutTableBox {
    EucCSSLayouter *_layouter;
    EucCSSLayoutTableCaption *_caption;
    EucCSSLayoutTableTable *_table;
}

@property (nonatomic, retain, readonly) EucCSSLayouter *layouter;
@property (nonatomic, retain, readonly) EucCSSLayoutTableCaption *caption;
@property (nonatomic, retain, readonly) EucCSSLayoutTableTable *table;

- (id)initWithNode:(EucCSSIntermediateDocumentNode *)node layouter:(EucCSSLayouter *)layouter;

- (EucCSSIntermediateDocumentNode *)accumulateCaptionNode:(EucCSSIntermediateDocumentNode *)captionNode;

@end
