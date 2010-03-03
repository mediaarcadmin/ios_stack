//
//  EucHTMLDocumentConcreteNode.m
//  LibCSSTest
//
//  Created by James Montgomerie on 10/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <libcss/libcss.h>
#import <libcss/properties.h>

#import "EucHTMLDBNode.h"
#import "EucHTMLDocument.h"
#import "EucHTMLDocumentConcreteNode.h"
#import "EucHTMLDocumentGeneratedContainerNode.h"
#import "LWCNSStringAdditions.h"
#import "THStringRenderer.h"
#import "THLog.h"

@implementation EucHTMLDocumentConcreteNode

@synthesize dbNode = _dbNode;

- (id)initWithHTMLDBNode:(EucHTMLDBNode *)dbNode inDocument:(EucHTMLDocument *)document;
{
    if((self = [super init])) {
        _dbNode = [dbNode retain];
        self.document = document;
        self.key = _dbNode.key << EUC_HTML_DOCUMENT_DB_KEY_SHIFT_FOR_FLAGS;
    }
    return self;
}

- (void)dealloc
{ 
    [_children release];
    
    if(_computedStyle) {
        css_computed_style_destroy(_computedStyle);
    }
    if(_computedBeforeStyle) {
        css_computed_style_destroy(_computedBeforeStyle);
    }
    if(_computedAfterStyle) {
        css_computed_style_destroy(_computedAfterStyle);
    }
    
    [_text release];
        
    [_dbNode release];
    
    [super dealloc];
}

- (BOOL)isTextNode
{
    return _dbNode.kind == nodeKindText;
}

- (NSString *)name
{
    lwc_string *name = _dbNode.name;
    if(name) {
        return [NSString stringWithLWCString:name];
    } else {
        return nil;
    }
}

- (NSString *)text
{
    if(!_text) {
        char *contents;
        size_t length = 0;
        if([_dbNode getCharacterContents:&contents length:&length]) {
            _text = (NSString *)CFStringCreateWithBytes(kCFAllocatorDefault,
                                                        (const UInt8 *)contents, 
                                                        length, 
                                                        kCFStringEncodingUTF8, 
                                                        false);
        }
    }
    return _text;
}

- (css_computed_style *)_createComputedStyleForPseudoElement:(enum css_pseudo_element)pseudoElement
                                            usingInlineStyle:(const css_stylesheet *)inlineStyle
                                            usingParentStyle:(const css_computed_style *)parentStyle 
{
    css_error err;
    css_computed_style *ret;
    
    css_computed_style_create(EucRealloc, NULL, &ret);
    css_select_handler *selectHandler = [EucHTMLDBNode selectHandler];
    err = css_select_style(_document.selectContext, 
                           (void *)(uintptr_t)_dbNode.key,
                           pseudoElement, 
                           CSS_MEDIA_PRINT, 
                           inlineStyle, 
                           ret,
                           selectHandler,
                           _document.htmlDBNodeManager);
        
    if(err == CSS_OK) {
        if(pseudoElement != CSS_PSEUDO_ELEMENT_NONE) {
            const css_computed_content_item *content = NULL;
            enum css_content_e contentValukeKind = css_computed_content(ret, &content);
            if(contentValukeKind == CSS_CONTENT_NONE ||
               contentValukeKind == CSS_CONTENT_NORMAL) {
                css_computed_style_destroy(ret);
                ret = NULL;
            }
        }
        
        if(ret) {
            if(parentStyle) {
                err = css_computed_style_compose(parentStyle, 
                                                 ret,
                                                 selectHandler->compute_font_size,
                                                 _document.htmlDBNodeManager,
                                                 ret);
                if(err != CSS_OK) {
                    THWarn(@"Error %ld composing style", (long)err);
                }
            }
        }
    } else {
        THWarn(@"Error %ld selecting style", (long)err);
    }    
    
    return ret;
}

