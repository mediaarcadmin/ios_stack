//
//  BlioTextFlowXAMLTreeNode.h
//  BlioApp
//
//  Created by James Montgomerie on 29/07/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <libEucalyptus/EucCSSXMLTreeNode.h>


@interface BlioTextFlowXAMLTreeNode : EucCSSXMLTreeNode {
    BOOL _inlineStyleConstructed;
    NSString *_constructedInlineStyle;
    BOOL _tagFound;
    NSString *_tag;
}

@property (nonatomic, retain, readonly) NSString *tag;

@end
