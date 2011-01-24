//
//  EucCSSXMLTree.m
//  libEucalyptus
//
//  Created by James Montgomerie on 11/03/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSXMLTree.h"
#import "EucCSSXMLTreeNode.h"

#import "THLog.h"

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
    
    CFMutableDataRef characterAccumulator;
    
    NSDictionary *dtdMap;
    NSString *defaultDTDID;
} EucCSSXMLTreeContext;

static void EucCSSXMLTreeProcessAccumulatedCharacters(EucCSSXMLTreeContext *context)
{
    if(context->characterAccumulator) {
        if(context->currentNode) {
            // Throw away characters before the root node.
            NSMutableArray *nodes = context->nodes;
            EucCSSXMLTreeNode *currentNode = context->currentNode;
            EucCSSXMLTreeNode *newNode = [[context->xmlTreeNodeClass alloc] initWithKey:nodes.count + 1
                                                                                   kind:EucCSSDocumentTreeNodeKindText];

            newNode.characters = (NSData *)context->characterAccumulator;

            [nodes addObject:newNode];
            [currentNode addChild:newNode];
            
            [newNode release];
        }
        CFRelease(context->characterAccumulator);
        context->characterAccumulator = NULL;
    }
}

static void EucCSSXMLTreeStartElementHandler(void *ctx, const XML_Char *name, const XML_Char **atts) 
{
    EucCSSXMLTreeContext *context = (EucCSSXMLTreeContext *)ctx;
    
    EucCSSXMLTreeProcessAccumulatedCharacters(context);
    
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
    
    EucCSSXMLTreeProcessAccumulatedCharacters(context);
    
    EucCSSXMLTreeNode *currentNode = context->currentNode;
    
    EucCSSXMLTreeNode *parent = currentNode.parent;
    if(parent) {
        context->currentNode = parent;
    }
}

static void EucCSSXMLTreeCharactersHandler(void *ctx, const XML_Char *chars, int len) 
{
    EucCSSXMLTreeContext *context = (EucCSSXMLTreeContext *)ctx;
    if(!context->characterAccumulator) {
        CFMutableDataRef characterData = CFDataCreateMutable(kCFAllocatorDefault, 0);
        CFDataAppendBytes(characterData, (const UInt8 *)chars, len);
        context->characterAccumulator = characterData;
    } else {
        CFDataAppendBytes(context->characterAccumulator, (const UInt8 *)chars, len);
    }
}

int EucCSSXMLTreeExternalEntityRefHandler(XML_Parser parser,
                                          const XML_Char *parserContext,
                                          const XML_Char *base,
                                          const XML_Char *systemID,
                                          const XML_Char *publicID) 
{
    EucCSSXMLTreeContext *context = (EucCSSXMLTreeContext *)XML_GetUserData(parser);
    
    NSString *DTDPath = nil;
    
    NSString *publicIDString = nil;
    if(publicID) {
        publicIDString = [NSString stringWithUTF8String:publicID];
        DTDPath = [context->dtdMap objectForKey:publicIDString];
        if(!DTDPath) {
            THWarn(@"No local path specified for DTD for public ID \"%s\", system ID \"%s\"", publicID, systemID);
        }
    } 
    if(!DTDPath) {
        THLog(@"Using default DTD %@", context->defaultDTDID);
        DTDPath = [context->dtdMap objectForKey:context->defaultDTDID];
    }
    
    if(!DTDPath) {
        THWarn(@"Could not find local DTD for public ID \"%s\", system ID \"%s\"", publicID, systemID);
    } else {
        NSData *DTDData = [[NSData alloc] initWithContentsOfMappedFile:DTDPath];
        XML_Parser externalEntityParser = XML_ExternalEntityParserCreate(parser, parserContext, NULL);
        
        XML_Parse(externalEntityParser, [DTDData bytes], [DTDData length], XML_TRUE);
        
        XML_ParserFree(externalEntityParser);
        [DTDData release];
    }
    
    return XML_STATUS_OK;
}

- (id)initWithData:(NSData *)xmlData
{
    return [self initWithData:xmlData xmlTreeNodeClass:[EucCSSXMLTreeNode class]];
}

- (id)initWithData:(NSData *)xmlData xmlTreeNodeClass:(Class)xmlTreeNodeClass
DTDPublicIDToLocalPathMap:(NSDictionary *)dtdMap defaultDTDPublicID:(NSString *)defaultDTDID
{
    if((self = [super init])) {
        _xmlTreeNodeClass = xmlTreeNodeClass;
        NSUInteger xmlLength = xmlData.length;
        if(xmlLength) {
            NSMutableArray *buildNodes = [[NSMutableArray alloc] init];
            NSMutableDictionary *buildIdToNodes = [[NSMutableDictionary alloc] init];
            EucCSSXMLTreeContext context = { self, _xmlTreeNodeClass, buildNodes, buildIdToNodes, NULL, NULL, dtdMap, defaultDTDID };
            
            XML_Parser parser = XML_ParserCreate("UTF-8");
            XML_SetUserData(parser, &context);    
            
            XML_UseForeignDTD(parser, defaultDTDID != nil);
            XML_SetParamEntityParsing(parser, XML_PARAM_ENTITY_PARSING_ALWAYS);
            XML_SetExternalEntityRefHandler(parser, EucCSSXMLTreeExternalEntityRefHandler);
            
            XML_SetElementHandler(parser, EucCSSXMLTreeStartElementHandler, EucCSSXMLTreeEndElementHandler);
            XML_SetCharacterDataHandler(parser, EucCSSXMLTreeCharactersHandler);
            
            XML_Parse(parser, [xmlData bytes], xmlLength, XML_TRUE);
            
            XML_ParserFree(parser);

            if(context.characterAccumulator) {
                CFRelease(context.characterAccumulator);
            }
            
            NSUInteger nodesCount = buildNodes.count;
            if(nodesCount) {
                _nodesCount = nodesCount;
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

- (id)initWithData:(NSData *)xmlData xmlTreeNodeClass:(Class)xmlTreeNodeClass
{
    return [self initWithData:xmlData xmlTreeNodeClass:xmlTreeNodeClass DTDPublicIDToLocalPathMap:nil defaultDTDPublicID:nil];
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
    if(key > 0 && key <= _nodesCount) { 
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
