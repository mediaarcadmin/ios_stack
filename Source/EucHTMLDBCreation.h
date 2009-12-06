/*
 *  EucHTMLDBCreation.h
 *  LibCSSTest
 *
 *  Created by James Montgomerie on 03/12/2009.
 *  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
 *
 */

#include "EucHTMLDB.h"

hubbub_error EucHTMLDBCreateRoot(void *ctx, void **result);
hubbub_tree_handler *EucHTMLDBHubbubTreeHandlerCreateWithContext(EucHTMLDB *context);

void Traverse(EucHTMLDB *context);
