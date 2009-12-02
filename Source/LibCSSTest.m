#import <Foundation/Foundation.h>

#include <hubbub/hubbub.h>
#include <hubbub/parser.h>

#include <sys/types.h>
#include <db.h>
#include <fcntl.h>
#include <limits.h>


enum NodeKinds
{
    nodeKindRoot = 0,
    nodeKindDoctype,
    nodeKindComment,
    nodeKindElement,
    nodeKindText
};

enum NodeArrayPositions
{
    kindPosition = 0,
    refcountPosition,
    parentPosition,
    childrenPosition,
    
    rootElementCount,
    
    doctypeNamePosition = rootElementCount, 
    doctypePublicIdPosition,
    doctypeSystemIdPosition,
    doctypeForceQuirksIdPosition,
    doctypeElementCount,
     
    commentTextPosition = rootElementCount,
    commentElementCount,
    
    elementNamespacePosition = rootElementCount,
    elementNamePosition,
    elementAttributesPosition,
    elementElementCount,
    
    textTextPosition = rootElementCount,
    textElementCount,
};

static size_t sNodeElementCounts[] = 
{ 
    rootElementCount,
    doctypeElementCount, 
    commentElementCount,
    elementElementCount,
    textElementCount
};

typedef struct DBTreeContext
{
    DB *db;
    uint32_t nodeCount;
    uint32_t rootNodeKey;
} DBTreeContext;

static hubbub_error DBTreeCreateRoot(void *ctx, void **result);

static DBTreeContext DBTreeInit() 
{
    DB *db;
    
    BTREEINFO openInfo = { 0 };
    openInfo.lorder = 1234;
    
    /*
     HASHINFO openInfo = { 0 };
     openInfo.lorder = 1234;
    */

    db = dbopen("/tmp/test.db", O_CREAT | O_RDWR | O_TRUNC, 0644, DB_BTREE, &openInfo);
    
    DBTreeContext ret = { db, 0, 0 };
    
    void *rootNodeP;
    DBTreeCreateRoot(&ret, &rootNodeP);
    uint32_t rootNodeKey = (uint32_t)(intptr_t)rootNodeP;
    
    ret.rootNodeKey = rootNodeKey;
    
    return ret;
}

void DBTreeClose(DBTreeContext *context)
{
    context->db->close(context->db);
}

static uint32_t DBPutBytes(DBTreeContext *context, uint32_t key, const void *bytes, size_t length)
{
    if(!key) {
        key = ++(context->nodeCount);
    }
    key = CFSwapInt32HostToLittle(key); // Should be a no-op on ARM.
    const DBT keyThang = 
    { 
        &key, 
        sizeof(uint32_t) 
    };    
    const DBT valueThang = 
    {
        (void *)bytes, 
        length
    };
    
    DB *db = context->db;
    if(db->put(db, (DBT *)&keyThang, &valueThang, 0) == 0) {
        return key;
    } else {
        return 0;
    }
}

static hubbub_error DBCopyBytes(DBTreeContext *context, uint32_t key, void **bytesOut, size_t *lengthOut)
{
    key = CFSwapInt32HostToLittle(key); // Should be a no-op on ARM.
    const DBT keyThang = 
    { 
        &key, 
        sizeof(uint32_t) 
    };    
    DBT valueThang = { 0 };
    
    DB *db = context->db;
    if(db->get(db, &keyThang, &valueThang, 0) == 0) {
        void *copyBytes = malloc(valueThang.size);
        memcpy(copyBytes, valueThang.data, valueThang.size);
        *bytesOut = copyBytes;
        *lengthOut = valueThang.size;
        return HUBBUB_OK;
    } else {
        return HUBBUB_UNKNOWN;
    }
}

static uint32_t DBPutUint32Array(DBTreeContext *context, uint32_t key, const uint32_t *keyArray, uint32_t count)
{
    if(CFByteOrderGetCurrent() == CFByteOrderBigEndian) {
        uint32_t *swappedKeys = alloca(count);
        for(uint32_t i = 0; i < count; ++i) {
            swappedKeys[i] = CFSwapInt32HostToLittle(keyArray[i]);
        }
        keyArray = swappedKeys;
    }
    return DBPutBytes(context, key, keyArray, count * sizeof(uint32_t));
}

