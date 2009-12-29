//
//  EucHTMLDocumentRenderer.h
//  LibCSSTest
//
//  Created by James Montgomerie on 13/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EucHTMLDocumentNode;

@interface EucHTMLDocumentRenderer : NSObject {
    BOOL _previousInlineCharacterWasSpace;
}

- (EucHTMLDocumentNode *)layoutNode:(EucHTMLDocumentNode *)node 
                                atX:(uint32_t)atX
                                atY:(uint32_t)atY
                    maxContentWidth:(uint32_t)maxWidth 
                   maxContentHeight:(uint32_t)maxHeight
                       laidOutNodes:(NSMutableArray *)laidOutNodes
                      laidOutFloats:(NSMutableArray *)laidOutFloats;

@end
