//
//  EucHTMLDocumentRendererLaidOutNode.m
//  LibCSSTest
//
//  Created by James Montgomerie on 10/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucHTMLDocumentRendererLaidOutNode.h"

const id const EucHTMLRendererSingleSpaceMarker = @" ";
const id const EucHTMLRendererOpenNodeMarker = @"o";
const id const EucHTMLRendererCloseNodeMarker = @"c";

@implementation EucHTMLDocumentRendererLaidOutNode

@synthesize documentNode = _documentNode;

@synthesize children = _children;

- (void)addChild:(EucHTMLDocumentRendererLaidOutNode *)child
{
    if(!_children) {
        _children = [[NSMutableArray alloc] init];
    }
    [_children addObject:child];
}

@synthesize lineContents = _lineContents;

@synthesize frame = _frame;

- (void)sizeToFit
{
}

- (void)sizeToFitHorizontally
{
}

@end
