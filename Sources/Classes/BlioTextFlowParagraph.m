//
//  BlioTextFlowParagraph.m
//  BlioApp
//
//  Created by James Montgomerie on 18/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioTextFlowParagraph.h"
#import "BlioTextFlowParagraphWords.h"
#import "BlioTextFlowFlow.h"

@interface BlioTextFlowParagraph ()

@property (nonatomic, assign, readonly) BlioTextFlowFlow *parent;

@property (nonatomic, assign, readonly) uint32_t key;

@end

@implementation BlioTextFlowParagraph

@synthesize textFlow = _textFlow;

@synthesize parent = _parent;
@synthesize previousSibling = _previousSibling;
@synthesize nextSibling = _nextSibling;

@synthesize key = _key;

@synthesize paragraphWords = _paragraphWords;

- (id)initWithTextFlow:(BlioTextFlow *)textFlow 
              flowNode:(BlioTextFlowFlow *)flowNode
                   key:(uint32_t)key
{
    if((self = [super init])) {
        _textFlow = textFlow;
        _key = key;
        _parent = flowNode;
    }
    return self;
}

- (EucCSSDocumentTreeNodeKind)kind
{
    return EucCSSDocumentTreeNodeKindElement;
}

- (NSString *)name
{
    return @"Paragraph";
}

- (uint32_t)childCount
{
    return _paragraphWords ? 1 : 0;
}

- (id<EucCSSDocumentTreeNode>)firstChild
{
    return _paragraphWords;
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

- (NSString *)imageSourceURLString
{
    return nil;
}

- (BOOL)isHyperlinkNode
{
    return NO;
}

- (NSString *)hyperlinkURLString
{
    return nil;
}

@end
