//
//  EucHTMLDocument.m
//  LibCSSTest
//
//  Created by James Montgomerie on 09/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <libcss/libcss.h>

#import "EucHTMLDocument.h"
#import "EucHTMLDocumentNode.h"

#import "EucHTMLDBCreation.h"
#import "EucHTMLDBNode.h"
#import "EucHTMLDBNodeManager.h"

//#import "LibCSSDebug.h"
//#import "dump_computed.h"

CGFloat libcss_size_to_pixels(css_fixed size, css_unit units)
{
    CGFloat ret = FIXTOFLT(size);
    
    
    /*NSString *unns = nil;
    switch(units) {
        case CSS_UNIT_EX:
            unns = @"ex";
            break;
        case CSS_UNIT_EM:
            unns = @"em";
            break;
        case CSS_UNIT_IN:
            unns = @"in";
            break;
        case CSS_UNIT_CM:
            unns = @"cm";
            break;
        case CSS_UNIT_MM:
            unns = @"mm";
            break;
        case CSS_UNIT_PC:
            unns = @"pc";
            break;
        case CSS_UNIT_PX:
            unns = @"px";
            break;
        case CSS_UNIT_PT:
            unns = @"pt";
            break;
    }*/

    switch(units) {
        case CSS_UNIT_EX:
        case CSS_UNIT_EM:
            abort();
            break;
        case CSS_UNIT_IN:
            ret *= 2.54;
        case CSS_UNIT_CM:
            ret *= 10;
        case CSS_UNIT_MM:
            ret *= 0.155828221; // mm per dot on an iPhone screen.
            break;
        case CSS_UNIT_PC:
            ret *= 12;
            break;
        case CSS_UNIT_PX:
        case CSS_UNIT_PT:
            break;
    }
    
    return ret;
}

@implementation EucHTMLDocument

@synthesize body = _body;
@synthesize selectContext = _selectCtx;
@synthesize htmlDBNodeManager = _manager;

static css_error resolve_url(void *pw, lwc_context *dict,
                             const char *base, lwc_string *rel, lwc_string **abs)
{    
	/* About as useless as possible */
	*abs = lwc_context_string_ref(dict, rel);
    
	return CSS_OK;
}


