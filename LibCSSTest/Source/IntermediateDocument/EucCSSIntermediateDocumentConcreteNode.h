//
//  EucCSSIntermediateDocumentConcreteNode.h
//  LibCSSTest
//
//  Created by James Montgomerie on 10/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <libcss/libcss.h>

#import "EucCSSIntermediateDocumentNode.h"

@class EucCSSIntermediateDocument, THStringRenderer;
@protocol EucCSSDocumentTreeNode;

@interface EucCSSIntermediateDocumentConcreteNode : EucCSSIntermediateDocumentNode {
    id<EucCSSDocumentTreeNode> _documentTreeNode;
    
    NSArray *_children;
    
    BOOL _stylesComputed;
    css_computed_style *_computedStyle;
    css_computed_style *_computedBeforeStyle;
    css_computed_style *_computedAfterStyle;
    
    NSString *_text;
}

@property (nonatomic, readonly) id<EucCSSDocumentTreeNode> documentTreeNode;

@property (nonatomic, readonly) NSString *name;

- (id)initWithDocumentTreeNode:(id<EucCSSDocumentTreeNode>)documentTreeNode inDocument:(EucCSSIntermediateDocument *)document;

@property (nonatomic, readonly) css_computed_style *computedBeforeStyle;
@property (nonatomic, readonly) css_computed_style *computedAfterStyle;

@end
