//
//  EucHTMLNodeManager.m
//  LibCSSTest
//
//  Created by James Montgomerie on 08/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import "EucHTMLDBNodeManager.h"
#import "EucHTMLDBNode.h"
#import <Foundation/NSObjCRuntime.h>

@implementation EucHTMLDBNodeManager

- (id)initWithHTMLDB:(EucHTMLDB *)htmlDb lwcContext:(lwc_context *)lwcContext;
{
    if((self = [super init])){
        _htmlDb = htmlDb;
        _lwcContext = lwc_context_ref(lwcContext);
        
        static const CFDictionaryKeyCallBacks keyCallbacks = {0};
        static const CFDictionaryValueCallBacks valueCallbacks = {0};
        _keyToExtantNode = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                     0,
                                                     &keyCallbacks,
                                                     &valueCallbacks);
    }
    return self;
}

- (void)dealloc
{
    [_bodyNode release];
    lwc_context_unref(_lwcContext);
    [super dealloc];
}

- (EucHTMLDBNode *)nodeForKey:(uint32_t)key
{
    EucHTMLDBNode *node = (EucHTMLDBNode *)CFDictionaryGetValue(_keyToExtantNode, (void *)(uintptr_t)key);
    if(!node) {
        node = [[[EucHTMLDBNode alloc] initWithManager:self HTMLDB:_htmlDb key:key lwcContext:_lwcContext] autorelease];
        CFDictionarySetValue(_keyToExtantNode, (void *)(uintptr_t)key, node);
    }
    return node;
}

- (BOOL)nodeIsBody:(EucHTMLDBNode *)node
{
    if(_bodyNode) {
        return node == _bodyNode;
    } else {
        if(node.kind == nodeKindElement) {
            lwc_string *bodyString;
            lwc_context_intern(_lwcContext, "body", 4, &bodyString);
            lwc_string *nodeName = node.name;
            bool isEqual = false;
            lwc_error err = lwc_context_string_caseless_isequal(_lwcContext,
                                                                nodeName, 
                                                                bodyString,
                                                                &isEqual);
            if(err == CSS_OK && isEqual) {
                _bodyNode = [node retain];
            }
            
            lwc_context_string_unref(_lwcContext, bodyString);
            
            return _bodyNode ? YES : NO;
        }                                          
    }        
}

- (void)notifyOfDealloc:(EucHTMLDBNode *)node
{
    CFDictionaryRemoveValue(_keyToExtantNode, (void *)(uintptr_t)node.key);
}

@end

