/*
 *  EucHTMLDBCreation.c
 *  LibCSSTest
 *
 *  Created by James Montgomerie on 03/12/2009.
 *  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
 *
 */

#include <CoreFoundation/CoreFoundation.h>

#include <sys/types.h>
#include <db.h>
#include <fcntl.h>
#include <limits.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

#include <hubbub/hubbub.h>
#include <hubbub/parser.h>

#include <libwapcaplet/libwapcaplet.h>

#include <libcss/libcss.h>

#include "EucHTMLDBCreation.h"

hubbub_error EucHTMLDBCreateRoot(void *ctx, void **result)
{
    EucHTMLDB *context = ctx;
    
    assert(context->rootNodeKey == 0);
    
    hubbub_error ret = HUBBUB_UNKNOWN;
    
    uint32_t nodeElements[rootElementCount];
    nodeElements[kindPosition] = nodeKindRoot;
    nodeElements[refcountPosition] = 0;
    
    nodeElements[parentPosition] = 0;
    nodeElements[childrenPosition] = 0;
    
    uint32_t resultKey = EucHTMLDBPutNode(context, 0, nodeElements);
    if(resultKey) {
        context->rootNodeKey = resultKey;
        *result = (void *)(uintptr_t)resultKey;
        ret = HUBBUB_OK;
    }
    
    //NSLog(@"%ld, %ld, %s", (long)(uintptr_t)*result, ret, __FUNCTION__);
    
    
    return ret;
}


static hubbub_error EucHTMLDBCreateComment(void *ctx,
                                        const hubbub_string *data,
                                        void **result)
{
    EucHTMLDB *context = ctx;
    hubbub_error ret = HUBBUB_UNKNOWN;
    
    uint32_t nodeElements[commentElementCount];
    nodeElements[kindPosition] = nodeKindComment;
    nodeElements[refcountPosition] = 1;
    
    nodeElements[parentPosition] = 0;
    nodeElements[childrenPosition] = 0;
    
    nodeElements[commentTextPosition] = EucHTMLDBPutUTF8(context, 0, data->ptr, data->len);
    if(nodeElements[commentTextPosition] ) {
        uint32_t resultKey = EucHTMLDBPutNode(context, 0, nodeElements);
        if(resultKey) {
            *result = (void *)(uintptr_t)resultKey;
            ret = HUBBUB_OK;
        }
    }
    
    //NSLog(@"%ld, %ld, %s", (long)(uintptr_t)*result, ret, __FUNCTION__);
    
    return ret;
}

static hubbub_error EucHTMLDBCreateDoctype(void *ctx,
                                        const hubbub_doctype *doctype,
                                        void **result)
{
    EucHTMLDB *context = ctx;
    hubbub_error ret = HUBBUB_UNKNOWN;
    
    uint32_t nodeElements[doctypeElementCount];
    nodeElements[kindPosition] = nodeKindDoctype;
    nodeElements[refcountPosition] = 1;
    
    nodeElements[parentPosition] = 0;
    nodeElements[childrenPosition] = 0;
    
    nodeElements[doctypeNamePosition] = EucHTMLDBPutUTF8(context, 0, doctype->name.ptr, doctype->name.len);
    if(nodeElements[doctypeNamePosition]) {
        if(doctype->public_missing) {
            nodeElements[doctypePublicIdPosition] = 0;
        } else {
            nodeElements[doctypePublicIdPosition] = EucHTMLDBPutUTF8(context, 0, doctype->public_id.ptr, doctype->public_id.len);
        }
        if(doctype->public_missing || nodeElements[doctypePublicIdPosition]) {
            if(doctype->system_missing) {
                nodeElements[doctypeSystemIdPosition] = 0;
            } else {
                nodeElements[doctypeSystemIdPosition] = EucHTMLDBPutUTF8(context, 0, doctype->system_id.ptr, doctype->system_id.len);
            }
            if(doctype->system_missing || nodeElements[doctypeSystemIdPosition]) {
                nodeElements[doctypeForceQuirksIdPosition] = (uint32_t)doctype->force_quirks;
                uint32_t resultKey = EucHTMLDBPutNode(context, 0, nodeElements);
                if(resultKey) {
                    *result = (void *)(uintptr_t)resultKey;
                    ret = HUBBUB_OK;
                }
            }
        }
    }
    
    //NSLog(@"%ld, %ld, %s", (long)(uintptr_t)*result, ret, __FUNCTION__);
    
    
    return ret;
}

