//
//  EucCSSDocumentTreeNode.h
//  LibCSSTest
//
//  Created by James Montgomerie on 09/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucCSSDocumentTreeNodeKind.h";

@protocol EucCSSDocumentTree;

@protocol EucCSSDocumentTreeNode <NSObject>

@required

- (uint32_t)key;
- (EucCSSDocumentTreeNodeKind)kind;
- (NSString *)name;

- (uint32_t)childCount;
- (id<EucCSSDocumentTreeNode>)firstChild;
- (id<EucCSSDocumentTreeNode>)previousSibling;
- (id<EucCSSDocumentTreeNode>)nextSibling;
- (id<EucCSSDocumentTreeNode>)parent;

- (NSString *)attributeWithName:(NSString *)attributeName;

// Bytes returned by this accessor /must/ live for at least as long as the
// node object.
- (BOOL)getCharacterContents:(const char **)contents length:(size_t *)length;

- (BOOL)isImageNode;
- (NSString *)imageSourceURLString;

- (BOOL)isHyperlinkNode;
- (NSString *)hyperlinkURLString;

- (NSString *)CSSID;

- (NSString *)CSSClasses;

- (NSString *)inlineStyle;

@optional

- (NSUInteger)columnSpan;
- (NSUInteger)rowSpan;
- (NSArray *)preprocessedWordStrings;

@end