//
//  BlioTextFlowFlowTree.m
//  BlioApp
//
//  Created by James Montgomerie on 18/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "BlioTextFlowFlowTree.h"
#import "BlioTextFlowFlow.h"
#import "BlioTextFlowParagraph.h"
#import "BlioTextFlowParagraphWords.h"
#import "BlioBookmark.h"

#import <expat/expat.h>

@implementation BlioTextFlowFlowTree

typedef struct BlioTextFlowFlowTreeContext 
{
    BlioTextFlow *textFlow;
    NSMutableArray *nodes;
    id<EucCSSDocumentTreeNode> currentNode;
    BlioTextFlowParagraph *lastOpenedParagraph;
    uint32_t paragraphCount;
    NSMutableArray *wordRangeAccumulator;
}  BlioTextFlowFlowTreeContext;

static void BlioTextFlowFlowTreeStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts) 
{
    BlioTextFlowFlowTreeContext *context = (BlioTextFlowFlowTreeContext *)ctx;
    BlioTextFlow *textFlow = context->textFlow;
    NSMutableArray *nodes = context->nodes;
    id<EucCSSDocumentTreeNode> currentNode = context->currentNode;
    
    if(strcmp("Flow", name) == 0) {
        if(currentNode == NULL) {
            BlioTextFlowFlow *flowNode = [[BlioTextFlowFlow alloc] initWithTextFlow:textFlow 
                                                                                key:nodes.count + 1];
            [nodes addObject:flowNode];
            context->currentNode = flowNode;
            [flowNode release];
        } else {
            NSLog(@"Unexpectedly seeing <Flow> node as non-first element - ignoring.");
        }
    } else if(strcmp("Paragraph", name) == 0) {
        if([currentNode isKindOfClass:[BlioTextFlowFlow class]]) { 
            BlioTextFlowFlow *flowNode = (BlioTextFlowFlow *)currentNode;
            
            BlioTextFlowParagraph *paragraphNode = [[BlioTextFlowParagraph alloc] initWithTextFlow:textFlow
                                                                                          flowNode:flowNode
                                                                                               key:nodes.count + 1];
            
            paragraphNode.previousSibling = context->lastOpenedParagraph;
            context->lastOpenedParagraph.nextSibling = paragraphNode;
            context->lastOpenedParagraph = paragraphNode;
            
            [nodes addObject:paragraphNode];
            context->currentNode = paragraphNode;
            [paragraphNode release];
        } else {
            NSLog(@"Unexpectedly seeing <Paragraph> node as non-top-level node - ignoring.");
        }
        ++context->paragraphCount;
    } else if(strcmp("Words", name) == 0) {
        if([currentNode isKindOfClass:[BlioTextFlowParagraph class]]) {
            uint32_t page = 0;
            uint32_t block = 0;
            uint32_t start = 0;
            uint32_t end = UINT32_MAX;
            
            for(int i = 0; atts[i]; i+=2) {
                if (strcmp("Page", atts[i]) == 0) {
                    page = atoi(atts[i+1]);
                } else if(strcmp("Start", atts[i]) == 0) {
                    start = atoi(atts[i+1]);
                } else if (strcmp("End", atts[i]) == 0) {
                    end = atoi(atts[i+1]);
                } else if (strcmp("Block", atts[i]) == 0) {
                    block = atoi(atts[i+1]);
                } 
            }

            if(!context->wordRangeAccumulator) {
                context->wordRangeAccumulator = [[NSMutableArray alloc] init];
            }
            
            BlioBookmarkPoint *startPoint = [[BlioBookmarkPoint alloc] init];
            startPoint.layoutPage = page + 1;
            startPoint.blockOffset = block;
            startPoint.wordOffset = start;

            BlioBookmarkPoint *endPoint = [[BlioBookmarkPoint alloc] init];
            endPoint.layoutPage = page + 1;
            endPoint.blockOffset = block;
            endPoint.wordOffset = end;
            
            BlioBookmarkRange *range = [[BlioBookmarkRange alloc] init];
            range.startPoint = startPoint;
            range.endPoint = endPoint;
            
            [context->wordRangeAccumulator addObject:range];

            [startPoint release];
            [endPoint release];
            [range release];
        } else {
            NSLog(@"Unexpectedly seeing <Words> node as non-paragraph-child node - ignoring.");
        }
    } else {
        NSLog(@"Unexpectedly seeing <%s> node - ignoring.", name);
    }
}

static void BlioTextFlowFlowTreeEndElementHandler(void *ctx, const XML_Char *name) 
{
    BlioTextFlowFlowTreeContext *context = (BlioTextFlowFlowTreeContext *)ctx;
    id<EucCSSDocumentTreeNode> currentNode = context->currentNode;
            
    if(strcmp("Words", name) != 0) { // Word nodes are not tracked in the context.
        if(strcmp("Paragraph", name) == 0) {
            NSMutableArray *nodes = context->nodes;
            
            if ([currentNode isKindOfClass:[BlioTextFlowParagraph class]]) {
                BlioTextFlowParagraph *paragraphNode = (BlioTextFlowParagraph *)currentNode;
                BlioTextFlowParagraphWords *words = [[BlioTextFlowParagraphWords alloc] initWithTextFlow:context->textFlow 
                                                                                               paragraph:paragraphNode 
                                                                                                  ranges:context->wordRangeAccumulator
                                                                                                     key:nodes.count + 1];
                paragraphNode.paragraphWords = words;
                [context->wordRangeAccumulator release];
                context->wordRangeAccumulator = nil;
            
                [nodes addObject:words];
                [words release];
            }
        }

        id<EucCSSDocumentTreeNode> parent = currentNode.parent;
        if(parent) {
            context->currentNode = parent;
        }
    }
}

- (id)initWithTextFlow:(BlioTextFlow *)textFlow data:(NSData *)xmlData
{
    if((self = [super init])) {
        NSUInteger xmlLength = xmlData.length;
        if(xmlLength) {
            NSMutableArray *buildNodes = [[NSMutableArray alloc] init];
            BlioTextFlowFlowTreeContext context = { textFlow, buildNodes, NULL, 0 };
            
            XML_Parser parser = XML_ParserCreate("UTF-8");
            XML_SetUserData(parser, &context);    
            XML_UseForeignDTD(parser, XML_TRUE);
            
            XML_SetElementHandler(parser, BlioTextFlowFlowTreeStartElementHandler, BlioTextFlowFlowTreeEndElementHandler);
            
            XML_Parse(parser, [xmlData bytes], xmlLength, XML_FALSE);
            
            XML_ParserFree(parser);
            
            if(buildNodes.count > 2) {
                BlioTextFlowFlow *flowNode = [buildNodes objectAtIndex:0];
                flowNode.childCount = context.paragraphCount;
                flowNode.firstChild = [buildNodes objectAtIndex:1];
                _nodes = buildNodes;
            } else {
                [buildNodes release];
            }
        }
    }
    return self;
}

- (BlioTextFlowParagraph *)firstParagraph
{
    return self.root.firstChild;
}

- (void)dealloc
{
    [_nodes release];
    
    [super dealloc];
}

- (id<EucCSSDocumentTreeNode>)root
{
    return [_nodes objectAtIndex:0];
}

- (id<EucCSSDocumentTreeNode>)nodeForKey:(uint32_t)key
{
    if(key > 0) { 
        return [_nodes objectAtIndex:key-1];
    } else {
        return nil;
    }
}

- (id<EucCSSDocumentTreeNode>)nodeWithId:(NSString *)identifier;
{
    return nil;
}

- (uint32_t)lastKey
{
    return [_nodes count] + 1;
}

@end