static hubbub_error DBCopyUint32Array(DBTreeContext *context, uint32_t key, uint32_t **keyArrayOut, uint32_t *countOut)
{
    key = CFSwapInt32HostToLittle(key); // Should be a no-op on ARM.
    const DBT keyThang = 
    { 
        &key, 
        sizeof(uint32_t) 
    };    
    DBT valueThang = { 0 };
    
    DB *db = context->db;
    if(db->get(db, &keyThang, &valueThang, 0) == 0) {
        uint32_t *copyArray = malloc(valueThang.size);
        uint32_t count = (valueThang.size / sizeof(uint32_t));
        assert(count * sizeof(uint32_t) == valueThang.size);
        if(CFByteOrderGetCurrent() == CFByteOrderBigEndian) {
            for(uint32_t i = 0; i < count; ++i) {
                copyArray[i] = CFSwapInt32HostToLittle(((uint32_t *)valueThang.data)[i]);
            }
        } else {
            memcpy(copyArray, valueThang.data, valueThang.size);
        }
        *keyArrayOut = copyArray;
        *countOut = count;
        return HUBBUB_OK;
    } else {
        return HUBBUB_UNKNOWN;
    }
}

static uint32_t DBPutUTF8(DBTreeContext *context, uint32_t key, const uint8_t *string, size_t length)
{
    return DBPutBytes(context, key, string, length);
}

static hubbub_error DBCopyUTF8(DBTreeContext *context, uint32_t key, uint8_t **string, size_t *length)
{
    return DBCopyBytes(context, key, (void **)string, length);
}


static uint32_t DBPutNode(DBTreeContext *context, uint32_t key, const uint32_t *node)
{

    return DBPutUint32Array(context, key, node, sNodeElementCounts[node[kindPosition]]);
}

static hubbub_error DBCopyNode(DBTreeContext *context, uint32_t key, uint32_t **node)
{
    uint32_t count;
    hubbub_error ret = DBCopyUint32Array(context, key, node, &count);
    assert(count == sNodeElementCounts[(*node)[kindPosition]]);
    return ret;
}

static hubbub_error DBDeleteValueForKey(DBTreeContext *context, uint32_t key)
{
    key = CFSwapInt32HostToLittle(key); // Should be a no-op on ARM.
    const DBT keyThang = 
    { 
        &key, 
        sizeof(uint32_t) 
    };
    
    DB *db = context->db;
    return db->del(db, &keyThang, 0) == 0 ? HUBBUB_OK : HUBBUB_UNKNOWN;
}

static uint32_t DBPutAttribute(DBTreeContext *context, uint32_t key, hubbub_ns ns, const hubbub_string* name, const hubbub_string* value)
{
    uint32_t attributeArray[3];
    attributeArray[0] = ns;
    if((attributeArray[1] = DBPutUTF8(context, 0, name->ptr, name->len)) &&
       (attributeArray[2] = DBPutUTF8(context, 0, value->ptr, value->len))) {
        return DBPutUint32Array(context, key, attributeArray, 3);
    } else {
        return 0;
    }
}

static hubbub_error DBCopyAttribute(DBTreeContext *context, uint32_t key, hubbub_ns *ns, hubbub_string* name, hubbub_string* value)
{
    uint32_t *attributeArray;
    uint32_t count;
    hubbub_error ret = DBCopyUint32Array(context, key, &attributeArray, &count);
    if(ret == HUBBUB_OK) {
        assert(count == 3);
        *ns = attributeArray[0];
        ret = DBCopyUTF8(context, attributeArray[1], (uint8_t **)&(name->ptr), &(name->len));
        if(ret == HUBBUB_OK) {
            ret = DBCopyUTF8(context, attributeArray[2], (uint8_t **)&(value->ptr), &(value->len));
        }
        free(attributeArray);
    }
    return ret;
}

static hubbub_error DBRemoveAttribute(DBTreeContext *context, uint32_t key) 
{
    uint32_t *attributeArray;
    uint32_t count;
    hubbub_error ret = DBCopyUint32Array(context, key, &attributeArray, &count);
    if(ret == HUBBUB_OK) {
        ret = DBDeleteValueForKey(context, attributeArray[1]);
        if(ret == HUBBUB_OK) {
            ret = DBDeleteValueForKey(context, attributeArray[2]);
            if(ret == HUBBUB_OK) {
                DBDeleteValueForKey(context, key);
            }
        }
        free(attributeArray);
    }        
    return ret;
}


