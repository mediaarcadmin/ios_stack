//
//  EucCSSLayoutTableBox.h
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

@class EucCSSLayoutTableWrapper, EucCSSIntermediateDocumentNode;

@interface EucCSSLayoutTableBox : NSObject {
    EucCSSLayoutTableWrapper *_wrapper;
    EucCSSIntermediateDocumentNode *_documentNode;
    EucCSSIntermediateDocumentNode *_nextNodeInDocument;
}

@property (nonatomic, assign) EucCSSLayoutTableWrapper *wrapper;
@property (nonatomic, retain) EucCSSIntermediateDocumentNode *documentNode;
@property (nonatomic, retain) EucCSSIntermediateDocumentNode *nextNodeInDocument;

@property (nonatomic, assign, readonly) BOOL documentNodeIsRepresentative;

- (id)initWithNode:(EucCSSIntermediateDocumentNode *)node wrapper:(EucCSSLayoutTableWrapper *)wrapper;

// Returns CGFLOAT_MAX if a set width is not defined.
- (CGFloat)widthWithScaleFactor:(CGFloat)scaleFactor;

@end
