/*
 *  EucCSSDocumentTreeNodeKind.h
 *  LibCSSTest
 *
 *  Created by James Montgomerie on 10/03/2010.
 *  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
 *
 */

typedef enum EucCSSDocumentTreeNodeKind
{
    EucCSSDocumentTreeNodeKindRoot = 0,
    EucCSSDocumentTreeNodeKindDoctype,
    EucCSSDocumentTreeNodeKindComment,
    EucCSSDocumentTreeNodeKindElement,
    EucCSSDocumentTreeNodeKindText
} EucCSSDocumentTreeNodeKind;

