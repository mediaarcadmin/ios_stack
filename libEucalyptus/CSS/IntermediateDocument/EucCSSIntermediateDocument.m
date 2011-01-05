//
//  EucCSSIntermediateDocument.m
//  LibCSSTest
//
//  Created by James Montgomerie on 09/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <libcss/libcss.h>

#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import "EucCSSIntermediateDocument.h"
#import "EucCSSIntermediateDocument_Package.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "EucCSSIntermediateDocumentConcreteNode.h"

#import "EucCSSDocumentTree.h"
#import "EucCSSDocumentTreeNode.h"

#import "EucCSSInternal.h"

#import "THCache.h"
#import "THLog.h"

@implementation EucCSSIntermediateDocument

+ (void)initialize
{
    if (self == [EucCSSIntermediateDocument class]) {
        css_initialise([[NSBundle mainBundle] pathForResource:@"Aliases" ofType:@""].fileSystemRepresentation, EucRealloc, NULL);
    }
}

@synthesize url = _url;
@synthesize dataSource = _dataSource;
@synthesize selectContext = _selectCtx;
@synthesize lwcContext = _lwcContext;
@synthesize documentTree = _documentTree;

css_error EucResolveURL(void *pw, lwc_context *dict, const char *base, lwc_string *rel, lwc_string **abs)
{    
    NSURL *baseUrl = [NSURL URLWithString:[NSString stringWithUTF8String:base]];
    NSURL *relativeUrl = [NSURL URLWithString:[NSString stringWithUTF8String:lwc_string_data(rel)]
                                relativeToURL:baseUrl];
    
    if(relativeUrl) {
        const char *absoluteString = [[relativeUrl absoluteString] UTF8String];
        lwc_context_intern(dict, absoluteString, strlen(absoluteString), abs);
    } else {
     	*abs = lwc_context_string_ref(dict, rel);   
    }
                          
	return CSS_OK;
}

- (css_error)_resolvePendingImportsForStylesheet:(css_stylesheet *)sheet
                                           atUrl:(NSURL *)sheetUrl
{
    css_error err;
    do {
        lwc_string *importUrl;
        uint64_t importMedia;
        
        err = css_stylesheet_next_pending_import(sheet,
                                                 &importUrl, 
                                                 &importMedia);        
        if(err == CSS_OK) {        
            NSURL *resolvedImportUrl = [NSURL URLWithString:[NSString stringWithUTF8String:lwc_string_data(importUrl)]
                                              relativeToURL:sheetUrl];

            css_stylesheet *import;
            if(css_stylesheet_create(CSS_LEVEL_3,
                                     NULL, [[resolvedImportUrl absoluteString] UTF8String], NULL,
                                     CSS_ORIGIN_AUTHOR, importMedia, false, 
                                     false, _lwcContext, 
                                     EucRealloc, NULL,
                                     EucResolveURL, NULL,
                                     &import) == CSS_OK) {
                
                if(resolvedImportUrl) {
                    NSData *stylesheetData = [_dataSource dataForURL:resolvedImportUrl];
                    if(stylesheetData) {
                        css_error err = css_stylesheet_append_data(import, 
                                                                   [stylesheetData bytes],
                                                                   [stylesheetData length]);
                        if(err != CSS_NEEDDATA) {
                            THWarn(@"Unexpected error %ld parsing stylesheet ar URL %@", err, [resolvedImportUrl absoluteString]);
                        }
                        err = css_stylesheet_data_done(import);
                        if(err == CSS_IMPORTS_PENDING) {
                            err = [self _resolvePendingImportsForStylesheet:import
                                                                      atUrl:resolvedImportUrl];
                        }
                        
                    }
                } 
                
                // We must register the sheet even if it's empty.
                css_stylesheet_data_done(import);
                css_stylesheet_register_import(sheet, import); 
            } else {
                THWarn(@"Error %ld creating stylesheet", (long)err);
            }
        }
    } while(err != CSS_INVALID);
    
    return CSS_OK;
}


