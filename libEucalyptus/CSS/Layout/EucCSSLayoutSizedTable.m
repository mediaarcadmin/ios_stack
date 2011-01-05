//
//  EucCSSLayoutSizedTable.m
//  libEucalyptus
//
//  Created by James Montgomerie on 04/01/2011.
//  Copyright 2011 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutSizedTable.h"

#import "EucCSSLayoutTableWrapper.h"

@implementation EucCSSLayoutSizedTable

- (id)initWithTableWrapper:(EucCSSLayoutTableWrapper *)tableWrapper
               scaleFactor:(CGFloat)scaleFactor
{
    if((self = [super initWithScaleFactor:scaleFactor])) {
        _tableWrapper = [tableWrapper retain];
    }
    return self;
}

- (void)dealloc
{
    [_tableWrapper release];
    
    [super dealloc];
}

@end
