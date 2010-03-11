/*
 *  EucHTMLDBCreation.h
 *  LibCSSTest
 *
 *  Created by James Montgomerie on 03/12/2009.
 *  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
 *
 */

#include "EucHTMLDB.h"

EucHTMLDB *EucHTMLDBCreateWithHTMLAtPath(const char* htmlPath, const char* newDbPath);

void Traverse(EucHTMLDB *context);
