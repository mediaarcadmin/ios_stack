//
//  EucCSSDocumentNode.h
//  LibCSSTest
//
//  Created by James Montgomerie on 24/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libcss/libcss.h>

@class EucCSSDocument, THStringRenderer;

@interface EucCSSDocumentNode : NSObject {
    EucCSSDocument *_document;
    
    THStringRenderer *_stringRenderer;
}

// Concrete:

@property (nonatomic, assign) EucCSSDocument *document;
@property (nonatomic, assign) uint32_t key;

@property (nonatomic, readonly) EucCSSDocumentNode *blockLevelNode;
@property (nonatomic, readonly) EucCSSDocumentNode *blockLevelParent;

@property (nonatomic, readonly) EucCSSDocumentNode *next;
- (EucCSSDocumentNode *)nextUnder:(EucCSSDocumentNode *)under;

@property (nonatomic, readonly) EucCSSDocumentNode *nextDisplayable;
- (EucCSSDocumentNode *)nextDisplayableUnder:(EucCSSDocumentNode *)under;


@property (nonatomic, readonly) THStringRenderer *stringRenderer;

// Overridable:
@property (nonatomic, readonly) BOOL isTextNode;  // Default: NO
@property (nonatomic, readonly) NSString *text;   // Default: nil;

// Abstract:

@property (nonatomic, readonly) EucCSSDocumentNode *parent;
@property (nonatomic, readonly) NSUInteger childrenCount;
@property (nonatomic, readonly) NSArray *children;

@property (nonatomic, readonly) css_computed_style *computedStyle;

@end
