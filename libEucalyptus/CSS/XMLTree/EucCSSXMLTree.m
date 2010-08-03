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

@synthesize idToNode = _idToNode;

typedef struct EucCSSXMLTreeContext
{
    Class xmlTreeNodeClass;
    NSMutableArray *nodes;
    NSMutableDictionary *idToNode;
    EucCSSXMLTreeNode *currentNode;
} EucCSSXMLTreeContext;

static void EucCSSXMLTreeStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts) 
{
    EucCSSXMLTreeContext *context = (EucCSSXMLTreeContext *)ctx;
    NSMutableArray *nodes = context->nodes;
    EucCSSXMLTreeNode *currentNode = context->currentNode;
    
    EucCSSXMLTreeNode *newNode = [[context->xmlTreeNodeClass alloc] initWithKey:nodes.count + 1
                                                                   kind:EucCSSDocumentTreeNodeKindElement];
    
    newNode.name = [NSString stringWithUTF8String:name];
        
    if(*atts) {
        NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
        for(int i = 0; atts[i]; i+=2) {
            NSString *name = [NSString stringWithUTF8String:atts[i]];
            NSString *value = [NSString stringWithUTF8String:atts[i+1]];
            [attributes setObject:value
                           forKey:name];
            if(strcasecmp("id", atts[i]) == 0) {
                [context->idToNode setValue:newNode forKey:value];
            }
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
    EucCSSXMLTreeNode *newNode = [[context->xmlTreeNodeClass alloc] initWithKey:nodes.count + 1
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
    return [self initWithData:xmlData xmlTreeNodeClass:[EucCSSXMLTreeNode class]];
}

- (id)initWithData:(NSData *)xmlData xmlTreeNodeClass:(Class)xmlTreeNodeClass
{
    if((self = [super init])) {
        _xmlTreeNodeClass = xmlTreeNodeClass;
        NSUInteger xmlLength = xmlData.length;
        if(xmlLength) {
            NSMutableArray *buildNodes = [[NSMutableArray alloc] init];
            NSMutableDictionary *buildIdToNodes = [[NSMutableDictionary alloc] init];
            EucCSSXMLTreeContext context = { _xmlTreeNodeClass, buildNodes, buildIdToNodes, NULL };
            
            XML_Parser parser = XML_ParserCreate("UTF-8");
            XML_SetUserData(parser, &context);    
            XML_UseForeignDTD(parser, XML_TRUE);
            
           /* XML_SetDoctypeDeclHander(parser, XML_StartDoctypeDeclHandler start, XML_EndDoctypeDeclHandler end);        
            XML_SetCommentHandler(parser, XML_CommentHandler handler)
           */ XML_SetElementHandler(parser, EucCSSXMLTreeStartElementHandler, EucCSSXMLTreeEndElementHandler);
            XML_SetCharacterDataHandler(parser, EucCSSXMLTreeCharactersHandler);
           // XML_SetSkippedEntityHandler(parser, paragraphBuildingSkippedEntityHandler);
            
            XML_Parse(parser, [xmlData bytes], xmlLength, XML_FALSE);
            
            XML_ParserFree(parser);
            
            if(buildNodes.count) {
                _nodes = buildNodes;
                _idToNode = buildIdToNodes;
            } else {
                [buildNodes release];
                [_idToNode release];
            }
        }
    }
    return self;
}

- (void)dealloc
{
    [_idToNode release];
    [_nodes release];
    [super dealloc];
}

- (EucCSSXMLTreeNode *)root
{
    return [_nodes objectAtIndex:0];
}

- (EucCSSXMLTreeNode *)nodeForKey:(uint32_t)key
{
    if(key > 0) { 
        return [_nodes objectAtIndex:key-1];
    } else {
        return nil;
    }
}

- (uint32_t)lastKey
{
    return _nodes.count;
}

@end
