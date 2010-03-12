//
//  EucCSSXMLTreeNode.h
//  libEucalyptus
//
//  Created by James Montgomerie on 11/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucCSSDocumentTreeNode.h"

@interface EucCSSXMLTreeNode : NSObject <EucCSSDocumentTreeNode> {
    uint32_t _key;
    EucCSSDocumentTreeNodeKind _kind;
    NSString *_name;
    
    NSMutableArray *_children;
    
    EucCSSXMLTreeNode *_parent;
    EucCSSXMLTreeNode *_previousSibling;
    EucCSSXMLTreeNode *_nextSibling;
    
    NSDictionary *_attributes;
    NSData *_characters;
}

@property (nonatomic, retain) NSString *name;

@property (nonatomic, retain) NSDictionary *attributes;
@property (nonatomic, retain) NSData *characters;

- (id)initWithKey:(uint32_t)key kind:(EucCSSDocumentTreeNodeKind)kind;

- (void)addChild:(EucCSSXMLTreeNode *)child;

@end