static hubbub_error EucHTMLDBCreateElement(void *ctx,
                                        const hubbub_tag *tag,
                                        void **result)
{
    EucHTMLDB *context = ctx;
    hubbub_error ret = HUBBUB_UNKNOWN;
    
    uint32_t nodeElements[elementElementCount];
    nodeElements[kindPosition] = nodeKindElement;
    nodeElements[refcountPosition] = 1;
    
    nodeElements[parentPosition] = 0;
    nodeElements[childrenPosition] = 0;
    
    nodeElements[elementNamespacePosition] = (int32_t)tag->ns;
    nodeElements[elementNamePosition] = EucHTMLDBPutUTF8(context, 0, tag->name.ptr, tag->name.len);
    if(nodeElements[elementNamePosition]) {
        hubbub_error innerRet = HUBBUB_OK;
        uint32_t attributeCount = tag->n_attributes;
        if(attributeCount) {
            uint32_t attributes[attributeCount];
            
            
            for(uint32_t i = 0; innerRet == HUBBUB_OK && i < attributeCount; ++i) {
                uint32_t newAttributeKey = EucHTMLDBPutAttribute(context, 0, tag->attributes[i].ns, &(tag->attributes[i].name),  &(tag->attributes[i].value));
                attributes[i] = newAttributeKey;
                if(!newAttributeKey) {
                    innerRet = HUBBUB_UNKNOWN;
                } 
            }
            if(innerRet == HUBBUB_OK) {
                nodeElements[elementAttributesPosition] = EucHTMLDBPutUint32Array(context, 0, attributes, attributeCount);
                if(!nodeElements[elementAttributesPosition]) {
                    innerRet = HUBBUB_UNKNOWN;
                }
            }
        }
        if(innerRet == HUBBUB_OK) {
            uint32_t resultKey = EucHTMLDBPutNode(context, 0, nodeElements);
            if(resultKey) {
                *result = (void *)(uintptr_t)resultKey;
                ret = HUBBUB_OK;
            }            
        } 
    }
    
    //NSLog(@"%ld, %ld, %s", (long)(uintptr_t)*result, ret, __FUNCTION__);
    
    
    return ret;    
}

static hubbub_error EucHTMLDBCreateText(void *ctx,
                                     const hubbub_string *data,
                                     void **result)
{   
    EucHTMLDB *context = ctx;
    hubbub_error ret = HUBBUB_UNKNOWN;
    
    uint32_t nodeElements[textElementCount];
    nodeElements[kindPosition] = nodeKindText;
    nodeElements[refcountPosition] = 1;
    
    nodeElements[parentPosition] = 0;
    nodeElements[childrenPosition] = 0;
    
    nodeElements[textTextPosition] = EucHTMLDBPutUTF8(context, 0, data->ptr, data->len);
    if(nodeElements[textTextPosition]) {
        uint32_t resultKey = EucHTMLDBPutNode(context, 0, nodeElements);
        if(resultKey) {
            *result = (void *)(uintptr_t)resultKey;
            ret = HUBBUB_OK;
        }            
    }
    
    //NSLog(@"%ld, %ld, %s", (long)(uintptr_t)*result, ret, __FUNCTION__);
    
    
    return ret;    
}

static hubbub_error EucHTMLDBCloneNodeWithNewRefCount(void *ctx,
                                                   uint32_t node,
                                                   uint32_t newParent,
                                                   bool deep,
                                                   uint32_t refCount,
                                                   uint32_t *result) 
{
    EucHTMLDB *context = ctx;
    uint32_t key = (uint32_t)(uintptr_t)node;
    
    hubbub_error ret;
    hubbub_error innerRet = HUBBUB_OK;
    
    uint32_t *nodeElements;
    ret = EucHTMLDBCopyNode(context, key, &nodeElements);
    if(ret == HUBBUB_OK) {
        nodeElements[refcountPosition] = refCount;
        nodeElements[parentPosition] = newParent;
        if(!deep) {
            nodeElements[childrenPosition] = 0;
        } else {
            if(nodeElements[childrenPosition] != 0) {
                uint32_t *childKeys;
                uint32_t childCount;
                ret = EucHTMLDBCopyUint32Array(context, nodeElements[childrenPosition], &childKeys, &childCount);
                if(ret == HUBBUB_OK) {
                    for(uint32_t i = 0; innerRet == HUBBUB_OK && i < childCount; ++i) {
                        innerRet = EucHTMLDBCloneNodeWithNewRefCount(context,
                                                                  childKeys[i],
                                                                  key,
                                                                  true,
                                                                  0,
                                                                  &childKeys[i]);
                    }
                    if(innerRet == HUBBUB_OK) {
                        nodeElements[childrenPosition] = EucHTMLDBPutUint32Array(context, 0, childKeys, childCount);
                        if(!nodeElements[childrenPosition]) {
                            innerRet == HUBBUB_UNKNOWN;
                        }
                    }
                    free(childKeys);
                }
            }
        }
        
        if(innerRet == HUBBUB_OK) {
            uint32_t resultKey = EucHTMLDBPutNode(context, 0, nodeElements);
            if(resultKey) {
                *result = resultKey;
                ret = HUBBUB_OK;
            }            
        } else {
            ret = innerRet;
        }
        free(nodeElements);
    } 
    
    //NSLog(@"%ld, %ld, %s", (long)(uintptr_t)*result, ret, __FUNCTION__);
    
    
    return ret;    
}

