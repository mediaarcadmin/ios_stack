//
//  EucCSSDocumentTree.h
//  LibCSSTest
//
//  Created by James Montgomerie on 09/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EucCSSDocumentTreeNode.h"

@protocol EucCSSDocumentTree <NSObject>

- (id<EucCSSDocumentTreeNode>)root;
- (id<EucCSSDocumentTreeNode>)nodeForKey:(uint32_t)key;

@optional
- (id<EucCSSDocumentTreeNode>)nodeWithId:(NSString *)identifier;

@end
