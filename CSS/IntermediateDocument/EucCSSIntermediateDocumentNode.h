//
//  EucCSSIntermediateDocumentNode.h
//  LibCSSTest
//
//  Created by James Montgomerie on 24/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libcss/libcss.h>

@class EucCSSIntermediateDocument, THStringRenderer;

@interface EucCSSIntermediateDocumentNode : NSObject {
    EucCSSIntermediateDocument *_document;
    
    uint32_t _key;
    THStringRenderer *_stringRenderer;
}

// Concrete:

@property (nonatomic, assign) EucCSSIntermediateDocument *document;
@property (nonatomic, assign) uint32_t key;

@property (nonatomic, readonly) EucCSSIntermediateDocumentNode *blockLevelNode;
@property (nonatomic, readonly) EucCSSIntermediateDocumentNode *blockLevelParent;

@property (nonatomic, readonly) EucCSSIntermediateDocumentNode *next;
- (EucCSSIntermediateDocumentNode *)nextUnder:(EucCSSIntermediateDocumentNode *)under;

@property (nonatomic, readonly) EucCSSIntermediateDocumentNode *nextDisplayable;
- (EucCSSIntermediateDocumentNode *)nextDisplayableUnder:(EucCSSIntermediateDocumentNode *)under;


@property (nonatomic, readonly) THStringRenderer *stringRenderer;

// Overridable:
@property (nonatomic, readonly) BOOL isTextNode;  // Default: NO
@property (nonatomic, readonly) NSString *text;   // Default: nil;

// Abstract:

@property (nonatomic, readonly) EucCSSIntermediateDocumentNode *parent;
@property (nonatomic, readonly) NSUInteger childrenCount;
@property (nonatomic, readonly) NSArray *children;

@property (nonatomic, readonly) css_computed_style *computedStyle;

@end
