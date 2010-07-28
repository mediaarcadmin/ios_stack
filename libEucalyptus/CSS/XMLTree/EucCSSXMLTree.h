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
    Class _xmlTreeNodeClass;
    NSArray *_nodes;
    NSDictionary *_idToNode;
}

@property (nonatomic, readonly) NSDictionary *idToNode;

- (id)initWithData:(NSData *)xmlData;
- (id)initWithData:(NSData *)xmlData xmlTreeNodeClass:(Class)xmlTreeNodeClass;

@end
