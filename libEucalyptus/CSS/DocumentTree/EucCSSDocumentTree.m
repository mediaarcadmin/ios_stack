/*
 *  EucCSSDocumentTree.m
 *  LibCSSTest
 *
 *  Created by James Montgomerie on 09/03/2010.
 *  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
 *
 */

#import "EucCSSDocumentTree.h"
#import "EucCSSDocumentTree_Package.h"
#import "EucConfiguration.h"

#import <libwapcaplet/libwapcaplet.h>
#import <pthread.h>
#import "LWCNSStringAdditions.h"

//
// In this file, string comparisons are done by trying == before calling
// the comparison function to take advantage of the fact that, in the 
// default implementation, node names, attributes etc. are interned in 
// libwapcaplet, so identical strings will have identical pointers.
// 

static bool _LWCStringContainsElement(lwc_string *string, lwc_string *element);

static css_error EucCSSDocumentTreeNodeName(void *pw, void *nodeIn, lwc_string **nameOut)
{
    id<EucCSSDocumentTreeNode> node = nodeIn;
    
    NSString *name = node.name;
    if(name) {
        *nameOut = lwc_intern_ns_string(name);
        return CSS_OK;
    }
    return CSS_INVALID;    
}

static css_error EucCSSDocumentTreeNodeClasses(void *pw, void *nodeIn, lwc_string ***classesOut, uint32_t *nClassesOut)
{
    id<EucCSSDocumentTreeNode> node = nodeIn;
    
    NSString *nsClasses = [node CSSClasses];
    
    if(nsClasses) {
        CFIndex classesStringLength = CFStringGetLength((CFStringRef)nsClasses);
        CFIndex bufferSize = CFStringGetMaximumSizeForEncoding(classesStringLength, kCFStringEncodingUTF8);
        char *classesString = malloc(bufferSize);
        CFStringGetBytes((CFStringRef)nsClasses, CFRangeMake(0, classesStringLength), kCFStringEncodingUTF8, '_', false, (UInt8 *)classesString, bufferSize, &classesStringLength);

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
                    lwc_intern_string((const char *)start, cursor - start, &classes[nClasses]);
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
        
        free(classesString);
    }        

    return CSS_OK;
}

static css_error EucCSSDocumentTreeNodeID(void *pw, void *nodeIn, lwc_string **idOut)
{
    id<EucCSSDocumentTreeNode> node = nodeIn;
    
    NSString *idAttribute = [node CSSID];
    if(idAttribute) {
        *idOut = lwc_intern_ns_string(idAttribute);
    } else {
        *idOut = nil;
    }
    return CSS_OK;    
}

static css_error EucCSSDocumentTreeNamedAncestorNode(void *pw, void *nodeIn, lwc_string *name, void **ancestor)
{
    id<EucCSSDocumentTreeNode> node = nodeIn;
    
    NSString *nsName = NSStringFromLWCString(name);    
    NSString *treeNodeName;
    do {
        node = node.parent;
        treeNodeName = node.name;
    } while(node && (!treeNodeName || !(treeNodeName == nsName || [treeNodeName caseInsensitiveCompare:nsName] == NSOrderedSame)));
        
    if(node) {
        *ancestor = node;
    } else {
        *ancestor = NULL;
    }
    
    return CSS_OK;
}    

static css_error EucCSSDocumentTreeParentNode(void *pw, void *nodeIn, void **parent)
{
    id<EucCSSDocumentTreeNode> node = nodeIn;
    
    *parent = node.parent;
    
    return CSS_OK;    
}

static css_error EucCSSDocumentTreeNamedParentNode(void *pw, void *nodeIn, lwc_string *name, void **parent)
{
    id<EucCSSDocumentTreeNode> node = nodeIn;
    
    id<EucCSSDocumentTreeNode> parentNode = node.parent;
    if(parentNode) {
        NSString *nsName = NSStringFromLWCString(name);
        NSString *parentNodeName = parentNode.name;
    
        if(nsName == parentNodeName || ([nsName caseInsensitiveCompare:parentNode.name] == NSOrderedSame)) {
            *parent = parentNode;
        } else {
            *parent = NULL;
        }
    } else {
        *parent = NULL;   
    }
        
    return CSS_OK;
}

static css_error EucCSSDocumentTreeSiblingNode(void *pw, void *nodeIn, void **sibling)
{
    id<EucCSSDocumentTreeNode> node = nodeIn;
    
    do {
        node = node.previousSibling;
    } while(node && node.kind != EucCSSDocumentTreeNodeKindElement);
    
    if(node) {
        *sibling = node;
    } else {
        *sibling = NULL;
    }
    return CSS_OK;    
}

static css_error EucCSSDocumentTreeNamedSiblingNode(void *pw, void *nodeIn, lwc_string *name, void **sibling)
{
    EucCSSDocumentTreeSiblingNode(pw, nodeIn, sibling);
    
    if(sibling) {
        id<EucCSSDocumentTreeNode> previousSiblingNode = *((id<EucCSSDocumentTreeNode> *)sibling);
        
        NSString *nsName = NSStringFromLWCString(name);
        NSString *siblingName = previousSiblingNode.name;
        
        if(!(nsName == siblingName || [nsName caseInsensitiveCompare:previousSiblingNode.name] == NSOrderedSame)) {
            *sibling = NULL;
        }
    }
    
    return CSS_OK;    
}

