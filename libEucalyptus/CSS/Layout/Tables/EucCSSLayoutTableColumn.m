//
//  EucCSSLayoutTableColumn.m
//  libEucalyptus
//
//  Created by James Montgomerie on 21/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutTableColumn.h"

#import "EucCSSIntermediateDocumentNode.h"

#import <libcss/libcss.h>

@implementation EucCSSLayoutTableColumn

- (id)initWithNode:(EucCSSIntermediateDocumentNode *)node wrapper:(EucCSSLayoutTableWrapper *)wrapper
{
    if((self = [super initWithNode:node wrapper:wrapper])) {
        NSParameterAssert(node.display == CSS_DISPLAY_TABLE_COLUMN);
    }
    return self;
}

- (BOOL)documentNodeIsRepresentative
{
    return self.documentNode.display == CSS_DISPLAY_TABLE_COLUMN;
}

@end
