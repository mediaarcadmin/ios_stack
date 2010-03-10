//
//  EucCSSDocumentTreeNode.h
//  LibCSSTest
//
//  Created by James Montgomerie on 09/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum EucCSSDocumentTreeNodeKind
{
    EucCSSDocumentTreeNodeKindDoctype,
    EucCSSDocumentTreeNodeKindComment,
    EucCSSDocumentTreeNodeKindElement,
    EucCSSDocumentTreeNodeKindText
} EucCSSDocumentTreeNodeKind;

@protocol EucCSSDocumentTree;

@protocol EucCSSDocumentTreeNode <NSObject>

@property (nonatomic, readonly) uint32_t key;

@property (nonatomic, readonly) id<EucCSSDocumentTreeNode> parent;
@property (nonatomic, readonly) id<EucCSSDocumentTreeNode> firstChild;
@property (nonatomic, readonly) id<EucCSSDocumentTreeNode> nextSibling;
@property (nonatomic, readonly) id<EucCSSDocumentTreeNode> previousSibling;

@property (nonatomic, readonly) uint32_t childCount;

@property (nonatomic, readonly) EucCSSDocumentTreeNodeKind kind;
@property (nonatomic, readonly) NSString *name;
- (NSString *)attributeWithName:(NSString *)attributeName;

- (BOOL)getCharacterContents:(const char **)contents length:(size_t *)length;

@end
