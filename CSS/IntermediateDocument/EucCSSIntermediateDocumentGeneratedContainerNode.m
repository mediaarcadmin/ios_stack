//
//  EucCSSIntermediateDocumentGeneratedContainerNode.m
//  LibCSSTest
//
//  Created by James Montgomerie on 24/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSIntermediateDocumentGeneratedContainerNode.h"
#import "EucCSSIntermediateDocument.h"
#import "EucCSSIntermediateDocument_Package.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "EucCSSIntermediateDocumentConcreteNode.h"

@implementation EucCSSIntermediateDocumentGeneratedContainerNode

- (id)initWithDocument:(EucCSSIntermediateDocument *)document 
             parentKey:(uint32_t)parentKey
        isBeforeParent:(BOOL)beforeParent;
{
    if((self = [super init])) {
        self.document = document;
        self.key = parentKey | (beforeParent ? EucCSSIntermediateDocumentNodeKeyFlagBeforeContainerNode : EucCSSIntermediateDocumentNodeKeyFlagAfterContainerNode);
        _parentKey = parentKey;
        _beforeParent = beforeParent;
        _childKey = self.key | EucCSSIntermediateDocumentNodeKeyFlagGeneratedTextNode;
    }
    return self;
}

- (EucCSSIntermediateDocumentNode *)parent
{
    return [self.document nodeForKey:_parentKey];
}

- (uint32_t)childCount
{
    return 1;
}

- (uint32_t *)childKeys
{
    return &_childKey;
}

- (css_computed_style *)computedStyle
{
    EucCSSIntermediateDocumentConcreteNode *parent = (EucCSSIntermediateDocumentConcreteNode *)(self.parent);
    return _beforeParent ? parent.computedBeforeStyle : parent.computedAfterStyle;
}

@end
