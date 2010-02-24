//
//  EucHTMLDocumentConcreteNode.h
//  LibCSSTest
//
//  Created by James Montgomerie on 10/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <libcss/libcss.h>

#import "EucHTMLDocumentNode.h"

@class EucHTMLDBNode, EucHTMLDocument, THStringRenderer;

@interface EucHTMLDocumentConcreteNode : EucHTMLDocumentNode {
    EucHTMLDBNode *_dbNode;
    
    NSArray *_children;
    
    BOOL _stylesComputed;
    css_computed_style *_computedStyle;
    css_computed_style *_computedBeforeStyle;
    css_computed_style *_computedAfterStyle;
    
    NSString *_text;
}

@property (nonatomic, readonly) EucHTMLDBNode *dbNode;

@property (nonatomic, readonly) NSString *name;

- (id)initWithHTMLDBNode:(EucHTMLDBNode *)dbNode inDocument:(EucHTMLDocument *)document;

@property (nonatomic, readonly) css_computed_style *computedBeforeStyle;
@property (nonatomic, readonly) css_computed_style *computedAfterStyle;

@end
