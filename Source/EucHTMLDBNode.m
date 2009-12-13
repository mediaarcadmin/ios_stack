/*
 *  EucHTMLDBNode.m
 *  LibCSSTest
 *
 *  Created by James Montgomerie on 08/12/2009.
 *  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
 *
 */

#import "EucHTMLDBNode.h"
#import "EucHTMLDBNodeManager.h"
#import <libcss/libcss.h>

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
    if(_childrenKeys) {
        free(_childrenKeys);
    }
    if(_attributeArray) {
        free(_attributeArray);
    }
    if(_characterContents) {
        free(_characterContents);
    }    
    if(_name) {
        lwc_context_string_unref(_lwcContext, _name);
    }
    if(_lwcContext) {
        lwc_context_unref(_lwcContext);
    }
    free(_rawNode);
    
    [_manager release];
    
    [super dealloc];
}

- (uint32_t)kind
{
    return _rawNode[kindPosition];
}

- (lwc_string *)name
{
    if(!_name && _rawNode[kindPosition] == nodeKindElement) {
        EucHTMLDBCopyLWCString(_htmlDb, _rawNode[elementNamePosition], _lwcContext, &_name);
    } 
    return _name;
}

css_error EucHTMLDBNodeName(void *pw, void *node, lwc_context *dict, lwc_string **nameOut)
{
    EucHTMLDBNodeManager *manager = (EucHTMLDBNodeManager *)pw;
    uint32_t key = (uint32_t)(intptr_t)node;

    lwc_string *name = [manager nodeForKey:key].name;
    if(name) {
        lwc_context_string_ref(dict, name);
    }
    *nameOut = name;
    
    return CSS_OK;
}

- (uint32_t *)attributeArray
{
    if(!_attributeArray && _rawNode[elementAttributesPosition]) {        
        EucHTMLDBCopyUint32Array(_htmlDb, _rawNode[elementAttributesPosition], &_attributeArray, &_attributeArrayCount);
    }    
    return _attributeArray;
}

- (uint32_t)attributeArrayCount
{
    if(!_attributeArrayCount && _rawNode[elementAttributesPosition]) {        
        [self attributeArray];
    }
    return _attributeArrayCount;
}

- (hubbub_string)copyHubbubAttributeForName:(const char *)attributeName;
{    
    uint32_t attributeArrayCount = self.attributeArrayCount;
    if(attributeArrayCount) {        
        uint32_t *attributeArray = self.attributeArray;
        size_t nameLength = strlen(attributeName);
        
        if(EucHTMLDBCopyUint32Array(self->_htmlDb, self->_rawNode[elementAttributesPosition], &attributeArray, &attributeArrayCount) == HUBBUB_OK) {
            for(uint32_t i = 0; i < attributeArrayCount; ++i) {
                hubbub_ns ns;
                hubbub_string thisName;
                hubbub_string thisValue;
                EucHTMLDBCopyAttribute(self->_htmlDb, attributeArray[i], &ns, &thisName, &thisValue);
                if(ns == HUBBUB_NS_HTML && 
                   nameLength == thisName.len && 
                   strncasecmp(attributeName, (const char *)thisName.ptr, nameLength) == 0 && thisValue.len) {
                    free((void *)thisName.ptr);
                    return thisValue;
                }
                free((void *)thisName.ptr);
                free((void *)thisValue.ptr);
            }
        }
    }
    
    hubbub_string ret = { NULL, 0 };
    return ret;
}

- (lwc_string *)copyLwcStringAttributeForName:(const char *)attributeName;
{
    hubbub_string attributeString = [self copyHubbubAttributeForName:attributeName];
    if(attributeString.len) {
        lwc_string *ret;
        lwc_context_intern(_lwcContext, (const char *)attributeString.ptr, attributeString.len, &ret);
        free((void *)attributeString.ptr);
        return ret;
    } else {
        return NULL;
    }
}

- (lwc_string **)classes
{
    if(!_classes) {
        hubbub_string classesString = [self copyHubbubAttributeForName:"class"];
        lwc_string **classes = malloc(sizeof(lwc_string *) * classesString.len);
        uint32_t classesCount = 0;
        if(classesString.len) {
            const uint8_t *start = classesString.ptr;
            const uint8_t *cursor = classesString.ptr;
            const uint8_t *end = classesString.ptr + classesString.len;
            
            while(start < end) {
                while(start != end && isspace(*start)) {
                    ++start;
                }
                cursor = start;
                while(cursor < end && !isspace(*cursor)) {
                    ++cursor;
                }
                if(cursor != start) {
                    lwc_context_intern(_lwcContext, (const char *)start, cursor - start, &classes[classesCount]);
                    ++classesCount;
                }
                start = cursor;
            }
            
            if(classesCount) {
                _classes = realloc(classes, sizeof(lwc_string *) * classesCount);
                _classesCount = classesCount;
            } else {
                free(classes);
            }  
            
            free((void *)classesString.ptr);
        }
    }
    return _classes;
}

