/*
 Copyright 2010 Microsoft Corp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "WAXMLHelper.h"
#import "WAAtomPubEntry.h"

@implementation WAXMLHelper

+ (void)performXPath:(NSString *)xpath onDocument:(xmlDocPtr)doc block:(void (^)(xmlNodePtr))block
{
    [self performXPath:xpath onNode:(xmlNodePtr)doc block:block];
}

+ (void)performXPath:(NSString *)xpath onNode:(xmlNodePtr)node block:(void (^)(xmlNodePtr))block
{
    xmlDocPtr doc;
    if(node->type == XML_DOCUMENT_NODE) {
        doc = (xmlDocPtr)node;
    } else {
        doc = node->doc;
    }
    
    xmlXPathContextPtr xpathCtx = xmlXPathNewContext(doc);
    if (!xpathCtx) {
        return;
    }
    
    xmlNodePtr root = xmlDocGetRootElement(doc);
    xpathCtx->node = ((void*)node == (void*)doc) ? root : node;
    
    // anchor at our current node
    if (root != NULL) {
        for (xmlNsPtr nsPtr = root->nsDef; nsPtr != NULL; nsPtr = nsPtr->next) {
            const xmlChar* prefix = nsPtr->prefix;
            if (prefix != NULL) {
                xmlXPathRegisterNs(xpathCtx, prefix, nsPtr->href);
            } else {
                xmlXPathRegisterNs(xpathCtx, (xmlChar*)"_default", nsPtr->href);
            }            
        }
    }
    
    xmlXPathObjectPtr xpathObj;
    xpathObj = xmlXPathEval((const xmlChar *)[xpath UTF8String], xpathCtx);
    if (xpathObj) {
        xmlNodeSetPtr nodeSet = xpathObj->nodesetval;
        if (nodeSet) {
            for (int index = 0; index < nodeSet->nodeNr; index++) {
                block(nodeSet->nodeTab[index]);
            }
        }

        xmlXPathFreeObject(xpathObj);
    }
    
    xmlXPathFreeContext(xpathCtx);
}

+ (NSString *)getElementValue:(xmlNodePtr)parent name:(NSString*)name
{
    xmlChar *nameStr = (xmlChar*)[name UTF8String];
    
    for (xmlNodePtr child = xmlFirstElementChild(parent); child; child = xmlNextElementSibling(child)) {
        if (xmlStrcmp(child->name, nameStr) == 0) {
            xmlChar *value = xmlNodeGetContent(child);
			NSString *str = [[NSString alloc] initWithUTF8String:(const char*)value];
            xmlFree(value);
            return [str autorelease];
        }
    }
    
    return nil;
}

+ (NSString *)getStringErrorValue:(xmlDocPtr)doc
{
    if (!doc) {
        return nil;
    }
    
    NSMutableString *value = [NSMutableString string];
    
    xmlChar *content = xmlNodeGetContent((xmlNodePtr)doc);
    [value appendString:[NSString stringWithUTF8String:(const char*)content]];
    xmlFree(content);
    
    return value;
}

+ (NSError *)checkForError:(xmlDocPtr)doc withStatusCode:(NSInteger)statusCode
{
    if (!doc) {
        return nil;
    }
    
    xmlNodePtr root = xmlDocGetRootElement(doc);
    if (xmlStrcmp(root->name, (xmlChar*)"Error") == 0) {
        NSString *code = [self getElementValue:root name:@"Code"];
        NSString *message = [self getElementValue:root name:@"Message"];
        NSString *detail = [self getElementValue:root name:@"AuthenticationErrorDetail"];
        
        if (detail == nil) {
            detail = @"";
        }
        
        if (code == nil) {
            code = @"";
        }
        
        // NSLocalizedRecoverySuggestionErrorKey
        return [NSError errorWithDomain:@"com.microsoft.WAToolkit" 
                                   code:statusCode 
                               userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                         message, NSLocalizedDescriptionKey, 
                                         detail, NSLocalizedFailureReasonErrorKey, 
                                         code, @"AzureReasonCode", nil]];
    }

    if (xmlStrcmp(root->name, (xmlChar*)"error") == 0) {
        NSString* code = [self getElementValue:root name:@"code"];
        NSString* message = [self getElementValue:root name:@"message"];
        
        return [NSError errorWithDomain:@"com.microsoft.WAToolkit" 
                                   code:statusCode
                               userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                         message, NSLocalizedDescriptionKey, 
                                         code, @"AzureReasonCode", nil]];
    }
    
    return nil;
}

+ (void)parseAtomPub:(xmlDocPtr)doc block:(void (^)(WAAtomPubEntry *))block
{
    [WAXMLHelper performXPath:@"/_default:feed/_default:entry" onDocument:doc block:^(xmlNodePtr node) {
         WAAtomPubEntry* entry = [[WAAtomPubEntry alloc] initWithNode:node];
         block(entry);
         [entry release];
     }];
}

@end
