//
//  EucCSSLayoutTableCell.m
//  libEucalyptus
//
//  Created by James Montgomerie on 21/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutTableCell.h"
#import "EucCSSLayoutTableWrapper.h"

#import "EucCSSIntermediateDocumentNode.h"

#import "EucCSSLayouter.h"
#import "EucCSSLayoutSizedTableCell.h"

#import <libcss/libcss.h>

@implementation EucCSSLayoutTableCell

- (id)initWithNode:(EucCSSIntermediateDocumentNode *)node wrapper:(EucCSSLayoutTableWrapper *)wrapper
{
    if((self = [super initWithNode:node wrapper:wrapper])) {
        enum css_display_e nodeDisplay = (enum css_display_e)node.display;
        BOOL inRealTableCell = (nodeDisplay == CSS_DISPLAY_TABLE_CELL);
        if(!inRealTableCell) {
            EucCSSIntermediateDocumentNode *nodeParent = node.parent;
            EucCSSIntermediateDocumentNode *currentDocumentNode = node; 
            while(currentDocumentNode.parent == nodeParent && 
                  currentDocumentNode.display != CSS_DISPLAY_TABLE_CELL) {
                currentDocumentNode = [nodeParent displayableNodeAfter:currentDocumentNode under:nil];
            }
            self.nextNodeInDocument = currentDocumentNode;
            _stopBeforeNode = [currentDocumentNode retain];
        }
    } 
    return self;
}

- (void)dealloc
{
    [_stopBeforeNode release];
    
    [super dealloc];
}

- (NSUInteger)columnSpan
{
    NSUInteger ret = 1;
    EucCSSIntermediateDocumentNode *node = self.documentNode;
    if(node.display == CSS_DISPLAY_TABLE_CELL) {
        ret = [node columnSpan];
    }
    return ret;
}

- (NSUInteger)rowSpan
{
    NSUInteger ret = 1;
    EucCSSIntermediateDocumentNode *node = self.documentNode;
    if(node.display == CSS_DISPLAY_TABLE_CELL) {
        ret = [node rowSpan];
    }
    return ret;
}

- (EucCSSLayoutSizedTableCell *)sizedTableCellWithScaleFactor:(CGFloat)scaleFactor
{
    EucCSSLayoutSizedContainer *container = [_wrapper.layouter sizedContainerFromNodeWithKey:self.documentNode.key
                                                                       stopBeforeNodeWithKey:_stopBeforeNode.key
                                                                                 scaleFactor:scaleFactor];
    NSParameterAssert([container isKindOfClass:[EucCSSLayoutSizedTableCell class]]);
    return (EucCSSLayoutSizedTableCell *)container;
}

- (BOOL)documentNodeIsRepresentative
{
    return self.documentNode.display == CSS_DISPLAY_TABLE_CELL;
}

@end
