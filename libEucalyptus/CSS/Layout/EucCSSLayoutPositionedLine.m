//
//  EucCSSLayoutPositionedLine.m
//  LibCSSTest
//
//  Created by James Montgomerie on 12/01/2010.
//  Copyright 2010 Things Made Out Of Other Things. All rights reserved.
//

#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#else
#import <ApplicationServices/ApplicationServices.h>
#endif

#import "EucCSSLayoutPositionedLine.h"
#import "EucCSSIntermediateDocumentNode.h"
#import "EucCSSLayoutPositionedRun.h"
#import "EucCSSLayoutDocumentRun.h"
#import "EucCSSLayoutDocumentRun_Package.h"
#import "THLog.h"

#import <libcss/libcss.h>

@implementation EucCSSLayoutPositionedLine

@synthesize startPoint = _startPoint;
@synthesize endPoint = _endPoint;

@synthesize componentWidth = _componentWidth;

@synthesize indent = _indent;
@synthesize baseline = _baseline;

@synthesize align = _align;

- (void)dealloc
{    
    EucCSSLayoutPositionedLineRenderItem *renderItem = _renderItems;
    EucCSSLayoutPositionedLineRenderItem *renderItemEnd = _renderItems + _renderItemCount;
    for(; renderItem < renderItemEnd; ++renderItem) {
        switch (renderItem->kind) {
            case EucCSSLayoutPositionedLineRenderItemKindString:
                [renderItem->item.stringItem.string release];
                [renderItem->item.stringItem.stringRenderer release];
                break;
            case EucCSSLayoutPositionedLineRenderItemKindImage:
                CFRelease(renderItem->item.imageItem.image);
                break;
            case EucCSSLayoutPositionedLineRenderItemKindUnderlineStart:
            case EucCSSLayoutPositionedLineRenderItemKindUnderlineStop:
                break;
            case EucCSSLayoutPositionedLineRenderItemKindHyperlinkStart:
            case EucCSSLayoutPositionedLineRenderItemKindHyperlinkStop:
                [renderItem->item.hyperlinkItem.url release];
                break;
        }
        if(renderItem->altText) {
            [renderItem->altText release];
        }

    }
    free(_renderItems);
    
    [super dealloc];
}

- (void)sizeToFitInWidth:(CGFloat)width;
{
    if(!_componentWidth) {
        EucCSSLayoutDocumentRun *documentRun = ((EucCSSLayoutPositionedRun *)self.parent).documentRun;
        CGFloat lineBoxHeight = 0;
        CGFloat currentBaseline = 0;
        
        size_t componentsCount = documentRun.componentsCount;
        
        uint32_t startComponentOffset = [documentRun pointToComponentOffset:_startPoint];
        uint32_t afterEndComponentOffset = [documentRun pointToComponentOffset:_endPoint];
        EucCSSLayoutDocumentRunComponentInfo *componentInfos = &(documentRun.componentInfos[startComponentOffset]);

        if(afterEndComponentOffset == startComponentOffset) {
            // This is a line with no components, ending in a hard break.
            // Set up to use the hard break itsself as the only component, so that
            // we pick up the line height.
            // This is a bit of a hack.
            afterEndComponentOffset = startComponentOffset + 1;
        }
        
        EucCSSIntermediateDocumentNode *currentDocumentNode = nil;
        uint32_t i;
        EucCSSLayoutDocumentRunComponentInfo *info;
        for(i = startComponentOffset, info = componentInfos;
            i < componentsCount && i < afterEndComponentOffset; 
            ++i, ++info) {
            if(info->kind != EucCSSLayoutDocumentRunComponentKindHyphenationRule 
               || i == startComponentOffset || i == afterEndComponentOffset - 1) {
                if(info->documentNode != currentDocumentNode) {
                    CGFloat emBoxHeight = info->pointSize;
                    CGFloat inlineBoxHeight = info->lineHeight;
                    
                    CGFloat halfLeading = (inlineBoxHeight - emBoxHeight) * 0.5f;
                    if(halfLeading != floorf(halfLeading)) {
                        halfLeading += 0.5f;
                        inlineBoxHeight += 1.0f;
                    }
                    
                    CGFloat baseline = info->ascender + halfLeading;
                    CGFloat descenderAndLineHeightAddition = inlineBoxHeight - baseline;
                    if(baseline > currentBaseline) {
                        currentBaseline = baseline;
                    }
                    CGFloat baselineAdjustedLineHeight = currentBaseline + descenderAndLineHeightAddition;
                    if(baselineAdjustedLineHeight > lineBoxHeight) {
                        lineBoxHeight = baselineAdjustedLineHeight;
                    }
                    currentDocumentNode = info->documentNode;
                }
                if(info->kind == EucCSSLayoutDocumentRunComponentKindHyphenationRule) {
                    if(i == startComponentOffset) {
                        _componentWidth += info->widthAfterHyphen;
                    }
                } else {
                    _componentWidth += info->width;
                }
            }
        }
        
        // Stopping 'just before' a hyphen component really means that we stop
        // after the first part of the hyphenated word.
        if(i < documentRun.componentsCount) {
            if(info->kind == EucCSSLayoutDocumentRunComponentKindHyphenationRule) {
                _componentWidth -= info->width;
                _componentWidth += info->widthBeforeHyphen;
            }
        }
        
        _baseline = currentBaseline;
        
        CGRect frame = self.frame;
        frame.size = CGSizeMake(width, lineBoxHeight);
        self.frame = frame;
    } else {
        CGRect frame = self.frame;
        frame.size.width = width;
        self.frame = frame;
    }
}

