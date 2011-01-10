//
//  EucCSSLayoutTableColumnGroup.m
//  libEucalyptus
//
//  Created by James Montgomerie on 21/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutTableColumnGroup.h"
#import "EucCSSLayoutTableColumn.h"

#import "EucCSSIntermediateDocumentNode.h"

#import <libcss/libcss.h>

@implementation EucCSSLayoutTableColumnGroup

@synthesize columns = _columns;

- (id)initWithNode:(EucCSSIntermediateDocumentNode *)node wrapper:(EucCSSLayoutTableWrapper *)wrapper
{
    if((self = [super initWithNode:node wrapper:wrapper])) {
        enum css_display_e nodeDisplay = (enum css_display_e)node.display;
        BOOL inRealTableColumnGroup = (nodeDisplay == CSS_DISPLAY_TABLE_COLUMN_GROUP);

        EucCSSIntermediateDocumentNode *currentDocumentNode = node;      
        if(inRealTableColumnGroup) {
            currentDocumentNode = [currentDocumentNode nextDisplayable];
        } else {
            NSParameterAssert(currentDocumentNode.display == CSS_DISPLAY_TABLE_COLUMN);
        }
        
        NSMutableArray *columnsBuild = [[NSMutableArray alloc] init];
        for(;;) {
            if(currentDocumentNode.isTextNode &&
               [currentDocumentNode.text rangeOfCharacterFromSet:[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet]].location == NSNotFound) {
                currentDocumentNode = currentDocumentNode.nextDisplayable;
            } else {  
                enum css_display_e currentNodeDisplay = (enum css_display_e)currentDocumentNode.display;

                if(inRealTableColumnGroup) {
                    if(currentDocumentNode.parent != node) {
                        break;
                    }
                } else {
                    if(currentDocumentNode.parent != node.parent ||
                       currentNodeDisplay != CSS_DISPLAY_TABLE_COLUMN) {
                        break;
                    }
                }
                
                if(currentNodeDisplay == CSS_DISPLAY_TABLE_COLUMN) {
                    EucCSSLayoutTableColumn *column = [[EucCSSLayoutTableColumn alloc] initWithNode:currentDocumentNode wrapper:wrapper];
                    [columnsBuild addObject:column];
                    currentDocumentNode = column.nextNodeInDocument;
                    [column release];
                } else {
                    currentDocumentNode = [node displayableNodeAfter:currentDocumentNode under:nil];
                }
            }
        }
        
        if(!inRealTableColumnGroup) {
            self.nextNodeInDocument = currentDocumentNode;
        }
        
        _columns = columnsBuild;
    }
    return self;
}
                
- (void)dealloc
{
    [_columns release];
 
    [super dealloc];
}

@end