static hubbub_error EucHTMLDBCloneNode(void *ctx,
                                    void *node,
                                    bool deep,
                                    void **result)
{
    hubbub_error ret;
    uint32_t innerResult = 0;
    ret = EucHTMLDBCloneNodeWithNewRefCount(ctx,
                                         (uint32_t)(intptr_t)node,
                                         0,
                                         deep,
                                         1,
                                         &innerResult);
    if(ret == HUBBUB_OK) {
        *result = (void *)(intptr_t)innerResult;
    }
    
    //NSLog(@"%ld, %ld, %s", (long)(uintptr_t)*result, ret, __FUNCTION__);
    
    return ret;
}

static hubbub_error EucHTMLDBRefNode(void *ctx, void *node)
{
    EucHTMLDB *context = ctx;
    uint32_t key = (uint32_t)(uintptr_t)node;
    
    hubbub_error ret;
    
    uint32_t *nodeElements;
    ret = EucHTMLDBCopyNode(context, key, &nodeElements);
    if(ret == HUBBUB_OK) {
        ++nodeElements[refcountPosition];
        if(!EucHTMLDBPutNode(context, key, nodeElements)) {
            ret = HUBBUB_UNKNOWN;
        }
        free(nodeElements);
    }
    
    //NSLog(@"%ld, %ld, %s", (long)(uintptr_t)node, ret, __FUNCTION__);
    
    return ret;
}

static hubbub_error EucHTMLDBRecursiveDeleteNode(void *ctx, uint32_t key, uint32_t *nodeElements) {
    EucHTMLDB *context = ctx;
    hubbub_error ret = HUBBUB_UNKNOWN;
    
    //assert(nodeElements[refcountPosition] != 0);
    
    ret = DBDeleteValueForKey(context, key);
    
    switch(nodeElements[kindPosition]) {
        case nodeKindDoctype:
            DBDeleteValueForKey(context, nodeElements[doctypeNamePosition]);
            break;
        case nodeKindComment:
            DBDeleteValueForKey(context, nodeElements[commentTextPosition]);
            if(nodeElements[doctypePublicIdPosition]) {
                DBDeleteValueForKey(context, nodeElements[doctypePublicIdPosition]);
            }
            if(nodeElements[doctypeSystemIdPosition]) {
                DBDeleteValueForKey(context, nodeElements[doctypeSystemIdPosition]);
            }
            break;
        case nodeKindElement:
            DBDeleteValueForKey(context, nodeElements[elementNamePosition]);
            if(nodeElements[elementAttributesPosition]) {
                uint32_t *attributeKeys;
                uint32_t attributeCount;
                if(EucHTMLDBCopyUint32Array(context, nodeElements[elementAttributesPosition], &attributeKeys, &attributeCount) == HUBBUB_OK) {
                    for(uint32_t i = 0; i < attributeCount; ++i) {
                        DBRemoveAttribute(context, attributeKeys[i]);
                    }
                    free(attributeKeys);
                }
                DBDeleteValueForKey(context, nodeElements[elementAttributesPosition]);
            }
            break;
        case nodeKindText:
            DBDeleteValueForKey(context, nodeElements[textTextPosition]);
            break;
        default:
            break;
    }
    
    if(nodeElements[childrenPosition]) {
        uint32_t *childrenArray;
        uint32_t childrenCount;
        if(EucHTMLDBCopyUint32Array(context, nodeElements[childrenPosition], &childrenArray, &childrenCount) == HUBBUB_OK) {
            for(uint32_t i = 0; i < childrenCount; ++i) {
                uint32_t *childNodeElements;
                ret = EucHTMLDBCopyNode(context, childrenArray[i], &childNodeElements);
                if(ret == HUBBUB_OK) {
                    EucHTMLDBRecursiveDeleteNode(context, childrenArray[i], childNodeElements);
                    free(childNodeElements);
                }
            }
            
            free(childrenArray);
        }
        DBDeleteValueForKey(context, nodeElements[childrenPosition]);
    }
    
    //NSLog(@"%ld, %ld, %s", (long)key, ret, __FUNCTION__);
    
    return ret;
}

static hubbub_error EucHTMLDBUnrefNode(void *ctx, void *node)
{
    EucHTMLDB *context = ctx;
    uint32_t key = (uint32_t)(uintptr_t)node;
    
    hubbub_error ret;
    
    uint32_t *nodeElements;
    ret = EucHTMLDBCopyNode(context, key, &nodeElements);
    if(ret == HUBBUB_OK) {
        if(nodeElements[kindPosition] != nodeKindRoot) {
            --nodeElements[refcountPosition];
            if(nodeElements[refcountPosition] == 0 && 
               !nodeElements[parentPosition]) {
                EucHTMLDBRecursiveDeleteNode(ctx, key, nodeElements);
            } else {
                if(!EucHTMLDBPutNode(context, key, nodeElements)) {
                    ret = HUBBUB_UNKNOWN;
                }
            }
        }
        free(nodeElements);
    }
    
    //NSLog(@"%ld, %ld, %s", (long)(uintptr_t)node, ret, __FUNCTION__);
    
    return ret;
}

