//
//  EucCSSLayoutPositionedTable.m
//  libEucalyptus
//
//  Created by James Montgomerie on 04/01/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutPositionedTable.h"

#import "EucCSSLayoutSizedTable.h"

@implementation EucCSSLayoutPositionedTable

- (id)initWithSizedTable:(EucCSSLayoutSizedTable *)sizedTable 
{
    if((self = [super init])) {
        _sizedTable = [sizedTable retain];
    }
    return self;
}

- (void)dealloc
{
    [_sizedTable release];
    
    [super dealloc];
}

- (void)positionInFrame:(CGRect)frame
 afterInternalPageBreak:(BOOL)afterInternalPageBreak
{
    if(_sizedTable.maxWidth < frame.size.width) {
        frame.size.width = _sizedTable.maxWidth;
    }
    if(_sizedTable.minWidth > frame.size.width) {
        frame.size.width = _sizedTable.minWidth;
    }
    
    frame.size.height = 5;
    
    // Calculate height properly.
    // Place horizontally.
    
    self.frame = frame;
}    

@end