- (uint32_t)classesCount
{
    if(!_classesCount) {
        [self classes];
    }
    return _classesCount;
}

css_error EucHTMLDBNodeClasses(void *pw, void *node, lwc_context *dict, lwc_string ***classesOut, uint32_t *nClassesOut)
{
    EucHTMLDBNodeManager *manager = (EucHTMLDBNodeManager *)pw;
    uint32_t key = (uint32_t)(intptr_t)node;
    
    EucHTMLDBNode *self = [manager nodeForKey:key];
    uint32_t classesCount = self.classesCount;
    if(self.classesCount) {
        // LibCSS expects a malloced array of reffed strings.
        size_t byteCount = classesCount * sizeof(lwc_string *);
        *classesOut = malloc(byteCount);
        memcpy(*classesOut, self.classes, byteCount);
        for(int i = 0; i < classesCount; ++i) {
            lwc_context_string_ref(dict, (*classesOut)[i]);
        }
        *nClassesOut = classesCount;
    } else {
        *classesOut = NULL;
        *nClassesOut = classesCount;
    }
    
    return CSS_OK;
}

css_error EucHTMLDBNodeID(void *pw, void *node, lwc_context *dict, lwc_string **id)
{
    EucHTMLDBNodeManager *manager = (EucHTMLDBNodeManager *)pw;
    uint32_t key = (uint32_t)(intptr_t)node;
        
    *id = [[manager nodeForKey:key] copyLwcStringAttributeForName:"id"];
    
    return CSS_OK;
}

- (EucHTMLDBNode *)_ancestorWithName:(lwc_string *)name chaining:(BOOL)chaining
{
    uint32_t parentKey = _rawNode[parentPosition];
    if(parentKey) {
        EucHTMLDBNode *parent = [_manager nodeForKey:parentKey];
        if(parent.kind == nodeKindElement) {
            bool equal;
            if(lwc_context_string_caseless_isequal(_lwcContext, name, parent.name, &equal) == lwc_error_ok && equal) {
                return parent;
            } else if(chaining) {
                return [self _ancestorWithName:name chaining:chaining];
            }
        }
    }
    return nil;
}

- (EucHTMLDBNode *)closestAncestorWithName:(lwc_string *)name
{
    return [self _ancestorWithName:name chaining:YES];
}

- (EucHTMLDBNode *)parentWithName:(lwc_string *)name
{
    return [self _ancestorWithName:name chaining:NO];
}

- (uint32_t *)childrenKeys
{
    if(!_childrenKeys && _rawNode[childrenPosition]) {        
        EucHTMLDBCopyUint32Array(_htmlDb, _rawNode[childrenPosition], &_childrenKeys, &_childrenKeysCount);
    }    
    return _childrenKeys;
}

- (uint32_t)childrenKeysCount
{
    if(!_childrenKeysCount && _rawNode[childrenPosition]) {        
        [self childrenKeys];
    }
    return _childrenKeysCount;
}

- (EucHTMLDBNode *)adjacentSiblingWithName:(lwc_string *)name
{
    uint32_t parentKey = _rawNode[parentPosition];
    if(parentKey) {
        EucHTMLDBNode *parent = [_manager nodeForKey:parentKey];
        uint32_t parentChildrenCount = parent.childrenKeysCount;
        if(parentChildrenCount > 1) {
            uint32_t *parentChildrenKeys = parent.childrenKeys;
            EucHTMLDBNode *siblingNode = nil;
            uint32_t myKey = self.key;
            for(uint32_t i = 1; i < parentChildrenCount; ++i) {
                if(parentChildrenKeys[i] == myKey) {
                    for(uint32_t j = i-1; j >= 0; --j) {
                        EucHTMLDBNode *siblingNode = [_manager nodeForKey:parentChildrenKeys[j]];
                        if(siblingNode.kind == nodeKindElement) {
                            break;
                        }
                    }
                }
            }
            if(siblingNode) {
                bool equal;
                if(!name || lwc_context_string_caseless_isequal(_lwcContext, name, siblingNode.name, &equal) == lwc_error_ok && equal) {
                    return siblingNode;
                }
            }
        }
    }
    return nil;    
    
}

