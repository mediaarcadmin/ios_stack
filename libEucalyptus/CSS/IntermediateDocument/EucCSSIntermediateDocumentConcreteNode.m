//
//  EucCSSIntermediateDocumentConcreteNode.m
//  LibCSSTest
//
//  Created by James Montgomerie on 10/12/2009.
//  Copyright 2009 Things Made Out Of Other Things. All rights reserved.
//

#import <libcss/libcss.h>
#import <libcss/properties.h>

#import "EucCSSInternal.h"

#import "EucCSSIntermediateDocument.h"
#import "EucCSSIntermediateDocument_Package.h"
#import "EucCSSIntermediateDocumentConcreteNode.h"
#import "EucCSSIntermediateDocumentGeneratedContainerNode.h"
#import "EucCSSIntermediateDocumentGeneratedTextNode.h"

#import "EucCSSDocumentTree.h"
#import "EucCSSDocumentTree_Package.h"
#import "EucCSSDocumentTreeNode.h"

#import "LWCNSStringAdditions.h"
#import "THStringRenderer.h"
#import "THLog.h"

@implementation EucCSSIntermediateDocumentConcreteNode

@synthesize documentTreeNode = _documentTreeNode;

- (id)initWithDocumentTreeNode:(id<EucCSSDocumentTreeNode>)documentTreeNode inDocument:(EucCSSIntermediateDocument *)document;
{
    if((self = [super init])) {
        _documentTreeNode = [documentTreeNode retain];
        self.document = document;
        self.key = _documentTreeNode.key << EUC_CSS_DOCUMENT_TREE_NODE_TO_INTERMEDIATE_DOCUMENT_NODE_KEY_SHIFT_FOR_FLAGS;
    }
    return self;
}

- (void)dealloc
{ 
    free(_childKeys);
    
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
        
    [_documentTreeNode release];
    
    [super dealloc];
}

- (NSString *)name
{
    return _documentTreeNode.name;
}

- (BOOL)isTextNode
{
    return _documentTreeNode.kind == EucCSSDocumentTreeNodeKindText;
}

- (NSString *)text
{
    if(!_text) {
        const char *contents;
        size_t length = 0;
        if([_documentTreeNode getCharacterContents:&contents length:&length]) {
            _text = (NSString *)CFStringCreateWithBytes(kCFAllocatorDefault,
                                                        (const UInt8 *)contents, 
                                                        length, 
                                                        kCFStringEncodingUTF8, 
                                                        false);
        }
    }
    return _text;
}

- (NSArray *)preprocessedWords
{
    if([_documentTreeNode respondsToSelector:@selector(preprocessedWordStrings)]) {
        return [_documentTreeNode performSelector:@selector(preprocessedWordStrings)];
    } else {
        return nil;
    }
}

- (BOOL)isImageNode
{
    return _documentTreeNode.isImageNode;
}

- (NSURL *)imageSource
{
    NSString *src = _documentTreeNode.imageSourceURLString;
    if(src) {
        return [NSURL URLWithString:src relativeToURL:_document.url];
    }
    return nil;
}

- (BOOL)isHyperlinkNode
{
    return _documentTreeNode.isHyperlinkNode;
}

- (NSURL *)hyperlinkURL
{
    NSString *href = _documentTreeNode.hyperlinkURLString;
    if(href) {
        return [NSURL URLWithString:href relativeToURL:_document.url];
    }
    return nil;
}


- (NSString *)altText
{
    return [_documentTreeNode attributeWithName:@"alt"];
}

