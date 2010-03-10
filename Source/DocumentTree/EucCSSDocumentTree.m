/*
 *  EucCSSDocumentTree.m
 *  LibCSSTest
 *
 *  Created by James Montgomerie on 09/03/2010.
 *  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
 *
 */

#import "EucCSSDocumentTree.h"

#import <libwapcaplet/libwapcaplet.h>
#import "LWCNSStringAdditions.h"

static bool _StringContainsElement(const char *string, size_t stringLength, const char *element, size_t elementLength);

static css_error EucCSSDocumentTreeNodeName(void *pw, void *node, lwc_context *dict, lwc_string **nameOut)
{
    id<EucCSSDocumentTree> tree = (id<EucCSSDocumentTree>)pw;
    uint32_t key = (uint32_t)((intptr_t)node);
    
    NSString *name = [tree nodeForKey:key].name;
    if(name) {
        const char *utf8Name = [name UTF8String];
        lwc_context_intern(dict, utf8Name, strlen(utf8Name), nameOut);
        return CSS_OK;
    }
    return CSS_INVALID;    
}

static css_error EucCSSDocumentTreeNodeClasses(void *pw, void *node, lwc_context *dict, lwc_string ***classesOut, uint32_t *nClassesOut)
{
    id<EucCSSDocumentTree> tree = (id<EucCSSDocumentTree>)pw;
    uint32_t key = (uint32_t)((intptr_t)node);
    
    NSString *classes = [[tree nodeForKey:key] attributeWithName:@"class"];
    
    if(classes) {
        const char *classesString = [classes UTF8String];
        size_t classesStringLength = strlen(classesString);

        if(classesStringLength) {
            uint32_t nClasses = 0;
            lwc_string **classes = malloc(sizeof(lwc_string *) * classesStringLength); // Overkill, but it'll be long enough at least.

            const char *start = classesString;
            const char *end = classesString + classesStringLength;
            
            while(start < end) {
                while(start != end && isspace(*start)) {
                    ++start;
                }
                const char *cursor = start;
                while(cursor < end && !isspace(*cursor)) {
                    ++cursor;
                }
                if(cursor != start) {
                    lwc_context_intern(dict, (const char *)start, cursor - start, &classes[nClasses]);
                    ++nClasses;
                }
                start = cursor;
            }
            
            if(nClasses) {
                classes = realloc(classes, sizeof(lwc_string *) * nClasses);
                
                *classesOut = classes;
                *nClassesOut = nClasses;
            } else {
                free(classes);
                
                *classesOut = NULL;
                *nClassesOut = 0;
            }  
        }
    }        

    return CSS_OK;
}

static css_error EucCSSDocumentTreeNodeID(void *pw, void *node, lwc_context *dict, lwc_string **idOut)
{
    id<EucCSSDocumentTree> tree = (id<EucCSSDocumentTree>)pw;
    uint32_t key = (uint32_t)((intptr_t)node);
    
    NSString *idAttribute = [[tree nodeForKey:key] attributeWithName:@"id"];
    if(idAttribute) {
        *idOut = [idAttribute lwcStringInContext:dict];
        return CSS_OK;
    }
    return CSS_INVALID;    
}

static css_error EucCSSDocumentTreeNamedAncestorNode(void *pw, void *node, lwc_string *name, void **ancestor)
{
    id<EucCSSDocumentTree> tree = (id<EucCSSDocumentTree>)pw;
    uint32_t key = (uint32_t)((intptr_t)node);
    
    NSString *nsName = [NSString stringWithLWCString:name];
    id<EucCSSDocumentTreeNode> treeNode = [tree nodeForKey:key];
    do {
        treeNode = treeNode.parent;
    } while(treeNode && !([treeNode.name caseInsensitiveCompare:nsName] == NSOrderedSame));
    
    if(treeNode) {
        *ancestor = (void *)((intptr_t)treeNode.key);
    } else {
        *ancestor = NULL;
    }
    
    return CSS_OK;
}    

