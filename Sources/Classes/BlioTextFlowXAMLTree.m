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

- (id)initWithData:(NSData *)data
{
    return [super initWithData:data xmlTreeNodeClass:[BlioTextFlowXAMLTreeNode class]];
}

- (NSString *)idForNodeAttribute:(const XML_Char *)name value:(const XML_Char *)value
{
    if(strcmp("Tag", name) == 0 && strncmp("__", value, 2) != 0) {
        return [NSString stringWithUTF8String:value];
    } else {
        return nil;
    }
}


@end