- (EucHTMLDBNode *)parentNode
{
    uint32_t parentKey = _rawNode[parentPosition];
    if(parentKey) {
        return [_manager nodeForKey:parentKey];
    } 
    return nil;
}
    
- (EucHTMLDBNode *)_nodeAfter:(uint32_t)key under:(uint32_t)underKey 
{
    uint32_t childrenCount = self.childrenKeysCount;
    if(childrenCount > 1) {
        uint32_t *childrenKeys = self.childrenKeys;
        for(uint32_t i = 0; i < childrenCount - 1; ++i) {
            if(childrenKeys[i] == key) {
                return [_manager nodeForKey:childrenKeys[i+1]];
            }
        }                
    } 
    if(_key == underKey) {
        return nil;
    }
    return [self.parentNode _nodeAfter:self.key under:underKey];
}

- (EucHTMLDBNode *)nextNodeUnder:(EucHTMLDBNode *)node;
{
    uint32_t childrenCount = self.childrenKeysCount;
    if(childrenCount) {
        return [_manager nodeForKey:self.childrenKeys[0]];
    } else {
        return [self.parentNode _nodeAfter:self.key under:node.key];
    }
    return NULL;
}

- (EucHTMLDBNode *)nextNode
{
    return [self nextNodeUnder:nil];
}

- (EucHTMLDBNode *)nextNodeWithName:(lwc_string *)name
{
    EucHTMLDBNode *candidate = self;
    while((candidate = [candidate nextNode])) {
        lwc_string *candidateName = candidate.name;
        bool equal;
        if(candidateName && lwc_context_string_caseless_isequal(_lwcContext, name, candidateName, &equal) == lwc_error_ok && equal) {
            return candidate;
        }
    }
    return NULL;
}

- (EucHTMLDBNode *)firstChild
{
    uint32_t childrenCount = self.childrenKeysCount;
    if(childrenCount) {
        return [_manager nodeForKey:self.childrenKeys[0]];
    } else {
        return nil;
    }
}

- (BOOL)getCharacterContents:(char **)contents length:(size_t *)length
{
    if(!_characterContents) {
        if(_rawNode[kindPosition] == nodeKindText) {
            EucHTMLDBCopyUTF8(_htmlDb, _rawNode[textTextPosition],
                              (uint8_t **)&_characterContents, &_characterContentsLength);
        }        
    }
    *contents = _characterContents;
    *length = _characterContentsLength;
    return contents ? YES : NO;
}

css_error EucHTMLDBNamedAncestorNode(void *pw, void *node, lwc_string *name, void **ancestor)
{
    EucHTMLDBNodeManager *manager = (EucHTMLDBNodeManager *)pw;
    uint32_t key = (uint32_t)(intptr_t)node;
    
    *ancestor = (void *)(intptr_t)[[manager nodeForKey:key] closestAncestorWithName:name].key;
    
    return CSS_OK;
}    

css_error EucHTMLDBNamedParentNode(void *pw, void *node, lwc_string *name, void **parent)
{
    EucHTMLDBNodeManager *manager = (EucHTMLDBNodeManager *)pw;
    uint32_t key = (uint32_t)(intptr_t)node;
    
    *parent = (void *)(intptr_t)[[manager nodeForKey:key] parentWithName:name].key;
    
    return CSS_OK;    
}

css_error EucHTMLDBNamedSiblingNode(void *pw, void *node, lwc_string *name, void **sibling)
{
    EucHTMLDBNodeManager *manager = (EucHTMLDBNodeManager *)pw;
    uint32_t key = (uint32_t)(intptr_t)node;
    
    *sibling = (void *)(intptr_t)[[manager nodeForKey:key] adjacentSiblingWithName:name].key;
    
    return CSS_OK;    
}

css_error EucHTMLDBParentNode(void *pw, void *node, void **parent)
{
    EucHTMLDBNodeManager *manager = (EucHTMLDBNodeManager *)pw;
    uint32_t key = (uint32_t)(intptr_t)node;
    
    *parent = (void *)(intptr_t)[[manager nodeForKey:key] parentNode].key;
    
    return CSS_OK;    
}

css_error EucHTMLDBSiblingNode(void *pw, void *node, void **sibling)
{
    EucHTMLDBNodeManager *manager = (EucHTMLDBNodeManager *)pw;
    uint32_t key = (uint32_t)(intptr_t)node;
    
    *sibling = (void *)(intptr_t)[[manager nodeForKey:key] adjacentSiblingWithName:nil].key;
    
    return CSS_OK;    
}

