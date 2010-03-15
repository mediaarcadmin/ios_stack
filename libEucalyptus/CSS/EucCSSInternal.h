/*
 *  EucCSSInternal.h
 *  LibCSSTest
 *
 *  Created by James Montgomerie on 10/03/2010.
 *  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
 *
 */

#include <TargetConditionals.h>
#include <memory.h>

void *EucRealloc(void *ptr, size_t len, void *pw);

#if !TARGET_OS_IPHONE

#define NSStringFromCGRect(x) NSStringFromRect(NSRectFromCGRect(x))

#endif