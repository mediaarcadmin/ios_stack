//
//  EucCSSLayoutTableCaption.m
//  libEucalyptus
//
//  Created by James Montgomerie on 21/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutTableCaption.h"

@implementation EucCSSLayoutTableCaption

- (id)initWithNode:(EucCSSIntermediateDocumentNode *)node wrapper:(EucCSSLayoutTableWrapper *)wrapper
{
    if((self = [super initWithNode:node wrapper:wrapper])) {
        // Generate contents now?
    }
    return self;
}

- (void)dealloc
{
    [super dealloc]; 
}

@end
