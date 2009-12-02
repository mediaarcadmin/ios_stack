#import <Foundation/Foundation.h>

#include <hubbub/hubbub.h>
#include <hubbub/parser.h>

#include <db.h>

enum ElementArrayPositions
{
    kindPosition = 0,
    refcountPosition,
    parentPosition,
    childrenPosition,
    contentPositions
};

static CFNumberRef sNodeKindDoctype = NULL;
static CFNumberRef sNodeKindComment = NULL;
static CFNumberRef sNodeKindElement = NULL;
static CFNumberRef sNodeKindText = NULL;

static CFNumberRef sNumber0 = NULL;
static CFNumberRef sNumber1 = NULL;


typedef struct DBTreeContext
{
    DB *db;
    uint32_t nodeCount;
} DBTreeContext;

static DBTreeContext DBTreeInit() 
{
    if(!sNodeKindDoctype) {
        int32_t number = 0;
        sNodeKindDoctype = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &number);
        ++number;
        sNodeKindComment = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &number);
        ++number;
        sNodeKindElement = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &number);
        ++number;
        sNodeKindText = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &number);
        
        number = 0;
        sNumber0 = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &number);
        number = 1;
        sNumber1 = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &number);
    }
    
    DB *db;
    
    BTREEINFO openInfo = { 0 };
    openInfo.lorder = 1234;
    db = dbopen(NULL, O_RDWR | O_TRUNC, 0644, DB_BTREE, &openInfo);
    
    DBTreeContext ret = { db, 0 };
    return ret;
}

static void * hubbubRealloc(void *ptr, size_t size, void *pw)
{
    return realloc(ptr, size);
}

static hubbub_error DBPutElement(DB *db, CFPropertyListRef element, uint32_t key) 
{
    key = CFSwapInt32HostToLittle(key); // Should be a no-op on ARM.
    const DBT keyThang = 
    { 
        &key, 
        sizeof(uint32_t) 
    };
    
    CFDataRef serialised = CFPropertyListCreateData(kCFAllocatorDefault,
                                                    element, 
                                                    kCFPropertyListBinaryFormat_v1_0, 
                                                    0, NULL);
    const DBT valueThang = 
    {
        (void *)CFDataGetBytePtr(serialised), 
        CFDataGetLength(serialised)
    };
    
    // Seems a little weird that the key is not defined as const for this 
    // call.  We rely on it being so nevertheless.
    int ret = db->put(db, (DBT *)&keyThang, &valueThang, 0);
    
    CFRelease(serialised);
    
    return ret == 0 ? HUBBUB_OK : HUBBUB_UNKNOWN;
}

static hubbub_error DBPutCArray(DB *db, const void **array, CFIndex count, uint32_t key) 
{
    hubbub_error ret = HUBBUB_UNKNOWN;
    CFArrayRef toStore = CFArrayCreate(kCFAllocatorDefault, (const void **)array, count, &kCFTypeArrayCallBacks);
    if(toStore) {
        ret = DBPutElement(db, toStore, key);
        CFRelease(toStore);     
    }
    return ret;
}

static CFPropertyListRef DBCopyElement(DB *db, uint32_t key) 
{
    CFPropertyListRef ret = NULL;
    
    key = CFSwapInt32HostToLittle(key); // Should be a no-op on ARM.
    const DBT keyThang = 
    { 
        &key, 
        sizeof(uint32_t) 
    };
    
    DBT valueThang;
    if(db->get(db, &keyThang, &valueThang, 0) == 0) {
        CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, 
                                                     valueThang.data, 
                                                     valueThang.size, 
                                                     kCFAllocatorNull);
        ret = CFPropertyListCreateWithData(kCFAllocatorDefault, 
                                           data,
                                           0, 
                                           NULL, 
                                           NULL);
        CFRelease(data);
    }
    
    return ret;
}

static hubbub_error DBRemoveElement(DB *db, uint32_t key)
{
    key = CFSwapInt32HostToLittle(key); // Should be a no-op on ARM.
    key = CFSwapInt32HostToLittle(key); // Should be a no-op on ARM.
    const DBT keyThang = 
    { 
        &key, 
        sizeof(uint32_t) 
    };
    
    return db->del(db, &keyThang, 0) == 0 ? HUBBUB_OK : HUBBUB_UNKNOWN;
}

