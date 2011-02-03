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
#import "LWCNSStringAdditions.h"

#import "THCache.h"
#import "THLog.h"

@implementation EucCSSIntermediateDocument

@synthesize url = _url;
@synthesize dataSource = _dataSource;
@synthesize selectContext = _selectCtx;
@synthesize documentTree = _documentTree;

css_error EucResolveURL(void *pw, const char *base, lwc_string *rel, lwc_string **abs)
{    
    NSURL *baseUrl = [NSURL URLWithString:[NSString stringWithUTF8String:base]];
    NSURL *relativeUrl = [NSURL URLWithString:NSStringFromLWCString(rel)
                                relativeToURL:baseUrl];
    
    if(relativeUrl) {
        *abs = lwc_intern_ns_string([relativeUrl absoluteString]);
    } else {
     	*abs = lwc_string_ref(rel);   
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
                                     false, false,
                                     EucRealloc, NULL,
                                     EucResolveURL, NULL,
                                     NULL, NULL,
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
                
                if (err == CSS_OK) {
                    ++_stylesheetsCount;
                    _stylesheets = realloc(_stylesheets, sizeof(css_stylesheet *) * _stylesheetsCount);
                    _stylesheets[_stylesheetsCount-1] = import;
                }                    
            } else {
                THWarn(@"Error %ld creating stylesheet", (long)err);
            }
        }
    } while(err != CSS_INVALID);
    
    return CSS_OK;
}


- (void)_setupStylesheetWithUserAgentCSSPaths:(NSArray *)basePaths
                                 userCSSPaths:(NSArray *)userPaths
{
    css_stylesheet *stylesheet;
    
    for(NSString *basePath in basePaths) {
        NSData *baseSheet = [NSData dataWithContentsOfMappedFile:basePath];
        if(css_stylesheet_create(CSS_LEVEL_3,
                                 "UTF-8", "", NULL,
                                 false, false,
                                 EucRealloc, NULL,
                                 EucResolveURL, NULL,
                                 NULL, NULL,
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
                
                css_select_ctx_append_sheet(_selectCtx, stylesheet, CSS_ORIGIN_UA, CSS_MEDIA_ALL);
            } else {
                css_stylesheet_destroy(stylesheet);
                THWarn(@"Error %ld parsing user stylesheet %@", (long)err, basePath);
            }
        }        
    }
    
    for(NSString *userPath in userPaths) {
        NSData *userSheet = [NSData dataWithContentsOfMappedFile:userPath];
        if(css_stylesheet_create(CSS_LEVEL_3,
                                 "UTF-8", "", NULL,
                                 false, false,
                                 EucRealloc, NULL,
                                 EucResolveURL, NULL,
                                 NULL, NULL,
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
                
                css_select_ctx_append_sheet(_selectCtx, stylesheet, CSS_ORIGIN_USER, CSS_MEDIA_ALL);
            } else {
                css_stylesheet_destroy(stylesheet);
                THWarn(@"Error %ld parsing stylesheet %@", (long)err, userPath);
            }
        }
    }    
    
    
    if([_documentTree respondsToSelector:@selector(nodesWithLinkedOrEmbeddedCSSInSubnodes)]) {
        const char* myUrl = [[_url absoluteString] UTF8String];
        NSArray *nodesWithLinkedOrEmbeddedCSSInSubnodes = [_documentTree nodesWithLinkedOrEmbeddedCSSInSubnodes];
        for(id<EucCSSDocumentTreeNode> nodeWithLinkedOrEmbeddedCSSInSubnodes in nodesWithLinkedOrEmbeddedCSSInSubnodes) {
            id<EucCSSDocumentTreeNode> examiningNode = nodeWithLinkedOrEmbeddedCSSInSubnodes;
            uint32_t headNodeKey = examiningNode.key;
            
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
                
                if([examiningNode hasEmbeddedCSSString]) {
                    id<EucCSSDocumentTreeNode> styleContents = examiningNode.firstChild;
                    if(styleContents && styleContents.kind == EucCSSDocumentTreeNodeKindText) {
                        css_error err = css_stylesheet_create(CSS_LEVEL_3,
                                                              "UTF-8", myUrl, NULL,
                                                              false, false,
                                                              EucRealloc, NULL,
                                                              EucResolveURL, NULL,
                                                              NULL, NULL,
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
                                
                                css_select_ctx_append_sheet(_selectCtx, stylesheet, CSS_ORIGIN_AUTHOR, CSS_MEDIA_ALL);
                            } else {
                                css_stylesheet_destroy(stylesheet);
                                THWarn(@"Error %ld parsing stylesheet", (long)err);
                            }
                        } else {
                            THWarn(@"Error %ld creating stylesheet", (long)err);
                        }
                    }                
                }
                
                NSString* href = [examiningNode linkedCSSRelativeURLString];
                if(href) {
                    NSURL *stylesheetUrl = [NSURL URLWithString:href relativeToURL:_url];
                    if(stylesheetUrl) {
                        NSData *stylesheetData = [_dataSource dataForURL:stylesheetUrl];
                        if(stylesheetData) {
                            NSString *title = [examiningNode attributeWithName:@"title"];
                            css_error err = css_stylesheet_create(CSS_LEVEL_3,
                                                                  NULL, [[stylesheetUrl absoluteString] UTF8String], [title UTF8String],
                                                                  false, false,
                                                                  EucRealloc, NULL,
                                                                  EucResolveURL, NULL,
                                                                  NULL, NULL,
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
                                    
                                    css_select_ctx_append_sheet(_selectCtx, stylesheet, CSS_ORIGIN_AUTHOR, CSS_MEDIA_ALL);
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
            } while(examiningNode);
        }
    }
}

- (id)initWithDocumentTree:(id<EucCSSDocumentTree>)documentTree
                    forURL:(NSURL *)url
                dataSource:(id<EucCSSIntermediateDocumentDataProvider>)dataSource
              baseCSSPaths:(NSArray *)baseCSSPaths
              userCSSPaths:(NSArray *)userCSSPaths
{
    if((self = [super init])) {
        BOOL success = NO;
        _documentTree = [documentTree retain];
        _url = [url retain];
        _dataSource = dataSource;
        if(css_select_ctx_create(EucRealloc, NULL, &_selectCtx) == CSS_OK) {
            [self _setupStylesheetWithUserAgentCSSPaths:baseCSSPaths userCSSPaths:userCSSPaths];
            success = YES;
        }
        
        if(!success) {
            [self release]; 
            self = nil;
        } else {
            _keyToExtantNode = [[THIntegerToObjectCache alloc] init];
            _keyToExtantNode.evictsOnMemoryWarnings = YES;
        }
    }
    return self;    
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
    _keyToExtantNode.evictsOnMemoryWarnings = NO;
    [_keyToExtantNode release];

    [_documentTree release];    
    [_url release];

    css_select_ctx_destroy(_selectCtx);

    for(NSUInteger i = 0; i < _stylesheetsCount; ++i) {
        css_stylesheet_destroy(_stylesheets[i]);
    }
    
    free(_stylesheets);
    
    [super dealloc];
}

@end