static hubbub_error EucHTMLDBInsertBefore(void *ctx, void *parent, void *child, void *childToGoBefore,
                                       void **result)
{
    EucHTMLDB *context = ctx;
    
    uint32_t resultKey = 0;
    
    uint32_t parentKey = (uint32_t)(uintptr_t)parent;
    uint32_t childKey = (uint32_t)(uintptr_t)child;
    uint32_t childToGoBeforeKey = (uint32_t)(uintptr_t)childToGoBefore;
    
    hubbub_error ret = HUBBUB_OK;
    
    uint32_t *parentElements;
    ret = EucHTMLDBCopyNode(context, parentKey, &parentElements);
    if(ret == HUBBUB_OK) {
        uint32_t *childElements;
        ret = EucHTMLDBCopyNode(context, childKey, &childElements);
        if(ret == HUBBUB_OK) {        
            
            // If there are no children already, just set the children array to a 
            // one-element array containing the child - easy.
            if(!parentElements[childrenPosition]) {
                parentElements[childrenPosition] = EucHTMLDBPutUint32Array(context, 0, &childKey, 1);
                if(!parentElements[childrenPosition]) {
                    ret = HUBBUB_UNKNOWN;
                } else {
                    if(!EucHTMLDBPutNode(context, parentKey, parentElements)) {
                        ret = HUBBUB_UNKNOWN;
                    } else {
                        ++childElements[refcountPosition];
                        childElements[parentPosition] = parentKey;
                        if(!EucHTMLDBPutNode(context, childKey, childElements)) {
                            ret = HUBBUB_UNKNOWN;
                        }
                        resultKey = childKey;                                    
                    }
                }
            }
            
            if(!resultKey && ret == HUBBUB_OK) {
                // Can we just prepend our text to the node we're to go before?
                if(childToGoBeforeKey && childElements[kindPosition] == nodeKindText) {
                    uint32_t *childToGoBeforeElements;
                    ret = EucHTMLDBCopyNode(context, childToGoBeforeKey, &childToGoBeforeElements);
                    if(ret == HUBBUB_OK) {
                        if(childToGoBeforeElements[kindPosition] == nodeKindText) {
                            uint8_t *childToGoBeforeString;
                            size_t childToGoBeforeStringLength;
                            ret = EucHTMLDBCopyUTF8(context, childToGoBeforeElements[textTextPosition], &childToGoBeforeString, &childToGoBeforeStringLength);
                            if(ret == HUBBUB_OK) {
                                uint8_t *childString;
                                size_t childStringLength;
                                ret = EucHTMLDBCopyUTF8(context, childElements[textTextPosition], &childString, &childStringLength);
                                if(ret == HUBBUB_OK) {
                                    size_t newLength = childToGoBeforeStringLength + childStringLength;
                                    childString = realloc(childString, newLength);
                                    memcpy(childString + childStringLength, childToGoBeforeString, childToGoBeforeStringLength);
                                    if(!EucHTMLDBPutUTF8(context, childToGoBeforeElements[textTextPosition], childString, newLength)) {
                                        ret = HUBBUB_UNKNOWN;
                                    } else {
                                        ++childToGoBeforeElements[refcountPosition];
                                        if(!EucHTMLDBPutNode(context, childToGoBeforeKey, childToGoBeforeElements)) {
                                            ret = HUBBUB_UNKNOWN;
                                        }
                                        resultKey = childToGoBeforeKey;
                                    }
                                    free(childString);
                                }
                                free(childToGoBeforeString);
                            }     
                        }
                        free(childToGoBeforeElements);
                    }
                }
                
                if(!resultKey && ret == HUBBUB_OK) {
                    uint32_t *childrenArray;
                    uint32_t childrenCount;
                    ret = EucHTMLDBCopyUint32Array(context, parentElements[childrenPosition], &childrenArray, &childrenCount);
                    if(ret == HUBBUB_OK) {
                        // Work out where to insert the node in the child array.
                        // If childToGoBeforeKey is 0, append the node. 
                        int32_t insertionIndex;
                        if(!childToGoBeforeKey) {
                            insertionIndex = childrenCount;
                        } else {
                            for(insertionIndex = 0; insertionIndex < childrenCount; ++insertionIndex) {
                                if(childrenArray[insertionIndex] == childToGoBeforeKey) {
                                    break;
                                }
                            }
                        }
                        
                        // Can we append our text to the preceeding node?
                        if(insertionIndex > 0 && childElements[kindPosition] == nodeKindText) {
                            uint32_t childToGoAfterKey = childrenArray[insertionIndex - 1];
                            uint32_t *childToGoAfterElements;
                            ret = EucHTMLDBCopyNode(context, childToGoAfterKey, &childToGoAfterElements);
                            if(ret == HUBBUB_OK) {
                                if(childToGoAfterElements[kindPosition] == nodeKindText) {
                                    uint8_t *childToGoAfterString;
                                    size_t childToGoAfterStringLength;
                                    ret = EucHTMLDBCopyUTF8(context, childToGoAfterElements[textTextPosition], &childToGoAfterString, &childToGoAfterStringLength);
                                    if(ret == HUBBUB_OK) {
                                        uint8_t *childString;
                                        size_t childStringLength;
                                        ret = EucHTMLDBCopyUTF8(context, childElements[textTextPosition], &childString, &childStringLength);
                                        if(ret == HUBBUB_OK) {
                                            size_t newLength = childToGoAfterStringLength + childStringLength;
                                            childToGoAfterString = realloc(childToGoAfterString, newLength);
                                            memcpy(childToGoAfterString + childToGoAfterStringLength, childString, childStringLength);
                                            if(!EucHTMLDBPutUTF8(context, childToGoAfterElements[textTextPosition], childToGoAfterString, newLength)) {
                                                ret = HUBBUB_UNKNOWN;
                                            } else {
                                                ++childToGoAfterElements[refcountPosition];
                                                if(!EucHTMLDBPutNode(context, childToGoAfterKey, childToGoAfterElements)) {
                                                    ret = HUBBUB_UNKNOWN;
                                                }
                                                resultKey = childToGoAfterKey;
                                            }
                                            free(childString);
                                        }
                                        free(childToGoAfterString);
                                    }     
                                }
                                free(childToGoAfterElements);
                            }            
                        }
                        
                        if(!resultKey && ret == HUBBUB_OK) {
                            // No text manipulation - we're going to really have to insert the node.
                            uint32_t newChildrenCount = childrenCount + 1;
                            if(insertionIndex < newChildrenCount) {
                                // Bump up the children after us, and insert.
                                childrenArray = realloc(childrenArray, newChildrenCount * sizeof(uint32_t));
                                for(uint32_t i = insertionIndex; i < childrenCount; ++i) {
                                    childrenArray[i+1] = childrenArray[i];
                                }
                                childrenArray[insertionIndex] = childKey;
                                if(!EucHTMLDBPutUint32Array(context, parentElements[childrenPosition], childrenArray, newChildrenCount)) {
                                    ret = HUBBUB_UNKNOWN;
                                } else {
                                    ++childElements[refcountPosition];
                                    childElements[parentPosition] = parentKey;
                                    if(!EucHTMLDBPutNode(context, childKey, childElements)) {
                                        ret = HUBBUB_UNKNOWN;
                                    }
                                    resultKey = childKey;
                                }                                
                            } else {
                                ret = HUBBUB_UNKNOWN;
                            }
                        }   
                        free(childrenArray);
                    }
                }
            }
            free(childElements);
        }
        free(parentElements);
    }
    
    if(ret == HUBBUB_OK) {
        *result = (void *)(intptr_t)resultKey;
    }
    
    //NSLog(@"%ld, %ld, %s", (long)(uintptr_t)*result, ret, __FUNCTION__);
    
    return ret;
}