static CFDictionaryRef DBTreeCreateDictionaryFromHubbubAttributes(uint32_t nAttributes, hubbub_attribute *attributes) 
{
    CFArrayRef *keys; // [namespace, key] arrays.
    CFStringRef *values;
    if(nAttributes > 16) {
        keys = malloc(nAttributes * sizeof(CFStringRef));
        values = malloc(nAttributes * sizeof(CFStringRef));
    } else {
        keys = alloca(nAttributes * sizeof(CFStringRef));
        values = alloca(nAttributes * sizeof(CFStringRef));
    }
    
    for(uint32_t i = 0; i < nAttributes; ++i) {
        int32_t ns32 = attributes[i].ns;
        CFNumberRef keyNamespace = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &ns32);
        CFStringRef keyName =  CFStringCreateWithBytes(kCFAllocatorDefault,
                                                       attributes[i].name.ptr,
                                                       attributes[i].name.len, 
                                                       kCFStringEncodingUTF8, 
                                                       NO);
        const void const *arrayElements[2] = { keyNamespace, keyName };
        keys[i] = CFArrayCreate(kCFAllocatorDefault, arrayElements, 2, &kCFTypeArrayCallBacks);
        CFRelease(keyNamespace);
        CFRelease(keyName);
        
        values[i] = CFStringCreateWithBytes(kCFAllocatorDefault,
                                            attributes[i].value.ptr,
                                            attributes[i].value.len, 
                                            kCFStringEncodingUTF8, 
                                            NO);
    }
    
    CFDictionaryRef ret = CFDictionaryCreate(kCFAllocatorDefault,
                                             (const void **)keys,
                                             (const void **)values, 
                                             nAttributes, 
                                             &kCFTypeDictionaryKeyCallBacks,
                                             &kCFTypeDictionaryValueCallBacks);
    
    for(uint32_t i = 0; i < nAttributes; ++i) {
        CFRelease(keys[i]);
        CFRelease(values[i]);
    }
    
    if(nAttributes > 16) {
        free(keys);
        free(values);
    }
    
    return ret;
}


static hubbub_error DBTreeCreateComment(void *ctx,
                                        const hubbub_string *data,
                                        void **result)
{
    hubbub_error ret = HUBBUB_UNKNOWN;
    
    DBTreeContext *context = ctx;
    
    void const *nodeElements[contentPositions + 1];
    nodeElements[kindPosition] = sNodeKindComment;
    nodeElements[refcountPosition] = sNumber1;
    
    nodeElements[parentPosition] = kCFNull;
    nodeElements[childrenPosition] = kCFNull;
    
    nodeElements[contentPositions + 0] = CFStringCreateWithBytesNoCopy(kCFAllocatorDefault, 
                                                    data->ptr, 
                                                    data->len, 
                                                    kCFStringEncodingUTF8, 
                                                    NO, 
                                                    kCFAllocatorNull);
    if(nodeElements[contentPositions + 0]) {
        ret = DBPutCArray(context->db, nodeElements, sizeof(nodeElements), context->nodeCount);
        if(ret == HUBBUB_OK) {
            *result = (void *)(uintptr_t)(context->nodeCount++);
        }
        CFRelease(nodeElements[contentPositions + 0]);
    }
        
    return ret;
}

static hubbub_error DBTreeCreateDoctype(void *ctx,
                                        const hubbub_doctype *data,
                                        void **result)
{
    hubbub_error ret = HUBBUB_UNKNOWN;
    
    DBTreeContext *context = ctx;
    
    void const *nodeElements[contentPositions + 4];
    nodeElements[kindPosition] = sNodeKindDoctype;
    nodeElements[refcountPosition] = sNumber1;

    nodeElements[parentPosition] = kCFNull;
    nodeElements[childrenPosition] = kCFNull;

    nodeElements[contentPositions + 0] = CFStringCreateWithBytesNoCopy(kCFAllocatorDefault, 
                                                    data->name.ptr, 
                                                    data->name.len, 
                                                    kCFStringEncodingUTF8, 
                                                    NO, 
                                                    kCFAllocatorNull);
    if(nodeElements[contentPositions + 0]) {
        if(data->public_missing) {
            nodeElements[contentPositions + 1] = CFRetain(kCFNull);
        } else {
            nodeElements[contentPositions + 1] = CFStringCreateWithBytesNoCopy(kCFAllocatorDefault, 
                                                            data->public_id.ptr, 
                                                            data->public_id.len, 
                                                            kCFStringEncodingUTF8, 
                                                            NO, 
                                                            kCFAllocatorNull);
        }
        if(nodeElements[contentPositions + 1]) {
            if(data->system_missing) {
                nodeElements[contentPositions + 2] = CFRetain(kCFNull);
            } else {
                nodeElements[contentPositions + 2] = CFStringCreateWithBytesNoCopy(kCFAllocatorDefault, 
                                                                data->system_id.ptr, 
                                                                data->system_id.len, 
                                                                kCFStringEncodingUTF8, 
                                                                NO, 
                                                                kCFAllocatorNull);
            }
            if(nodeElements[contentPositions + 2]) {
                nodeElements[contentPositions + 3] = data->force_quirks ? kCFBooleanTrue : kCFBooleanFalse;
                ret = DBPutCArray(context->db, nodeElements, sizeof(nodeElements), context->nodeCount);
                if(ret == HUBBUB_OK) {
                    *result = (void *)(uintptr_t)(context->nodeCount++);
                }                
                CFRelease(nodeElements[contentPositions + 2]);
            }
            CFRelease(nodeElements[contentPositions + 1]);
        }
        CFRelease(nodeElements[contentPositions + 0]);
    }
    
    return ret;
}


