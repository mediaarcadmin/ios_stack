//
//  EucCSSXMLTree.m
//  libEucalyptus
//
//  Created by James Montgomerie on 11/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSXMLTree.h"
#import "EucCSSXMLTreeNode.h"

@implementation EucCSSXMLTree

@synthesize nodes = _nodes;
@synthesize idToNode = _idToNode;

typedef struct EucCSSXMLTreeContext
{    
    EucCSSXMLTree *self;
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
    
    CFStringRef nameString = CFStringCreateWithCString(kCFAllocatorDefault, (const char *)name, kCFStringEncodingUTF8);
    newNode.name = (NSString *)nameString;
    CFRelease(nameString);
        
    if(*atts) {
        for(int i = 0; atts[i]; i+=2) {
            if(atts[i+1]) {
                CFStringRef attributeName = CFStringCreateWithCString(kCFAllocatorDefault, (const char *)atts[i], kCFStringEncodingUTF8);
                CFStringRef attributeValue = CFStringCreateWithCString(kCFAllocatorDefault, (const char *)atts[i+1], kCFStringEncodingUTF8);
                [newNode addAttributeValue:(NSString *)attributeValue forName:(NSString *)attributeName];
                CFRelease(attributeName);
                CFRelease(attributeValue);
            }
        }
        
        NSString *idForNode = [newNode CSSID];
        if(idForNode) {
            [context->idToNode setValue:newNode forKey:idForNode];
        }        
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
    CFDataRef characterData = CFDataCreate(kCFAllocatorDefault, (const UInt8 *)chars, len);
    newNode.characters = (NSData *)characterData;
    CFRelease(characterData);
    
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
            EucCSSXMLTreeContext context = { self, _xmlTreeNodeClass, buildNodes, buildIdToNodes, NULL };
            
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