static hubbub_error DBTreeCreateRoot(void *ctx, void **result)
{
    DBTreeContext *context = ctx;
    hubbub_error ret = HUBBUB_UNKNOWN;
    
    uint32_t nodeElements[rootElementCount];
    nodeElements[kindPosition] = nodeKindRoot;
    nodeElements[refcountPosition] = 0;
    
    nodeElements[parentPosition] = 0;
    nodeElements[childrenPosition] = 0;
    
    uint32_t resultKey = DBPutNode(context, 0, nodeElements);
    if(resultKey) {
        *result = (void *)(uintptr_t)resultKey;
        ret = HUBBUB_OK;
    }
    
    //NSLog(@"%ld, %ld, %s", (long)(uintptr_t)*result, ret, __FUNCTION__);

    
    return ret;
}


static hubbub_error DBTreeCreateComment(void *ctx,
                                        const hubbub_string *data,
                                        void **result)
{
    DBTreeContext *context = ctx;
    hubbub_error ret = HUBBUB_UNKNOWN;
    
    uint32_t nodeElements[commentElementCount];
    nodeElements[kindPosition] = nodeKindComment;
    nodeElements[refcountPosition] = 1;
    
    nodeElements[parentPosition] = 0;
    nodeElements[childrenPosition] = 0;
    
    nodeElements[commentTextPosition] = DBPutUTF8(context, 0, data->ptr, data->len);
    if(nodeElements[commentTextPosition] ) {
        uint32_t resultKey = DBPutNode(context, 0, nodeElements);
        if(resultKey) {
            *result = (void *)(uintptr_t)resultKey;
            ret = HUBBUB_OK;
        }
    }

    //NSLog(@"%ld, %ld, %s", (long)(uintptr_t)*result, ret, __FUNCTION__);
    
    return ret;
}

