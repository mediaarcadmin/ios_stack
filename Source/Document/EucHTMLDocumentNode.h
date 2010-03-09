//
//  EucHTMLDocumentNode.h
//  LibCSSTest
//
//  Created by James Montgomerie on 24/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libcss/libcss.h>

@class EucHTMLDocument, THStringRenderer;

@interface EucHTMLDocumentNode : NSObject {
    EucHTMLDocument *_document;
    
    THStringRenderer *_stringRenderer;
}

// Concrete:

@property (nonatomic, assign) EucHTMLDocument *document;
@property (nonatomic, assign) uint32_t key;

@property (nonatomic, readonly) EucHTMLDocumentNode *blockLevelNode;
@property (nonatomic, readonly) EucHTMLDocumentNode *blockLevelParent;

@property (nonatomic, readonly) EucHTMLDocumentNode *next;
- (EucHTMLDocumentNode *)nextUnder:(EucHTMLDocumentNode *)under;

@property (nonatomic, readonly) EucHTMLDocumentNode *nextDisplayable;
- (EucHTMLDocumentNode *)nextDisplayableUnder:(EucHTMLDocumentNode *)under;


@property (nonatomic, readonly) THStringRenderer *stringRenderer;

// Overridable:
@property (nonatomic, readonly) BOOL isTextNode;  // Default: NO
@property (nonatomic, readonly) NSString *text;   // Default: nil;

// Abstract:

@property (nonatomic, readonly) EucHTMLDocumentNode *parent;
@property (nonatomic, readonly) NSUInteger childrenCount;
@property (nonatomic, readonly) NSArray *children;

@property (nonatomic, readonly) css_computed_style *computedStyle;

@end
