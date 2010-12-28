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

#import "EucCSSIntermediateDocumentNode.h"

#import <libcss/libcss.h>

@interface EucCSSLayoutTableWrapper ()

@property (nonatomic, retain) EucCSSLayoutTableCaption *caption;
@property (nonatomic, retain) EucCSSLayoutTableTable *table;

@end

@implementation EucCSSLayoutTableWrapper

@synthesize caption = _caption;
@synthesize table = _table;

- (id)initWithNode:(EucCSSIntermediateDocumentNode *)node
{
    if((self = [super initWithNode:node])) {
        _table = [[EucCSSLayoutTableTable alloc] initWithNode:node];
    }
    return self;
}

- (void)dealloc
{
    [_nextNodeInDocument release];

    [super dealloc];
}

- (EucCSSIntermediateDocumentNode *)accumulateCaptionNode:(EucCSSIntermediateDocumentNode *)captionNode
{
    EucCSSLayoutTableCaption *caption = [[EucCSSLayoutTableCaption alloc] initWithNode:captionNode];
    EucCSSIntermediateDocumentNode *nextNodeInDocument = [[caption.nextNodeInDocument retain] autorelease];
    if(!self.caption) {
        // In a malformed table with more than one caption, first caption wins.
        self.caption = caption;
        [caption release];
    }
    return nextNodeInDocument;
}

@end
