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
        css_computed_style *currentNodeStyle = currentDocumentNode.computedStyle;
        
        if(!currentNodeStyle || 
           css_computed_float(currentNodeStyle) != CSS_FLOAT_NONE ||
           css_computed_display(currentNodeStyle, false) != CSS_DISPLAY_BLOCK) {
            EucCSSIntermediateDocumentNode* previousNode = NULL;
            css_computed_style *previousStyle = NULL;
            do {
                previousNode = currentDocumentNode.previous;
                previousStyle = previousNode.computedStyle;
                if(previousNode.blockLevelParent.key == currentDocumentNode.blockLevelParent.key &&
                   previousNode && (!previousStyle || css_computed_display(previousStyle, false) != CSS_DISPLAY_BLOCK || css_computed_float(previousStyle) != CSS_FLOAT_NONE)) {
                    currentDocumentNode = previousNode;
                    currentNodeStyle = previousStyle;
                }
            } while(previousNode.blockLevelParent.key == currentDocumentNode.blockLevelParent.key &&
                    previousNode && (!previousStyle || css_computed_display(previousStyle, false) != CSS_DISPLAY_BLOCK || css_computed_float(previousStyle) != CSS_FLOAT_NONE));
            if(previousStyle && css_computed_display(previousStyle, false) == CSS_DISPLAY_BLOCK && css_computed_float(previousStyle) == CSS_FLOAT_NONE) {
                if(previousNode == currentDocumentNode.parent) {
                    currentDocumentNode = previousNode;
                    currentNodeStyle = currentDocumentNode.computedStyle;
                }
            }
        }        
        nextRunNodeKey = currentDocumentNode.key;
        
        do {
            css_computed_style *currentNodeStyle = currentDocumentNode.computedStyle;
            if(!currentNodeStyle || 
               css_computed_float(currentNodeStyle) != CSS_FLOAT_NONE ||
               css_computed_display(currentNodeStyle, false) != CSS_DISPLAY_BLOCK) {
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
        return [self runForNodeWithKey:run.nextNodeInDocument.key];
    } else {
        return nil;
    }
}


- (EucCSSLayoutRun *)previousRunForRun:(EucCSSLayoutRun *)run
{
    EucCSSIntermediateDocumentNode *previousNode = [self.document nodeForKey:run.id].previous;
    if(previousNode) {
        css_computed_style *previousNodeStyle = previousNode.computedStyle;

        while(previousNodeStyle && 
              css_computed_display(previousNodeStyle, false) == CSS_DISPLAY_BLOCK && 
              css_computed_float(previousNodeStyle) == CSS_FLOAT_NONE) {
            // If the previous node was a block, there's no run between it and
            // this run, so we have to move further back.
            previousNode = previousNode.previous;
            previousNodeStyle = previousNode.computedStyle;
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