static hubbub_error EucHTMLDBAppendChild(void *ctx, void *parent, void *child, void **result)
{
    return EucHTMLDBInsertBefore(ctx, parent, child, NULL, result);
}

static hubbub_error EucHTMLDBRemoveChild(void *ctx, void *parent, void *child, void **result)
{
    EucHTMLDB *context = ctx;
    
    uint32_t parentKey = (uint32_t)(uintptr_t)parent;
    uint32_t childKey = (uint32_t)(uintptr_t)child;
    
    hubbub_error ret = HUBBUB_OK;
    
    uint32_t *parentElements;
    ret = EucHTMLDBCopyNode(context, parentKey, &parentElements);
    if(ret == HUBBUB_OK) {
        uint32_t *childrenArray;
        uint32_t childrenCount;
        ret = EucHTMLDBCopyUint32Array(context, parentElements[childrenPosition], &childrenArray, &childrenCount);
        if(ret == HUBBUB_OK) {
            if(childrenCount == 1) {
                // 1 child = remove the children array;
                assert(childKey == childrenArray[0]);
                ret = DBDeleteValueForKey(context, parentElements[childrenPosition]);
                parentElements[childrenPosition] = 0;
            } else {
                // Remove the reference to the child from the array and re-put it.
                uint32_t newChildrenCount = childrenCount -1;
                uint32_t i = 0;
                for(; i < newChildrenCount; ++i) {
                    if(childrenArray[i] == childKey) {
                        break;
                    }
                }
                for(; i < newChildrenCount; ++i) {
                    childrenArray[i] == childrenArray[i + 1];
                }
                if(!EucHTMLDBPutUint32Array(context, parentElements[childrenPosition], childrenArray, newChildrenCount)) {
                    ret = HUBBUB_UNKNOWN;
                }
            }
            free(childrenArray);
        }
        
        ret = EucHTMLDBRefNode(ctx, child);
        if(ret == HUBBUB_OK) {
            *result = child;
        }
    }
    
    //NSLog(@"%ld, %ld, %s", (long)(uintptr_t)*result, ret, __FUNCTION__);
    
    return ret;    
}

