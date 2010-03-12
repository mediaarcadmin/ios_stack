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
    NSArray *_nodes;
}

- (id)initWithData:(NSData *)xmlData;

@end
