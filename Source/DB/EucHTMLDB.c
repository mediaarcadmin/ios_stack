/*
 *  EucHTMLDB.c
 *  LibCSSTest
 *
 *  Created by James Montgomerie on 06/12/2009.
 *  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
 *
 */

#include "EucHTMLDB.h"
#include <CoreFoundation/CoreFoundation.h>

size_t sNodeElementCounts[] = 
{ 
    rootElementCount,
    doctypeElementCount, 
    commentElementCount,
    elementElementCount,
    textElementCount
};

static uint32_t EucHTMLDBPutBytes(EucHTMLDB *context, uint32_t key, const void *bytes, size_t length)
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

static hubbub_error EucHTMLDBCopyBytes(EucHTMLDB *context, uint32_t key, void **bytesOut, size_t *lengthOut)
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

uint32_t EucHTMLDBPutUint32Array(EucHTMLDB *context, uint32_t key, const uint32_t *keyArray, uint32_t count)
{
    if(CFByteOrderGetCurrent() == CFByteOrderBigEndian) {
        uint32_t *swappedKeys = alloca(count);
        for(uint32_t i = 0; i < count; ++i) {
            swappedKeys[i] = CFSwapInt32HostToLittle(keyArray[i]);
        }
        keyArray = swappedKeys;
    }
    return EucHTMLDBPutBytes(context, key, keyArray, count * sizeof(uint32_t));
}

hubbub_error EucHTMLDBCopyUint32Array(EucHTMLDB *context, uint32_t key, uint32_t **keyArrayOut, uint32_t *countOut)
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

uint32_t EucHTMLDBPutUTF8(EucHTMLDB *context, uint32_t key, const uint8_t *string, size_t length)
{
    return EucHTMLDBPutBytes(context, key, string, length);
}

hubbub_error EucHTMLDBCopyUTF8(EucHTMLDB *context, uint32_t key, uint8_t **string, size_t *length)
{
    return EucHTMLDBCopyBytes(context, key, (void **)string, length);
}


hubbub_error EucHTMLDBCopyLWCString(EucHTMLDB *context, uint32_t key, lwc_context *lwcContext, lwc_string **string)
{    
    hubbub_error ret = HUBBUB_UNKNOWN;
    
    key = CFSwapInt32HostToLittle(key); // Should be a no-op on ARM.
    const DBT keyThang = 
    { 
        &key, 
        sizeof(uint32_t) 
    };    
    DBT valueThang = { 0 };
    

    DB *db = context->db;
    if(db->get(db, &keyThang, &valueThang, 0) == 0) {
        lwc_string *str;
        if(lwc_context_intern(lwcContext, valueThang.data, valueThang.size, &str) == lwc_error_ok) {
            ret = HUBBUB_OK;
            *string = str;
        }
    }
    
    return ret;
}

uint32_t EucHTMLDBPutNode(EucHTMLDB *context, uint32_t key, const uint32_t *node)
{
    
    return EucHTMLDBPutUint32Array(context, key, node, sNodeElementCounts[node[kindPosition]]);
}

hubbub_error EucHTMLDBCopyNode(EucHTMLDB *context, uint32_t key, uint32_t **node)
{
    uint32_t count;
    hubbub_error ret = EucHTMLDBCopyUint32Array(context, key, node, &count);
    assert(count == sNodeElementCounts[(*node)[kindPosition]]);
    return ret;
}

hubbub_error DBDeleteValueForKey(EucHTMLDB *context, uint32_t key)
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

uint32_t EucHTMLDBPutAttribute(EucHTMLDB *context, uint32_t key, hubbub_ns ns, const hubbub_string* name, const hubbub_string* value)
{
    uint32_t attributeArray[3];
    attributeArray[0] = ns;
    if((attributeArray[1] = EucHTMLDBPutUTF8(context, 0, name->ptr, name->len)) &&
       (attributeArray[2] = EucHTMLDBPutUTF8(context, 0, value->ptr, value->len))) {
        return EucHTMLDBPutUint32Array(context, key, attributeArray, 3);
    } else {
        return 0;
    }
}

hubbub_error EucHTMLDBCopyAttribute(EucHTMLDB *context, uint32_t key, hubbub_ns *ns, hubbub_string* name, hubbub_string* value)
{
    uint32_t *attributeArray;
    uint32_t count;
    hubbub_error ret = EucHTMLDBCopyUint32Array(context, key, &attributeArray, &count);
    if(ret == HUBBUB_OK) {
        assert(count == 3);
        *ns = attributeArray[0];
        ret = EucHTMLDBCopyUTF8(context, attributeArray[1], (uint8_t **)&(name->ptr), &(name->len));
        if(ret == HUBBUB_OK) {
            ret = EucHTMLDBCopyUTF8(context, attributeArray[2], (uint8_t **)&(value->ptr), &(value->len));
        }
        free(attributeArray);
    }
    return ret;
}

hubbub_error DBRemoveAttribute(EucHTMLDB *context, uint32_t key) 
{
    uint32_t *attributeArray;
    uint32_t count;
    hubbub_error ret = EucHTMLDBCopyUint32Array(context, key, &attributeArray, &count);
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

void *EucRealloc(void *ptr, size_t len, void *pw)
{
	return realloc(ptr, len);
}


EucHTMLDB *EucHTMLDBOpen(char *path, int flags) 
{
    EucHTMLDB *context = calloc(1, sizeof(EucHTMLDB));
    
    hubbub_error err = HUBBUB_OK;
    
    BTREEINFO openInfo = { 0 };
    openInfo.lorder = 1234;
    /*
     HASHINFO openInfo = { 0 };
     openInfo.lorder = 1234;
     */
    context->db = dbopen(path, flags, 0644, DB_BTREE, &openInfo);
    if(!context->db) {
        err = HUBBUB_UNKNOWN;
        fprintf(stderr, "Error \"%ld\" opening database at \"%s\"\n", (long)errno, path);
    }    
    
    if(err != HUBBUB_OK) {
        unlink(path);
        free(context);
        context = NULL;
    }
    return context;
}

void EucHTMLDBClose(EucHTMLDB *context)
{
    context->db->close(context->db);
    free(context);
}

