/*
 *  EucHTDBCreation.h
 *  LibCSSTest
 *
 *  Created by James Montgomerie on 03/12/2009.
 *  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
 *
 */

#include "EucHTDB.h"

hubbub_error EucHTDBCreateRoot(void *ctx, void **result);
hubbub_tree_handler *EucHTDBHubbubTreeHandlerCreateWithContext(EucHTDB *context);

void Traverse(EucHTDB *context);
