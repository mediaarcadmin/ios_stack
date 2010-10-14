//
//  EucCSSLayoutRunExtractor.h
//  libEucalyptus
//
//  Created by James Montgomerie on 21/04/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EucCSSIntermediateDocument, EucCSSLayoutDocumentRun;

@interface EucCSSLayoutRunExtractor : NSObject {
    EucCSSIntermediateDocument *_document;
}

@property (nonatomic, retain) EucCSSIntermediateDocument *document;

- (id)initWithDocument:(EucCSSIntermediateDocument *)document;
- (EucCSSLayoutDocumentRun *)documentRunForNodeWithKey:(uint32_t)nextRunNodeKey;
- (EucCSSLayoutDocumentRun *)nextDocumentRunForDocumentRun:(EucCSSLayoutDocumentRun *)run;
- (EucCSSLayoutDocumentRun *)previousDocumentRunForDocumentRun:(EucCSSLayoutDocumentRun *)run;

@end