- (void)_setupStylesheets:(NSString *)basePath
{
    NSData *baseSheet = [NSData dataWithContentsOfMappedFile:basePath];
    
    css_stylesheet *stylesheet;
    if(css_stylesheet_create(CSS_LEVEL_21, "UTF-8",
                             "", "", CSS_ORIGIN_UA, 
                             CSS_MEDIA_ALL, false,
                             false, _lwcContext,
                             EucRealloc, NULL,
                             resolve_url, NULL,
                             &stylesheet) == CSS_OK) {
        css_error err = css_stylesheet_append_data(stylesheet, (uint8_t *)baseSheet.bytes, baseSheet.length);
        if(err == CSS_NEEDDATA) {
            err = css_stylesheet_data_done(stylesheet);
        }
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
    
    lwc_string *headString;
    lwc_context_intern(_lwcContext, "head", 4, &headString);
    lwc_string *styleString;
    lwc_context_intern(_lwcContext, "style", 5, &styleString);
    
    EucHTMLDBNode *headNode = [_rootDBNode nextNodeWithName:headString];    
    EucHTMLDBNode *examiningNode = headNode;
    while((examiningNode = [examiningNode nextNodeUnder:headNode])) {        
        lwc_string *name = examiningNode.name;
        bool equal;
        if(name &&
           lwc_context_string_caseless_isequal(_lwcContext, name, styleString, &equal) == lwc_error_ok && equal) {
            char *styleChars;
            size_t styleLength;
            if([[examiningNode firstChild] getCharacterContents:&styleChars length:&styleLength]) {
                css_stylesheet *stylesheet;
                if(css_stylesheet_create(CSS_LEVEL_21, "UTF-8",
                                         "", "", CSS_ORIGIN_AUTHOR, 
                                         CSS_MEDIA_ALL, false,
                                         false, _lwcContext,
                                         EucRealloc, NULL,
                                         resolve_url, NULL,
                                         &stylesheet) == CSS_OK) {
                    
                    css_error err = css_stylesheet_append_data(stylesheet, (uint8_t *)styleChars, styleLength);
                    if(err == CSS_NEEDDATA) {
                        err = css_stylesheet_data_done(stylesheet);
                    }
                    if (err == CSS_OK) {
                        ++_stylesheetsCount;
                        _stylesheets = realloc(_stylesheets, sizeof(css_stylesheet *) * _stylesheetsCount);
                        _stylesheets[_stylesheetsCount-1] = stylesheet;
                        
                        css_select_ctx_append_sheet(_selectCtx, stylesheet);
                        
                        /*char buf[8192];
                        size_t len = 8192;
                        dump_sheet(stylesheet, buf, &len);
                        
                        NSLog(@"%s", buf);   */                     
                    } else {
                        css_stylesheet_destroy(stylesheet);
                        NSLog(@"Error %ld parsing stylesheet", (long)err);
                    }
                }
            }
        }
    }
    
    
    lwc_context_string_unref(_lwcContext, headString);
    lwc_context_string_unref(_lwcContext, styleString);
}

- (id)initWithPath:(NSString *)path
{
    if((self = [super init])) {
        BOOL success = NO;
        _db = EucHTMLDBCreateWithHTMLAtPath([path fileSystemRepresentation],
                                            "/tmp/test.db");
        if(_db) {
             if(lwc_create_context(EucRealloc, NULL, &_lwcContext) == lwc_error_ok) {
                lwc_context_ref(_lwcContext);
                _manager = [[EucHTMLDBNodeManager alloc] initWithHTMLDB:_db
                                                             lwcContext:_lwcContext];
                if(_manager) {
                    _rootDBNode = [[_manager nodeForKey:1] retain];
                    if(_rootDBNode) {
                        lwc_string *bodyString;
                        lwc_context_intern(_lwcContext, "body", 4, &bodyString);
                        _bodyDBNode = [[_rootDBNode nextNodeWithName:bodyString] retain];
                        lwc_context_string_unref(_lwcContext, bodyString);
                        if(_bodyDBNode) {
                            if(css_select_ctx_create(EucRealloc, NULL, &_selectCtx) == CSS_OK) {
                                [self _setupStylesheets:@"/Users/jamie/Development/LibCSSTest/Resources/EPubDefault.css"];
                                
                                /*EucHTMLDBNode *current = _bodyDBNode;
                                
                                do {
                                    if(current.kind == nodeKindElement) {
                                        css_computed_style *computed;
                                        css_computed_style_create(EucRealloc, NULL, &computed);
                                        css_error err = css_select_style(_selectCtx, 
                                                                         (void *)(uintptr_t)current.key,
                                                                         CSS_PSEUDO_ELEMENT_NONE, 
                                                                         CSS_MEDIA_PRINT, 
                                                                         NULL, 
                                                                         computed,
                                                                         [EucHTMLDBNode selectHandler],
                                                                         _manager);
                                        if(err == CSS_OK) { 
                                            char *buf = malloc(8192);
                                            if (buf == NULL) {
                                                assert(0 && "No memory for result data");
                                            }
                                            size_t buflen = 8192;
                                            
                                            dump_computed_style(computed, buf, &buflen);
                                            printf("%ld - <%s>:\n%s\n\n\n", (long)current.key, lwc_string_data(current.name), buf);
                                            
                                            free(buf);
                                            css_computed_style_destroy(computed);
                                        } else {
                                            NSLog(@"Error %ld", (long)err);
                                        }
                                    }
                                } while(current = [current nextNodeUnder:_bodyDBNode]);*/
                                
                                _body = [[[EucHTMLDocumentNode alloc] initWithHTMLDBNode:_bodyDBNode inDocument:self] retain];
                                success = YES;
                            }
                        }
                    }
                }
            }
        }
        if(!success) {
            [self release]; 
            self = nil;
        } else {
            static const CFDictionaryKeyCallBacks keyCallbacks = {0};
            static const CFDictionaryValueCallBacks valueCallbacks = {0};
            _keyToExtantNode = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                         0,
                                                         &keyCallbacks,
                                                         &valueCallbacks);
            CFDictionarySetValue(_keyToExtantNode, (void *)(uintptr_t)_body.key, _body);
        }
    }
    return self;
}

- (EucHTMLDocumentNode *)nodeForKey:(uint32_t)key
{
    EucHTMLDocumentNode *node = (EucHTMLDocumentNode *)CFDictionaryGetValue(_keyToExtantNode, (void *)(uintptr_t)key);
    if(!node) {
        node = [[[EucHTMLDocumentNode alloc] initWithHTMLDBNode:[_manager nodeForKey:key] inDocument:self] autorelease];
        CFDictionarySetValue(_keyToExtantNode, (void *)(uintptr_t)key, node);
    }
    return node;
}

- (BOOL)nodeIsBody:(EucHTMLDocumentNode *)node
{
    return [_manager nodeIsBody:node.dbNode];
}

- (void)notifyOfDealloc:(EucHTMLDocumentNode *)node
{
    CFDictionaryRemoveValue(_keyToExtantNode, (void *)(uintptr_t)node.key);
}

- (void)close
{
    if(_db) {
        EucHTMLDBClose(_db);
        _db = NULL;
    }
    if(_selectCtx) {
        css_select_ctx_destroy(_selectCtx);
        _selectCtx = NULL;
    }
    for(NSUInteger i = 0; i < _stylesheetsCount; ++i) {
        css_stylesheet_destroy(_stylesheets[i]);
        _stylesheets[i] = NULL;
    }
    _stylesheetsCount = 0;
    if(_lwcContext) {
        lwc_context_unref(_lwcContext);
        _lwcContext = NULL;
    }
    [_rootDBNode release];
    _rootDBNode = nil;
    [_bodyDBNode release];
    _bodyDBNode = nil;
    [_body release];
    _body = nil;
    
    [_manager release];    
}

- (void)dealloc
{
    CFRelease(_keyToExtantNode);
    [self close];
    
    [super dealloc];
}

@end
