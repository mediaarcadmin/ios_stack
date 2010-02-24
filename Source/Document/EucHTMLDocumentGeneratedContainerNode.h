//
//  EucHTMLDocumentGeneratedContainerNode.h
//  LibCSSTest
//
//  Created by James Montgomerie on 24/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libcss/libcss.h>

#import "EucHTMLDocumentNode.h"

@class EucHTMLDocument, EucHTMLDocumentConcreteNode;

@interface EucHTMLDocumentGeneratedContainerNode : EucHTMLDocumentNode {
    uint32_t _parentKey;    
    BOOL _beforeParent;
}

- (id)initWithDocument:(EucHTMLDocument *)document 
             parentKey:(uint32_t)parentKey
        isBeforeParent:(BOOL)beforeParent;

@end
