//
//  EucCSSIntermediateDocumentNode.m
//  LibCSSTest
//
//  Created by James Montgomerie on 24/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucCSSIntermediateDocument.h"
#import "EucCSSIntermediateDocument_Package.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "THStringRenderer.h"
#import "LWCNSStringAdditions.h"
#import <libcss/libcss.h>

@implementation EucCSSIntermediateDocumentNode

@dynamic parent;

@dynamic childrenCount;
@dynamic children;

@dynamic computedStyle;


@synthesize document = _document;
@synthesize key = _key;


- (void)dealloc
{
    [_document notifyOfDealloc:self];
    [_document release];
    
    [_stringRenderer release];
    
    [super dealloc];
}

- (EucCSSIntermediateDocumentNode *)_nodeAfter:(EucCSSIntermediateDocumentNode *)child under:(EucCSSIntermediateDocumentNode *)under
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

- (EucCSSIntermediateDocumentNode *)nextUnder:(EucCSSIntermediateDocumentNode *)under {
    NSArray *children = self.children;
    if(children) {
        return [children objectAtIndex:0];
    } else if(self != under){
        return [self.parent _nodeAfter:self under:under];
    } else {
        return NULL;
    } 
}

- (EucCSSIntermediateDocumentNode *)next
{
    return [self nextUnder:nil];
}

- (EucCSSIntermediateDocumentNode *)_displayableNodeAfter:(EucCSSIntermediateDocumentNode *)child under:(EucCSSIntermediateDocumentNode *)under
{
    NSUInteger childrenCount =  self.childrenCount;
    if(childrenCount) {
        NSArray *children = self.children;
        NSUInteger i = 0;
        if(child) {
            for(; i < childrenCount; ++i) {
                if([children objectAtIndex:i] == child) {
                    ++i;
                    break;
                }
            }
        }
        for(; i < childrenCount; ++i) {
            EucCSSIntermediateDocumentNode *prospectiveNextNode = [children objectAtIndex:i];
            css_computed_style *style = [prospectiveNextNode computedStyle];
            if(!style || css_computed_display(style, false) != CSS_DISPLAY_NONE) {
                return prospectiveNextNode;
            } 
        }
    }
    if(self == under) {
        return nil;
    }
    return [self.parent _displayableNodeAfter:self under:under];
}

- (EucCSSIntermediateDocumentNode *)nextDisplayableUnder:(EucCSSIntermediateDocumentNode *)under {
    EucCSSIntermediateDocumentNode *nextNode = nil;
    
    NSArray *children = self.children;
    if(children) {
        nextNode = [self _displayableNodeAfter:nil under:under];
    }
    if(!nextNode) {
        if(self != under){
            nextNode = [self.parent _displayableNodeAfter:self under:under];
        } 
    }
    return nextNode;
}

- (EucCSSIntermediateDocumentNode *)nextDisplayable
{
    return [self nextDisplayableUnder:nil];
}


- (EucCSSIntermediateDocumentNode *)previousDisplayableSibling
{
    EucCSSIntermediateDocumentNode *parent = self.parent;
    NSArray *parentChildren = parent.children;
    if(parentChildren.count > 1) {
        NSUInteger myIndex = [parentChildren indexOfObject:self];
        if(myIndex >= 1) {
            return [parentChildren objectAtIndex:myIndex - 1];
        }
    }
    return nil;
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
                NSString *fontName = @"Georgia";
                if(!names) {
                    switch(family) {
                        case CSS_FONT_FAMILY_SANS_SERIF:
                            fontName = @"Helvetica";
                            break;
                        case CSS_FONT_FAMILY_MONOSPACE:
                            fontName = @"Courier";
                            break;
                        case CSS_FONT_FAMILY_SERIF:
                        case CSS_FONT_FAMILY_CURSIVE:
                        case CSS_FONT_FAMILY_FANTASY:
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

- (EucCSSIntermediateDocumentNode *)blockLevelNode
{
    EucCSSIntermediateDocumentNode *prospectiveNode = self;
    css_computed_style *currentNodeStyle = self.computedStyle;
    while(prospectiveNode && (!currentNodeStyle || (css_computed_display(currentNodeStyle, false) & CSS_DISPLAY_BLOCK) != CSS_DISPLAY_BLOCK)) {
        prospectiveNode = prospectiveNode.parent;
        currentNodeStyle = prospectiveNode.computedStyle;
    }  
    return prospectiveNode;    
}

- (EucCSSIntermediateDocumentNode *)blockLevelParent
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

- (BOOL)isImageNode
{
    return NO;
}

- (NSURL *)imageSrc
{
    return nil;
}

@end