static hubbub_error EucHTMLDBReparentChildren(void *ctx, void *fromParent, void *toParent)
{
    EucHTMLDB *context = ctx;
    
    uint32_t fromParentKey = (uint32_t)(uintptr_t)fromParent;
    uint32_t toParentKey = (uint32_t)(uintptr_t)toParent;
    
    hubbub_error ret = HUBBUB_OK;
    
    uint32_t *fromParentElements;
    ret = EucHTMLDBCopyNode(context, fromParentKey, &fromParentElements);
    if(ret == HUBBUB_OK) {
        uint32_t *fromChildrenArray;
        uint32_t fromChildrenCount;
        ret = EucHTMLDBCopyUint32Array(context, fromParentElements[childrenPosition], &fromChildrenArray, &fromChildrenCount);
        if(ret == HUBBUB_OK) {
            uint32_t *toParentElements;
            ret = EucHTMLDBCopyNode(context, toParentKey, &toParentElements);
            if(ret == HUBBUB_OK) {
                if(!toParentElements[childrenPosition]) {
                    toParentElements[childrenPosition] = fromParentElements[childrenPosition];
                    if(!EucHTMLDBPutNode(context, toParentKey, toParentElements)) {
                        ret = HUBBUB_UNKNOWN;
                    }
                } else {
                    uint32_t *toChildrenArray;
                    uint32_t toChildrenCount;
                    ret = EucHTMLDBCopyUint32Array(context, toParentElements[childrenPosition], &toChildrenArray, &toChildrenCount);
                    if(ret == HUBBUB_OK) {
                        int32_t appendedChildrenCount = fromChildrenCount + toChildrenCount;
                        toChildrenArray = realloc(toChildrenArray, appendedChildrenCount * sizeof(uint32_t));
                        memcpy(toChildrenArray + toChildrenCount, fromChildrenArray, fromChildrenCount);
                        if(!EucHTMLDBPutUint32Array(context, toParentElements[childrenPosition], toChildrenArray, appendedChildrenCount)) {
                            ret = HUBBUB_UNKNOWN;
                        } else {
                            ret = DBDeleteValueForKey(context, fromParentElements[childrenPosition]);
                        }
                        free(toChildrenArray);                        
                    }
                }
                
                // Reparent the nodes.
                for(uint32_t i = 0; ret == HUBBUB_OK && i < fromChildrenCount; ++i) {
                    uint32_t childKey = fromChildrenArray[i];
                    uint32_t *childElements;
                    ret = EucHTMLDBCopyNode(context, childKey, &childElements);
                    childElements[parentPosition] = toParentKey;
                    if(!EucHTMLDBPutNode(context, childKey, childElements)) {
                        ret = HUBBUB_UNKNOWN;
                    }
                    free(childElements);
                }
                
                if(ret == HUBBUB_OK) {
                    // Clear out the old parent's children pointer (the actual array 
                    // it refers to has already been either reused of destroyed above).
                    fromParentElements[childrenPosition] = 0;
                    if(!EucHTMLDBPutNode(context, fromParentKey, fromParentElements)) {
                        ret = HUBBUB_UNKNOWN;
                    }
                }
                
                free(toParentElements);
            }
            free(fromChildrenArray);
        }
        free(fromParentElements);
    }
    
    //NSLog(@"%ld, %ld, %s", (long)0, ret, __FUNCTION__);
    
    return ret;
}

static hubbub_error EucHTMLDBGetParent(void *ctx, void *node, bool element_only, void **result)
{
    EucHTMLDB *context = ctx;
    
    uint32_t resultKey = 0;
    
    uint32_t nodeKey = (uint32_t)(uintptr_t)node;
    hubbub_error ret = HUBBUB_OK;
    uint32_t *nodeElements;
    ret = EucHTMLDBCopyNode(context, nodeKey, &nodeElements);
    if(ret == HUBBUB_OK) {
        if(!element_only || nodeElements[kindPosition] == nodeKindElement) {
            resultKey = nodeElements[parentPosition];
            if(resultKey) {
                ret = EucHTMLDBRefNode(ctx, (void *)(intptr_t)resultKey);
            }
        }
        free(nodeElements);
    }
    
    if(ret == HUBBUB_OK) {
        *result = (void *)(intptr_t)resultKey;
    }
    
    //NSLog(@"%ld, %ld, %s", (long)(uintptr_t)*result, ret, __FUNCTION__);
    
    return ret;
}

static hubbub_error EucHTMLDBHasChildren(void *ctx, void *node, bool *result)
{
    EucHTMLDB *context = ctx;
    
    uint32_t nodeKey = (uint32_t)(uintptr_t)node;
    hubbub_error ret = HUBBUB_OK;
    
    uint32_t *nodeElements;
    ret = EucHTMLDBCopyNode(context, nodeKey, &nodeElements);
    if(ret == HUBBUB_OK) {
        *result = (nodeElements[childrenPosition] != 0);
        free(nodeElements);
    }
    
    //NSLog(@"%ld, %ld, %s", (long)(uintptr_t)*result, ret, __FUNCTION__);
    
    return ret;
}

