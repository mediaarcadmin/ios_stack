//
//  EucCSSLayoutTableBox.h
//  libEucalyptus
//
//  Created by James Montgomerie on 21/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EucCSSIntermediateDocumentNode;

@interface EucCSSLayoutTableBox : NSObject {
    EucCSSIntermediateDocumentNode *_documentNode;
    EucCSSIntermediateDocumentNode *_nextNodeInDocument;
}

@property (nonatomic, retain) EucCSSIntermediateDocumentNode *documentNode;
@property (nonatomic, retain) EucCSSIntermediateDocumentNode *nextNodeInDocument;

- (id)initWithNode:(EucCSSIntermediateDocumentNode *)node;

@end
