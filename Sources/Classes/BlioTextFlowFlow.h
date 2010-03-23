//
//  BlioTextFlowFlow.h
//  BlioApp
//
//  Created by James Montgomerie on 18/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libEucalyptus/EucCSSDocumentTree.h>

@class BlioTextFlow, BlioTextFlowParagraph;

@interface BlioTextFlowFlow : NSObject <EucCSSDocumentTreeNode> {
    uint32_t _key;
    
    // Nothing below is retained.
    BlioTextFlow *_textFlow; 
    BlioTextFlowParagraph *_firstChild;
    uint32_t _childCount;
}

@property (nonatomic, assign, readonly) BlioTextFlow *textFlow;
@property (nonatomic, assign) uint32_t childCount;
@property (nonatomic, assign) BlioTextFlowParagraph *firstChild;

- (id)initWithTextFlow:(BlioTextFlow *)textFlow key:(uint32_t)key;

@end
