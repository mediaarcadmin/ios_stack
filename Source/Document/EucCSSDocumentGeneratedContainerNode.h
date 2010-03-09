//
//  EucCSSDocumentGeneratedContainerNode.h
//  LibCSSTest
//
//  Created by James Montgomerie on 24/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libcss/libcss.h>

#import "EucCSSDocumentNode.h"

@class EucCSSDocument, EucCSSDocumentConcreteNode;

@interface EucCSSDocumentGeneratedContainerNode : EucCSSDocumentNode {
    uint32_t _parentKey;    
    BOOL _beforeParent;
}

- (id)initWithDocument:(EucCSSDocument *)document 
             parentKey:(uint32_t)parentKey
        isBeforeParent:(BOOL)beforeParent;

@end
