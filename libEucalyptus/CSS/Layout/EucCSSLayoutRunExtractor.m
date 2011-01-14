//
//  EucCSSLayoutRunExtractor.m
//  libEucalyptus
//
//  Created by James Montgomerie on 21/04/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSLayoutRunExtractor.h"
#import "EucCSSIntermediateDocument.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "EucCSSIntermediateDocumentConcreteNode.h"
#import "EucCSSLayoutRun.h"

#import <libcss/libcss.h>

@implementation EucCSSLayoutRunExtractor

@synthesize document = _document;

- (id)initWithDocument:(EucCSSIntermediateDocument *)document
{
    if((self = [super init])) {
        _document = [document retain];
    }
    return self;
}

- (void)dealloc
{
    [_document release];
    
    [super dealloc];
}

- (EucCSSIntermediateDocumentNode *)_layoutNodeForKey:(uint32_t)nodeKey
{
    if(nodeKey == 0) {
        return self.document.rootNode;
    } else {
        return [self.document nodeForKey:nodeKey];
    }
}

- (EucCSSLayoutRun *)runForNodeWithKey:(uint32_t)nextRunNodeKey;
{
    EucCSSLayoutRun *ret = nil;
    
    EucCSSIntermediateDocumentNode* currentDocumentNode = [self _layoutNodeForKey:nextRunNodeKey];
    
    if(currentDocumentNode) {
        if(!currentDocumentNode.isLayoutRunBreaker) {
            EucCSSIntermediateDocumentNode* previousNode = NULL;
            do {
                previousNode = currentDocumentNode.previous;
                if(previousNode.parent.key == currentDocumentNode.parent.key &&
                   previousNode && !previousNode.isLayoutRunBreaker) {
                    currentDocumentNode = previousNode;
                }
            } while(previousNode.parent.key == currentDocumentNode.parent.key &&
                    previousNode && !previousNode.isLayoutRunBreaker);
            if(previousNode.isLayoutRunBreaker) {
                if(previousNode == currentDocumentNode.parent) {
                    currentDocumentNode = previousNode;
                }
            }
        }        
        nextRunNodeKey = currentDocumentNode.key;
        
        do {
            if(!currentDocumentNode.isLayoutRunBreaker) {
                // This is an inline element - start a run.
                ret = [EucCSSLayoutRun runWithNode:currentDocumentNode
                                    underLimitNode:currentDocumentNode.blockLevelParent
                                    stopBeforeNode:nil
                                             forId:nextRunNodeKey];
                
            } else {
                // This is a block-level element.
                // First run in a block has the ID of the block it's in.
                nextRunNodeKey = ((EucCSSIntermediateDocumentConcreteNode *)currentDocumentNode).key;  
                currentDocumentNode = currentDocumentNode.nextDisplayable;
            }
        } while(currentDocumentNode && !ret);
    }
    
    return ret;
}

- (EucCSSLayoutRun *)nextRunForRun:(EucCSSLayoutRun *)run
{
    if(run.nextNodeInDocument) {
        EucCSSLayoutRun *nextRun = [self runForNodeWithKey:run.nextNodeInDocument.key];
        return nextRun;
    } else {
        return nil;
    }
}


- (EucCSSLayoutRun *)previousRunForRun:(EucCSSLayoutRun *)run
{
    EucCSSIntermediateDocumentNode *previousNode = [self.document nodeForKey:run.id].previous;
    if(previousNode) {
        while(previousNode.isLayoutRunBreaker) {
            // If the previous node was a block, there's no run between it and
            // this run, so we have to move further back.
            previousNode = previousNode.previous;
        }

        if(previousNode) {
            EucCSSLayoutRun *previousRun = [self runForNodeWithKey:previousNode.key];
            if(previousRun.id == run.id) {
                // This happens if we're already at the first node.
                return nil;
            }
            return previousRun;
        }
    }       
    return nil;
}

@end
