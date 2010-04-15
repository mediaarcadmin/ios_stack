//
//  BlioTextFlowParagraphWords.h
//  BlioApp
//
//  Created by James Montgomerie on 18/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libEucalyptus/EucCSSDocumentTreeNode.h>

@class BlioTextFlowParagraph, BlioTextFlow, BlioBookmarkPoint;

@interface BlioTextFlowParagraphWords : NSObject <EucCSSDocumentTreeNode> {
    BlioTextFlow *_textFlow;           // nonretained.
    BlioTextFlowParagraph *_paragraph; // nonretained.
    
    NSArray *_ranges;
    uint32_t _key;
    
    NSArray *_wordStrings;
}

@property (nonatomic, assign) NSArray *ranges;

- (id)initWithTextFlow:(BlioTextFlow *)textFlow
             paragraph:(BlioTextFlowParagraph *)paragraph 
                ranges:(NSArray *)ranges
                   key:(uint32_t)key;

- (BlioBookmarkPoint *)wordOffsetToBookmarkPoint:(uint32_t)wordOffset;
- (NSArray *)preprocessedWordStrings; // for the layout engine.
- (NSArray *)wordStrings;
- (NSArray *)words;

@end