static hubbub_error EucHTMLDBFormAssociate(void *ctx, void *form, void *node)
{
    // We don't care about forms.
    return HUBBUB_OK;
}

static hubbub_error EucHTMLDBAddAttributes(void *ctx, 
                                        void *node,
                                        const hubbub_attribute *attributes,
                                        uint32_t additionalAttributesCount)
{
    EucHTMLDB *context = ctx;
    
    uint32_t nodeKey = (uint32_t)(uintptr_t)node;
    hubbub_error ret = HUBBUB_OK;
    
    uint32_t *nodeElements;
    ret = EucHTMLDBCopyNode(context, nodeKey, &nodeElements);
    if(ret == HUBBUB_OK) {
        assert(nodeElements[kindPosition] == nodeKindElement);
        
        uint32_t oldAttributeCount = 0;
        uint32_t *attributeArray = NULL;
        if(nodeElements[elementAttributesPosition]) {
            ret = EucHTMLDBCopyUint32Array(context, nodeElements[elementAttributesPosition], &attributeArray, &oldAttributeCount);
        }        
        if(ret == HUBBUB_OK) {
            uint32_t newAttributeCount = oldAttributeCount;
            attributeArray = realloc(attributeArray, sizeof(uint32_t) * (additionalAttributesCount + oldAttributeCount));
            
            for(uint32_t i = 0; ret == HUBBUB_OK && i < additionalAttributesCount; ++i) {
                uint32_t j = 0;
                for(; ret == HUBBUB_OK && j < oldAttributeCount; ++j) {
                    // Ick.  Need to iterate through the old attributes,
                    // looking for identical namespace and tag.  If one 
                    // exists, /don't/ append the new attribute.
                    // This doesn't need to be too efficient - it only seems
                    // to be called when backing off from parse errors.
                    hubbub_ns ns;
                    hubbub_string name;
                    hubbub_string value;
                    EucHTMLDBCopyAttribute(context, attributeArray[j], &ns, &name, &value);
                    if(ns == attributes[i].ns && 
                       attributes[i].name.len == name.len && 
                       memcmp(attributes[i].name.ptr, name.ptr, name.len) == 0) {
                        free((void *)name.ptr);
                        free((void *)value.ptr);
                        break;
                    }
                    free((void *)name.ptr);
                    free((void *)value.ptr);
                }
                if(ret == HUBBUB_OK && j == oldAttributeCount) {
                    // No old attribute with the same name!  Append the new one.
                    attributeArray[newAttributeCount] = EucHTMLDBPutAttribute(context, 0, attributes[i].ns, &attributes[i].name, &attributes[i].value);
                    if(attributeArray[newAttributeCount]) {
                        ++newAttributeCount;
                    } else {
                        ret = HUBBUB_UNKNOWN;
                    }
                }
            }
            if(newAttributeCount != oldAttributeCount) {
                if(!EucHTMLDBPutUint32Array(context, nodeElements[elementAttributesPosition], attributeArray, oldAttributeCount)) {
                    ret = HUBBUB_UNKNOWN;
                }
            }
            free(attributeArray);
        }
    }
    
    //NSLog(@"%ld, %ld, %s", (long)(uintptr_t)node, ret, __FUNCTION__);
    
    return ret;
}

static hubbub_error EucHTMLDBSetQuirksMode(void *ctx, hubbub_quirks_mode mode)
{
    // We don't care about quirks mode.
    return HUBBUB_OK;
}

static void printBuffer(uint8_t *buffer, int length) 
{
    // Tried to use a %*s argument to printf, but it still runs strlen on the
    // string, so we have to copy it into a null-terminated buffer.
    uint8_t duplicate[length + 1];
    memcpy(duplicate, buffer, length);
    duplicate[length] = '\0';
    printf("%s", (char *)duplicate);
}

static void TraverseNode(EucHTMLDB *context, uint32_t key, uint32_t indent)
{
    uint32_t *node;
    EucHTMLDBCopyNode(context, key, &node);
    
    char *name;
    switch(node[kindPosition]) {
        case nodeKindRoot:
            name = "root";
            break;
        case nodeKindComment:
            name = "comment";
            break;
        case nodeKindDoctype:
            name = "doctype";
            break;
        case nodeKindElement:
            name = "element";
            break;
        default:
            name = "text";
            break;
    }
    
    printf("%6ld:%*s%s", (long)key, (int)indent, "|", name);
    uint32_t childrenKey = node[childrenPosition];
    
    switch(node[kindPosition]) {
        case nodeKindRoot:
            break;
        case nodeKindComment:
        {
            uint8_t* text;
            size_t textLength;
            EucHTMLDBCopyUTF8(context, node[commentTextPosition], &text, &textLength);
            printf(": \"");
            printBuffer(text, textLength);
            printf("\"");
            free(text);
        }
            break;
        case nodeKindDoctype:
        {
        }
            break;
        case nodeKindElement:
        {
            uint8_t* text;
            size_t textLength;
            EucHTMLDBCopyUTF8(context, node[elementNamePosition], &text, &textLength);
            printf(": <");
            printBuffer(text, textLength);
            printf(">");
            free(text);
        }
            break;
        case nodeKindText:          
        {
            uint8_t* text;
            size_t textLength;
            EucHTMLDBCopyUTF8(context, node[textTextPosition], &text, &textLength);
            printf(": \"");
            printBuffer(text, textLength);
            printf("\"");
        }
            break;
        default:
            break;
    }
    
    printf("\n");
    
    free(node);
    
    if(childrenKey) {
        uint32_t childCount;
        uint32_t *children;
        EucHTMLDBCopyUint32Array(context, childrenKey, &children, &childCount);
        for(uint32_t i = 0; i < childCount; ++i) {
            TraverseNode(context, children[i], indent + 2);
        }
    } 
}