css_error EucHTMLDBNodeHasName(void *pw, void *node, lwc_string *name, bool *match)
{
    EucHTMLDBNodeManager *manager = (EucHTMLDBNodeManager *)pw;
    uint32_t key = (uint32_t)(intptr_t)node;
    EucHTMLDBNode *self = [manager nodeForKey:key];
    
    lwc_context_string_caseless_isequal(self.lwcContext, self.name, name, match);
    
    return CSS_OK;        
}

css_error EucHTMLDBNodeHasClass(void *pw, void *node, lwc_string *name, bool *match)
{
    EucHTMLDBNodeManager *manager = (EucHTMLDBNodeManager *)pw;
    uint32_t key = (uint32_t)(intptr_t)node;
    EucHTMLDBNode *self = [manager nodeForKey:key];
    
    bool ret = false;
    
    uint32_t classesCount = self.classesCount;
    if(classesCount) {
        lwc_context *lwcContext = self.lwcContext;
        lwc_string **classes = self.classes;
        for(int i = 0; i < classesCount; ++i) {
            lwc_context_string_caseless_isequal(lwcContext, name, classes[i], &ret);
            if(ret) {
                break;
            }
        }
    }
  
    *match = ret;
    
    return CSS_OK;
}

css_error EucHTMLDBNodeHasID(void *pw, void *node, lwc_string *name, bool *match)
{
    EucHTMLDBNodeManager *manager = (EucHTMLDBNodeManager *)pw;
    uint32_t key = (uint32_t)(intptr_t)node;
    EucHTMLDBNode *self = [manager nodeForKey:key];
    
    lwc_string *attributeValue = [self copyLwcStringAttributeForName:"id"];
    if(attributeValue) {
        lwc_context *context = self.lwcContext;
        lwc_context_string_caseless_isequal(context, attributeValue, name, match);
        lwc_context_string_unref(context, attributeValue);
    } else {
        *match = false;
    }
    
    return CSS_OK;        
}

css_error EucHTMLDBNodeHasAttribute(void *pw, void *node, lwc_string *name, bool *match)
{
    EucHTMLDBNodeManager *manager = (EucHTMLDBNodeManager *)pw;
    uint32_t key = (uint32_t)(intptr_t)node;
    EucHTMLDBNode *self = [manager nodeForKey:key];
    
    lwc_string *attributeValue = [self copyLwcStringAttributeForName:lwc_string_data(name)];
    if(attributeValue) {
        lwc_context_string_unref(self.lwcContext, attributeValue);
        *match = true;
    } else {
        *match = false;
    }
    
    return CSS_OK;            
}

css_error EucHTMLDBNodeHasAttributeEqual(void *pw, void *node, lwc_string *name, lwc_string *value, bool *match) 
{
    EucHTMLDBNodeManager *manager = (EucHTMLDBNodeManager *)pw;
    uint32_t key = (uint32_t)(intptr_t)node;
    EucHTMLDBNode *self = [manager nodeForKey:key];
    
    lwc_string *attributeValue = [self copyLwcStringAttributeForName:lwc_string_data(name)];
    if(attributeValue) {
        lwc_context_string_caseless_isequal(self.lwcContext, attributeValue, value, match);
        lwc_context_string_unref(self.lwcContext, attributeValue);
    } else {
        *match = false;
    }
    
    return CSS_OK;        
}

css_error EucHTMLDBNodeHasAttributeDashmatch(void *pw, void *node, lwc_string *name, lwc_string *value, bool *match)
{
    EucHTMLDBNodeManager *manager = (EucHTMLDBNodeManager *)pw;
    uint32_t key = (uint32_t)(intptr_t)node;
    EucHTMLDBNode *self = [manager nodeForKey:key];
    
    lwc_string *attributeValue = [self copyLwcStringAttributeForName:lwc_string_data(name)];
    if(attributeValue) {
        lwc_context *context = self.lwcContext;
        lwc_context_string_caseless_isequal(context, attributeValue, name, match);
        if(!*match) {
            size_t wantedLength = lwc_string_length(value);
            size_t attributeLength = lwc_string_length(attributeValue);
            if(attributeLength >= wantedLength + 1) { 
                const char *attributeString = lwc_string_data(attributeValue);
                if(attributeString[wantedLength] == '-') {
                    *match == strncasecmp(lwc_string_data(value),
                                          attributeString,
                                          wantedLength);
                }
            }
        }
        lwc_context_string_unref(context, attributeValue);
    } else {
        *match = false;
    }
    
    return CSS_OK;        
}

