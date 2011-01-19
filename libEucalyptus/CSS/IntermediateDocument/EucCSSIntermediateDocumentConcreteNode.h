//
//  EucCSSIntermediateDocumentConcreteNode.h
//  LibCSSTest
//
//  Created by James Montgomerie on 10/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libcss/libcss.h>

#import "EucCSSIntermediateDocumentNode.h"

@class EucCSSIntermediateDocument, THStringRenderer;
@protocol EucCSSDocumentTreeNode;

@interface EucCSSIntermediateDocumentConcreteNode : EucCSSIntermediateDocumentNode {
    id<EucCSSDocumentTreeNode> _documentTreeNode;
    
    BOOL _childrenComputed;
    uint32_t _childCount;
    uint32_t *_childKeys;
    
    css_select_results *_selectResults;
    BOOL _stylesComputed;
    
    NSString *_text;
}

@property (nonatomic, readonly) id<EucCSSDocumentTreeNode> documentTreeNode;

@property (nonatomic, readonly) NSString *name;

- (id)initWithDocumentTreeNode:(id<EucCSSDocumentTreeNode>)documentTreeNode inDocument:(EucCSSIntermediateDocument *)document;

@property (nonatomic, readonly) css_computed_style *computedBeforeStyle;
@property (nonatomic, readonly) css_computed_style *computedAfterStyle;

@end
