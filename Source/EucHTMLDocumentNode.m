//
//  EucHTMLDocumentNode.m
//  LibCSSTest
//
//  Created by James Montgomerie on 10/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <libcss/libcss.h>

#import "EucHTMLDBNode.h"
#import "EucHTMLDocument.h"
#import "EucHTMLDocumentNode.h"


@implementation EucHTMLDocumentNode

@synthesize dbNode = _dbNode;

- (id)initWithHTMLDBNode:(EucHTMLDBNode *)dbNode inDocument:(EucHTMLDocument *)document;
{
    if((self = [super init])) {
        _dbNode = [dbNode retain];
        _document = [document retain];
    }
    return self;
}

- (void)dealloc
{
    [_document notifyOfDealloc:self];
 
    [_children release];
    
    if(_computedStyle) {
        css_computed_style_destroy(_computedStyle);
    }
        
    [_dbNode release];
    [_document release];
    
    [super dealloc];
}

- (uint32_t)key
{
    return _dbNode.key;
}

- (css_computed_style *)computedStyle
{
    if(!_computedStyle) {
        css_computed_style_create(EucRealloc, NULL, &_computedStyle);
        css_select_handler *selectHandler = [EucHTMLDBNode selectHandler];
        css_error err = css_select_style(_document.selectContext, 
                                         (void *)(uintptr_t)_dbNode.key,
                                         CSS_PSEUDO_ELEMENT_NONE, 
                                         CSS_MEDIA_PRINT, 
                                         NULL, 
                                         _computedStyle,
                                         selectHandler,
                                         _document.htmlDBNodeManager);
        if(err != CSS_OK) {
            EucHTMLDocumentNode *parent = self.parent;
            if(parent) {
                err = css_computed_style_compose([parent computedStyle], 
                                                 _computedStyle,
                                                 selectHandler->compute_font_size,
                                                 _document.htmlDBNodeManager,
                                                 _computedStyle);
            } 
        }
    }
    return _computedStyle;
}

- (BOOL)hasText
{
    return _dbNode.kind == nodeKindText;
}

- (EucHTMLDocumentNode *)parent
{
    return [_document nodeForKey:_dbNode.parentNode.key];
}

- (EucHTMLDocumentNode *)next
{
    return [_document nodeForKey:_dbNode.nextNode.key];
}

- (EucHTMLDocumentNode *)nextUnder:(EucHTMLDocumentNode *)under {
    return [_document nodeForKey:[_dbNode nextNodeUnder:under.dbNode].key];
}

- (NSArray *)children
{
    if(!_children) {
        uint32_t childrenCount = _dbNode.childrenKeysCount;
        if(childrenCount) {
            EucHTMLDocumentNode *children[childrenCount];
            uint32_t *childrenKeys = _dbNode.childrenKeys;
            for(uint32_t i = 0; i < childrenCount; ++i) {
                children[i] = [_document nodeForKey:childrenKeys[i]];
            }
            _children = [[NSArray alloc] initWithObjects:children count:childrenCount];
        }
    }
    return _children;
}

@end
