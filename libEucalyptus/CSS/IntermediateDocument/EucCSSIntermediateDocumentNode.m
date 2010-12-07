//
//  EucCSSIntermediateDocumentNode.m
//  LibCSSTest
//
//  Created by James Montgomerie on 24/02/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import "EucConfiguration.h"
#import "EucCSSInternal.h"
#import "EucCSSIntermediateDocument.h"
#import "EucCSSIntermediateDocument_Package.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "THStringRenderer.h"
#import "THPair.h"
#import "THCache.h"
#import "LWCNSStringAdditions.h"
#import <libcss/libcss.h>

#import <pthread.h>

@implementation EucCSSIntermediateDocumentNode

@dynamic parent;

@dynamic childCount;
@dynamic childKeys;

@dynamic computedStyle;


@synthesize document = _document;
@synthesize key = _key;

static THStringAndIntegerToObjectCache *sStringRenderersCache = nil;

+ (void)initialize
{
    if (self == [EucCSSIntermediateDocumentNode class]) {
        sStringRenderersCache = [[THStringAndIntegerToObjectCache alloc] init];
    }
}

- (void)dealloc
{    
    [_stringRenderer release];

    [super dealloc];
}

- (EucCSSIntermediateDocumentNode *)_nodeBefore:(EucCSSIntermediateDocumentNode *)child under:(EucCSSIntermediateDocumentNode *)under
{
    uint32_t childCount =  self.childCount;
    if(childCount > 1) {
        uint32_t afterKey = child.key;
        uint32_t *childKeys = self.childKeys;
        if(afterKey != childKeys[0]) {
            for(NSUInteger i = 1; i <= childCount; ++i) {
                if(childKeys[i] == afterKey || i == childCount) {
                    EucCSSIntermediateDocumentNode *before = [_document nodeForKey:childKeys[i-1]];
                    while(before.childCount) {
                        before = [_document nodeForKey:before.childKeys[before.childCount-1]];
                    }
                    return before;
                }
            }
        } 
    }
    // This is our last child.
    if(self == under) {
        return nil;
    }
    return self;
}


