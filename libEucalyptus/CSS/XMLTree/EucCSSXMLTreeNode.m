//
//  EucCSSXMLTreeNode.m
//  libEucalyptus
//
//  Created by James Montgomerie on 11/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSXMLTreeNode.h"

#import <libwapcaplet/libwapcaplet.h>
#import "LWCNSStringAdditions.h"

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

- (void)setName:(NSString *)name
{
    _name = (NSString *)lwc_intern_ns_string(name);
}

- (void)dealloc
{
    if(_attributesCountX2) {
        for(NSUInteger i = 0; i < _attributesCountX2; ++i) {
            lwc_string_unref(_attributes[i]);
        }
        free(_attributes);
    }
    if(_name) {
        lwc_string_unref((lwc_string *)_name);
    }
    
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
    NSString *ret = nil;
    if(_attributesCountX2) {
        lwc_string *lwcName = lwc_intern_ns_string(attributeName);

        for(NSUInteger i = 0; i < _attributesCountX2; i += 2) {
            if(lwcName == _attributes[i]) {
                ret = NSStringFromLWCString(_attributes[i+1]);
                break;
            }
        }
               
        lwc_string_unref(lwcName);
    }
    return ret;
}   

- (void)addAttributeValue:(NSString *)value forName:(NSString *)name;
{
    if(_attributesCountX2 == _attributesCapacity) {
        _attributesCapacity += 8;
        _attributes = realloc(_attributes, _attributesCapacity * sizeof(lwc_string *));
    }
    _attributes[_attributesCountX2++] = lwc_intern_ns_string(name);
    _attributes[_attributesCountX2++] = lwc_intern_ns_string(value);
}

- (BOOL)hasAttributes
{
    return _attributesCountX2 != 0;
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