static hubbub_error DBTreeCreateElement(void *ctx,
                                        const hubbub_tag *tag,
                                        void **result)
{
    hubbub_error ret = HUBBUB_UNKNOWN;

    DBTreeContext *context = ctx;
    
    void const *nodeElements[contentPositions + 3];
    nodeElements[kindPosition] = sNodeKindElement;
    nodeElements[refcountPosition] = sNumber1;
    
    nodeElements[parentPosition] = kCFNull;
    nodeElements[childrenPosition] = kCFNull;
    
    int32_t ns32 = (int32_t)tag->ns;
    nodeElements[contentPositions + 0] = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &ns32);
    if(nodeElements[contentPositions + 0]) {
        nodeElements[contentPositions + 1] = CFStringCreateWithBytesNoCopy(kCFAllocatorDefault, 
                                                        tag->name.ptr, 
                                                        tag->name.len, 
                                                        kCFStringEncodingUTF8, 
                                                        NO, 
                                                        kCFAllocatorNull);
        if(nodeElements[contentPositions + 1]) {
            nodeElements[contentPositions + 2] = DBTreeCreateDictionaryFromHubbubAttributes(tag->n_attributes, tag->attributes);
            if(nodeElements[contentPositions + 2]) {
                ret = DBPutCArray(context->db, nodeElements, sizeof(nodeElements), context->nodeCount);
                if(ret == HUBBUB_OK) {
                    *result = (void *)(uintptr_t)(context->nodeCount++);
                }                
                CFRelease(nodeElements[contentPositions + 2]);                
            }
            CFRelease(nodeElements[contentPositions + 1]);
        }
        CFRelease(nodeElements[contentPositions + 0]);
    }
    
    return ret;    
}

static hubbub_error DBTreeCreateText(void *ctx,
                                     const hubbub_string *data,
                                     void **result)
{   
    hubbub_error ret = HUBBUB_UNKNOWN;
    
    DBTreeContext *context = ctx;
    
    void const *nodeElements[contentPositions + 1];
    nodeElements[kindPosition] = sNodeKindElement;
    nodeElements[refcountPosition] = sNumber1;
    
    nodeElements[parentPosition] = kCFNull;
    nodeElements[childrenPosition] = kCFNull;
    
    
    nodeElements[contentPositions + 0] = CFStringCreateWithBytesNoCopy(kCFAllocatorDefault, 
                                                     data->ptr, 
                                                     data->len, 
                                                     kCFStringEncodingUTF8, 
                                                     NO, 
                                                     kCFAllocatorNull);
    if(nodeElements[contentPositions + 0]) {
        ret = DBPutCArray(context->db, nodeElements, sizeof(nodeElements), context->nodeCount);
        if(ret == HUBBUB_OK) {
            *result = (void *)(uintptr_t)(context->nodeCount++);
        }                
        CFRelease(nodeElements[contentPositions + 0]);
    }
    
    return ret;    
}

