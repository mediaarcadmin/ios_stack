//
//  EucCSSLayoutTableTable.m
//  libEucalyptus
//
//  Created by James Montgomerie on 21/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutTableTable.h"
#import "EucCSSLayoutTableWrapper.h"
#import "EucCSSLayoutTableHeaderGroup.h"
#import "EucCSSLayoutTableFooterGroup.h"
#import "EucCSSLayoutTableRowGroup.h"
#import "EucCSSLayoutTableColumnGroup.h"

#import "EucCSSIntermediateDocumentNode.h"

#import "THLog.h"
#import <libcss/libcss.h>

@implementation EucCSSLayoutTableTable

@synthesize headerGroup = _headerGroup;
@synthesize rowGroups = _rowGroups;
@synthesize footerGroup = _footerGroup;

@synthesize columnGroups = _columnGroups;

- (id)initWithNode:(EucCSSIntermediateDocumentNode *)node wrapper:(EucCSSLayoutTableWrapper *)wrapper
{
    if((self = [super initWithNode:node wrapper:wrapper])) {
        enum css_display_e nodeDisplay = (enum css_display_e)node.display;
        BOOL inRealTableNode = (nodeDisplay == CSS_DISPLAY_TABLE || nodeDisplay == CSS_DISPLAY_INLINE_TABLE);

        EucCSSIntermediateDocumentNode *currentDocumentNode = node;              
        EucCSSIntermediateDocumentNode *nodeParent = node.parent;              
        if(inRealTableNode) {
            currentDocumentNode = [currentDocumentNode nextDisplayable];
        }

        for(;;) {
            if(inRealTableNode) {
                if(currentDocumentNode.parent != node) {
                    break;
                }
            } else {
                // We're in an implicit table node.
                // We nil-out the current node below when we stop seeing table
                // nodes, so we know to break now if it's nil.
                if(!currentDocumentNode || 
                   currentDocumentNode.parent != nodeParent) {
                    break;
                }
            }
            
            enum css_display_e currentNodeDisplay = (enum css_display_e)currentDocumentNode.display;
            switch(currentNodeDisplay) {
                case CSS_DISPLAY_INHERIT:
                case CSS_DISPLAY_NONE:
                default:
                {
                    THWarn(@"Unexpected node with display: %ld", (long)currentNodeDisplay);
                    // Fall Through.
                }
                case CSS_DISPLAY_INLINE:
                case CSS_DISPLAY_BLOCK:
                case CSS_DISPLAY_LIST_ITEM:
                case CSS_DISPLAY_RUN_IN:
                case CSS_DISPLAY_INLINE_BLOCK:    
                case CSS_DISPLAY_TABLE:
                case CSS_DISPLAY_INLINE_TABLE:
                {
                    if(!inRealTableNode) {
                        // We're not parented with a table node, we're just
                        // constructing one from consecutive table elements.
                        // Stop, because this is not a table element.
                        self.nextNodeInDocument = currentDocumentNode;
                        currentDocumentNode = nil;
                        break;
                    } else {
                        // Generate row, so fall through to cases below.
                    }
                }
                case CSS_DISPLAY_TABLE_ROW_GROUP:
                case CSS_DISPLAY_TABLE_HEADER_GROUP:
                case CSS_DISPLAY_TABLE_FOOTER_GROUP:
                case CSS_DISPLAY_TABLE_ROW:
                case CSS_DISPLAY_TABLE_CELL:
                {
                    EucCSSLayoutTableRowGroup *rowGroup;
                    if(currentNodeDisplay == CSS_DISPLAY_TABLE_HEADER_GROUP && !_headerGroup) {
                        // First header group wins - others treated like 
                        // regular row groups.
                        _headerGroup = [[EucCSSLayoutTableHeaderGroup alloc] initWithNode:currentDocumentNode wrapper:wrapper];
                        rowGroup = _headerGroup;
                    } else if(currentNodeDisplay == CSS_DISPLAY_TABLE_FOOTER_GROUP && !_footerGroup) {
                        // First footer group wins - others treated like 
                        // regular row groups.
                        _footerGroup = [[EucCSSLayoutTableFooterGroup alloc] initWithNode:currentDocumentNode wrapper:wrapper];
                        rowGroup = _footerGroup;
                    } else {
                        rowGroup =[[EucCSSLayoutTableRowGroup alloc] initWithNode:currentDocumentNode wrapper:wrapper];
                        if(!_rowGroups) {
                            _rowGroups = [[NSMutableArray alloc] init];
                        }
                        [_rowGroups addObject:rowGroup];
                        [rowGroup release];
                    }
                    currentDocumentNode = rowGroup.nextNodeInDocument;
                    break;
                }
                case CSS_DISPLAY_TABLE_COLUMN_GROUP:
                case CSS_DISPLAY_TABLE_COLUMN:
                {
                    EucCSSLayoutTableColumnGroup *columnGroup =[[EucCSSLayoutTableColumnGroup alloc] initWithNode:currentDocumentNode wrapper:wrapper];
                    if(!_columnGroups) {
                        _columnGroups = [[NSMutableArray alloc] init];
                    }
                    [_columnGroups addObject:columnGroup];
                    [columnGroup release];
                    currentDocumentNode = columnGroup.nextNodeInDocument;
                    break;   
                } 
                case CSS_DISPLAY_TABLE_CAPTION:
                {
                    currentDocumentNode = [wrapper accumulateCaptionNode:currentDocumentNode];
                    break;           
                }                    
            }
        }
    }
    return self;    
}

- (void)dealloc
{
    [_headerGroup release];
    [_rowGroups release];
    [_footerGroup release];
    
    [_columnGroups release];

    [super dealloc];
}

@end