static css_error EucCSSDocumentTreeNamedParentNode(void *pw, void *node, lwc_string *name, void **parent)
{
    id<EucCSSDocumentTree> tree = (id<EucCSSDocumentTree>)pw;
    uint32_t key = (uint32_t)((intptr_t)node);
    
    id<EucCSSDocumentTreeNode> parentNode = [tree nodeForKey:key].parent;
        
    if(parentNode && ([parentNode.name caseInsensitiveCompare:[NSString stringWithLWCString:name]] == NSOrderedSame)) {
        *parent = (void *)((intptr_t)parentNode.key);
    } else {
        *parent = NULL;
    }
    
    return CSS_OK;
}

static css_error EucCSSDocumentTreeNamedSiblingNode(void *pw, void *node, lwc_string *name, void **sibling)
{
    id<EucCSSDocumentTree> tree = (id<EucCSSDocumentTree>)pw;
    uint32_t key = (uint32_t)((intptr_t)node);
    
    id<EucCSSDocumentTreeNode> previousSiblingNode = [tree nodeForKey:key].previousSibling;

    if(previousSiblingNode && ([previousSiblingNode.name caseInsensitiveCompare:[NSString stringWithLWCString:name]] == NSOrderedSame)) {
        *sibling = (void *)((intptr_t)previousSiblingNode.key);
    } else {
        *sibling = NULL;
    }
    
    return CSS_OK;    
}

static css_error EucCSSDocumentTreeParentNode(void *pw, void *node, void **parent)
{
    id<EucCSSDocumentTree> tree = (id<EucCSSDocumentTree>)pw;
    uint32_t key = (uint32_t)((intptr_t)node);
    
    *parent = (void *)(intptr_t)([tree nodeForKey:key].parent.key);
    
    return CSS_OK;    
}

static css_error EucCSSDocumentTreeSiblingNode(void *pw, void *node, void **sibling)
{
    id<EucCSSDocumentTree> tree = (id<EucCSSDocumentTree>)pw;
    uint32_t key = (uint32_t)((intptr_t)node);
    
    *sibling = (void *)(intptr_t)([tree nodeForKey:key].previousSibling.key);
    
    return CSS_OK;    
}

static css_error EucCSSDocumentTreeNodeHasName(void *pw, void *node, lwc_string *name, bool *match)
{
    id<EucCSSDocumentTree> tree = (id<EucCSSDocumentTree>)pw;
    uint32_t key = (uint32_t)((intptr_t)node);
    id<EucCSSDocumentTreeNode> treeNode = [tree nodeForKey:key];

    *match = ([treeNode.name caseInsensitiveCompare:[NSString stringWithLWCString:name]] == NSOrderedSame);
    
    return CSS_OK;        
}

static css_error EucCSSDocumentTreeNodeHasClass(void *pw, void *node, lwc_string *name, bool *match)
{
    id<EucCSSDocumentTree> tree = (id<EucCSSDocumentTree>)pw;
    uint32_t key = (uint32_t)((intptr_t)node);
    id<EucCSSDocumentTreeNode> treeNode = [tree nodeForKey:key];
    
    NSString *attributeValue = [treeNode attributeWithName:@"class"];
    if(attributeValue) {        
        const char *utf8AttibuteValue = [attributeValue UTF8String];        
        *match = _StringContainsElement(utf8AttibuteValue, strlen(utf8AttibuteValue),
                                        lwc_string_data(name), lwc_string_length(name));
    } else {
        *match = false;
    }
    
    return CSS_OK;        
}

static css_error EucCSSDocumentTreeNodeHasID(void *pw, void *node, lwc_string *name, bool *match)
{
    id<EucCSSDocumentTree> tree = (id<EucCSSDocumentTree>)pw;
    uint32_t key = (uint32_t)((intptr_t)node);
    id<EucCSSDocumentTreeNode> treeNode = [tree nodeForKey:key];
    
    *match = ([[treeNode attributeWithName:@"id"] caseInsensitiveCompare:[NSString stringWithLWCString:name]] == NSOrderedSame);
    
    return CSS_OK;        
}

