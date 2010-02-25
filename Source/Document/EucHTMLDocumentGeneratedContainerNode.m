//
//  EucHTMLDocumentGeneratedContainerNode.m
//  LibCSSTest
//
//  Created by James Montgomerie on 24/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucHTMLDocumentGeneratedContainerNode.h"
#import "EucHTMLDocument.h"
#import "EucHTMLDocumentNode.h"
#import "EucHTMLDocumentConcreteNode.h"

@implementation EucHTMLDocumentGeneratedContainerNode

- (id)initWithDocument:(EucHTMLDocument *)document 
             parentKey:(uint32_t)parentKey
        isBeforeParent:(BOOL)beforeParent;
{
    if((self = [super init])) {
        self.document = document;
        self.key = parentKey | (beforeParent ? EucHTMLDocumentNodeKeyFlagBeforeContainerNode : EucHTMLDocumentNodeKeyFlagAfterContainerNode);
        _parentKey = parentKey;
        _beforeParent = beforeParent;
    }
    return self;
}

- (EucHTMLDocumentNode *)parent
{
    return [self.document nodeForKey:_parentKey];
}

- (NSUInteger)childrenCount
{
    return 1;
}

- (NSArray *)children
{
    return [NSArray arrayWithObject:[self.document nodeForKey:self.key | EucHTMLDocumentNodeKeyFlagGeneratedTextNode]];
}

- (css_computed_style *)computedStyle
{
    EucHTMLDocumentConcreteNode *parent = (EucHTMLDocumentConcreteNode *)(self.parent);
    return _beforeParent ? parent.computedBeforeStyle : parent.computedAfterStyle;
}

@end
