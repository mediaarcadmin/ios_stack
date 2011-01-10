//
//  EucCSSLayoutTableBox.m
//  libEucalyptus
//
//  Created by James Montgomerie on 21/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutTableBox.h"

#import "EucCSSIntermediateDocumentNode.h"

#import "EucCSSInternal.h"

#import <libcss/libcss.h>

@implementation EucCSSLayoutTableBox

@synthesize wrapper = _wrapper;
@synthesize documentNode = _documentNode;
@synthesize nextNodeInDocument = _nextNodeInDocument;

- (id)initWithNode:(EucCSSIntermediateDocumentNode *)node wrapper:(EucCSSLayoutTableWrapper *)wrapper
{
    if((self = [super init])) {
        _wrapper = wrapper;
        _documentNode = [node retain];
        _nextNodeInDocument = [[node.parent displayableNodeAfter:node under:nil] retain];
    }
    return self;
}

- (void)dealloc
{
    [_documentNode release];
    [_nextNodeInDocument release];
    
    [super dealloc];
}

- (BOOL)documentNodeIsRepresentative
{
    return NO;
}

- (CGFloat)widthWithScaleFactor:(CGFloat)scaleFactor
{
    CGFloat ret = CGFLOAT_MAX;
 
    if(self.documentNodeIsRepresentative) {
        css_computed_style *nodeStyle = self.documentNode.computedStyle;
        if(nodeStyle) {
            css_fixed length = 0;
            css_unit unit = (css_unit)0;
            
            uint8_t widthKind = css_computed_width(nodeStyle, &length, &unit);
            if(widthKind == CSS_WIDTH_SET) {
                ret = EucCSSLibCSSSizeToPixels(nodeStyle, length, unit, 0, scaleFactor);
            }
        }
    }
    
    return ret;
}

@end
