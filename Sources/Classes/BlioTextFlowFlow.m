//
//  BlioTextFlowFlow.m
//  BlioApp
//
//  Created by James Montgomerie on 18/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioTextFlowFlow.h"

@interface BlioTextFlowFlow ()

@property (nonatomic, assign, readonly) uint32_t key;

@end

@implementation BlioTextFlowFlow

@synthesize textFlow = _textFlow;

@synthesize key = _key;
@synthesize childCount = _childCount;
@synthesize firstChild = _firstChild;

- (id)initWithTextFlow:(BlioTextFlow *)textFlow key:(uint32_t)key
{
    if((self = [super init])) {
        _textFlow = textFlow;
        _key = key;
    }
    return self;
}

- (EucCSSDocumentTreeNodeKind)kind
{
    return EucCSSDocumentTreeNodeKindRoot;
}

- (NSString *)name
{
    return @"Flow";
}

- (id<EucCSSDocumentTreeNode>)previousSibling
{
    return nil;
}

- (id<EucCSSDocumentTreeNode>)nextSibling
{
    return nil;
}

- (id<EucCSSDocumentTreeNode>)parent
{
    return nil;
}

- (NSString *)attributeWithName:(NSString *)attributeName
{
    return nil;
}

- (BOOL)getCharacterContents:(const char **)contents length:(size_t *)length
{
    return NO;
}

- (BOOL)isImageNode
{
    return NO;
}

- (NSString *)imageSourceURL
{
    return nil;
}

@end