css_error EucHTMLDBNodeHasAttributeIncludes(void *pw, void *node, lwc_string *name, lwc_string *value, bool *match)
{
    EucHTMLDBNodeManager *manager = (EucHTMLDBNodeManager *)pw;
    uint32_t key = (uint32_t)(intptr_t)node;
    EucHTMLDBNode *self = [manager nodeForKey:key];
    
    lwc_string *attributeValue = [self copyLwcStringAttributeForName:lwc_string_data(name)];
    if(attributeValue) {
        lwc_context *context = self.lwcContext;
        size_t wantedLength = lwc_string_length(value);
        size_t attributeLength = lwc_string_length(attributeValue);
        if(wantedLength == attributeLength) {
            lwc_context_string_caseless_isequal(context, attributeValue, name, match);
        } else {
            const char *wantedString = lwc_string_data(value);
            const char *attributeString = lwc_string_data(attributeValue);
            
            const char *start = attributeString;
            const char *cursor = attributeString;
            const char *end = start + attributeLength;
            
            while(start < end) {
                while(start < end && isspace(*start)) {
                    ++start;
                }
                cursor = start;
                while(cursor < end && !isspace(*cursor)) {
                    ++cursor;
                }
                if(cursor - start == wantedLength) {
                    if(strncasecmp(start, wantedString, wantedLength) == 0) {
                        *match = true;
                        break;
                    }
                }
                start = cursor;
            }
        }
        lwc_context_string_unref(context, attributeValue);
    } else {
        *match = false;
    }
    
    return CSS_OK;        
}


css_error EucHTMLDBNodeIsFirstChild(void *pw, void *node, bool *match)
{

    EucHTMLDBNodeManager *manager = (EucHTMLDBNodeManager *)pw;
    uint32_t key = (uint32_t)(intptr_t)node;
    EucHTMLDBNode *self = [manager nodeForKey:key];
     
    EucHTMLDBNode *parent = self.parentNode;
    *match = (parent && parent.childrenKeysCount && parent.childrenKeys[0] == self.key);
    return CSS_OK;
}

css_error EucHTMLDBNodeIsLink(void *pw, void *node, bool *match)
{
    EucHTMLDBNodeManager *manager = (EucHTMLDBNodeManager *)pw;
    uint32_t key = (uint32_t)(intptr_t)node;
    EucHTMLDBNode *self = [manager nodeForKey:key];

    lwc_string *aString;
    lwc_context_intern(self->_lwcContext, "a", 1, &aString);
    
    css_error ret = EucHTMLDBNodeHasName(pw, node, aString, match);
    if(ret == CSS_OK && *match) {
        lwc_string *hrefString;
        lwc_context_intern(self->_lwcContext, "href", 4, &hrefString);
        ret = EucHTMLDBNodeHasAttribute(pw, node, hrefString, match);
        if(ret != CSS_OK) {
            *match = false;
        }
        lwc_context_string_unref(self->_lwcContext, hrefString);
    }
    lwc_context_string_unref(self->_lwcContext, aString);

    return ret;
}

css_error EucHTMLDBNodeIsVisited(void *pw, void *node, bool *match)
{
    *match = false;
    return CSS_OK;
}

css_error EucHTMLDBNodeIsHover(void *pw, void *node, bool *match)
{
    *match = false;
    return CSS_OK;
}

css_error EucHTMLDBNodeIsActive(void *pw, void *node, bool *match)
{
    *match = false;
    return CSS_OK; 
}

css_error EucHTMLDBNodeIsFocus(void *pw, void *node, bool *match)
{
    *match = false;
    return CSS_OK;  
}

css_error EucHTMLDBNodeIsLang(void *pw, void *node,
                              lwc_string *lang, bool *match)
{
    *match = false;
    return CSS_OK;
}

css_error EucHTMLDBNodePresentationalHint(void *pw, void *node,
                                          uint32_t property, css_hint *hint)
{
	return CSS_PROPERTY_NOT_SET;
}