static css_error EucCSSDocumentTreeNodeHasAttribute(void *pw, void *node, lwc_string *name, bool *match)
{
    id<EucCSSDocumentTree> tree = (id<EucCSSDocumentTree>)pw;
    uint32_t key = (uint32_t)((intptr_t)node);
    id<EucCSSDocumentTreeNode> treeNode = [tree nodeForKey:key];
    
    *match = [treeNode attributeWithName:[NSString stringWithLWCString:name]] != nil;
    
    return CSS_OK;        
}

static css_error EucCSSDocumentTreeNodeHasAttributeEqual(void *pw, void *node, lwc_string *name, lwc_string *value, bool *match) 
{
    id<EucCSSDocumentTree> tree = (id<EucCSSDocumentTree>)pw;
    uint32_t key = (uint32_t)((intptr_t)node);
    id<EucCSSDocumentTreeNode> treeNode = [tree nodeForKey:key];
    
    NSString *nsAttributeValue = [treeNode attributeWithName:[NSString stringWithLWCString:name]];
    *match = nsAttributeValue != nil && ([nsAttributeValue caseInsensitiveCompare:[NSString stringWithLWCString:value]] == NSOrderedSame);
    
    return CSS_OK;        
}

static css_error EucCSSDocumentTreeNodeHasAttributeDashmatch(void *pw, void *node, lwc_string *name, lwc_string *value, bool *match)
{
    id<EucCSSDocumentTree> tree = (id<EucCSSDocumentTree>)pw;
    uint32_t key = (uint32_t)((intptr_t)node);
    id<EucCSSDocumentTreeNode> treeNode = [tree nodeForKey:key];
    
    NSString *attributeValue = [treeNode attributeWithName:[NSString stringWithLWCString:name]];
    if(attributeValue) {
        NSString *valueToMatch = [NSString stringWithLWCString:value];
        if([attributeValue hasPrefix:valueToMatch]) {
            NSUInteger valueToMatchLength = valueToMatch.length;
            if(attributeValue.length > valueToMatch.length) {
                *match = [attributeValue characterAtIndex:valueToMatchLength] == '-';
            } else {
                *match = true;
            }
        }
    } else {
        *match = false;
    }
    
    return CSS_OK;        
}

static css_error EucCSSDocumentTreeNodeHasAttributeIncludes(void *pw, void *node, lwc_string *name, lwc_string *value, bool *match)
{
    id<EucCSSDocumentTree> tree = (id<EucCSSDocumentTree>)pw;
    uint32_t key = (uint32_t)((intptr_t)node);
    id<EucCSSDocumentTreeNode> treeNode = [tree nodeForKey:key];
    
    NSString *attributeValue = [treeNode attributeWithName:[NSString stringWithLWCString:name]];
    if(attributeValue) {        
        const char *utf8AttibuteValue = [attributeValue UTF8String];        
        *match = _StringContainsElement(utf8AttibuteValue, strlen(utf8AttibuteValue),
                                        lwc_string_data(value), lwc_string_length(value));
    } else {
        *match = false;
    }
    
    return CSS_OK;        
}


static css_error EucCSSDocumentTreeNodeIsFirstChild(void *pw, void *node, bool *match)
{
    
    id<EucCSSDocumentTree> tree = (id<EucCSSDocumentTree>)pw;
    uint32_t key = (uint32_t)((intptr_t)node);

    *match = ([tree nodeForKey:key].parent.firstChild.key == key);
    return CSS_OK;
}

static css_error EucCSSDocumentTreeNodeIsLink(void *pw, void *node, bool *match)
{
    id<EucCSSDocumentTree> tree = (id<EucCSSDocumentTree>)pw;
    uint32_t key = (uint32_t)((intptr_t)node);
    id<EucCSSDocumentTreeNode> treeNode = [tree nodeForKey:key];
    
    *match = ([treeNode.name caseInsensitiveCompare:@"a"] == NSOrderedSame) && 
             [treeNode attributeWithName:@"href"] != nil;
        
    return CSS_OK;
}

static css_error EucCSSDocumentTreeNodeIsVisited(void *pw, void *node, bool *match)
{
    *match = false;
    return CSS_OK;
}

static css_error EucCSSDocumentTreeNodeIsHover(void *pw, void *node, bool *match)
{
    *match = false;
    return CSS_OK;
}

