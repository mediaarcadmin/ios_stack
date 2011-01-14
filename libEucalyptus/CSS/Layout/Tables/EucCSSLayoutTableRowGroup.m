//
//  EucCSSLayoutTableRowGroup.m
//  libEucalyptus
//
//  Created by James Montgomerie on 21/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutTableRowGroup.h"
#import "EucCSSLayoutTableRow.h"

#import "EucCSSIntermediateDocumentNode.h"

#import <libcss/libcss.h>


@implementation EucCSSLayoutTableRowGroup

@synthesize rows = _rows;

- (id)initWithNode:(EucCSSIntermediateDocumentNode *)node wrapper:(EucCSSLayoutTableWrapper *)wrapper
{
    if((self = [super initWithNode:node wrapper:wrapper])) {
        enum css_display_e nodeDisplay = (enum css_display_e)node.display;
        BOOL inRealTableRowGroup = (nodeDisplay == CSS_DISPLAY_TABLE_ROW_GROUP) || (nodeDisplay == CSS_DISPLAY_TABLE_HEADER_GROUP) || (nodeDisplay == CSS_DISPLAY_TABLE_FOOTER_GROUP);
        
        EucCSSIntermediateDocumentNode *currentDocumentNode = node;      
        if(inRealTableRowGroup) {
            currentDocumentNode = [currentDocumentNode nextDisplayable];
        }
        
        NSMutableArray *rowsBuild = [[NSMutableArray alloc] init];
        for(;;) {
            if(currentDocumentNode.isTextNode &&
               [currentDocumentNode.text rangeOfCharacterFromSet:[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet]].location == NSNotFound) {
                currentDocumentNode = currentDocumentNode.nextDisplayable;
            } else {  
                if(inRealTableRowGroup) {
                    if(currentDocumentNode.parent != node) {
                        break;
                    } 
                } else {
                    if(currentDocumentNode.parent != node.parent) {
                        break;
                    } else {
                        enum css_display_e currentNodeDisplay = (enum css_display_e)currentDocumentNode.display;
                        if(currentNodeDisplay == CSS_DISPLAY_TABLE_COLUMN ||
                           currentNodeDisplay == CSS_DISPLAY_TABLE_ROW_GROUP ||
                           currentNodeDisplay == CSS_DISPLAY_TABLE_COLUMN_GROUP ||
                           currentNodeDisplay == CSS_DISPLAY_TABLE_CAPTION) {
                            break;
                        }
                    }
                }
                
                EucCSSLayoutTableRow *row = [[EucCSSLayoutTableRow alloc] initWithNode:currentDocumentNode wrapper:wrapper];
                [rowsBuild addObject:row];
                currentDocumentNode = row.nextNodeInDocument;
                [row release];        
            }
        }
        
        if(!inRealTableRowGroup) {
            self.nextNodeInDocument = currentDocumentNode;
        }
        
        _rows = rowsBuild;
    }
    return self;
}

- (void)dealloc
{
    [_rows release];
    
    [super dealloc];
}

- (BOOL)documentNodeIsRepresentative
{
    uint8_t display = self.documentNode.display;
    return display == CSS_DISPLAY_TABLE_ROW_GROUP || display == CSS_DISPLAY_TABLE_HEADER_GROUP || display == CSS_DISPLAY_TABLE_FOOTER_GROUP;
}

@end
