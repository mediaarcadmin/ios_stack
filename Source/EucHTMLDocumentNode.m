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

- (css_computed_style *)_computedStyle
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
                err = css_computed_style_compose([parent _computedStyle], 
                                                 _computedStyle,
                                                 selectHandler->compute_font_size,
                                                 _document.htmlDBNodeManager,
                                                 _computedStyle);
            } 
        }
    }
    return _computedStyle;
}

- (EucHTMLDocumentNode *)parent
{
    return [_document nodeForKey:_dbNode.parentNode.key];
}

- (EucHTMLDocumentNode *)next
{
    return [_document nodeForKey:_dbNode.nextNode.key];
}

@end
