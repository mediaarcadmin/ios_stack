//
//  EucHTMLDocumentNode.h
//  LibCSSTest
//
//  Created by James Montgomerie on 10/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EucHTMLDBNode, EucHTMLDocument;

@interface EucHTMLDocumentNode : NSObject {
    EucHTMLDBNode *_dbNode;
    EucHTMLDocument *_document;
    
    css_computed_style *_computedStyle;
}

@property (nonatomic, readonly) uint32_t key;

- (id)initWithHTMLDBNode:(EucHTMLDBNode *)dbNode inDocument:(EucHTMLDocument *)document;
- (EucHTMLDocumentNode *)parent;
- (EucHTMLDocumentNode *)next;

@end
