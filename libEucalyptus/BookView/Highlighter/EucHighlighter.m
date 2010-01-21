//
//  EucHighlighter.m
//  libEucalyptus
//
//  Created by James Montgomerie on 20/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucHighlighter.h"
#import "EucHighlighterOverlayView.h"

@implementation EucHighlighter

- (BOOL)attachToView:(UIView *)view forTapAtPoint:(CGPoint)point
{
    _overlayView = [[EucHighlighterOverlayView alloc] initWithFrame:view.bounds];
    [view addSubview:_overlayView];
    return YES;
}

- (void)detatchFromView
{
    
}

- (void)temporarilyHighlightElementAtIndex:(NSInteger)elementIndex inBlockAtIndex:(NSInteger)blockIndex animated:(BOOL)animated
{
    
}

- (void)clearTemporaryHighlights
{
    
}

- (NSInteger)highlightElementsFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    return 0;
}

- (void)removeHighlight:(NSInteger)highlightId 
{
    
}

@end
