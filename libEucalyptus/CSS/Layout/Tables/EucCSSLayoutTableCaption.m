//
//  EucCSSLayoutTableCaption.m
//  libEucalyptus
//
//  Created by James Montgomerie on 21/12/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutTableCaption.h"
#import "EucCSSLayoutTableWrapper.h"

#import "EucCSSLayoutSizedBlock.h"

#import "EucCSSLayouter.h"

#import "EucCSSIntermediateDocumentNode.h"

#import <libcss/libcss.h>

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

- (BOOL)documentNodeIsRepresentative
{
    return self.documentNode.display == CSS_DISPLAY_TABLE_CAPTION;
}

- (EucCSSLayoutSizedBlock *)sizedContentsWithScaleFactor:(CGFloat)scaleFactor
{
    NSParameterAssert(self.documentNodeIsRepresentative);
    EucCSSLayoutSizedBlock *ret = (EucCSSLayoutSizedBlock *)[self.wrapper.layouter sizedContainerFromNodeWithKey:self.documentNode.key
                                                                                           stopBeforeNodeWithKey:0
                                                                                                     scaleFactor:scaleFactor];
    NSParameterAssert([ret isKindOfClass:[EucCSSLayoutSizedBlock class]]);
    return ret;
}

@end