static css_error EucCSSDocumentTreeNodeHasName(void *pw, void *nodeIn, lwc_string *name, bool *match)
{
    id<EucCSSDocumentTreeNode> node = nodeIn;

    NSString *nodeName = node.name;
    NSString *nsName = NSStringFromLWCString(name);
    *match = (nodeName != nil && (nodeName == nsName || [nodeName caseInsensitiveCompare:nsName] == NSOrderedSame));
    
    return CSS_OK;        
}

static css_error EucCSSDocumentTreeNodeHasClass(void *pw, void *nodeIn, lwc_string *name, bool *match)
{
    id<EucCSSDocumentTreeNode> node = nodeIn;
    
    NSString *attributeValue = [node CSSClasses];
    if(attributeValue) {    
        lwc_string *lwcAttributeValue = lwc_intern_ns_string(attributeValue);
        *match = _LWCStringContainsElement(lwcAttributeValue, name);
        lwc_string_unref(lwcAttributeValue);
    } else {
        *match = false;
    }
    
    return CSS_OK;        
}

static css_error EucCSSDocumentTreeNodeHasID(void *pw, void *nodeIn, lwc_string *name, bool *match)
{
    id<EucCSSDocumentTreeNode> node = nodeIn;
    
    NSString *nsName = NSStringFromLWCString(name);
    NSString *identifier = [node CSSID];
    *match = (identifier && (identifier == nsName || [identifier caseInsensitiveCompare:nsName] == NSOrderedSame));
    
    return CSS_OK;        
}

static css_error EucCSSDocumentTreeNodeHasAttribute(void *pw, void *nodeIn, lwc_string *name, bool *match)
{
    id<EucCSSDocumentTreeNode> node = nodeIn;
    
    NSString *nsName = NSStringFromLWCString(name);
    *match = [node attributeWithName:nsName] != nil;
    
    return CSS_OK;        
}

static css_error EucCSSDocumentTreeNodeHasAttributeEqual(void *pw, void *nodeIn, lwc_string *name, lwc_string *value, bool *match) 
{
    id<EucCSSDocumentTreeNode> node = nodeIn;
        
    NSString *nsName = NSStringFromLWCString(name);
    NSString *nsAttributeValue = [node attributeWithName:nsName];
    if(nsAttributeValue) {
        NSString *nsValue = NSStringFromLWCString(value);
        *match = (nsAttributeValue == nsValue || [nsAttributeValue caseInsensitiveCompare:nsValue] == NSOrderedSame);
    } else {
        *match = false;
    }
    
    return CSS_OK;        
}

