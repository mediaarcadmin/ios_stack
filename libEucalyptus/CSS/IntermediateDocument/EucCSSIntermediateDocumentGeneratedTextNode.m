//
//  EucCSSIntermediateDocumentGeneratedTextNode.m
//  LibCSSTest
//
//  Created by James Montgomerie on 24/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSIntermediateDocumentGeneratedTextNode.h"
#import "EucCSSIntermediateDocument.h"
#import "LWCNSStringAdditions.h"

#import <libcss/libcss.h>

@implementation EucCSSIntermediateDocumentGeneratedTextNode

- (id)initWithDocument:(EucCSSIntermediateDocument *)document 
             parentKey:(uint32_t)parentKey
{
    if((self = [super init])) {
        self.document = document;
        self.key = parentKey | EucCSSIntermediateDocumentNodeKeyFlagGeneratedTextNode;
        _parentKey = parentKey;
    }
    return self;
}

- (EucCSSIntermediateDocumentNode *)parent
{
    return [self.document nodeForKey:_parentKey];
}

- (NSUInteger)childrenCount
{
    return 0;
}

- (NSArray *)children
{
    return nil;
}

- (BOOL)isTextNode
{
    return YES;
}

- (NSString *)text
{ 
    NSString *ret = nil;
    const css_computed_content_item *content;
    if(css_computed_content(self.parent.computedStyle, &content) == CSS_CONTENT_SET) {
        if(content->type == CSS_COMPUTED_CONTENT_STRING) {
            ret = [NSString stringWithLWCString:content->data.string];
        }
    }
    return ret;
}

- (css_computed_style *)computedStyle
{
    return nil;
}

@end