- (void)_setupStylesheetWithUserAgentCSSPaths:(NSArray *)basePaths
                                 userCSSPaths:(NSArray *)userPaths
                                    parseHead:(BOOL)parseHead
{
    css_stylesheet *stylesheet;
    
    for(NSString *basePath in basePaths) {
        NSData *baseSheet = [NSData dataWithContentsOfMappedFile:basePath];
        if(css_stylesheet_create(CSS_LEVEL_3, "UTF-8",
                                 "", "", CSS_ORIGIN_UA, 
                                 CSS_MEDIA_ALL, false,
                                 false, _lwcContext,
                                 EucRealloc, NULL,
                                 EucResolveURL, NULL,
                                 &stylesheet) == CSS_OK) {
            css_error err = css_stylesheet_append_data(stylesheet, (uint8_t *)baseSheet.bytes, baseSheet.length);
            if(err != CSS_NEEDDATA) {
                THWarn(@"Unexpected error %ld parsing user stylesheet %@", (long)err, basePath);
            }
            err = css_stylesheet_data_done(stylesheet);
            if (err == CSS_OK) {
                ++_stylesheetsCount;
                _stylesheets = realloc(_stylesheets, sizeof(css_stylesheet *) * _stylesheetsCount);
                _stylesheets[_stylesheetsCount-1] = stylesheet;
                
                css_select_ctx_append_sheet(_selectCtx, stylesheet);
            } else {
                css_stylesheet_destroy(stylesheet);
                THWarn(@"Error %ld parsing user stylesheet %@", (long)err, basePath);
            }
        }        
    }
    
    for(NSString *userPath in userPaths) {
        NSData *userSheet = [NSData dataWithContentsOfMappedFile:userPath];
        if(css_stylesheet_create(CSS_LEVEL_3, "UTF-8",
                                 "", "", CSS_ORIGIN_USER, 
                                 CSS_MEDIA_ALL, false,
                                 false, _lwcContext,
                                 EucRealloc, NULL,
                                 EucResolveURL, NULL,
                                 &stylesheet) == CSS_OK) {
            css_error err = css_stylesheet_append_data(stylesheet, (uint8_t *)userSheet.bytes, userSheet.length);
            if(err != CSS_NEEDDATA) {
                THWarn(@"Unexpected error %ld parsing user stylesheet %@", (long)err, userPath);
            }
            err = css_stylesheet_data_done(stylesheet);
            if (err == CSS_OK) {
                ++_stylesheetsCount;
                _stylesheets = realloc(_stylesheets, sizeof(css_stylesheet *) * _stylesheetsCount);
                _stylesheets[_stylesheetsCount-1] = stylesheet;
                
                css_select_ctx_append_sheet(_selectCtx, stylesheet);
            } else {
                css_stylesheet_destroy(stylesheet);
                THWarn(@"Error %ld parsing stylesheet %@", (long)err, userPath);
            }
        }
    }    
    
    if(parseHead) {
        // Find the <head> node.
        id<EucCSSDocumentTreeNode> examiningNode = _documentTree.root;
        while(examiningNode && [@"head" caseInsensitiveCompare:examiningNode.name] != NSOrderedSame) {
            id<EucCSSDocumentTreeNode> oldExaminingNode = examiningNode;

            examiningNode = oldExaminingNode.firstChild;
            if(!examiningNode) {
                examiningNode = oldExaminingNode.nextSibling;
            }
            if(!examiningNode) {
                examiningNode = oldExaminingNode.parent.nextSibling;
            }
        }

        if(examiningNode) {
            const char* myUrl = [[_url absoluteString] UTF8String];
            uint32_t headNodeKey = examiningNode.key;

            // Look through under the head node to find <style> nodes.
            do {
                id<EucCSSDocumentTreeNode> oldExaminingNode = examiningNode;

                examiningNode = oldExaminingNode.firstChild;
                if(!examiningNode) {
                    examiningNode = oldExaminingNode.nextSibling;
                }
                if(!examiningNode) {
                    id<EucCSSDocumentTreeNode> parent = oldExaminingNode.parent;
                    if(parent.key == headNodeKey) {
                        examiningNode = nil;   
                    } else {
                        examiningNode = parent.nextSibling;
                    }
                }
                
                if(examiningNode) {
                    if([@"style" caseInsensitiveCompare:examiningNode.name] == NSOrderedSame) {
                        id<EucCSSDocumentTreeNode> styleContents = examiningNode.firstChild;
                        if(styleContents && styleContents.kind == EucCSSDocumentTreeNodeKindText) {
                            css_error err = css_stylesheet_create(CSS_LEVEL_3, 
                                                                  "UTF-8", myUrl, "", 
                                                                  CSS_ORIGIN_AUTHOR, 
                                                                  CSS_MEDIA_ALL, false,
                                                                  false, _lwcContext,
                                                                  EucRealloc, NULL,
                                                                  EucResolveURL, NULL,
                                                                  &stylesheet);
                            if(err == CSS_OK) {
                                do {
                                    const char *styleChars;
                                    size_t styleLength;
                                    if([styleContents getCharacterContents:&styleChars length:&styleLength]) {
                                        err = css_stylesheet_append_data(stylesheet, (uint8_t *)styleChars, styleLength);
                                        styleContents = styleContents.nextSibling;
                                    } else {
                                        THWarn(@"Error getting text contents for stylesheet");
                                        err = CSS_INVALID;
                                    }
                                } while(err == CSS_NEEDDATA &&
                                        styleContents && 
                                        styleContents.kind == EucCSSDocumentTreeNodeKindText);
                            
                                if(err != CSS_NEEDDATA) {
                                    THWarn(@"Unexpected error %ld parsing inline stylesheet", err);
                                }
                                    
                                err = css_stylesheet_data_done(stylesheet);
                                if(err == CSS_IMPORTS_PENDING) {
                                    err = [self _resolvePendingImportsForStylesheet:stylesheet
                                                                              atUrl:_url];
                                } 
                                
                                if(err == CSS_OK) {
                                    ++_stylesheetsCount;
                                    _stylesheets = realloc(_stylesheets, sizeof(css_stylesheet *) * _stylesheetsCount);
                                    _stylesheets[_stylesheetsCount-1] = stylesheet;
                                    
                                    css_select_ctx_append_sheet(_selectCtx, stylesheet);
                                } else {
                                    css_stylesheet_destroy(stylesheet);
                                    THWarn(@"Error %ld parsing stylesheet", (long)err);
                                }
                            } else {
                                THWarn(@"Error %ld creating stylesheet", (long)err);
                            }
                        }                
                    } else if([@"link" caseInsensitiveCompare:examiningNode.name] == NSOrderedSame) {
                        NSString *rel = [examiningNode attributeWithName:@"rel"];
                        if(rel && [rel caseInsensitiveCompare:@"stylesheet"] == NSOrderedSame) {
                            NSString *type = [examiningNode attributeWithName:@"type"];
                            if(type && [type caseInsensitiveCompare:@"text/css"] == NSOrderedSame) {
                                NSString *href = [examiningNode attributeWithName:@"href"];
                                if(href) {
                                    NSURL *stylesheetUrl = [NSURL URLWithString:href relativeToURL:_url];
                                    if(stylesheetUrl) {
                                        NSData *stylesheetData = [_dataSource dataForURL:stylesheetUrl];
                                        if(stylesheetData) {
                                            NSString *title = [examiningNode attributeWithName:@"title"];
                                            css_error err = css_stylesheet_create(CSS_LEVEL_3, 
                                                                                  NULL, 
                                                                                  [[stylesheetUrl absoluteString] UTF8String],
                                                                                  [title UTF8String], 
                                                                                  CSS_ORIGIN_AUTHOR, 
                                                                                  CSS_MEDIA_ALL, false,
                                                                                  false, _lwcContext,
                                                                                  EucRealloc, NULL,
                                                                                  EucResolveURL, NULL,
                                                                                  &stylesheet);
                                            if(err == CSS_OK) {
                                                css_error err = css_stylesheet_append_data(stylesheet, 
                                                                                           [stylesheetData bytes],
                                                                                           [stylesheetData length]);
                                                
                                                if(err != CSS_NEEDDATA) {
                                                    THWarn(@"Unexpected error %ld parsing stylesheet at URL %@", err, [stylesheetUrl absoluteString]);
                                                }
                                                
                                                err = css_stylesheet_data_done(stylesheet);
                                                if(err == CSS_IMPORTS_PENDING) {
                                                    err = [self _resolvePendingImportsForStylesheet:stylesheet
                                                                                              atUrl:_url];
                                                } 
                                                
                                                if (err == CSS_OK) {
                                                    ++_stylesheetsCount;
                                                    _stylesheets = realloc(_stylesheets, sizeof(css_stylesheet *) * _stylesheetsCount);
                                                    _stylesheets[_stylesheetsCount-1] = stylesheet;
                                                    
                                                    css_select_ctx_append_sheet(_selectCtx, stylesheet);
                                                } else {
                                                    css_stylesheet_destroy(stylesheet);
                                                    THWarn(@"Error %ld parsing stylesheet", (long)err);
                                                }
                                            } else {
                                                THWarn(@"Error %ld creating stylesheet", (long)err);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } while(examiningNode);
        }
    }
}

- (id)initWithDocumentTree:(id<EucCSSDocumentTree>)documentTree
              baseCSSPaths:(NSArray *)baseCSSPaths
              userCSSPaths:(NSArray *)userCSSPaths
                    forURL:(NSURL *)url
                dataSource:(id<EucCSSIntermediateDocumentDataSource>)dataSource
                    isHTML:(BOOL)isHTML
                lwcContext:(lwc_context *)lwcContext
{
    if((self = [super init])) {
        BOOL success = NO;
        _documentTree = [documentTree retain];
        _url = [url retain];
        _dataSource = dataSource;
        _lwcContext = lwcContext;
        lwc_context_ref(_lwcContext);
        if(css_select_ctx_create(EucRealloc, NULL, &_selectCtx) == CSS_OK) {
            [self _setupStylesheetWithUserAgentCSSPaths:baseCSSPaths userCSSPaths:userCSSPaths parseHead:isHTML];
            success = YES;
        }
        
        if(!success) {
            [self release]; 
            self = nil;
        } else {
            _keyToExtantNode = [[THIntegerToObjectCache alloc] init];
        }
    }
    return self;    
}

- (id)initWithDocumentTree:(id<EucCSSDocumentTree>)documentTree
                    forURL:(NSURL *)url
                dataSource:(id<EucCSSIntermediateDocumentDataSource>)dataSource
              baseCSSPaths:(NSArray *)baseCSSPaths
              userCSSPaths:(NSArray *)userCSSPaths
                    isHTML:(BOOL)isHTML
{
    lwc_context *lwcContext;
    if(lwc_create_context(EucRealloc, NULL, &lwcContext) == lwc_error_ok) {
        return [self initWithDocumentTree:documentTree baseCSSPaths:baseCSSPaths userCSSPaths:userCSSPaths forURL:url dataSource:dataSource isHTML:isHTML lwcContext:lwcContext];
    } else {
        [self release];
        return nil;
    }
}

- (EucCSSIntermediateDocumentNode *)rootNode
{
    return [self nodeForKey:_documentTree.root.key << EUC_CSS_DOCUMENT_TREE_NODE_TO_INTERMEDIATE_DOCUMENT_NODE_KEY_SHIFT_FOR_FLAGS];
}

- (EucCSSIntermediateDocumentNode *)nodeForKey:(uint32_t)key
{
    EucCSSIntermediateDocumentNode *node = [_keyToExtantNode objectForKey:key];
    if(!node) {
        uint32_t nonGeneratedKey = key & ~EUC_CSS_INTERMEDIATE_DOCUMENT_NODE_KEY_FLAG_MASK;
        if(nonGeneratedKey == key) {
            id<EucCSSDocumentTreeNode> documentTreeNode = [_documentTree nodeForKey:key >> EUC_CSS_DOCUMENT_TREE_NODE_TO_INTERMEDIATE_DOCUMENT_NODE_KEY_SHIFT_FOR_FLAGS];
            if(documentTreeNode) {
                node = [[EucCSSIntermediateDocumentConcreteNode alloc] initWithDocumentTreeNode:documentTreeNode inDocument:self];
            }
        } else {
            EucCSSIntermediateDocumentNode *nonGeneratedNode = [self nodeForKey:nonGeneratedKey];
            node = [[nonGeneratedNode generatedChildNodeForKey:key] retain];
        }
        if(node) {
            [_keyToExtantNode cacheObject:node forKey:key];
        }
        [node autorelease];
    }
    return node;
}

- (uint32_t)nodeKeyForId:(NSString *)identifier
{
    id<EucCSSDocumentTreeNode> documentTreeNode = [[_documentTree idToNode] objectForKey:identifier];
    return documentTreeNode.key << EUC_CSS_DOCUMENT_TREE_NODE_TO_INTERMEDIATE_DOCUMENT_NODE_KEY_SHIFT_FOR_FLAGS;
}

- (NSDictionary *)idToNodeKey
{
    NSMutableDictionary *ret = nil;
    if([_documentTree respondsToSelector:@selector(idToNode)]) {
        NSDictionary *idToDocumentTreeNode = [_documentTree idToNode];
        NSUInteger count = idToDocumentTreeNode.count;
        if(count) {
            ret = [[NSMutableDictionary alloc] initWithCapacity:count];
            for(id identifier in [idToDocumentTreeNode keyEnumerator]) {
                id<EucCSSDocumentTreeNode> documentTreeNode = [[_documentTree idToNode] objectForKey:identifier];
                [ret setObject:[NSNumber numberWithUnsignedInt:documentTreeNode.key]
                        forKey:identifier];
            }
        }
    }
    return [ret autorelease];
}

+ (uint32_t)documentTreeNodeKeyForKey:(uint32_t)key
{
    NSParameterAssert((key & EUC_CSS_INTERMEDIATE_DOCUMENT_NODE_KEY_FLAG_MASK) == 0);
    return key >> EUC_CSS_DOCUMENT_TREE_NODE_TO_INTERMEDIATE_DOCUMENT_NODE_KEY_SHIFT_FOR_FLAGS;
}

+ (uint32_t)keyForDocumentTreeNodeKey:(uint32_t)key
{
    return key << EUC_CSS_DOCUMENT_TREE_NODE_TO_INTERMEDIATE_DOCUMENT_NODE_KEY_SHIFT_FOR_FLAGS;
}

- (float)estimatedPercentageForNodeWithKey:(uint32_t)key
{
    uint32_t documentTreeNodeKey = key >> EUC_CSS_DOCUMENT_TREE_NODE_TO_INTERMEDIATE_DOCUMENT_NODE_KEY_SHIFT_FOR_FLAGS;
    return 100.0f * ((float)documentTreeNodeKey) / ((float)_documentTree.lastKey);
}

- (NSData *)dataForURL:(NSURL *)url
{
    return [_dataSource dataForURL:url];
}

- (CGImageRef)imageForURL:(NSURL *)url
{
    CGImageRef image = NULL;

    NSData *imageData = [self dataForURL:url];
    if(imageData) {
        #if TARGET_OS_IPHONE
            image = [UIImage imageWithData:imageData].CGImage;
            if(image) {
                CFRetain(image);
            }
        #else
            CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
            if(imageSource) {
                image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
                CFRelease(imageSource);
            }
        #endif
    }
    
    [(id)image autorelease];
    return image;
}

- (void)dealloc 
{        
    [_keyToExtantNode release];

    [_documentTree release];    
    [_url release];

    css_select_ctx_destroy(_selectCtx);

    for(NSUInteger i = 0; i < _stylesheetsCount; ++i) {
        css_stylesheet_destroy(_stylesheets[i]);
    }
    
    free(_stylesheets);
    
    if(_lwcContext) {
        lwc_context_unref(_lwcContext);
    }
    
    [super dealloc];
}

@end
