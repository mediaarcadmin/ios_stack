//
//  EucCSSIntermediateDocument.m
//  LibCSSTest
//
//  Created by James Montgomerie on 09/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <libcss/libcss.h>

#import "EucCSSIntermediateDocument.h"
#import "EucCSSIntermediateDocument_Package.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "EucCSSIntermediateDocumentConcreteNode.h"
#import "EucCSSIntermediateDocumentGeneratedContainerNode.h"
#import "EucCSSIntermediateDocumentGeneratedTextNode.h"

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
            if(css_stylesheet_create(CSS_LEVEL_21,
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
                            THWarn(@"Unexpected error %ld parsing base stylesheet ar URL %@", err, [resolvedImportUrl absoluteString]);
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


- (void)_setupStylesheets:(NSString *)basePath parseHead:(BOOL)parseHead
{
    NSData *baseSheet = [NSData dataWithContentsOfMappedFile:basePath];
    
    css_stylesheet *stylesheet;
    if(css_stylesheet_create(CSS_LEVEL_21, "UTF-8",
                             "", "", CSS_ORIGIN_UA, 
                             CSS_MEDIA_ALL, false,
                             false, _lwcContext,
                             EucRealloc, NULL,
                             EucResolveURL, NULL,
                             &stylesheet) == CSS_OK) {
        css_error err = css_stylesheet_append_data(stylesheet, (uint8_t *)baseSheet.bytes, baseSheet.length);
        if(err != CSS_NEEDDATA) {
            THWarn(@"Unexpected error %ld parsing base stylesheet", err);
        }
        err = css_stylesheet_data_done(stylesheet);
        if (err == CSS_OK) {
            ++_stylesheetsCount;
            _stylesheets = realloc(_stylesheets, sizeof(css_stylesheet *) * _stylesheetsCount);
            _stylesheets[_stylesheetsCount-1] = stylesheet;
            
            css_select_ctx_append_sheet(_selectCtx, stylesheet);
        } else {
            css_stylesheet_destroy(stylesheet);
            NSLog(@"Error %ld parsing stylesheet", (long)err);
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
                            css_error err = css_stylesheet_create(CSS_LEVEL_21, 
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
                                    THWarn(@"Unexpected error %ld parsing base stylesheet", err);
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
                                            css_error err = css_stylesheet_create(CSS_LEVEL_21, 
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
                                                    THWarn(@"Unexpected error %ld parsing base stylesheet", err);
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
               baseCSSPath:(NSString *)baseCSSPath
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
            [self _setupStylesheets:baseCSSPath parseHead:isHTML];
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
               baseCSSPath:(NSString *)baseCSSPath
                    isHTML:(BOOL)isHTML
{
    lwc_context *lwcContext;
    if(lwc_create_context(EucRealloc, NULL, &lwcContext) == lwc_error_ok) {
        return [self initWithDocumentTree:documentTree baseCSSPath:baseCSSPath forURL:url dataSource:dataSource isHTML:isHTML lwcContext:lwcContext];
    } else {
        [self release];
        return nil;
    }
}

- (EucCSSIntermediateDocumentNode *)rootNode
{
    return [self nodeForKey:_documentTree.root.key << EUC_HTML_DOCUMENT_DB_KEY_SHIFT_FOR_FLAGS];
}

- (EucCSSIntermediateDocumentNode *)nodeForKey:(uint32_t)key
{
    EucCSSIntermediateDocumentNode *node = [_keyToExtantNode objectForKey:key];
    if(!node) {
        uint32_t keyKind = key & EucCSSIntermediateDocumentNodeKeyFlagMask;
        if(keyKind != 0) {
            if(keyKind < EucCSSIntermediateDocumentNodeKeyFlagGeneratedTextNode) {
                node = [[EucCSSIntermediateDocumentGeneratedContainerNode alloc] initWithDocument:self 
                                                                             parentKey:key ^ keyKind 
                                                                        isBeforeParent:(keyKind == EucCSSIntermediateDocumentNodeKeyFlagBeforeContainerNode)];
            } else {
                NSParameterAssert((keyKind & EucCSSIntermediateDocumentNodeKeyFlagGeneratedTextNode) == EucCSSIntermediateDocumentNodeKeyFlagGeneratedTextNode);
                node = [[EucCSSIntermediateDocumentGeneratedTextNode alloc] initWithDocument:self
                                                                        parentKey:key ^ EucCSSIntermediateDocumentNodeKeyFlagGeneratedTextNode];
            }
        } else {
            id<EucCSSDocumentTreeNode> dbNode = [_documentTree nodeForKey:key >> EUC_HTML_DOCUMENT_DB_KEY_SHIFT_FOR_FLAGS];
            if(dbNode) {
                node = [[EucCSSIntermediateDocumentConcreteNode alloc] initWithDocumentTreeNode:dbNode inDocument:self];
            }
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
    id<EucCSSDocumentTreeNode> dbNode = nil;
    if([_documentTree respondsToSelector:@selector(nodeWithId:)]) {
        dbNode = [_documentTree nodeWithId:identifier];
    } else {
        // Perform the search manually.
        dbNode = _documentTree.root;
        NSString *dbNodeId = [dbNode attributeWithName:@"id"];
        while(dbNode && (!dbNodeId || ![dbNodeId isEqualToString:identifier])) {
            id<EucCSSDocumentTreeNode> oldExaminingNode = dbNode;
            
            dbNode = oldExaminingNode.firstChild;
            if(!dbNode) {
                dbNode = oldExaminingNode.nextSibling;
            }
            if(!dbNode) {
                dbNode = oldExaminingNode.parent.nextSibling;
            }
            
            dbNodeId = [dbNode attributeWithName:@"id"];
        }
    }
    return dbNode.key << EUC_HTML_DOCUMENT_DB_KEY_SHIFT_FOR_FLAGS;
}

- (float)estimatedPercentageForNodeWithKey:(uint32_t)key
{
    uint32_t dbNodeKey = key >> EUC_HTML_DOCUMENT_DB_KEY_SHIFT_FOR_FLAGS;
    return ((float)dbNodeKey) / ((float)_documentTree.lastKey);
}

- (void)dealloc
{        
    [_keyToExtantNode release];

    css_select_ctx_destroy(_selectCtx);

    for(NSUInteger i = 0; i < _stylesheetsCount; ++i) {
        css_stylesheet_destroy(_stylesheets[i]);
    }
    
    free(_stylesheets);
    
    if(_lwcContext) {
        lwc_context_unref(_lwcContext);
    }
    
    [_documentTree release];    
    [_url release];

    [super dealloc];
}

@end