css_error EucHTMLDBUADefaultForProperty(void *pw, uint32_t property, css_hint *hint)
{
	if (property == CSS_PROP_COLOR) {
		hint->data.color = 0x00000000;
		hint->status = CSS_COLOR_COLOR;
	} else if (property == CSS_PROP_FONT_FAMILY) {
		hint->data.strings = NULL;
		hint->status = CSS_FONT_FAMILY_SERIF;
	} else if (property == CSS_PROP_QUOTES) {
		hint->data.strings = NULL;
		hint->status = CSS_QUOTES_NONE;
	} else if (property == CSS_PROP_VOICE_FAMILY) {
		hint->data.strings = NULL;
		hint->status = 0;
	} else {
		return CSS_INVALID;
	}
    
	return CSS_OK;
}

css_error EucHTMLDBComputeFontSize(void *pw, const css_hint *parent, css_hint *size)
{
	static css_hint_length sizes[] = {
		{ FLTTOFIX(6.75), CSS_UNIT_PT },
		{ FLTTOFIX(7.50), CSS_UNIT_PT },
		{ FLTTOFIX(9.75), CSS_UNIT_PT },
		{ FLTTOFIX(12.0), CSS_UNIT_PT },
		{ FLTTOFIX(13.5), CSS_UNIT_PT },
		{ FLTTOFIX(18.0), CSS_UNIT_PT },
		{ FLTTOFIX(24.0), CSS_UNIT_PT }
	};
	const css_hint_length *parent_size;
        
	/* Grab parent size, defaulting to medium if none */
	if (parent == NULL) {
		parent_size = &sizes[CSS_FONT_SIZE_MEDIUM - 1];
	} else {
		assert(parent->status == CSS_FONT_SIZE_DIMENSION);
		assert(parent->data.length.unit != CSS_UNIT_EM);
		assert(parent->data.length.unit != CSS_UNIT_EX);
		parent_size = &parent->data.length;
	}
    
	assert(size->status != CSS_FONT_SIZE_INHERIT);
    
	if (size->status < CSS_FONT_SIZE_LARGER) {
		/* Keyword -- simple */
		size->data.length = sizes[size->status - 1];
	} else if (size->status == CSS_FONT_SIZE_LARGER) {
		/** \todo Step within table, if appropriate */
		size->data.length.value = 
        FMUL(parent_size->value, FLTTOFIX(1.2));
		size->data.length.unit = parent_size->unit;
	} else if (size->status == CSS_FONT_SIZE_SMALLER) {
		/** \todo Step within table, if appropriate */
		size->data.length.value = 
        FMUL(parent_size->value, FLTTOFIX(1.2));
		size->data.length.unit = parent_size->unit;
	} else if (size->data.length.unit == CSS_UNIT_EM ||
               size->data.length.unit == CSS_UNIT_EX) {
		size->data.length.value = 
        FMUL(size->data.length.value, parent_size->value);
        
		if (size->data.length.unit == CSS_UNIT_EX) {
			size->data.length.value = FMUL(size->data.length.value,
                                           FLTTOFIX(0.6));
		}
        
		size->data.length.unit = parent_size->unit;
	} else if (size->data.length.unit == CSS_UNIT_PCT) {
		size->data.length.value = FDIV(FMUL(size->data.length.value,
                                            parent_size->value), FLTTOFIX(100));
		size->data.length.unit = parent_size->unit;
	}
    
	size->status = CSS_FONT_SIZE_DIMENSION;
    
	return CSS_OK;
}

+ (css_select_handler *)selectHandler
{
    static css_select_handler select_handler = {
        EucHTMLDBNodeName,
        EucHTMLDBNodeClasses,
        EucHTMLDBNodeID,
        EucHTMLDBNamedAncestorNode,
        EucHTMLDBNamedParentNode,
        EucHTMLDBNamedSiblingNode,
        EucHTMLDBParentNode,
        EucHTMLDBSiblingNode,
        EucHTMLDBNodeHasName,
        EucHTMLDBNodeHasClass,
        EucHTMLDBNodeHasID,
        EucHTMLDBNodeHasAttribute,
        EucHTMLDBNodeHasAttributeEqual,
        EucHTMLDBNodeHasAttributeDashmatch,
        EucHTMLDBNodeHasAttributeIncludes,
        EucHTMLDBNodeIsFirstChild,
        EucHTMLDBNodeIsLink,
        EucHTMLDBNodeIsVisited,
        EucHTMLDBNodeIsHover,
        EucHTMLDBNodeIsActive,
        EucHTMLDBNodeIsFocus,
        EucHTMLDBNodeIsLang,
        EucHTMLDBNodePresentationalHint,
        EucHTMLDBUADefaultForProperty,
        EucHTMLDBComputeFontSize
    };
    return &select_handler;
}

@end