/*
 *  EucHTMLDBNode.m
 *  LibCSSTest
 *
 *  Created by James Montgomerie on 08/12/2009.
 *  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
 *
 */

#import "LWCNSStringAdditions.h"
#import "EucHTMLDBNode.h"
#import "EucHTMLDBNodeManager.h"
#import <libcss/libcss.h>

@interface EucHTMLDBNode ()

@property (nonatomic, assign, readonly) uint32_t *childKeys;
@property (nonatomic, assign, readonly) uint32_t *attributeArray;
@property (nonatomic, assign, readonly) uint32_t attributeArrayCount;

@property (nonatomic, assign, readonly) uint32_t key;
@property (nonatomic, assign, readonly) EucCSSDocumentTreeNodeKind kind;

@end

@implementation EucHTMLDBNode

@synthesize key = _key;
@synthesize lwcContext = _lwcContext;
 
- (id)initWithManager:(EucHTMLDBNodeManager *)manager HTMLDB:(EucHTMLDB *)htmlDb key:(uint32_t)key lwcContext:(lwc_context *)lwcContext
{
    if((self = [super init])) {
        _manager = [manager retain];
        _htmlDb = htmlDb;
        _key = key;
        
        _lwcContext = lwc_context_ref(lwcContext);
        
        if(EucHTMLDBCopyNode(_htmlDb, _key, &_rawNode) != HUBBUB_OK) {
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)dealloc;
{
    [_manager notifyOfDealloc:self];
    if(_classes) {
        for(int i = 0; i < _classesCount; ++i) {
            lwc_context_string_unref(_lwcContext, _classes[i]);
        }
        free(_classes);
    }
    if(_childKeys) {
        free(_childKeys);
    }
    if(_attributeArray) {
        free(_attributeArray);
    }
    if(_characterContents) {
        free(_characterContents);
    }    
    [_name release];
    if(_lwcContext) {
        lwc_context_unref(_lwcContext);
    }
    free(_rawNode);
    
    [_manager release];
    
    [super dealloc];
}

- (EucHTMLDBNode *)parent
{
    if(_key != _manager.htmlRootKey) {
        uint32_t parentKey = _rawNode[parentPosition];
        if(parentKey) {
            return [_manager nodeForKey:parentKey];
        } 
    }
    return nil;
}

- (EucHTMLDBNode *)firstChild
{
    if(self.childCount) {
        return [_manager nodeForKey:self.childKeys[0]];
    }
    return nil;
}

- (EucHTMLDBNode *)previousSibling
{
    EucHTMLDBNode *ret = nil;
    EucHTMLDBNode *parent = self.parent;
    uint32_t parentChildCount = parent.childCount;
    if(parentChildCount > 1) {
        uint32_t key = self.key;
        uint32_t *parentChildKeys = parent.childKeys;
        if(parentChildKeys[0] != key) {
            for(uint32_t i = 1; i < parentChildCount; ++i) {
                if(parentChildKeys[i] == key) {
                    ret = [_manager nodeForKey:parentChildKeys[i-1]];
                    break;
                }
            }
        }
    }
    return ret;
}

- (EucHTMLDBNode *)nextSibling
{
    EucHTMLDBNode *ret = nil;
    EucHTMLDBNode *parent = self.parent;
    uint32_t parentChildCount = parent.childCount;
    if(parentChildCount > 1) {
        uint32_t key = self.key;
        uint32_t *parentChildKeys = parent.childKeys;
        uint32_t lastPotentialSelfIndex = parentChildCount - 2;
        for(uint32_t i = 0; i <= lastPotentialSelfIndex; ++i) {
            if(parentChildKeys[i] == key) {
                ret = [_manager nodeForKey:parentChildKeys[i+1]];
                break;
            }
        }
    }
    return ret;
}

- (EucCSSDocumentTreeNodeKind)kind
{
    return (EucCSSDocumentTreeNodeKind)(_rawNode[kindPosition]);
}

- (NSString *)name
{
    if(!_name && _rawNode[kindPosition] == EucCSSDocumentTreeNodeKindElement) {
        uint8_t *utf8Name;
        size_t length;
        EucHTMLDBCopyUTF8(_htmlDb, _rawNode[elementNamePosition], &utf8Name, &length);
        _name = [[NSString alloc] initWithBytesNoCopy:utf8Name length:length encoding:NSUTF8StringEncoding freeWhenDone:YES];
    } 
    return _name;
}

- (uint32_t *)attributeArray
{
    if(!_attributeArray &&
       _rawNode[kindPosition] == EucCSSDocumentTreeNodeKindElement &&
       _rawNode[elementAttributesPosition]) {        
        EucHTMLDBCopyUint32Array(_htmlDb, _rawNode[elementAttributesPosition], &_attributeArray, &_attributeArrayCount);
    }    
    return _attributeArray;
}

- (uint32_t)attributeArrayCount
{
    if(!_attributeArrayCount &&
       _rawNode[kindPosition] == EucCSSDocumentTreeNodeKindElement &&
       _rawNode[elementAttributesPosition]) {        
        [self attributeArray];
    }
    return _attributeArrayCount;
}

- (NSString *)attributeWithName:(NSString *)attributeName;
{    
    uint32_t attributeArrayCount = self.attributeArrayCount;
    if(attributeArrayCount) {    
        const char *utf8AttributeName = [attributeName UTF8String];
        
        uint32_t *attributeArray = self.attributeArray;
        size_t utf8AttributeNameLength = strlen(utf8AttributeName);
        
        for(uint32_t i = 0; i < attributeArrayCount; ++i) {
            hubbub_ns ns;
            hubbub_string thisName;
            hubbub_string thisValue;
            EucHTMLDBCopyAttribute(self->_htmlDb, attributeArray[i], &ns, &thisName, &thisValue);
            if(/*ns == HUBBUB_NS_HTML &&*/
               utf8AttributeNameLength == thisName.len && 
               strncasecmp(utf8AttributeName, (const char *)thisName.ptr, utf8AttributeNameLength) == 0 && thisValue.len) {
                free((void *)thisName.ptr);
                return [[NSString alloc] initWithBytesNoCopy:(void *)thisValue.ptr
                                                      length:thisValue.len
                                                    encoding:NSUTF8StringEncoding
                                                freeWhenDone:YES];
            }
            free((void *)thisName.ptr);
            free((void *)thisValue.ptr);
        }
    }
    return nil;
}

- (uint32_t)childCount
{
    if(!_childCount && _rawNode[childrenPosition]) {        
        [self childKeys];
    }
    return _childCount;
}

- (uint32_t *)childKeys
{
    if(!_childKeys && _rawNode[childrenPosition]) {        
        EucHTMLDBCopyUint32Array(_htmlDb, _rawNode[childrenPosition], &_childKeys, &_childCount);
    }    
    return _childKeys;
}

- (BOOL)getCharacterContents:(char **)contents length:(size_t *)length
{
    if(!_characterContents) {
        if(_rawNode[kindPosition] == EucCSSDocumentTreeNodeKindText) {
            EucHTMLDBCopyUTF8(_htmlDb, _rawNode[textTextPosition],
                              (uint8_t **)&_characterContents, &_characterContentsLength);
        }        
    }
    *contents = _characterContents;
    *length = _characterContentsLength;
    return contents ? YES : NO;
}

@end