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
#import "EucHTMLDocumentConcreteNode.h"
#import "EucHTMLDocumentGeneratedContainerNode.h"
#import "EucHTMLDocumentGeneratedTextNode.h"

#import "EucHTMLDBCreation.h"
#import "EucHTMLDBNode.h"
#import "EucHTMLDBNodeManager.h"

#import "THLog.h"

//#import "LibCSSDebug.h"
//#import "dump_computed.h"

CGFloat libcss_size_to_pixels(css_computed_style *computed_style, css_fixed size, css_unit units, CGFloat percentageBase)
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
            NSCParameterAssert(units != CSS_UNIT_EX);
            break;
        case CSS_UNIT_EM:
            {
                css_fixed fontSize;
                css_unit fontUnit;
                css_computed_font_size(computed_style, &fontSize, &fontUnit);
                NSCParameterAssert(fontUnit == CSS_UNIT_PX || fontUnit == CSS_UNIT_PT);
                ret = FIXTOFLT(FMUL(size, fontSize));
            }
            break;
        case CSS_UNIT_IN:
            ret *= 2.54f;        // Convert to cm.
        case CSS_UNIT_CM:  
            ret *= 10.0f;          // Convert to mm.
        case CSS_UNIT_MM:
            ret *= 0.155828221f; // mm per dot on an iPhone screen.
            break;
        case CSS_UNIT_PC:
            ret *= 12.0f;
            break;
        case CSS_UNIT_PX:
        case CSS_UNIT_PT:
            break;
        case CSS_UNIT_PCT:
            ret = percentageBase * (ret * 0.01f);
            break;
        default:
            THWarn(@"Unexpected unit %ld (%f size) - not converting.", (long)units, (double)ret);
            break;
    }
    
    return roundf(ret);
}

@implementation EucHTMLDocument

@synthesize body = _body;
@synthesize selectContext = _selectCtx;
@synthesize lwcContext = _lwcContext;
@synthesize htmlDBNodeManager = _manager;

css_error EucResolveURL(void *pw, lwc_context *dict, const char *base, lwc_string *rel, lwc_string **abs)
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
                             EucResolveURL, NULL,
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
                                         EucResolveURL, NULL,
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
                                            NULL);
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
                                _body = [[[EucHTMLDocumentConcreteNode alloc] initWithHTMLDBNode:_bodyDBNode inDocument:self] retain];
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
        uint32_t keyKind = key & GENERATED_NODE_KEY_MASK;
        if(keyKind != 0) {
            if(keyKind < GENERATED_NODE_TEXT_KEY_FLAG) {
                node = [[EucHTMLDocumentGeneratedContainerNode alloc] initWithDocument:self 
                                                                             parentKey:key ^ keyKind 
                                                                        isBeforeParent:(keyKind == GENERATED_NODE_BEFORE_CONTAINER_KEY_FLAG)];
            } else {
                NSParameterAssert((keyKind & GENERATED_NODE_TEXT_KEY_FLAG) == GENERATED_NODE_TEXT_KEY_FLAG);
                node = [[EucHTMLDocumentGeneratedTextNode alloc] initWithDocument:self
                                                                        parentKey:key ^ GENERATED_NODE_TEXT_KEY_FLAG];
            }
        } else {
            node = [[EucHTMLDocumentConcreteNode alloc] initWithHTMLDBNode:[_manager nodeForKey:key >> DB_KEY_MAPPING_SHIFT] inDocument:self];
        }
        CFDictionarySetValue(_keyToExtantNode, (void *)(uintptr_t)key, node);
        [node autorelease];
    }
    return node;
}

- (BOOL)nodeIsBody:(EucHTMLDocumentNode *)node
{
    if([node isKindOfClass:[EucHTMLDocumentConcreteNode class]]) {
        return [_manager nodeIsBody:((EucHTMLDocumentConcreteNode *)node).dbNode];
    } else {
        return NO;
    }
}

- (void)notifyOfDealloc:(EucHTMLDocumentConcreteNode *)node
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