- (EucCSSIntermediateDocumentNode *)_nodeAfter:(EucCSSIntermediateDocumentNode *)child under:(EucCSSIntermediateDocumentNode *)under
{
    uint32_t childCount =  self.childCount;
    if(childCount > 1) {
        uint32_t beforeKey = child.key;
        uint32_t *childKeys = self.childKeys;
        NSUInteger i = 0;
        NSUInteger maxChildBeforeEnd = childCount - 1;
        for(; i < maxChildBeforeEnd; ++i) {
            if(childKeys[i] == beforeKey) {
                return [_document nodeForKey:childKeys[i+1]];
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
    uint32_t *childKeys = self.childKeys;
    if(childKeys) {
        return [_document nodeForKey:childKeys[0]];
    } else if(self != under){
        return [self.parent _nodeAfter:self under:under];
    } else {
        return NULL;
    } 
}

- (EucCSSIntermediateDocumentNode *)previousUnder:(EucCSSIntermediateDocumentNode *)under {
    if(self != under){
        return [self.parent _nodeBefore:self under:under];
    } else {
        return NULL;
    } 
}

- (EucCSSIntermediateDocumentNode *)next
{
    return [self nextUnder:nil];
}

- (EucCSSIntermediateDocumentNode *)previous
{
    return [self previousUnder:nil];
}


- (EucCSSIntermediateDocumentNode *)displayableNodeAfter:(EucCSSIntermediateDocumentNode *)child under:(EucCSSIntermediateDocumentNode *)under
{
    uint32_t childCount =  self.childCount;
    if(childCount) {
        uint32_t beforeKey = child.key;
        uint32_t *childKeys = self.childKeys;
        uint32_t i = 0;
        if(child) {
            for(; i < childCount; ++i) {
                if(childKeys[i] == beforeKey) {
                    ++i;
                    break;
                }
            }
        }
        for(; i < childCount; ++i) {
            EucCSSIntermediateDocumentNode *prospectiveNextNode = [_document nodeForKey:childKeys[i]];
            css_computed_style *style = [prospectiveNextNode computedStyle];
            if(!style || css_computed_display(style, false) != CSS_DISPLAY_NONE) {
                return prospectiveNextNode;
            } 
        }
    }
    if(self == under) {
        return nil;
    }
    return [self.parent displayableNodeAfter:self under:under];
}

- (EucCSSIntermediateDocumentNode *)nextDisplayableUnder:(EucCSSIntermediateDocumentNode *)under \
{
   /* EucCSSIntermediateDocumentNode *nextNode = nil;
    
    NSArray *children = self.children;
    if(children) {
        nextNode = [self _displayableNodeAfter:nil under:under];
    }
    if(!nextNode) {
        if(self != under){
            nextNode = [self.parent _displayableNodeAfter:self under:under];
        } 
    }*/
    return [self displayableNodeAfter:nil under:under];
}

- (EucCSSIntermediateDocumentNode *)nextDisplayable
{
    return [self nextDisplayableUnder:nil];
}

- (EucCSSIntermediateDocumentNode *)previousDisplayableSibling
{
    EucCSSIntermediateDocumentNode *parent = self.parent;
    uint32_t parentChildCount = parent.childCount;
    if(parentChildCount > 1) {
        uint32_t myKey = self.key;
        uint32_t *parentChildKeys = parent.childKeys;
        for(uint32_t i = 1; i < parentChildCount; ++i) {
            if(parentChildKeys[i] == myKey) {
                return [_document nodeForKey:parentChildKeys[i-1]];
            }
        }
    }
    return nil;
}

- (THStringRenderer *)_cachedStringRendererWithFontName:(NSString *)fontName
                                             styleFlags:(THStringRendererFontStyleFlags)styleFlags
{
    THStringRenderer *stringRenderer;
    
    stringRenderer = [sStringRenderersCache objectForStringKey:fontName integerKey:styleFlags];
    if(!stringRenderer) {
        stringRenderer = [[THStringRenderer alloc] initWithFontName:fontName
                                                         styleFlags:styleFlags];
        if(stringRenderer) {
            [sStringRenderersCache cacheObject:stringRenderer forStringKey:fontName integerKey:styleFlags];
            [stringRenderer autorelease];
        } else {
            [sStringRenderersCache cacheObject:[NSNull null] forStringKey:fontName integerKey:styleFlags];
        }
    } else {
        if((id)stringRenderer == [NSNull null]) {
            stringRenderer = nil;
        } 
    }  
    
    return stringRenderer;
}

- (void)_setupTextIVars
{
    css_computed_style *style = self.computedStyle;
    if(!style) {
        EucCSSIntermediateDocumentNode *parent = self.parent;
        _stringRenderer = [parent.stringRenderer retain];
        _textPointSize = parent->_textPointSize;
    } else {
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
                
                _stringRenderer = [self _cachedStringRendererWithFontName:fontName
                                                               styleFlags:styleFlags];
            }
        }
        
        if(!_stringRenderer) {
            NSString *fontName;
            switch(family) {
                case CSS_FONT_FAMILY_SERIF:
                    fontName = [EucConfiguration objectForKey:EucConfigurationSerifFontFamilyKey];
                    break;                            
                case CSS_FONT_FAMILY_SANS_SERIF:
                    fontName = [EucConfiguration objectForKey:EucConfigurationSansSerifFontFamilyKey];
                    break;
                case CSS_FONT_FAMILY_MONOSPACE:
                    fontName = [EucConfiguration objectForKey:EucConfigurationMonospaceFontFamilyKey];
                    break;
                case CSS_FONT_FAMILY_CURSIVE:
                    fontName = [EucConfiguration objectForKey:EucConfigurationCursiveFontFamilyKey];
                    break;
                case CSS_FONT_FAMILY_FANTASY:
                    fontName = [EucConfiguration objectForKey:EucConfigurationFantasyFontFamilyKey];
                    break;
                default:
                    fontName = [EucConfiguration objectForKey:EucConfigurationDefaultFontFamilyKey];
            }
            _stringRenderer = [self _cachedStringRendererWithFontName:fontName
                                                           styleFlags:styleFlags];
        }
        
        [_stringRenderer retain];
        
        css_fixed length = 0;
        css_unit unit = (css_unit)0;
        
        css_computed_font_size(style, &length, &unit);
        _textPointSize = EucCSSLibCSSSizeToPixels(style, length, unit, 0.0f, 1.0f);    
    }    
}    

- (THStringRenderer *)stringRenderer
{
    if(!_stringRenderer) {
        [self _setupTextIVars];
    }
    return _stringRenderer;
}

- (CGFloat)textPointSizeAtScaleFactor:(CGFloat)scaleFactor
{
    if(!_stringRenderer) {
        [self _setupTextIVars];
    }
    return roundf(_textPointSize * scaleFactor);
}

- (CGFloat)textAscenderAtScaleFactor:(CGFloat)scaleFactor
{
    if(!_stringRenderer) {
        [self _setupTextIVars];
    } 
    return [_stringRenderer ascenderForPointSize:[self textPointSizeAtScaleFactor:scaleFactor]];
}

- (CGFloat)lineHeightAtScaleFactor:(CGFloat)scaleFactor
{
    if(!_stringRenderer) {
        [self _setupTextIVars];
    }  
    
    css_computed_style *style = NULL;
    css_fixed size = size; 
    css_unit units = units; 

    if(!_lineHeightKind) {
        style = self.computedStyle;
        if(!style) {
            style = self.parent.computedStyle;
        }
        _lineHeightKind = css_computed_line_height(style, &size, &units); 
    }
    
    if(_lineHeightKind == CSS_LINE_HEIGHT_NORMAL) {
        return [_stringRenderer lineSpacingForPointSize:[self textPointSizeAtScaleFactor:scaleFactor]];
    } else {
        if(!style) {
            style = self.computedStyle;
            if(!style) {
                style = self.parent.computedStyle;
            }
            css_computed_line_height(style, &size, &units);             
        }
        return EucCSSLibCSSSizeToPixels(style, size, units, [self textPointSizeAtScaleFactor:scaleFactor], scaleFactor);
    }
}

- (EucCSSIntermediateDocumentNode *)blockLevelNode
{
    EucCSSIntermediateDocumentNode *prospectiveNode = self;
    css_computed_style *currentNodeStyle = self.computedStyle;
    while(prospectiveNode && (!currentNodeStyle || css_computed_display(currentNodeStyle, false) != CSS_DISPLAY_BLOCK)) {
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

- (NSArray *)preprocessedWords
{
    return nil;
}

- (BOOL)isImageNode
{
    return NO;
}

- (NSURL *)imageSource
{
    return nil;
}

- (BOOL)isHyperlinkNode
{
    return NO;
}

- (NSURL *)hyperlinkURL
{
    return nil;
}


- (NSString *)altText
{
    return nil;
}

- (NSString *)name
{
    return NSStringFromClass(self.class);
}

@end
