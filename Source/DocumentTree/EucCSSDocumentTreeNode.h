//
//  EucCSSDocumentTreeNode.h
//  LibCSSTest
//
//  Created by James Montgomerie on 09/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol EucCSSDocumentTreeNode <NSObject>

@property (nonatomic, readonly) uint32_t key;

@property (nonatomic, readonly) id<EucCSSDocumentTreeNode> parent;
@property (nonatomic, readonly) id<EucCSSDocumentTreeNode> firstChild;
@property (nonatomic, readonly) id<EucCSSDocumentTreeNode> nextSibling;
@property (nonatomic, readonly) id<EucCSSDocumentTreeNode> previousSibling;

@property (nonatomic, readonly) NSString *name;
- (NSString *)attributeWithName:(NSString *)attributeName;

@end