- (void)_computeStyles
{
    if(_dbNode.kind == nodeKindElement) {
        css_error err;
        
        css_stylesheet *inlineStyle = NULL;
        hubbub_string inlineStyleString = [_dbNode copyHubbubAttributeForName:"style"];
        if(inlineStyleString.len) {
            err = css_stylesheet_create(CSS_LEVEL_21, "UTF-8",
                                        "", "", CSS_ORIGIN_AUTHOR, 
                                        CSS_MEDIA_ALL, false,
                                        true, _document.lwcContext,
                                        EucRealloc, NULL,
                                        EucResolveURL, NULL,
                                        &inlineStyle);
            if(err != CSS_OK) {
                THWarn(@"Error %ld creating inline style", (long)err);
            } else {
                err = css_stylesheet_append_data(inlineStyle, inlineStyleString.ptr, inlineStyleString.len);
                if(err == CSS_NEEDDATA) {
                    err = css_stylesheet_data_done(inlineStyle);
                }
                if(err != CSS_OK) {
                    THWarn(@"Error %ld adding data to inline style", (long)err);
                    css_stylesheet_destroy(inlineStyle);
                    inlineStyle = NULL;
                }
            }
            free((void *)inlineStyleString.ptr);
        }
        
        const css_computed_style *parentStyle = nil;
        EucHTMLDocumentConcreteNode *parent = (EucHTMLDocumentConcreteNode *)self.parent;
        if(parent) {
            parentStyle = parent.computedStyle;
        }
        
        _computedStyle = [self _createComputedStyleForPseudoElement:CSS_PSEUDO_ELEMENT_NONE usingInlineStyle:inlineStyle usingParentStyle:parentStyle];
        if(_computedStyle) {
            _computedBeforeStyle = [self _createComputedStyleForPseudoElement:CSS_PSEUDO_ELEMENT_BEFORE usingInlineStyle:NULL usingParentStyle:_computedStyle];
            _computedAfterStyle = [self _createComputedStyleForPseudoElement:CSS_PSEUDO_ELEMENT_AFTER usingInlineStyle:NULL usingParentStyle:_computedStyle];
        }
                
        if(inlineStyle) {
            css_stylesheet_destroy(inlineStyle);
        }
    }
    _stylesComputed = YES;
}

- (css_computed_style *)computedStyle
{
    if(!_stylesComputed) {
        [self _computeStyles];
    }
    return _computedStyle;
}

- (css_computed_style *)computedBeforeStyle
{
    if(!_stylesComputed) {
        [self _computeStyles];
    }
    return _computedBeforeStyle;
}

- (css_computed_style *)computedAfterStyle
{
    if(!_stylesComputed) {
        [self _computeStyles];
    }
    return _computedAfterStyle;
}

- (EucHTMLDocumentNode *)parent
{
    EucHTMLDBNode *parentDBNode = _dbNode.parentNode;
    if(parentDBNode) {
        return [_document nodeForKey:parentDBNode.key << EUC_HTML_DOCUMENT_DB_KEY_SHIFT_FOR_FLAGS];
    } else {
        return nil;
    }    
}

- (NSUInteger)childrenCount;
{
    NSUInteger childrenCount = _dbNode.childrenKeysCount;
    if(self.computedBeforeStyle) {
        childrenCount++;
    }
    if(self.computedAfterStyle) {
        childrenCount++;
    }
    return childrenCount;
}

- (NSArray *)children
{
    if(!_children) { 
        NSUInteger childrenCount = self.childrenCount;
        if(childrenCount) {
            NSMutableArray *children = [[NSMutableArray alloc] initWithCapacity:childrenCount];
            
            if(self.computedBeforeStyle) {
                [children addObject:[_document nodeForKey:self.key | EucHTMLDocumentNodeKeyFlagBeforeContainerNode]];
            }
            
            uint32_t dbNodeChildrenCount = _dbNode.childrenKeysCount;
            uint32_t *childrenKeys = _dbNode.childrenKeys;
            for(uint32_t i = 0; i < dbNodeChildrenCount; ++i) {
                [children addObject:[_document nodeForKey:childrenKeys[i] << EUC_HTML_DOCUMENT_DB_KEY_SHIFT_FOR_FLAGS]];
            }

            if(self.computedAfterStyle) {
                [children addObject:[_document nodeForKey:self.key | EucHTMLDocumentNodeKeyFlagAfterContainerNode]];
            }
            
            _children = children;
        }
    }
    return _children;
}


@end