- (CGFloat)minimumWidth
{
    return ceilf(_componentWidth + _indent);
}

- (size_t)renderItemCount
{
    if(!_renderItems) {
        [self renderItems];
    }
    return _renderItemCount;
}

static inline void _incrementRenderitemsCount(EucCSSLayoutPositionedLineRenderItem **currentRenderItem, size_t *renderItemCount, size_t *renderItemCapacity, EucCSSLayoutPositionedLineRenderItem **renderItems) 
{
    ++*renderItemCount;
    if(*renderItemCount == *renderItemCapacity) { 
        size_t oldCapacity = *renderItemCapacity;
        *renderItemCapacity *= 2; 
        *renderItems = realloc(*renderItems, *renderItemCapacity * sizeof(EucCSSLayoutPositionedLineRenderItem)); 
        bzero((*renderItems) + oldCapacity, oldCapacity * sizeof(EucCSSLayoutPositionedLineRenderItem));
        *currentRenderItem = (*renderItems) + oldCapacity;
    } else {
        ++*currentRenderItem;
    }
}

- (EucCSSLayoutPositionedLineRenderItem *)renderItems
{
    if(!_renderItems) {
        EucCSSLayoutDocumentRun *documentRun = ((EucCSSLayoutPositionedRun *)self.parent).documentRun;
        
        size_t componentsCount = documentRun.componentsCount;
        uint32_t startComponentOffset = [documentRun pointToComponentOffset:_startPoint];
        uint32_t afterEndComponentOffset = [documentRun pointToComponentOffset:_endPoint];
        
        _renderItems = calloc(sizeof(EucCSSLayoutPositionedLineRenderItem), componentsCount);
        size_t renderItemCapacity = componentsCount;
        
        CGRect contentBounds = self.contentBounds;
        CGSize size = contentBounds.size;
        CGFloat xPosition = contentBounds.origin.x;
        CGFloat yPosition = contentBounds.origin.y;
        CGFloat baseline = _baseline;        
        
        CGFloat extraWidthNeeded = 0.0f;
        CGFloat spacesRemaining = 0.0f;
        
        EucCSSLayoutDocumentRunComponentInfo *componentInfos = &(documentRun.componentInfos[startComponentOffset]);
        
        uint32_t i;
        EucCSSLayoutDocumentRunComponentInfo *info;
        
        switch(_align) {
            case CSS_TEXT_ALIGN_CENTER:
                xPosition += (size.width - _componentWidth) * 0.5f;
                break;
            case CSS_TEXT_ALIGN_RIGHT:
                xPosition += size.width - _componentWidth - _indent;
                break;
            case CSS_TEXT_ALIGN_JUSTIFY:
                for(i = startComponentOffset, info = componentInfos;
                    i < componentsCount && i < afterEndComponentOffset; 
                    ++i, ++info) {
                    if(info->kind == EucCSSLayoutDocumentRunComponentKindSpace || 
                       info->kind == EucCSSLayoutDocumentRunComponentKindNonbreakingSpace) {
                        spacesRemaining++;
                    }
                }    
                extraWidthNeeded = size.width - _indent - _componentWidth;
                // Fall through.
            default:
                xPosition += _indent;
        }

        css_color color = 0x00000000;
        BOOL currentUnderline = NO;
        NSURL *currentHyperlink = nil;
        BOOL checkNodeDependentStyles = YES;
        
        EucCSSLayoutPositionedLineRenderItem *renderItem = _renderItems;
        for(i = startComponentOffset, info = componentInfos;
            i < componentsCount && i < afterEndComponentOffset; 
            ++i, ++info) {
            
            if(checkNodeDependentStyles) {
                css_computed_style *style = [info->documentNode computedStyle];
                if(!style) {
                    style = [(info->documentNode).parent computedStyle];
                }
                
                css_color newColor;
                uint8_t colorRet = css_computed_color(style, &newColor);
                if(colorRet == CSS_COLOR_COLOR) {
                    color = newColor;
                } else {
                    THWarn(@"Unexpected color format %ld", (long)colorRet);
                }
                
                uint8_t decoration = css_computed_text_decoration(style);
                BOOL shouldUnderline = (decoration == CSS_TEXT_DECORATION_UNDERLINE);
                if(currentUnderline != shouldUnderline) {
                    if(shouldUnderline) {
                        //NSLog(@"Underline On");
                        renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindUnderlineStart;
                        renderItem->item.underlineItem.underlinePoint = CGPointMake(floorf(xPosition), yPosition + baseline + 1.5f);
                    } else {
                        //NSLog(@"Underline Off");
                        renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindUnderlineStop;
                        renderItem->item.underlineItem.underlinePoint = CGPointMake(ceilf(xPosition), yPosition + baseline + 1.5f);
                    }
                    _incrementRenderitemsCount(&renderItem, &_renderItemCount, &renderItemCapacity, &_renderItems);
                    currentUnderline = shouldUnderline;
                }

                NSURL *href = nil;
                EucCSSIntermediateDocumentNode *documentNode = info->documentNode;
                while(!href && documentNode) {
                    if(documentNode.isHyperlinkNode) {
                        href = documentNode.hyperlinkURL;
                    }
                    documentNode = documentNode.parent;
                }
                if(href) {
                    if(currentHyperlink) {
                        if(![currentHyperlink isEqual:href]) {
                            renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindHyperlinkStop;
                            renderItem->item.hyperlinkItem.url = [currentHyperlink retain];
                            _incrementRenderitemsCount(&renderItem, &_renderItemCount, &renderItemCapacity, &_renderItems);
                            [currentHyperlink release];
                            //NSLog(@"Hyperlink Off");
                            //NSLog(@"Hyperlink On");
                            currentHyperlink = [href retain];
                            renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindHyperlinkStart;
                            renderItem->item.hyperlinkItem.url = [currentHyperlink retain];
                            _incrementRenderitemsCount(&renderItem, &_renderItemCount, &renderItemCapacity, &_renderItems);
                        }
                    } else {
                        //NSLog(@"Hyperlink On");
                        currentHyperlink = [href retain];
                        renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindHyperlinkStart;
                        renderItem->item.hyperlinkItem.url = [currentHyperlink retain];
                        _incrementRenderitemsCount(&renderItem, &_renderItemCount, &renderItemCapacity, &_renderItems);
                    }
                } else {
                    if(currentHyperlink) {
                        //NSLog(@"Hyperlink Off");
                        renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindHyperlinkStop;
                        renderItem->item.hyperlinkItem.url = [currentHyperlink retain];
                        _incrementRenderitemsCount(&renderItem, &_renderItemCount, &renderItemCapacity, &_renderItems);
                        [currentHyperlink release];
                        currentHyperlink = nil;
                    }
                }
                        
                checkNodeDependentStyles = NO;
            }
            
            if(info->kind == EucCSSLayoutDocumentRunComponentKindWord) {
                renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindString;
                renderItem->item.stringItem.string = [(NSString *)info->component retain];
                renderItem->item.stringItem.rect = CGRectMake(xPosition, yPosition + baseline - info->ascender, info->width, size.height);
                renderItem->item.stringItem.pointSize = info->pointSize;
                renderItem->item.stringItem.stringRenderer = [info->documentNode.stringRenderer retain];
                renderItem->item.stringItem.layoutPoint = info->point;
                renderItem->item.stringItem.color = color;
                _incrementRenderitemsCount(&renderItem, &_renderItemCount, &renderItemCapacity, &_renderItems);
                
                xPosition += info->width;
            } else if(info->kind == EucCSSLayoutDocumentRunComponentKindSpace || 
                      info->kind == EucCSSLayoutDocumentRunComponentKindNonbreakingSpace) {
                if(extraWidthNeeded != 0.0f) {
                    CGFloat extraSpace = extraWidthNeeded / spacesRemaining;
                    xPosition += extraSpace;
                    extraWidthNeeded -= extraSpace;
                    --spacesRemaining;
                }
                xPosition += info->width;
            } else if(info->kind == EucCSSLayoutDocumentRunComponentKindHyphenationRule) {
                if(i == startComponentOffset) {
                    renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindString;
                    renderItem->item.stringItem.string = [(NSString *)info->component2 retain];
                    renderItem->item.stringItem.rect = CGRectMake(xPosition, yPosition + baseline - info->ascender, info->widthAfterHyphen, size.height);
                    renderItem->item.stringItem.pointSize = info->pointSize;
                    renderItem->item.stringItem.stringRenderer = [info->documentNode.stringRenderer retain];
                    renderItem->item.stringItem.layoutPoint = info->point;
                    renderItem->item.stringItem.color = color;
                    _incrementRenderitemsCount(&renderItem, &_renderItemCount, &renderItemCapacity, &_renderItems);
                    
                    xPosition += info->widthAfterHyphen;
                }
            } else if(info->kind == EucCSSLayoutDocumentRunComponentKindImage) {
                renderItem->kind = EucCSSLayoutPositionedLineRenderItemKindImage;
                renderItem->item.imageItem.image = CGImageRetain((CGImageRef)info->component);
                renderItem->item.imageItem.rect = CGRectMake(xPosition, yPosition + baseline - info->ascender, info->width, info->pointSize);
                renderItem->item.imageItem.layoutPoint = info->point;
                renderItem->altText = [[info->documentNode altText] retain];
                _incrementRenderitemsCount(&renderItem, &_renderItemCount, &renderItemCapacity, &_renderItems);
                
                xPosition += info->width;
            } else if(info->kind == EucCSSLayoutDocumentRunComponentKindOpenNode || info->kind == EucCSSLayoutDocumentRunComponentKindCloseNode) {
                checkNodeDependentStyles = YES;
            }
        }
        
        // Stopping 'just before' a hyphen component really means that we stop
        // after the first part of the hyphenated word.
        if(i < documentRun.componentsCount) {
            if(info->kind == EucCSSLayoutDocumentRunComponentKindHyphenationRule) {
                --renderItem;
                
                xPosition -= info->width;
                
                // Store the entire word in the alt text for accessibility.
                renderItem->altText = renderItem->item.stringItem.string;
                
                renderItem->item.stringItem.string = [(NSString *)info->component retain];
                renderItem->item.stringItem.rect.size.width = info->widthBeforeHyphen;
                renderItem->item.stringItem.layoutPoint = info->point;
            }
        }
        
        [currentHyperlink release];
    }
    return _renderItems;
}

- (NSComparisonResult)compare:(EucCSSLayoutPositionedLine *)rhs 
{
    return self < rhs ? NSOrderedAscending : (self > rhs ? NSOrderedDescending : NSOrderedSame);
}

@end
