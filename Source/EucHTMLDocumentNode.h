//
//  EucHTMLDocumentNode.h
//  LibCSSTest
//
//  Created by James Montgomerie on 10/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <libcss/libcss.h>

@class EucHTMLDBNode, EucHTMLDocument;

@interface EucHTMLDocumentNode : NSObject {
    EucHTMLDBNode *_dbNode;
    EucHTMLDocument *_document;
    
    NSArray *_children;
    
    css_computed_style *_computedStyle;
    NSString *_text;
}

@property (nonatomic, readonly) uint32_t key;
@property (nonatomic, readonly) EucHTMLDBNode *dbNode;

@property (nonatomic, readonly) css_computed_style *computedStyle;
@property (nonatomic, readonly) BOOL isTextNode;
@property (nonatomic, readonly) NSString *text;

@property (nonatomic, readonly) EucHTMLDocumentNode *parent;
@property (nonatomic, readonly) NSArray *children;
@property (nonatomic, readonly) EucHTMLDocumentNode *next;
- (EucHTMLDocumentNode *)nextUnder:(EucHTMLDocumentNode *)under;

- (id)initWithHTMLDBNode:(EucHTMLDBNode *)dbNode inDocument:(EucHTMLDocument *)document;

@end
