//
//  EucHTMLLayouter.h
//  LibCSSTest
//
//  Created by James Montgomerie on 13/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EucHTMLDocument, EucHTMLLayoutPositionedBlock;

typedef struct EucHTMLLayoutBookmark
{
    uint32_t nodeKey;
    uint32_t wordOffset;
    uint32_t componentOffset;
} EucHTMLLayoutBookmark;

@interface EucHTMLLayouter : NSObject {
    EucHTMLDocument *_document;
}

@property (nonatomic, retain) EucHTMLDocument *document;

- (EucHTMLLayoutPositionedBlock *)layoutFromNodeWithId:(uint32_t)nodeId
                                            wordOffset:(uint32_t)wordOffset
                                          hyphenOffset:(uint32_t)hyphenOffset
                                               inFrame:(CGRect)frame;

@end
