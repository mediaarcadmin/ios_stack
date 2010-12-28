//
//  EucCSSLayoutTableCell.m
//  libEucalyptus
//
//  Created by James Montgomerie on 21/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutTableCell.h"

#import "EucCSSIntermediateDocumentNode.h"

#import <libcss/libcss.h>

@implementation EucCSSLayoutTableCell

- (id)initWithNode:(EucCSSIntermediateDocumentNode *)node
{
    if((self = [super initWithNode:node])) {
        enum css_display_e nodeDisplay = (enum css_display_e)node.display;
        BOOL inRealTableCell = (nodeDisplay == CSS_DISPLAY_TABLE_CELL);
        if(inRealTableCell) {
            _lastBlockNodeKey = node.key;
        } else {
            EucCSSIntermediateDocumentNode *nodeParent = node.parent;
            EucCSSIntermediateDocumentNode *currentDocumentNode = node; 
            while(currentDocumentNode.parent == nodeParent && 
                  currentDocumentNode.display != CSS_DISPLAY_TABLE_CELL) {
                currentDocumentNode = [nodeParent displayableNodeAfter:currentDocumentNode under:nil];
            }
            self.nextNodeInDocument = currentDocumentNode;
            _stopBeforeNodeKey = currentDocumentNode.key;
        }
    } 
    return self;
}

@end
