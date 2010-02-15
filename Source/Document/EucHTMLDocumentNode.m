//
//  EucHTMLDocumentNode.m
//  LibCSSTest
//
//  Created by James Montgomerie on 10/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <libcss/libcss.h>
#import <libcss/properties.h>

#import "EucHTMLDBNode.h"
#import "EucHTMLDocument.h"
#import "EucHTMLDocumentNode.h"
#import "LWCNSStringAdditions.h"
#import "THStringRenderer.h"
#import "THLog.h"

@implementation EucHTMLDocumentNode

@synthesize dbNode = _dbNode;
@synthesize document = _document;

- (id)initWithHTMLDBNode:(EucHTMLDBNode *)dbNode inDocument:(EucHTMLDocument *)document;
{
    if((self = [super init])) {
        _dbNode = [dbNode retain];
        _document = document;
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
    
    [_text release];
        
    [_dbNode release];
    
    [super dealloc];
}

- (uint32_t)key
{
    return _dbNode.key;
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

- (css_computed_style *)computedStyle
{
    if(_dbNode.kind == nodeKindElement) {
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
            if(err == CSS_OK) {
                if(self != _document.body) {
                    EucHTMLDocumentNode *parent = self.parent;
                    if(parent) {
                        const css_computed_style *parentStyle = parent.computedStyle;
                        if(parentStyle) {
                            err = css_computed_style_compose(parentStyle, 
                                                             _computedStyle,
                                                             selectHandler->compute_font_size,
                                                             _document.htmlDBNodeManager,
                                                             _computedStyle);
                            if(err != CSS_OK) {
                                THWarn(@"Error %ld composing style", (long)err);
                            }
                        }
                    } 
                }
            } else {
                THWarn(@"Error %ld selecting style", (long)err);
            }
        }
    }
    return _computedStyle;
}

- (THStringRenderer *)stringRenderer
{
    if(!_stringRenderer) {
        css_computed_style *style;
        if(self.isTextNode) {
            style = self.parent.computedStyle;
        } else {
            style = self.computedStyle;
        }
        
        if(style) {
            THStringRendererFontStyleFlags styleFlags = THStringRendererFontStyleFlagRegular;

            uint8_t fontStyle = css_computed_font_style(style);
            if(fontStyle == CSS_FONT_STYLE_ITALIC ||
               fontStyle == CSS_FONT_STYLE_OBLIQUE) {
                styleFlags |= THStringRendererFontStyleFlagItalic;
            }
            
            uint8_t fontWeight = css_computed_font_weight(style);
            if(fontWeight == CSS_FONT_WEIGHT_BOLD ||
               fontWeight == CSS_FONT_WEIGHT_BOLDER) {
                styleFlags |= THStringRendererFontStyleFlagBold;
            }
            //// TODO: handle other weights.
            
            //// TODO: handle small caps
            // uint8_t fontVariant = css_computed_font_variant(style);
            
            lwc_string **names = NULL;
            uint8_t family = css_computed_font_family(style, &names);
            
            if(names) {
                for(; *names && !_stringRenderer; ++names) {
                    NSString *fontName = [NSString stringWithLWCString:*names];
                    _stringRenderer = [[THStringRenderer alloc] initWithFontName:fontName
                                                                      styleFlags:styleFlags];
                }
            }
            
            if(!_stringRenderer) {
                NSString *fontName = @"LinuxLibertine";
                if(!names) {
                    switch(family) {
                        case CSS_FONT_FAMILY_SANS_SERIF:
                            fontName = @"Helvetica";
                            break;
                        case CSS_FONT_FAMILY_SERIF:
                        case CSS_FONT_FAMILY_CURSIVE:
                        case CSS_FONT_FAMILY_FANTASY:
                        case CSS_FONT_FAMILY_MONOSPACE:
                            break;
                    }
                }
                _stringRenderer = [[THStringRenderer alloc] initWithFontName:fontName
                                                                  styleFlags:styleFlags];
            }
        }
    }
    return _stringRenderer;
}

- (EucHTMLDocumentNode *)parent
{
    EucHTMLDBNode *parentDBNode = _dbNode.parentNode;
    if(parentDBNode) {
        return [_document nodeForKey:parentDBNode.key];
    } else {
        return nil;
    }    
}

- (EucHTMLDocumentNode *)blockLevelParent
{
    EucHTMLDocumentNode *prospectiveParent = self;
    css_computed_style *currentNodeStyle = NULL;
    do {
        prospectiveParent = prospectiveParent.parent;
        currentNodeStyle = prospectiveParent.computedStyle;
    } while(prospectiveParent && (!currentNodeStyle || (css_computed_display(currentNodeStyle, false) & CSS_DISPLAY_BLOCK) != CSS_DISPLAY_BLOCK));
    return prospectiveParent;
}

- (EucHTMLDocumentNode *)next
{
    EucHTMLDBNode *nextDBNode = _dbNode.nextNode;
    if(nextDBNode) {
        return [_document nodeForKey:nextDBNode.key];
    } else {
        return nil;
    }    
}

- (EucHTMLDocumentNode *)nextUnder:(EucHTMLDocumentNode *)under {
    EucHTMLDBNode *nextDBNode = [_dbNode nextNodeUnder:under.dbNode];
    if(nextDBNode) {
        return [_document nodeForKey:nextDBNode.key];
    } else {
        return nil;
    }
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
