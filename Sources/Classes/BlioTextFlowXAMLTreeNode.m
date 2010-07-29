//
//  BlioTextFlowXAMLTreeNode.m
//  BlioApp
//
//  Created by James Montgomerie on 29/07/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioTextFlowXAMLTreeNode.h"

@implementation BlioTextFlowXAMLTreeNode

- (void)dealloc
{
    if(_constructedInlineStyle) {
        [_constructedInlineStyle release];
    }
    
    [super dealloc];
}

- (NSString *)attributeWithName:(NSString *)attributeName
{
    if([attributeName isEqualToString:@"style" ]) {
        // Some XAML attributes are not directly compatible with being styled 
        // with CSS, so we convert them to an inline style here.
        // Other attributes are styled by the TextFlowXAML.css resource
        // file.
        if(!_inlineStyleConstructed) {
            NSDictionary *myAttributes = self.attributes;
            if(myAttributes.count) {
                NSMutableString *constructionString = [[NSMutableString alloc] init];
                for(NSString *key in [myAttributes keyEnumerator]) {
                    if([key isEqualToString:@"Margin"]) {
                        NSArray *elements = [[myAttributes objectForKey:key] componentsSeparatedByString:@","];
                        NSUInteger elementCount = [elements count];
                        if(elementCount == 1) {
                            [constructionString appendFormat:@"margin:%@px;", [elements objectAtIndex:0]];
                        } else if(elementCount == 2) {
                            [constructionString appendFormat:@"margin:%@px %@px;", [elements objectAtIndex:1], [elements objectAtIndex:0]];
                        } else if(elementCount == 4) {
                            [constructionString appendFormat:@"margin:%@px %@px %@px %@px;", [elements objectAtIndex:1], [elements objectAtIndex:2], [elements objectAtIndex:3], [elements objectAtIndex:0]];
                        }                    
                    } else if([key isEqualToString:@"FontSize"]) {
                        [constructionString appendFormat:@"font-size:%@px;", [myAttributes objectForKey:key]];
                    } else if([key isEqualToString:@"TextIndent"]) {
                        [constructionString appendFormat:@"text-indent:%@px;", [myAttributes objectForKey:key]];
                    }
                }
                if(constructionString.length) {
                    _constructedInlineStyle = constructionString;
                } else {
                    [constructionString release];
                }
            }
            _inlineStyleConstructed = YES;
        }
        return _constructedInlineStyle;
    } else {
        return [super attributeWithName:attributeName];
    }
}

@end
