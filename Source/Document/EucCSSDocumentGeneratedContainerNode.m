//
//  EucCSSDocumentGeneratedContainerNode.m
//  LibCSSTest
//
//  Created by James Montgomerie on 24/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSDocumentGeneratedContainerNode.h"
#import "EucCSSDocument.h"
#import "EucCSSDocumentNode.h"
#import "EucCSSDocumentConcreteNode.h"

@implementation EucCSSDocumentGeneratedContainerNode

- (id)initWithDocument:(EucCSSDocument *)document 
             parentKey:(uint32_t)parentKey
        isBeforeParent:(BOOL)beforeParent;
{
    if((self = [super init])) {
        self.document = document;
        self.key = parentKey | (beforeParent ? EucCSSDocumentNodeKeyFlagBeforeContainerNode : EucCSSDocumentNodeKeyFlagAfterContainerNode);
        _parentKey = parentKey;
        _beforeParent = beforeParent;
    }
    return self;
}

- (EucCSSDocumentNode *)parent
{
    return [self.document nodeForKey:_parentKey];
}

- (NSUInteger)childrenCount
{
    return 1;
}

- (NSArray *)children
{
    return [NSArray arrayWithObject:[self.document nodeForKey:self.key | EucCSSDocumentNodeKeyFlagGeneratedTextNode]];
}

- (css_computed_style *)computedStyle
{
    EucCSSDocumentConcreteNode *parent = (EucCSSDocumentConcreteNode *)(self.parent);
    return _beforeParent ? parent.computedBeforeStyle : parent.computedAfterStyle;
}

@end
