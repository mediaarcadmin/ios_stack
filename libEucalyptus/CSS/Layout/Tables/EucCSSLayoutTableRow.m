//
//  EucCSSLayoutTableRow.m
//  libEucalyptus
//
//  Created by James Montgomerie on 21/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutTableRow.h"
#import "EucCSSLayoutTableCell.h"

#import "EucCSSIntermediateDocumentNode.h"

#import <libcss/libcss.h>

@implementation EucCSSLayoutTableRow

@synthesize cells = _cells;

- (id)initWithNode:(EucCSSIntermediateDocumentNode *)node wrapper:(EucCSSLayoutTableWrapper *)wrapper
{
    if((self = [super initWithNode:node wrapper:wrapper])) {
        enum css_display_e nodeDisplay = (enum css_display_e)node.display;
        BOOL inRealTableRow = (nodeDisplay == CSS_DISPLAY_TABLE_ROW);
        
        EucCSSIntermediateDocumentNode *currentDocumentNode = node;      
        if(inRealTableRow) {
            currentDocumentNode = [currentDocumentNode nextDisplayable];
        }
        
        NSMutableArray *cellsBuild = [[NSMutableArray alloc] init];
        for(;;) {
            if(currentDocumentNode.isTextNode &&
               [currentDocumentNode.text rangeOfCharacterFromSet:[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet]].location == NSNotFound) {
                currentDocumentNode = currentDocumentNode.nextDisplayable;
            } else {  
                if(inRealTableRow) {
                    if(currentDocumentNode.parent != node) {
                        break;
                    } 
                } else {
                    if(currentDocumentNode.parent != node.parent) {
                        break;
                    } else {
                        enum css_display_e currentNodeDisplay = (enum css_display_e)currentDocumentNode.display;
                        if(currentNodeDisplay == CSS_DISPLAY_TABLE_ROW ||
                           currentNodeDisplay == CSS_DISPLAY_TABLE_COLUMN ||
                           currentNodeDisplay == CSS_DISPLAY_TABLE_ROW_GROUP ||
                           currentNodeDisplay == CSS_DISPLAY_TABLE_COLUMN_GROUP ||
                           currentNodeDisplay == CSS_DISPLAY_TABLE_CAPTION) {
                            break;
                       }
                    }
                }
                
                EucCSSLayoutTableCell *cell = [[EucCSSLayoutTableCell alloc] initWithNode:currentDocumentNode wrapper:wrapper];
                [cellsBuild addObject:cell];
                currentDocumentNode = cell.nextNodeInDocument;
                [cell release]; 
            }
        }
        
        if(!inRealTableRow) {
            self.nextNodeInDocument = currentDocumentNode;
        }
        
        _cells = cellsBuild;
    }
    return self;
}

- (void)dealloc
{
    [_cells release];
    
    [super dealloc];
}

@end
