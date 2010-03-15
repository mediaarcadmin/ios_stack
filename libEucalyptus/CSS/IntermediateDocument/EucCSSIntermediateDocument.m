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

#import "THLog.h"

//#import "LibCSSDebug.h"
//#import "dump_computed.h"

CGFloat EucCSSLibCSSSizeToPixels(css_computed_style *computed_style, css_fixed size, css_unit units, CGFloat percentageBase)
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
                css_fixed fontSize = 0;
                css_unit fontUnit = 0;
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

@implementation EucCSSIntermediateDocument

+ (void)initialize
{
    css_initialise([[NSBundle mainBundle] pathForResource:@"Aliases" ofType:@""].fileSystemRepresentation, EucRealloc, NULL);
}

@synthesize selectContext = _selectCtx;
@synthesize lwcContext = _lwcContext;
@synthesize documentTree = _documentTree;

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
            
            if(examiningNode && [@"style" caseInsensitiveCompare:examiningNode.name] == NSOrderedSame) {
                id<EucCSSDocumentTreeNode> styleContents = examiningNode.firstChild;
                if(styleContents && styleContents.kind == EucCSSDocumentTreeNodeKindText) {
                    if(css_stylesheet_create(CSS_LEVEL_21, "UTF-8",
                                             "", "", CSS_ORIGIN_AUTHOR, 
                                             CSS_MEDIA_ALL, false,
                                             false, _lwcContext,
                                             EucRealloc, NULL,
                                             EucResolveURL, NULL,
                                             &stylesheet) == CSS_OK) {
                        css_error err = CSS_NEEDDATA;
                        do {
                            const char *styleChars;
                            size_t styleLength;
                            if([styleContents getCharacterContents:&styleChars length:&styleLength]) {
                                err = css_stylesheet_append_data(stylesheet, (uint8_t *)styleChars, styleLength);
                                styleContents = styleContents.nextSibling;
                            } else {
                                NSLog(@"Error getting text contents for stylesheet");
                                err = CSS_INVALID;
                            }
                        } while(err == CSS_NEEDDATA &&
                                styleContents && 
                                styleContents.kind == EucCSSDocumentTreeNodeKindText);
                        
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
                }                
            }
        } while(examiningNode);
    }
}

- (id)initWithDocumentTree:(id<EucCSSDocumentTree>)documentTree
               baseCSSPath:(NSString *)baseCSSPath
{
    lwc_context *lwcContext;
    if(lwc_create_context(EucRealloc, NULL, &lwcContext) == lwc_error_ok) {
        return [self initWithDocumentTree:documentTree baseCSSPath:baseCSSPath lwcContext:lwcContext];
    } else {
        [self release];
        return nil;
    }
}

- (id)initWithDocumentTree:(id<EucCSSDocumentTree>)documentTree
               baseCSSPath:(NSString *)baseCSSPath
                lwcContext:(lwc_context *)lwcContext;
{
    if((self = [super init])) {
        BOOL success = NO;
        _documentTree = [documentTree retain];
        _lwcContext = lwcContext;
        lwc_context_ref(_lwcContext);
        if(css_select_ctx_create(EucRealloc, NULL, &_selectCtx) == CSS_OK) {
            [self _setupStylesheets:baseCSSPath];
            success = YES;
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
        }
    }
    return self;    
}

- (EucCSSIntermediateDocumentNode *)rootNode
{
    return [self nodeForKey:_documentTree.root.key << EUC_HTML_DOCUMENT_DB_KEY_SHIFT_FOR_FLAGS];
}

- (EucCSSIntermediateDocumentNode *)nodeForKey:(uint32_t)key
{
    EucCSSIntermediateDocumentNode *node = (EucCSSIntermediateDocumentNode *)CFDictionaryGetValue(_keyToExtantNode, (void *)(uintptr_t)key);
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
            CFDictionarySetValue(_keyToExtantNode, (void *)(uintptr_t)key, node);
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

- (void)notifyOfDealloc:(EucCSSIntermediateDocumentNode *)node
{
    CFDictionaryRemoveValue(_keyToExtantNode, (void *)(uintptr_t)node.key);
}

- (void)dealloc
{
    if(_keyToExtantNode) {
        CFRelease(_keyToExtantNode);
    }
    
    css_select_ctx_destroy(_selectCtx);
    _selectCtx = NULL;

    for(NSUInteger i = 0; i < _stylesheetsCount; ++i) {
        css_stylesheet_destroy(_stylesheets[i]);
        _stylesheets[i] = NULL;
    }
    _stylesheetsCount = 0;
    
    if(_lwcContext) {
        lwc_context_unref(_lwcContext);
        _lwcContext = NULL;
    }
    
    [_documentTree release];
    _documentTree = nil;
    
    [super dealloc];
}

@end
