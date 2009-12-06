/*
 *  EucHTMLDB.h
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

enum EucHTMLDBNodeKinds
{
    nodeKindRoot = 0,
    nodeKindDoctype,
    nodeKindComment,
    nodeKindElement,
    nodeKindText
};

enum EucHTMLDBNodeArrayPositions
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

typedef struct EucHTMLDB
{
    DB *db;
    uint32_t nodeCount;
    uint32_t rootNodeKey;
} EucHTMLDB;

void *EucRealloc(void *ptr, size_t len, void *pw);

// 'flags' are flags ass pased to open().
// e.g. O_CREAT | O_RDWR | O_TRUNC to create a new HTDP to write into.
//      O_RDONLY to read an existing tree.
EucHTMLDB *EucHTMLDBOpen(char *path, int flags);
void EucHTMLDBClose(EucHTMLDB *context);

uint32_t EucHTMLDBPutUint32Array(EucHTMLDB *context, uint32_t key, const uint32_t *keyArray, uint32_t count);
hubbub_error EucHTMLDBCopyUint32Array(EucHTMLDB *context, uint32_t key, uint32_t **keyArrayOut, uint32_t *countOut);

uint32_t EucHTMLDBPutUTF8(EucHTMLDB *context, uint32_t key, const uint8_t *string, size_t length);
hubbub_error EucHTMLDBCopyUTF8(EucHTMLDB *context, uint32_t key, uint8_t **string, size_t *length);

uint32_t EucHTMLDBPutNode(EucHTMLDB *context, uint32_t key, const uint32_t *node);
hubbub_error EucHTMLDBCopyNode(EucHTMLDB *context, uint32_t key, uint32_t **node);

hubbub_error DBDeleteValueForKey(EucHTMLDB *context, uint32_t key);

uint32_t EucHTMLDBPutAttribute(EucHTMLDB *context, uint32_t key, hubbub_ns ns, const hubbub_string* name, const hubbub_string* value);
hubbub_error EucHTMLDBCopyAttribute(EucHTMLDB *context, uint32_t key, hubbub_ns *ns, hubbub_string* name, hubbub_string* value);
hubbub_error DBRemoveAttribute(EucHTMLDB *context, uint32_t key);

