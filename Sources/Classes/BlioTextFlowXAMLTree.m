//
//  BlioTextFlowXAMLTree.m
//  BlioApp
//
//  Created by James Montgomerie on 29/07/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioTextFlowXAMLTree.h"
#import "BlioTextFlowXAMLTreeNode.h"

@implementation BlioTextFlowXAMLTree

- (Class)xmlTreeNodeClass
{
    return [BlioTextFlowXAMLTreeNode class];
}

@end