static hubbub_error DBTreeCreateDoctype(void *ctx,
                                        const hubbub_doctype *doctype,
                                        void **result)
{
    DBTreeContext *context = ctx;
    hubbub_error ret = HUBBUB_UNKNOWN;
    
    uint32_t nodeElements[doctypeElementCount];
    nodeElements[kindPosition] = nodeKindDoctype;
    nodeElements[refcountPosition] = 1;

    nodeElements[parentPosition] = 0;
    nodeElements[childrenPosition] = 0;

    nodeElements[doctypeNamePosition] = DBPutUTF8(context, 0, doctype->name.ptr, doctype->name.len);
    if(nodeElements[doctypeNamePosition]) {
        if(doctype->public_missing) {
            nodeElements[doctypePublicIdPosition] = 0;
        } else {
            nodeElements[doctypePublicIdPosition] = DBPutUTF8(context, 0, doctype->public_id.ptr, doctype->public_id.len);
        }
        if(doctype->public_missing || nodeElements[doctypePublicIdPosition]) {
            if(doctype->system_missing) {
                nodeElements[doctypeSystemIdPosition] = 0;
            } else {
                nodeElements[doctypeSystemIdPosition] = DBPutUTF8(context, 0, doctype->system_id.ptr, doctype->system_id.len);
            }
            if(doctype->system_missing || nodeElements[doctypeSystemIdPosition]) {
                nodeElements[doctypeForceQuirksIdPosition] = (uint32_t)doctype->force_quirks;
                uint32_t resultKey = DBPutNode(context, 0, nodeElements);
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

static hubbub_error DBTreeCreateElement(void *ctx,
                                        const hubbub_tag *tag,
                                        void **result)
{
    DBTreeContext *context = ctx;
    hubbub_error ret = HUBBUB_UNKNOWN;
    
    uint32_t nodeElements[elementElementCount];
    nodeElements[kindPosition] = nodeKindElement;
    nodeElements[refcountPosition] = 1;
    
    nodeElements[parentPosition] = 0;
    nodeElements[childrenPosition] = 0;
    
    nodeElements[elementNamespacePosition] = (int32_t)tag->ns;
    nodeElements[elementNamePosition] = DBPutUTF8(context, 0, tag->name.ptr, tag->name.len);
    if(nodeElements[elementNamePosition]) {
        hubbub_error innerRet = HUBBUB_OK;
        uint32_t attributeCount = tag->n_attributes;
        if(attributeCount) {
            uint32_t attributes[attributeCount];
            

            for(uint32_t i = 0; innerRet == HUBBUB_OK && i < attributeCount; ++i) {
                uint32_t newAttributeKey = DBPutAttribute(context, 0, tag->attributes[i].ns, &(tag->attributes[i].name),  &(tag->attributes[i].value));
                attributes[i] = newAttributeKey;
                if(!newAttributeKey) {
                    innerRet = HUBBUB_UNKNOWN;
                } 
            }
            if(innerRet == HUBBUB_OK) {
                nodeElements[elementAttributesPosition] = DBPutUint32Array(context, 0, attributes, attributeCount);
                if(!nodeElements[elementAttributesPosition]) {
                    innerRet = HUBBUB_UNKNOWN;
                }
            }
        }
        if(innerRet == HUBBUB_OK) {
            uint32_t resultKey = DBPutNode(context, 0, nodeElements);
            if(resultKey) {
                *result = (void *)(uintptr_t)resultKey;
                ret = HUBBUB_OK;
            }            
        } 
    }
    
    //NSLog(@"%ld, %ld, %s", (long)(uintptr_t)*result, ret, __FUNCTION__);

    
    return ret;    
}

static hubbub_error DBTreeCreateText(void *ctx,
                                     const hubbub_string *data,
                                     void **result)
{   
    DBTreeContext *context = ctx;
    hubbub_error ret = HUBBUB_UNKNOWN;
    
    uint32_t nodeElements[textElementCount];
    nodeElements[kindPosition] = nodeKindText;
    nodeElements[refcountPosition] = 1;
    
    nodeElements[parentPosition] = 0;
    nodeElements[childrenPosition] = 0;
        
    nodeElements[textTextPosition] = DBPutUTF8(context, 0, data->ptr, data->len);
    if(nodeElements[textTextPosition]) {
        uint32_t resultKey = DBPutNode(context, 0, nodeElements);
        if(resultKey) {
            *result = (void *)(uintptr_t)resultKey;
            ret = HUBBUB_OK;
        }            
    }
    
    //NSLog(@"%ld, %ld, %s", (long)(uintptr_t)*result, ret, __FUNCTION__);

    
    return ret;    
}

static hubbub_error DBTreeCloneNodeWithNewRefCount(void *ctx,
                                                   uint32_t node,
                                                   uint32_t newParent,
                                                   bool deep,
                                                   uint32_t refCount,
                                                   uint32_t *result) 
{
    DBTreeContext *context = ctx;
    uint32_t key = (uint32_t)(uintptr_t)node;

    hubbub_error ret;
    hubbub_error innerRet = HUBBUB_OK;

    uint32_t *nodeElements;
    ret = DBCopyNode(context, key, &nodeElements);
    if(ret == HUBBUB_OK) {
        nodeElements[refcountPosition] = refCount;
        nodeElements[parentPosition] = newParent;
        if(!deep) {
            nodeElements[childrenPosition] = 0;
        } else {
            if(nodeElements[childrenPosition] != 0) {
                uint32_t *childKeys;
                uint32_t childCount;
                ret = DBCopyUint32Array(context, nodeElements[childrenPosition], &childKeys, &childCount);
                if(ret == HUBBUB_OK) {
                    for(uint32_t i = 0; innerRet == HUBBUB_OK && i < childCount; ++i) {
                        innerRet = DBTreeCloneNodeWithNewRefCount(context,
                                                                  childKeys[i],
                                                                  key,
                                                                  true,
                                                                  0,
                                                                  &childKeys[i]);
                    }
                    if(innerRet == HUBBUB_OK) {
                        nodeElements[childrenPosition] = DBPutUint32Array(context, 0, childKeys, childCount);
                        if(!nodeElements[childrenPosition]) {
                            innerRet == HUBBUB_UNKNOWN;
                        }
                    }
                    free(childKeys);
                }
            }
        }
        
        if(innerRet == HUBBUB_OK) {
            uint32_t resultKey = DBPutNode(context, 0, nodeElements);
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

static hubbub_error DBTreeCloneNode(void *ctx,
                                    void *node,
                                    bool deep,
                                    void **result)
{
    hubbub_error ret;
    uint32_t innerResult = 0;
    ret = DBTreeCloneNodeWithNewRefCount(ctx,
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

static hubbub_error DBTreeRefNode(void *ctx, void *node)
{
    DBTreeContext *context = ctx;
    uint32_t key = (uint32_t)(uintptr_t)node;
    
    hubbub_error ret;
    
    uint32_t *nodeElements;
    ret = DBCopyNode(context, key, &nodeElements);
    if(ret == HUBBUB_OK) {
        ++nodeElements[refcountPosition];
        if(!DBPutNode(context, key, nodeElements)) {
            ret = HUBBUB_UNKNOWN;
        }
        free(nodeElements);
    }

    //NSLog(@"%ld, %ld, %s", (long)(uintptr_t)node, ret, __FUNCTION__);
    
    return ret;
}

static hubbub_error DBTreeRecursiveDeleteNode(void *ctx, uint32_t key, uint32_t *nodeElements) {
    DBTreeContext *context = ctx;
    hubbub_error ret = HUBBUB_UNKNOWN;

    assert(nodeElements[refcountPosition] != 0);
    
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
                if(DBCopyUint32Array(context, nodeElements[elementAttributesPosition], &attributeKeys, &attributeCount) == HUBBUB_OK) {
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
        if(DBCopyUint32Array(context, nodeElements[childrenPosition], &childrenArray, &childrenCount) == HUBBUB_OK) {
            for(uint32_t i = 0; i < childrenCount; ++i) {
                uint32_t *childNodeElements;
                ret = DBCopyNode(context, childrenArray[i], &childNodeElements);
                if(ret == HUBBUB_OK) {
                    DBTreeRecursiveDeleteNode(context, childrenArray[i], childNodeElements);
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

static hubbub_error DBTreeUnrefNode(void *ctx, void *node)
{
    DBTreeContext *context = ctx;
    uint32_t key = (uint32_t)(uintptr_t)node;
    
    hubbub_error ret;
    
    uint32_t *nodeElements;
    ret = DBCopyNode(context, key, &nodeElements);
    if(ret == HUBBUB_OK) {
        if(nodeElements[kindPosition] != nodeKindRoot) {
            --nodeElements[refcountPosition];
            if(nodeElements[refcountPosition] == 0 && 
               !nodeElements[parentPosition]) {
                DBTreeRecursiveDeleteNode(ctx, key, nodeElements);
            } else {
                if(!DBPutNode(context, key, nodeElements)) {
                    ret = HUBBUB_UNKNOWN;
                }
            }
        }
        free(nodeElements);
    }
    
    //NSLog(@"%ld, %ld, %s", (long)(uintptr_t)node, ret, __FUNCTION__);
    
    return ret;
}

static hubbub_error DBTreeInsertBefore(void *ctx, void *parent, void *child, void *childToGoBefore,
                                       void **result)
{
    DBTreeContext *context = ctx;
        
    uint32_t resultKey = 0;
    
    uint32_t parentKey = (uint32_t)(uintptr_t)parent;
    uint32_t childKey = (uint32_t)(uintptr_t)child;
    uint32_t childToGoBeforeKey = (uint32_t)(uintptr_t)childToGoBefore;
    
    hubbub_error ret = HUBBUB_OK;
        
    uint32_t *parentElements;
    ret = DBCopyNode(context, parentKey, &parentElements);
    if(ret == HUBBUB_OK) {
        uint32_t *childElements;
        ret = DBCopyNode(context, childKey, &childElements);
        if(ret == HUBBUB_OK) {        
            
            // If there are no children already, just set the children array to a 
            // one-element array containing the child - easy.
            if(!parentElements[childrenPosition]) {
                parentElements[childrenPosition] = DBPutUint32Array(context, 0, &childKey, 1);
                if(!parentElements[childrenPosition]) {
                    ret = HUBBUB_UNKNOWN;
                } else {
                    if(!DBPutNode(context, parentKey, parentElements)) {
                        ret = HUBBUB_UNKNOWN;
                    } else {
                        ++childElements[refcountPosition];
                        childElements[parentPosition] = parentKey;
                        if(!DBPutNode(context, childKey, childElements)) {
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
                    ret = DBCopyNode(context, childToGoBeforeKey, &childToGoBeforeElements);
                    if(ret == HUBBUB_OK) {
                        if(childToGoBeforeElements[kindPosition] == nodeKindText) {
                            uint8_t *childToGoBeforeString;
                            size_t childToGoBeforeStringLength;
                            ret = DBCopyUTF8(context, childToGoBeforeElements[textTextPosition], &childToGoBeforeString, &childToGoBeforeStringLength);
                            if(ret == HUBBUB_OK) {
                                uint8_t *childString;
                                size_t childStringLength;
                                ret = DBCopyUTF8(context, childElements[textTextPosition], &childString, &childStringLength);
                                if(ret == HUBBUB_OK) {
                                    size_t newLength = childToGoBeforeStringLength + childStringLength;
                                    childString = realloc(childString, newLength);
                                    memcpy(childString + childStringLength, childToGoBeforeString, childToGoBeforeStringLength);
                                    if(!DBPutUTF8(context, childToGoBeforeElements[textTextPosition], childString, newLength)) {
                                        ret = HUBBUB_UNKNOWN;
                                    } else {
                                        ++childToGoBeforeElements[refcountPosition];
                                        if(!DBPutNode(context, childToGoBeforeKey, childToGoBeforeElements)) {
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
                    ret = DBCopyUint32Array(context, parentElements[childrenPosition], &childrenArray, &childrenCount);
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
                            ret = DBCopyNode(context, childToGoAfterKey, &childToGoAfterElements);
                            if(ret == HUBBUB_OK) {
                                if(childToGoAfterElements[kindPosition] == nodeKindText) {
                                    uint8_t *childToGoAfterString;
                                    size_t childToGoAfterStringLength;
                                    ret = DBCopyUTF8(context, childToGoAfterElements[textTextPosition], &childToGoAfterString, &childToGoAfterStringLength);
                                    if(ret == HUBBUB_OK) {
                                        uint8_t *childString;
                                        size_t childStringLength;
                                        ret = DBCopyUTF8(context, childElements[textTextPosition], &childString, &childStringLength);
                                        if(ret == HUBBUB_OK) {
                                            size_t newLength = childToGoAfterStringLength + childStringLength;
                                            childToGoAfterString = realloc(childToGoAfterString, newLength);
                                            memcpy(childToGoAfterString + childToGoAfterStringLength, childString, childStringLength);
                                            if(!DBPutUTF8(context, childToGoAfterElements[textTextPosition], childToGoAfterString, newLength)) {
                                                ret = HUBBUB_UNKNOWN;
                                            } else {
                                                ++childToGoAfterElements[refcountPosition];
                                                if(!DBPutNode(context, childToGoAfterKey, childToGoAfterElements)) {
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
                                if(!DBPutUint32Array(context, parentElements[childrenPosition], childrenArray, newChildrenCount)) {
                                    ret = HUBBUB_UNKNOWN;
                                } else {
                                    ++childElements[refcountPosition];
                                    childElements[parentPosition] = parentKey;
                                    if(!DBPutNode(context, childKey, childElements)) {
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

static hubbub_error DBTreeAppendChild(void *ctx, void *parent, void *child, void **result)
{
    return DBTreeInsertBefore(ctx, parent, child, NULL, result);
}

static hubbub_error DBTreeRemoveChild(void *ctx, void *parent, void *child, void **result)
{
    DBTreeContext *context = ctx;
        
    uint32_t parentKey = (uint32_t)(uintptr_t)parent;
    uint32_t childKey = (uint32_t)(uintptr_t)child;
    
    hubbub_error ret = HUBBUB_OK;
    
    uint32_t *parentElements;
    ret = DBCopyNode(context, parentKey, &parentElements);
    if(ret == HUBBUB_OK) {
        uint32_t *childrenArray;
        uint32_t childrenCount;
        ret = DBCopyUint32Array(context, parentElements[childrenPosition], &childrenArray, &childrenCount);
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
                if(!DBPutUint32Array(context, parentElements[childrenPosition], childrenArray, newChildrenCount)) {
                    ret = HUBBUB_UNKNOWN;
                }
            }
            free(childrenArray);
        }
        
        ret = DBTreeRefNode(ctx, child);
        if(ret == HUBBUB_OK) {
            *result = child;
        }
    }

    //NSLog(@"%ld, %ld, %s", (long)(uintptr_t)*result, ret, __FUNCTION__);
    
    return ret;    
}

static hubbub_error DBTreeReparentChildren(void *ctx, void *fromParent, void *toParent)
{
    DBTreeContext *context = ctx;
    
    uint32_t fromParentKey = (uint32_t)(uintptr_t)fromParent;
    uint32_t toParentKey = (uint32_t)(uintptr_t)toParent;
    
    hubbub_error ret = HUBBUB_OK;
    
    uint32_t *fromParentElements;
    ret = DBCopyNode(context, fromParentKey, &fromParentElements);
    if(ret == HUBBUB_OK) {
        uint32_t *fromChildrenArray;
        uint32_t fromChildrenCount;
        ret = DBCopyUint32Array(context, fromParentElements[childrenPosition], &fromChildrenArray, &fromChildrenCount);
        if(ret == HUBBUB_OK) {
            uint32_t *toParentElements;
            ret = DBCopyNode(context, toParentKey, &toParentElements);
            if(ret == HUBBUB_OK) {
                if(!toParentElements[childrenPosition]) {
                    toParentElements[childrenPosition] = fromParentElements[childrenPosition];
                    if(!DBPutNode(context, toParentKey, toParentElements)) {
                        ret = HUBBUB_UNKNOWN;
                    }
                } else {
                    uint32_t *toChildrenArray;
                    uint32_t toChildrenCount;
                    ret = DBCopyUint32Array(context, toParentElements[childrenPosition], &toChildrenArray, &toChildrenCount);
                    if(ret == HUBBUB_OK) {
                        int32_t appendedChildrenCount = fromChildrenCount + toChildrenCount;
                        toChildrenArray = realloc(toChildrenArray, appendedChildrenCount * sizeof(uint32_t));
                        memcpy(toChildrenArray + toChildrenCount, fromChildrenArray, fromChildrenCount);
                        if(!DBPutUint32Array(context, toParentElements[childrenPosition], toChildrenArray, appendedChildrenCount)) {
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
                    ret = DBCopyNode(context, childKey, &childElements);
                    childElements[parentPosition] = toParentKey;
                    if(!DBPutNode(context, childKey, childElements)) {
                        ret = HUBBUB_UNKNOWN;
                    }
                    free(childElements);
                }
                
                if(ret == HUBBUB_OK) {
                    // Clear out the old parent's children pointer (the actual array 
                    // it refers to has already been either reused of destroyed above).
                    fromParentElements[childrenPosition] = 0;
                    if(!DBPutNode(context, fromParentKey, fromParentElements)) {
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

static hubbub_error DBTreeGetParent(void *ctx, void *node, bool element_only, void **result)
{
    DBTreeContext *context = ctx;
    
    uint32_t resultKey = 0;
    
    uint32_t nodeKey = (uint32_t)(uintptr_t)node;
    hubbub_error ret = HUBBUB_OK;
    uint32_t *nodeElements;
    ret = DBCopyNode(context, nodeKey, &nodeElements);
    if(ret == HUBBUB_OK) {
        if(!element_only || nodeElements[kindPosition] == nodeKindElement) {
            resultKey = nodeElements[parentPosition];
            if(resultKey) {
                ret = DBTreeRefNode(ctx, (void *)(intptr_t)resultKey);
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

static hubbub_error DBTreeHasChildren(void *ctx, void *node, bool *result)
{
    DBTreeContext *context = ctx;
    
    uint32_t nodeKey = (uint32_t)(uintptr_t)node;
    hubbub_error ret = HUBBUB_OK;
    
    uint32_t *nodeElements;
    ret = DBCopyNode(context, nodeKey, &nodeElements);
    if(ret == HUBBUB_OK) {
        *result = (nodeElements[childrenPosition] != 0);
        free(nodeElements);
    }
    
    //NSLog(@"%ld, %ld, %s", (long)(uintptr_t)*result, ret, __FUNCTION__);
    
    return ret;
}

static hubbub_error DBTreeFormAssociate(void *ctx, void *form, void *node)
{
    // We don't care about forms.
    return HUBBUB_OK;
}

static hubbub_error DBTreeAddAttributes(void *ctx, void *node,
                                        const hubbub_attribute *attributes,
                                        uint32_t additionalAttributesCount)
{
    DBTreeContext *context = ctx;
    
    uint32_t nodeKey = (uint32_t)(uintptr_t)node;
    hubbub_error ret = HUBBUB_OK;
    
    uint32_t *nodeElements;
    ret = DBCopyNode(context, nodeKey, &nodeElements);
    if(ret == HUBBUB_OK) {
        assert(nodeElements[kindPosition] == nodeKindElement);
        
        uint32_t oldAttributeCount = 0;
        uint32_t *attributeArray = NULL;
        if(nodeElements[elementAttributesPosition]) {
            ret = DBCopyUint32Array(context, nodeElements[elementAttributesPosition], &attributeArray, &oldAttributeCount);
        }        
        if(ret == HUBBUB_OK) {
            attributeArray = realloc(attributeArray, sizeof(uint32_t) * (additionalAttributesCount + oldAttributeCount));
            
            for(uint32_t i = 0; i < additionalAttributesCount; ++i) {
                for(uint32_t j = 0; j < oldAttributeCount; ++j) {
                    // Ick.  Need to iterate through the old attributes,
                    // looking for identical namespace and tag.  If one 
                    // exists, /don't/ append the new attribute.
                    // This doesn't need to be too efficient - it only seems
                    // to be called when backing off from parse errors.
                }
            }
            
            free(attributeArray);
        }
    }
    
    NSLog(@"%ld, %ld, %s", (long)(uintptr_t)node, ret, __FUNCTION__);
    
    return ret;
}

static hubbub_error DBTreeSetQuirksMode(void *ctx, hubbub_quirks_mode mode)
{
    // We don't care about quirks mode.
    return HUBBUB_OK;
}

static void *HubbubRealloc(void *ptr, size_t len, void *pw)
{
	return realloc(ptr, len);
}

static void TraverseNode(DBTreeContext *context, uint32_t key, uint32_t indent)
{
    uint32_t *node;
    DBCopyNode(context, key, &node);
    
    
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
                DBCopyUTF8(context, node[commentTextPosition], &text, &textLength);
                printf(": \"%*s\"", (int)textLength, text);
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
                DBCopyUTF8(context, node[elementNamePosition], &text, &textLength);
                printf(": <%*s>", (int)textLength, text);
                free(text);
            }
            break;
        case nodeKindText:          
            {
                uint8_t* text;
                size_t textLength;
                DBCopyUTF8(context, node[textTextPosition], &text, &textLength);
                printf(": \"%*s\"", (int)textLength, text);
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
        DBCopyUint32Array(context, childrenKey, &children, &childCount);
        for(uint32_t i = 0; i < childCount; ++i) {
            TraverseNode(context, children[i], indent + 2);
        }
    } 

}

static void Traverse(DBTreeContext *context)
{
    TraverseNode(context, context->rootNodeKey, 0);
}

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    BOOL hubbubInitialised = NO;
    const ssize_t chunkSize = 4096;
    uint8_t buffer[chunkSize];

    hubbub_error err;
    err = hubbub_initialise(argv[1], HubbubRealloc, NULL);
    if(err != HUBBUB_OK) {
        NSLog(@"Error \"%s\" setting up hubbub", hubbub_error_to_string(err));
        goto bail;
    } else {
        hubbubInitialised = YES;
    }

    hubbub_parser *parser = NULL;
    err = hubbub_parser_create(NULL, true, HubbubRealloc, NULL, &parser);
    if(err != HUBBUB_OK) {
        NSLog(@"Error \"%s\" creating parser", hubbub_error_to_string(err));
        goto bail;
    }

    DBTreeContext context = DBTreeInit();
        
    hubbub_tree_handler treeHandler = {
        DBTreeCreateComment,
        DBTreeCreateDoctype,
        DBTreeCreateElement,
        DBTreeCreateText,
        DBTreeRefNode,
        DBTreeUnrefNode,
        DBTreeAppendChild,
        DBTreeInsertBefore,
        DBTreeRemoveChild,
        DBTreeCloneNode,
        DBTreeReparentChildren,
        DBTreeGetParent,
        DBTreeHasChildren,
        DBTreeFormAssociate,
        DBTreeAddAttributes,
        DBTreeSetQuirksMode,
        NULL,
        &context
    };
    
    hubbub_parser_optparams params;
	params.tree_handler = &treeHandler;
	err = hubbub_parser_setopt(parser, HUBBUB_PARSER_TREE_HANDLER, &params);
    if(err != HUBBUB_OK) {
        NSLog(@"Error \"%s\" setting option on parser", hubbub_error_to_string(err));
        goto bail;
    }
    
    params.document_node = (void *)(intptr_t)context.rootNodeKey;
	assert(hubbub_parser_setopt(parser, HUBBUB_PARSER_DOCUMENT_NODE,
                                &params) == HUBBUB_OK);
    
    
    FILE *fp = fopen(argv[2], "rb");
	if (fp == NULL) {
		printf("Failed opening %s\n", argv[2]);
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
            NSLog(@"Error \"%s\" during parse", hubbub_error_to_string(err));
            goto bail;
        }
	}

    hubbub_charset_source cssource = 0;
	const char *charset = hubbub_parser_read_charset(parser, &cssource);
    
	NSLog(@"Charset: %s (from %d)\n", charset, cssource);    
    Traverse(&context);

bail:
    if(fp) {
        fclose(fp);
    }
    if(parser) {
        hubbub_parser_destroy(parser);
    }
    
    DBTreeClose(&context);
    
    if(hubbubInitialised) {
        hubbub_finalise(HubbubRealloc, NULL);
    }
    
    [pool drain];
    return 0;
}
