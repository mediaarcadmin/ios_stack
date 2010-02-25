//
//  EucHTMLDocumentNode.m
//  LibCSSTest
//
//  Created by James Montgomerie on 24/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucHTMLDocument.h"
#import "EucHTMLDocumentNode.h"
#import "THStringRenderer.h"
#import "LWCNSStringAdditions.h"

@implementation EucHTMLDocumentNode

@dynamic parent;

@dynamic childrenCount;
@dynamic children;

@dynamic computedStyle;


@synthesize document = _document;
@synthesize key = _key;


- (void)dealloc
{
    [self.document notifyOfDealloc:self];

    [_stringRenderer release];
    
    [super dealloc];
}

- (EucHTMLDocumentNode *)_nodeAfter:(EucHTMLDocumentNode *)child under:(EucHTMLDocumentNode *)under
{
    NSUInteger childrenCount =  self.childrenCount;
    if(childrenCount > 1) {
        NSArray *children = self.children;
        NSUInteger i = 0;
        NSUInteger maxChildBeforeEnd = childrenCount - 1;
        for(; i < maxChildBeforeEnd; ++i) {
            if([children objectAtIndex:i] == child) {
                return [children objectAtIndex:i + 1];
            }
        }
    }
    // This is our last child.
    if(self == under) {
        return nil;
    }
    return [self.parent _nodeAfter:self under:under];
}

- (EucHTMLDocumentNode *)nextUnder:(EucHTMLDocumentNode *)under {
    NSArray *children = self.children;
    if(children) {
        return [children objectAtIndex:0];
    } else if(self != under){
        return [self.parent _nodeAfter:self under:under];
    } else {
        return NULL;
    } 
}

- (EucHTMLDocumentNode *)next
{
    return [self nextUnder:nil];
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

- (EucHTMLDocumentNode *)blockLevelNode
{
    EucHTMLDocumentNode *prospectiveNode = self;
    css_computed_style *currentNodeStyle = self.computedStyle;
    while(prospectiveNode && (!currentNodeStyle || (css_computed_display(currentNodeStyle, false) & CSS_DISPLAY_BLOCK) != CSS_DISPLAY_BLOCK)) {
        prospectiveNode = prospectiveNode.parent;
        currentNodeStyle = prospectiveNode.computedStyle;
    }  
    return prospectiveNode;    
}

- (EucHTMLDocumentNode *)blockLevelParent
{
    return self.parent.blockLevelNode;
}

- (BOOL)isTextNode
{
    return NO;
}

- (NSString *)text
{
    return nil;
}

@end
