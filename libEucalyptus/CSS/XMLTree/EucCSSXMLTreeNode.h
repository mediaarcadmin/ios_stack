//
//  EucCSSXMLTreeNode.h
//  libEucalyptus
//
//  Created by James Montgomerie on 11/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EucCSSDocumentTreeNode.h"

struct lwc_string_s;

@interface EucCSSXMLTreeNode : NSObject <EucCSSDocumentTreeNode> {
    uint32_t _key;
    EucCSSDocumentTreeNodeKind _kind;
    NSString *_name;
    
    NSMutableArray *_children;
    
    EucCSSXMLTreeNode *_parent;
    EucCSSXMLTreeNode *_previousSibling;
    EucCSSXMLTreeNode *_nextSibling;
    
    NSData *_characters;
    
    // Storing the attributes in an array of [[name, value][name, value]]
    // uses less memory than a dictionary, and performance testing 
    // shows that it's actually faster for real documents (I guess
    // there are few enough attributes that a linear search can be 
    // faster than a dictionary lookup).
    NSUInteger _attributesCountX2;
    NSUInteger _attributesCapacity;
    struct lwc_string_s **_attributes;
}

@property (nonatomic, retain) NSString *name;

@property (nonatomic, retain) NSData *characters;

- (id)initWithKey:(uint32_t)key kind:(EucCSSDocumentTreeNodeKind)kind;

- (void)addChild:(EucCSSXMLTreeNode *)child;
- (void)addAttributeValue:(NSString *)value forName:(NSString *)name;
@property (nonatomic, assign, readonly) BOOL hasAttributes;

@end