static hubbub_error DBTreeCloneNodeWithNewRefCount(void *ctx,
                                                   uint32_t node,
                                                   bool deep,
                                                   uint32_t refCount,
                                                   uint32_t *result) 
{
    DBTreeContext *context = ctx;
    uint32_t key = (uint32_t)(uintptr_t)node;
    
    hubbub_error ret = HUBBUB_UNKNOWN;
    hubbub_error innerRet = HUBBUB_OK;

    CFArrayRef newChildren;
    CFArrayRef nodeArray = (CFArrayRef)DBCopyElement(context->db, key);
    if(nodeArray) {
        CFIndex count = CFArrayGetCount(nodeArray);
        void const *nodeElements[count];
        CFArrayGetValues(nodeArray, CFRangeMake(0, count), nodeElements);
        
        nodeElements[refcountPosition] = refCount == 1 ? sNumber1 : sNumber0;
        if(!deep) {
            nodeElements[parentPosition] = kCFNull;
            nodeElements[childrenPosition] = kCFNull;
        } else {
            nodeElements[parentPosition] = kCFNull;
            if(nodeElements[childrenPosition] != kCFNull) {
                CFIndex childCount = CFArrayGetCount(nodeElements[childrenPosition]);
                void const *newChildrenElements[childCount];
                memset(newChildrenElements, 0, sizeof(void *));
                CFIndex i = 0;
                for(; i < childCount; ++i) {
                    CFNumberRef childNumber = CFArrayGetValueAtIndex(nodeElements[childrenPosition], i);
                    uint32_t oldChildKey;
                    CFNumberGetValue(childNumber, kCFNumberSInt32Type, &oldChildKey);
                    uint32_t newChildKey;
                    hubbub_error innerRet = DBTreeCloneNodeWithNewRefCount(ctx,
                                                                           oldChildKey,
                                                                           true,
                                                                           0,
                                                                           &newChildKey);
                    if(innerRet == HUBBUB_OK) { 
                        newChildrenElements[i] = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &newChildKey);
                    }
                }
                if(innerRet == HUBBUB_OK) {
                    newChildren = CFArrayCreate(kCFAllocatorDefault, newChildrenElements, i, &kCFTypeArrayCallBacks);
                    nodeElements[childrenPosition] = newChildren;
                }
                for(CFIndex j = 0; j < i; ++j) {
                    CFRelease((CFTypeRef)newChildrenElements[j]);
                }
            }
        }
        
        if(innerRet == HUBBUB_OK) {
            ret = DBPutCArray(context->db, nodeElements, count, context->nodeCount);
            if(ret == HUBBUB_OK) {
                *result = context->nodeCount++;
            }   
        } else {
            ret = innerRet;
        }
        CFRelease(nodeArray);
    } 
    if(newChildren) {
        CFRelease(newChildren);
    }
    
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
                                         deep,
                                         1,
                                         &innerResult);
    if(ret == HUBBUB_OK) {
        *result = (void *)(intptr_t)result;
    }
    return ret;
}


static hubbub_error DBTreeRefNode(void *ctx, void *node)
{
    DBTreeContext *context = ctx;
    uint32_t key = (uint32_t)(uintptr_t)node;
    
    hubbub_error ret = HUBBUB_UNKNOWN;

    CFArrayRef nodeArray = (CFArrayRef)DBCopyElement(context->db, key);
    if(nodeArray) {
        uint32_t refcount;
        CFNumberGetValue(CFArrayGetValueAtIndex(nodeArray, refcountPosition), kCFNumberSInt32Type, &refcount);
        ++refcount;
        CFNumberRef newValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &refcount);
        CFMutableArrayRef newNodeArray = CFArrayCreateMutableCopy(kCFAllocatorDefault, CFArrayGetCount(nodeArray), nodeArray);
        CFArraySetValueAtIndex(newNodeArray, refcount, newValue);
        CFRelease(newValue);
        ret = DBPutElement(context->db, newNodeArray, key);
        CFRelease(newNodeArray);
    }
    
    return ret;
}


static hubbub_error DBTreeDeleteRecursive(void *ctx, uint32_t key, CFArrayRef nodeArray)
{
    DBTreeContext *context = ctx;
    
    hubbub_error ret = HUBBUB_OK;

    CFTypeRef children = CFArrayGetValueAtIndex(nodeArray, childrenPosition);
    if(children != kCFNull) {
        CFIndex childCount = CFArrayGetCount(children);
        for(CFIndex i = 0; ret == HUBBUB_OK && i < childCount; ++i) {
            uint32_t childKey;
            CFNumberGetValue(CFArrayGetValueAtIndex(children, i), kCFNumberSInt32Type, &childKey);
            CFArrayRef childNodeArray = (CFArrayRef)DBCopyElement(context->db, key);
            ret = DBTreeDeleteRecursive(ctx, childKey, childNodeArray);
        }
    }
    if(ret == HUBBUB_OK) {
        ret = DBRemoveElement(context->db, key);
    }
    return ret;
}



