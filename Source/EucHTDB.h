/*
 *  EucHTDB.h
 *  LibCSSTest
 *
 *  Created by James Montgomerie on 06/12/2009.
 *  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
 *
 */

#include <stdint.h>
#include <db.h>
#include <fcntl.h>
#include <limits.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

#include <hubbub/hubbub.h>
#include <hubbub/parser.h>

enum EucHTDBNodeKinds
{
    nodeKindRoot = 0,
    nodeKindDoctype,
    nodeKindComment,
    nodeKindElement,
    nodeKindText
};

enum EucHTDBNodeArrayPositions
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

extern size_t sNodeElementCounts[];

typedef struct EucHTDB
{
    DB *db;
    uint32_t nodeCount;
    uint32_t rootNodeKey;
} EucHTDB;

void *EucRealloc(void *ptr, size_t len, void *pw);

// 'flags' are flags ass pased to open().
// e.g. O_CREAT | O_RDWR | O_TRUNC to create a new HTDP to write into.
//      O_RDONLY to read an existing tree.
EucHTDB *EucHTDBOpen(char *path, int flags);
void EucHTDBClose(EucHTDB *context);

uint32_t EucHTDBPutUint32Array(EucHTDB *context, uint32_t key, const uint32_t *keyArray, uint32_t count);
hubbub_error EucHTDBCopyUint32Array(EucHTDB *context, uint32_t key, uint32_t **keyArrayOut, uint32_t *countOut);

uint32_t EucHTDBPutUTF8(EucHTDB *context, uint32_t key, const uint8_t *string, size_t length);
hubbub_error EucHTDBCopyUTF8(EucHTDB *context, uint32_t key, uint8_t **string, size_t *length);

uint32_t EucHTDBPutNode(EucHTDB *context, uint32_t key, const uint32_t *node);
hubbub_error EucHTDBCopyNode(EucHTDB *context, uint32_t key, uint32_t **node);

hubbub_error DBDeleteValueForKey(EucHTDB *context, uint32_t key);

uint32_t EucHTDBPutAttribute(EucHTDB *context, uint32_t key, hubbub_ns ns, const hubbub_string* name, const hubbub_string* value);
hubbub_error EucHTDBCopyAttribute(EucHTDB *context, uint32_t key, hubbub_ns *ns, hubbub_string* name, hubbub_string* value);
hubbub_error DBRemoveAttribute(EucHTDB *context, uint32_t key);

