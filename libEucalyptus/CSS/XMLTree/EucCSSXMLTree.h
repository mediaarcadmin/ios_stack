//
//  EucCSSXMLTree.h
//  libEucalyptus
//
//  Created by James Montgomerie on 11/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EucCSSDocumentTree.h"

@class EucCSSXMLTreeNode;

@interface EucCSSXMLTree : NSObject <EucCSSDocumentTree> { 
    NSUInteger _nodesCount;
    NSArray *_nodes;
    NSDictionary *_idToNode;
}

@property (nonatomic, retain, readonly) NSArray *nodes;
@property (nonatomic, retain, readonly) NSDictionary *idToNode;

// Can be overridden in subclasses.
@property (nonatomic, retain, readonly) Class xmlTreeNodeClass; // Default is EucCSSXMLTreeNode.          
                                                                // Must be EucCSSXMLTreeNode subclass.
@property (nonatomic, retain, readonly) NSString *defaultDTDPublicID; // Default is nil.
@property (nonatomic, retain, readonly) NSDictionary *DTDPublicIDToLocalPath; // Default is nil.

- (id)initWithData:(NSData *)xmlData;

@end