void Traverse(EucHTMLDB *context)
{
    lwc_context *lwcContext;
    assert(lwc_create_context(EucRealloc, NULL, &lwcContext) == lwc_error_ok);
    lwc_context_ref(lwcContext);
 
    TraverseNode(context, context->rootNodeKey, 0);
    
    lwc_context_unref(lwcContext);
}

hubbub_tree_handler *EucHTMLDBHubbubTreeHandlerCreateWithContext(EucHTMLDB *context)
{
    hubbub_tree_handler treeHandler = {
        EucHTMLDBCreateComment,
        EucHTMLDBCreateDoctype,
        EucHTMLDBCreateElement,
        EucHTMLDBCreateText,
        EucHTMLDBRefNode,
        EucHTMLDBUnrefNode,
        EucHTMLDBAppendChild,
        EucHTMLDBInsertBefore,
        EucHTMLDBRemoveChild,
        EucHTMLDBCloneNode,
        EucHTMLDBReparentChildren,
        EucHTMLDBGetParent,
        EucHTMLDBHasChildren,
        EucHTMLDBFormAssociate,
        EucHTMLDBAddAttributes,
        EucHTMLDBSetQuirksMode,
        NULL,
        context
    };
    
    hubbub_tree_handler *ret = malloc(sizeof(hubbub_tree_handler));
    memcpy(ret, &treeHandler, sizeof(hubbub_tree_handler));
    
    return ret;
}


EucHTMLDB *EucHTMLDBCreateWithHTMLAtPath(const char* htmlPath, const char* dbPath)
{
    const ssize_t chunkSize = 4096;
    uint8_t buffer[chunkSize];
    hubbub_error err;
    
    EucHTMLDB *context = EucHTMLDBOpen("/tmp/test.db", O_CREAT | O_RDWR | O_TRUNC);
    
    FILE *fp = fopen(htmlPath, "rb");
	if (fp == NULL) {
		printf("Failed opening %s\n", htmlPath);
		goto bail;
	}
    
    hubbub_parser *parser;
    err = hubbub_parser_create(NULL, true, EucRealloc, NULL, &parser);
    if(err != HUBBUB_OK) {
        fprintf(stderr, "Error \"%s\" creating parser\n", hubbub_error_to_string(err));
        goto bail;
    }
    
    hubbub_tree_handler *treeHandler = EucHTMLDBHubbubTreeHandlerCreateWithContext(context);
    
    hubbub_parser_optparams params;
	params.tree_handler = treeHandler;
	err = hubbub_parser_setopt(parser, HUBBUB_PARSER_TREE_HANDLER, &params);
    if(err != HUBBUB_OK) {
        fprintf(stderr, "Error \"%s\" setting HUBBUB_PARSER_TREE_HANDLER option on parser\n", hubbub_error_to_string(err));
        goto bail;
    }
    
    void *rootNodeP;
    EucHTMLDBCreateRoot(context, &rootNodeP);
    params.document_node = rootNodeP;
    err = hubbub_parser_setopt(parser, HUBBUB_PARSER_DOCUMENT_NODE, &params);
    if(err != HUBBUB_OK) {
        fprintf(stderr, "Error \"%s\" setting HUBBUB_PARSER_DOCUMENT_NODE option on parser\n", hubbub_error_to_string(err));
        goto bail;
    }
    
    size_t bytesRead = 0;
	for(;;) {
        bytesRead = fread(buffer, 1, chunkSize, fp);
        
        if(bytesRead < 1) {
            break;
        }
        
		err = hubbub_parser_parse_chunk(parser, buffer, bytesRead);
        if(err != HUBBUB_OK) {
            fprintf(stderr, "Error \"%s\" during parse\n", hubbub_error_to_string(err));
            goto bail;
        }
	}
    
    hubbub_charset_source cssource = 0;
	const char *charset = hubbub_parser_read_charset(parser, &cssource);
    
	printf("Parsed!  Charset: %s (from %d)\n", charset, cssource);    

bail:
    if(fp) {
        fclose(fp);
    }
    if(parser) {
        hubbub_parser_destroy(parser);
    }
    if(treeHandler) {
        free(treeHandler);
    }
    
    return context;
}


