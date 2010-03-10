//
//  EucCSSDocumentTree.h
//  LibCSSTest
//
//  Created by James Montgomerie on 09/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <libcss/libcss.h>

#import "EucCSSDocumentTreeNode.h"

extern css_select_handler EucCSSDocumentTreeSelectHandler;

@protocol EucCSSDocumentTree <NSObject>

@property (nonatomic, retain, readonly) id<EucCSSDocumentTreeNode> root;

- (id<EucCSSDocumentTreeNode>)nodeForKey:(uint32_t)key;

@end
