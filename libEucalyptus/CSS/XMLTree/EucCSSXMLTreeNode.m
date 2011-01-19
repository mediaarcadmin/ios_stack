//
//  EucCSSXMLTreeNode.m
//  libEucalyptus
//
//  Created by James Montgomerie on 11/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSXMLTreeNode.h"

@interface EucCSSXMLTreeNode ()

@property (nonatomic, assign) EucCSSXMLTreeNode *parent;
@property (nonatomic, assign) EucCSSXMLTreeNode *previousSibling;
@property (nonatomic, assign) EucCSSXMLTreeNode *nextSibling;

@property (nonatomic, assign, readonly) uint32_t key;
@property (nonatomic, assign, readonly) EucCSSDocumentTreeNodeKind kind;

@end

@implementation EucCSSXMLTreeNode

@synthesize key = _key;
@synthesize kind = _kind;
@synthesize name = _name;
@synthesize attributes = _attributes;
@synthesize characters = _characters;
@synthesize parent = _parent;
@synthesize previousSibling = _previousSibling;
@synthesize nextSibling = _nextSibling;

- (id)initWithKey:(uint32_t)key kind:(EucCSSDocumentTreeNodeKind)kind
{
    if((self = [super init])) {
        _key = key;
        _kind = kind;
    }
    return self;
}

- (void)dealloc
{
    [_attributes release];
    [_name release];
    [_characters release];
    [_children release];
    [super dealloc];
}

- (uint32_t)childCount
{
    return _children.count;
}

- (EucCSSXMLTreeNode *)firstChild
{
    return [_children objectAtIndex:0];
}

- (void)addChild:(EucCSSXMLTreeNode *)child
{
    if(!_children) {
        _children = [[NSMutableArray alloc] init];
    } else {
        EucCSSXMLTreeNode *previousSibling = _children.lastObject;
        child.previousSibling = previousSibling;
        previousSibling.nextSibling = child;
    }
    child.parent = self;
    [_children addObject:child];
}

-(NSString *)attributeWithName:(NSString *)attributeName
{
    return [_attributes objectForKey:attributeName];
}   

- (BOOL)getCharacterContents:(const char **)contents length:(size_t *)length
{
    if(_characters) {
        *contents = _characters.bytes;
        *length = _characters.length;
        return YES;
    } else {
        return NO;
    }
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
    return NO;
}

- (NSString *)CSSID
{
    return nil;
}

- (NSString *)inlineStyle
{
    return nil;
}

@end
