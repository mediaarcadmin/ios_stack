//
//  EucCSSXMLTree.h
//  libEucalyptus
//
//  Created by James Montgomerie on 11/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <expat/expat.h>

#import "EucCSSDocumentTree.h"

@class EucCSSXMLTreeNode;

@interface EucCSSXMLTree : NSObject <EucCSSDocumentTree> { 
    Class _xmlTreeNodeClass;
    NSUInteger _nodesCount;
    NSArray *_nodes;
    NSDictionary *_idToNode;
}

@property (nonatomic, retain, readonly) NSArray *nodes;
@property (nonatomic, retain, readonly) NSDictionary *idToNode;

- (id)initWithData:(NSData *)xmlData;

- (id)initWithData:(NSData *)xmlData
  xmlTreeNodeClass:(Class)xmlTreeNodeClass;

- (id)initWithData:(NSData *)xmlData
  xmlTreeNodeClass:(Class)xmlTreeNodeClas 
DTDPublicIDToLocalPathMap:(NSDictionary *)dtdMap 
defaultDTDPublicID:(NSString *)defaultDTDID;

@end
