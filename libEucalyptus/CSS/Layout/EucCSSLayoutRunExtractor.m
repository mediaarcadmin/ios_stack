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
#import "EucCSSLayoutDocumentRun.h"

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

- (EucCSSLayoutDocumentRun *)documentRunForNodeWithKey:(uint32_t)nextRunNodeKey;
{
    EucCSSLayoutDocumentRun *ret = nil;
    
    EucCSSIntermediateDocumentNode* currentDocumentNode = [self _layoutNodeForKey:nextRunNodeKey];
    
    if(currentDocumentNode) {
        if(currentDocumentNode.display != CSS_DISPLAY_BLOCK) {
            EucCSSIntermediateDocumentNode* previousNode = NULL;
            do {
                previousNode = currentDocumentNode.previous;
                if(previousNode.blockLevelParent.key == currentDocumentNode.blockLevelParent.key &&
                   previousNode && previousNode.display != CSS_DISPLAY_BLOCK) {
                    currentDocumentNode = previousNode;
                }
            } while(previousNode.blockLevelParent.key == currentDocumentNode.blockLevelParent.key &&
                    previousNode && previousNode.display != CSS_DISPLAY_BLOCK);
            if(previousNode.display == CSS_DISPLAY_BLOCK) {
                if(previousNode == currentDocumentNode.parent) {
                    currentDocumentNode = previousNode;
                }
            }
        }        
        nextRunNodeKey = currentDocumentNode.key;
        
        do {
            if(currentDocumentNode.display != CSS_DISPLAY_BLOCK) {                
                // This is an inline element - start a run.
                ret = [EucCSSLayoutDocumentRun documentRunWithNode:currentDocumentNode
                                                    underLimitNode:currentDocumentNode.blockLevelParent
                                                             forId:nextRunNodeKey
                                                       scaleFactor:1.0f];
                
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

- (EucCSSLayoutDocumentRun *)nextDocumentRunForDocumentRun:(EucCSSLayoutDocumentRun *)run
{
    if(run.nextNodeInDocument) {
        return [self documentRunForNodeWithKey:run.nextNodeInDocument.key];
    } else {
        return nil;
    }
}


- (EucCSSLayoutDocumentRun *)previousDocumentRunForDocumentRun:(EucCSSLayoutDocumentRun *)run
{
    EucCSSIntermediateDocumentNode *previousNode = [self.document nodeForKey:run.id].previous;
    if(previousNode) {
        while(previousNode.display == CSS_DISPLAY_BLOCK) {
            // If the previous node was a block, there's no run between it and
            // this run, so we have to move further back.
            previousNode = previousNode.previous;
        }

        if(previousNode) {
            EucCSSLayoutDocumentRun *previousRun = [self documentRunForNodeWithKey:previousNode.key];
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
