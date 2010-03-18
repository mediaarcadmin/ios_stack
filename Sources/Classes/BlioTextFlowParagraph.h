//
//  BlioTextFlowParagraph.h
//  BlioApp
//
//  Created by James Montgomerie on 18/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libEucalyptus/EucCSSDocumentTreeNode.h>

@class BlioTextFlow, BlioTextFlowFlow, BlioTextFlowParagraphWords;

@interface BlioTextFlowParagraph : NSObject <EucCSSDocumentTreeNode> {
    uint32_t _key;
    
    // Nothing below is retained.
    BlioTextFlow *_textFlow; 
    
    BlioTextFlowFlow *_parent;
    BlioTextFlowParagraph *_previousSibling;
    BlioTextFlowParagraph *_nextSibling;
    
    BlioTextFlowParagraphWords *_paragraphWords;
}

@property (nonatomic, assign, readonly) BlioTextFlow *textFlow;
@property (nonatomic, assign) BlioTextFlowParagraphWords *paragraphWords;

@property (nonatomic, assign) BlioTextFlowParagraph *previousSibling;
@property (nonatomic, assign) BlioTextFlowParagraph *nextSibling;

- (id)initWithTextFlow:(BlioTextFlow *)textFlow 
              flowNode:(BlioTextFlowFlow *)flowNode
                   key:(uint32_t)key;

@end