static css_error EucCSSDocumentTreeNodeIsActive(void *pw, void *node, bool *match)
{
    *match = false;
    return CSS_OK; 
}

static css_error EucCSSDocumentTreeNodeIsFocus(void *pw, void *node, bool *match)
{
    *match = false;
    return CSS_OK;  
}

static css_error EucCSSDocumentTreeNodeIsLang(void *pw, void *node, lwc_string *lang, bool *match)
{
    *match = false;
    return CSS_OK;
}

static css_error EucCSSDocumentTreeNodePresentationalHint(void *pw, void *node, uint32_t property, css_hint *hint)
{
	return CSS_PROPERTY_NOT_SET;
}

static css_error EucCSSDocumentTreeUADefaultForProperty(void *pw, uint32_t propertyIn, css_hint *hint)
{
    enum css_properties_e property = (enum css_properties_e)propertyIn;
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

static css_error EucCSSDocumentTreeComputeFontSize(void *pw, const css_hint *parent, css_hint *size)
{
	static css_hint_length sizes[] = {
		{ FLTTOFIX(18.0f / 1.2f / 1.2f / 1.2f), CSS_UNIT_PT },
		{ FLTTOFIX(18.0f / 1.2f / 1.2f), CSS_UNIT_PT },
		{ FLTTOFIX(18.0f / 1.2f), CSS_UNIT_PT },
		{ FLTTOFIX(18.0f), CSS_UNIT_PT },
		{ FLTTOFIX(18.0f * 1.2f), CSS_UNIT_PT },
		{ FLTTOFIX(18.0f * 1.2f * 1.2f), CSS_UNIT_PT },
		{ FLTTOFIX(18.0f * 1.2f * 1.2f * 1.2f), CSS_UNIT_PT }
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
    
    assert(size->data.length.unit == CSS_UNIT_PT || size->data.length.unit == CSS_UNIT_PX);
    
	return CSS_OK;
}

static bool _StringContainsElement(const char *string, size_t stringLength, const char *element, size_t elementLength)
{
    if(stringLength == elementLength) {
        return (strcasecmp(string, element) == 0);
    } else {        
        const char *start = string;
        const char *end = start + stringLength;
        
        while(start < end) {
            while(start < end && isspace(*start)) {
                ++start;
            }
            const char *cursor = start;
            while(cursor < end && !isspace(*cursor)) {
                ++cursor;
            }
            if(cursor - start == elementLength) {
                if(strncasecmp(start, element, elementLength) == 0) {
                    return true;
                }
            }
            start = cursor;
        }
    }
    return false;
}
                                        
css_select_handler EucCSSDocumentTreeSelectHandler = {
    EucCSSDocumentTreeNodeName,
    EucCSSDocumentTreeNodeClasses,
    EucCSSDocumentTreeNodeID,
    EucCSSDocumentTreeNamedAncestorNode,
    EucCSSDocumentTreeNamedParentNode,
    EucCSSDocumentTreeNamedSiblingNode,
    EucCSSDocumentTreeParentNode,
    EucCSSDocumentTreeSiblingNode,
    EucCSSDocumentTreeNodeHasName,
    EucCSSDocumentTreeNodeHasClass,
    EucCSSDocumentTreeNodeHasID,
    EucCSSDocumentTreeNodeHasAttribute,
    EucCSSDocumentTreeNodeHasAttributeEqual,
    EucCSSDocumentTreeNodeHasAttributeDashmatch,
    EucCSSDocumentTreeNodeHasAttributeIncludes,
    EucCSSDocumentTreeNodeIsFirstChild,
    EucCSSDocumentTreeNodeIsLink,
    EucCSSDocumentTreeNodeIsVisited,
    EucCSSDocumentTreeNodeIsHover,
    EucCSSDocumentTreeNodeIsActive,
    EucCSSDocumentTreeNodeIsFocus,
    EucCSSDocumentTreeNodeIsLang,
    EucCSSDocumentTreeNodePresentationalHint,
    EucCSSDocumentTreeUADefaultForProperty,
    EucCSSDocumentTreeComputeFontSize
};
