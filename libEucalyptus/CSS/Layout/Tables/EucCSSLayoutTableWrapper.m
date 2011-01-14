//
//  EucCSSLayoutTableWrapper.m
//  libEucalyptus
//
//  Created by James Montgomerie on 21/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutTableWrapper.h"
#import "EucCSSLayoutTableTable.h"
#import "EucCSSLayoutTableCaption.h"
#import "EucCSSLayoutTableRowGroup.h"
#import "EucCSSLayoutTableRow.h"

#import "EucCSSIntermediateDocumentNode.h"

#import <libcss/libcss.h>

@interface EucCSSLayoutTableWrapper ()

@property (nonatomic, retain) EucCSSLayoutTableCaption *caption;
@property (nonatomic, retain) EucCSSLayoutTableTable *table;

@end

@implementation EucCSSLayoutTableWrapper

@synthesize layouter = _layouter;
@synthesize caption = _caption;
@synthesize table = _table;

- (id)initWithNode:(EucCSSIntermediateDocumentNode *)node layouter:(EucCSSLayouter *)layouter
{
    if((self = [super initWithNode:node wrapper:self])) {
        _layouter = [layouter retain];
        _table = [[EucCSSLayoutTableTable alloc] initWithNode:node wrapper:self];
    }
    return self;
}

- (void)dealloc
{
    [_layouter release];
    [_caption release];
    [_table release];
    
    [super dealloc];
}

- (EucCSSIntermediateDocumentNode *)accumulateCaptionNode:(EucCSSIntermediateDocumentNode *)captionNode
{
    EucCSSLayoutTableCaption *caption = [[EucCSSLayoutTableCaption alloc] initWithNode:captionNode wrapper:self];
    EucCSSIntermediateDocumentNode *nextNodeInDocument = [[caption.nextNodeInDocument retain] autorelease];
    if(!self.caption) {
        // In a malformed table with more than one caption, first caption wins.
        self.caption = caption;
    }
    [caption release];
    return nextNodeInDocument;
}

- (NSUInteger)rowForDocumentNode:(EucCSSIntermediateDocumentNode *)documentNode
{
    NSUInteger rowNumber = 0;
    
    if(_caption.documentNode != documentNode) {
        rowNumber = 1;
        NSUInteger examiningRow = 1;
        for(EucCSSLayoutTableRowGroup *rowGroup in self.table.rowGroups) {
            for(EucCSSLayoutTableRow *row in rowGroup.rows) {
                if(documentNode.key >= row.documentNode.key) {
                    rowNumber = examiningRow;
                }
                ++examiningRow;
            }
        }
    }
    
    return rowNumber;
}

@end
