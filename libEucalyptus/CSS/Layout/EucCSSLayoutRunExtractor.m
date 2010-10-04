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
        css_computed_style *currentNodeStyle = currentDocumentNode.computedStyle;
        
        if(!currentNodeStyle || (css_computed_display(currentNodeStyle, false) & CSS_DISPLAY_BLOCK) != CSS_DISPLAY_BLOCK) {
            
        } else {
            currentDocumentNode = currentDocumentNode.nextDisplayable;
        }
        
        do {
            css_computed_style *currentNodeStyle = currentDocumentNode.computedStyle;
            if(!currentNodeStyle || (css_computed_display(currentNodeStyle, false) & CSS_DISPLAY_BLOCK) != CSS_DISPLAY_BLOCK) {                
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
    if(run.nextNodeInDocument) {
        return [self documentRunForNodeWithKey:[self.document nodeForKey:run.id].previous.key];
    } else {
        return nil;
    }
}

@end