static hubbub_error DBTreeUnrefNode(void *ctx, void *node)
{
    DBTreeContext *context = ctx;
    
    uint32_t key = (uint32_t)(uintptr_t)node;
    
    hubbub_error ret = HUBBUB_UNKNOWN;
    
    CFArrayRef nodeArray = (CFArrayRef)DBCopyElement(context->db, key);
    if(nodeArray) {
        uint32_t refcount;
        CFNumberGetValue(CFArrayGetValueAtIndex(nodeArray, refcountPosition), kCFNumberSInt32Type, &refcount);
        if(refcount == 1 && 
           CFArrayGetValueAtIndex(nodeArray, parentPosition) == kCFNull) {
            DBTreeDeleteRecursive(ctx, key, nodeArray);
        } else {
            --refcount;
            CFNumberRef newValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &refcount);
            CFMutableArrayRef newNodeArray = CFArrayCreateMutableCopy(kCFAllocatorDefault, CFArrayGetCount(nodeArray), nodeArray);
            CFArraySetValueAtIndex(newNodeArray, refcount, newValue);
            CFRelease(newValue);
            ret = DBPutElement(context->db, newNodeArray, key);
            CFRelease(newNodeArray);
        }
    }
    
    return ret;
}

static hubbub_error appendChild(void *ctx, void *parent, void *child, void **result)
{
    DBTreeContext *context = ctx;
    
    uint32_t parentKey = (uint32_t)(uintptr_t)parent;
    uint32_t childKey = (uint32_t)(uintptr_t)child;
    
    hubbub_error ret = HUBBUB_UNKNOWN;
    
    CFArrayRef parentArray = (CFArrayRef)DBCopyElement(context->db, parentKey);
    CFArrayRef childArray = (CFArrayRef)DBCopyElement(context->db, childKey);
    if(parentArray && childArray) {
        if(CFEqual(CFArrayGetValueAtIndex(parentArray, kindPosition), sNodeKindText) && 
           CFEqual(CFArrayGetValueAtIndex(childArray, kindPosition), sNodeKindText)) {
            
        } else {
            
        }
    }
    return ret;
}

static hubbub_error insertBefore(void *ctx, void *parent, void *child, void *ref_child,
                                  void **result);
static hubbub_error removeChild(void *ctx, void *parent, void *child, void **result);
static hubbub_error cloneNode(void *ctx, void *node, bool deep, void **result);
static hubbub_error reparentChildren(void *ctx, void *node, void *new_parent);
static hubbub_error getParent(void *ctx, void *node, bool element_only, void **result);
static hubbub_error hasChildren(void *ctx, void *node, bool *result);
static hubbub_error formAssociate(void *ctx, void *form, void *node);
static hubbub_error addAttributes(void *ctx, void *node,
                                   const hubbub_attribute *attributes, uint32_t n_attributes);
static hubbub_error setQuirksMode(void *ctx, hubbub_quirks_mode mode);



int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    BOOL hubbubInitialised = NO;
    const ssize_t chunkSize = 4096;
    uint8_t buffer[chunkSize];

    hubbub_error err;
    err = hubbub_initialise(argv[1], hubbubRealloc, NULL);
    if(err != HUBBUB_OK) {
        NSLog(@"Error \"%s\" setting up hubbub", hubbub_error_to_string(err));
        goto bail;
    } else {
        hubbubInitialised = YES;
    }

    
    hubbub_parser *parser = NULL;
    err = hubbub_parser_create(NULL, true, hubbubRealloc, NULL, &parser);
    if(err != HUBBUB_OK) {
        NSLog(@"Error \"%s\" creating parser", hubbub_error_to_string(err));
        goto bail;
    }

    hubbub_parser_optparams params;
    params.token_handler.handler = token_handler;
	params.token_handler.pw = NULL;
	err = hubbub_parser_setopt(parser, HUBBUB_PARSER_TOKEN_HANDLER, &params);
    if(err != HUBBUB_OK) {
        NSLog(@"Error \"%s\" setting option on parser", hubbub_error_to_string(err));
        goto bail;
    }
    
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
    
bail:
    if(fp) {
        fclose(fp);
    }
    if(parser) {
        hubbub_parser_destroy(parser);
    }
    if(hubbubInitialised) {
        hubbub_finalise(hubbubRealloc, NULL);
    }
    
    [pool drain];
    return 0;
}
