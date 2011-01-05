//
//  EucCSSLayoutTableBox.m
//  libEucalyptus
//
//  Created by James Montgomerie on 21/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutTableBox.h"

#import "EucCSSIntermediateDocumentNode.h"

@implementation EucCSSLayoutTableBox

@synthesize wrapper = _wrapper;
@synthesize documentNode = _documentNode;
@synthesize nextNodeInDocument = _nextNodeInDocument;

- (id)initWithNode:(EucCSSIntermediateDocumentNode *)node wrapper:(EucCSSLayoutTableWrapper *)wrapper
{
    if((self = [super init])) {
        _wrapper = wrapper;
        _documentNode = [node retain];
        _nextNodeInDocument = [[node.parent displayableNodeAfter:node under:nil] retain];
    }
    return self;
}

- (void)dealloc
{
    [_documentNode release];
    [_nextNodeInDocument release];
    
    [super dealloc];
}

@end