static css_error EucCSSDocumentTreeNodeHasAttributeDashmatch(void *pw, void *nodeIn, lwc_string *name, lwc_string *value, bool *match)
{
    id<EucCSSDocumentTreeNode> node = nodeIn;
    
    NSString *nsName = NSStringFromLWCString(name);
    NSString *attributeValue = [node attributeWithName:nsName];
    if(attributeValue) {
        NSString *valueToMatch = NSStringFromLWCString(value);
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

static css_error EucCSSDocumentTreeNodeHasAttributeIncludes(void *pw, void *nodeIn, lwc_string *name, lwc_string *value, bool *match)
{
    id<EucCSSDocumentTreeNode> node = nodeIn;
    
    NSString *nsName = NSStringFromLWCString(name);
    NSString *attributeValue = [node attributeWithName:nsName];
    if(attributeValue) {    
        lwc_string *lwcAttributeValue = lwc_intern_ns_string(attributeValue);
        *match = _LWCStringContainsElement(lwcAttributeValue, value);
        lwc_string_unref(lwcAttributeValue);
    } else {
        *match = false;
    }
    
    return CSS_OK;        
}

static css_error EucCSSDocumentTreeNodeIsFirstChild(void *pw, void *nodeIn, bool *match)
{
    id<EucCSSDocumentTreeNode> node = nodeIn;

    id<EucCSSDocumentTreeNode> firstChildNode = node.parent.firstChild;
    while(firstChildNode && firstChildNode.kind != EucCSSDocumentTreeNodeKindElement) {
        firstChildNode = firstChildNode.nextSibling;
    }
    *match = (firstChildNode == node);
    return CSS_OK;
}

static css_error EucCSSDocumentTreeNodeIsLink(void *pw, void *nodeIn, bool *match)
{
    id<EucCSSDocumentTreeNode> node = nodeIn;
    *match = [node isHyperlinkNode];
    return CSS_OK;
}

static css_error EucCSSDocumentTreeNodeIsVisited(void *pw, void *nodeIn, bool *match)
{
    *match = false;
    return CSS_OK;
}

static css_error EucCSSDocumentTreeNodeIsHover(void *pw, void *nodeIn, bool *match)
{
    *match = false;
    return CSS_OK;
}

static css_error EucCSSDocumentTreeNodeIsActive(void *pw, void *nodeIn, bool *match)
{
    *match = false;
    return CSS_OK; 
}

static css_error EucCSSDocumentTreeNodeIsFocus(void *pw, void *nodeIn, bool *match)
{
    *match = false;
    return CSS_OK;  
}

static css_error EucCSSDocumentTreeNodeIsLang(void *pw, void *nodeIn, lwc_string *lang, bool *match)
{
    *match = false;
    return CSS_OK;
}

static css_error EucCSSDocumentTreeNodePresentationalHint(void *pw, void *nodeIn, uint32_t property, css_hint *hint)
{
	return CSS_PROPERTY_NOT_SET;
}

static css_error EucCSSDocumentTreeUADefaultForProperty(void *pw, uint32_t propertyIn, css_hint *hint)
{
    enum css_properties_e property = (enum css_properties_e)propertyIn;
	if (property == CSS_PROP_COLOR) {
 		hint->data.color = 0xFF000000;
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

static pthread_once_t s_font_sizes_once_control = PTHREAD_ONCE_INIT;
static css_hint_length s_font_sizes[7];
static void setup_font_sizes() {
    float default_size = [[EucConfiguration objectForKey:EucConfigurationDefaultFontSizeKey] floatValue];
    s_font_sizes[0].value = FLTTOFIX(default_size / 1.2f / 1.2f / 1.2f);
    s_font_sizes[0].unit = CSS_UNIT_PT;
    s_font_sizes[1].value = FLTTOFIX(default_size / 1.2f / 1.2f);
    s_font_sizes[1].unit = CSS_UNIT_PT;
    s_font_sizes[2].value = FLTTOFIX(default_size / 1.2f);
    s_font_sizes[2].unit = CSS_UNIT_PT;
    s_font_sizes[3].value = FLTTOFIX(default_size);
    s_font_sizes[3].unit = CSS_UNIT_PT;
    s_font_sizes[4].value = FLTTOFIX(default_size * 1.2f);
    s_font_sizes[4].unit = CSS_UNIT_PT;
    s_font_sizes[5].value = FLTTOFIX(default_size * 1.2f * 1.2f);
    s_font_sizes[5].unit = CSS_UNIT_PT;
    s_font_sizes[6].value = FLTTOFIX(default_size * 1.2f * 1.2f * 1.2f);
    s_font_sizes[6].unit = CSS_UNIT_PT;
}

static css_error EucCSSDocumentTreeComputeFontSize(void *pw, const css_hint *parent, css_hint *size)
{
    pthread_once(&s_font_sizes_once_control, setup_font_sizes);
    
	const css_hint_length *parent_size;
    
	/* Grab parent size, defaulting to medium if none */
	if (parent == NULL) {
		parent_size = &s_font_sizes[CSS_FONT_SIZE_MEDIUM - 1];
	} else {
		assert(parent->status == CSS_FONT_SIZE_DIMENSION);
		assert(parent->data.length.unit != CSS_UNIT_EM);
		assert(parent->data.length.unit != CSS_UNIT_EX);
		parent_size = &parent->data.length;
	}
    
	assert(size->status != CSS_FONT_SIZE_INHERIT);
    
	if (size->status < CSS_FONT_SIZE_LARGER) {
		size->data.length = s_font_sizes[size->status - 1];
	} else if (size->status == CSS_FONT_SIZE_LARGER) {
		size->data.length.value = 
        FMUL(parent_size->value, FLTTOFIX(1.2));
		size->data.length.unit = parent_size->unit;
	} else if (size->status == CSS_FONT_SIZE_SMALLER) {
		size->data.length.value = 
        FDIV(parent_size->value, FLTTOFIX(1.2));
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

static bool _LWCStringContainsElement(lwc_string *lwcString, lwc_string *lwcElement)
{
    if(lwcString == lwcElement) {
        return true;
    } else {
        static CFCharacterSetRef whitespaceSet = NULL;
        if(!whitespaceSet) {
            // Not entirely thread-safe, but since it'll always return the same constant
            // value, should be fine in practice.
            whitespaceSet = CFCharacterSetGetPredefined(kCFCharacterSetWhitespaceAndNewline);
        }
        
        CFStringRef string = (CFStringRef)NSStringFromLWCString(lwcString);
        CFStringRef element = (CFStringRef)NSStringFromLWCString(lwcElement);
        
        CFIndex length = CFStringGetLength(string);
        CFRange range = CFRangeMake(0, length);
        CFRange foundRange;
        while(CFStringFindWithOptions(string, element, range, 0, &foundRange)) {
            if(foundRange.location == 0 || CFCharacterSetIsCharacterMember(whitespaceSet, CFStringGetCharacterAtIndex(string, foundRange.location - 1))) {
                CFIndex end = foundRange.location + foundRange.length;
                if(end == length || CFCharacterSetIsCharacterMember(whitespaceSet, CFStringGetCharacterAtIndex(string, end))) {
                    return true;
                }
            }
            range.location = foundRange.location + 1;
            range.length = length - range.location;
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