- (css_computed_style *)_createComputedStyleForPseudoElement:(enum css_pseudo_element)pseudoElement
                                            usingInlineStyle:(const css_stylesheet *)inlineStyle
                                            usingParentStyle:(const css_computed_style *)parentStyle 
{
    css_error err;
    css_computed_style *ret;
    
    css_computed_style_create(EucRealloc, NULL, &ret);
    css_select_handler *selectHandler = &EucCSSDocumentTreeSelectHandler;
    err = css_select_style(_document.selectContext, 
                           (void *)(uintptr_t)_documentTreeNode.key,
                           pseudoElement, 
                           CSS_MEDIA_PRINT, 
                           inlineStyle, 
                           ret,
                           selectHandler,
                           _document.documentTree);
        
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
                                                 NULL,
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
    if(_documentTreeNode.kind == EucCSSDocumentTreeNodeKindElement || 
       _documentTreeNode.kind == EucCSSDocumentTreeNodeKindRoot) {
        css_error err;
        
        css_stylesheet *inlineStyle = NULL;
        NSString *inlineStyleString = [_documentTreeNode attributeWithName:@"style"];
        if(inlineStyleString) {
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
                const char *utf8StyleString = [inlineStyleString UTF8String];
                err = css_stylesheet_append_data(inlineStyle, (const uint8_t *)utf8StyleString, strlen(utf8StyleString));
                if(err == CSS_NEEDDATA) {
                    err = css_stylesheet_data_done(inlineStyle);
                }
                if(err != CSS_OK) {
                    THWarn(@"Error %ld adding data to inline style", (long)err);
                    css_stylesheet_destroy(inlineStyle);
                    inlineStyle = NULL;
                }
            }
        }
        
        const css_computed_style *parentStyle = nil;
        EucCSSIntermediateDocumentConcreteNode *parent = (EucCSSIntermediateDocumentConcreteNode *)self.parent;
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

- (EucCSSIntermediateDocumentNode *)parent
{
    id<EucCSSDocumentTreeNode> parentDocumentTreeNode = _documentTreeNode.parent;
    if(parentDocumentTreeNode) {
        return [_document nodeForKey:parentDocumentTreeNode.key << EUC_CSS_DOCUMENT_TREE_NODE_TO_INTERMEDIATE_DOCUMENT_NODE_KEY_SHIFT_FOR_FLAGS];
    } else {
        return nil;
    }    
}

- (void)tableRemoveIrrelevantBoxes
{
    EucCSSIntermediateDocument *document = self.document;
    uint8_t myDisplay = self.display;
    
    
    // 1. Remove irrelevant boxes: 
    
    if(myDisplay == CSS_DISPLAY_TABLE_COLUMN) {
        // 1.1. All child boxes of a 'table-column' parent are treated as if they had 'display: none'.
        free(_childKeys);
    } else {
        NSMutableIndexSet *toRemove = [[NSIndexSet alloc] init];
        uint32_t *childKeys = _childKeys;
        for(NSUInteger i = 0; i < _childCount; ++i) {
            EucCSSIntermediateDocumentNode *childNode = [document nodeForKey:childKeys[i]];
            uint8_t childDisplay = childDisplay;
            
            if(myDisplay == CSS_DISPLAY_TABLE_COLUMN_GROUP && 
               childDisplay != CSS_DISPLAY_TABLE_COLUMN) {
                // 1.2. If a child C of a 'table-column-group' parent is not a
                // 'table-column' box, then it is treated as if it had 'display: none'.
                [toRemove addIndex:i];
            }
            if(childNode.isTextNode) {
                if([childNode.text rangeOfCharacterFromSet:[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet]].location == NSNotFound) {
                    // 1.3. If a child C of a tabular container P is an anonymous inline
                    // box that contains only white space, and its immediately
                    // preceding and following siblings, if any, are proper table
                    // descendants of P and are either 'table-caption' or internal
                    // table boxes, then it is treated as if it had 'display: none'.
                    // A box D is a proper table descendant of A if D can be a
                    // descendant of A without causing the generation of any
                    // intervening 'table' or 'inline-table' boxes.
                    
                    // 1.4. If a box B is an anonymous inline containing only white
                    // space, and is between two immediate siblings each of
                    // which is either an internal table box or a 'table-caption'
                    // box then B is treated as if it had 'display: none'.

                    // TODO: Think we might be misinterpreting the this - these seem to be the same...

                    
                    BOOL doRemove = YES;
                    if(i >= 1) {
                        EucCSSIntermediateDocumentNode *previousSibling = [document nodeForKey:childKeys[i - 1]];
                        uint8_t previousSiblingDisplay = previousSibling.display;
                        if(previousSiblingDisplay != CSS_DISPLAY_TABLE_CAPTION &&
                           previousSiblingDisplay != CSS_DISPLAY_TABLE_ROW &&
                           previousSiblingDisplay != CSS_DISPLAY_TABLE_ROW_GROUP &&
                           previousSiblingDisplay != CSS_DISPLAY_TABLE_FOOTER_GROUP &&
                           previousSiblingDisplay != CSS_DISPLAY_TABLE_HEADER_GROUP &&
                           previousSiblingDisplay != CSS_DISPLAY_TABLE_COLUMN &&
                           previousSiblingDisplay != CSS_DISPLAY_TABLE_COLUMN_GROUP &&
                           previousSiblingDisplay != CSS_DISPLAY_TABLE_CELL) {
                            doRemove = NO;
                        }
                    } 
                    if(i < _childCount - 2) {
                        EucCSSIntermediateDocumentNode *nextSibling = [document nodeForKey:childKeys[i + 1]];
                        uint8_t nextSiblingDisplay = nextSibling.display;
                        if(nextSiblingDisplay != CSS_DISPLAY_TABLE_CAPTION &&
                           nextSiblingDisplay != CSS_DISPLAY_TABLE_ROW &&
                           nextSiblingDisplay != CSS_DISPLAY_TABLE_ROW_GROUP &&
                           nextSiblingDisplay != CSS_DISPLAY_TABLE_FOOTER_GROUP &&
                           nextSiblingDisplay != CSS_DISPLAY_TABLE_HEADER_GROUP &&
                           nextSiblingDisplay != CSS_DISPLAY_TABLE_COLUMN &&
                           nextSiblingDisplay != CSS_DISPLAY_TABLE_COLUMN_GROUP &&
                           nextSiblingDisplay != CSS_DISPLAY_TABLE_CELL) {
                            doRemove = NO;
                        }
                    }
                    if(doRemove) {
                        [toRemove addIndex:i];
                    }
                }
            }
        }
        NSUInteger toRemoveCount = toRemove.count;
        if(toRemoveCount) {
            uint32_t *newChildKeys = NULL;
            NSUInteger newChildCount = _childCount - toRemoveCount;
            if(newChildCount > 0) {
                newChildKeys = malloc(sizeof(uint32_t) * newChildCount);
                NSUInteger i = 0, j = 0;
                for(; i < _childCount; ++i, ++j) {
                    if(![toRemove containsIndex:i]) {
                        newChildKeys[j++] = _childKeys[i];
                    }
                }
            }
            free(_childKeys);
            _childKeys = newChildKeys;
            _childCount = newChildCount;
        }
        [toRemove release];
    }
}

- (void)_computeChildren
{
    uint32_t childCount = _documentTreeNode.childCount;
    if(self.computedBeforeStyle) {
        childCount++;
    }
    if(self.computedAfterStyle) {
        childCount++;
    }
    _childCount = childCount;
    
    uint32_t generatedCount = 0;
    
    if(childCount) {
        uint32_t *children = malloc(childCount * sizeof(uint32_t));
        uint32_t *child = children;
        
        if(self.computedBeforeStyle) {
            *(child++) = self.key | ++generatedCount;
            ++generatedCount;
        }
        
        id<EucCSSDocumentTreeNode> documentChild = _documentTreeNode.firstChild;
        while(documentChild) {
             *(child++) = documentChild.key << EUC_CSS_DOCUMENT_TREE_NODE_TO_INTERMEDIATE_DOCUMENT_NODE_KEY_SHIFT_FOR_FLAGS;
            documentChild = documentChild.nextSibling;
        }
        
        if(self.computedAfterStyle) {
            *(child++) = self.key | ++generatedCount;
            ++generatedCount;
        }
        
        _childKeys = children;
    }
    _childrenComputed = YES;
}

- (uint32_t)childCount;
{
    if(!_childrenComputed) {
        [self _computeChildren];
    }
    return _childCount;
}

- (uint32_t *)childKeys
{
    if(!_childrenComputed) {
        [self _computeChildren];
    }
    return _childKeys;    
}


- (EucCSSIntermediateDocumentNode *)generatedChildNodeForKey:(uint32_t)childKey
{
    EucCSSIntermediateDocumentNode *generatedChild = nil;
    
    uint32_t generationKey = childKey & EUC_CSS_INTERMEDIATE_DOCUMENT_NODE_KEY_FLAG_MASK;
    switch(generationKey) {
        case 1:
            generatedChild = [[EucCSSIntermediateDocumentGeneratedContainerNode alloc] initWithDocument:self.document
                                                                                                    key:childKey
                                                                                         isBeforeParent:self.computedBeforeStyle ? YES : NO];
            break;
        case 3:
            generatedChild = [[EucCSSIntermediateDocumentGeneratedContainerNode alloc] initWithDocument:self.document
                                                                                                    key:childKey
                                                                                         isBeforeParent:NO]; 
            break;
        case 2:
        case 4:
            generatedChild = [[EucCSSIntermediateDocumentGeneratedTextNode alloc] initWithDocument:self.document key:childKey];
            break;
        default:
            THWarn(@"Unexpected generated child key %ld", (long)generationKey);            
    }
    
    return [generatedChild autorelease];
}

- (NSUInteger)rowSpan
{
    if([_documentTreeNode respondsToSelector:@selector(rowSpan)]) {
        NSUInteger ret = [_documentTreeNode rowSpan];
        return MAX(ret, 1);
    } else {
        return [super rowSpan];
    }
}

- (NSUInteger)columnSpan
{
    if([_documentTreeNode respondsToSelector:@selector(columnSpan)]) {
        NSUInteger ret = [_documentTreeNode columnSpan];
        return MAX(ret, 1);
    } else {
        return [super columnSpan];
    }
}

@end
