//
//  EucCSSXMLTree.m
//  libEucalyptus
//
//  Created by James Montgomerie on 11/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSXMLTree.h"
#import "EucCSSXMLTreeNode.h"

#import <expat/expat.h>

@implementation EucCSSXMLTree

typedef struct EucCSSXMLTreeContext
{
    NSMutableArray *nodes;
    EucCSSXMLTreeNode *currentNode;
} EucCSSXMLTreeContext;

static void EucCSSXMLTreeStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts) 
{
    EucCSSXMLTreeContext *context = (EucCSSXMLTreeContext *)ctx;
    NSMutableArray *nodes = context->nodes;
    EucCSSXMLTreeNode *currentNode = context->currentNode;
    
    EucCSSXMLTreeNode *newNode = [[EucCSSXMLTreeNode alloc] initWithKey:nodes.count + 1
                                                                   kind:EucCSSDocumentTreeNodeKindElement];
    
    newNode.name = [NSString stringWithUTF8String:name];
        
    if(*atts) {
        NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
        for(int i = 0; atts[i]; i+=2) {
            [attributes setObject:[NSString stringWithUTF8String:atts[i+1]]
                           forKey:[NSString stringWithUTF8String:atts[i]]];
        }
        newNode.attributes = attributes;
        [attributes release];
    }
    
    [nodes addObject:newNode];
    [currentNode addChild:newNode];

    context->currentNode = newNode;
         
    [newNode release];
}

static void EucCSSXMLTreeEndElementHandler(void *ctx, const XML_Char *name) 
{
    EucCSSXMLTreeContext *context = (EucCSSXMLTreeContext *)ctx;
    EucCSSXMLTreeNode *currentNode = context->currentNode;
    
    EucCSSXMLTreeNode *parent = currentNode.parent;
    if(parent) {
        context->currentNode = parent;
    }
}

static void EucCSSXMLTreeCharactersHandler(void *ctx, const XML_Char *chars, int len) 
{
    EucCSSXMLTreeContext *context = (EucCSSXMLTreeContext *)ctx;
    NSMutableArray *nodes = context->nodes;
    EucCSSXMLTreeNode *currentNode = context->currentNode;
    EucCSSXMLTreeNode *newNode = [[EucCSSXMLTreeNode alloc] initWithKey:nodes.count + 1
                                                                   kind:EucCSSDocumentTreeNodeKindText];
    NSData *characterData = [[NSData alloc] initWithBytes:chars length:len];
    newNode.characters = characterData;
    [characterData release];
    
    [nodes addObject:newNode];
    [currentNode addChild:newNode];
    [newNode release];
}

- (id)initWithData:(NSData *)xmlData
{
    if((self = [super init])) {
        NSMutableArray *buildNodes = [[NSMutableArray alloc] init];
        EucCSSXMLTreeContext context = { buildNodes, NULL };
        
        XML_Parser parser = XML_ParserCreate("UTF-8");
        XML_SetUserData(parser, &context);    
        XML_UseForeignDTD(parser, XML_TRUE);
        
       /* XML_SetDoctypeDeclHander(parser, XML_StartDoctypeDeclHandler start, XML_EndDoctypeDeclHandler end);        
        XML_SetCommentHandler(parser, XML_CommentHandler handler)
       */ XML_SetElementHandler(parser, EucCSSXMLTreeStartElementHandler, EucCSSXMLTreeEndElementHandler);
        XML_SetCharacterDataHandler(parser, EucCSSXMLTreeCharactersHandler);
       // XML_SetSkippedEntityHandler(parser, paragraphBuildingSkippedEntityHandler);
        
        XML_Parse(parser, [xmlData bytes], [xmlData length], XML_FALSE);
        
        XML_ParserFree(parser);
        
        _nodes = buildNodes;
    }
    return self;
}

- (void)dealloc
{
    [_nodes release];
    [super dealloc];
}

- (EucCSSXMLTreeNode *)root
{
    return [_nodes objectAtIndex:0];
}

- (EucCSSXMLTreeNode *)nodeForKey:(uint32_t)key
{
    return [_nodes objectAtIndex:key-1];
}

@end
