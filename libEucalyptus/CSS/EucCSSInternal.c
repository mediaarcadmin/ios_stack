/*
 *  EucCSSInternal.c
 *  LibCSSTest
 *
 *  Created by James Montgomerie on 10/03/2010.
 *  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
 *
 */

#include "EucCSSInternal.h"
#include <stdlib.h>

void *EucRealloc(void *ptr, size_t len, void *pw)
{
    if(len == 0) {
        free(ptr);
        return NULL;
    } else {
        return realloc(ptr, len);
    }
}
