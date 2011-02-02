//
//  EucCSSXHTMLTree.m
//  libEucalyptus
//
//  Created by James Montgomerie on 02/02/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSXHTMLTree.h"
#import "EucCSSXHTMLTreeNode.h"

@implementation EucCSSXHTMLTree

- (Class)xmlTreeNodeClass
{
    return [EucCSSXHTMLTreeNode class];
}

- (NSString *)defaultDTDPublicID
{
    return @"-//W3C//DTD XHTML 1.1//EN";
}

- (NSDictionary *)DTDPublicIDToLocalPath
{
    NSString *dtdPath = [[NSBundle mainBundle] pathForResource:@"xhtml-entities" ofType:@"ent"];
    return [NSDictionary dictionaryWithObject:dtdPath forKey:self.defaultDTDPublicID];
}

@end
