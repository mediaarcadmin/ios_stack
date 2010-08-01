//
//  EucCSSIntermediateDocumentNode.h
//  LibCSSTest
//
//  Created by James Montgomerie on 24/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

struct css_computed_style;

@class EucCSSIntermediateDocument, THStringRenderer;

@interface EucCSSIntermediateDocumentNode : NSObject {
    EucCSSIntermediateDocument *_document;
    
    uint32_t _key;
    THStringRenderer *_stringRenderer;
}

// Concrete:
@property (nonatomic, assign) uint32_t key;
@property (nonatomic, assign) EucCSSIntermediateDocument *document;

@property (nonatomic, readonly) EucCSSIntermediateDocumentNode *blockLevelNode;
@property (nonatomic, readonly) EucCSSIntermediateDocumentNode *blockLevelParent;

@property (nonatomic, readonly) EucCSSIntermediateDocumentNode *next;
- (EucCSSIntermediateDocumentNode *)nextUnder:(EucCSSIntermediateDocumentNode *)under;

@property (nonatomic, readonly) EucCSSIntermediateDocumentNode *nextDisplayable;
- (EucCSSIntermediateDocumentNode *)nextDisplayableUnder:(EucCSSIntermediateDocumentNode *)under;
- (EucCSSIntermediateDocumentNode *)displayableNodeAfter:(EucCSSIntermediateDocumentNode *)child under:(EucCSSIntermediateDocumentNode *)under;

@property (nonatomic, readonly) EucCSSIntermediateDocumentNode *previousDisplayableSibling;

@property (nonatomic, readonly) THStringRenderer *stringRenderer;

// Overridable:
@property (nonatomic, readonly) BOOL isTextNode;  // Default: NO
@property (nonatomic, readonly) NSString *text;   // Default: nil;
@property (nonatomic, readonly) NSArray *preprocessedWords; // Default: nil - optional.

@property (nonatomic, readonly) BOOL isImageNode;
@property (nonatomic, readonly) NSURL *imageSource;
@property (nonatomic, readonly) NSString *altText;
@property (nonatomic, readonly) NSString *name; // Will just return the class name - can be overridden to return e.g. 
                                                // XML name of the underlying document node.  Just used for debugging.

// Abstract:

@property (nonatomic, readonly) EucCSSIntermediateDocumentNode *parent;
@property (nonatomic, readonly) uint32_t childCount;
@property (nonatomic, readonly) uint32_t *childKeys;

@property (nonatomic, readonly) struct css_computed_style *computedStyle;

@end
