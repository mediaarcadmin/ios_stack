//
//  EucCSSXHTMLTreeNode.m
//  libEucalyptus
//
//  Created by James Montgomerie on 05/01/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSXHTMLTreeNode.h"

@implementation EucCSSXHTMLTreeNode

- (BOOL)isImageNode
{
    return [@"img" caseInsensitiveCompare:self.name] == NSOrderedSame;
}

- (NSString *)imageSourceURLString
{
    return [self attributeWithName:@"src"];
}    

- (BOOL)isHyperlinkNode
{
    if([@"a" caseInsensitiveCompare:self.name] == NSOrderedSame) {
        return [self attributeWithName:@"href"].length != 0;
    }
    return NO;
}

- (NSString *)hyperlinkURLString
{
    return [self attributeWithName:@"href"];
}

- (NSString *)CSSID
{
    return [self attributeWithName:@"id"];
}

- (NSUInteger)columnSpan
{
    NSUInteger colSpan = [[self attributeWithName:@"colspan"] integerValue];
    return MAX(colSpan, 1); 
}

- (NSUInteger)rowSpan
{
    NSUInteger rowSpan = [[self attributeWithName:@"rowspan"] integerValue];
    return MAX(rowSpan, 1); 
}

- (NSString *)inlineStyle
{
    return [self attributeWithName:@"style"];
}

@end
